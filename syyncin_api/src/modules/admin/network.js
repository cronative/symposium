/**
 * Admin › Networking — oversight of connection requests and connections.
 *   GET    /admin/connection-requests            ?status=&search=&userId=&page=&limit=
 *   PATCH  /admin/connection-requests/:id/cancel cancel a pending request (moderation)
 *   GET    /admin/connections                    ?search=&userId=&page=&limit=
 *   DELETE /admin/connections/:userAId/:userBId  remove a connection (moderation)
 * Plus helpers used by /admin/stats and /admin/users/:id.
 */
const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { ApiError, ah, ok, okList, errors, paging } = require('../../utils/http');
const { fileUrl } = require('../../utils/format');
const { validate, idParam } = require('../../middleware');
const N = require('../../services/notifications');

const router = express.Router();

const member = (r, p) => ({
  id: r[`${p}_id`],
  fullName: r[`${p}_name`],
  jobTitle: r[`${p}_job`],
  photoUrl: fileUrl(r[`${p}_photo`]),
  status: r[`${p}_status`],
});
const memberCols = (alias, p) =>
  `${alias}.id AS ${p}_id, ${alias}.full_name AS ${p}_name, ${alias}.job_title AS ${p}_job, ${alias}.photo_path AS ${p}_photo, ${alias}.status AS ${p}_status`;
const like = (s) => `%${s.replace(/[%_]/g, '\\$&')}%`;

const listQuery = z.object({
  search: z.string().trim().max(80).optional(),
  userId: z.coerce.number().int().positive().optional(),
  page: z.coerce.number().optional(),
  limit: z.coerce.number().optional(),
});

// GET /admin/connection-requests
router.get(
  '/connection-requests',
  validate(listQuery.extend({ status: z.enum(['pending', 'accepted', 'declined', 'withdrawn', 'all']).optional().default('all') }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const p = paging(q);
    const where = ['1=1'];
    const params = { limit: p.limit, offset: p.offset };
    if (q.status !== 'all') { where.push('r.status = :st'); params.st = q.status; }
    if (q.userId) { where.push('(r.sender_id = :uid OR r.receiver_id = :uid)'); params.uid = q.userId; }
    if (q.search) {
      where.push('(s.full_name LIKE :q OR t.full_name LIKE :q OR s.phone LIKE :q OR t.phone LIKE :q OR r.message LIKE :q)');
      params.q = like(q.search);
    }
    const from = 'FROM connection_requests r JOIN users s ON s.id = r.sender_id JOIN users t ON t.id = r.receiver_id';
    const w = where.join(' AND ');
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total ${from} WHERE ${w}`, params);
    const rows = await db.query(
      `SELECT r.id, r.status, r.message, r.created_at, r.responded_at, ${memberCols('s', 's')}, ${memberCols('t', 't')}
         ${from} WHERE ${w} ORDER BY r.created_at DESC, r.id DESC LIMIT :limit OFFSET :offset`,
      params,
    );
    okList(
      res,
      rows.map((r) => ({
        id: r.id, status: r.status, message: r.message, createdAt: r.created_at, respondedAt: r.responded_at,
        sender: member(r, 's'), receiver: member(r, 't'),
      })),
      p,
      total,
      Number(total) ? 'Connection requests fetched successfully.' : 'No connection requests match these filters.',
    );
  }),
);

// PATCH /admin/connection-requests/:id/cancel — e.g. spam or a reported message
router.patch(
  '/connection-requests/:id/cancel',
  idParam,
  ah(async (req, res) => {
    const r = await db.one('SELECT * FROM connection_requests WHERE id = :id', { id: req.params.id });
    if (!r) throw errors.notFound('Request');
    if (r.status !== 'pending') throw new ApiError(409, 'REQUEST_CLOSED', `This request was already ${r.status}.`, { status: r.status });
    await db.query("UPDATE connection_requests SET status = 'withdrawn', responded_at = UTC_TIMESTAMP() WHERE id = :id", { id: r.id });
    await N.events.requestWithdrawn(r, 'request_cancelled_by_admin');
    ok(res, { id: r.id, status: 'withdrawn' }, 'Request cancelled. It no longer appears in either member\'s Inbox.');
  }),
);

// GET /admin/connections
router.get(
  '/connections',
  validate(listQuery, 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const p = paging(q);
    const where = ['1=1'];
    const params = { limit: p.limit, offset: p.offset };
    if (q.userId) { where.push('(c.user_a_id = :uid OR c.user_b_id = :uid)'); params.uid = q.userId; }
    if (q.search) { where.push('(a.full_name LIKE :q OR b.full_name LIKE :q OR a.phone LIKE :q OR b.phone LIKE :q)'); params.q = like(q.search); }
    const from = 'FROM connections c JOIN users a ON a.id = c.user_a_id JOIN users b ON b.id = c.user_b_id';
    const w = where.join(' AND ');
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total ${from} WHERE ${w}`, params);
    const rows = await db.query(
      `SELECT c.created_at, c.request_id, ${memberCols('a', 'a')}, ${memberCols('b', 'b')}
         ${from} WHERE ${w} ORDER BY c.created_at DESC LIMIT :limit OFFSET :offset`,
      params,
    );
    okList(
      res,
      rows.map((r) => ({ userA: member(r, 'a'), userB: member(r, 'b'), connectedAt: r.created_at, requestId: r.request_id })),
      p,
      total,
      Number(total) ? 'Connections fetched successfully.' : 'No connections match these filters.',
    );
  }),
);

// DELETE /admin/connections/:userAId/:userBId
router.delete(
  '/connections/:userAId/:userBId',
  validate(z.object({ userAId: z.coerce.number().int().positive(), userBId: z.coerce.number().int().positive() }), 'params'),
  ah(async (req, res) => {
    const x = Number(req.params.userAId);
    const y = Number(req.params.userBId);
    const [a, b] = x < y ? [x, y] : [y, x];
    const r = await db.query('DELETE FROM connections WHERE user_a_id = :a AND user_b_id = :b', { a, b });
    if (!r.affectedRows) throw errors.notFound('Connection');
    await N.events.connectionRemoved(a, b);
    ok(res, { userAId: a, userBId: b, removed: true }, 'Connection removed.');
  }),
);

/** Networking block for /admin/stats. */
async function networkStats() {
  const num = (v) => Number(v || 0);
  const r = await db.one(`
    SELECT
      (SELECT COUNT(*) FROM connections) AS connections,
      (SELECT COUNT(*) FROM connections WHERE created_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS newConnections7d,
      (SELECT COUNT(*) FROM connection_requests) AS requests,
      (SELECT COUNT(*) FROM connection_requests WHERE status = 'pending') AS pending,
      (SELECT COUNT(*) FROM connection_requests WHERE status = 'accepted') AS accepted,
      (SELECT COUNT(*) FROM connection_requests WHERE status = 'declined') AS declined,
      (SELECT COUNT(*) FROM connection_requests WHERE status = 'withdrawn') AS withdrawn,
      (SELECT COUNT(*) FROM saved_profiles) AS bookmarks,
      (SELECT COUNT(*) FROM users WHERE onboarding_step >= 7 AND open_to_connect = 0) AS notOpenToConnect,
      (SELECT COUNT(*) FROM users WHERE onboarding_step >= 7 AND nearby_discovery = 0) AS hiddenFromDiscovery`);
  const daily = await db.query(`
    SELECT DATE(created_at) AS day, COUNT(*) AS requests, SUM(status = 'accepted') AS accepted
      FROM connection_requests WHERE created_at >= UTC_DATE() - INTERVAL 13 DAY
     GROUP BY DATE(created_at) ORDER BY day`);
  const answered = num(r.accepted) + num(r.declined);
  return {
    connections: num(r.connections),
    newConnections7d: num(r.newConnections7d),
    requests: { total: num(r.requests), pending: num(r.pending), accepted: num(r.accepted), declined: num(r.declined), withdrawn: num(r.withdrawn) },
    acceptanceRate: answered ? Math.round((num(r.accepted) / answered) * 100) : null,
    bookmarks: num(r.bookmarks),
    notOpenToConnect: num(r.notOpenToConnect),
    hiddenFromDiscovery: num(r.hiddenFromDiscovery),
    requestsByDay: daily.map((d) => ({
      day: d.day instanceof Date ? d.day.toISOString().slice(0, 10) : String(d.day).slice(0, 10),
      requests: num(d.requests),
      accepted: num(d.accepted),
    })),
  };
}

/** Networking summary for one member (user drawer). */
async function userNetwork(userId) {
  const num = (v) => Number(v || 0);
  const c = await db.one(
    `SELECT
       (SELECT COUNT(*) FROM connections WHERE user_a_id = :u OR user_b_id = :u) AS connections,
       (SELECT COUNT(*) FROM connection_requests WHERE sender_id = :u) AS sent,
       (SELECT COUNT(*) FROM connection_requests WHERE sender_id = :u AND status = 'accepted') AS sentAccepted,
       (SELECT COUNT(*) FROM connection_requests WHERE sender_id = :u AND status = 'pending') AS sentPending,
       (SELECT COUNT(*) FROM connection_requests WHERE receiver_id = :u) AS received,
       (SELECT COUNT(*) FROM connection_requests WHERE receiver_id = :u AND status = 'pending') AS receivedPending,
       (SELECT COUNT(*) FROM connection_requests WHERE sender_id = :u AND created_at > UTC_TIMESTAMP() - INTERVAL 1 DAY) AS sentLast24h,
       (SELECT COUNT(*) FROM saved_profiles WHERE user_id = :u) AS saved,
       (SELECT COUNT(*) FROM saved_profiles WHERE saved_user_id = :u) AS savedBy`,
    { u: userId },
  );
  const recent = await db.query(
    `SELECT o.id, o.full_name, o.job_title, o.photo_path, c.created_at
       FROM connections c JOIN users o ON o.id = IF(c.user_a_id = :u, c.user_b_id, c.user_a_id)
      WHERE c.user_a_id = :u OR c.user_b_id = :u ORDER BY c.created_at DESC LIMIT 5`,
    { u: userId },
  );
  return {
    connections: num(c.connections),
    requestsSent: { total: num(c.sent), accepted: num(c.sentAccepted), pending: num(c.sentPending), last24h: num(c.sentLast24h) },
    requestsReceived: { total: num(c.received), pending: num(c.receivedPending) },
    saved: num(c.saved),
    savedBy: num(c.savedBy),
    recentConnections: recent.map((r) => ({ id: r.id, fullName: r.full_name, jobTitle: r.job_title, photoUrl: fileUrl(r.photo_path), connectedAt: r.created_at })),
  };
}

module.exports = { router, networkStats, userNetwork };
