/**
 * Profile sections shared by onboarding (one step at a time) and
 * PUT /me/profile (Edit Profile — any number of sections at once).
 *
 * Each section = { schema, check(body, conn), save(conn, userId, body) }.
 *  - schema: zod validation (shape, lengths, enums)
 *  - check:  rules that need the database (ids exist + active, age, mindset completeness)
 *  - save:   writes; a section replaces what was there before (like the setup step).
 */
const { z } = require('zod');
const env = require('../config/env');
const db = require('../config/db');
const { ApiError } = require('../utils/http');
const { ageOn } = require('../utils/format');

const id = z.coerce.number().int().positive();
const ids = z.array(id).transform((a) => [...new Set(a)]);
const optionalText = (max) => z.string().trim().max(max).optional().transform((v) => (v ? v : null));

const GENDERS = ['woman', 'man', 'other', 'prefer_not_to_say'];
const CONNECT_MODES = ['in_person', 'online', 'both'];
const AVAILABILITY = ['weekdays', 'weekends', 'evenings', 'flexible'];

/** Ensure every id exists and is active in a master table. */
async function assertActive(table, list, label, conn) {
  if (!list.length) return;
  const rows = await db.query(`SELECT id FROM ${table} WHERE is_active = 1 AND id IN (:ids)`, { ids: list }, conn);
  if (rows.length !== list.length) throw new ApiError(400, 'INVALID_SELECTION', `One or more selected ${label} are not available.`);
}

async function replaceLinks(conn, table, col, userId, list) {
  await db.query(`DELETE FROM ${table} WHERE user_id = :u`, { u: userId }, conn);
  if (list.length) await db.query(`INSERT INTO ${table} (user_id, ${col}) VALUES ?`, [list.map((v) => [userId, v])], conn);
}

const basic = {
  schema: z.object({
    fullName: z.string().trim().min(2, 'Enter your full name.').max(120),
    dob: z.iso.date().optional().nullable(),
    linkedinUrl: z
      .string()
      .trim()
      .max(255)
      .regex(/^(https?:\/\/)?([a-z]{2,3}\.)?linkedin\.com\/in\/[A-Za-z0-9_\-%]+\/?$/i, 'Enter a valid LinkedIn profile URL.')
      .optional()
      .nullable()
      .or(z.literal('').transform(() => undefined)),
    gender: z.enum(GENDERS).optional().nullable(),
    about: z.string().trim().max(500, 'Keep your bio under 500 characters.').optional().nullable(),
  }),
  async check(b) {
    if (!b.dob) return;
    const age = ageOn(b.dob);
    if (age < 0 || age > 110) throw new ApiError(400, 'INVALID_DOB', 'Enter a valid date of birth.');
    if (age < env.rules.minAge) throw new ApiError(400, 'AGE_RESTRICTED', `SyyncIn is for members aged ${env.rules.minAge} and above.`);
  },
  async save(conn, userId, b) {
    await db.query(
      `UPDATE users SET full_name = :n, dob = :d, linkedin_url = :l, gender = :g
              ${b.about !== undefined ? ', about = :a' : ''} WHERE id = :id`,
      { n: b.fullName, d: b.dob || null, l: b.linkedinUrl || null, g: b.gender || null, a: b.about || null, id: userId },
      conn,
    );
  },
};

const work = {
  schema: z.object({
    jobTitle: z.string().trim().min(2, 'Enter your job title.').max(120),
    industryId: id,
    company: optionalText(150),
    experienceLevelId: id,
    skillIds: ids.optional().default([]),
  }),
  async check(b, conn) {
    if (b.skillIds.length > env.rules.maxSkills) throw new ApiError(400, 'TOO_MANY_SKILLS', `Choose up to ${env.rules.maxSkills} skills.`);
    await assertActive('industries', [b.industryId], 'industries', conn);
    await assertActive('experience_levels', [b.experienceLevelId], 'experience levels', conn);
    await assertActive('skills', b.skillIds, 'skills', conn);
  },
  async save(conn, userId, b) {
    await db.query(
      'UPDATE users SET job_title = :j, industry_id = :i, company = :c, experience_level_id = :e WHERE id = :id',
      { j: b.jobTitle, i: b.industryId, c: b.company, e: b.experienceLevelId, id: userId },
      conn,
    );
    await replaceLinks(conn, 'user_skills', 'skill_id', userId, b.skillIds);
  },
};

const interests = {
  schema: z.object({ interestIds: ids, reasonIds: ids }),
  async check({ interestIds, reasonIds }, conn) {
    if (interestIds.length < env.rules.minInterests) throw new ApiError(400, 'MIN_INTERESTS', `Choose at least ${env.rules.minInterests} interests.`);
    if (reasonIds.length < 1 || reasonIds.length > env.rules.maxReasons) {
      throw new ApiError(400, 'REASONS_RANGE', `Choose between 1 and ${env.rules.maxReasons} reasons.`);
    }
    await assertActive('interests', interestIds, 'interests', conn);
    await assertActive('reasons', reasonIds, 'reasons', conn);
  },
  async save(conn, userId, { interestIds, reasonIds }) {
    await replaceLinks(conn, 'user_interests', 'interest_id', userId, interestIds);
    await replaceLinks(conn, 'user_reasons', 'reason_id', userId, reasonIds);
  },
};

const mindset = {
  // Every question is optional: send only the ones answered (an empty list clears them).
  schema: z.object({ answers: z.array(z.object({ questionId: id, optionId: id })).max(50) }),
  async check({ answers }, conn) {
    const questions = await db.query('SELECT id FROM mindset_questions WHERE is_active = 1', {}, conn);
    const expected = new Set(questions.map((q) => q.id));
    const given = new Set(answers.map((a) => a.questionId));
    if (given.size !== answers.length) throw new ApiError(400, 'DUPLICATE_ANSWER', 'Answer each question once.');
    const extra = [...given].filter((q) => !expected.has(q));
    if (extra.length) {
      throw new ApiError(400, 'INVALID_SELECTION', 'One or more questions are no longer available.', { invalidQuestionIds: extra });
    }
    if (!answers.length) return;
    const valid = await db.query('SELECT id, question_id FROM mindset_options WHERE is_active = 1 AND id IN (:ids)', { ids: answers.map((a) => a.optionId) }, conn);
    const optQ = new Map(valid.map((o) => [o.id, o.question_id]));
    if (answers.some((a) => optQ.get(a.optionId) !== a.questionId)) {
      throw new ApiError(400, 'INVALID_SELECTION', 'One or more answers do not belong to their question.');
    }
  },
  async save(conn, userId, { answers }) {
    await db.query('DELETE FROM user_mindset_answers WHERE user_id = :u', { u: userId }, conn);
    if (!answers.length) return;
    await db.query('INSERT INTO user_mindset_answers (user_id, question_id, option_id) VALUES ?', [answers.map((a) => [userId, a.questionId, a.optionId])], conn);
  },
};

const community = {
  schema: z.object({
    cityId: id,
    localityId: id.optional().nullable(),
    lat: z.number().min(-90).max(90).optional().nullable(),
    lng: z.number().min(-180).max(180).optional().nullable(),
    connectMode: z.enum(CONNECT_MODES),
    radiusKm: z.number().int().refine((v) => env.rules.radiusOptionsKm.includes(v), 'Choose 5, 10, 25 or 50 km.'),
    availability: z.array(z.enum(AVAILABILITY)).min(1, 'Choose when you are usually available.').transform((a) => [...new Set(a)]),
    nearbyDiscovery: z.boolean(),
    openToConnect: z.boolean().optional(),
  }),
  async check(b, conn) {
    await assertActive('cities', [b.cityId], 'cities', conn);
    if (b.localityId) {
      const loc = await db.one('SELECT id FROM localities WHERE id = :l AND city_id = :c AND is_active = 1', { l: b.localityId, c: b.cityId }, conn);
      if (!loc) throw new ApiError(400, 'INVALID_SELECTION', 'That locality is not in the selected city.');
    }
  },
  async save(conn, userId, b) {
    await db.query(
      `UPDATE users SET city_id = :c, locality_id = :l, lat = :lat, lng = :lng, connect_mode = :m,
              radius_km = :r, availability = :a, nearby_discovery = :n
              ${b.openToConnect !== undefined ? ', open_to_connect = :o' : ''} WHERE id = :id`,
      {
        c: b.cityId, l: b.localityId || null, lat: b.lat ?? null, lng: b.lng ?? null, m: b.connectMode,
        r: b.radiusKm, a: JSON.stringify(b.availability), n: b.nearbyDiscovery ? 1 : 0, o: b.openToConnect ? 1 : 0, id: userId,
      },
      conn,
    );
  },
};

const settings = {
  schema: z
    .object({ openToConnect: z.boolean().optional(), nearbyDiscovery: z.boolean().optional() })
    .refine((v) => v.openToConnect !== undefined || v.nearbyDiscovery !== undefined, 'Send openToConnect and/or nearbyDiscovery.'),
  async check() {},
  async save(conn, userId, b) {
    const sets = [];
    if (b.openToConnect !== undefined) sets.push(`open_to_connect = ${b.openToConnect ? 1 : 0}`);
    if (b.nearbyDiscovery !== undefined) sets.push(`nearby_discovery = ${b.nearbyDiscovery ? 1 : 0}`);
    await db.query(`UPDATE users SET ${sets.join(', ')} WHERE id = :id`, { id: userId }, conn);
  },
};

const SECTIONS = { basic, work, interests, mindset, community, settings };

module.exports = { SECTIONS, GENDERS, CONNECT_MODES, AVAILABILITY, assertActive };
