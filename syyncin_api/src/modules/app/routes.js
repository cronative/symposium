const fs = require('fs');
const express = require('express');
const env = require('../../config/env');
const db = require('../../config/db');
const { z } = require('zod');
const { ApiError, ah, ok, errors } = require('../../utils/http');
const { loadProfile } = require('../../services/profile');
const { SECTIONS } = require('../../services/profileSections');
const { requireUser, imageUpload, validate } = require('../../middleware');

const router = express.Router();

// GET /app/config — public; read on Splash
router.get('/app/config', (_req, res) =>
  ok(res, {
    minAppVersion: env.app.minVersion,
    termsUrl: env.app.termsUrl,
    privacyUrl: env.app.privacyUrl,
    otp: { length: env.otp.length, expiresIn: env.otp.expirySeconds, resendAfter: env.otp.resendSeconds },
    rules: {
      minAge: env.rules.minAge,
      minInterests: env.rules.minInterests,
      maxReasons: env.rules.maxReasons,
      maxSkills: env.rules.maxSkills,
      radiusOptionsKm: env.rules.radiusOptionsKm,
      connectModes: ['in_person', 'online', 'both'],
      availability: ['weekdays', 'weekends', 'evenings', 'flexible'],
      genders: ['woman', 'man', 'other', 'prefer_not_to_say'],
    },
    realtime: {
      path: '/socket.io',
      auth: 'Send the access token as { auth: { token } } when connecting.',
      events: ['ready', 'notification', 'notification:removed', 'inbox:updated'],
    },
  }, 'App configuration fetched successfully.'),
);

// GET /me — profile + onboarding step (Splash routes on this)
router.get('/me', requireUser, ah(async (req, res) => ok(res, await loadProfile(req.user.id), 'Profile fetched successfully.')));

// PUT /me/profile — Edit Profile. Send any sections (each replaces that section); all-or-nothing.
const editSchema = z
  .object(Object.fromEntries(Object.entries(SECTIONS).map(([k, sec]) => [k, sec.schema.optional()])))
  .strict()
  .refine((b) => Object.values(b).some((v) => v !== undefined), 'Send at least one section to update.');

router.put(
  '/me/profile',
  requireUser,
  validate(editSchema),
  ah(async (req, res) => {
    if (req.user.onboarding_step < 7) {
      throw new ApiError(409, 'ONBOARDING_INCOMPLETE', 'Finish profile setup first — use the /onboarding endpoints.', { currentStep: req.user.onboarding_step });
    }
    const parts = Object.entries(req.body).filter(([, v]) => v !== undefined);
    for (const [name, body] of parts) await SECTIONS[name].check(body);
    await db.tx(async (conn) => {
      for (const [name, body] of parts) await SECTIONS[name].save(conn, req.user.id, body);
    });
    ok(res, await loadProfile(req.user.id), 'Profile updated successfully.');
  }),
);

// PATCH /me/settings — quick toggles on My Profile › Preferences
router.patch(
  '/me/settings',
  requireUser,
  validate(SECTIONS.settings.schema),
  ah(async (req, res) => {
    await SECTIONS.settings.save(undefined, req.user.id, req.body);
    const p = await loadProfile(req.user.id);
    ok(res, { openToConnect: p.community.openToConnect, nearbyDiscovery: p.community.nearbyDiscovery }, 'Preferences saved.');
  }),
);

// POST /me/photo — multipart field "photo"
router.post(
  '/me/photo',
  requireUser,
  imageUpload('photos', 'photo'),
  ah(async (req, res) => {
    if (!req.file) throw errors.badRequest('FILE_REQUIRED', 'Choose a photo to upload.');
    const rel = `${env.uploads.dir}/photos/${req.file.filename}`;
    const old = req.user.photo_path;
    await db.query('UPDATE users SET photo_path = :p WHERE id = :id', { p: rel, id: req.user.id });
    if (old) fs.promises.unlink(old).catch(() => {});
    const profile = await loadProfile(req.user.id);
    ok(res, { photoUrl: profile.photoUrl }, 'Profile photo updated.');
  }),
);

// DELETE /me/photo
router.delete(
  '/me/photo',
  requireUser,
  ah(async (req, res) => {
    if (req.user.photo_path) {
      await db.query('UPDATE users SET photo_path = NULL WHERE id = :id', { id: req.user.id });
      fs.promises.unlink(req.user.photo_path).catch(() => {});
    }
    ok(res, { photoUrl: null }, 'Profile photo removed.');
  }),
);

module.exports = router;
