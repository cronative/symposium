/**
 * Realtime channel (Socket.IO) — delivers in-app notifications while the app is open.
 *
 * Client: connect to the API host with { path: '/socket.io', auth: { token: '<accessToken>' } }.
 * Each user joins the room `user:<id>`, so every open device of that user gets the events.
 *
 * Server → client events (all payloads are plain objects):
 *   ready              { userId, unreadCount, inbox }             right after connecting
 *   notification       Notification                               show a local notification + add to the list
 *   notification:removed { ids }                                  e.g. the sender withdrew the request
 *   inbox:updated      { reason, inbox }                          silently refresh Inbox lists / badge
 *   message:new        { conversationId, message, unreadCount, totalUnread, sender? }   chat message (also echoed to the sender's other devices)
 *   message:read       { conversationId, readerId, lastReadId }   the other member read up to lastReadId (✓✓)
 *   chat:read          { conversationId, lastReadId, unreadCount, totalUnread }  you read a chat on another device
 *   typing             { conversationId, userId, isTyping }       the other member is typing
 *
 * Client → server events:
 *   typing             { conversationId, isTyping }               forwarded to the other member of that chat
 * Connection errors: err.message = 'TOKEN_INVALID' | 'ACCOUNT_BLOCKED' | 'UNAUTHORIZED' → refresh the token / sign out.
 */
const { Server } = require('socket.io');
const env = require('../config/env');
const db = require('../config/db');
const { verifyAccess } = require('../utils/security');

let io = null;

function authError(code) {
  const err = new Error(code);
  err.data = { code };
  return err;
}

function attach(httpServer) {
  io = new Server(httpServer, {
    path: '/socket.io',
    cors: { origin: env.corsOrigins.includes('*') ? true : env.corsOrigins },
    pingInterval: 25_000,
    pingTimeout: 20_000,
  });

  io.use(async (socket, next) => {
    try {
      const header = socket.handshake.headers.authorization || '';
      const token = socket.handshake.auth?.token || (header.startsWith('Bearer ') ? header.slice(7) : null);
      if (!token) return next(authError('UNAUTHORIZED'));
      let payload;
      try {
        payload = verifyAccess(token);
      } catch {
        return next(authError('TOKEN_INVALID'));
      }
      if (payload.typ !== 'user') return next(authError('UNAUTHORIZED'));
      const user = await db.one('SELECT id, status FROM users WHERE id = :id', { id: Number(payload.sub) });
      if (!user) return next(authError('UNAUTHORIZED'));
      if (user.status === 'blocked') return next(authError('ACCOUNT_BLOCKED'));
      socket.data.userId = user.id;
      next();
    } catch (e) {
      next(e);
    }
  });

  io.on('connection', async (socket) => {
    const userId = socket.data.userId;
    socket.join(`user:${userId}`);
    try {
      // Lazy require avoids a circular import (notifications → realtime).
      const notifications = require('../services/notifications');
      socket.emit('ready', { userId, unreadCount: await notifications.unreadCount(userId), inbox: await notifications.inboxSummary(userId) });
    } catch (e) {
      console.error('[realtime] ready failed', e.message);
    }

    // Typing indicator — only forwarded inside a conversation this user belongs to.
    const partnerOf = new Map(); // conversationId → other member id
    socket.on('typing', async (p) => {
      try {
        const conversationId = Number(p?.conversationId);
        if (!Number.isInteger(conversationId) || conversationId <= 0) return;
        if (!partnerOf.has(conversationId)) {
          const c = await db.one('SELECT user_a_id, user_b_id FROM conversations WHERE id = :id AND (user_a_id = :me OR user_b_id = :me)', { id: conversationId, me: userId });
          partnerOf.set(conversationId, c ? (c.user_a_id === userId ? c.user_b_id : c.user_a_id) : null);
        }
        const other = partnerOf.get(conversationId);
        if (other) emitToUser(other, 'typing', { conversationId, userId, isTyping: Boolean(p.isTyping) });
      } catch (e) {
        console.error('[realtime] typing failed', e.message);
      }
    });
  });

  return io;
}

/** Send an event to every open connection of a user (no-op if nobody is connected). */
function emitToUser(userId, event, payload) {
  if (io) io.to(`user:${userId}`).emit(event, payload);
}

/** Close all sockets of a user (e.g. when an admin blocks them). */
function disconnectUser(userId) {
  if (io) io.in(`user:${userId}`).disconnectSockets(true);
}

async function close() {
  if (io) await new Promise((r) => io.close(() => r()));
}

module.exports = { attach, emitToUser, disconnectUser, close };
