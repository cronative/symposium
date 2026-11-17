/**
 * SyyncMatch configuration — weights, intent affinities and complementary skills.
 * Bump VERSION whenever weights or rules change; the API returns it with every score
 * (`algorithmVersion`), so the app never needs a release to pick up new weights.
 *
 * Weights can be overridden without a code change via env, e.g.
 *   SYYNCMATCH_KYN_WEIGHTS='{"skills":0.3,"intent":0.25,"interests":0.2,"location":0.15,"professional":0.1}'
 */
const VERSION = 'syyncmatch-1.0';

function weightsFrom(envName, defaults) {
  try {
    const raw = process.env[envName];
    if (!raw) return defaults;
    const w = { ...defaults, ...JSON.parse(raw) };
    const sum = Object.values(w).reduce((a, b) => a + Number(b || 0), 0);
    if (!(sum > 0.99 && sum < 1.01)) throw new Error(`weights must add up to 1 (got ${sum})`);
    return w;
  } catch (e) {
    console.error(`[syyncmatch] ignoring ${envName}: ${e.message}`);
    return defaults;
  }
}

const KYN_WEIGHTS = weightsFrom('SYYNCMATCH_KYN_WEIGHTS', { skills: 0.3, intent: 0.25, interests: 0.2, location: 0.15, professional: 0.1 });
const SEEK_WEIGHTS = weightsFrom('SYYNCMATCH_SEEK_WEIGHTS', { expertise: 0.45, intent: 0.25, experience: 0.15, location: 0.1, interests: 0.05 });

/** 85–100 excellent · 70–84 strong · 50–69 potential · 0–49 low. */
const LEVELS = [
  { min: 85, key: 'excellent', label: 'Excellent Match' },
  { min: 70, key: 'strong', label: 'Strong Match' },
  { min: 50, key: 'potential', label: 'Potential Match' },
  { min: 0, key: 'low', label: 'Low Compatibility' },
];

/** Below this share of known factors (by weight) the score is flagged "insufficient" instead of shown as a verdict. */
const MIN_COVERAGE = 0.6;

/** Candidate pool scored per request (nearest first) — keeps scoring fast on large datasets. */
const CANDIDATE_POOL = Number(process.env.SYYNCMATCH_POOL) || 800;

/** Seconds a computed ranking is reused (also invalidated on any profile / settings change). */
const CACHE_TTL_S = 120;

/**
 * Connection intents → canonical keys (matched on the reason title, case-insensitive).
 * Unknown titles fall back to a slug of the title, so new reasons still match themselves.
 */
const INTENT_KEYS = {
  'grow my network': 'network',
  'exchange ideas': 'ideas',
  'find collaborators': 'collaborate',
  'learn from others': 'learn',
  'explore opportunities': 'opportunities',
  'meet in person': 'in_person',
  'seeking a mentor': 'seeking_mentor',
  'seeking mentor': 'seeking_mentor',
  'open to mentoring': 'offering_mentorship',
  'mentor others': 'offering_mentorship',
  'hiring': 'hiring',
  'open to work': 'open_to_work',
};

/**
 * Directional affinity: AFFINITY[what I want][what they want] (0–1). Missing pair = 0.
 * Mentor/mentee and hiring/job-seeking are complementary, not symmetric:
 * two people both "Seeking a mentor" do not match each other.
 */
const AFFINITY = {
  network: { network: 1, ideas: 0.6, collaborate: 0.6, learn: 0.6, opportunities: 0.6, in_person: 0.6 },
  ideas: { ideas: 1, learn: 0.8, collaborate: 0.7, network: 0.5, offering_mentorship: 0.5 },
  collaborate: { collaborate: 1, opportunities: 0.8, ideas: 0.7, network: 0.5 },
  learn: { learn: 1, ideas: 0.8, offering_mentorship: 0.9, network: 0.5 },
  opportunities: { opportunities: 1, collaborate: 0.8, network: 0.6, hiring: 0.8 },
  in_person: { in_person: 1, network: 0.5 },
  seeking_mentor: { offering_mentorship: 1, learn: 0.3 },
  offering_mentorship: { seeking_mentor: 1, learn: 0.8 },
  hiring: { open_to_work: 1, opportunities: 0.7 },
  open_to_work: { hiring: 1, opportunities: 0.6 },
};

/**
 * Skills that work well together (by canonical lower-case name). Only listed pairs count —
 * unrelated skills are never treated as compatible.
 */
const COMPLEMENTARY = [
  ['ui/ux design', 'flutter'], ['ui/ux design', 'ios (swift)'], ['ui/ux design', 'android (kotlin)'], ['ui/ux design', 'react'],
  ['ui/ux design', 'product management'], ['ui/ux design', 'graphic design'],
  ['product management', 'flutter'], ['product management', 'react'], ['product management', 'node.js'], ['product management', 'data analysis'],
  ['flutter', 'node.js'], ['react', 'node.js'], ['ios (swift)', 'node.js'], ['android (kotlin)', 'node.js'],
  ['data analysis', 'machine learning'], ['data analysis', 'digital marketing'],
  ['digital marketing', 'seo'], ['digital marketing', 'content writing'], ['seo', 'content writing'], ['digital marketing', 'graphic design'],
  ['sales', 'business development'], ['sales', 'digital marketing'], ['business development', 'finance'],
  ['leadership', 'project management'], ['project management', 'product management'], ['public speaking', 'leadership'],
  ['photography', 'graphic design'], ['photography', 'content writing'],
];

module.exports = { VERSION, KYN_WEIGHTS, SEEK_WEIGHTS, LEVELS, MIN_COVERAGE, CANDIDATE_POOL, CACHE_TTL_S, INTENT_KEYS, AFFINITY, COMPLEMENTARY };
