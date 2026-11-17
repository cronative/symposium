/**
 * KYN Home + Filters + member profiles.
 *   GET    /discover              people cards (search, quick chips, filters, sort, paging) — default sort: SyyncScore
 *   GET    /discover/filters      options + defaults for the Filters screen
 *   GET    /users/:id             Professional Profile
 *   GET    /users/:id/icebreakers suggestions for "Send Connection Request"
 *   PUT    /users/:id/save        bookmark   ·   DELETE /users/:id/save  remove bookmark
 *   GET    /me/saved              bookmarked members
 */
const express = require('express');
const { z } = require('zod');
const env = require('../../config/env');
const db = require('../../config/db');
const { ah, ok, okList, errors, paging } = require('../../utils/http');
const { requireUser, requireOnboarded, validate, idParam } = require('../../middleware');
const P = require('../../services/people');
const M = require('../../services/match/engine');
const matchCfg = require('../../services/match/config');

const router = express.Router();
router.use(['/discover', '/users', '/me/saved'], requireUser, requireOnboarded);

const QUICK = ['all', 'nearby', 'professionals', 'similar'];
const SORTS = ['match', 'nearest', 'name', 'newest'];
const csvIds = z
  .string()
  .optional()
  .transform((v) => (v ? [...new Set(v.split(',').map((x) => parseInt(x, 10)).filter((n) => n > 0))] : []));
const boolish = z.enum(['true', 'false', '1', '0']).optional().transform((v) => v === 'true' || v === '1');

const discoverQuery = z.object({
  search: z.string().trim().max(60).optional(),
  quick: z.enum(QUICK).optional().default('all'),
  industryId: z.coerce.number().int().positive().optional(),
  interestIds: csvIds,
  experienceLevelId: z.coerce.number().int().positive().optional(),
  cityId: z.coerce.number().int().positive().optional(),
  maxDistanceKm: z.coerce.number().min(1).max(100).optional(),
  sort: z.enum(SORTS).optional().default('match'),
  verifiedOnly: boolish,
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
});

// GET /discover — KYN Home list. Also powers "Show N people" on Filters (use limit=1 and read meta.total).
router.get(
  '/discover',
  validate(discoverQuery, 'query'),
  ah(async (req, res) => {
    const me = req.user;
    const f = req.validQuery;
    const pg = paging(f);
    const origin = await P.originOf(me);
    const cityId = f.cityId ?? me.city_id ?? null;
    let maxKm = f.maxDistanceKm ?? me.radius_km ?? 25;
    if (f.quick === 'nearby') maxKm = Math.min(maxKm, env.rules.nearbyKm);

    const where = [P.VISIBLE, 'u.id <> :me', 'u.nearby_discovery = 1'];
    const params = { me: me.id, oLat: origin?.lat, oLng: origin?.lng };
    if (cityId) { where.push('u.city_id = :cityId'); params.cityId = cityId; }
    if (origin) { where.push(`${P.distanceSql(origin)} <= :maxKm`); params.maxKm = maxKm; }
    if (f.industryId) { where.push('u.industry_id = :industryId'); params.industryId = f.industryId; }
    if (f.experienceLevelId) { where.push('u.experience_level_id = :exp'); params.exp = f.experienceLevelId; }
    if (f.verifiedOnly) where.push("u.verification_status = 'verified'");
    if (f.interestIds.length) {
      where.push('EXISTS (SELECT 1 FROM user_interests fi WHERE fi.user_id = u.id AND fi.interest_id IN (:interestIds))');
      params.interestIds = f.interestIds;
    }
    if (f.quick === 'similar') {
      where.push(`EXISTS (SELECT 1 FROM user_interests a JOIN user_interests b ON b.interest_id = a.interest_id AND b.user_id = :me
                          WHERE a.user_id = u.id)`);
    }
    if (f.quick === 'professionals' && me.industry_id) { where.push('u.industry_id = :myIndustry'); params.myIndustry = me.industry_id; }
    if (f.search) {
      where.push(`(u.full_name LIKE :q OR u.job_title LIKE :q OR u.company LIKE :q
                   OR EXISTS (SELECT 1 FROM user_interests si JOIN interests sx ON sx.id = si.interest_id WHERE si.user_id = u.id AND sx.name LIKE :q)
                   OR EXISTS (SELECT 1 FROM user_skills sk JOIN skills ss ON ss.id = sk.skill_id WHERE sk.user_id = u.id AND ss.name LIKE :q))`);
      params.q = `%${f.search.replace(/[%_]/g, '\\$&')}%`;
    }
    const order = {
      match: 'u.id', // ranked in code below
      nearest: origin ? 'distance_km IS NULL, distance_km ASC, u.full_name' : 'u.full_name',
      name: 'u.full_name ASC, u.id',
      newest: 'u.created_at DESC, u.id DESC',
    }[f.sort];

    const whereSql = where.join(' AND ');
    let total;
    let rows;
    let scores;
    if (f.sort === 'match') {
      // SyyncMatch: score the (nearest-first) candidate pool on the server, then page the ranking.
      const pool = await db.query(
        `SELECT u.id ${P.CARD_FROM} WHERE ${whereSql} ORDER BY ${origin ? `${P.distanceSql(origin)} IS NULL, ${P.distanceSql(origin)},` : ''} u.id LIMIT :pool`,
        { ...params, pool: matchCfg.CANDIDATE_POOL },
      );
      const { page: _p, limit: _l, ...filterKey } = f;
      const ranked = await M.rankKyn(me.id, pool.map((r) => r.id), JSON.stringify(filterKey));
      total = ranked.length;
      const pageIds = ranked.slice(pg.offset, pg.offset + pg.limit).map((r) => r.id);
      scores = new Map(ranked.map((r) => [r.id, r.match]));
      const byId = new Map(
        (pageIds.length ? await db.query(`${P.cardSelect(origin)} ${P.CARD_FROM} WHERE u.id IN (:ids)`, { ...params, ids: pageIds }) : []).map((r) => [r.id, r]),
      );
      rows = pageIds.map((id) => byId.get(id)).filter(Boolean);
    } else {
      [{ total }] = await db.query(`SELECT COUNT(*) AS total ${P.CARD_FROM} WHERE ${whereSql}`, params);
      rows = await db.query(
        `${P.cardSelect(origin)} ${P.CARD_FROM} WHERE ${whereSql} ORDER BY ${order} LIMIT :limit OFFSET :offset`,
        { ...params, limit: pg.limit, offset: pg.offset },
      );
      scores = await M.matchesFor(me.id, rows.map((r) => r.id));
    }
    const cards = (await P.toCards(rows, me.id)).map((c) => ({ ...c, match: M.publicMatch(scores.get(c.id)) || null }));
    const n = Number(total);
    okList(res, cards, pg, n, n ? `${n} ${n === 1 ? 'person' : 'people'} found near you.` : 'No matches just yet. Try widening your search or adjusting your filters.', {
      applied: {
        quick: f.quick,
        search: f.search || null,
        cityId,
        maxDistanceKm: origin ? maxKm : null,
        industryId: f.industryId ?? null,
        interestIds: f.interestIds,
        experienceLevelId: f.experienceLevelId ?? null,
        verifiedOnly: f.verifiedOnly,
        sort: f.sort,
      },
      locationAvailable: Boolean(origin),
    });
  }),
);

// GET /discover/filters — everything the Filters screen needs in one call
router.get(
  '/discover/filters',
  ah(async (req, res) => {
    const [industries, interests, levels, cities] = await Promise.all([
      db.query('SELECT id, name FROM industries WHERE is_active = 1 ORDER BY sort_order, name'),
      db.query('SELECT id, name, icon FROM interests WHERE is_active = 1 ORDER BY sort_order, name'),
      db.query('SELECT id, label, min_years AS minYears, max_years AS maxYears FROM experience_levels WHERE is_active = 1 ORDER BY sort_order'),
      db.query('SELECT id, name, state FROM cities WHERE is_active = 1 ORDER BY sort_order, name'),
    ]);
    ok(res, {
      professions: industries,
      interests,
      experienceLevels: levels,
      cities,
      distance: { minKm: 5, maxKm: 50, stepKm: 1, defaultKm: req.user.radius_km || 25 },
      quickFilters: [
        { value: 'all', label: 'All' },
        { value: 'nearby', label: 'Nearby', hint: `Within ${env.rules.nearbyKm} km` },
        { value: 'professionals', label: 'Professionals', hint: 'Same industry as you' },
        { value: 'similar', label: 'Similar', hint: 'Shares at least one interest' },
      ],
      sortOptions: [
        { value: 'match', label: 'Best match' },
        { value: 'nearest', label: 'Nearest' },
        { value: 'name', label: 'Name' },
        { value: 'newest', label: 'Newest' },
      ],
      defaults: { quick: 'all', cityId: req.user.city_id, maxDistanceKm: req.user.radius_km || 25, sort: 'match', interestIds: [], industryId: null, experienceLevelId: null },
    }, 'Filter options fetched successfully.');
  }),
);

async function targetOr404(me, id) {
  const target = await db.one('SELECT * FROM users WHERE id = :id', { id });
  if (!(await P.canView(me, target))) throw errors.notFound('Member');
  return target;
}

// GET /users/:id — Professional Profile
router.get(
  '/users/:id',
  idParam,
  ah(async (req, res) => {
    const me = req.user;
    const target = await targetOr404(me, Number(req.params.id));
    const [card] = await P.cardsByIds(me, [target.id]);
    const [skills, reasons, mindset, myAnswers] = await Promise.all([
      db.query('SELECT s.id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :id ORDER BY s.sort_order', { id: target.id }),
      db.query('SELECT r.id, r.title, r.icon FROM user_reasons ur JOIN reasons r ON r.id = ur.reason_id WHERE ur.user_id = :id ORDER BY r.sort_order', { id: target.id }),
      db.query(
        `SELECT q.id AS questionId, q.question, o.id AS optionId, o.label AS answer
           FROM user_mindset_answers a JOIN mindset_questions q ON q.id = a.question_id JOIN mindset_options o ON o.id = a.option_id
          WHERE a.user_id = :id AND q.is_active = 1 ORDER BY q.sort_order`,
        { id: target.id },
      ),
      db.query('SELECT option_id FROM user_mindset_answers WHERE user_id = :me', { me: me.id }),
    ]);
    const mine = new Set(myAnswers.map((a) => a.option_id));
    let availability = target.availability;
    if (typeof availability === 'string') availability = JSON.parse(availability);
    const connected = card.connection.status === 'connected' || target.id === me.id;
    const match = target.id === me.id ? null : M.publicMatch((await M.matchesFor(me.id, [target.id])).get(target.id)) || null;
    ok(res, {
      ...card,
      match,
      about: target.about,
      skills,
      intent: reasons,
      mindset: mindset.map((m) => ({ ...m, shared: target.id !== me.id && mine.has(m.optionId) })),
      connectionPreferences: { connectMode: target.connect_mode, availability: availability || [] },
      linkedinUrl: connected ? target.linkedin_url : null,
      memberSince: target.created_at,
    }, 'Profile fetched successfully.');
  }),
);

// GET /users/:id/icebreakers — message suggestions ("Need a little inspiration?")
router.get(
  '/users/:id/icebreakers',
  idParam,
  ah(async (req, res) => {
    const me = req.user;
    const target = await targetOr404(me, Number(req.params.id));
    const [card] = await P.cardsByIds(me, [target.id]);
    const first = (target.full_name || '').split(/\s+/)[0] || 'there';
    const shared = card.sharedInterests;
    const sameArea = card.locality && me.locality_id === card.locality.id;
    ok(res, {
      maxLength: env.rules.requestMessageMax,
      suggestions: [
        `Hi ${first}, I'd love to connect and exchange ideas.`,
        shared.length
          ? `We share an interest in ${shared.slice(0, 2).join(' and ')}. It would be great to connect.`
          : 'We share a few interests. It would be great to connect.',
        sameArea
          ? `I'm also in ${card.locality.name} and would love to meet for a coffee sometime.`
          : "I'm new to the area and would love to meet more professionals.",
      ],
    }, 'Suggestions ready. Tap one to use or edit it.');
  }),
);

// PUT /users/:id/save — bookmark (idempotent)
router.put(
  '/users/:id/save',
  idParam,
  ah(async (req, res) => {
    const target = await targetOr404(req.user, Number(req.params.id));
    if (target.id === req.user.id) throw errors.badRequest('CANNOT_SAVE_SELF', 'You cannot bookmark your own profile.');
    await db.query('INSERT IGNORE INTO saved_profiles (user_id, saved_user_id) VALUES (:me, :id)', { me: req.user.id, id: target.id });
    ok(res, { userId: target.id, isSaved: true }, 'Profile saved to your bookmarks.');
  }),
);

// DELETE /users/:id/save — remove bookmark (idempotent)
router.delete(
  '/users/:id/save',
  idParam,
  ah(async (req, res) => {
    await db.query('DELETE FROM saved_profiles WHERE user_id = :me AND saved_user_id = :id', { me: req.user.id, id: Number(req.params.id) });
    ok(res, { userId: Number(req.params.id), isSaved: false }, 'Removed from your bookmarks.');
  }),
);

// GET /me/saved — bookmarked members (newest first)
router.get(
  '/me/saved',
  ah(async (req, res) => {
    const pg = paging(req.query);
    const where = `sp.user_id = :me AND ${P.VISIBLE}`;
    const [{ total }] = await db.query(`SELECT COUNT(*) AS total FROM saved_profiles sp JOIN users u ON u.id = sp.saved_user_id WHERE ${where}`, { me: req.user.id });
    const rows = await db.query(
      `SELECT sp.saved_user_id AS id FROM saved_profiles sp JOIN users u ON u.id = sp.saved_user_id
        WHERE ${where} ORDER BY sp.created_at DESC LIMIT :limit OFFSET :offset`,
      { me: req.user.id, limit: pg.limit, offset: pg.offset },
    );
    okList(res, await P.cardsByIds(req.user, rows.map((r) => r.id)), pg, total, Number(total) ? 'Saved profiles fetched successfully.' : 'You have not saved any profiles yet.');
  }),
);

module.exports = router;
