const crypto = require('crypto');
const express = require('express');
const { z } = require('zod');
const env = require('../../config/env');
const db = require('../../config/db');
const { ApiError, errors, ah, ok } = require('../../utils/http');
const { hmac, safeEqual, randomOtp, issueTokens, rotateRefresh, revokeRefresh } = require('../../utils/security');
const { parseIdentifier, maskDestination } = require('../../utils/format');
const { sendOtp, isMock } = require('../../services/otpProvider');
const { validate } = require('../../middleware');

const router = express.Router();
const sec = (s) => new Date(Date.now() + s * 1000);
/** Fixed test code (OTP_FIXED_CODE, default 123456 outside production) or a random one. */
const newCode = () => (/^\d{6}$/.test(env.otp.fixedCode) ? env.otp.fixedCode : randomOtp());
const codeHash = (requestId, code) => hmac(`${requestId}:${code}`);

async function assertRateLimit(identifier) {
  const r = await db.one(
    'SELECT COUNT(*) AS n FROM otp_requests WHERE identifier = :i AND created_at > :since',
    { i: identifier, since: new Date(Date.now() - 3600_000) },
  );
  if (r.n >= env.otp.maxRequestsPerHour) {
    throw errors.tooMany('OTP_RATE_LIMITED', 'Too many code requests. Please try again in a little while.');
  }
}

function otpResponse(row, code) {
  const data = {
    requestId: row.id,
    channel: row.channel,
    maskedDestination: maskDestination(row.identifier, row.channel),
    expiresIn: env.otp.expirySeconds,
    resendAfter: env.otp.resendSeconds,
  };
  if (isMock() && env.otp.exposeDevCode && !env.isProd) data.devCode = code;
  return data;
}

/** Find or create the user for a verified identifier. */
async function upsertUserByIdentifier({ identifier, channel }, conn) {
  const col = channel === 'email' ? 'email' : 'phone';
  let user = await db.one(`SELECT * FROM users WHERE ${col} = :v`, { v: identifier }, conn);
  let isNew = false;
  if (!user) {
    const r = await db.query(
      `INSERT INTO users (${col}, terms_accepted_at) VALUES (:v, UTC_TIMESTAMP())`,
      { v: identifier },
      conn,
    );
    user = await db.one('SELECT * FROM users WHERE id = :id', { id: r.insertId }, conn);
    isNew = true;
  }
  return { user, isNew };
}

async function sessionFor(user, isNew, conn) {
  if (user.status === 'blocked') throw new ApiError(403, 'ACCOUNT_BLOCKED', 'This account has been blocked.');
  await db.query('UPDATE users SET last_login_at = UTC_TIMESTAMP() WHERE id = :id', { id: user.id }, conn);
  const tokens = await issueTokens('user', user.id, {}, conn);
  return {
    ...tokens,
    user: {
      id: user.id,
      isNew,
      onboardingStep: user.onboarding_step,
      verificationStatus: user.verification_status,
    },
  };
}

// POST /auth/otp/request
router.post(
  '/otp/request',
  validate(z.object({
    identifier: z.string().min(5).max(190),
    termsAccepted: z.literal(true, { error: 'Please accept the Terms of Service and Privacy Policy.' }),
  })),
  ah(async (req, res) => {
    const parsed = parseIdentifier(req.body.identifier);
    if (!parsed) throw new ApiError(400, 'INVALID_IDENTIFIER', 'Enter a valid phone number or email address.');
    await assertRateLimit(parsed.identifier);

    const id = crypto.randomUUID();
    const code = newCode();
    const row = {
      id,
      identifier: parsed.identifier,
      channel: parsed.channel,
      code_hash: codeHash(id, code),
      terms_accepted: 1,
      expires_at: sec(env.otp.expirySeconds),
      resend_available_at: sec(env.otp.resendSeconds),
    };
    await db.query(
      `INSERT INTO otp_requests (id, identifier, channel, code_hash, terms_accepted, expires_at, resend_available_at)
       VALUES (:id, :identifier, :channel, :code_hash, :terms_accepted, :expires_at, :resend_available_at)`,
      row,
    );
    await sendOtp({ identifier: parsed.identifier, channel: parsed.channel, code });
    ok(res, otpResponse(row, code), `Verification code sent to ${maskDestination(row.identifier, row.channel)}.`);
  }),
);

// POST /auth/otp/resend
router.post(
  '/otp/resend',
  validate(z.object({ requestId: z.uuid() })),
  ah(async (req, res) => {
    const row = await db.one('SELECT * FROM otp_requests WHERE id = :id', { id: req.body.requestId });
    if (!row || row.consumed_at) throw new ApiError(404, 'OTP_NOT_FOUND', 'This code request is no longer valid. Please start again.');
    const wait = Math.ceil((new Date(row.resend_available_at) - Date.now()) / 1000);
    if (wait > 0) throw errors.tooMany('OTP_RESEND_TOO_SOON', `You can request a new code in ${wait}s.`, { retryAfter: wait });
    await assertRateLimit(row.identifier);

    const code = newCode();
    const upd = { id: row.id, h: codeHash(row.id, code), e: sec(env.otp.expirySeconds), r: sec(env.otp.resendSeconds) };
    await db.query('UPDATE otp_requests SET code_hash = :h, attempts = 0, expires_at = :e, resend_available_at = :r WHERE id = :id', upd);
    // count the resend toward the hourly limit
    await db.query(
      `INSERT INTO otp_requests (id, identifier, channel, code_hash, expires_at, resend_available_at, consumed_at)
       VALUES (:id, :i, :c, :h, UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP())`,
      { id: crypto.randomUUID(), i: row.identifier, c: row.channel, h: '0'.repeat(64) },
    );
    await sendOtp({ identifier: row.identifier, channel: row.channel, code });
    ok(res, otpResponse(row, code), 'A new verification code is on its way.');
  }),
);

// POST /auth/otp/verify
router.post(
  '/otp/verify',
  validate(z.object({ requestId: z.uuid(), code: z.string().regex(/^\d{6}$/, 'Enter the 6-digit code.') })),
  ah(async (req, res) => {
    const { requestId, code } = req.body;
    const data = await db.tx(async (conn) => {
      const row = await db.one('SELECT * FROM otp_requests WHERE id = :id FOR UPDATE', { id: requestId }, conn);
      if (!row || row.consumed_at) throw new ApiError(404, 'OTP_NOT_FOUND', 'This code request is no longer valid. Please start again.');
      if (row.attempts >= env.otp.maxAttempts) {
        throw errors.tooMany('OTP_TOO_MANY_ATTEMPTS', "You've tried too many times. Please wait a little before trying again.");
      }
      if (new Date(row.expires_at) < new Date()) {
        throw new ApiError(400, 'OTP_EXPIRED', 'This code has expired. Request a new one to continue.');
      }
      if (!safeEqual(codeHash(row.id, code), row.code_hash)) {
        const attempts = row.attempts + 1;
        await db.query('UPDATE otp_requests SET attempts = :a WHERE id = :id', { a: attempts, id: row.id }, conn);
        return { error: attempts >= env.otp.maxAttempts ? 'locked' : 'invalid', remaining: env.otp.maxAttempts - attempts };
      }
      await db.query('UPDATE otp_requests SET consumed_at = UTC_TIMESTAMP() WHERE id = :id', { id: row.id }, conn);
      const { user, isNew } = await upsertUserByIdentifier(row, conn);
      return sessionFor(user, isNew, conn);
    });
    // Attempt counter must persist, so errors are raised after the transaction commits.
    if (data.error === 'locked') {
      throw errors.tooMany('OTP_TOO_MANY_ATTEMPTS', "You've tried too many times. Please wait a little before trying again.");
    }
    if (data.error === 'invalid') {
      throw new ApiError(400, 'OTP_INVALID', "That code doesn't look right. Check it and try again.", { remainingAttempts: data.remaining });
    }
    ok(res, data, data.user.isNew ? 'Verified! Let\'s set up your profile.' : 'Signed in successfully.');
  }),
);

// POST /auth/social — Google / LinkedIn / Apple
// Dev/mock mode accepts idToken "mock:<providerUid>:<email>". Plug real token
// verification (google-auth-library, apple-signin-auth, LinkedIn OIDC) into verifySocialToken.
async function verifySocialToken(provider, idToken) {
  if (!env.isProd && idToken.startsWith('mock:')) {
    const [, uid, email] = idToken.split(':');
    if (!uid) return null;
    return { uid, email: email || null };
  }
  throw new ApiError(501, 'SOCIAL_NOT_CONFIGURED', `${provider} sign-in is not configured on the server yet.`);
}

router.post(
  '/social',
  validate(z.object({
    provider: z.enum(['google', 'linkedin', 'apple']),
    idToken: z.string().min(5),
    termsAccepted: z.literal(true, { error: 'Please accept the Terms of Service and Privacy Policy.' }),
  })),
  ah(async (req, res) => {
    const { provider, idToken } = req.body;
    const profile = await verifySocialToken(provider, idToken);
    if (!profile) throw new ApiError(401, 'SOCIAL_TOKEN_INVALID', 'Could not verify your account. Please try again.');

    const data = await db.tx(async (conn) => {
      const link = await db.one('SELECT user_id FROM user_social_accounts WHERE provider = :p AND provider_uid = :u', { p: provider, u: profile.uid }, conn);
      let user;
      let isNew = false;
      if (link) {
        user = await db.one('SELECT * FROM users WHERE id = :id', { id: link.user_id }, conn);
      } else {
        if (profile.email) {
          ({ user, isNew } = await upsertUserByIdentifier({ identifier: profile.email.toLowerCase(), channel: 'email' }, conn));
        } else {
          const r = await db.query('INSERT INTO users (terms_accepted_at) VALUES (UTC_TIMESTAMP())', {}, conn);
          user = await db.one('SELECT * FROM users WHERE id = :id', { id: r.insertId }, conn);
          isNew = true;
        }
        await db.query('INSERT INTO user_social_accounts (user_id, provider, provider_uid) VALUES (:id, :p, :u)', { id: user.id, p: provider, u: profile.uid }, conn);
      }
      return sessionFor(user, isNew, conn);
    });
    ok(res, data, data.user.isNew ? 'Account created. Let\'s set up your profile.' : 'Signed in successfully.');
  }),
);

// POST /auth/refresh
router.post(
  '/refresh',
  validate(z.object({ refreshToken: z.string().min(20) })),
  ah(async (req, res) => {
    const userId = await rotateRefresh('user', req.body.refreshToken);
    if (!userId) throw new ApiError(401, 'REFRESH_INVALID', 'Your session has expired. Please sign in again.');
    const user = await db.one('SELECT * FROM users WHERE id = :id', { id: userId });
    if (!user) throw errors.unauthorized();
    ok(res, await sessionFor(user, false), 'Session refreshed.');
  }),
);

// POST /auth/logout
router.post(
  '/logout',
  validate(z.object({ refreshToken: z.string().min(20) })),
  ah(async (req, res) => {
    await revokeRefresh('user', req.body.refreshToken);
    ok(res, { loggedOut: true }, 'Logged out successfully.');
  }),
);

module.exports = router;
