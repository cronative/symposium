/**
 * SyyncMatch scoring factors — pure functions (no database), each returning a number
 * in [0, 1], or `null` when either side is missing the data (unknown ≠ perfect).
 *
 * A "profile" here is the internal feature object built by engine.js:
 *   { id, skills: Set<id>, skillNames: Map<id,name>, interests: Set<id>, intents: Set<key>,
 *     industryId, expRank, jobTitle, cityId, localityId, lat, lng, radiusKm, connectMode }
 * lat/lng never leave the server.
 */
const cfg = require('./config');

const clamp01 = (x) => (Number.isFinite(x) ? Math.min(1, Math.max(0, x)) : 0);

/** Lower-case, trimmed, single-spaced — canonical form for names. */
const canon = (s) => String(s || '').trim().toLowerCase().replace(/\s+/g, ' ');

const COMPLEMENT = (() => {
  const m = new Map();
  for (const [a, b] of cfg.COMPLEMENTARY) {
    if (!m.has(a)) m.set(a, new Set());
    if (!m.has(b)) m.set(b, new Set());
    m.get(a).add(b);
    m.get(b).add(a);
  }
  return m;
})();

const intersect = (a, b) => {
  let n = 0;
  for (const x of a) if (b.has(x)) n += 1;
  return n;
};

/**
 * Set similarity: half Jaccard (|A∩B| / |A∪B|), half overlap (|A∩B| / min(|A|,|B|)).
 * Pure Jaccard punishes members who list many items; the overlap half keeps one shared
 * item out of three meaningful without letting tiny lists score 100%.
 */
function setSimilarity(a, b) {
  if (!a?.size || !b?.size) return null;
  const inter = intersect(a, b);
  if (!inter) return 0;
  const union = a.size + b.size - inter;
  return clamp01(0.5 * (inter / union) + 0.5 * (inter / Math.min(a.size, b.size)));
}

/** Share of the other side's distinct skills that complement one of mine (only configured pairs). */
function complementarity(aNames, bNames) {
  const aOnly = aNames.filter((n) => !bNames.includes(n));
  const bOnly = bNames.filter((n) => !aNames.includes(n));
  if (!aOnly.length || !bOnly.length) return { ratio: 0, pairs: 0 };
  let pairs = 0;
  for (const x of aOnly) {
    const set = COMPLEMENT.get(x);
    if (set && bOnly.some((y) => set.has(y))) pairs += 1;
  }
  return { ratio: pairs / Math.min(aOnly.length, bOnly.length), pairs };
}

const namesOf = (p) => [...p.skills].map((id) => canon(p.skillNames?.get(id))).filter(Boolean);

/** Skills & expertise: shared skills, plus up to 35% of the remaining gap for complementary skills. */
function skills(a, b) {
  const sim = setSimilarity(a.skills, b.skills);
  if (sim === null) return { value: null, shared: 0, complementary: 0 };
  const comp = complementarity(namesOf(a), namesOf(b));
  const value = clamp01(sim + 0.35 * clamp01(comp.ratio) * (1 - sim));
  return { value, shared: intersect(a.skills, b.skills), complementary: comp.pairs };
}

/** Shared interests. */
function interests(a, b) {
  const value = setSimilarity(a.interests, b.interests);
  return { value, shared: value === null ? 0 : intersect(a.interests, b.interests) };
}

/** How well what `want` is looking for is served by `offer` (directional, 0–1). */
function intentDirection(want, offer) {
  if (!want.size || !offer.size) return null;
  let total = 0;
  for (const w of want) {
    let best = 0;
    // Configured intents use only their affinity row (so two mentees don't match);
    // unknown, newly added intents still match themselves.
    const row = cfg.AFFINITY[w];
    for (const o of offer) best = Math.max(best, row ? row[o] ?? 0 : w === o ? 1 : 0);
    total += best;
  }
  return total / want.size;
}

/** Connection intent, matched both ways ("Seeking a mentor" ↔ "Open to mentoring"). */
function intent(a, b) {
  const ab = intentDirection(a.intents, b.intents);
  const ba = intentDirection(b.intents, a.intents);
  if (ab === null || ba === null) return { value: null };
  return { value: clamp01((ab + ba) / 2) };
}

/** Great-circle distance in km (server-side only). */
function distanceKm(a, b) {
  if ([a.lat, a.lng, b.lat, b.lng].some((v) => v == null || !Number.isFinite(Number(v)))) return null;
  const rad = (d) => (Number(d) * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Location & discovery radius. Uses the member's approximate pin when they shared one,
 * otherwise their city centre (manual city selection / location permission denied).
 *   within my radius → 0.6–1 (closer is better) · up to 2× radius → fades to 0 · same locality → 1
 *   no coordinates but same city → 0.7 · online-only vs in-person-only → halved.
 */
function location(a, b, radiusKm = a.radiusKm) {
  const radius = Number(radiusKm) > 0 ? Number(radiusKm) : 25;
  const d = distanceKm(a, b);
  let value = null;
  let sameCity = Boolean(a.cityId && a.cityId === b.cityId);
  if (a.localityId && a.localityId === b.localityId) value = 1;
  else if (d !== null) value = d <= radius ? 1 - 0.4 * (d / radius) : clamp01(0.6 * (1 - (d - radius) / radius));
  else if (a.cityId && b.cityId) value = sameCity ? 0.7 : 0;
  if (value === null) return { value: null, distanceKm: null, sameCity: false, withinRadius: false };
  const modes = new Set([a.connectMode, b.connectMode]);
  if (modes.has('online') && modes.has('in_person')) value *= 0.5;
  return { value: clamp01(value), distanceKm: d, sameCity, sameLocality: Boolean(a.localityId && a.localityId === b.localityId), withinRadius: d !== null && d <= radius };
}

const titleTokens = (t) => new Set(canon(t).split(/[^a-z0-9+#.]+/).filter((w) => w.length > 2 && !STOP.has(w)));
const STOP = new Set(['and', 'the', 'for', 'senior', 'junior', 'lead', 'head', 'associate', 'intern', 'manager', 'executive', 'specialist']);

/** Professional relevance: same industry (50%), similar experience (30%), related job title (20%). */
function professional(a, b) {
  const parts = [];
  if (a.industryId && b.industryId) parts.push(['industry', 0.5, a.industryId === b.industryId ? 1 : 0]);
  if (a.expRank != null && b.expRank != null) parts.push(['experience', 0.3, clamp01(1 - Math.abs(a.expRank - b.expRank) / 3)]);
  const ta = titleTokens(a.jobTitle);
  const tb = titleTokens(b.jobTitle);
  if (ta.size && tb.size) parts.push(['title', 0.2, intersect(ta, tb) ? 1 : 0]);
  if (!parts.length) return { value: null };
  // Missing parts count as 0 — no redistribution, so thin profiles can't look perfect.
  const value = parts.reduce((s, [, w, v]) => s + w * v, 0);
  const get = (k) => parts.find((p) => p[0] === k)?.[2];
  return { value: clamp01(value), sameIndustry: get('industry') === 1, similarExperience: (get('experience') ?? 0) >= 0.66 };
}

module.exports = { clamp01, canon, setSimilarity, complementarity, skills, interests, intentDirection, intent, distanceKm, location, professional, titleTokens };
