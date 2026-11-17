const fs = require('fs');
const express = require('express');
const env = require('../../config/env');
const db = require('../../config/db');
const { ApiError, ah, ok, created, errors } = require('../../utils/http');
const { STEPS, advanceStep } = require('../../services/profile');
const { requireUser, idParam, imageUpload } = require('../../middleware');

const router = express.Router();
router.use(requireUser);

const view = (v) => ({ id: v.id, status: v.status, reason: v.reason, submittedAt: v.created_at, reviewedAt: v.reviewed_at });

// POST /verification/selfie — multipart field "selfie" (mandatory final step)
router.post(
  '/selfie',
  (req, _res, next) => {
    if (req.user.onboarding_step < STEPS.selfie) {
      return next(new ApiError(409, 'STEP_LOCKED', 'Please complete your profile first.', { currentStep: req.user.onboarding_step }));
    }
    if (req.user.verification_status === 'verified') return next(new ApiError(409, 'ALREADY_VERIFIED', 'Your identity is already verified.'));
    next();
  },
  imageUpload('selfies', 'selfie'),
  ah(async (req, res) => {
    if (!req.file) throw errors.badRequest('FILE_REQUIRED', 'Take a selfie to continue.');
    const rel = `${env.uploads.dir}/selfies/${req.file.filename}`;
    const status = env.verification.autoApprove ? 'verified' : 'pending';
    const v = await db.tx(async (conn) => {
      // supersede any earlier pending submission
      await db.query(
        "UPDATE verifications SET status = 'rejected', reason = 'Superseded by a newer selfie', reviewed_at = UTC_TIMESTAMP() WHERE user_id = :u AND status = 'pending'",
        { u: req.user.id },
        conn,
      );
      const r = await db.query(
        `INSERT INTO verifications (user_id, selfie_path, status, reviewed_at) VALUES (:u, :p, :s, ${status === 'verified' ? 'UTC_TIMESTAMP()' : 'NULL'})`,
        { u: req.user.id, p: rel, s: status },
        conn,
      );
      await db.query('UPDATE users SET verification_status = :s WHERE id = :u', { s: status, u: req.user.id }, conn);
      await advanceStep(req.user.id, STEPS.done, conn);
      return db.one('SELECT * FROM verifications WHERE id = :id', { id: r.insertId }, conn);
    }).catch((e) => {
      fs.promises.unlink(rel).catch(() => {});
      throw e;
    });
    created(res, view(v), v.status === 'verified' ? 'Selfie verified. Your profile is now verified.' : 'Selfie submitted. We will verify it shortly.');
  }),
);

// GET /verification/latest
router.get('/latest', ah(async (req, res) => {
  const v = await db.one('SELECT * FROM verifications WHERE user_id = :u ORDER BY id DESC LIMIT 1', { u: req.user.id });
  if (!v) throw errors.notFound('Verification');
  ok(res, view(v), { pending: 'Your selfie is under review. We will notify you once it is verified.', verified: 'Your profile is verified.', rejected: v.reason ? `Your selfie was not approved: ${v.reason}` : 'Your selfie was not approved. Please submit a new one.' }[v.status]);
}));

// GET /verification/:id
router.get('/:id', idParam, ah(async (req, res) => {
  const v = await db.one('SELECT * FROM verifications WHERE id = :id AND user_id = :u', { id: req.params.id, u: req.user.id });
  if (!v) throw errors.notFound('Verification');
  ok(res, view(v), { pending: 'Your selfie is under review. We will notify you once it is verified.', verified: 'Your profile is verified.', rejected: v.reason ? `Your selfie was not approved: ${v.reason}` : 'Your selfie was not approved. Please submit a new one.' }[v.status]);
}));

module.exports = router;
