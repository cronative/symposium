/**
 * Send Connection Request · Inbox (Requests received / sent, Connections).
 *   POST   /connections/requests              send   { userId, message? }
 *   GET    /connections/requests              ?direction=received|sent&status=pending|all
 *   POST   /connections/requests/:id/accept   receiver
 *   POST   /connections/requests/:id/decline  receiver
 *   DELETE /connections/requests/:id          sender withdraws
 *   GET    /connections                       ?search=
 *   DELETE /connections/:userId               remove a connection
 *   GET    /inbox/summary                     badge counts
 */
const express = require('express');
const { z } = require('zod');
const env = require('../../config/env');
const db = require('../../config/db');
const { ApiError, ah, ok, created, okList, errors, paging } = require('../../utils/http');
const { requireUser, requireOnboarded, validate, idParam } = require('../../middleware');
const P = require('../../services/people');
const N = require('../../services/notifications');

const router = express.Router();
router.use(['/connections', '/inbox'], requireUser, requireOnboarded);

const requestRow = (r) => ({
  id: r.id,
  status: r.status,
  message: r.message,
  createdAt: r.created_at,
  respondedAt: r.responded_at,
});

async function decorateRequests(me, rows) {
  const otherIds = rows.map((r) => (r.sender_id === me.id ? r.receiver_id : r.sender_id));
  const cards = await P.cardsByIds(me, [...new Set(otherIds)]);
  const byId = new Map(cards.map((c) => [c.id, c]));
  return rows.map((r, i) => ({
    ...requestRow(r),
    direction: r.sender_id === me.id ? 'sent' : 'received',
    user: byId.get(otherIds[i]) || null,
  }));
}

// POST /connections/requests — Send Connection Request
router.post(
  '/connections/requests',
  validate(z.object({
    userId: z.coerce.number().int().positive(),
    message: z.string().trim().max(env.rules.requestMessageMax, `Keep your message under ${env.rules.requestMessageMax} characters.`).optional().nullable(),
  })),
  ah(async (req, res) => {
    const me = req.user;
    const { userId, message } = req.body;
    if (userId === me.id) throw errors.badRequest('CANNOT_CONNECT_SELF', 'You cannot send a request to yourself.');
    const target = await db.one('SELECT * FROM users WHERE id = :id', { id: userId });
    if (!(await P.canView(me, target))) throw errors.notFound('Member');

    const rel = (await P.relationMap(me.id, [userId])).get(userId);
    if (rel.status === 'connected') throw errors.conflict('ALREADY_CONNECTED', 'You are already connected.');
    if (rel.status === 'pending_sent') throw new ApiError(409, 'REQUEST_ALREADY_SENT', 'You have already sent a request to this member.', { requestId: rel.requestId });
    if (rel.status === 'pending_received') {
      throw new ApiError(409, 'REQUEST_RECEIVED', 'This member has already sent you a request. Accept it from your Inbox.', { requestId: rel.requestId });
    }
    if (!target.open_to_connect) throw new ApiError(403, 'NOT_ACCEPTING_REQUESTS', 'This member is not accepting new connections right now.');

    const [{ sent }] = await db.query(
      'SELECT COUNT(*) AS sent FROM connection_requests WHERE sender_id = :me AND created_at > UTC_TIMESTAMP() - INTERVAL 1 DAY',
      { me: me.id },
    );
    if (Number(sent) >= env.rules.maxRequestsPerDay) {
      throw errors.tooMany('DAILY_REQUEST_LIMIT', `You can send up to ${env.rules.maxRequestsPerDay} requests a day. Try again tomorrow.`);
    }

    let id;
    try {
      const r = await db.query('INSERT INTO connection_requests (sender_id, receiver_id, message) VALUES (:me, :to, :m)', { me: me.id, to: userId, m: message || null });
      id = r.insertId;
    } catch (e) {
      if (e.code === 'ER_DUP_ENTRY') throw errors.conflict('REQUEST_ALREADY_SENT', 'A request between you two is already pending.');
      throw e;
    }
    const row = await db.one('SELECT * FROM connection_requests WHERE id = :id', { id });
    await N.events.requestSent(row, me);
    const [item] = await decorateRequests(me, [row]);
    created(res, item, `Connection request sent to ${(target.full_name || 'this member').split(/\s+/)[0]}.`);
  }),
);

// GET /connections/requests — Inbox › Requests (Received / Sent)
router.get(
  '/connections/requests',
  validate(z.object({
    direction: z.enum(['received', 'sent']).optional().default('received'),
    status: z.enum(['pending', 'all']).optional().default('pending'),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const pg = paging(q);
    const col = q.direction === 'received' ? 'receiver_id' : 'sender_id';
    const other = q.direction === 'received' ? 'sender_id' : 'receiver_id';
    const where = `r.${col} = :me ${q.status === 'pending' ? "AND r.status = 'pending'" : ''} AND u.status = 'active'`;
    const from = `FROM connection_requests r JOIN users u ON u.id = r.${other}`;
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total ${from} WHERE ${where}`, { me: req.user.id });
    const rows = await db.query(`SELECT r.* ${from} WHERE ${where} ORDER BY r.created_at DESC, r.id DESC LIMIT :limit OFFSET :offset`, {
      me: req.user.id, limit: pg.limit, offset: pg.offset,
    });
    okList(res, await decorateRequests(req.user, rows), pg, total, Number(total) ? 'Requests fetched successfully.' : q.direction === 'received' ? "You're all caught up. No new requests." : 'No pending requests sent.');
  }),
);

/** Load a pending request the current user may act on. */
async function pendingFor(conn, requestId, userId, as) {
  const r = await db.one('SELECT * FROM connection_requests WHERE id = :id FOR UPDATE', { id: requestId }, conn);
  if (!r || r[as === 'receiver' ? 'receiver_id' : 'sender_id'] !== userId) throw errors.notFound('Request');
  if (r.status !== 'pending') throw new ApiError(409, 'REQUEST_CLOSED', `This request was already ${r.status}.`, { status: r.status });
  return r;
}

// POST /connections/requests/:id/accept
router.post(
  '/connections/requests/:id/accept',
  idParam,
  ah(async (req, res) => {
    const me = req.user;
    const r = await db.tx(async (conn) => {
      const row = await pendingFor(conn, Number(req.params.id), me.id, 'receiver');
      await db.query("UPDATE connection_requests SET status = 'accepted', responded_at = UTC_TIMESTAMP() WHERE id = :id", { id: row.id }, conn);
      const [a, b] = P.pair(row.sender_id, row.receiver_id);
      await db.query('INSERT IGNORE INTO connections (user_a_id, user_b_id, request_id) VALUES (:a, :b, :r)', { a, b, r: row.id }, conn);
      return db.one('SELECT * FROM connection_requests WHERE id = :id', { id: row.id }, conn);
    });
    await N.events.requestAccepted(r, me);
    const [item] = await decorateRequests(me, [r]);
    ok(res, item, `You're now connected with ${(item.user?.fullName || 'this member').split(/\s+/)[0]}.`);
  }),
);

// POST /connections/requests/:id/decline
router.post(
  '/connections/requests/:id/decline',
  idParam,
  ah(async (req, res) => {
    const r = await db.tx(async (conn) => {
      const row = await pendingFor(conn, Number(req.params.id), req.user.id, 'receiver');
      await db.query("UPDATE connection_requests SET status = 'declined', responded_at = UTC_TIMESTAMP() WHERE id = :id", { id: row.id }, conn);
      return db.one('SELECT * FROM connection_requests WHERE id = :id', { id: row.id }, conn);
    });
    await N.events.requestDeclined(r);
    ok(res, requestRow(r), 'Request declined.');
  }),
);

// DELETE /connections/requests/:id — sender withdraws a pending request
router.delete(
  '/connections/requests/:id',
  idParam,
  ah(async (req, res) => {
    const r = await db.tx(async (conn) => {
      const row = await pendingFor(conn, Number(req.params.id), req.user.id, 'sender');
      await db.query("UPDATE connection_requests SET status = 'withdrawn', responded_at = UTC_TIMESTAMP() WHERE id = :id", { id: row.id }, conn);
      return db.one('SELECT * FROM connection_requests WHERE id = :id', { id: row.id }, conn);
    });
    await N.events.requestWithdrawn(r);
    ok(res, requestRow(r), 'Request withdrawn.');
  }),
);

// GET /connections — Inbox › My Connections (newest first, "New" badge for recent ones)
router.get(
  '/connections',
  validate(z.object({
    search: z.string().trim().max(60).optional(),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const pg = paging(q);
    const params = { me: req.user.id };
    let where = "(c.user_a_id = :me OR c.user_b_id = :me) AND u.status = 'active'";
    if (q.search) {
      where += ' AND (u.full_name LIKE :q OR u.job_title LIKE :q OR u.company LIKE :q)';
      params.q = `%${q.search.replace(/[%_]/g, '\\$&')}%`;
    }
    const from = 'FROM connections c JOIN users u ON u.id = IF(c.user_a_id = :me, c.user_b_id, c.user_a_id)';
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total ${from} WHERE ${where}`, params);
    const rows = await db.query(
      `SELECT u.id, c.created_at ${from} WHERE ${where} ORDER BY c.created_at DESC, u.full_name LIMIT :limit OFFSET :offset`,
      { ...params, limit: pg.limit, offset: pg.offset },
    );
    const cards = await P.cardsByIds(req.user, rows.map((r) => r.id));
    const cutoff = Date.now() - env.rules.newConnectionDays * 86_400_000;
    const data = cards.map((c) => ({ ...c, connectedAt: c.connection.connectedAt, isNew: new Date(c.connection.connectedAt).getTime() > cutoff }));
    okList(res, data, pg, total, Number(total) ? 'Connections fetched successfully.' : q.search ? 'No connections match your search.' : 'No connections yet. Start by sending a request from KYN.');
  }),
);

// DELETE /connections/:userId — remove a connection
router.delete(
  '/connections/:id',
  idParam,
  ah(async (req, res) => {
    const [a, b] = P.pair(req.user.id, Number(req.params.id));
    const r = await db.query('DELETE FROM connections WHERE user_a_id = :a AND user_b_id = :b', { a, b });
    if (!r.affectedRows) throw errors.notFound('Connection');
    await N.events.connectionRemoved(a, b);
    ok(res, { userId: Number(req.params.id), removed: true }, 'Connection removed.');
  }),
);

// GET /inbox/summary — counts for the tab badge, Inbox chips and the bell
router.get(
  '/inbox/summary',
  ah(async (req, res) => ok(res, await N.inboxSummary(req.user.id), 'Inbox summary fetched successfully.')),
);

module.exports = router;
