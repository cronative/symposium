/**
 * SyyncMatch engine — builds feature profiles from the database in bulk (no N+1),
 * scores candidates with the KYN or Seek strategy and explains every score.
 *
 * Score = Σ weight × factor × 100, factors in [0,1]. Unknown factors count as 0 (never
 * as a perfect match); when less than MIN_COVERAGE of the weight is known, the result is
 * flagged `insufficient` so the app shows "Not enough info" instead of a verdict.
 * Scores never depend on subscriptions.
 */
// Lazy so the pure scoring functions can be unit-tested without a database.
const db = { query: (...a) => require('../../config/db').query(...a) };
const cfg = require('./config');
const F = require('./factors');

// ── Profiles ────────────────────────────────────────────────────────────
const slug = (t) => F.canon(t).replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
const intentKey = (title) => cfg.INTENT_KEYS[F.canon(title)] || slug(title);

/**
 * Feature profiles for user ids (4 queries total, whatever the number of ids).
 * Only data needed for scoring is loaded; nothing here is sent to the app.
 */
async function loadProfiles(ids) {
  const out = new Map();
  if (!ids.length) return out;
  const [users, skills, interests, reasons] = await Promise.all([
    db.query(
      `SELECT u.id, u.job_title, u.industry_id, u.city_id, u.locality_id, u.radius_km, u.connect_mode,
              COALESCE(u.lat, c.lat) AS lat, COALESCE(u.lng, c.lng) AS lng, e.sort_order AS exp_rank
         FROM users u
         LEFT JOIN cities c ON c.id = u.city_id
         LEFT JOIN experience_levels e ON e.id = u.experience_level_id
        WHERE u.id IN (:ids)`,
      { ids },
    ),
    db.query('SELECT us.user_id, s.id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id IN (:ids) AND s.is_active = 1', { ids }),
    db.query('SELECT ui.user_id, ui.interest_id FROM user_interests ui JOIN interests x ON x.id = ui.interest_id WHERE ui.user_id IN (:ids) AND x.is_active = 1', { ids }),
    db.query('SELECT ur.user_id, r.title FROM user_reasons ur JOIN reasons r ON r.id = ur.reason_id WHERE ur.user_id IN (:ids) AND r.is_active = 1', { ids }),
  ]);
  for (const u of users) {
    out.set(u.id, {
      id: u.id,
      jobTitle: u.job_title,
      industryId: u.industry_id,
      cityId: u.city_id,
      localityId: u.locality_id,
      radiusKm: u.radius_km,
      connectMode: u.connect_mode,
      lat: u.lat == null ? null : Number(u.lat),
      lng: u.lng == null ? null : Number(u.lng),
      expRank: u.exp_rank == null ? null : Number(u.exp_rank),
      skills: new Set(),
      skillNames: new Map(),
      interests: new Set(),
      intents: new Set(),
    });
  }
  for (const s of skills) {
    const p = out.get(s.user_id);
    if (p) { p.skills.add(s.id); p.skillNames.set(s.id, s.name); }
  }
  for (const i of interests) out.get(i.user_id)?.interests.add(i.interest_id);
  for (const r of reasons) out.get(r.user_id)?.intents.add(intentKey(r.title));
  return out;
}

// ── Scoring ─────────────────────────────────────────────────────────────
function levelOf(score, insufficient) {
  if (insufficient) return { key: 'insufficient', label: 'Not enough info' };
  const l = cfg.LEVELS.find((x) => score >= x.min) || cfg.LEVELS[cfg.LEVELS.length - 1];
  return { key: l.key, label: l.label };
}

/**
 * Weighted sum → integer score 0–100 and integer points per factor that add up to the
 * score exactly (largest-remainder rounding), so the breakdown always matches the badge.
 */
function combine(values, weights) {
  const keys = Object.keys(weights);
  const raw = keys.map((k) => weights[k] * F.clamp01(values[k] ?? 0) * 100);
  const total = Math.max(0, Math.min(100, Math.round(raw.reduce((a, b) => a + b, 0))));
  const floors = raw.map(Math.floor);
  let left = total - floors.reduce((a, b) => a + b, 0);
  const order = raw.map((r, i) => [r - Math.floor(r), i]).sort((a, b) => b[0] - a[0] || a[1] - b[1]);
  for (const [, i] of order) {
    if (left <= 0) break;
    floors[i] += 1;
    left -= 1;
  }
  const coverage = keys.reduce((s, k) => s + (values[k] === null || values[k] === undefined ? 0 : weights[k]), 0);
  const insufficient = coverage < cfg.MIN_COVERAGE;
  const level = levelOf(total, insufficient);
  return {
    score: total,
    level: level.key,
    label: level.label,
    insufficient,
    coverage: Math.round(coverage * 100) / 100,
    breakdown: Object.fromEntries(keys.map((k, i) => [k, floors[i]])),
  };
}

/** Up to 3 truthful reasons, strongest contribution first. */
function pickReasons(candidates) {
  return candidates
    .filter((r) => r.ok)
    .sort((a, b) => b.weight - a.weight)
    .map((r) => r.label)
    .filter((l, i, all) => all.indexOf(l) === i)
    .slice(0, 3);
}

function locationReason(loc, weight) {
  if (!loc.value) return [];
  if (loc.sameLocality) return [{ ok: true, label: 'Same Neighbourhood', weight }];
  if (loc.withinRadius) return [{ ok: true, label: 'Nearby Professional', weight }];
  if (loc.sameCity) return [{ ok: true, label: 'Same City', weight }];
  return [];
}

/** KYN: how compatible `b` is for `a` (symmetric factors except location, which uses a's radius). */
function scoreKyn(a, b, weights = cfg.KYN_WEIGHTS) {
  const sk = F.skills(a, b);
  const it = F.intent(a, b);
  const ir = F.interests(a, b);
  const lo = F.location(a, b);
  const pr = F.professional(a, b);
  const values = { skills: sk.value, intent: it.value, interests: ir.value, location: lo.value, professional: pr.value };
  const result = combine(values, weights);
  const w = (k) => weights[k] * F.clamp01(values[k] ?? 0);
  result.reasons = result.insufficient ? [] : pickReasons([
    { ok: sk.shared > 0 && sk.value >= 0.3, label: 'Shared Skills', weight: w('skills') },
    { ok: sk.shared === 0 && sk.complementary > 0, label: 'Complementary Skills', weight: w('skills') },
    { ok: (it.value ?? 0) >= 0.7, label: 'Compatible Goals', weight: w('intent') },
    { ok: ir.shared > 0, label: 'Common Interests', weight: w('interests') },
    ...locationReason(lo, w('location')),
    { ok: Boolean(pr.sameIndustry), label: 'Same Industry', weight: w('professional') },
    { ok: !pr.sameIndustry && Boolean(pr.similarExperience), label: 'Similar Experience', weight: w('professional') * 0.8 },
  ]);
  result.algorithmVersion = cfg.VERSION;
  return result;
}

/**
 * Seek: rank people for a specific expertise request.
 *   req = { skills: Set<id>, skillNames: Map, terms: Set<string>, intents: Set<key>, industryId, minExpRank, radiusKm }
 *   me  = requester profile (location origin + interests + default intents)
 */
function scoreSeek(req, me, b, weights = cfg.SEEK_WEIGHTS) {
  // Required expertise: share of requested skills they have (+ complementary), or keyword hits in title / skills.
  let expertise = null;
  let skillHit = 0;
  if (req.skills?.size) {
    skillHit = [...req.skills].filter((id) => b.skills.has(id)).length;
    const cover = skillHit / req.skills.size;
    const comp = F.complementarity([...req.skills].map((id) => F.canon(req.skillNames?.get(id))).filter(Boolean), [...b.skills].map((id) => F.canon(b.skillNames.get(id))));
    expertise = F.clamp01(cover + 0.25 * F.clamp01(comp.ratio) * (1 - cover));
  }
  let termHit = false;
  if (req.terms?.size) {
    const hay = [F.canon(b.jobTitle), ...[...b.skillNames.values()].map(F.canon)].join(' | ');
    const hits = [...req.terms].filter((t) => hay.includes(t)).length;
    termHit = hits > 0;
    const t = hits / req.terms.size;
    expertise = expertise === null ? t : Math.max(expertise, t);
  }
  const wantIntents = req.intents?.size ? req.intents : me.intents;
  const intentVal = wantIntents.size && b.intents.size ? F.intentDirection(wantIntents, b.intents) : null;
  // Experience & industry.
  const parts = [];
  const industry = req.industryId || me.industryId;
  if (industry && b.industryId) parts.push([0.5, b.industryId === industry ? 1 : 0]);
  if (req.minExpRank != null && b.expRank != null) parts.push([0.5, b.expRank >= req.minExpRank ? 1 : F.clamp01(1 - (req.minExpRank - b.expRank) / 3)]);
  else if (me.expRank != null && b.expRank != null) parts.push([0.5, F.clamp01(0.5 + (b.expRank - me.expRank) / 4)]); // more experienced helps
  const experience = parts.length ? parts.reduce((s, [w, v]) => s + w * v, 0) : null;
  const lo = F.location(me, b, req.radiusKm || me.radiusKm);
  const ir = F.interests(me, b);

  const values = { expertise, intent: intentVal, experience, location: lo.value, interests: ir.value };
  const result = combine(values, weights);
  const w = (k) => weights[k] * F.clamp01(values[k] ?? 0);
  result.reasons = result.insufficient ? [] : pickReasons([
    { ok: skillHit > 0 || termHit, label: 'Required Expertise', weight: w('expertise') },
    { ok: (intentVal ?? 0) >= 0.7, label: 'Compatible Goals', weight: w('intent') },
    { ok: (experience ?? 0) >= 0.75, label: 'Relevant Experience', weight: w('experience') },
    ...locationReason(lo, w('location')),
    { ok: ir.shared > 0, label: 'Common Interests', weight: w('interests') },
  ]);
  result.algorithmVersion = cfg.VERSION;
  return result;
}

/** Stable order: score ↓, coverage ↓, id ↑ (ids are unique, so ties never shuffle between pages). */
const byMatch = (a, b) => b.match.score - a.match.score || b.match.coverage - a.match.coverage || a.id - b.id;

// ── Cache ───────────────────────────────────────────────────────────────
// Rankings are reused for CACHE_TTL_S, and dropped as soon as anyone changes their
// profile or discovery settings (bump() is called from the API after those writes).
let generation = 0;
const cache = new Map();
const MAX_ENTRIES = 500;

function bump() {
  generation += 1;
  cache.clear();
}

async function cached(key, compute) {
  const hit = cache.get(key);
  if (hit && hit.gen === generation && Date.now() - hit.at < cfg.CACHE_TTL_S * 1000) return hit.value;
  const gen = generation;
  const value = await compute();
  if (gen === generation) {
    if (cache.size >= MAX_ENTRIES) cache.delete(cache.keys().next().value);
    cache.set(key, { at: Date.now(), gen, value });
  }
  return value;
}

/** KYN ranking for `meId` over candidate ids → [{ id, match }] sorted by SyyncScore. */
async function rankKyn(meId, candidateIds, cacheKey) {
  return cached(`kyn:${meId}:${cacheKey}`, async () => {
    const profiles = await loadProfiles([meId, ...candidateIds]);
    const me = profiles.get(meId);
    if (!me) return [];
    return candidateIds
      .map((id) => profiles.get(id))
      .filter(Boolean)
      .map((p) => ({ id: p.id, match: scoreKyn(me, p) }))
      .sort(byMatch);
  });
}

/** SyyncScore of specific members for `meId` (cards, profile) → Map<id, match>. */
async function matchesFor(meId, ids) {
  const others = ids.filter((id) => id !== meId);
  if (!others.length) return new Map();
  const profiles = await loadProfiles([meId, ...others]);
  const me = profiles.get(meId);
  const out = new Map();
  if (!me) return out;
  for (const id of others) {
    const p = profiles.get(id);
    if (p) out.set(id, scoreKyn(me, p));
  }
  return out;
}

/** Seek ranking for a request → [{ id, match }]. */
async function rankSeek(meId, candidateIds, request, cacheKey) {
  return cached(`seek:${meId}:${cacheKey}`, async () => {
    const profiles = await loadProfiles([meId, ...candidateIds]);
    const me = profiles.get(meId);
    if (!me) return [];
    return candidateIds
      .map((id) => profiles.get(id))
      .filter(Boolean)
      .map((p) => ({ id: p.id, match: scoreSeek(request, me, p) }))
      .sort(byMatch);
  });
}

/** Public shape on member cards (camelCase like the rest of the card). */
const publicMatch = (m) =>
  m && {
    score: m.score,
    level: m.level,
    label: m.label,
    reasons: m.reasons,
    breakdown: m.breakdown,
    insufficient: m.insufficient,
    algorithmVersion: m.algorithmVersion,
  };

module.exports = { loadProfiles, intentKey, combine, levelOf, scoreKyn, scoreSeek, byMatch, rankKyn, rankSeek, matchesFor, publicMatch, bump };
