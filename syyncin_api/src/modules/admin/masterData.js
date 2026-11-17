const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { ApiError, ah, ok, created, okList, errors, paging } = require('../../utils/http');
const { camel } = require('../../utils/format');
const { validate, idParam } = require('../../middleware');

const name = (max) => z.string().trim().min(1, 'Required.').max(max);
const icon = z.string().trim().regex(/^[a-z0-9_]{1,40}$/, 'Use a lowercase icon key, e.g. "users".');
const fk = z.number().int().positive();
const common = { isActive: z.boolean().optional(), sortOrder: z.number().int().min(0).optional() };

/**
 * Master-data types. Each entry drives the 7 generic admin endpoints.
 *  fields  : API key → { col, schema }  (create requires all non-optional)
 *  search  : columns for ?search=
 *  filters : query param → column (e.g. ?cityId=)
 *  usage   : SQL counting references; >0 → DELETE deactivates instead of removing
 */
const TYPES = {
  industries: {
    table: 'industries',
    label: 'Industry',
    fields: { name: { col: 'name', schema: name(100) } },
    search: ['t.name'],
    usage: ['SELECT COUNT(*) n FROM users WHERE industry_id = :id', 'SELECT COUNT(*) n FROM skills WHERE industry_id = :id'],
  },
  'experience-levels': {
    table: 'experience_levels',
    label: 'Experience level',
    fields: {
      label: { col: 'label', schema: name(50) },
      minYears: { col: 'min_years', schema: z.number().int().min(0).max(60).nullable().optional() },
      maxYears: { col: 'max_years', schema: z.number().int().min(0).max(60).nullable().optional() },
    },
    search: ['t.label'],
    refine: (b) => b.minYears == null || b.maxYears == null || b.maxYears >= b.minYears || 'maxYears must be ≥ minYears.',
    usage: ['SELECT COUNT(*) n FROM users WHERE experience_level_id = :id'],
  },
  skills: {
    table: 'skills',
    label: 'Skill',
    fields: {
      name: { col: 'name', schema: name(80) },
      industryId: { col: 'industry_id', schema: fk.nullable().optional() },
    },
    select: 't.*, i.name AS industry_name',
    joins: 'LEFT JOIN industries i ON i.id = t.industry_id',
    search: ['t.name'],
    filters: { industryId: 't.industry_id' },
    usage: ['SELECT COUNT(*) n FROM user_skills WHERE skill_id = :id'],
  },
  interests: {
    table: 'interests',
    label: 'Interest',
    fields: {
      name: { col: 'name', schema: name(60) },
      icon: { col: 'icon', schema: icon.nullable().optional() },
    },
    search: ['t.name'],
    usage: ['SELECT COUNT(*) n FROM user_interests WHERE interest_id = :id'],
  },
  reasons: {
    table: 'reasons',
    label: 'Reason',
    fields: {
      title: { col: 'title', schema: name(80) },
      subtitle: { col: 'subtitle', schema: name(160) },
      icon: { col: 'icon', schema: icon },
    },
    search: ['t.title', 't.subtitle'],
    usage: ['SELECT COUNT(*) n FROM user_reasons WHERE reason_id = :id'],
  },
  cities: {
    table: 'cities',
    label: 'City',
    fields: {
      name: { col: 'name', schema: name(80) },
      state: { col: 'state', schema: name(80) },
      lat: { col: 'lat', schema: z.number().min(-90).max(90).nullable().optional() },
      lng: { col: 'lng', schema: z.number().min(-180).max(180).nullable().optional() },
    },
    select: 't.*, (SELECT COUNT(*) FROM localities l WHERE l.city_id = t.id) AS locality_count',
    search: ['t.name', 't.state'],
    usage: ['SELECT COUNT(*) n FROM users WHERE city_id = :id', 'SELECT COUNT(*) n FROM localities WHERE city_id = :id'],
  },
  localities: {
    table: 'localities',
    label: 'Locality',
    fields: {
      cityId: { col: 'city_id', schema: fk },
      name: { col: 'name', schema: name(100) },
    },
    select: 't.*, c.name AS city_name',
    joins: 'JOIN cities c ON c.id = t.city_id',
    search: ['t.name', 'c.name'],
    filters: { cityId: 't.city_id' },
    usage: ['SELECT COUNT(*) n FROM users WHERE locality_id = :id'],
  },
  'mindset-questions': {
    table: 'mindset_questions',
    label: 'Question',
    fields: { question: { col: 'question', schema: name(160) } },
    createExtra: { options: z.array(name(60)).min(2).max(6).optional() },
    search: ['t.question'],
    usage: ['SELECT COUNT(*) n FROM user_mindset_answers WHERE question_id = :id'],
    withOptions: true,
  },
};

const rowOut = (r) => camel(r);

async function attachOptions(rows) {
  if (!rows.length) return rows;
  const opts = await db.query(
    'SELECT id, question_id, label, is_active, sort_order FROM mindset_options WHERE question_id IN (:ids) ORDER BY sort_order, id',
    { ids: rows.map((r) => r.id) },
  );
  return rows.map((r) => ({ ...r, options: opts.filter((o) => o.question_id === r.id).map(camel) }));
}

async function usageCount(cfg, id) {
  let n = 0;
  for (const sql of cfg.usage) n += Number((await db.one(sql, { id })).n);
  return n;
}

function bodyToCols(cfg, body) {
  const cols = {};
  for (const [key, f] of Object.entries(cfg.fields)) if (body[key] !== undefined) cols[f.col] = body[key];
  if (body.isActive !== undefined) cols.is_active = body.isActive ? 1 : 0;
  if (body.sortOrder !== undefined) cols.sort_order = body.sortOrder;
  return cols;
}

function buildRouter(type) {
  const cfg = TYPES[type];
  const t = cfg.table;
  const fieldSchemas = Object.fromEntries(Object.entries(cfg.fields).map(([k, f]) => [k, f.schema]));
  let createSchema = z.object({ ...fieldSchemas, ...common, ...(cfg.createExtra || {}) });
  let updateSchema = z.object(fieldSchemas).partial().extend(common);
  if (cfg.refine) {
    const rule = (val, ctx) => {
      const r = cfg.refine(val);
      if (r !== true) ctx.addIssue({ code: 'custom', message: r });
    };
    createSchema = createSchema.superRefine(rule);
    updateSchema = updateSchema.superRefine(rule);
  }
  const select = `SELECT ${cfg.select || 't.*'} FROM ${t} t ${cfg.joins || ''}`;
  const getOne = async (id) => {
    const r = await db.one(`${select} WHERE t.id = :id`, { id });
    if (!r) throw errors.notFound(cfg.label);
    const out = rowOut(r);
    return cfg.withOptions ? (await attachOptions([out]))[0] : out;
  };

  const router = express.Router();

  // GET /admin/<type>?search=&status=active|inactive|all&page=&limit=&<filters>
  router.get(
    '/',
    validate(z.object({
      search: z.string().max(80).optional(),
      status: z.enum(['active', 'inactive', 'all']).optional().default('all'),
      page: z.coerce.number().optional(),
      limit: z.coerce.number().optional(),
      ...Object.fromEntries(Object.keys(cfg.filters || {}).map((k) => [k, z.coerce.number().int().positive().optional()])),
    }), 'query'),
    ah(async (req, res) => {
      const q = req.validQuery;
      const p = paging(q);
      const where = ['1=1'];
      const params = { limit: p.limit, offset: p.offset };
      if (q.search) {
        where.push(`(${cfg.search.map((c) => `${c} LIKE :search`).join(' OR ')})`);
        params.search = `%${q.search}%`;
      }
      if (q.status !== 'all') where.push(`t.is_active = ${q.status === 'active' ? 1 : 0}`);
      for (const [k, col] of Object.entries(cfg.filters || {})) {
        if (q[k]) {
          where.push(`${col} = :${k}`);
          params[k] = q[k];
        }
      }
      const w = where.join(' AND ');
      const [{ total }] = await db.query(`SELECT COUNT(*) AS total FROM ${t} t ${cfg.joins || ''} WHERE ${w}`, params);
      let rows = (await db.query(`${select} WHERE ${w} ORDER BY t.sort_order, t.id LIMIT :limit OFFSET :offset`, params)).map(rowOut);
      if (cfg.withOptions) rows = await attachOptions(rows);
      okList(res, rows, p, total, `${cfg.label} list fetched successfully.`);
    }),
  );

  // PATCH /admin/<type>/reorder { ids: [...] } — position = sort order
  router.patch(
    '/reorder',
    validate(z.object({ ids: z.array(z.number().int().positive()).min(1).max(1000) })),
    ah(async (req, res) => {
      const ids = [...new Set(req.body.ids)];
      const found = await db.query(`SELECT id FROM ${t} WHERE id IN (:ids)`, { ids });
      if (found.length !== ids.length) throw new ApiError(400, 'INVALID_IDS', 'Some ids do not exist.');
      await db.tx(async (conn) => {
        for (let i = 0; i < ids.length; i++) {
          await db.query(`UPDATE ${t} SET sort_order = :o WHERE id = :id`, { o: i + 1, id: ids[i] }, conn);
        }
      });
      ok(res, { reordered: ids.length }, 'Order saved. The app now shows items in this order.');
    }),
  );

  // GET /admin/<type>/:id
  router.get('/:id', idParam, ah(async (req, res) => ok(res, await getOne(req.params.id), `${cfg.label} fetched successfully.`)));

  // POST /admin/<type>
  router.post(
    '/',
    validate(createSchema),
    ah(async (req, res) => {
      const cols = bodyToCols(cfg, req.body);
      if (cols.sort_order === undefined) {
        const r = await db.one(`SELECT COALESCE(MAX(sort_order), 0) + 1 AS n FROM ${t}`);
        cols.sort_order = r.n;
      }
      const id = await db.tx(async (conn) => {
        const keys = Object.keys(cols);
        const r = await db.query(
          `INSERT INTO ${t} (${keys.join(', ')}) VALUES (${keys.map((k) => `:${k}`).join(', ')})`,
          cols,
          conn,
        );
        if (cfg.withOptions && req.body.options?.length) {
          await db.query(
            'INSERT INTO mindset_options (question_id, label, sort_order) VALUES ?',
            [req.body.options.map((label, i) => [r.insertId, label, i + 1])],
            conn,
          );
        }
        return r.insertId;
      });
      created(res, await getOne(id), `${cfg.label} added successfully.`);
    }),
  );

  // PUT /admin/<type>/:id (partial update)
  router.put(
    '/:id',
    idParam,
    validate(updateSchema),
    ah(async (req, res) => {
      await getOne(req.params.id);
      const cols = bodyToCols(cfg, req.body);
      const keys = Object.keys(cols);
      if (!keys.length) throw new ApiError(400, 'NOTHING_TO_UPDATE', 'Send at least one field to update.');
      await db.query(`UPDATE ${t} SET ${keys.map((k) => `${k} = :${k}`).join(', ')} WHERE id = :id`, { ...cols, id: req.params.id });
      ok(res, await getOne(req.params.id), `${cfg.label} updated successfully.`);
    }),
  );

  // PATCH /admin/<type>/:id/status { isActive }
  router.patch(
    '/:id/status',
    idParam,
    validate(z.object({ isActive: z.boolean() })),
    ah(async (req, res) => {
      await getOne(req.params.id);
      await db.query(`UPDATE ${t} SET is_active = :a WHERE id = :id`, { a: req.body.isActive ? 1 : 0, id: req.params.id });
      ok(res, await getOne(req.params.id), req.body.isActive ? `${cfg.label} activated. It is now visible in the app.` : `${cfg.label} deactivated. It is now hidden from the app.`);
    }),
  );

  // DELETE /admin/<type>/:id — hard delete if unused, otherwise deactivate
  router.delete(
    '/:id',
    idParam,
    ah(async (req, res) => {
      await getOne(req.params.id);
      const used = await usageCount(cfg, req.params.id);
      if (used > 0) {
        await db.query(`UPDATE ${t} SET is_active = 0 WHERE id = :id`, { id: req.params.id });
        return ok(
          res,
          { id: req.params.id, deleted: false, deactivated: true, usageCount: used },
          `${cfg.label} is in use by ${used} member${used === 1 ? '' : 's'}, so it was deactivated instead of deleted.`,
        );
      }
      await db.query(`DELETE FROM ${t} WHERE id = :id`, { id: req.params.id });
      ok(res, { id: req.params.id, deleted: true, deactivated: false, usageCount: 0 }, `${cfg.label} deleted successfully.`);
    }),
  );

  return router;
}

/** Extra endpoints for mindset answer options. */
function mindsetOptionsRouter() {
  const router = express.Router();
  const getOpt = async (id) => {
    const o = await db.one('SELECT * FROM mindset_options WHERE id = :id', { id });
    if (!o) throw errors.notFound('Option');
    return camel(o);
  };

  // POST /admin/mindset-questions/:id/options
  router.post(
    '/mindset-questions/:id/options',
    idParam,
    validate(z.object({ label: name(60), sortOrder: z.number().int().min(0).optional(), isActive: z.boolean().optional() })),
    ah(async (req, res) => {
      const q = await db.one('SELECT id FROM mindset_questions WHERE id = :id', { id: req.params.id });
      if (!q) throw errors.notFound('Question');
      const so = req.body.sortOrder ?? (await db.one('SELECT COALESCE(MAX(sort_order),0)+1 AS n FROM mindset_options WHERE question_id = :q', { q: q.id })).n;
      const r = await db.query(
        'INSERT INTO mindset_options (question_id, label, sort_order, is_active) VALUES (:q, :l, :s, :a)',
        { q: q.id, l: req.body.label, s: so, a: req.body.isActive === false ? 0 : 1 },
      );
      created(res, await getOpt(r.insertId), 'Option added successfully.');
    }),
  );

  // PUT /admin/mindset-options/:id
  router.put(
    '/mindset-options/:id',
    idParam,
    validate(z.object({ label: name(60).optional(), sortOrder: z.number().int().min(0).optional(), isActive: z.boolean().optional() })),
    ah(async (req, res) => {
      await getOpt(req.params.id);
      const cols = {};
      if (req.body.label !== undefined) cols.label = req.body.label;
      if (req.body.sortOrder !== undefined) cols.sort_order = req.body.sortOrder;
      if (req.body.isActive !== undefined) cols.is_active = req.body.isActive ? 1 : 0;
      const keys = Object.keys(cols);
      if (!keys.length) throw new ApiError(400, 'NOTHING_TO_UPDATE', 'Send at least one field to update.');
      await db.query(`UPDATE mindset_options SET ${keys.map((k) => `${k} = :${k}`).join(', ')} WHERE id = :id`, { ...cols, id: req.params.id });
      ok(res, await getOpt(req.params.id), 'Option updated successfully.');
    }),
  );

  // DELETE /admin/mindset-options/:id
  router.delete(
    '/mindset-options/:id',
    idParam,
    ah(async (req, res) => {
      await getOpt(req.params.id);
      const { n } = await db.one('SELECT COUNT(*) n FROM user_mindset_answers WHERE option_id = :id', { id: req.params.id });
      if (Number(n) > 0) {
        await db.query('UPDATE mindset_options SET is_active = 0 WHERE id = :id', { id: req.params.id });
        return ok(res, { id: req.params.id, deleted: false, deactivated: true, usageCount: Number(n) }, 'This option has already been chosen by members, so it was deactivated instead of deleted.');
      }
      await db.query('DELETE FROM mindset_options WHERE id = :id', { id: req.params.id });
      ok(res, { id: req.params.id, deleted: true, deactivated: false, usageCount: 0 }, 'Option deleted successfully.');
    }),
  );

  return router;
}

module.exports = { TYPES, buildRouter, mindsetOptionsRouter };
