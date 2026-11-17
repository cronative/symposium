const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const db = require('../config/db');

const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');
const hmac = (s) => crypto.createHmac('sha256', env.otp.secret).update(s).digest('hex');

/** Constant-time compare of two hex strings. */
function safeEqual(a, b) {
  const ab = Buffer.from(a, 'hex');
  const bb = Buffer.from(b, 'hex');
  return ab.length === bb.length && crypto.timingSafeEqual(ab, bb);
}

function randomOtp(length = env.otp.length) {
  let code = '';
  for (let i = 0; i < length; i++) code += crypto.randomInt(0, 10);
  return code;
}

function signAccess(subjectType, id, extra = {}) {
  return jwt.sign({ typ: subjectType, ...extra }, env.jwt.accessSecret, {
    subject: String(id),
    expiresIn: env.jwt.accessTtl,
  });
}

function verifyAccess(token) {
  return jwt.verify(token, env.jwt.accessSecret);
}

/** Issue access + opaque refresh token (stored hashed). */
async function issueTokens(subjectType, id, extra = {}, conn) {
  const refreshToken = crypto.randomBytes(48).toString('base64url');
  const expires = new Date(Date.now() + env.jwt.refreshTtlDays * 86400_000);
  await db.query(
    'INSERT INTO refresh_tokens (subject_type, subject_id, token_hash, expires_at) VALUES (:t, :id, :h, :e)',
    { t: subjectType, id, h: sha256(refreshToken), e: expires },
    conn,
  );
  const accessToken = signAccess(subjectType, id, extra);
  const decoded = jwt.decode(accessToken);
  return {
    accessToken,
    refreshToken,
    tokenType: 'Bearer',
    expiresIn: decoded.exp - decoded.iat,
  };
}

/** Validate + rotate a refresh token. Returns the subject row id. */
async function rotateRefresh(subjectType, refreshToken) {
  const row = await db.one(
    `SELECT * FROM refresh_tokens WHERE token_hash = :h AND subject_type = :t`,
    { h: sha256(refreshToken), t: subjectType },
  );
  if (!row || row.revoked_at || new Date(row.expires_at) < new Date()) return null;
  await db.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = :id', { id: row.id });
  return row.subject_id;
}

async function revokeRefresh(subjectType, refreshToken) {
  await db.query(
    'UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = :h AND subject_type = :t AND revoked_at IS NULL',
    { h: sha256(refreshToken), t: subjectType },
  );
}

async function revokeAll(subjectType, id) {
  await db.query(
    'UPDATE refresh_tokens SET revoked_at = NOW() WHERE subject_type = :t AND subject_id = :id AND revoked_at IS NULL',
    { t: subjectType, id },
  );
}

module.exports = { sha256, hmac, safeEqual, randomOtp, issueTokens, verifyAccess, rotateRefresh, revokeRefresh, revokeAll };
