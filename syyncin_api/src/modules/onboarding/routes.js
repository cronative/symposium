const express = require('express');
const db = require('../../config/db');
const { ApiError, ah, ok } = require('../../utils/http');
const { STEPS, loadProfile, advanceStep } = require('../../services/profile');
const { SECTIONS } = require('../../services/profileSections');
const { requireUser, validate } = require('../../middleware');

const router = express.Router();
router.use(requireUser);

/** A step can be (re)submitted once the user has reached it. */
const requireStep = (step) => (req, _res, next) =>
  req.user.onboarding_step >= step
    ? next()
    : next(new ApiError(409, 'STEP_LOCKED', 'Please complete the previous step first.', { currentStep: req.user.onboarding_step }));

/** PUT /onboarding/<step> — validate, check, save, move to the next step. */
function step(path, section, current, next, message) {
  router.put(
    path,
    requireStep(current),
    validate(section.schema),
    ah(async (req, res) => {
      await section.check(req.body);
      await db.tx(async (conn) => {
        await section.save(conn, req.user.id, req.body);
        await advanceStep(req.user.id, next, conn);
      });
      ok(res, await loadProfile(req.user.id), message);
    }),
  );
}

// GET /onboarding/status
router.get('/status', ah(async (req, res) => ok(res, await loadProfile(req.user.id), 'Setup progress fetched successfully.')));

step('/basic', SECTIONS.basic, STEPS.basic, STEPS.work, 'Basic details saved.'); //               Step 1 About you
step('/work', SECTIONS.work, STEPS.work, STEPS.interests, 'Work details saved.'); //             Step 2 Your work
step('/interests', SECTIONS.interests, STEPS.interests, STEPS.mindset, 'Interests saved.'); // Step 3 Interests + "I'm here to…"
step('/mindset', SECTIONS.mindset, STEPS.mindset, STEPS.community, 'Mindset saved.'); //    Step 4 Mindset (all questions optional)
step('/community', SECTIONS.community, STEPS.community, STEPS.selfie, 'Community preferences saved. One last step: verify your selfie.'); // Step 5 Your community

module.exports = router;
