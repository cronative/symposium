/**
 * npm run admin:create -- --email admin@syyncin.app --password "Secret#123" --name "Nik" --role super_admin
 */
const bcrypt = require('bcryptjs');
const db = require('../src/config/db');

(async () => {
  const arg = (k, d) => {
    const i = process.argv.indexOf(`--${k}`);
    return i > -1 ? process.argv[i + 1] : d;
  };
  const email = (arg('email') || '').toLowerCase();
  const password = arg('password');
  const name = arg('name', 'Admin');
  const role = arg('role', 'super_admin');
  if (!email || !password || password.length < 8) {
    console.error('Usage: --email <email> --password <min 8 chars> [--name <name>] [--role super_admin|admin]');
    process.exit(1);
  }
  const hash = await bcrypt.hash(password, 12);
  await db.query(
    `INSERT INTO admins (name, email, password_hash, role) VALUES (:n, :e, :h, :r)
     ON DUPLICATE KEY UPDATE name = VALUES(name), password_hash = VALUES(password_hash), role = VALUES(role), is_active = 1`,
    { n: name, e: email, h: hash, r: role },
  );
  console.log(`✓ admin ${email} (${role}) ready`);
  await db.pool.end();
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
