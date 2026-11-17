const fs = require('fs');
const path = require('path');
const express = require('express');
const bcrypt = require('bcryptjs');
const { z } = require('zod');
const db = require('../../config/db');
const { ApiError, ah, ok, okList, errors, paging } = require('../../utils/http');
const { issueTokens, rotateRefresh, revokeRefresh, revokeAll } = require('../../utils/security');
const { loadProfile } = require('../../services/profile');
const { requireAdmin, validate, idParam } = require('../../middleware');
const { TYPES, buildRouter, mindsetOptionsRouter } = require('./masterData');
const network = require('./network');
const realtime = require('../../realtime');

const router = express.Router();
const adminView = (a) => ({ id: a.id, name: a.name, email: a.email, role: a.role });

// ─── Admin auth ────────────────────────────────────────────────────────
router.post(
  '/auth/login',
  validate(z.object({ email: z.email().transform((e) => e.toLowerCase()), password: z.string().min(1).max(200) })),
  ah(async (req, res) => {
    const a = await db.one('SELECT * FROM admins WHERE email = :e', { e: req.body.email });
    const okPw = a && (await bcrypt.compare(req.body.password, a.password_hash));
    if (!okPw || !a.is_active) throw new ApiError(401, 'INVALID_CREDENTIALS', 'Incorrect email or password.');
    await db.query('UPDATE admins SET last_login_at = UTC_TIMESTAMP() WHERE id = :id', { id: a.id });
    ok(res, { ...(await issueTokens('admin', a.id, { role: a.role })), admin: adminView(a) }, `Welcome back, ${a.name}.`);
  }),
);

router.post(
  '/auth/refresh',
  validate(z.object({ refreshToken: z.string().min(20) })),
  ah(async (req, res) => {
    const id = await rotateRefresh('admin', req.body.refreshToken);
    const a = id && (await db.one('SELECT * FROM admins WHERE id = :id AND is_active = 1', { id }));
    if (!a) throw new ApiError(401, 'REFRESH_INVALID', 'Session expired. Please log in again.');
    ok(res, { ...(await issueTokens('admin', a.id, { role: a.role })), admin: adminView(a) }, 'Session refreshed.');
  }),
);

router.post(
  '/auth/logout',
  validate(z.object({ refreshToken: z.string().min(20) })),
  ah(async (req, res) => {
    await revokeRefresh('admin', req.body.refreshToken);
    ok(res, { loggedOut: true }, 'Logged out successfully.');
  }),
);

// Everything below requires an admin token.
router.use(requireAdmin());

router.get('/auth/me', (req, res) => ok(res, adminView(req.admin), 'Admin profile fetched successfully.'));

// ─── Dashboard stats ──────────────────────────────────────────────────
router.get('/stats', ah(async (_req, res) => {
  const u = await db.one(`
    SELECT COUNT(*) AS total,
           SUM(onboarding_step >= 7) AS onboarded,
           SUM(verification_status = 'verified') AS verified,
           SUM(verification_status = 'pending') AS pendingVerification,
           SUM(status = 'blocked') AS blocked,
           SUM(created_at >= UTC_TIMESTAMP() - INTERVAL 7 DAY) AS newLast7Days
      FROM users`);
  const steps = await db.query('SELECT onboarding_step AS step, COUNT(*) AS users FROM users GROUP BY onboarding_step ORDER BY step');
  const daily = await db.query(`
    SELECT DATE(created_at) AS day, COUNT(*) AS users FROM users
     WHERE created_at >= UTC_DATE() - INTERVAL 13 DAY GROUP BY DATE(created_at) ORDER BY day`);
  const topInterests = await db.query(`
    SELECT i.name, COUNT(*) AS users FROM user_interests ui JOIN interests i ON i.id = ui.interest_id
     GROUP BY i.id ORDER BY users DESC, i.name LIMIT 8`);
  const masters = {};
  for (const [type, cfg] of Object.entries(TYPES)) {
    const r = await db.one(`SELECT COUNT(*) AS total, SUM(is_active = 1) AS active FROM ${cfg.table}`);
    masters[type] = { total: Number(r.total), active: Number(r.active || 0) };
  }
  const num = (v) => Number(v || 0);
  ok(res, {
    users: {
      total: num(u.total), onboarded: num(u.onboarded), verified: num(u.verified),
      pendingVerification: num(u.pendingVerification), blocked: num(u.blocked), newLast7Days: num(u.newLast7Days),
    },
    onboardingFunnel: steps.map((s) => ({ step: s.step, users: Number(s.users) })),
    signupsByDay: daily.map((d) => ({ day: d.day instanceof Date ? d.day.toISOString().slice(0, 10) : String(d.day).slice(0, 10), users: Number(d.users) })),
    topInterests: topInterests.map((t) => ({ name: t.name, users: Number(t.users) })),
    masterData: masters,
    network: await network.networkStats(),
  }, 'Dashboard stats fetched successfully.');
}));

// ─── Master data: 8 types × 7 endpoints ──────────────────────────────
for (const type of Object.keys(TYPES)) router.use(`/${type}`, buildRouter(type));
router.use('/', mindsetOptionsRouter());

// ─── Verifications (manual selfie approval) ──────────────────────────
const verifRow = (v) => ({
  id: v.id,
  status: v.status,
  reason: v.reason,
  submittedAt: v.created_at,
  reviewedAt: v.reviewed_at,
  reviewedBy: v.reviewer_name ? { id: v.reviewed_by, name: v.reviewer_name } : null,
  selfieUrl: `/api/v1/admin/verifications/${v.id}/selfie`,
  user: { id: v.user_id, fullName: v.full_name, phone: v.phone, email: v.email, photoPath: v.photo_path ? `/${v.photo_path}` : null },
});
const VERIF_SELECT = `SELECT v.*, u.full_name, u.phone, u.email, u.photo_path, a.name AS reviewer_name
  FROM verifications v JOIN users u ON u.id = v.user_id LEFT JOIN admins a ON a.id = v.reviewed_by`;

router.get(
  '/verifications',
  validate(z.object({
    status: z.enum(['pending', 'verified', 'rejected', 'all']).optional().default('pending'),
    search: z.string().max(80).optional(),
    page: z.coerce.number().optional(),
    limit: z.coerce.number().optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const p = paging(q);
    const where = ['1=1'];
    const params = { limit: p.limit, offset: p.offset };
    if (q.status !== 'all') { where.push('v.status = :status'); params.status = q.status; }
    if (q.search) { where.push('(u.full_name LIKE :s OR u.phone LIKE :s OR u.email LIKE :s)'); params.s = `%${q.search}%`; }
    const w = where.join(' AND ');
    const [{ total }] = await db.query(`SELECT COUNT(*) total FROM verifications v JOIN users u ON u.id = v.user_id WHERE ${w}`, params);
    const rows = await db.query(`${VERIF_SELECT} WHERE ${w} ORDER BY v.created_at ASC, v.id ASC LIMIT :limit OFFSET :offset`, params);
    okList(res, rows.map(verifRow), p, total, 'Verifications fetched successfully.');
  }),
);

async function getVerif(id) {
  const v = await db.one(`${VERIF_SELECT} WHERE v.id = :id`, { id });
  if (!v) throw errors.notFound('Verification');
  return v;
}

router.get('/verifications/:id', idParam, ah(async (req, res) => ok(res, verifRow(await getVerif(req.params.id)), 'Verification fetched successfully.')));

// Selfies are never public — streamed to authenticated admins only.
router.get('/verifications/:id/selfie', idParam, ah(async (req, res) => {
  const v = await getVerif(req.params.id);
  const file = path.resolve(v.selfie_path);
  if (!fs.existsSync(file)) throw errors.notFound('Selfie file');
  res.set('Cache-Control', 'private, no-store');
  res.sendFile(file);
}));

router.patch(
  '/verifications/:id',
  idParam,
  validate(z.object({
    action: z.enum(['approve', 'reject']),
    reason: z.string().trim().max(255).optional(),
  }).refine((b) => b.action === 'approve' || (b.reason && b.reason.length >= 3), { message: 'Add a reason when rejecting.', path: ['reason'] })),
  ah(async (req, res) => {
    const v = await getVerif(req.params.id);
    if (v.status !== 'pending') throw new ApiError(409, 'ALREADY_REVIEWED', `This verification is already ${v.status}.`);
    const status = req.body.action === 'approve' ? 'verified' : 'rejected';
    await db.tx(async (conn) => {
      await db.query(
        'UPDATE verifications SET status = :s, reason = :r, reviewed_by = :a, reviewed_at = UTC_TIMESTAMP() WHERE id = :id',
        { s: status, r: req.body.reason || null, a: req.admin.id, id: v.id },
        conn,
      );
      const latest = await db.one('SELECT MAX(id) AS id FROM verifications WHERE user_id = :u', { u: v.user_id }, conn);
      if (latest.id === v.id) {
        await db.query('UPDATE users SET verification_status = :s WHERE id = :u', { s: status, u: v.user_id }, conn);
      }
    });
    ok(res, verifRow(await getVerif(v.id)), status === 'verified' ? 'Selfie approved. The member is now verified.' : 'Selfie rejected. The member can submit a new one.');
  }),
);

// ─── Users ───────────────────────────────────────────────────────────
router.get(
  '/users',
  validate(z.object({
    search: z.string().max(80).optional(),
    status: z.enum(['active', 'blocked', 'all']).optional().default('all'),
    verificationStatus: z.enum(['none', 'pending', 'verified', 'rejected']).optional(),
    onboarding: z.enum(['complete', 'incomplete']).optional(),
    cityId: z.coerce.number().int().positive().optional(),
    page: z.coerce.number().optional(),
    limit: z.coerce.number().optional(),
  }), 'query'),
  ah(async (req, res) => {
    const q = req.validQuery;
    const p = paging(q);
    const where = ['1=1'];
    const params = { limit: p.limit, offset: p.offset };
    if (q.search) { where.push('(u.full_name LIKE :s OR u.phone LIKE :s OR u.email LIKE :s OR u.job_title LIKE :s)'); params.s = `%${q.search}%`; }
    if (q.status !== 'all') { where.push('u.status = :st'); params.st = q.status; }
    if (q.verificationStatus) { where.push('u.verification_status = :vs'); params.vs = q.verificationStatus; }
    if (q.onboarding) where.push(q.onboarding === 'complete' ? 'u.onboarding_step >= 7' : 'u.onboarding_step < 7');
    if (q.cityId) { where.push('u.city_id = :c'); params.c = q.cityId; }
    const w = where.join(' AND ');
    const [{ total }] = await db.query(`SELECT COUNT(*) total FROM users u WHERE ${w}`, params);
    const rows = await db.query(
      `SELECT u.id, u.full_name, u.phone, u.email, u.job_title, u.company, c.name AS city, u.onboarding_step,
              u.verification_status, u.status, u.last_login_at, u.created_at, u.open_to_connect, u.nearby_discovery,
              (SELECT COUNT(*) FROM connections cn WHERE cn.user_a_id = u.id OR cn.user_b_id = u.id) AS connections
         FROM users u LEFT JOIN cities c ON c.id = u.city_id
        WHERE ${w} ORDER BY u.id DESC LIMIT :limit OFFSET :offset`,
      params,
    );
    okList(res, rows.map((r) => ({
      id: r.id, fullName: r.full_name, phone: r.phone, email: r.email, jobTitle: r.job_title, company: r.company, city: r.city,
      onboardingStep: r.onboarding_step, verificationStatus: r.verification_status, status: r.status,
      lastLoginAt: r.last_login_at, createdAt: r.created_at,
      connections: Number(r.connections), openToConnect: Boolean(r.open_to_connect), nearbyDiscovery: Boolean(r.nearby_discovery),
    })), p, total, 'Users fetched successfully.');
  }),
);

router.get('/users/:id', idParam, ah(async (req, res) => {
  const profile = await loadProfile(req.params.id);
  if (!profile) throw errors.notFound('User');
  const verifications = await db.query(
    'SELECT id, status, reason, created_at AS submittedAt, reviewed_at AS reviewedAt FROM verifications WHERE user_id = :u ORDER BY id DESC',
    { u: req.params.id },
  );
  ok(res, { ...profile, verifications, network: await network.userNetwork(Number(req.params.id)) }, 'User fetched successfully.');
}));

router.patch(
  '/users/:id/status',
  idParam,
  validate(z.object({ status: z.enum(['active', 'blocked']) })),
  ah(async (req, res) => {
    const u = await db.one('SELECT id FROM users WHERE id = :id', { id: req.params.id });
    if (!u) throw errors.notFound('User');
    await db.query('UPDATE users SET status = :s WHERE id = :id', { s: req.body.status, id: u.id });
    if (req.body.status === 'blocked') {
      await revokeAll('user', u.id);
      realtime.disconnectUser(u.id); // close live connections immediately
    }
    ok(res, { id: u.id, status: req.body.status }, req.body.status === 'blocked' ? 'User blocked and signed out of all devices.' : 'User unblocked.');
  }),
);

// ─── Networking (connection requests & connections) ─────────────────
router.use('/', network.router);

module.exports = router;
