/**
 * In-app notifications: stored in `notifications`, delivered live over Socket.IO
 * (and later via push — see services/push.js).
 */
const db = require('../config/db');
const env = require('../config/env');
const realtime = require('../realtime');
const push = require('./push');
const { fileUrl } = require('../utils/format');

const TYPES = {
  requestReceived: 'connection_request.received',
  requestAccepted: 'connection_request.accepted',
};

const parse = (v) => (typeof v === 'string' ? JSON.parse(v) : v || {});
const firstName = (n) => String(n || 'Someone').split(/\s+/)[0];

function view(r) {
  return {
    id: r.id,
    type: r.type,
    title: r.title,
    body: r.body,
    data: parse(r.data),
    actor: r.actor_id ? { id: r.actor_id, fullName: r.actor_name, photoUrl: fileUrl(r.actor_photo) } : null,
    isRead: Boolean(r.read_at),
    readAt: r.read_at,
    createdAt: r.created_at,
  };
}

const SELECT = `SELECT n.*, a.full_name AS actor_name, a.photo_path AS actor_photo
  FROM notifications n LEFT JOIN users a ON a.id = n.actor_id`;

async function unreadCount(userId) {
  const [{ n }] = await db.query('SELECT COUNT(*) AS n FROM notifications WHERE user_id = :u AND read_at IS NULL', { u: userId });
  return Number(n);
}

/** Counts behind the Inbox badge and chips. */
async function inboxSummary(userId) {
  const [row] = await db.query(
    `SELECT
       (SELECT COUNT(*) FROM connection_requests r JOIN users u ON u.id = r.sender_id WHERE r.receiver_id = :me AND r.status = 'pending' AND u.status = 'active') AS received,
       (SELECT COUNT(*) FROM connection_requests r JOIN users u ON u.id = r.receiver_id WHERE r.sender_id = :me AND r.status = 'pending' AND u.status = 'active') AS sent,
       (SELECT COUNT(*) FROM connections c WHERE c.user_a_id = :me OR c.user_b_id = :me) AS connections,
       (SELECT COUNT(*) FROM connections c WHERE (c.user_a_id = :me OR c.user_b_id = :me) AND c.created_at > UTC_TIMESTAMP() - INTERVAL :days DAY) AS newConnections,
       (SELECT COUNT(*) FROM notifications n WHERE n.user_id = :me AND n.read_at IS NULL) AS unread`,
    { me: userId, days: env.rules.newConnectionDays },
  );
  const received = Number(row.received);
  return {
    requests: { received, sent: Number(row.sent) },
    connections: { total: Number(row.connections), new: Number(row.newConnections) },
    notifications: { unread: Number(row.unread) },
    messages: { unread: await require('./chat').totalUnread(userId) },
    showBadge: received > 0,
  };
}

/** Store a notification, push it to the user's open apps, and hand it to push (later). */
async function create(userId, { type, title, body, data = {}, actorId = null }) {
  const r = await db.query(
    'INSERT INTO notifications (user_id, type, title, body, data, actor_id) VALUES (:u, :t, :ti, :b, :d, :a)',
    { u: userId, t: type, ti: title, b: body, d: JSON.stringify(data), a: actorId },
  );
  const n = view(await db.one(`${SELECT} WHERE n.id = :id`, { id: r.insertId }));
  realtime.emitToUser(userId, 'notification', n);
  await push.send(userId, n).catch(() => {});
  return n;
}

/** Tell a user's open apps to refresh the Inbox silently. */
async function inboxUpdated(userId, reason) {
  realtime.emitToUser(userId, 'inbox:updated', { reason, inbox: await inboxSummary(userId) });
}

/** Drop the "new request" notification once that request is gone (withdrawn / cancelled). */
async function removeRequestNotification(userId, requestId) {
  const rows = await db.query(
    "SELECT id FROM notifications WHERE user_id = :u AND type = :t AND JSON_EXTRACT(data, '$.requestId') = :r",
    { u: userId, t: TYPES.requestReceived, r: requestId },
  );
  if (!rows.length) return;
  const ids = rows.map((x) => x.id);
  await db.query('DELETE FROM notifications WHERE id IN (:ids)', { ids });
  realtime.emitToUser(userId, 'notification:removed', { ids });
}

/** Mark the "new request" notification read once the receiver has answered it. */
async function markRequestNotificationRead(userId, requestId) {
  await db.query(
    "UPDATE notifications SET read_at = UTC_TIMESTAMP() WHERE user_id = :u AND type = :t AND read_at IS NULL AND JSON_EXTRACT(data, '$.requestId') = :r",
    { u: userId, t: TYPES.requestReceived, r: requestId },
  );
}

/**
 * Side effects of connection events. Never throws — a failed notification must not
 * fail the request that caused it.
 */
const events = {
  async requestSent(request, sender) {
    await safe(async () => {
      await create(request.receiver_id, {
        type: TYPES.requestReceived,
        title: 'New connection request',
        body: request.message
          ? `${sender.full_name || 'Someone'}: “${request.message.slice(0, 120)}”`
          : `${sender.full_name || 'Someone'} wants to connect with you.`,
        data: { requestId: request.id, userId: sender.id, screen: 'inbox.requests.received' },
        actorId: sender.id,
      });
      await inboxUpdated(request.receiver_id, 'request_received');
      await inboxUpdated(request.sender_id, 'request_sent');
    });
  },
  async requestAccepted(request, receiver) {
    await safe(async () => {
      await markRequestNotificationRead(request.receiver_id, request.id);
      await create(request.sender_id, {
        type: TYPES.requestAccepted,
        title: 'Request accepted',
        body: `${firstName(receiver.full_name)} accepted your connection request. Say hello!`,
        data: { requestId: request.id, userId: receiver.id, screen: 'inbox.connections' },
        actorId: receiver.id,
      });
      await inboxUpdated(request.sender_id, 'request_accepted');
      await inboxUpdated(request.receiver_id, 'request_accepted');
    });
  },
  async requestDeclined(request) {
    await safe(async () => {
      await markRequestNotificationRead(request.receiver_id, request.id);
      await inboxUpdated(request.sender_id, 'request_declined'); // silent — no notification for a decline
      await inboxUpdated(request.receiver_id, 'request_declined');
    });
  },
  async requestWithdrawn(request, reason = 'request_withdrawn') {
    await safe(async () => {
      await removeRequestNotification(request.receiver_id, request.id);
      await inboxUpdated(request.receiver_id, reason);
      await inboxUpdated(request.sender_id, reason);
    });
  },
  async connectionRemoved(a, b) {
    await safe(async () => {
      await inboxUpdated(a, 'connection_removed');
      await inboxUpdated(b, 'connection_removed');
    });
  },
};

async function safe(fn) {
  try {
    await fn();
  } catch (e) {
    console.error('[notifications]', e.message);
  }
}

module.exports = { TYPES, SELECT, view, create, unreadCount, inboxSummary, inboxUpdated, events };
