/**
 * npm run db:migrate   → create database (if needed) + tables + seed
 * npm run db:seed      → seed only
 * npm run db:reset     → DROP all tables, recreate, seed (dev only!)
 * add --demo           → also insert the demo members shown on KYN (db/demo.sql)
 */
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const env = require('../src/config/env');

(async () => {
  const args = process.argv.slice(2);
  const conn = await mysql.createConnection({
    host: env.db.host, port: env.db.port, user: env.db.user, password: env.db.password, multipleStatements: true,
  });
  await conn.query(`CREATE DATABASE IF NOT EXISTS \`${env.db.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
  await conn.query(`USE \`${env.db.database}\``);
  await conn.query("SET time_zone = '+00:00'");

  if (args.includes('--reset')) {
    if (env.isProd) throw new Error('Refusing to reset in production');
    const [tables] = await conn.query('SHOW TABLES');
    if (tables.length) {
      const names = tables.map((t) => `\`${Object.values(t)[0]}\``).join(', ');
      await conn.query(`SET FOREIGN_KEY_CHECKS = 0; DROP TABLE ${names}; SET FOREIGN_KEY_CHECKS = 1;`);
    }
    console.log('✓ dropped tables');
  }
  if (!args.includes('--seed-only')) {
    await conn.query(fs.readFileSync(path.join(__dirname, '../db/schema.sql'), 'utf8'));
    // Columns added after the first release (CREATE TABLE IF NOT EXISTS won't add them).
    const added = [
      ['users', 'open_to_connect', 'TINYINT(1) NOT NULL DEFAULT 1 AFTER nearby_discovery'],
      ['users', 'about', 'VARCHAR(500) NULL AFTER open_to_connect'],
    ];
    for (const [table, column, def] of added) {
      const [rows] = await conn.query(
        'SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?',
        [env.db.database, table, column],
      );
      if (!rows.length) {
        await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${def}`);
        console.log(`✓ added ${table}.${column}`);
      }
    }
    console.log('✓ schema');
  }
  await conn.query(fs.readFileSync(path.join(__dirname, '../db/seed.sql'), 'utf8'));
  console.log('✓ seed');
  if (args.includes('--demo')) {
    await conn.query(fs.readFileSync(path.join(__dirname, '../db/demo.sql'), 'utf8'));
    console.log('✓ demo members (KYN / Inbox sample data)');
  }
  await conn.end();
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
