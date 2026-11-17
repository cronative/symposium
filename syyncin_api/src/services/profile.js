const db = require('../config/db');
const { fileUrl } = require('../utils/format');

/** Onboarding steps (matches the app):
 * 1 About you · 2 Work · 3 Interests · 4 Mindset · 5 Community · 6 Selfie · 7 Done */
const STEPS = { basic: 1, work: 2, interests: 3, mindset: 4, community: 5, selfie: 6, done: 7 };
const STEP_NAMES = { 1: 'basic', 2: 'work', 3: 'interests', 4: 'mindset', 5: 'community', 6: 'selfie', 7: 'done' };

/** Full profile with resolved master-data labels. */
async function loadProfile(userId, conn) {
  const u = await db.one(
    `SELECT u.*, i.name AS industry_name, e.label AS experience_label,
            c.name AS city_name, c.state AS city_state, l.name AS locality_name
       FROM users u
       LEFT JOIN industries i ON i.id = u.industry_id
       LEFT JOIN experience_levels e ON e.id = u.experience_level_id
       LEFT JOIN cities c ON c.id = u.city_id
       LEFT JOIN localities l ON l.id = u.locality_id
      WHERE u.id = :id`,
    { id: userId },
    conn,
  );
  if (!u) return null;

  const [skills, interests, reasons, mindset] = await Promise.all([
    db.query('SELECT s.id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :id ORDER BY s.sort_order', { id: userId }, conn),
    db.query('SELECT x.id, x.name FROM user_interests ui JOIN interests x ON x.id = ui.interest_id WHERE ui.user_id = :id ORDER BY x.sort_order', { id: userId }, conn),
    db.query('SELECT r.id, r.title, r.icon FROM user_reasons ur JOIN reasons r ON r.id = ur.reason_id WHERE ur.user_id = :id ORDER BY r.sort_order', { id: userId }, conn),
    db.query(
      `SELECT a.question_id AS questionId, q.question, a.option_id AS optionId, o.label AS answer
         FROM user_mindset_answers a
         JOIN mindset_questions q ON q.id = a.question_id
         JOIN mindset_options o ON o.id = a.option_id
        WHERE a.user_id = :id ORDER BY q.sort_order`,
      { id: userId },
      conn,
    ),
  ]);

  let availability = u.availability;
  if (typeof availability === 'string') availability = JSON.parse(availability);

  return {
    id: u.id,
    phone: u.phone,
    email: u.email,
    fullName: u.full_name,
    dob: u.dob,
    gender: u.gender,
    linkedinUrl: u.linkedin_url,
    about: u.about,
    photoUrl: fileUrl(u.photo_path),
    work: {
      jobTitle: u.job_title,
      industry: u.industry_id ? { id: u.industry_id, name: u.industry_name } : null,
      company: u.company,
      experienceLevel: u.experience_level_id ? { id: u.experience_level_id, label: u.experience_label } : null,
      skills,
    },
    interests,
    reasons,
    mindset,
    community: {
      city: u.city_id ? { id: u.city_id, name: u.city_name, state: u.city_state } : null,
      locality: u.locality_id ? { id: u.locality_id, name: u.locality_name } : null,
      lat: u.lat,
      lng: u.lng,
      connectMode: u.connect_mode,
      radiusKm: u.radius_km,
      availability: availability || [],
      nearbyDiscovery: Boolean(u.nearby_discovery),
      openToConnect: Boolean(u.open_to_connect),
    },
    onboarding: { step: u.onboarding_step, stepName: STEP_NAMES[u.onboarding_step], completed: u.onboarding_step >= STEPS.done },
    verificationStatus: u.verification_status,
    status: u.status,
    createdAt: u.created_at,
  };
}

/** Advance onboarding_step only forward (re-editing an earlier step never moves it back). */
async function advanceStep(userId, toStep, conn) {
  await db.query('UPDATE users SET onboarding_step = GREATEST(onboarding_step, :s) WHERE id = :id', { s: toStep, id: userId }, conn);
}

module.exports = { STEPS, STEP_NAMES, loadProfile, advanceStep };
