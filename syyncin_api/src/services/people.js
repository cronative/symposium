/**
 * Member cards for KYN / Filters / Profile / Inbox.
 * One card shape everywhere so the app can reuse a single model.
 */
const db = require('../config/db');
const { fileUrl } = require('../utils/format');

/** Members other people can see at all (active + finished onboarding). */
const VISIBLE = "u.status = 'active' AND u.onboarding_step >= 7";

const pair = (a, b) => (a < b ? [a, b] : [b, a]);
const initials = (name) =>
  String(name || '')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('');

/** Where distances are measured from: the user's own pin, else their city centre. */
async function originOf(user) {
  if (user.lat != null && user.lng != null) return { lat: Number(user.lat), lng: Number(user.lng) };
  if (!user.city_id) return null;
  const c = await db.one('SELECT lat, lng FROM cities WHERE id = :id', { id: user.city_id });
  return c && c.lat != null ? { lat: Number(c.lat), lng: Number(c.lng) } : null;
}

/** Haversine distance (km) from :oLat/:oLng to the member's pin or city centre. */
const distanceSql = (origin) =>
  origin
    ? `(6371 * 2 * ASIN(SQRT(
          POW(SIN(RADIANS(COALESCE(u.lat, c.lat) - :oLat) / 2), 2) +
          COS(RADIANS(:oLat)) * COS(RADIANS(COALESCE(u.lat, c.lat))) *
          POW(SIN(RADIANS(COALESCE(u.lng, c.lng) - :oLng) / 2), 2))))`
    : 'NULL';

const CARD_FROM = `
  FROM users u
  LEFT JOIN industries i ON i.id = u.industry_id
  LEFT JOIN experience_levels e ON e.id = u.experience_level_id
  LEFT JOIN cities c ON c.id = u.city_id
  LEFT JOIN localities l ON l.id = u.locality_id`;

const cardSelect = (origin) => `
  SELECT u.id, u.full_name, u.photo_path, u.job_title, u.company, u.verification_status, u.open_to_connect,
         u.nearby_discovery, u.connect_mode, u.created_at,
         u.industry_id, i.name AS industry_name, u.experience_level_id, e.label AS experience_label,
         u.city_id, c.name AS city_name, u.locality_id, l.name AS locality_name,
         ${distanceSql(origin)} AS distance_km`;

/** Connection state between `meId` and each of `ids`. */
async function relationMap(meId, ids) {
  const map = new Map(ids.map((id) => [id, { status: 'none', requestId: null, connectedAt: null }]));
  if (!ids.length) return map;
  const [conns, reqs] = await Promise.all([
    db.query(
      `SELECT user_a_id, user_b_id, created_at FROM connections
        WHERE (user_a_id = :me AND user_b_id IN (:ids)) OR (user_b_id = :me AND user_a_id IN (:ids))`,
      { me: meId, ids },
    ),
    db.query(
      `SELECT id, sender_id, receiver_id FROM connection_requests
        WHERE status = 'pending' AND ((sender_id = :me AND receiver_id IN (:ids)) OR (receiver_id = :me AND sender_id IN (:ids)))`,
      { me: meId, ids },
    ),
  ]);
  for (const r of reqs) {
    const other = r.sender_id === meId ? r.receiver_id : r.sender_id;
    map.set(other, { status: r.sender_id === meId ? 'pending_sent' : 'pending_received', requestId: r.id, connectedAt: null });
  }
  for (const c of conns) {
    const other = c.user_a_id === meId ? c.user_b_id : c.user_a_id;
    map.set(other, { status: 'connected', requestId: null, connectedAt: c.created_at });
  }
  return map;
}

async function myInterestNames(meId) {
  const rows = await db.query('SELECT x.name FROM user_interests ui JOIN interests x ON x.id = ui.interest_id WHERE ui.user_id = :id', { id: meId });
  return new Set(rows.map((r) => r.name));
}

/** rows (from cardSelect) → API cards, with interests, shared interests, saved + connection state. */
async function toCards(rows, meId) {
  if (!rows.length) return [];
  const ids = rows.map((r) => r.id);
  const [interestRows, savedRows, relations, mine, skillRows] = await Promise.all([
    db.query(
      `SELECT ui.user_id, x.id, x.name FROM user_interests ui JOIN interests x ON x.id = ui.interest_id
        WHERE ui.user_id IN (:ids) AND x.is_active = 1 ORDER BY x.sort_order`,
      { ids },
    ),
    db.query('SELECT saved_user_id FROM saved_profiles WHERE user_id = :me AND saved_user_id IN (:ids)', { me: meId, ids }),
    relationMap(meId, ids),
    myInterestNames(meId),
    db.query(
      `SELECT us.user_id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id
        WHERE us.user_id IN (:ids) AND s.is_active = 1 ORDER BY s.sort_order, s.name`,
      { ids },
    ),
  ]);
  const skillsBy = new Map();
  for (const r of skillRows) {
    if (!skillsBy.has(r.user_id)) skillsBy.set(r.user_id, []);
    skillsBy.get(r.user_id).push(r.name);
  }
  const interestsBy = new Map();
  for (const r of interestRows) {
    if (!interestsBy.has(r.user_id)) interestsBy.set(r.user_id, []);
    interestsBy.get(r.user_id).push({ id: r.id, name: r.name });
  }
  const saved = new Set(savedRows.map((r) => r.saved_user_id));

  return rows.map((r) => {
    const list = interestsBy.get(r.id) || [];
    const rel = relations.get(r.id);
    return {
      id: r.id,
      fullName: r.full_name,
      initials: initials(r.full_name),
      photoUrl: fileUrl(r.photo_path),
      jobTitle: r.job_title,
      company: r.company,
      industry: r.industry_id ? { id: r.industry_id, name: r.industry_name } : null,
      experienceLevel: r.experience_level_id ? { id: r.experience_level_id, label: r.experience_label } : null,
      city: r.city_id ? { id: r.city_id, name: r.city_name } : null,
      locality: r.locality_id ? { id: r.locality_id, name: r.locality_name } : null,
      distanceKm: r.distance_km == null ? null : Math.round(r.distance_km * 10) / 10,
      verified: r.verification_status === 'verified',
      openToConnect: Boolean(r.open_to_connect),
      interests: list,
      skills: skillsBy.get(r.id) || [],
      sharedInterests: r.id === meId ? [] : list.filter((x) => mine.has(x.name)).map((x) => x.name),
      isSaved: saved.has(r.id),
      connection: r.id === meId ? { status: 'self', requestId: null, connectedAt: null } : rel,
    };
  });
}

/** Load cards for specific user ids (keeps the given order). */
async function cardsByIds(me, ids) {
  if (!ids.length) return [];
  const origin = await originOf(me);
  const rows = await db.query(`${cardSelect(origin)} ${CARD_FROM} WHERE u.id IN (:ids)`, { ids, oLat: origin?.lat, oLng: origin?.lng });
  const cards = await toCards(rows, me.id);
  const byId = new Map(cards.map((c) => [c.id, c]));
  return ids.map((id) => byId.get(id)).filter(Boolean);
}

/**
 * Can `me` open this member's profile?
 * Hidden members (nearby discovery off) stay reachable for existing connections / requests.
 */
async function canView(me, target) {
  if (!target || target.status !== 'active' || target.onboarding_step < 7) return false;
  if (target.id === me.id || target.nearby_discovery) return true;
  const [a, b] = pair(me.id, target.id);
  const rel = await db.one(
    `SELECT 1 AS x FROM connections WHERE user_a_id = :a AND user_b_id = :b
     UNION SELECT 1 FROM connection_requests WHERE status = 'pending' AND pending_pair = CONCAT(:a, '-', :b)`,
    { a, b },
  );
  return Boolean(rel);
}

module.exports = { VISIBLE, CARD_FROM, pair, initials, originOf, distanceSql, cardSelect, relationMap, toCards, cardsByIds, canView, myInterestNames };
