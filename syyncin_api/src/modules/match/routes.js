/**
 * SyyncMatch — professional recommendations with an explainable SyyncScore.
 *   GET /matches          KYN recommendations (people you're not connected with yet), best first
 *   GET /seek/matches     Seek: rank people for a specific expertise request
 * Scores are always computed here — the app never sends or stores them.
 * Response items: { user_id, match_score, match_level, match_label, match_reasons, score_breakdown, insufficient_data, user }
 */
const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { ok, ah, errors, paging } = require('../../utils/http');
const { requireUser, requireOnboarded, validate } = require('../../middleware');
const P = require('../../services/people');
const M = require('../../services/match/engine');
const cfg = require('../../services/match/config');
const F = require('../../services/match/factors');

const router = express.Router();
router.use(['/matches', '/seek'], requireUser, requireOnboarded);

const csvIds = z
  .string()
  .optional()
  .transform((v) => (v ? [...new Set(v.split(',').map((x) => parseInt(x, 10)).filter((n) => n > 0))].slice(0, 20) : []));

const toItem = (r, card) => ({
  user_id: r.id,
  match_score: r.match.score,
  match_level: r.match.level,
  match_label: r.match.label,
  match_reasons: r.match.reasons,
  score_breakdown: r.match.breakdown,
  insufficient_data: r.match.insufficient,
  user: card || null,
});

/**
 * Members who may be recommended to `me`: visible (active, onboarded, discoverable),
 * open to new connections, not me, not already connected and no open request either way.
 */
function eligibleWhere(me) {
  return {
    where: [
      P.VISIBLE,
      'u.id <> :me',
      'u.nearby_discovery = 1',
      'u.open_to_connect = 1',
      'NOT EXISTS (SELECT 1 FROM connections cx WHERE (cx.user_a_id = LEAST(:me, u.id) AND cx.user_b_id = GREATEST(:me, u.id)))',
      "NOT EXISTS (SELECT 1 FROM connection_requests rx WHERE rx.status = 'pending' AND rx.pending_pair = CONCAT(LEAST(:me, u.id), '-', GREATEST(:me, u.id)))",
    ],
    params: { me: me.id },
  };
}

async function page(req, res, ranked, pg, message, extra = {}) {
  const slice = ranked.slice(pg.offset, pg.offset + pg.limit);
  const cards = await P.cardsByIds(req.user, slice.map((r) => r.id));
  const byId = new Map(cards.map((c) => [c.id, c]));
  ok(res, {
    matches: slice.map((r) => toItem(r, byId.get(r.id))),
    pagination: { page: pg.page, limit: pg.limit, total: ranked.length, has_more: pg.offset + slice.length < ranked.length },
    algorithm_version: cfg.VERSION,
    ...extra,
  }, message);
}

// GET /matches — KYN recommendations ranked by SyyncScore
router.get(
  '/matches',
  validate(z.object({
    cityId: z.coerce.number().int().positive().optional(),
    maxDistanceKm: z.coerce.number().min(1).max(100).optional(),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(50).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const me = req.user;
    const q = req.validQuery;
    const pg = paging(q);
    const origin = await P.originOf(me);
    const { where, params } = eligibleWhere(me);
    Object.assign(params, { oLat: origin?.lat, oLng: origin?.lng });
    const cityId = q.cityId ?? null;
    if (cityId) { where.push('u.city_id = :cityId'); params.cityId = cityId; }
    if (origin && q.maxDistanceKm) { where.push(`${P.distanceSql(origin)} <= :maxKm`); params.maxKm = q.maxDistanceKm; }
    const pool = await db.query(
      `SELECT u.id ${P.CARD_FROM} WHERE ${where.join(' AND ')}
        ORDER BY ${origin ? `${P.distanceSql(origin)} IS NULL, ${P.distanceSql(origin)},` : ''} u.id LIMIT :pool`,
      { ...params, pool: cfg.CANDIDATE_POOL },
    );
    const ranked = await M.rankKyn(me.id, pool.map((r) => r.id), `rec:${cityId}:${q.maxDistanceKm ?? ''}`);
    await page(req, res, ranked, pg, ranked.length ? 'Professional matches fetched successfully.' : 'No new matches right now. Complete your profile or widen your area to see more.');
  }),
);

// GET /seek/matches — rank people for an expertise request (private; not a job board)
router.get(
  '/seek/matches',
  validate(z.object({
    skillIds: csvIds,
    q: z.string().trim().max(80).optional(),
    intentIds: csvIds,
    industryId: z.coerce.number().int().positive().optional(),
    experienceLevelId: z.coerce.number().int().positive().optional(),
    cityId: z.coerce.number().int().positive().optional(),
    maxDistanceKm: z.coerce.number().min(1).max(500).optional(),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(50).optional(),
  }), 'query'),
  ah(async (req, res) => {
    const me = req.user;
    const q = req.validQuery;
    const terms = [...new Set(F.canon(q.q).split(/[^a-z0-9+#./]+/).filter((t) => t.length > 1))].slice(0, 8);
    if (!q.skillIds.length && !terms.length) {
      throw errors.badRequest('SEEK_QUERY_REQUIRED', 'Tell us which skill or expertise you are looking for.');
    }
    const pg = paging(q);
    const origin = await P.originOf(me);
    const { where, params } = eligibleWhere(me);
    Object.assign(params, { oLat: origin?.lat, oLng: origin?.lng });
    // Pre-filter: only people with a requested skill or a keyword in their title / skills.
    const any = [];
    if (q.skillIds.length) { any.push('EXISTS (SELECT 1 FROM user_skills qs WHERE qs.user_id = u.id AND qs.skill_id IN (:skillIds))'); params.skillIds = q.skillIds; }
    terms.forEach((t, i) => {
      params[`t${i}`] = `%${t.replace(/[%_]/g, '\\$&')}%`;
      any.push(`u.job_title LIKE :t${i}`, `EXISTS (SELECT 1 FROM user_skills ks JOIN skills kx ON kx.id = ks.skill_id WHERE ks.user_id = u.id AND kx.name LIKE :t${i})`);
    });
    where.push(`(${any.join(' OR ')})`);
    if (q.cityId) { where.push('u.city_id = :cityId'); params.cityId = q.cityId; }
    if (origin && q.maxDistanceKm) { where.push(`${P.distanceSql(origin)} <= :maxKm`); params.maxKm = q.maxDistanceKm; }
    const pool = await db.query(`SELECT u.id ${P.CARD_FROM} WHERE ${where.join(' AND ')} ORDER BY u.id LIMIT :pool`, { ...params, pool: cfg.CANDIDATE_POOL });

    const [skillRows, intentRows, level] = await Promise.all([
      q.skillIds.length ? db.query('SELECT id, name FROM skills WHERE id IN (:ids) AND is_active = 1', { ids: q.skillIds }) : [],
      q.intentIds.length ? db.query('SELECT title FROM reasons WHERE id IN (:ids) AND is_active = 1', { ids: q.intentIds }) : [],
      q.experienceLevelId ? db.one('SELECT sort_order FROM experience_levels WHERE id = :id', { id: q.experienceLevelId }) : null,
    ]);
    const request = {
      skills: new Set(skillRows.map((s) => s.id)),
      skillNames: new Map(skillRows.map((s) => [s.id, s.name])),
      terms: new Set(terms),
      intents: new Set(intentRows.map((r) => M.intentKey(r.title))),
      industryId: q.industryId ?? null,
      minExpRank: level ? Number(level.sort_order) : null,
      radiusKm: q.maxDistanceKm ?? null,
    };
    const { page: _p, limit: _l, ...key } = q;
    const ranked = await M.rankSeek(me.id, pool.map((r) => r.id), request, JSON.stringify(key));
    await page(req, res, ranked, pg, ranked.length ? 'Professionals with this expertise fetched successfully.' : 'Nobody with this expertise yet. Try a related skill or a wider area.', {
      request: { skill_ids: [...request.skills], q: q.q || null, intent_ids: q.intentIds, industry_id: request.industryId, experience_level_id: q.experienceLevelId ?? null },
    });
  }),
);

module.exports = router;
