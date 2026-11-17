/**
 * In-app notifications (bell / notification list).
 *   GET    /notifications               ?unreadOnly=true&page=&limit=   (+ data.unreadCount)
 *   GET    /notifications/unread-count
 *   PATCH  /notifications/read-all
 *   PATCH  /notifications/:id/read
 *   DELETE /notifications/:id
 * Live delivery happens over Socket.IO (see src/realtime) — these endpoints cover
 * anything that arrived while the app was closed.
 */
const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { ah, ok, okList, errors, paging } = require('../../utils/http');
const { requireUser, validate, idParam } = require('../../middleware');
const N = require('../../services/notifications');

const router = express.Router();
router.use(requireUser);

router.get(
  '/',
  validate(z.object({
    unreadOnly: z.enum(['true', 'false', '1', '0']).optional().transform((v) => v === 'true' || v === '1'),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const p = paging(q);
    const where = `n.user_id = :u ${q.unreadOnly ? 'AND n.read_at IS NULL' : ''}`;
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total FROM notifications n WHERE ${where}`, { u: req.user.id });
    const rows = await db.query(`${N.SELECT} WHERE ${where} ORDER BY n.created_at DESC, n.id DESC LIMIT :limit OFFSET :offset`, {
      u: req.user.id, limit: p.limit, offset: p.offset,
    });
    const unreadCount = await N.unreadCount(req.user.id);
    okList(res, rows.map(N.view), p, total, Number(total) ? 'Notifications fetched successfully.' : "You're all caught up.", { unreadCount });
  }),
);

router.get('/unread-count', ah(async (req, res) => {
  const unreadCount = await N.unreadCount(req.user.id);
  ok(res, { unreadCount }, unreadCount ? `You have ${unreadCount} unread notification${unreadCount === 1 ? '' : 's'}.` : 'No unread notifications.');
}));

router.patch('/read-all', ah(async (req, res) => {
  const r = await db.query('UPDATE notifications SET read_at = UTC_TIMESTAMP() WHERE user_id = :u AND read_at IS NULL', { u: req.user.id });
  ok(res, { updated: r.affectedRows, unreadCount: 0 }, 'All notifications marked as read.');
}));

router.patch('/:id/read', idParam, ah(async (req, res) => {
  const n = await db.one('SELECT id FROM notifications WHERE id = :id AND user_id = :u', { id: req.params.id, u: req.user.id });
  if (!n) throw errors.notFound('Notification');
  await db.query('UPDATE notifications SET read_at = COALESCE(read_at, UTC_TIMESTAMP()) WHERE id = :id', { id: n.id });
  ok(res, { id: n.id, isRead: true, unreadCount: await N.unreadCount(req.user.id) }, 'Notification marked as read.');
}));

router.delete('/:id', idParam, ah(async (req, res) => {
  const r = await db.query('DELETE FROM notifications WHERE id = :id AND user_id = :u', { id: req.params.id, u: req.user.id });
  if (!r.affectedRows) throw errors.notFound('Notification');
  ok(res, { id: Number(req.params.id), deleted: true, unreadCount: await N.unreadCount(req.user.id) }, 'Notification removed.');
}));

module.exports = router;
