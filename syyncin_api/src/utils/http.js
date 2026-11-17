/**
 * One response format for every endpoint (success and failure):
 *
 *   { "status": 1, "data": { … }, "message": "Request completed successfully." }   // success
 *   { "status": 0, "data": { "code": "…", … }, "message": "What went wrong." }      // failure
 *
 * - `data` is ALWAYS an object. Lists → { items: [...] } (+ `pagination` when paged).
 * - Failures carry a stable machine code in `data.code` (apps branch on it) and, for
 *   validation errors, `data.errors: [{ field, message }]`.
 * - Use the helpers below — never call res.json() directly in a route.
 */

/** Error with an HTTP status, a stable code for the apps and a user-facing message. */
class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const errors = {
  badRequest: (code, msg, details) => new ApiError(400, code, msg, details),
  validation: (msg, fieldErrors) => new ApiError(400, 'VALIDATION_ERROR', msg, fieldErrors),
  unauthorized: (msg = 'Authentication required.') => new ApiError(401, 'UNAUTHORIZED', msg),
  forbidden: (msg = 'You do not have access to this resource.') => new ApiError(403, 'FORBIDDEN', msg),
  notFound: (what = 'Resource') => new ApiError(404, 'NOT_FOUND', `${what} not found.`),
  conflict: (code, msg, details) => new ApiError(409, code, msg, details),
  tooMany: (code, msg, details) => new ApiError(429, code, msg, details),
};

/** Wrap async route handlers so rejections reach the error middleware. */
const ah = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const DEFAULT_MESSAGES = {
  GET: 'Data fetched successfully.',
  POST: 'Request completed successfully.',
  PUT: 'Updated successfully.',
  PATCH: 'Updated successfully.',
  DELETE: 'Deleted successfully.',
};

/** Coerce anything into the object `data` must be. */
function asObject(data) {
  if (data === undefined || data === null) return {};
  if (Array.isArray(data)) return { items: data };
  if (typeof data !== 'object') return { value: data };
  return data;
}

/** Low-level writer used by every helper and the error handler. */
function send(res, httpStatus, status, data, message) {
  return res.status(httpStatus).json({ status, data: asObject(data), message: message || (status ? 'Request completed successfully.' : 'Something went wrong. Please try again.') });
}

/** 200 success. `message` defaults to a sensible one for the HTTP method. */
const ok = (res, data, message, httpStatus = 200) => send(res, httpStatus, 1, data, message || DEFAULT_MESSAGES[res.req?.method] || DEFAULT_MESSAGES.POST);

/** 201 success for newly created resources. */
const created = (res, data, message = 'Created successfully.') => ok(res, data, message, 201);

/** 200 paged list → data: { items, pagination, ...extra }. */
const okList = (res, items, { page, limit }, total, message, extra = {}) =>
  ok(res, { items, pagination: pageMeta({ page, limit }, total), ...extra }, message);

/** Failure response (used by the error middleware). */
const fail = (res, httpStatus, message, data) => send(res, httpStatus, 0, data, message);

/** ?page=&limit= → { page, limit, offset } with sane bounds. */
function paging(q) {
  const page = Math.max(1, parseInt(q.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(q.limit, 10) || 20));
  return { page, limit, offset: (page - 1) * limit };
}

const pageMeta = ({ page, limit }, total) => ({ page, limit, total: Number(total), totalPages: Math.ceil(Number(total) / limit) || 0 });

module.exports = { ApiError, errors, ah, ok, created, okList, fail, send, asObject, paging, pageMeta };
