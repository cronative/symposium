/**
 * 1:1 chat between connected members.
 * A pair has at most one conversation (user_a_id < user_b_id). Read state is the highest
 * message id each side has seen, so "unread" = newer messages written by the other side.
 */
const db = require('../config/db');
const P = require('./people');
const realtime = require('../realtime');
const { errors } = require('../utils/http');
const { fileUrl } = require('../utils/format');

const isA = (c, me) => c.user_a_id === me;
const otherOf = (c, me) => (isA(c, me) ? c.user_b_id : c.user_a_id);
const myReadOf = (c, me) => Number(isA(c, me) ? c.a_last_read_id : c.b_last_read_id);
const theirReadOf = (c, me) => Number(isA(c, me) ? c.b_last_read_id : c.a_last_read_id);

function messageView(m, me) {
  return {
    id: m.id,
    conversationId: m.conversation_id,
    senderId: m.sender_id,
    body: m.body,
    clientId: m.client_id || null,
    createdAt: m.created_at,
    isMine: m.sender_id === me,
  };
}

async function isConnected(x, y) {
  const [a, b] = P.pair(x, y);
  return Boolean(await db.one('SELECT 1 AS x FROM connections WHERE user_a_id = :a AND user_b_id = :b', { a, b }));
}

/** The conversation with another member, created on first use. */
async function getOrCreate(me, otherId) {
  const [a, b] = P.pair(me, otherId);
  await db.query('INSERT IGNORE INTO conversations (user_a_id, user_b_id) VALUES (:a, :b)', { a, b });
  return db.one('SELECT * FROM conversations WHERE user_a_id = :a AND user_b_id = :b', { a, b });
}

/** A conversation the member is part of (404 otherwise). */
async function forMember(id, me) {
  const c = await db.one('SELECT * FROM conversations WHERE id = :id AND (user_a_id = :me OR user_b_id = :me)', { id, me });
  if (!c) throw errors.notFound('Conversation');
  return c;
}

async function unreadIn(c, me) {
  const [{ n }] = await db.query('SELECT COUNT(*) AS n FROM messages WHERE conversation_id = :c AND sender_id <> :me AND id > :r', { c: c.id, me, r: myReadOf(c, me) });
  return Number(n);
}

/** Unread messages across all conversations (Inbox › Messages badge). */
async function totalUnread(me) {
  const [{ n }] = await db.query(
    `SELECT COUNT(*) AS n FROM messages m
       JOIN conversations c ON c.id = m.conversation_id
       JOIN users u ON u.id = m.sender_id AND u.status = 'active'
      WHERE m.sender_id <> :me
        AND ((c.user_a_id = :me AND m.id > c.a_last_read_id) OR (c.user_b_id = :me AND m.id > c.b_last_read_id))`,
    { me },
  );
  return Number(n);
}

/** Small fallback when the other member's card isn't visible any more (e.g. blocked). */
async function basicUser(id) {
  const u = await db.one('SELECT id, full_name, photo_path FROM users WHERE id = :id', { id });
  if (!u) return null;
  return { id: u.id, fullName: u.full_name || 'SyyncIn member', photoUrl: fileUrl(u.photo_path), initials: P.initials(u.full_name), connection: { status: 'none' } };
}

/** Build list/detail items for conversation rows (one query each for cards, last messages, unread). */
async function views(meUser, rows) {
  if (!rows.length) return [];
  const me = meUser.id;
  const otherIds = rows.map((c) => otherOf(c, me));
  const lastIds = rows.map((c) => c.last_message_id).filter(Boolean);
  const [cards, lasts, unread] = await Promise.all([
    P.cardsByIds(meUser, [...new Set(otherIds)]),
    lastIds.length ? db.query('SELECT * FROM messages WHERE id IN (:ids)', { ids: lastIds }) : [],
    db.query(
      `SELECT c.id, COUNT(m.id) AS n FROM conversations c
         JOIN messages m ON m.conversation_id = c.id AND m.sender_id <> :me
          AND m.id > IF(c.user_a_id = :me, c.a_last_read_id, c.b_last_read_id)
        WHERE c.id IN (:ids) GROUP BY c.id`,
      { me, ids: rows.map((c) => c.id) },
    ),
  ]);
  const cardById = new Map(cards.map((c) => [c.id, c]));
  const lastById = new Map(lasts.map((m) => [m.id, m]));
  const unreadById = new Map(unread.map((r) => [r.id, Number(r.n)]));
  return Promise.all(rows.map(async (c, i) => {
    const user = cardById.get(otherIds[i]) || (await basicUser(otherIds[i]));
    const last = lastById.get(c.last_message_id);
    return {
      id: c.id,
      user,
      lastMessage: last ? messageView(last, me) : null,
      lastMessageAt: c.last_message_at,
      unreadCount: unreadById.get(c.id) || 0,
      myLastReadId: myReadOf(c, me),
      otherLastReadId: theirReadOf(c, me),
      canSend: user?.connection?.status === 'connected',
    };
  }));
}

const view = async (meUser, c) => (await views(meUser, [c]))[0];

/** Store a message and deliver it live to both members' open apps. */
async function send(meUser, c, body, clientId) {
  const me = meUser.id;
  const other = otherOf(c, me);
  if (!(await isConnected(me, other))) throw errors.forbidden('You can only message your connections.');
  if (clientId) {
    const dup = await db.one('SELECT * FROM messages WHERE sender_id = :me AND client_id = :cid', { me, cid: clientId });
    if (dup) return { message: dup, duplicate: true };
  }
  let id;
  try {
    id = (await db.query('INSERT INTO messages (conversation_id, sender_id, body, client_id) VALUES (:c, :me, :b, :cid)', { c: c.id, me, b: body, cid: clientId || null })).insertId;
  } catch (e) {
    if (e.code !== 'ER_DUP_ENTRY') throw e;
    return { message: await db.one('SELECT * FROM messages WHERE sender_id = :me AND client_id = :cid', { me, cid: clientId }), duplicate: true };
  }
  const col = isA(c, me) ? 'a_last_read_id' : 'b_last_read_id';
  await db.query(`UPDATE conversations SET last_message_id = :id, last_message_at = UTC_TIMESTAMP(), ${col} = :id WHERE id = :c`, { id, c: c.id });
  const message = await db.one('SELECT * FROM messages WHERE id = :id', { id });
  const fresh = await db.one('SELECT * FROM conversations WHERE id = :id', { id: c.id });
  try {
    realtime.emitToUser(other, 'message:new', {
      conversationId: c.id,
      message: messageView(message, other),
      unreadCount: await unreadIn(fresh, other),
      totalUnread: await totalUnread(other),
      sender: { id: me, fullName: meUser.full_name, photoUrl: fileUrl(meUser.photo_path), initials: P.initials(meUser.full_name) },
    });
    realtime.emitToUser(me, 'message:new', { conversationId: c.id, message: messageView(message, me), unreadCount: 0, totalUnread: await totalUnread(me) });
  } catch (e) {
    console.error('[chat] live delivery failed', e.message);
  }
  return { message, duplicate: false };
}

/** Mark messages up to `upTo` (default: latest) as read and tell the other side (✓✓). */
async function markRead(me, c, upTo) {
  const last = Number(c.last_message_id || 0);
  const target = Math.min(upTo ? Number(upTo) : last, last);
  const col = isA(c, me) ? 'a_last_read_id' : 'b_last_read_id';
  const before = myReadOf(c, me);
  if (target > before) {
    await db.query(`UPDATE conversations SET ${col} = GREATEST(${col}, :t) WHERE id = :c`, { t: target, c: c.id });
  }
  const fresh = await db.one('SELECT * FROM conversations WHERE id = :id', { id: c.id });
  const lastReadId = myReadOf(fresh, me);
  const result = { conversationId: c.id, lastReadId, unreadCount: await unreadIn(fresh, me), totalUnread: await totalUnread(me) };
  if (lastReadId > before) {
    realtime.emitToUser(otherOf(c, me), 'message:read', { conversationId: c.id, readerId: me, lastReadId });
    realtime.emitToUser(me, 'chat:read', result);
  }
  return result;
}

module.exports = { messageView, isConnected, getOrCreate, forMember, otherOf, totalUnread, views, view, send, markRead };
