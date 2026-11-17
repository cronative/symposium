/**
 * 1:1 chat (text) between connected members.
 *   GET   /chats                         conversation list (latest first) ?search=
 *   POST  /chats                         open the chat with a connection { userId }
 *   GET   /chats/:id                     one conversation
 *   GET   /chats/:id/messages            ?before=<id> (older page) | ?after=<id> (catch up) &limit=
 *   POST  /chats/:id/messages            send { body, clientId? }
 *   POST  /chats/:id/read                mark read { messageId? }
 * Realtime: message:new · message:read · chat:read · typing (see src/realtime/index.js).
 */
const express = require('express');
const { z } = require('zod');
const env = require('../../config/env');
const db = require('../../config/db');
const { ApiError, ah, ok, created, okList, errors, paging } = require('../../utils/http');
const { requireUser, requireOnboarded, validate, idParam } = require('../../middleware');
const C = require('../../services/chat');

const router = express.Router();
router.use('/chats', requireUser, requireOnboarded);

// GET /chats — Inbox › Messages
router.get(
  '/chats',
  validate(z.object({
    search: z.string().trim().max(60).optional(),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const pg = paging(q);
    const params = { me: req.user.id };
    let where = "(c.user_a_id = :me OR c.user_b_id = :me) AND c.last_message_id IS NOT NULL AND u.status = 'active'";
    if (q.search) {
      where += ' AND u.full_name LIKE :q';
      params.q = `%${q.search.replace(/[%_]/g, '\\$&')}%`;
    }
    const from = 'FROM conversations c JOIN users u ON u.id = IF(c.user_a_id = :me, c.user_b_id, c.user_a_id)';
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total ${from} WHERE ${where}`, params);
    const rows = await db.query(`SELECT c.* ${from} WHERE ${where} ORDER BY c.last_message_at DESC, c.id DESC LIMIT :limit OFFSET :offset`, { ...params, limit: pg.limit, offset: pg.offset });
    const items = await C.views(req.user, rows);
    okList(res, items, pg, total, Number(total) ? 'Chats fetched successfully.' : q.search ? 'No chats match your search.' : 'No messages yet. Say hi to one of your connections.', {
      totalUnread: await C.totalUnread(req.user.id),
    });
  }),
);

// POST /chats — open (or create) the chat with a connection
router.post(
  '/chats',
  validate(z.object({ userId: z.coerce.number().int().positive() })),
  ah(async (req, res) => {
    const { userId } = req.body;
    if (userId === req.user.id) throw errors.badRequest('CANNOT_CHAT_SELF', 'You cannot message yourself.');
    if (!(await C.isConnected(req.user.id, userId))) throw new ApiError(403, 'NOT_CONNECTED', 'You can only message your connections.');
    const c = await C.getOrCreate(req.user.id, userId);
    ok(res, await C.view(req.user, c), 'Chat opened.');
  }),
);

// GET /chats/:id
router.get(
  '/chats/:id',
  idParam,
  ah(async (req, res) => ok(res, await C.view(req.user, await C.forMember(Number(req.params.id), req.user.id)), 'Chat fetched successfully.')),
);

// GET /chats/:id/messages — oldest → newest within the page
router.get(
  '/chats/:id/messages',
  idParam,
  validate(z.object({
    before: z.coerce.number().int().positive().optional(),
    after: z.coerce.number().int().nonnegative().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const me = req.user.id;
    const c = await C.forMember(Number(req.params.id), me);
    const { before, after } = req.validQuery;
    const limit = req.validQuery.limit || 30;
    let rows;
    if (after !== undefined) {
      rows = await db.query('SELECT * FROM messages WHERE conversation_id = :c AND id > :after ORDER BY id ASC LIMIT :n', { c: c.id, after, n: limit + 1 });
    } else {
      rows = await db.query(
        `SELECT * FROM messages WHERE conversation_id = :c ${before ? 'AND id < :before' : ''} ORDER BY id DESC LIMIT :n`,
        { c: c.id, before, n: limit + 1 },
      );
    }
    const hasMore = rows.length > limit;
    rows = rows.slice(0, limit);
    if (after === undefined) rows.reverse();
    const v = await C.view(req.user, c);
    ok(res, {
      items: rows.map((m) => C.messageView(m, me)),
      hasMore,
      otherLastReadId: v.otherLastReadId,
      canSend: v.canSend,
    }, rows.length ? 'Messages fetched successfully.' : 'No messages yet.');
  }),
);

// POST /chats/:id/messages — send a text message
router.post(
  '/chats/:id/messages',
  idParam,
  validate(z.object({
    body: z.string().trim().min(1, 'Type a message.').max(env.rules.messageMax, `Keep your message under ${env.rules.messageMax} characters.`),
    clientId: z.string().trim().min(1).max(64).optional().nullable(),
  })),
  ah(async (req, res) => {
    const c = await C.forMember(Number(req.params.id), req.user.id);
    if (!(await C.isConnected(req.user.id, C.otherOf(c, req.user.id)))) throw new ApiError(403, 'NOT_CONNECTED', 'You can only message your connections.');
    const { message, duplicate } = await C.send(req.user, c, req.body.body, req.body.clientId);
    const item = C.messageView(message, req.user.id);
    if (duplicate) return ok(res, item, 'Message already sent.');
    created(res, item, 'Message sent.');
  }),
);

// POST /chats/:id/read — mark as read (✓✓ for the sender)
router.post(
  '/chats/:id/read',
  idParam,
  validate(z.object({ messageId: z.coerce.number().int().positive().optional() })),
  ah(async (req, res) => {
    const c = await C.forMember(Number(req.params.id), req.user.id);
    ok(res, await C.markRead(req.user.id, c, req.body.messageId), 'Marked as read.');
  }),
);

module.exports = router;
