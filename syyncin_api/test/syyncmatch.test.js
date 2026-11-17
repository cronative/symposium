/**
 * SyyncMatch unit tests — pure scoring, no database.  Run: node --test test/
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const F = require('../src/services/match/factors');
const E = require('../src/services/match/engine');
const cfg = require('../src/services/match/config');

const SKILLS = { 1: 'UI/UX Design', 2: 'Product Management', 3: 'Flutter', 4: 'iOS (Swift)', 7: 'Node.js', 11: 'Sales', 12: 'Business Development', 20: 'Photography' };

/** Build a feature profile like engine.loadProfiles does. */
function person(o = {}) {
  const skills = o.skills ?? [];
  return {
    id: o.id ?? 1,
    jobTitle: o.jobTitle ?? null,
    industryId: o.industryId ?? null,
    cityId: o.cityId ?? null,
    localityId: o.localityId ?? null,
    radiusKm: o.radiusKm ?? 25,
    connectMode: o.connectMode ?? 'both',
    lat: o.lat ?? null,
    lng: o.lng ?? null,
    expRank: o.expRank ?? null,
    skills: new Set(skills),
    skillNames: new Map(skills.map((id) => [id, SKILLS[id] || `Skill ${id}`])),
    interests: new Set(o.interests ?? []),
    intents: new Set(o.intents ?? []),
  };
}

const AHMEDABAD = { lat: 23.0225, lng: 72.5714 };
const full = (o = {}) =>
  person({ skills: [3, 7], interests: [1, 2, 3], intents: ['network', 'collaborate'], industryId: 1, expRank: 3, jobTitle: 'Flutter Developer', cityId: 1, ...AHMEDABAD, ...o });

// ── Factors ──────────────────────────────────────────────────────────────
test('skills: identical sets → 1, disjoint unrelated → 0, missing → null', () => {
  assert.equal(F.skills(person({ skills: [3, 7] }), person({ skills: [3, 7] })).value, 1);
  assert.equal(F.skills(person({ skills: [20] }), person({ skills: [11] })).value, 0);
  assert.equal(F.skills(person({ skills: [] }), person({ skills: [3] })).value, null);
});

test('skills: partial overlap is between 0 and 1 (Jaccard + overlap blend)', () => {
  const v = F.skills(person({ skills: [3, 7, 11] }), person({ skills: [3, 4] })).value;
  assert.ok(v > 0.3 && v < 1, `got ${v}`);
});

test('skills: complementary pairs help, unrelated skills do not', () => {
  const comp = F.skills(person({ skills: [1] }), person({ skills: [3] }));
  assert.ok(comp.value > 0 && comp.complementary === 1, 'UI/UX ↔ Flutter is complementary');
  assert.equal(F.skills(person({ skills: [20] }), person({ skills: [7] })).value, 0, 'Photography ↔ Node.js is not');
});

test('intent: directional — mentee ↔ mentor matches, two mentees do not', () => {
  assert.equal(F.intent(person({ intents: ['seeking_mentor'] }), person({ intents: ['offering_mentorship'] })).value, 1);
  assert.equal(F.intent(person({ intents: ['seeking_mentor'] }), person({ intents: ['seeking_mentor'] })).value, 0);
  assert.equal(F.intent(person({ intents: ['hiring'] }), person({ intents: ['open_to_work'] })).value, 1);
});

test('intent: same goal → 1, missing → null', () => {
  assert.equal(F.intent(person({ intents: ['collaborate'] }), person({ intents: ['collaborate'] })).value, 1);
  assert.equal(F.intent(person({ intents: [] }), person({ intents: ['collaborate'] })).value, null);
});

test('interests: shared count and similarity', () => {
  const r = F.interests(person({ interests: [1, 2, 3] }), person({ interests: [3, 4] }));
  assert.equal(r.shared, 1);
  assert.ok(r.value > 0 && r.value < 1);
  assert.equal(F.interests(person(), person({ interests: [1] })).value, null);
});

test('location: same spot → 1, far away → 0, city-only fallback, missing → null', () => {
  assert.equal(F.location(person(AHMEDABAD), person(AHMEDABAD)).value, 1);
  assert.equal(F.location(person({ ...AHMEDABAD, radiusKm: 25 }), person({ lat: 19.076, lng: 72.8777 })).value, 0); // Mumbai
  assert.equal(F.location(person({ cityId: 1 }), person({ cityId: 1 })).value, 0.7);
  assert.equal(F.location(person({ cityId: 1 }), person({ cityId: 2 })).value, 0);
  assert.equal(F.location(person(), person()).value, null);
});

test('location: within radius scores more the closer it is; online-only vs in-person-only is halved', () => {
  const me = person({ ...AHMEDABAD, radiusKm: 25 });
  const near = F.location(me, person({ lat: 23.05, lng: 72.6 })).value;
  const mid = F.location(me, person({ lat: 23.2, lng: 72.6 })).value;
  assert.ok(near > mid && mid >= 0.6);
  const clash = F.location(person({ ...AHMEDABAD, connectMode: 'online' }), person({ ...AHMEDABAD, connectMode: 'in_person' })).value;
  assert.equal(clash, 0.5);
});

test('professional: industry, experience and title; nothing known → null', () => {
  assert.equal(F.professional(person({ industryId: 1, expRank: 3, jobTitle: 'Flutter Developer' }), person({ industryId: 1, expRank: 3, jobTitle: 'Senior Flutter Engineer' })).value, 1);
  assert.equal(F.professional(person(), person()).value, null);
  assert.ok(F.professional(person({ industryId: 1 }), person({ industryId: 1 })).value === 0.5, 'missing parts are not redistributed');
});

// ── Combined score ───────────────────────────────────────────────────────
test('KYN: identical complete profiles score 100 / excellent; breakdown adds up', () => {
  const r = E.scoreKyn(full({ id: 1 }), full({ id: 2 }));
  assert.equal(r.score, 100);
  assert.equal(r.level, 'excellent');
  assert.equal(Object.values(r.breakdown).reduce((a, b) => a + b, 0), r.score);
  assert.deepEqual(r.breakdown, { skills: 30, intent: 25, interests: 20, location: 15, professional: 10 });
  assert.ok(r.reasons.length >= 2 && r.reasons.length <= 3 && r.reasons.includes('Shared Skills'));
});

test('KYN: incompatible profiles score low', () => {
  const r = E.scoreKyn(
    full({ id: 1, intents: ['seeking_mentor'] }),
    person({ id: 2, skills: [20], interests: [9], intents: ['seeking_mentor'], industryId: 5, expRank: 1, jobTitle: 'Photographer', lat: 19.076, lng: 72.8777 }),
  );
  assert.ok(r.score < 50, `got ${r.score}`);
  assert.equal(r.level, 'low');
  assert.deepEqual(r.reasons, []);
});

test('KYN: missing data never looks like a perfect match and is flagged insufficient', () => {
  const r = E.scoreKyn(full({ id: 1 }), person({ id: 2, interests: [1, 2, 3] }));
  assert.ok(r.score <= 20, `got ${r.score}`);
  assert.equal(r.insufficient, true);
  assert.equal(r.level, 'insufficient');
  assert.deepEqual(r.reasons, []);
});

test('scores stay within 0–100 for random profiles; breakdown always sums to score', () => {
  let seed = 42;
  const rnd = (n) => { seed = (seed * 1103515245 + 12345) % 2 ** 31; return seed % n; };
  const ids = Object.keys(SKILLS).map(Number);
  const keys = Object.keys(cfg.AFFINITY);
  for (let i = 0; i < 500; i++) {
    const mk = (id) => person({
      id,
      skills: ids.filter(() => rnd(3) === 0),
      interests: [1, 2, 3, 4, 5, 6].filter(() => rnd(2) === 0),
      intents: keys.filter(() => rnd(4) === 0),
      industryId: rnd(3) || null,
      expRank: rnd(6) || null,
      lat: rnd(2) ? 22 + rnd(300) / 100 : null,
      lng: 72 + rnd(100) / 100,
      cityId: rnd(3) || null,
    });
    const r = E.scoreKyn(mk(1), mk(2));
    assert.ok(r.score >= 0 && r.score <= 100);
    assert.equal(Object.values(r.breakdown).reduce((a, b) => a + b, 0), r.score);
  }
});

test('levels: boundaries 85 / 70 / 50', () => {
  assert.equal(E.levelOf(100).key, 'excellent');
  assert.equal(E.levelOf(85).key, 'excellent');
  assert.equal(E.levelOf(84).key, 'strong');
  assert.equal(E.levelOf(70).key, 'strong');
  assert.equal(E.levelOf(69).key, 'potential');
  assert.equal(E.levelOf(50).key, 'potential');
  assert.equal(E.levelOf(49).key, 'low');
  assert.equal(E.levelOf(0).key, 'low');
});

test('ordering is deterministic: score ↓, coverage ↓, id ↑', () => {
  const m = (score, coverage = 1) => ({ score, coverage });
  const list = [{ id: 5, match: m(80) }, { id: 2, match: m(80) }, { id: 9, match: m(90) }, { id: 3, match: m(80, 0.7) }];
  assert.deepEqual([...list].sort(E.byMatch).map((x) => x.id), [9, 2, 5, 3]);
  assert.deepEqual([...list].reverse().sort(E.byMatch).map((x) => x.id), [9, 2, 5, 3]);
});

// ── Seek ─────────────────────────────────────────────────────────────────
test('Seek: expertise dominates — a Flutter expert outranks a nearby non-expert', () => {
  const me = full({ id: 1, skills: [2], intents: ['collaborate'] });
  const req = { skills: new Set([3]), skillNames: new Map([[3, 'Flutter']]), terms: new Set(), intents: new Set(), industryId: null, minExpRank: null };
  const expert = E.scoreSeek(req, me, full({ id: 2, skills: [3, 7], lat: 23.3, lng: 72.6 }));
  const nearby = E.scoreSeek(req, me, full({ id: 3, skills: [11] }));
  assert.ok(expert.score > nearby.score, `${expert.score} vs ${nearby.score}`);
  assert.ok(expert.reasons.includes('Required Expertise'));
  assert.ok(!nearby.reasons.includes('Required Expertise'));
  assert.equal(Object.values(expert.breakdown).reduce((a, b) => a + b, 0), expert.score);
});

test('Seek: keyword search matches job titles; minimum experience is respected', () => {
  const me = full({ id: 1 });
  const req = { skills: new Set(), skillNames: new Map(), terms: new Set(['flutter']), intents: new Set(), industryId: null, minExpRank: 4 };
  const senior = E.scoreSeek(req, me, full({ id: 2, skills: [], jobTitle: 'Flutter Lead', expRank: 5 }));
  const junior = E.scoreSeek(req, me, full({ id: 3, skills: [], jobTitle: 'Flutter Intern', expRank: 1 }));
  assert.ok(senior.score > junior.score);
});

test('weights add up to 1 for both strategies', () => {
  const sum = (w) => Object.values(w).reduce((a, b) => a + b, 0);
  assert.ok(Math.abs(sum(cfg.KYN_WEIGHTS) - 1) < 1e-9);
  assert.ok(Math.abs(sum(cfg.SEEK_WEIGHTS) - 1) < 1e-9);
});
