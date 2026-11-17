const mysql = require('mysql2/promise');
const env = require('./env');

const pool = mysql.createPool({
  ...env.db,
  waitForConnections: true,
  namedPlaceholders: true,
  dateStrings: ['DATE'],
  timezone: 'Z',
  charset: 'utf8mb4',
  supportBigNumbers: true,
  decimalNumbers: true,
  // Remote DB (VPS): keep sockets alive and drop idle ones before the server's
  // wait_timeout / firewall silently kills them ("first request after idle → 500").
  // Opening a connection to the remote DB is slow (seconds), so keep a few warm:
  // idle ones live up to 10 min and the warmer below pings them every 30 s,
  // which also stops firewalls/NAT from silently dropping them.
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  maxIdle: 10,
  idleTimeout: 10 * 60 * 1000,
  connectTimeout: 20000,
});

/** Keep WARM_CONNECTIONS ready: open them at start, then ping every 30 s. */
const WARM_CONNECTIONS = Number(process.env.DB_WARM_CONNECTIONS || 4);
const warm = () => Promise.all(Array.from({ length: WARM_CONNECTIONS }, () => pool.query('SELECT 1').catch(() => {})));
if (WARM_CONNECTIONS > 0 && process.env.NODE_ENV !== 'test') {
  setImmediate(warm);
  setInterval(warm, 30 * 1000).unref(); // unref: scripts (migrate, admin:create) still exit
}

/** Errors from a dead socket — safe to retry once on a fresh connection. */
const RETRYABLE = new Set(['PROTOCOL_CONNECTION_LOST', 'ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED', 'ER_CON_COUNT_ERROR']);
const PING_TIMEOUT_MS = 3000;
const withTimeout = (promise, ms) =>
  Promise.race([promise, new Promise((_, reject) => setTimeout(() => reject(Object.assign(new Error('DB ping timed out'), { code: 'ETIMEDOUT' })), ms))]);
const retryable = (e) => RETRYABLE.has(e && e.code) || /closed state|connection lost/i.test((e && e.message) || '');

// All DATETIME values are stored and compared in UTC.
pool.pool.on('connection', (conn) => conn.query("SET time_zone = '+00:00'"));

/** Run a query and return rows. */
async function query(sql, params = {}, conn = pool) {
  try {
    const [rows] = await conn.query(sql, params);
    return rows;
  } catch (e) {
    if (conn !== pool || !retryable(e)) throw e; // never retry inside a transaction
    const [rows] = await pool.query(sql, params);
    return rows;
  }
}

/** Return first row or null. */
async function one(sql, params = {}, conn = pool) {
  const rows = await query(sql, params, conn);
  return rows[0] || null;
}

/** Run fn(conn) inside a transaction. */
async function tx(fn) {
  let conn;
  try {
    conn = await pool.getConnection();
    await withTimeout(conn.ping(), PING_TIMEOUT_MS);
  } catch (e) {
    if (conn) conn.destroy();
    if (!retryable(e)) throw e;
    conn = await pool.getConnection(); // stale socket → take a fresh one
  }
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

module.exports = { pool, query, one, tx };
