const env = require('./config/env');
const app = require('./app');
const { pool } = require('./config/db');
const realtime = require('./realtime');

const server = app.listen(env.port, () => {
  console.log(`SyyncIn API listening on ${env.publicBaseUrl} (${env.nodeEnv}) · realtime on /socket.io`);
});
realtime.attach(server);

async function shutdown(signal) {
  console.log(`${signal} received, shutting down…`);
  await realtime.close().catch(() => {});
  server.close(async () => {
    await pool.end().catch(() => {});
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
