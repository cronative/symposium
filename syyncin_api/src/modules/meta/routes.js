const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { ah, ok } = require('../../utils/http');
const { validate } = require('../../middleware');

/** Public, read-only lookups for the app. Only active items, in admin-set order. */
const router = express.Router();

router.get('/industries', ah(async (_q, res) =>
  ok(res, await db.query('SELECT id, name FROM industries WHERE is_active = 1 ORDER BY sort_order, name'), 'Industries fetched successfully.')));

router.get('/experience-levels', ah(async (_q, res) =>
  ok(res, await db.query('SELECT id, label, min_years AS minYears, max_years AS maxYears FROM experience_levels WHERE is_active = 1 ORDER BY sort_order, id'), 'Experience levels fetched successfully.')));

router.get('/interests', ah(async (_q, res) =>
  ok(res, await db.query('SELECT id, name, icon FROM interests WHERE is_active = 1 ORDER BY sort_order, name'), 'Interests fetched successfully.')));

router.get('/reasons', ah(async (_q, res) =>
  ok(res, await db.query('SELECT id, title, subtitle, icon FROM reasons WHERE is_active = 1 ORDER BY sort_order, id'), 'Reasons fetched successfully.')));

router.get(
  '/skills',
  validate(z.object({ q: z.string().max(60).optional(), industryId: z.coerce.number().int().positive().optional() }), 'query'),
  ah(async (req, res) => {
    const { q, industryId } = req.validQuery;
    const rows = await db.query(
      `SELECT id, name, industry_id AS industryId FROM skills
        WHERE is_active = 1
          ${q ? 'AND name LIKE :q' : ''}
          ${industryId ? 'AND (industry_id = :ind OR industry_id IS NULL)' : ''}
        ORDER BY sort_order, name LIMIT 50`,
      { q: `%${q || ''}%`, ind: industryId || null },
    );
    ok(res, rows, rows.length ? 'Skills fetched successfully.' : 'No skills match your search.');
  }),
);

router.get('/mindset-questions', ah(async (_q, res) => {
  const qs = await db.query('SELECT id, question FROM mindset_questions WHERE is_active = 1 ORDER BY sort_order, id');
  const opts = qs.length
    ? await db.query(
        'SELECT id, question_id AS questionId, label FROM mindset_options WHERE is_active = 1 AND question_id IN (:ids) ORDER BY sort_order, id',
        { ids: qs.map((q) => q.id) },
      )
    : [];
  ok(res, qs.map((q) => ({ ...q, options: opts.filter((o) => o.questionId === q.id).map(({ id, label }) => ({ id, label })) })), 'Mindset questions fetched successfully.');
}));

router.get(
  '/cities',
  validate(z.object({ q: z.string().max(60).optional() }), 'query'),
  ah(async (req, res) => {
    const { q } = req.validQuery;
    ok(res, await db.query(
      `SELECT id, name, state, lat, lng FROM cities WHERE is_active = 1 ${q ? 'AND name LIKE :q' : ''}
        ORDER BY sort_order, name LIMIT 50`,
      { q: `${q || ''}%` },
    ), 'Cities fetched successfully.');
  }),
);

router.get(
  '/localities',
  validate(z.object({ cityId: z.coerce.number().int().positive(), q: z.string().max(60).optional() }), 'query'),
  ah(async (req, res) => {
    const { cityId, q } = req.validQuery;
    ok(res, await db.query(
      `SELECT id, name FROM localities WHERE is_active = 1 AND city_id = :c ${q ? 'AND name LIKE :q' : ''}
        ORDER BY sort_order, name LIMIT 100`,
      { c: cityId, q: `%${q || ''}%` },
    ), 'Localities fetched successfully.');
  }),
);

module.exports = router;
