const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { z } = require('zod');
const env = require('../config/env');
const db = require('../config/db');
const { ApiError, errors, fail } = require('../utils/http');
const { friendly } = require('../utils/validationMessages');
const { verifyAccess } = require('../utils/security');

function bearer(req) {
  const h = req.headers.authorization || '';
  return h.startsWith('Bearer ') ? h.slice(7) : null;
}

/** App user auth. Blocked users are rejected. Sets req.user. */
async function requireUser(req, _res, next) {
  try {
    const token = bearer(req);
    if (!token) throw errors.unauthorized();
    let payload;
    try {
      payload = verifyAccess(token);
    } catch {
      throw new ApiError(401, 'TOKEN_INVALID', 'Your session has expired. Please sign in again.');
    }
    if (payload.typ !== 'user') throw errors.unauthorized();
    const user = await db.one('SELECT * FROM users WHERE id = :id', { id: Number(payload.sub) });
    if (!user) throw errors.unauthorized();
    if (user.status === 'blocked') throw new ApiError(403, 'ACCOUNT_BLOCKED', 'This account has been blocked.');
    req.user = user;
    next();
  } catch (e) {
    next(e);
  }
}

/** After requireUser: networking features need a finished profile (onboarding step 7). */
function requireOnboarded(req, _res, next) {
  if (req.user.onboarding_step >= 7) return next();
  next(new ApiError(403, 'PROFILE_INCOMPLETE', 'Finish setting up your profile to use this feature.', { currentStep: req.user.onboarding_step }));
}

/** Admin auth; optionally restrict to roles. Sets req.admin. */
const requireAdmin = (...roles) =>
  async function adminGuard(req, _res, next) {
    try {
      const token = bearer(req);
      if (!token) throw errors.unauthorized();
      let payload;
      try {
        payload = verifyAccess(token);
      } catch {
        throw new ApiError(401, 'TOKEN_INVALID', 'Session expired. Please log in again.');
      }
      if (payload.typ !== 'admin') throw errors.forbidden();
      const admin = await db.one('SELECT id, name, email, role, is_active FROM admins WHERE id = :id', { id: Number(payload.sub) });
      if (!admin || !admin.is_active) throw errors.unauthorized();
      if (roles.length && !roles.includes(admin.role)) throw errors.forbidden();
      req.admin = admin;
      next();
    } catch (e) {
      next(e);
    }
  };

/** Validate req[source] with a zod schema; replaces it with parsed output. */
const validate = (schema, source = 'body') => (req, _res, next) => {
  const r = schema.safeParse(req[source] ?? {});
  if (!r.success) {
    const details = r.error.issues.map((i) => ({ field: i.path.join('.') || '_', message: friendly(i) }));
    return next(errors.validation(details[0]?.message || 'Please check the highlighted fields.', details));
  }
  if (source === 'query') req.validQuery = r.data;
  else req[source] = r.data;
  next();
};

const idParam = validate(z.object({ id: z.coerce.number().int().positive() }).passthrough(), 'params');

/** Image upload to uploads/<folder>/ (jpg/png/webp, MAX_IMAGE_MB). */
function imageUpload(folder, field) {
  const dir = path.join(env.uploads.dir, folder);
  fs.mkdirSync(dir, { recursive: true });
  const ext = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' };
  return multer({
    storage: multer.diskStorage({
      destination: dir,
      filename: (_req, file, cb) => cb(null, `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext[file.mimetype]}`),
    }),
    limits: { fileSize: env.uploads.maxImageMb * 1024 * 1024, files: 1 },
    fileFilter: (_req, file, cb) =>
      ext[file.mimetype] ? cb(null, true) : cb(new ApiError(415, 'UNSUPPORTED_FILE', 'Upload a JPG, PNG or WEBP image.')),
  }).single(field);
}

function notFound(req, _res, next) {
  next(new ApiError(404, 'ROUTE_NOT_FOUND', `No route for ${req.method} ${req.originalUrl}`));
}

/**
 * Every failure leaves here in the standard shape:
 *   { status: 0, data: { code, errors?, ...details }, message }
 */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, _next) {
  if (err instanceof multer.MulterError) {
    err = new ApiError(err.code === 'LIMIT_FILE_SIZE' ? 413 : 400, 'UPLOAD_ERROR',
      err.code === 'LIMIT_FILE_SIZE' ? `Image must be under ${env.uploads.maxImageMb} MB.` : err.message);
  }
  if (err?.type === 'entity.parse.failed') err = new ApiError(400, 'INVALID_JSON', 'Request body is not valid JSON.');
  if (err?.type === 'entity.too.large') err = new ApiError(413, 'PAYLOAD_TOO_LARGE', 'Request body is too large.');
  if (err?.code === 'ER_DUP_ENTRY') err = new ApiError(409, 'DUPLICATE', 'An item with the same name already exists.');
  if (err?.code === 'ER_NO_REFERENCED_ROW_2') err = new ApiError(400, 'INVALID_REFERENCE', 'A referenced item does not exist.');
  // Other framework errors that already carry a 4xx status (e.g. malformed request).
  if (!(err instanceof ApiError) && Number(err?.status) >= 400 && Number(err?.status) < 500) {
    err = new ApiError(Number(err.status), 'BAD_REQUEST', err.expose && err.message ? err.message : 'The request could not be processed.');
  }

  const known = err instanceof ApiError;
  const httpStatus = known ? err.status : 500;
  if (httpStatus >= 500) console.error(`[${req.method} ${req.originalUrl}]`, err);

  const data = { code: known ? err.code : 'INTERNAL_ERROR' };
  if (known && err.details) {
    if (Array.isArray(err.details)) data.errors = err.details; // validation: [{ field, message }]
    else Object.assign(data, err.details); //                    extra context, e.g. { requestId }
  }
  fail(res, httpStatus, known ? err.message : 'Something went wrong. Please try again.', data);
}

module.exports = { requireUser, requireOnboarded, requireAdmin, validate, idParam, imageUpload, notFound, errorHandler };
