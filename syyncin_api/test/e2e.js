/**
 * End-to-end test against a running server + real MySQL.
 *   npm run db:reset && npm run admin:create -- --email admin@syyncin.app --password "Admin#12345"
 *   npm start   (in another terminal)
 *   npm run test:e2e
 */
const { io: ioClient } = require('socket.io-client');

const BASE = process.env.API_URL || 'http://localhost:4000/api/v1';
const ORIGIN = BASE.replace('/api/v1', '');

/** Open a realtime connection and record every event it receives. */
function listen(token) {
  return new Promise((resolve, reject) => {
    const s = ioClient(ORIGIN, { path: '/socket.io', auth: { token }, transports: ['websocket'], reconnection: false });
    const events = [];
    s.onAny((e, p) => events.push([e, p]));
    const timer = setTimeout(() => reject(new Error('socket timeout')), 4000);
    s.on('ready', (p) => { clearTimeout(timer); resolve({ s, events, ready: p }); });
    s.on('connect_error', (e) => { clearTimeout(timer); reject(e); });
  });
}
/** Resolve with the first `event` payload matching `pred` (already received or arriving within `ms`). */
function waitFor(sock, event, pred = () => true, ms = 3000) {
  return new Promise((resolve) => {
    const seen = sock.events.find(([e, p]) => e === event && pred(p));
    if (seen) return resolve(seen[1]);
    const t = setTimeout(() => { sock.s.off(event, h); resolve(null); }, ms);
    const h = (p) => { if (pred(p)) { clearTimeout(t); sock.s.off(event, h); resolve(p); } };
    sock.s.on(event, h);
  });
}
const ADMIN = { email: process.env.ADMIN_EMAIL || 'admin@syyncin.app', password: process.env.ADMIN_PASSWORD || 'Admin#12345' };

let passed = 0;
const failures = [];
const hit = new Set();

const envelopeIssues = [];
const defaultMessages = new Set();
const GENERIC = ['Data fetched successfully.', 'Request completed successfully.', 'Updated successfully.', 'Deleted successfully.', 'Something went wrong. Please try again.'];

/** Every JSON response must be exactly { status: 0|1, data: {}, message: "…" } with status matching the HTTP code. */
function checkEnvelope(name, httpStatus, json) {
  const problems = [];
  if (!json || typeof json !== 'object') problems.push('not JSON');
  else {
    const keys = Object.keys(json).sort().join(',');
    if (keys !== 'data,message,status') problems.push(`keys=${keys}`);
    if (json.status !== (httpStatus < 400 ? 1 : 0)) problems.push(`status=${json.status} for HTTP ${httpStatus}`);
    if (!json.data || typeof json.data !== 'object' || Array.isArray(json.data)) problems.push('data is not an object');
    if (typeof json.message !== 'string' || json.message.trim().length < 4) problems.push('empty message');
    if (json.status === 0 && typeof json.data?.code !== 'string') problems.push('failure without data.code');
    if (GENERIC.includes(json.message)) defaultMessages.add(name.replace(/\/\d+/g, '/:id').replace(/\?.*? →/, ' →'));
  }
  if (problems.length) envelopeIssues.push(`${name}: ${problems.join('; ')}`);
  else passed++;
}

async function call(method, path, { token, body, form, expect = 200, raw = false } = {}) {
  hit.add(`${method} ${path.replace(/\?.*$/, '').replace(/\/\d+(?=\/|$)/g, '/:id').replace(/[0-9a-f-]{36}/, ':uuid')}`);
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload;
  if (form) payload = form;
  else if (body !== undefined) { headers['Content-Type'] = 'application/json'; payload = JSON.stringify(body); }
  const res = await fetch(BASE + path, { method, headers, body: payload });
  const json = raw ? null : await res.json().catch(() => null);
  const name = `${method} ${path} → ${expect}`;
  if (!raw) checkEnvelope(name, res.status, json);
  if (res.status === expect) passed++;
  else { failures.push(`${name} (got ${res.status}: ${json?.message} ${JSON.stringify(json?.data)})`); if (process.env.DEBUG) console.log('✗', failures.at(-1)); }
  if (raw) return res;
  // Convenience view for the assertions below: lists unwrap to arrays, paging → meta, failures → error.
  const d = json?.data || {};
  return {
    status: json?.status,
    message: json?.message,
    body: json,
    data: Array.isArray(d.items) ? d.items : d,
    meta: d.pagination,
    error: json?.status === 0 ? { code: d.code, message: json.message, details: d } : undefined,
  };
}

function check(label, cond) {
  if (cond) passed++;
  else failures.push(`assert: ${label}`);
}

const jpeg = () => {
  const fd = new FormData();
  return fd;
};
const imageForm = (field) => {
  const fd = jpeg();
  const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, ...new Array(200).fill(7), 0xff, 0xd9]);
  fd.append(field, new Blob([bytes], { type: 'image/jpeg' }), 'img.jpg');
  return fd;
};

(async () => {
  // ── Health & config ───────────────────────────────────────────────
  const health = await fetch(BASE.replace('/api/v1', '') + '/health').then((r) => r.json());
  check('health ok', health.status === 1 && health.message === 'Server is healthy.');
  const cfg = await call('GET', '/app/config');
  check('config minAge 25', cfg.data.rules.minAge === 25);

  // ── Meta (public) ────────────────────────────────────────────────
  const industries = (await call('GET', '/meta/industries')).data;
  const levels = (await call('GET', '/meta/experience-levels')).data;
  const interests = (await call('GET', '/meta/interests')).data;
  const reasons = (await call('GET', '/meta/reasons')).data;
  const skills = (await call('GET', '/meta/skills?q=fl')).data;
  const questions = (await call('GET', '/meta/mindset-questions')).data;
  const cities = (await call('GET', '/meta/cities?q=Ahm')).data;
  const localities = (await call('GET', `/meta/localities?cityId=${cities[0].id}&q=bopal`)).data;
  await call('GET', '/meta/localities', { expect: 400 });
  check('21 interests', interests.length === 21);
  check('6 reasons', reasons.length === 6);
  check('5 questions × 4 options', questions.length === 5 && questions.every((q) => q.options.length === 4));
  check('skills search', skills.some((s) => s.name === 'Flutter'));
  check('localities filtered', localities.length === 2);

  // ── Auth / OTP ───────────────────────────────────────────────────
  await call('POST', '/auth/otp/request', { body: { identifier: 'abc', termsAccepted: true }, expect: 400 });
  await call('POST', '/auth/otp/request', { body: { identifier: '9812345210', termsAccepted: false }, expect: 400 });
  const phone = `98${String(Date.now()).slice(-8)}`;
  const otp = (await call('POST', '/auth/otp/request', { body: { identifier: phone, termsAccepted: true } })).data;
  check('masked destination', /^\+91 \d\d•••••\d{3}$/.test(otp.maskedDestination));
  check('devCode present', /^\d{6}$/.test(otp.devCode));
  const wrong = otp.devCode === '000000' ? '111111' : '000000';
  const bad = await call('POST', '/auth/otp/verify', { body: { requestId: otp.requestId, code: wrong }, expect: 400 });
  check('OTP_INVALID + remaining 4', bad.error.code === 'OTP_INVALID' && bad.error.details.remainingAttempts === 4);
  const soon = await call('POST', '/auth/otp/resend', { body: { requestId: otp.requestId }, expect: 429 });
  check('OTP_RESEND_TOO_SOON', soon.error.code === 'OTP_RESEND_TOO_SOON');
  const session = (await call('POST', '/auth/otp/verify', { body: { requestId: otp.requestId, code: otp.devCode } })).data;
  check('new user', session.user.isNew === true && session.user.onboardingStep === 1);
  await call('POST', '/auth/otp/verify', { body: { requestId: otp.requestId, code: otp.devCode }, expect: 404 }); // single use
  let token = session.accessToken;

  // lock-out after 5 wrong attempts
  const otp2 = (await call('POST', '/auth/otp/request', { body: { identifier: `lock${Date.now()}@test.com`, termsAccepted: true } })).data;
  for (let i = 0; i < 4; i++) await call('POST', '/auth/otp/verify', { body: { requestId: otp2.requestId, code: wrong === otp2.devCode ? '222222' : wrong }, expect: 400 });
  const locked = await call('POST', '/auth/otp/verify', { body: { requestId: otp2.requestId, code: wrong === otp2.devCode ? '222222' : wrong }, expect: 429 });
  check('OTP_TOO_MANY_ATTEMPTS', locked.error.code === 'OTP_TOO_MANY_ATTEMPTS');

  // ── Profile & onboarding ─────────────────────────────────────────
  await call('GET', '/me', { expect: 401 });
  const me = (await call('GET', '/me', { token })).data;
  check('me step 1', me.onboarding.step === 1);
  await call('PUT', '/onboarding/work', { token, body: {}, expect: 409 }); // locked
  const young = await call('PUT', '/onboarding/basic', { token, body: { fullName: 'Krupa Shah', dob: '2010-01-01' }, expect: 400 });
  check('AGE_RESTRICTED', young.error.code === 'AGE_RESTRICTED');
  await call('PUT', '/onboarding/basic', { token, body: { fullName: 'Krupa Shah', linkedinUrl: 'not-a-url' }, expect: 400 });
  const s1 = (await call('PUT', '/onboarding/basic', { token, body: { fullName: 'Krupa Shah', dob: '1995-06-15', linkedinUrl: 'https://linkedin.com/in/krupa-shah', gender: 'woman' } })).data;
  check('step → 2', s1.onboarding.step === 2);
  await call('PUT', '/onboarding/work', { token, body: { jobTitle: 'UI/UX Designer', industryId: 99999, experienceLevelId: levels[2].id }, expect: 400 });
  await call('PUT', '/onboarding/work', { token, body: { jobTitle: 'UI/UX Designer', industryId: industries[1].id, experienceLevelId: levels[2].id, skillIds: skills.concat(skills).slice(0, 1).concat([1, 2, 3, 5, 6, 7]) }, expect: 400 });
  const s2 = (await call('PUT', '/onboarding/work', { token, body: { jobTitle: 'UI/UX Designer', industryId: industries[1].id, company: 'Airbnb', experienceLevelId: levels[2].id, skillIds: [1, 3] } })).data;
  check('work saved', s2.work.skills.length === 2 && s2.onboarding.step === 3);
  await call('PUT', '/onboarding/interests', { token, body: { interestIds: [interests[0].id, interests[1].id], reasonIds: [reasons[0].id] }, expect: 400 });
  await call('PUT', '/onboarding/interests', { token, body: { interestIds: interests.slice(0, 3).map((i) => i.id), reasonIds: reasons.slice(0, 4).map((r) => r.id) }, expect: 400 });
  const s3 = (await call('PUT', '/onboarding/interests', { token, body: { interestIds: interests.slice(0, 4).map((i) => i.id), reasonIds: [reasons[0].id, reasons[4].id] } })).data;
  check('interests saved', s3.interests.length === 4 && s3.reasons.length === 2 && s3.onboarding.step === 4);
  const answers = questions.map((q) => ({ questionId: q.id, optionId: q.options[0].id }));
  check('mindset optional (partial ok)', (await call('PUT', '/onboarding/mindset', { token, body: { answers: answers.slice(0, 2) } })).data.mindset.length === 2);
  check('mindset optional (none ok)', (await call('PUT', '/onboarding/mindset', { token, body: { answers: [] } })).data.mindset.length === 0);
  await call('PUT', '/onboarding/mindset', { token, body: { answers: answers.map((a, i) => (i === 0 ? { ...a, optionId: questions[1].options[0].id } : a)) }, expect: 400 });
  const s4 = (await call('PUT', '/onboarding/mindset', { token, body: { answers } })).data;
  check('mindset saved', s4.mindset.length === 5 && s4.onboarding.step === 5);
  await call('PUT', '/onboarding/community', { token, body: { cityId: cities[0].id, connectMode: 'both', radiusKm: 7, availability: ['flexible'], nearbyDiscovery: true }, expect: 400 });
  const s5 = (await call('PUT', '/onboarding/community', { token, body: { cityId: cities[0].id, localityId: localities[0].id, lat: 23.0225, lng: 72.5714, connectMode: 'both', radiusKm: 25, availability: ['flexible', 'evenings'], nearbyDiscovery: true } })).data;
  check('community saved', s5.community.city.name === 'Ahmedabad' && s5.community.availability.length === 2 && s5.onboarding.step === 6);
  const status = (await call('GET', '/onboarding/status', { token })).data;
  check('status step 6', status.onboarding.stepName === 'selfie');

  // ── Photo & selfie ───────────────────────────────────────────────
  const photo = (await call('POST', '/me/photo', { token, form: imageForm('photo') })).data;
  check('photo url', /\/uploads\/photos\/.+\.jpg$/.test(photo.photoUrl));
  const pub = await fetch(photo.photoUrl);
  check('photo publicly served', pub.status === 200);
  const pdf = new FormData();
  pdf.append('photo', new Blob(['%PDF'], { type: 'application/pdf' }), 'x.pdf');
  await call('POST', '/me/photo', { token, form: pdf, expect: 415 });
  await call('DELETE', '/me/photo', { token });
  const selfie = (await call('POST', '/verification/selfie', { token, form: imageForm('selfie'), expect: 201 }));
  const sv = selfie?.data || (await call('GET', '/verification/latest', { token })).data;
  check('selfie pending', sv.status === 'pending');
  await call('GET', `/verification/${sv.id}`, { token });
  await call('GET', '/verification/latest', { token });
  check('selfie not public', (await fetch(`${BASE.replace('/api/v1', '')}/uploads/selfies/`)).status === 404);

  // ── Tokens ───────────────────────────────────────────────────────
  const refreshed = (await call('POST', '/auth/refresh', { body: { refreshToken: session.refreshToken } })).data;
  await call('POST', '/auth/refresh', { body: { refreshToken: session.refreshToken }, expect: 401 }); // rotated
  token = refreshed.accessToken;
  check('returning user', refreshed.user.onboardingStep === 7);

  // social (mock)
  const social = (await call('POST', '/auth/social', { body: { provider: 'google', idToken: `mock:g${Date.now()}:social${Date.now()}@test.com`, termsAccepted: true } })).data;
  check('social new user', social.user.isNew === true);

  // ── Admin auth ───────────────────────────────────────────────────
  await call('POST', '/admin/auth/login', { body: { email: ADMIN.email, password: 'wrong-pass' }, expect: 401 });
  const adm = (await call('POST', '/admin/auth/login', { body: ADMIN })).data;
  const at = adm.accessToken;
  await call('GET', '/admin/auth/me', { token: at });
  const stats = (await call('GET', '/admin/stats', { token: at })).data;
  check('stats', stats.users.total >= 2 && stats.masterData.interests.total === 21);
  await call('GET', '/admin/industries', { expect: 401 });
  await call('GET', '/admin/industries', { token, expect: 403 }); // user token
  const admRef = (await call('POST', '/admin/auth/refresh', { body: { refreshToken: adm.refreshToken } })).data;
  await call('POST', '/admin/auth/logout', { body: { refreshToken: admRef.refreshToken } });

  // ── Master data CRUD (8 types) ───────────────────────────────────
  const samples = {
    industries: [{ name: 'Test Industry' }, { name: 'Test Industry 2' }],
    'experience-levels': [{ label: '20+ years', minYears: 20 }, { label: '20+ yrs' }],
    skills: [{ name: 'Test Skill', industryId: industries[0].id }, { name: 'Test Skill X' }],
    interests: [{ name: 'Test Interest', icon: 'star' }, { name: 'Test Interest 2' }],
    reasons: [{ title: 'Test Reason', subtitle: 'Just testing', icon: 'users' }, { subtitle: 'Edited subtitle' }],
    cities: [{ name: 'Test City', state: 'Gujarat', lat: 22.1, lng: 72.1 }, { name: 'Test City 2' }],
    localities: [{ cityId: cities[0].id, name: 'Test Locality' }, { name: 'Test Locality 2' }],
    'mindset-questions': [{ question: 'Test question?', options: ['A', 'B', 'C'] }, { question: 'Edited question?' }],
  };
  for (const [type, [createBody, updateBody]] of Object.entries(samples)) {
    const list = await call('GET', `/admin/${type}?page=1&limit=5&status=all`, { token: at });
    check(`${type} list paging`, list.meta && list.meta.limit === 5 && list.data.length <= 5);
    await call('POST', `/admin/${type}`, { token: at, body: {}, expect: 400 });
    const c = (await call('POST', `/admin/${type}`, { token: at, body: createBody, expect: 201 })).data || {};
    if (!c.id) { failures.push(`${type}: create returned no id`); continue; }
    await call('POST', `/admin/${type}`, { token: at, body: createBody, expect: type === 'mindset-questions' ? 201 : 409 });
    await call('GET', `/admin/${type}/${c.id}`, { token: at });
    await call('GET', `/admin/${type}/999999`, { token: at, expect: 404 });
    const u = (await call('PUT', `/admin/${type}/${c.id}`, { token: at, body: updateBody })).data;
    check(`${type} updated`, Object.entries(updateBody).every(([k, v]) => u[k] === v));
    await call('PUT', `/admin/${type}/${c.id}`, { token: at, body: {}, expect: 400 });
    const off = (await call('PATCH', `/admin/${type}/${c.id}/status`, { token: at, body: { isActive: false } })).data;
    check(`${type} deactivated`, off.isActive === false);
    const inactive = await call('GET', `/admin/${type}?status=inactive&search=${encodeURIComponent((updateBody.name || updateBody.label || updateBody.question || 'Test').slice(0, 6))}`, { token: at });
    check(`${type} inactive filter`, inactive.data.some((r) => r.id === c.id));
    await call('PATCH', `/admin/${type}/${c.id}/status`, { token: at, body: { isActive: true } });
    const all = (await call('GET', `/admin/${type}?limit=100`, { token: at })).data.map((r) => r.id);
    const reordered = [c.id, ...all.filter((x) => x !== c.id)];
    await call('PATCH', `/admin/${type}/reorder`, { token: at, body: { ids: reordered } });
    const first = (await call('GET', `/admin/${type}?limit=1`, { token: at })).data[0];
    check(`${type} reorder`, first.id === c.id);
    await call('PATCH', `/admin/${type}/reorder`, { token: at, body: { ids: [999999] }, expect: 400 });
    const del = (await call('DELETE', `/admin/${type}/${c.id}`, { token: at })).data;
    check(`${type} hard delete`, del.deleted === true);
  }
  // experience-level rule
  await call('POST', '/admin/experience-levels', { token: at, body: { label: 'Bad', minYears: 5, maxYears: 2 }, expect: 400 });

  // used item → deactivated, hidden from app
  const usedInterest = interests[0].id;
  const soft = (await call('DELETE', `/admin/interests/${usedInterest}`, { token: at })).data;
  check('used interest deactivated', soft.deleted === false && soft.deactivated === true && soft.usageCount >= 1);
  const metaAfter = (await call('GET', '/meta/interests')).data;
  check('inactive hidden from app', !metaAfter.some((i) => i.id === usedInterest));
  await call('PATCH', `/admin/interests/${usedInterest}/status`, { token: at, body: { isActive: true } });

  // mindset options
  const q1 = questions[0].id;
  const opt = (await call('POST', `/admin/mindset-questions/${q1}/options`, { token: at, body: { label: 'Freedom' }, expect: 201 })).data;
  await call('POST', '/admin/mindset-questions/999999/options', { token: at, body: { label: 'X' }, expect: 404 });
  const optU = (await call('PUT', `/admin/mindset-options/${opt.id}`, { token: at, body: { label: 'Independence' } })).data;
  check('option updated', optU.label === 'Independence');
  check('option hard delete', (await call('DELETE', `/admin/mindset-options/${opt.id}`, { token: at })).data.deleted === true);
  const usedOpt = questions[0].options[0].id;
  check('used option deactivated', (await call('DELETE', `/admin/mindset-options/${usedOpt}`, { token: at })).data.deactivated === true);
  await call('PUT', `/admin/mindset-options/${usedOpt}`, { token: at, body: { isActive: true } });

  // ── Verifications ────────────────────────────────────────────────
  const queue = await call('GET', '/admin/verifications?status=pending', { token: at });
  const item = queue.data.find((v) => v.id === sv.id);
  check('pending in queue', Boolean(item));
  await call('GET', `/admin/verifications/${sv.id}`, { token: at });
  const img = await call('GET', `/admin/verifications/${sv.id}/selfie`, { token: at, raw: true });
  check('selfie stream', img.headers.get('content-type')?.startsWith('image/'));
  await call('PATCH', `/admin/verifications/${sv.id}`, { token: at, body: { action: 'reject' }, expect: 400 });
  const appr = (await call('PATCH', `/admin/verifications/${sv.id}`, { token: at, body: { action: 'approve' } })).data;
  check('approved', appr.status === 'verified');
  await call('PATCH', `/admin/verifications/${sv.id}`, { token: at, body: { action: 'reject', reason: 'late' }, expect: 409 });
  check('user verified', (await call('GET', '/me', { token })).data.verificationStatus === 'verified');

  // ── Users ────────────────────────────────────────────────────────
  const users = await call('GET', '/admin/users?search=Krupa&status=all&onboarding=complete', { token: at });
  const uid = users.data[0]?.id;
  check('user search', Boolean(uid));
  const detail = (await call('GET', `/admin/users/${uid}`, { token: at })).data;
  check('user detail', detail.verifications.length >= 1 && detail.interests.length === 4);
  await call('PATCH', `/admin/users/${uid}/status`, { token: at, body: { status: 'blocked' } });
  const blocked = await call('GET', '/me', { token, expect: 403 });
  check('ACCOUNT_BLOCKED', blocked.error.code === 'ACCOUNT_BLOCKED');
  await call('POST', '/auth/refresh', { body: { refreshToken: refreshed.refreshToken }, expect: 401 }); // revoked
  await call('PATCH', `/admin/users/${uid}/status`, { token: at, body: { status: 'active' } });
  await call('GET', '/me', { token });
  await call('POST', '/auth/logout', { body: { refreshToken: social.refreshToken } });
  await call('GET', '/nope', { expect: 404 });

  // ── KYN · Members · Connections · Edit Profile ───────────────────
  // Admin tests above may have added mindset questions — answer whatever is live now.
  const liveQuestions = (await call('GET', '/meta/mindset-questions')).data;
  const liveAnswers = (pick) => liveQuestions.map((qq) => ({ questionId: qq.id, optionId: qq.options[Math.min(pick, qq.options.length - 1)].id }));
  async function makeMember(fullName, lat, lng, interestSlice) {
    const o = (await call('POST', '/auth/otp/request', { body: { identifier: `mem${Date.now()}${Math.floor(Math.random() * 1e4)}@test.com`, termsAccepted: true } })).data;
    const t = (await call('POST', '/auth/otp/verify', { body: { requestId: o.requestId, code: o.devCode } })).data.accessToken;
    await call('PUT', '/onboarding/basic', { token: t, body: { fullName, dob: '1990-01-01', linkedinUrl: 'https://linkedin.com/in/member', gender: 'man' } });
    await call('PUT', '/onboarding/work', { token: t, body: { jobTitle: 'Growth Hacker', industryId: industries[0].id, experienceLevelId: levels[3].id, skillIds: [2] } });
    await call('PUT', '/onboarding/interests', { token: t, body: { interestIds: interestSlice.map((i) => i.id), reasonIds: [reasons[1].id] } });
    await call('PUT', '/onboarding/mindset', { token: t, body: { answers: liveAnswers(0) } });
    await call('PUT', '/onboarding/community', { token: t, body: { cityId: cities[0].id, lat, lng, connectMode: 'both', radiusKm: 25, availability: ['weekends'], nearbyDiscovery: true } });
    await call('POST', '/verification/selfie', { token: t, form: imageForm('selfie'), expect: 201 });
    const me2 = (await call('GET', '/me', { token: t })).data;
    return { token: t, id: me2.id };
  }

  // gates for unfinished profiles
  const incomplete = social.accessToken;
  const gate = await call('GET', '/discover', { token: incomplete, expect: 403 });
  check('PROFILE_INCOMPLETE', gate.error.code === 'PROFILE_INCOMPLETE');
  await call('PUT', '/me/profile', { token: incomplete, body: { settings: { openToConnect: true } }, expect: 409 });

  const A = { token, id: me.id };
  const B = await makeMember('Zed Growth', 23.03, 72.58, interests.slice(2, 5)); // ~1.1 km from A, shares interests 3–4
  const C = await makeMember('Yash Far', 23.2, 72.63, interests.slice(10, 13)); //  ~20 km, no shared interests

  const disc = await call('GET', '/discover?sort=nearest&limit=100', { token: A.token });
  const bCard = disc.data.find((p) => p.id === B.id);
  check('discover lists B', Boolean(bCard) && disc.meta.total >= 2 && disc.body.data.locationAvailable === true && disc.body.data.applied.sort === 'nearest');
  check('card shape', bCard && bCard.initials === 'ZG' && bCard.distanceKm > 0 && bCard.distanceKm < 3 && bCard.connection.status === 'none' && bCard.verified === false);
  check('shared interests', bCard && bCard.sharedInterests.length === 2);
  check('self excluded', !disc.data.some((p) => p.id === A.id));
  const nearest = disc.data.filter((p) => p.distanceKm != null).map((p) => p.distanceKm);
  check('sorted nearest', nearest.every((d, i) => i === 0 || d >= nearest[i - 1]));
  const similar = (await call('GET', '/discover?quick=similar&limit=100', { token: A.token })).data;
  check('quick=similar', similar.some((p) => p.id === B.id) && !similar.some((p) => p.id === C.id));
  const nearby = (await call('GET', '/discover?quick=nearby&limit=100', { token: A.token })).data;
  check('quick=nearby ≤ 2 km', nearby.every((p) => p.distanceKm <= 2) && nearby.some((p) => p.id === B.id));
  const close = (await call('GET', '/discover?maxDistanceKm=5&limit=100', { token: A.token })).data;
  check('maxDistanceKm', close.some((p) => p.id === B.id) && !close.some((p) => p.id === C.id));
  const searched = (await call('GET', '/discover?search=growth%20hack&limit=100', { token: A.token })).data;
  check('search by role', searched.some((p) => p.id === B.id));
  const byInterest = (await call('GET', `/discover?interestIds=${interests[11].id}&limit=100`, { token: A.token })).data;
  check('interestIds filter', byInterest.some((p) => p.id === C.id) && !byInterest.some((p) => p.id === B.id));
  const count = await call('GET', '/discover?maxDistanceKm=5&limit=1', { token: A.token });
  check('Show N people (meta.total)', count.data.length <= 1 && count.meta.total === close.length);
  await call('GET', '/discover?sort=bogus', { token: A.token, expect: 400 });
  const byName = (await call('GET', '/discover?sort=name&limit=100', { token: A.token })).data.map((p) => p.fullName);
  check('sort=name', byName.every((n, i) => i === 0 || n.localeCompare(byName[i - 1]) >= 0 || n.toLowerCase() >= byName[i - 1].toLowerCase()));
  const fopts = (await call('GET', '/discover/filters', { token: A.token })).data;
  check('filter options', fopts.professions.length >= 12 && fopts.sortOptions.length === 4 && fopts.defaults.sort === 'match' && fopts.defaults.maxDistanceKm === 25);

  // SyyncMatch · SyyncScore
  const ranked = await call('GET', '/discover?limit=100', { token: A.token });
  check('default sort = match', ranked.body.data.applied.sort === 'match' && ranked.meta.total === disc.meta.total);
  check('cards carry SyyncScore', ranked.data.every((p) => p.match && p.match.score >= 0 && p.match.score <= 100 && Array.isArray(p.match.reasons)
    && p.match.reasons.length <= 3 && typeof p.match.algorithmVersion === 'string' && typeof p.match.label === 'string'));
  const scores = ranked.data.map((p) => p.match.score);
  check('sorted by SyyncScore', scores.every((x, i) => i === 0 || x <= scores[i - 1]));
  check('breakdown adds up', ranked.data.every((p) => Object.values(p.match.breakdown).reduce((a, b) => a + b, 0) === p.match.score));
  const bm = ranked.data.find((p) => p.id === B.id).match;
  const cm = ranked.data.find((p) => p.id === C.id).match;
  check('B (near, shared interests) outranks C', bm.score > cm.score && bm.reasons.includes('Common Interests') && !cm.reasons.includes('Common Interests'));
  check('no coordinates leak', !JSON.stringify(ranked.body).match(/"(lat|lng)"/));
  const p1 = (await call('GET', '/discover?limit=1&page=1', { token: A.token })).data;
  const p2 = (await call('GET', '/discover?limit=1&page=2', { token: A.token })).data;
  check('stable paging', p1[0]?.id === ranked.data[0].id && p2[0]?.id === ranked.data[1].id);
  check('nearest sort still has scores', disc.data.every((p) => p.match && typeof p.match.score === 'number'));
  const recs = await call('GET', '/matches', { token: A.token });
  const recB = recs.body.data.matches.find((m) => m.user_id === B.id);
  check('/matches format', recs.body.status === 1 && typeof recs.message === 'string' && recs.body.data.pagination.page === 1 && recs.body.data.pagination.has_more === false
    && recB && recB.match_score === bm.score && recB.match_level === bm.level && recB.user.id === B.id && recB.score_breakdown.skills >= 0 && Array.isArray(recB.match_reasons));
  check('/matches excludes self', !recs.body.data.matches.some((m) => m.user_id === A.id));
  const ms = recs.body.data.matches.map((m) => m.match_score);
  check('/matches sorted', ms.every((x, i) => i === 0 || x <= ms[i - 1]));
  await call('GET', '/matches', { expect: 401 });
  await call('GET', '/matches?limit=500', { token: A.token, expect: 400 });
  const seek = await call('GET', `/seek/matches?skillIds=2`, { token: A.token });
  check('Seek by skill', seek.body.data.matches.some((m) => m.user_id === B.id && m.match_reasons.includes('Required Expertise'))
    && seek.body.data.matches.some((m) => m.user_id === C.id));
  check('Seek by keyword', (await call('GET', '/seek/matches?q=growth', { token: A.token })).body.data.matches.some((m) => m.user_id === B.id));
  check('Seek no results', (await call('GET', '/seek/matches?q=zzzqqq', { token: A.token })).body.data.matches.length === 0);
  check('SEEK_QUERY_REQUIRED', (await call('GET', '/seek/matches', { token: A.token, expect: 400 })).error.code === 'SEEK_QUERY_REQUIRED');

  // member profile, icebreakers, bookmarks
  const prof = (await call('GET', `/users/${B.id}`, { token: A.token })).data;
  check('profile has SyyncScore', prof.match && prof.match.score === bm.score && prof.match.level === bm.level);
  check('profile detail', prof.skills.length === 1 && prof.intent.length === 1 && prof.mindset.length === liveQuestions.length && prof.linkedinUrl === null);
  check('mindset shared flags', prof.mindset.filter((m) => m.shared).length === questions.length); // A answered the original questions only
  await call('GET', '/users/999999', { token: A.token, expect: 404 });
  const ice = (await call('GET', `/users/${B.id}/icebreakers`, { token: A.token })).data;
  check('icebreakers', ice.suggestions.length === 3 && ice.suggestions[0].startsWith('Hi Zed'));
  await call('PUT', `/users/${A.id}/save`, { token: A.token, expect: 400 });
  await call('PUT', `/users/${B.id}/save`, { token: A.token });
  await call('PUT', `/users/${B.id}/save`, { token: A.token }); // idempotent
  const saved = await call('GET', '/me/saved', { token: A.token });
  check('saved list', saved.data.length === 1 && saved.data[0].isSaved === true);
  await call('DELETE', `/users/${B.id}/save`, { token: A.token });
  check('unsaved', (await call('GET', '/me/saved', { token: A.token })).meta.total === 0);

  // requests: send / duplicate / reverse / withdraw / decline / accept
  await call('POST', '/connections/requests', { token: A.token, body: { userId: A.id }, expect: 400 });
  await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id, message: 'x'.repeat(301) }, expect: 400 });
  const r1 = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id, message: ice.suggestions[0] }, expect: 201 })).data;
  check('request created', r1.status === 'pending' && r1.direction === 'sent' && r1.user.id === B.id && r1.user.connection.status === 'pending_sent');
  check('dup → REQUEST_ALREADY_SENT', (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id }, expect: 409 })).error.code === 'REQUEST_ALREADY_SENT');
  const rev = await call('POST', '/connections/requests', { token: B.token, body: { userId: A.id }, expect: 409 });
  check('reverse → REQUEST_RECEIVED', rev.error.code === 'REQUEST_RECEIVED' && rev.error.details.requestId === r1.id);
  const recv = await call('GET', '/connections/requests?direction=received', { token: B.token });
  check('B received', recv.data.length === 1 && recv.data[0].message === ice.suggestions[0] && recv.data[0].user.id === A.id);
  check('A sent', (await call('GET', '/connections/requests?direction=sent', { token: A.token })).data[0].id === r1.id);
  const sumB = (await call('GET', '/inbox/summary', { token: B.token })).data;
  check('summary badge', sumB.requests.received === 1 && sumB.showBadge === true);
  await call('POST', `/connections/requests/${r1.id}/accept`, { token: A.token, expect: 404 }); // only receiver
  await call('DELETE', `/connections/requests/${r1.id}`, { token: B.token, expect: 404 }); // only sender
  await call('DELETE', `/connections/requests/${r1.id}`, { token: A.token });
  check('withdrawn → REQUEST_CLOSED', (await call('DELETE', `/connections/requests/${r1.id}`, { token: A.token, expect: 409 })).error.code === 'REQUEST_CLOSED');
  const r2 = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id }, expect: 201 })).data;
  await call('POST', `/connections/requests/${r2.id}/decline`, { token: B.token });
  const allSent = await call('GET', '/connections/requests?direction=sent&status=all', { token: A.token });
  check('history kept', allSent.meta.total === 2 && allSent.data.some((x) => x.status === 'declined') && allSent.data.some((x) => x.status === 'withdrawn'));
  const r3 = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id }, expect: 201 })).data;
  const acc = (await call('POST', `/connections/requests/${r3.id}/accept`, { token: B.token })).data;
  check('accepted', acc.status === 'accepted' && acc.user.connection.status === 'connected');
  check('connected excluded from /matches (cache refreshed)', !(await call('GET', '/matches', { token: A.token })).body.data.matches.some((m) => m.user_id === B.id));
  const conns = await call('GET', '/connections', { token: A.token });
  check('connections list', conns.data.length === 1 && conns.data[0].id === B.id && conns.data[0].isNew === true);
  check('connections search', (await call('GET', '/connections?search=zed', { token: A.token })).data.length === 1
    && (await call('GET', '/connections?search=nobody', { token: A.token })).data.length === 0);
  check('linkedin after connect', (await call('GET', `/users/${B.id}`, { token: A.token })).data.linkedinUrl === 'https://linkedin.com/in/member');
  check('ALREADY_CONNECTED', (await call('POST', '/connections/requests', { token: B.token, body: { userId: A.id }, expect: 409 })).error.code === 'ALREADY_CONNECTED');
  const sumA = (await call('GET', '/inbox/summary', { token: A.token })).data;
  check('summary connections', sumA.connections.total === 1 && sumA.connections.new === 1 && sumA.requests.sent === 0);
  await call('DELETE', `/connections/${B.id}`, { token: A.token });
  await call('DELETE', `/connections/${B.id}`, { token: A.token, expect: 404 });

  // privacy toggles
  const st = (await call('PATCH', '/me/settings', { token: C.token, body: { openToConnect: false } })).data;
  check('settings saved', st.openToConnect === false && st.nearbyDiscovery === true);
  await call('PATCH', '/me/settings', { token: C.token, body: {}, expect: 400 });
  check('NOT_ACCEPTING_REQUESTS', (await call('POST', '/connections/requests', { token: A.token, body: { userId: C.id }, expect: 403 })).error.code === 'NOT_ACCEPTING_REQUESTS');
  await call('PATCH', '/me/settings', { token: C.token, body: { nearbyDiscovery: false } });
  check('hidden from KYN', !(await call('GET', '/discover?limit=100', { token: A.token })).data.some((p) => p.id === C.id));
  check('hidden excluded from /matches + Seek', !(await call('GET', '/matches', { token: A.token })).body.data.matches.some((m) => m.user_id === C.id)
    && !(await call('GET', '/seek/matches?skillIds=2', { token: A.token })).body.data.matches.some((m) => m.user_id === C.id));
  await call('GET', `/users/${C.id}`, { token: A.token, expect: 404 });

  // Edit Profile (PUT /me/profile)
  await call('PUT', '/me/profile', { token: A.token, body: {}, expect: 400 });
  await call('PUT', '/me/profile', { token: A.token, body: { nickname: 'x' }, expect: 400 });
  await call('PUT', '/me/profile', { token: A.token, body: { interests: { interestIds: [interests[0].id], reasonIds: [reasons[0].id] } }, expect: 400 });
  await call('PUT', '/me/profile', { token: A.token, body: { basic: { fullName: 'Krupa Shah', dob: '2015-01-01' } }, expect: 400 });
  const beforeEdit = (await call('GET', '/me', { token: A.token })).data;
  // all-or-nothing: valid work + invalid community → nothing saved
  await call('PUT', '/me/profile', { token: A.token, body: { work: { jobTitle: 'Should Not Save', industryId: industries[0].id, experienceLevelId: levels[0].id }, community: { cityId: 999999, connectMode: 'both', radiusKm: 25, availability: ['weekends'], nearbyDiscovery: true } }, expect: 400 });
  check('all-or-nothing', (await call('GET', '/me', { token: A.token })).data.work.jobTitle === beforeEdit.work.jobTitle);
  const edited = (await call('PUT', '/me/profile', {
    token: A.token,
    body: {
      basic: { fullName: 'Krupa Shah', dob: '1996-06-12', gender: 'woman', linkedinUrl: 'https://linkedin.com/in/krupashah', about: 'I design things.' },
      work: { jobTitle: 'Senior UI/UX Designer', industryId: industries[1].id, company: 'Independent Designer', experienceLevelId: levels[3].id, skillIds: [1, 3, 17] },
      interests: { interestIds: interests.slice(0, 5).map((i) => i.id), reasonIds: [reasons[0].id, reasons[1].id, reasons[2].id] },
      mindset: { answers: liveAnswers(1) },
      community: { cityId: cities[0].id, localityId: localities[1].id, connectMode: 'online', radiusKm: 10, availability: ['weekends', 'evenings'], nearbyDiscovery: true, openToConnect: false },
    },
  })).data;
  check('edit saved', edited.about === 'I design things.' && edited.work.jobTitle === 'Senior UI/UX Designer' && edited.work.skills.length === 3
    && edited.interests.length === 5 && edited.reasons.length === 3 && edited.mindset.length === liveQuestions.length && edited.mindset.every((m) => liveAnswers(1).some((a) => a.optionId === m.optionId))
    && edited.community.radiusKm === 10 && edited.community.openToConnect === false && edited.onboarding.step === 7);
  const partial = (await call('PUT', '/me/profile', { token: A.token, body: { settings: { openToConnect: true } } })).data;
  check('partial edit keeps the rest', partial.community.openToConnect === true && partial.about === 'I design things.' && partial.work.skills.length === 3);
  const keepAbout = (await call('PUT', '/me/profile', { token: A.token, body: { basic: { fullName: 'Krupa S.' } } })).data;
  check('about kept when omitted', keepAbout.about === 'I design things.' && keepAbout.fullName === 'Krupa S.');

  // Realtime + notifications
  const badSock = await listen('not-a-token').then(() => null, (e) => e);
  check('socket rejects bad token', badSock && badSock.message === 'TOKEN_INVALID');
  const sA = await listen(A.token);
  const sB = await listen(B.token);
  check('socket ready payload', sB.ready.userId === B.id && typeof sB.ready.unreadCount === 'number' && sB.ready.inbox.requests.received === 0);
  const rt1 = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id, message: 'Live hello' }, expect: 201 })).data;
  const live = await waitFor(sB, 'notification', (n) => n.data.requestId === rt1.id);
  check('B gets live notification', live && live.type === 'connection_request.received' && live.actor.id === A.id && /Live hello/.test(live.body) && live.isRead === false);
  const upd = await waitFor(sB, 'inbox:updated', (p) => p.reason === 'request_received');
  check('B inbox:updated', upd && upd.inbox.requests.received === 1 && upd.inbox.showBadge === true);
  check('A inbox:updated (sent)', Boolean(await waitFor(sA, 'inbox:updated', (p) => p.reason === 'request_sent' && p.inbox.requests.sent === 1)));
  const nl = await call('GET', '/notifications', { token: B.token });
  check('notifications list', nl.data[0].id === live.id && nl.body.data.unreadCount >= 1 && nl.meta.total >= 1);
  check('unread count', (await call('GET', '/notifications/unread-count', { token: B.token })).data.unreadCount >= 1);
  check('summary has unread', (await call('GET', '/inbox/summary', { token: B.token })).data.notifications.unread >= 1);
  await call('DELETE', `/connections/requests/${rt1.id}`, { token: A.token });
  const removed = await waitFor(sB, 'notification:removed', (p) => p.ids.includes(live.id));
  check('withdraw removes notification live', Boolean(removed));
  check('withdrawn notification gone', !(await call('GET', '/notifications', { token: B.token })).data.some((n) => n.id === live.id));
  const rt2 = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id }, expect: 201 })).data;
  const live2 = await waitFor(sB, 'notification', (n) => n.data.requestId === rt2.id);
  check('no-message body', live2 && /wants to connect with you/.test(live2.body));
  await call('POST', `/connections/requests/${rt2.id}/accept`, { token: B.token });
  const accepted = await waitFor(sA, 'notification', (n) => n.type === 'connection_request.accepted' && n.data.requestId === rt2.id);
  check('A gets accepted notification', accepted && accepted.actor.id === B.id && accepted.data.screen === 'inbox.connections');
  const unreadB = (await call('GET', '/notifications?unreadOnly=true', { token: B.token })).data;
  check('answered request notification marked read', !unreadB.some((n) => n.data.requestId === rt2.id));
  await call('PATCH', `/notifications/${accepted.id}/read`, { token: B.token, expect: 404 }); // not B's
  const rd = (await call('PATCH', `/notifications/${accepted.id}/read`, { token: A.token })).data;
  check('mark read', rd.isRead === true && typeof rd.unreadCount === 'number');
  check('read-all', (await call('PATCH', '/notifications/read-all', { token: A.token })).data.unreadCount === 0);
  check('delete notification', (await call('DELETE', `/notifications/${accepted.id}`, { token: A.token })).data.deleted === true);
  await call('DELETE', `/notifications/${accepted.id}`, { token: A.token, expect: 404 });
  await call('GET', '/notifications', { expect: 401 });
  await call('DELETE', `/connections/${B.id}`, { token: A.token });
  check('connection_removed pushed to both', Boolean(await waitFor(sB, 'inbox:updated', (p) => p.reason === 'connection_removed'))
    && Boolean(await waitFor(sA, 'inbox:updated', (p) => p.reason === 'connection_removed')));
  // admin block closes the member's live connection
  const sC = await listen(C.token);
  const cGone = new Promise((r) => sC.s.on('disconnect', () => r(true)));
  await call('PATCH', `/admin/users/${C.id}/status`, { token: at, body: { status: 'blocked' } });
  check('blocked member disconnected', await Promise.race([cGone, new Promise((r) => setTimeout(() => r(false), 3000))]));
  const blockedSock = await listen(C.token).then(() => null, (e) => e);
  check('blocked member cannot reconnect', blockedSock && blockedSock.message === 'ACCOUNT_BLOCKED');
  await call('PATCH', `/admin/users/${C.id}/status`, { token: at, body: { status: 'active' } });

  // Admin › Networking
  const pend = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id, message: 'Admin test' }, expect: 201 })).data;
  const adminReqs = await call('GET', `/admin/connection-requests?status=pending&userId=${A.id}`, { token: at });
  check('admin sees pending request', adminReqs.data.some((r) => r.id === pend.id && r.sender.id === A.id && r.receiver.id === B.id) && adminReqs.meta.total >= 1);
  check('admin request search', (await call('GET', '/admin/connection-requests?status=all&search=Admin%20test', { token: at })).data.some((r) => r.id === pend.id));
  await call('GET', '/admin/connection-requests?status=bogus', { token: at, expect: 400 });
  await call('GET', '/admin/connection-requests', { token: A.token, expect: 403 }); // user token
  const cancelled = await call('PATCH', `/admin/connection-requests/${pend.id}/cancel`, { token: at });
  check('admin cancel', cancelled.data.status === 'withdrawn' && /cancelled/i.test(cancelled.message));
  check('cancel twice → REQUEST_CLOSED', (await call('PATCH', `/admin/connection-requests/${pend.id}/cancel`, { token: at, expect: 409 })).error.code === 'REQUEST_CLOSED');
  await call('PATCH', '/admin/connection-requests/999999/cancel', { token: at, expect: 404 });
  check('admin cancel removes notification live', Boolean(await waitFor(sB, 'inbox:updated', (p) => p.reason === 'request_cancelled_by_admin')));
  check('cancelled request gone from Inbox', (await call('GET', '/connections/requests?direction=received', { token: B.token })).data.length === 0);
  const again = (await call('POST', '/connections/requests', { token: A.token, body: { userId: B.id }, expect: 201 })).data;
  await call('POST', `/connections/requests/${again.id}/accept`, { token: B.token });
  // 1:1 chat
  check('no chats yet', (await call('GET', '/chats', { token: A.token })).data.length === 0);
  await call('POST', '/chats', { token: A.token, body: { userId: A.id }, expect: 400 });
  check('chat needs connection', (await call('POST', '/chats', { token: A.token, body: { userId: C.id }, expect: 403 })).error.code === 'NOT_CONNECTED');
  const chat = (await call('POST', '/chats', { token: A.token, body: { userId: B.id } })).data;
  check('chat opened', chat.id > 0 && chat.user.id === B.id && chat.canSend === true && chat.lastMessage === null && chat.unreadCount === 0);
  check('same chat for both', (await call('POST', '/chats', { token: B.token, body: { userId: A.id } })).data.id === chat.id);
  check('empty chat not listed', (await call('GET', '/chats', { token: A.token })).data.length === 0);
  await call('GET', `/chats/${chat.id}`, { token: C.token, expect: 404 });
  await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: '   ' }, expect: 400 });
  await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: 'x'.repeat(2001) }, expect: 400 });
  await call('POST', `/chats/${chat.id}/messages`, { token: C.token, body: { body: 'hi' }, expect: 404 });
  const m1 = (await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: 'Hi Zed 👋', clientId: 'c-1' }, expect: 201 })).data;
  check('message sent', m1.id > 0 && m1.isMine === true && m1.body === 'Hi Zed 👋' && m1.senderId === A.id);
  check('retry is idempotent', (await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: 'Hi Zed 👋', clientId: 'c-1' } })).data.id === m1.id);
  const liveMsg = await waitFor(sB, 'message:new', (p) => p.message.id === m1.id);
  check('B gets message live', liveMsg && liveMsg.message.isMine === false && liveMsg.unreadCount === 1 && liveMsg.totalUnread === 1 && liveMsg.sender.id === A.id);
  check('A other device echo', Boolean(await waitFor(sA, 'message:new', (p) => p.message.id === m1.id && p.message.isMine === true)));
  sA.s.emit('typing', { conversationId: chat.id, isTyping: true });
  check('typing forwarded', Boolean(await waitFor(sB, 'typing', (p) => p.conversationId === chat.id && p.userId === A.id && p.isTyping === true)));
  {
    const sC2 = await listen(C.token);
    sC2.s.emit('typing', { conversationId: chat.id, isTyping: true });
    check('outsider typing ignored', !(await waitFor(sB, 'typing', (p) => p.userId === C.id, 600)));
    sC2.s.close();
  }
  const m2 = (await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: 'Coffee this week?' }, expect: 201 })).data;
  const listB = await call('GET', '/chats', { token: B.token });
  check('chat list', listB.data.length === 1 && listB.data[0].lastMessage.id === m2.id && listB.data[0].unreadCount === 2 && listB.body.data.totalUnread === 2 && listB.data[0].user.id === A.id);
  check('chat search', (await call('GET', '/chats?search=krupa', { token: B.token })).data.length === 1 && (await call('GET', '/chats?search=nobody', { token: B.token })).data.length === 0);
  check('summary messages unread', (await call('GET', '/inbox/summary', { token: B.token })).data.messages.unread === 2);
  const hist = (await call('GET', `/chats/${chat.id}/messages`, { token: B.token })).body.data;
  check('history oldest→newest', hist.items.length === 2 && hist.items[0].id === m1.id && hist.items[1].id === m2.id && hist.hasMore === false && hist.otherLastReadId === m2.id);
  const page1 = (await call('GET', `/chats/${chat.id}/messages?limit=1`, { token: B.token })).body.data;
  const page2 = (await call('GET', `/chats/${chat.id}/messages?limit=1&before=${page1.items[0].id}`, { token: B.token })).body.data;
  check('paging older', page1.items[0].id === m2.id && page1.hasMore === true && page2.items[0].id === m1.id && page2.hasMore === false);
  check('catch up after', (await call('GET', `/chats/${chat.id}/messages?after=${m1.id}`, { token: B.token })).body.data.items.map((m) => m.id).join() === String(m2.id));
  const rdB = (await call('POST', `/chats/${chat.id}/read`, { token: B.token, body: {} })).data;
  check('read', rdB.lastReadId === m2.id && rdB.unreadCount === 0 && rdB.totalUnread === 0);
  check('A sees ✓✓ live', Boolean(await waitFor(sA, 'message:read', (p) => p.conversationId === chat.id && p.lastReadId === m2.id && p.readerId === B.id)));
  check('A list shows read', (await call('GET', '/chats', { token: A.token })).data[0].otherLastReadId === m2.id);
  const reply = (await call('POST', `/chats/${chat.id}/messages`, { token: B.token, body: { body: 'Sure, Thursday?' }, expect: 201 })).data;
  check('reply order', (await call('GET', '/chats', { token: A.token })).data[0].lastMessage.id === reply.id);
  const adminConns = await call('GET', `/admin/connections?userId=${A.id}`, { token: at });
  check('admin sees connection', adminConns.data.length === 1 && [adminConns.data[0].userA.id, adminConns.data[0].userB.id].sort().join() === [A.id, B.id].sort().join() && adminConns.data[0].requestId === again.id);
  check('admin connection search', (await call('GET', '/admin/connections?search=Zed', { token: at })).meta.total >= 1);
  const ud = (await call('GET', `/admin/users/${A.id}`, { token: at })).data;
  check('user network summary', ud.network.connections === 1 && ud.network.requestsSent.total >= 5 && ud.network.requestsSent.accepted >= 2 && ud.network.recentConnections[0].id === B.id);
  const ulist = (await call('GET', '/admin/users?search=Zed', { token: at })).data;
  check('users list connections column', ulist[0].connections === 1 && ulist[0].openToConnect === true);
  const net = (await call('GET', '/admin/stats', { token: at })).data.network;
  check('stats network', net.connections >= 1 && net.requests.total >= 6 && net.requests.withdrawn >= 2 && typeof net.acceptanceRate === 'number' && net.requestsByDay.length >= 1 && net.notOpenToConnect >= 1 && net.hiddenFromDiscovery >= 1);
  await call('DELETE', `/admin/connections/${B.id}/${A.id}`, { token: at }); // either order
  await call('DELETE', `/admin/connections/${A.id}/${B.id}`, { token: at, expect: 404 });
  check('removed for members too', (await call('GET', '/connections', { token: A.token })).data.length === 0);
  const oldChat = (await call('GET', `/chats/${chat.id}`, { token: A.token })).data;
  check('history kept, sending closed', oldChat.canSend === false && oldChat.lastMessage.id === reply.id);
  check('NOT_CONNECTED send', (await call('POST', `/chats/${chat.id}/messages`, { token: A.token, body: { body: 'still there?' }, expect: 403 })).error.code === 'NOT_CONNECTED');

  sA.s.close();
  sB.s.close();

  // API docs
  const docs = await fetch(BASE.replace('/api/v1', '') + '/docs/openapi.json').then((r) => r.json());
  const opCount = Object.values(docs.paths).reduce((n, o) => n + Object.keys(o).length, 0);
  check('openapi served', docs.openapi === '3.1.0' && opCount >= 125);

  // ── Report ───────────────────────────────────────────────────────
  console.log(`\nEndpoints exercised: ${hit.size}`);
  console.log(`Checks passed: ${passed}`);
  if (defaultMessages.size) console.log(`\nEndpoints still using a generic message (${defaultMessages.size}):\n - ${[...defaultMessages].join('\n - ')}`);
  failures.push(...envelopeIssues.map((e) => `envelope: ${e}`));
  if (failures.length) {
    console.log(`\nFAILED (${failures.length}):\n - ${failures.join('\n - ')}`);
    process.exit(1);
  }
  console.log('ALL GREEN ✅');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
