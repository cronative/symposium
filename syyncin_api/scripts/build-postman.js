/** npm run postman → postman/SyyncIn.postman_collection.json */
const fs = require('fs');
const path = require('path');
const { TYPES } = require('../src/modules/admin/masterData');

const json = (o) => ({ mode: 'raw', raw: JSON.stringify(o, null, 2), options: { raw: { language: 'json' } } });
const req = (name, method, url, { body, auth, form, tests, query } = {}) => {
  const [p, qs] = url.split('?');
  const r = {
    name,
    request: {
      method,
      header: [],
      url: {
        raw: `{{baseUrl}}${url}`,
        host: ['{{baseUrl}}'],
        path: p.split('/').filter(Boolean),
        ...(qs || query ? { query: (qs || '').split('&').filter(Boolean).map((kv) => { const [key, value] = kv.split('='); return { key, value }; }) } : {}),
      },
    },
  };
  if (auth) r.request.auth = { type: 'bearer', bearer: [{ key: 'token', value: auth === 'admin' ? '{{adminToken}}' : '{{accessToken}}', type: 'string' }] };
  else r.request.auth = { type: 'noauth' };
  if (body) r.request.body = json(body);
  if (form) r.request.body = { mode: 'formdata', formdata: [{ key: form, type: 'file', src: [] }] };
  if (tests) r.event = [{ listen: 'test', script: { type: 'text/javascript', exec: tests } }];
  return r;
};
const save = (pairs) => [
  'const j = pm.response.json();',
  ...pairs.map(([v, p]) => `if (j.data && ${p}) pm.collectionVariables.set('${v}', ${p});`),
];

const samples = {
  industries: { name: 'Hospitality' },
  'experience-levels': { label: '15+ years', minYears: 15, maxYears: null },
  skills: { name: 'Figma', industryId: 2 },
  interests: { name: 'Photography', icon: 'camera' },
  reasons: { title: 'Find a mentor', subtitle: 'Learn from experienced professionals', icon: 'graduation' },
  cities: { name: 'Rajkot', state: 'Gujarat', lat: 22.3039, lng: 70.8022 },
  localities: { cityId: 1, name: 'Science City' },
  'mindset-questions': { question: 'How do you recharge?', options: ['Alone', 'With friends', 'Outdoors', 'Learning'] },
};
const filters = { skills: '&industryId=', localities: '&cityId=1' };

const masterFolders = Object.keys(TYPES).map((type) => {
  const v = `${type.replace(/-./g, (m) => m[1].toUpperCase())}Id`;
  return {
    name: TYPES[type].label === 'Question' ? 'Mindset questions' : `${TYPES[type].label}s`.replace('ys', 'ies'),
    item: [
      req(`List ${type}`, 'GET', `/admin/${type}?search=&status=all&page=1&limit=20${filters[type] || ''}`, { auth: 'admin' }),
      req(`Create`, 'POST', `/admin/${type}`, { auth: 'admin', body: samples[type], tests: save([[v, 'j.data.id']]) }),
      req(`Get one`, 'GET', `/admin/${type}/{{${v}}}`, { auth: 'admin' }),
      req(`Update`, 'PUT', `/admin/${type}/{{${v}}}`, { auth: 'admin', body: Object.fromEntries(Object.entries(samples[type]).filter(([k]) => k !== 'options').slice(0, 1)) }),
      req(`Activate / deactivate`, 'PATCH', `/admin/${type}/{{${v}}}/status`, { auth: 'admin', body: { isActive: false } }),
      req(`Reorder`, 'PATCH', `/admin/${type}/reorder`, { auth: 'admin', body: { ids: [`{{${v}}}`, 1, 2].map((x) => (typeof x === 'string' ? x : x)) } }),
      req(`Delete (deactivates if in use)`, 'DELETE', `/admin/${type}/{{${v}}}`, { auth: 'admin' }),
    ],
  };
});
// Reorder body needs numeric ids — fix the placeholder to be unquoted.
for (const f of masterFolders) {
  const r = f.item.find((i) => i.name === 'Reorder');
  r.request.body.raw = r.request.body.raw.replace(/"(\{\{\w+\}\})"/, '$1');
}

// Runs after every request: checks the standard { status, data, message } envelope.
const envelopeTest = [
  "if ((pm.response.headers.get('Content-Type') || '').includes('application/json')) {",
  '  const body = pm.response.json();',
  "  pm.test('standard envelope { status, data, message }', () => {",
  "    pm.expect(body).to.have.all.keys('status', 'data', 'message');",
  "    pm.expect(body.status).to.eql(pm.response.code < 400 ? 1 : 0);",
  "    pm.expect(body.data).to.be.an('object');",
  "    pm.expect(body.message).to.be.a('string').and.not.empty;",
  '  });',
  '}',
];

const collection = {
  event: [{ listen: 'test', script: { type: 'text/javascript', exec: envelopeTest } }],
  info: {
    name: 'SyyncIn API',
    description:
      'App + Admin APIs. Run "App › Auth › Request OTP" then "Verify OTP" (devCode is auto-filled in mock mode); ' +
      'run "Admin › Auth › Login" for admin calls. Tokens are stored in collection variables automatically. ' +
      'Full reference with try-it-out: http://localhost:4000/docs',
    schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
  },
  variable: [
    { key: 'baseUrl', value: 'http://localhost:4000/api/v1' },
    { key: 'accessToken', value: '' },
    { key: 'refreshToken', value: '' },
    { key: 'requestId', value: '' },
    { key: 'otpCode', value: '' },
    { key: 'adminToken', value: '' },
    { key: 'adminRefreshToken', value: '' },
    { key: 'verificationId', value: '' },
    { key: 'userId', value: '1' },
    { key: 'questionId', value: '1' },
    { key: 'optionId', value: '' },
    { key: 'memberId', value: '2' },
    { key: 'connectionRequestId', value: '' },
    { key: 'adminRequestId', value: '' },
    { key: 'notificationId', value: '' },
    { key: 'connUserA', value: '' },
    { key: 'connUserB', value: '' },
    ...Object.keys(TYPES).map((t) => ({ key: `${t.replace(/-./g, (m) => m[1].toUpperCase())}Id`, value: '' })),
  ],
  item: [
    {
      name: 'App',
      item: [
        { name: 'Config & profile', item: [
          req('App config', 'GET', '/app/config'),
          req('Me', 'GET', '/me', { auth: 'user' }),
          req('Upload profile photo', 'POST', '/me/photo', { auth: 'user', form: 'photo' }),
          req('Remove profile photo', 'DELETE', '/me/photo', { auth: 'user' }),
          req('Edit profile (any sections)', 'PUT', '/me/profile', { auth: 'user', body: {
            basic: { fullName: 'Krupa Shah', dob: '1996-06-12', gender: 'woman', linkedinUrl: 'https://linkedin.com/in/krupashah', about: 'I enjoy designing intuitive digital experiences.' },
            work: { jobTitle: 'UI/UX Designer', industryId: 2, company: 'Independent Designer', experienceLevelId: 3, skillIds: [1, 17] },
            interests: { interestIds: [1, 3, 4, 11], reasonIds: [1, 2, 3] },
            community: { cityId: 1, localityId: 1, connectMode: 'both', radiusKm: 25, availability: ['weekends', 'evenings'], nearbyDiscovery: true, openToConnect: true },
          } }),
          req('Settings toggles', 'PATCH', '/me/settings', { auth: 'user', body: { openToConnect: true, nearbyDiscovery: true } }),
          req('Saved members', 'GET', '/me/saved?page=1&limit=20', { auth: 'user' }),
        ] },
        { name: 'KYN & Filters', item: [
          req('Discover (KYN Home)', 'GET', '/discover?search=&quick=all&sort=nearest&page=1&limit=20', { auth: 'user', tests: save([['memberId', 'j.data.items && j.data.items[0] && j.data.items[0].id']]) }),
          req('Discover with filters', 'GET', '/discover?industryId=1&interestIds=1,3&experienceLevelId=4&maxDistanceKm=10&sort=name&verifiedOnly=false', { auth: 'user' }),
          req('Count for "Show N people"', 'GET', '/discover?maxDistanceKm=10&limit=1', { auth: 'user' }),
          req('Filter options', 'GET', '/discover/filters', { auth: 'user' }),
        ] },
        { name: 'Members', item: [
          req('Professional profile', 'GET', '/users/{{memberId}}', { auth: 'user' }),
          req('Icebreakers', 'GET', '/users/{{memberId}}/icebreakers', { auth: 'user' }),
          req('Bookmark', 'PUT', '/users/{{memberId}}/save', { auth: 'user' }),
          req('Remove bookmark', 'DELETE', '/users/{{memberId}}/save', { auth: 'user' }),
        ] },
        { name: 'Connections & Inbox', item: [
          req('Send request', 'POST', '/connections/requests', { auth: 'user', body: { userId: '{{memberId}}', message: "Hi, I'd love to connect and exchange ideas." }, tests: save([['connectionRequestId', 'j.data.id']]) }),
          req('Requests received', 'GET', '/connections/requests?direction=received&status=pending', { auth: 'user', tests: save([['connectionRequestId', 'j.data.items && j.data.items[0] && j.data.items[0].id']]) }),
          req('Requests sent', 'GET', '/connections/requests?direction=sent&status=pending', { auth: 'user' }),
          req('Accept request', 'POST', '/connections/requests/{{connectionRequestId}}/accept', { auth: 'user' }),
          req('Decline request', 'POST', '/connections/requests/{{connectionRequestId}}/decline', { auth: 'user' }),
          req('Withdraw request', 'DELETE', '/connections/requests/{{connectionRequestId}}', { auth: 'user' }),
          req('My connections', 'GET', '/connections?search=&page=1&limit=20', { auth: 'user' }),
          req('Remove connection', 'DELETE', '/connections/{{memberId}}', { auth: 'user' }),
          req('Inbox summary (badges)', 'GET', '/inbox/summary', { auth: 'user' }),
        ] },
        { name: 'Notifications', item: [
          req('List', 'GET', '/notifications?unreadOnly=false&page=1&limit=20', { auth: 'user', tests: save([['notificationId', 'j.data.items && j.data.items[0] && j.data.items[0].id']]) }),
          req('Unread count', 'GET', '/notifications/unread-count', { auth: 'user' }),
          req('Mark one read', 'PATCH', '/notifications/{{notificationId}}/read', { auth: 'user' }),
          req('Mark all read', 'PATCH', '/notifications/read-all', { auth: 'user' }),
          req('Delete', 'DELETE', '/notifications/{{notificationId}}', { auth: 'user' }),
        ] },
        { name: 'Auth', item: [
          req('Request OTP', 'POST', '/auth/otp/request', { body: { identifier: '+919812345210', termsAccepted: true }, tests: save([['requestId', 'j.data.requestId'], ['otpCode', 'j.data.devCode']]) }),
          req('Resend OTP', 'POST', '/auth/otp/resend', { body: { requestId: '{{requestId}}' }, tests: save([['otpCode', 'j.data.devCode']]) }),
          req('Verify OTP', 'POST', '/auth/otp/verify', { body: { requestId: '{{requestId}}', code: '{{otpCode}}' }, tests: save([['accessToken', 'j.data.accessToken'], ['refreshToken', 'j.data.refreshToken']]) }),
          req('Social sign-in (mock token)', 'POST', '/auth/social', { body: { provider: 'google', idToken: 'mock:google-uid-123:user@example.com', termsAccepted: true }, tests: save([['accessToken', 'j.data.accessToken'], ['refreshToken', 'j.data.refreshToken']]) }),
          req('Refresh token', 'POST', '/auth/refresh', { body: { refreshToken: '{{refreshToken}}' }, tests: save([['accessToken', 'j.data.accessToken'], ['refreshToken', 'j.data.refreshToken']]) }),
          req('Logout', 'POST', '/auth/logout', { body: { refreshToken: '{{refreshToken}}' } }),
        ] },
        { name: 'Meta (lookups)', item: [
          req('Industries', 'GET', '/meta/industries'),
          req('Experience levels', 'GET', '/meta/experience-levels'),
          req('Skills (search)', 'GET', '/meta/skills?q=fl&industryId='),
          req('Interests', 'GET', '/meta/interests'),
          req('Reasons', 'GET', '/meta/reasons'),
          req('Mindset questions', 'GET', '/meta/mindset-questions'),
          req('Cities (search)', 'GET', '/meta/cities?q=Ahm'),
          req('Localities', 'GET', '/meta/localities?cityId=1&q='),
        ] },
        { name: 'Onboarding', item: [
          req('Status', 'GET', '/onboarding/status', { auth: 'user' }),
          req('Step 1 · Basic', 'PUT', '/onboarding/basic', { auth: 'user', body: { fullName: 'Krupa Shah', dob: '1995-06-15', linkedinUrl: 'https://linkedin.com/in/krupa-shah', gender: 'woman' } }),
          req('Step 2 · Work', 'PUT', '/onboarding/work', { auth: 'user', body: { jobTitle: 'UI/UX Designer', industryId: 2, company: 'Airbnb', experienceLevelId: 3, skillIds: [1, 2] } }),
          req('Step 3 · Interests & reasons', 'PUT', '/onboarding/interests', { auth: 'user', body: { interestIds: [1, 2, 4], reasonIds: [1, 5] } }),
          req('Step 4 · Mindset', 'PUT', '/onboarding/mindset', { auth: 'user', body: { answers: [{ questionId: 1, optionId: 1 }, { questionId: 2, optionId: 5 }, { questionId: 3, optionId: 9 }, { questionId: 4, optionId: 13 }, { questionId: 5, optionId: 17 }] } }),
          req('Step 5 · Community', 'PUT', '/onboarding/community', { auth: 'user', body: { cityId: 1, localityId: 1, lat: 23.0225, lng: 72.5714, connectMode: 'both', radiusKm: 25, availability: ['flexible'], nearbyDiscovery: true } }),
        ] },
        { name: 'Verification', item: [
          req('Submit selfie', 'POST', '/verification/selfie', { auth: 'user', form: 'selfie', tests: save([['verificationId', 'j.data.id']]) }),
          req('Latest verification', 'GET', '/verification/latest', { auth: 'user' }),
          req('Verification by id', 'GET', '/verification/{{verificationId}}', { auth: 'user' }),
        ] },
      ],
    },
    {
      name: 'Admin',
      item: [
        { name: 'Auth', item: [
          req('Login', 'POST', '/admin/auth/login', { body: { email: 'admin@syyncin.app', password: 'Admin#12345' }, tests: save([['adminToken', 'j.data.accessToken'], ['adminRefreshToken', 'j.data.refreshToken']]) }),
          req('Refresh', 'POST', '/admin/auth/refresh', { body: { refreshToken: '{{adminRefreshToken}}' }, tests: save([['adminToken', 'j.data.accessToken'], ['adminRefreshToken', 'j.data.refreshToken']]) }),
          req('Me', 'GET', '/admin/auth/me', { auth: 'admin' }),
          req('Dashboard stats', 'GET', '/admin/stats', { auth: 'admin' }),
          req('Logout', 'POST', '/admin/auth/logout', { body: { refreshToken: '{{adminRefreshToken}}' } }),
        ] },
        { name: 'Master data', item: masterFolders },
        { name: 'Mindset options', item: [
          req('Add option to question', 'POST', '/admin/mindset-questions/{{questionId}}/options', { auth: 'admin', body: { label: 'Freedom' }, tests: save([['optionId', 'j.data.id']]) }),
          req('Update option', 'PUT', '/admin/mindset-options/{{optionId}}', { auth: 'admin', body: { label: 'Independence', isActive: true } }),
          req('Delete option', 'DELETE', '/admin/mindset-options/{{optionId}}', { auth: 'admin' }),
        ] },
        { name: 'Verifications', item: [
          req('Queue', 'GET', '/admin/verifications?status=pending&search=&page=1&limit=20', { auth: 'admin' }),
          req('Detail', 'GET', '/admin/verifications/{{verificationId}}', { auth: 'admin' }),
          req('Selfie image', 'GET', '/admin/verifications/{{verificationId}}/selfie', { auth: 'admin' }),
          req('Approve', 'PATCH', '/admin/verifications/{{verificationId}}', { auth: 'admin', body: { action: 'approve' } }),
          req('Reject', 'PATCH', '/admin/verifications/{{verificationId}}', { auth: 'admin', body: { action: 'reject', reason: 'Face not clearly visible' } }),
        ] },
        { name: 'Networking', item: [
          req('Connection requests', 'GET', '/admin/connection-requests?status=all&search=&userId=&page=1&limit=20', { auth: 'admin', tests: save([['adminRequestId', 'j.data.items && j.data.items[0] && j.data.items[0].id']]) }),
          req('Cancel pending request', 'PATCH', '/admin/connection-requests/{{adminRequestId}}/cancel', { auth: 'admin' }),
          req('Connections', 'GET', '/admin/connections?search=&userId=&page=1&limit=20', { auth: 'admin', tests: save([['connUserA', 'j.data.items && j.data.items[0] && j.data.items[0].userA.id'], ['connUserB', 'j.data.items && j.data.items[0] && j.data.items[0].userB.id']]) }),
          req('Remove connection', 'DELETE', '/admin/connections/{{connUserA}}/{{connUserB}}', { auth: 'admin' }),
        ] },
        { name: 'Users', item: [
          req('List', 'GET', '/admin/users?search=&status=all&verificationStatus=&onboarding=&page=1&limit=20', { auth: 'admin' }),
          req('Detail', 'GET', '/admin/users/{{userId}}', { auth: 'admin' }),
          req('Block', 'PATCH', '/admin/users/{{userId}}/status', { auth: 'admin', body: { status: 'blocked' } }),
          req('Unblock', 'PATCH', '/admin/users/{{userId}}/status', { auth: 'admin', body: { status: 'active' } }),
        ] },
      ],
    },
  ],
};

const out = path.join(__dirname, '../postman/SyyncIn.postman_collection.json');
fs.writeFileSync(out, JSON.stringify(collection, null, 2));
let n = 0;
const count = (items) => items.forEach((i) => (i.item ? count(i.item) : n++));
count(collection.item);
console.log(`✓ ${out} (${n} requests)`);
