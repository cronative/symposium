/**
 * OpenAPI 3.1 description of every SyyncIn endpoint — served by Swagger UI at /docs
 * (raw JSON at /docs/openapi.json; import that URL into Postman / Insomnia too).
 *
 * Request bodies for profile sections and admin master data are generated from the
 * same zod schemas the API validates with, so the docs can't drift from the rules.
 */
const { z } = require('zod');
const env = require('../config/env');
const { SECTIONS, GENDERS, CONNECT_MODES, AVAILABILITY } = require('../services/profileSections');
const { TYPES } = require('../modules/admin/masterData');

const fromZod = (schema) => {
  const s = z.toJSONSchema(schema, { io: 'input', unrepresentable: 'any' });
  delete s.$schema;
  return s;
};
const ref = (name) => ({ $ref: `#/components/schemas/${name}` });
const arr = (items) => ({ type: 'array', items });
const obj = (properties, required) => ({ type: 'object', properties, ...(required ? { required } : {}) });
const str = (extra = {}) => ({ type: 'string', ...extra });
const int = (extra = {}) => ({ type: 'integer', ...extra });
const bool = { type: 'boolean' };
const nullable = (s) => ({ ...s, type: [s.type, 'null'] });
const idObj = (labelKey = 'name') => nullable(obj({ id: int(), [labelKey]: str() }));

const pathId = (name = 'id', description) => ({ name, in: 'path', required: true, schema: int({ minimum: 1 }), ...(description ? { description } : {}) });
const q = (name, schema, description, extra = {}) => ({ name, in: 'query', schema, ...(description ? { description } : {}), ...extra });
const pageParams = [q('page', int({ minimum: 1, default: 1 })), q('limit', int({ minimum: 1, maximum: 100, default: 20 }))];

/** Build one operation. */
function op(tag, summary, o = {}) {
  const {
    auth = 'user', description, params = [], body, bodyExample, multipart, data, example, status = 200, paged = false, errors = [], raw,
  } = o;
  // Lists are always wrapped: data = { items: [...], pagination? }
  let payload = data || { type: 'object' };
  if (payload.type === 'array') payload = obj({ items: payload, ...(paged ? { pagination: ref('PageMeta') } : {}) }, paged ? ['items', 'pagination'] : ['items']);
  const success = obj({ status: { type: 'integer', const: 1 }, data: payload, message: str({ example: o.message || 'Request completed successfully.' }) }, ['status', 'data', 'message']);
  const out = {
    tags: [tag],
    summary,
    ...(description ? { description } : {}),
    ...(auth ? { security: [{ [auth === 'admin' ? 'adminAuth' : 'userAuth']: [] }] } : { security: [] }),
    ...(params.length ? { parameters: params } : {}),
    responses: {
      [status]: raw
        ? { description: raw.description, content: { [raw.type]: { schema: { type: 'string', format: 'binary' } } } }
        : { description: 'OK', content: { 'application/json': { schema: success, ...(example ? { example: { status: 1, data: example, message: o.message || 'Request completed successfully.' } } : {}) } } },
    },
  };
  if (body) {
    out.requestBody = { required: true, content: { 'application/json': { schema: body, ...(bodyExample ? { example: bodyExample } : {}) } } };
  }
  if (multipart) {
    out.requestBody = {
      required: true,
      content: { 'multipart/form-data': { schema: obj({ [multipart]: str({ format: 'binary', description: `JPG / PNG / WEBP, max ${env.uploads.maxImageMb} MB` }) }, [multipart]) } },
    };
  }
  const errs = [...(auth ? ['401 UNAUTHORIZED / TOKEN_INVALID'] : []), ...errors];
  for (const e of errs) {
    const [code, ...name] = e.split(' ');
    const key = code;
    const text = name.join(' ');
    out.responses[key] = out.responses[key]
      ? { ...out.responses[key], description: `${out.responses[key].description} · ${text}` }
      : { description: text, content: { 'application/json': { schema: ref('Error') } } };
  }
  return out;
}

// ─── Reusable schemas ──────────────────────────────────────────────────
const schemas = {
  Error: {
    ...obj(
      {
        status: { type: 'integer', const: 0 },
        data: {
          ...obj({
            code: str({ description: 'Stable machine code — branch on this in the app', example: 'VALIDATION_ERROR' }),
            errors: arr(obj({ field: str({ example: 'fullName' }), message: str({ example: 'Full name must have at least 2 characters.' }) })),
          }, ['code']),
          description: '`errors` is present for validation failures. Some errors add context, e.g. `requestId`, `remainingAttempts`, `currentStep`.',
          additionalProperties: true,
        },
        message: str({ description: 'Human-readable — show it to the user', example: 'Full name must have at least 2 characters.' }),
      },
      ['status', 'data', 'message'],
    ),
    example: { status: 0, data: { code: 'VALIDATION_ERROR', errors: [{ field: 'fullName', message: 'Full name must have at least 2 characters.' }] }, message: 'Full name must have at least 2 characters.' },
  },
  PageMeta: obj({ page: int(), limit: int(), total: int(), totalPages: int() }),
  Tokens: obj({
    accessToken: str(),
    refreshToken: str(),
    expiresIn: int({ description: 'Access-token lifetime in seconds' }),
    user: obj({ id: int(), isNew: bool, onboardingStep: int({ minimum: 1, maximum: 7 }), verificationStatus: str({ enum: ['none', 'pending', 'verified', 'rejected'] }) }),
  }),
  Profile: obj({
    id: int(),
    phone: nullable(str()),
    email: nullable(str()),
    fullName: nullable(str()),
    dob: nullable(str({ format: 'date' })),
    gender: nullable(str({ enum: GENDERS })),
    linkedinUrl: nullable(str()),
    about: nullable(str()),
    photoUrl: nullable(str({ format: 'uri' })),
    work: obj({ jobTitle: nullable(str()), industry: idObj(), company: nullable(str()), experienceLevel: idObj('label'), skills: arr(obj({ id: int(), name: str() })) }),
    interests: arr(obj({ id: int(), name: str() })),
    reasons: arr(obj({ id: int(), title: str(), icon: str() })),
    mindset: arr(obj({ questionId: int(), question: str(), optionId: int(), answer: str() })),
    community: obj({
      city: nullable(obj({ id: int(), name: str(), state: str() })),
      locality: idObj(),
      lat: nullable({ type: 'number' }),
      lng: nullable({ type: 'number' }),
      connectMode: nullable(str({ enum: CONNECT_MODES })),
      radiusKm: nullable(int()),
      availability: arr(str({ enum: AVAILABILITY })),
      nearbyDiscovery: bool,
      openToConnect: bool,
    }),
    onboarding: obj({ step: int(), stepName: str(), completed: bool }),
    verificationStatus: str({ enum: ['none', 'pending', 'verified', 'rejected'] }),
    status: str({ enum: ['active', 'blocked'] }),
    createdAt: str({ format: 'date-time' }),
  }),
  Connection: obj(
    {
      status: str({ enum: ['none', 'pending_sent', 'pending_received', 'connected', 'self'] }),
      requestId: nullable(int({ description: 'Set while a request is pending (use it to accept / withdraw)' })),
      connectedAt: nullable(str({ format: 'date-time' })),
    },
    ['status'],
  ),
  PersonCard: obj({
    id: int(),
    match: nullable(obj({ score: int({ minimum: 0, maximum: 100 }), level: str({ enum: ['excellent', 'strong', 'potential', 'low', 'insufficient'] }), label: str(), reasons: arr(str()), breakdown: { type: 'object', additionalProperties: int() }, insufficient: bool, algorithmVersion: str() })),
    fullName: str(),
    initials: str({ example: 'KS' }),
    photoUrl: nullable(str({ format: 'uri' })),
    jobTitle: nullable(str()),
    company: nullable(str()),
    industry: idObj(),
    experienceLevel: idObj('label'),
    city: idObj(),
    locality: idObj(),
    distanceKm: nullable({ type: 'number', description: 'Rounded to 0.1 km. null when either side has no location.' }),
    verified: bool,
    openToConnect: bool,
    interests: arr(obj({ id: int(), name: str() })),
    sharedInterests: arr(str()),
    isSaved: bool,
    connection: ref('Connection'),
  }),
  PersonDetail: {
    allOf: [
      ref('PersonCard'),
      obj({
        about: nullable(str()),
        skills: arr(obj({ id: int(), name: str() })),
        intent: arr(obj({ id: int(), title: str(), icon: str() })),
        mindset: arr(obj({ questionId: int(), question: str(), optionId: int(), answer: str(), shared: bool })),
        connectionPreferences: obj({ connectMode: nullable(str({ enum: CONNECT_MODES })), availability: arr(str()) }),
        linkedinUrl: nullable(str({ description: 'Only for connections (and yourself)' })),
        memberSince: str({ format: 'date-time' }),
      }),
    ],
  },
  ConnectionRequest: obj({
    id: int(),
    direction: str({ enum: ['received', 'sent'] }),
    status: str({ enum: ['pending', 'accepted', 'declined', 'withdrawn'] }),
    message: nullable(str({ maxLength: env.rules.requestMessageMax })),
    createdAt: str({ format: 'date-time' }),
    respondedAt: nullable(str({ format: 'date-time' })),
    user: ref('PersonCard'),
  }),
  ConnectionItem: { allOf: [ref('PersonCard'), obj({ connectedAt: str({ format: 'date-time' }), isNew: bool })] },
  InboxSummary: obj({
    requests: obj({ received: int(), sent: int() }),
    connections: obj({ total: int(), new: int() }),
    messages: obj({ unread: int() }),
    showBadge: bool,
  }),
  ChatMessage: obj({ id: int(), conversationId: int(), senderId: int(), body: str(), clientId: nullable(str()), createdAt: str({ format: 'date-time' }), isMine: bool }),
  Chat: obj({
    id: int(),
    user: ref('PersonCard'),
    lastMessage: nullable(ref('ChatMessage')),
    lastMessageAt: nullable(str({ format: 'date-time' })),
    unreadCount: int(),
    myLastReadId: int(),
    otherLastReadId: int({ description: 'Messages of mine with id ≤ this were read by the other member (✓✓)' }),
    canSend: { type: 'boolean', description: 'false once the connection is removed (history stays readable)' },
  }),
  MasterItem: obj({ id: int(), name: str(), isActive: bool, sortOrder: int(), usageCount: int(), createdAt: str(), updatedAt: str() }),
  Verification: obj({ id: int(), status: str({ enum: ['pending', 'verified', 'rejected'] }), reason: nullable(str()), createdAt: str(), reviewedAt: nullable(str()) }),
};

// Edit Profile body: every section optional, at least one.
schemas.EditProfile = {
  type: 'object',
  description: 'Send only the sections you changed. Each section replaces that part of the profile (same rules as onboarding). All-or-nothing.',
  properties: Object.fromEntries(Object.entries(SECTIONS).map(([k, s]) => [k, fromZod(s.schema)])),
  minProperties: 1,
  additionalProperties: false,
};

// ─── Paths ─────────────────────────────────────────────────────────────
const P = {};
const add = (path, method, operation) => {
  P[path] = P[path] || {};
  P[path][method] = operation;
};
const T = {
  config: 'App · Config',
  auth: 'App · Auth',
  me: 'App · My profile',
  meta: 'App · Master data',
  onb: 'App · Onboarding',
  ver: 'App · Verification',
  kyn: 'App · KYN & Filters',
  mem: 'App · Members',
  net: 'App · Connections & Inbox',
  notif: 'App · Notifications & realtime',
  chat: 'App · Chat',
  match: 'App · SyyncMatch',
  aAuth: 'Admin · Auth',
  aDash: 'Admin · Dashboard',
  aVer: 'Admin · Verifications',
  aUsers: 'Admin · Users',
  aOpt: 'Admin · Mindset options',
  aNet: 'Admin · Networking',
};

// Config & auth
add('/app/config', 'get', op(T.config, 'App configuration (read on Splash)', { auth: null, description: 'Terms/privacy URLs, OTP timing, validation rules and enum values the app should use.' }));
add('/auth/otp/request', 'post', op(T.auth, 'Request an OTP (phone or email)', {
  auth: null,
  body: obj({ identifier: str({ description: '10-digit Indian mobile, E.164 phone or email' }), termsAccepted: { const: true } }, ['identifier', 'termsAccepted']),
  bodyExample: { identifier: '9812345210', termsAccepted: true },
  data: obj({ requestId: str({ format: 'uuid' }), maskedDestination: str(), channel: str({ enum: ['sms', 'email'] }), expiresIn: int(), resendAfter: int(), devCode: str({ description: 'Mock provider only, never in production' }) }),
  errors: ['400 VALIDATION_ERROR / INVALID_IDENTIFIER', '429 OTP_RATE_LIMITED'],
}));
add('/auth/otp/resend', 'post', op(T.auth, 'Resend the OTP', { auth: null, body: obj({ requestId: str({ format: 'uuid' }) }, ['requestId']), errors: ['404 OTP_NOT_FOUND', '429 OTP_RESEND_TOO_SOON'] }));
add('/auth/otp/verify', 'post', op(T.auth, 'Verify OTP → tokens', {
  auth: null,
  body: obj({ requestId: str({ format: 'uuid' }), code: str({ pattern: '^\\d{6}$' }) }, ['requestId', 'code']),
  data: ref('Tokens'),
  errors: ['400 OTP_INVALID (details.remainingAttempts) / OTP_EXPIRED', '404 OTP_NOT_FOUND (used or unknown)', '429 OTP_TOO_MANY_ATTEMPTS'],
}));
add('/auth/social', 'post', op(T.auth, 'Sign in with Google / LinkedIn / Apple', {
  auth: null,
  body: obj({ provider: str({ enum: ['google', 'linkedin', 'apple'] }), idToken: str({ description: 'Mock mode: "mock:<uid>:<email>"' }), termsAccepted: { const: true } }, ['provider', 'idToken', 'termsAccepted']),
  data: ref('Tokens'),
  errors: ['401 SOCIAL_TOKEN_INVALID', '501 SOCIAL_NOT_CONFIGURED'],
}));
add('/auth/refresh', 'post', op(T.auth, 'Refresh tokens (rotates the refresh token)', { auth: null, body: obj({ refreshToken: str() }, ['refreshToken']), data: ref('Tokens'), errors: ['401 REFRESH_INVALID'] }));
add('/auth/logout', 'post', op(T.auth, 'Log out (revokes the refresh token)', { auth: null, body: obj({ refreshToken: str() }, ['refreshToken']) }));

// Me
add('/me', 'get', op(T.me, 'My profile (Splash routes on onboarding.step)', { data: ref('Profile'), errors: ['403 ACCOUNT_BLOCKED'] }));
add('/me/profile', 'put', op(T.me, 'Edit Profile — update any sections at once', {
  description: 'Used by Edit Profile (Personal · Work · Interests · Discovery). Only after onboarding is complete.',
  body: ref('EditProfile'),
  bodyExample: {
    basic: { fullName: 'Krupa Shah', dob: '1996-06-12', gender: 'woman', linkedinUrl: 'https://linkedin.com/in/krupashah', about: 'I enjoy designing intuitive digital experiences.' },
    work: { jobTitle: 'UI/UX Designer', industryId: 2, company: 'Independent Designer', experienceLevelId: 3, skillIds: [1, 17] },
    interests: { interestIds: [1, 3, 4, 11], reasonIds: [1, 2, 3] },
    community: { cityId: 1, localityId: 1, connectMode: 'both', radiusKm: 25, availability: ['weekends', 'evenings'], nearbyDiscovery: true, openToConnect: true },
  },
  data: ref('Profile'),
  errors: ['409 ONBOARDING_INCOMPLETE', '400 VALIDATION_ERROR / INVALID_SELECTION / MIN_INTERESTS / REASONS_RANGE / TOO_MANY_SKILLS / AGE_RESTRICTED'],
}));
add('/me/settings', 'patch', op(T.me, 'Quick toggles: open to connect · nearby discovery', {
  body: fromZod(SECTIONS.settings.schema),
  bodyExample: { openToConnect: false },
  data: obj({ openToConnect: bool, nearbyDiscovery: bool }),
}));
add('/me/photo', 'post', op(T.me, 'Upload profile photo', { multipart: 'photo', data: obj({ photoUrl: str() }), errors: ['400 FILE_REQUIRED', '413 UPLOAD_ERROR', '415 UNSUPPORTED_FILE'] }));
add('/me/photo', 'delete', op(T.me, 'Remove profile photo', { data: obj({ photoUrl: { type: 'null' } }) }));
add('/me/saved', 'get', op(T.me, 'Bookmarked members', { params: pageParams, data: arr(ref('PersonCard')), paged: true, errors: ['403 PROFILE_INCOMPLETE'] }));

// Meta
const metaList = (path, summary, params = []) => add(path, 'get', op(T.meta, summary, { auth: null, params, data: arr({ type: 'object' }) }));
metaList('/meta/industries', 'Industries (active, admin order)');
metaList('/meta/experience-levels', 'Experience levels');
metaList('/meta/interests', 'Interests');
metaList('/meta/reasons', '"I\'m here to…" reasons');
metaList('/meta/mindset-questions', 'Mindset questions with options');
metaList('/meta/skills', 'Search skills', [q('q', str()), q('industryId', int())]);
metaList('/meta/cities', 'Search cities', [q('q', str())]);
metaList('/meta/localities', 'Localities of a city', [q('cityId', int(), 'Required', { required: true }), q('q', str())]);

// Onboarding
add('/onboarding/status', 'get', op(T.onb, 'Saved answers (resume setup)', { data: ref('Profile') }));
const onb = [
  ['basic', 'Step 1 · About you'],
  ['work', 'Step 2 · Your work'],
  ['interests', 'Step 3 · Interests + reasons'],
  ['mindset', 'Step 4 · Your mindset (all questions optional; send only answered ones)'],
  ['community', 'Step 5 · Your community'],
];
for (const [name, summary] of onb) {
  add(`/onboarding/${name}`, 'put', op(T.onb, summary, { body: fromZod(SECTIONS[name].schema), data: ref('Profile'), errors: ['409 STEP_LOCKED', '400 VALIDATION_ERROR'] }));
}

// Verification
add('/verification/selfie', 'post', op(T.ver, 'Submit selfie (step 6)', { multipart: 'selfie', status: 201, data: ref('Verification'), errors: ['400 FILE_REQUIRED', '409 STEP_LOCKED / ALREADY_VERIFIED', '415 UNSUPPORTED_FILE'] }));
add('/verification/latest', 'get', op(T.ver, 'Latest verification status', { data: ref('Verification') }));
add('/verification/{id}', 'get', op(T.ver, 'One verification', { params: [pathId()], data: ref('Verification'), errors: ['404 NOT_FOUND'] }));

// KYN & Filters
add('/discover', 'get', op(T.kyn, 'KYN Home — people near you', {
  description: [
    'Members with a finished profile who have **nearby discovery** on, excluding you.',
    'Defaults: your city, your discovery radius (or 25 km), nearest first.',
    '`quick`: **nearby** ≤ 2 km · **professionals** = same industry as you · **similar** = shares ≥ 1 interest.',
    'For **“Show N people”** on Filters call with the same filters and `limit=1`, then read `meta.total`.',
  ].join('\n\n'),
  params: [
    q('search', str({ maxLength: 60 }), 'Name, role, company, interest or skill'),
    q('quick', str({ enum: ['all', 'nearby', 'professionals', 'similar'], default: 'all' })),
    q('industryId', int(), 'Profession'),
    q('interestIds', str(), 'Comma-separated, e.g. 1,4,11 (matches any)'),
    q('experienceLevelId', int()),
    q('cityId', int(), 'Defaults to your city'),
    q('maxDistanceKm', { type: 'number', minimum: 1, maximum: 100 }, 'Defaults to your radius'),
    q('sort', str({ enum: ['nearest', 'name', 'newest'], default: 'nearest' })),
    q('verifiedOnly', bool),
    ...pageParams,
  ],
  data: arr(ref('PersonCard')),
  paged: true,
  errors: ['403 PROFILE_INCOMPLETE'],
}));
add('/discover/filters', 'get', op(T.kyn, 'Filters screen options + defaults', {
  data: obj({
    professions: arr(obj({ id: int(), name: str() })),
    interests: arr(obj({ id: int(), name: str() })),
    experienceLevels: arr(obj({ id: int(), label: str() })),
    cities: arr(obj({ id: int(), name: str(), state: str() })),
    distance: obj({ minKm: int(), maxKm: int(), stepKm: int(), defaultKm: int() }),
    quickFilters: arr(obj({ value: str(), label: str(), hint: str() })),
    sortOptions: arr(obj({ value: str(), label: str() })),
    defaults: { type: 'object' },
  }),
}));

// Members
add('/users/{id}', 'get', op(T.mem, 'Professional Profile of a member', { params: [pathId()], data: ref('PersonDetail'), errors: ['403 PROFILE_INCOMPLETE', '404 NOT_FOUND'] }));
add('/users/{id}/icebreakers', 'get', op(T.mem, 'Message suggestions for a connection request', {
  params: [pathId()],
  data: obj({ maxLength: int(), suggestions: arr(str()) }),
  example: { maxLength: 300, suggestions: ["Hi Krupa, I'd love to connect and exchange ideas.", 'We share an interest in Design and Startups. It would be great to connect.', "I'm new to the area and would love to meet more professionals."] },
}));
add('/users/{id}/save', 'put', op(T.mem, 'Bookmark a member', { params: [pathId()], data: obj({ userId: int(), isSaved: bool }), errors: ['400 CANNOT_SAVE_SELF', '404 NOT_FOUND'] }));
add('/users/{id}/save', 'delete', op(T.mem, 'Remove bookmark', { params: [pathId()], data: obj({ userId: int(), isSaved: bool }) }));

// Connections & Inbox
add('/connections/requests', 'post', op(T.net, 'Send a connection request', {
  body: obj({ userId: int(), message: nullable(str({ maxLength: env.rules.requestMessageMax })) }, ['userId']),
  bodyExample: { userId: 1, message: "Hi Krupa, I'd love to connect and exchange ideas." },
  status: 201,
  data: ref('ConnectionRequest'),
  errors: [
    '400 CANNOT_CONNECT_SELF',
    '403 NOT_ACCEPTING_REQUESTS',
    '404 NOT_FOUND',
    '409 ALREADY_CONNECTED / REQUEST_ALREADY_SENT / REQUEST_RECEIVED (details.requestId — accept it instead)',
    `429 DAILY_REQUEST_LIMIT (${env.rules.maxRequestsPerDay}/day)`,
  ],
}));
add('/connections/requests', 'get', op(T.net, 'Inbox › Requests (received / sent)', {
  params: [q('direction', str({ enum: ['received', 'sent'], default: 'received' })), q('status', str({ enum: ['pending', 'all'], default: 'pending' })), ...pageParams],
  data: arr(ref('ConnectionRequest')),
  paged: true,
}));
add('/connections/requests/{id}/accept', 'post', op(T.net, 'Accept a received request', { params: [pathId()], data: ref('ConnectionRequest'), errors: ['404 NOT_FOUND', '409 REQUEST_CLOSED'] }));
add('/connections/requests/{id}/decline', 'post', op(T.net, 'Decline a received request', { params: [pathId()], errors: ['404 NOT_FOUND', '409 REQUEST_CLOSED'] }));
add('/connections/requests/{id}', 'delete', op(T.net, 'Withdraw a sent request', { params: [pathId()], errors: ['404 NOT_FOUND', '409 REQUEST_CLOSED'] }));
add('/connections', 'get', op(T.net, 'Inbox › My Connections', {
  params: [q('search', str({ maxLength: 60 }), 'Name, role or company'), ...pageParams],
  data: arr(ref('ConnectionItem')),
  paged: true,
  description: `\`isNew\` is true for ${env.rules.newConnectionDays} days after connecting (the "New" tag).`,
}));
add('/connections/{id}', 'delete', op(T.net, 'Remove a connection', { params: [pathId('id', 'The other member\'s user id')], errors: ['404 NOT_FOUND'] }));
add('/inbox/summary', 'get', op(T.net, 'Inbox badge counts', { data: ref('InboxSummary') }));

// SyyncMatch
const matchItem = obj({
  user_id: int(),
  match_score: int({ minimum: 0, maximum: 100, description: 'SyyncScore' }),
  match_level: str({ enum: ['excellent', 'strong', 'potential', 'low', 'insufficient'] }),
  match_label: str({ example: 'Strong Match' }),
  match_reasons: arr(str({ example: 'Shared Skills' })),
  score_breakdown: { type: 'object', additionalProperties: int(), description: 'Points per factor; adds up to match_score' },
  insufficient_data: bool,
  user: ref('PersonCard'),
});
const matchPage = obj({ matches: arr(matchItem), pagination: obj({ page: int(), limit: int(), total: int(), has_more: bool }), algorithm_version: str() });
add('/matches', 'get', op(T.match, 'KYN recommendations ranked by SyyncScore', {
  description: 'Weights: skills 30% · intent 25% · interests 20% · location 15% · professional 10%. Excludes you, hidden / blocked / not-open-to-connect members, existing connections and open requests. Levels: 85+ excellent · 70+ strong · 50+ potential · else low; `insufficient` when less than 60% of the factors are known. Every /discover card and /users/{id} also carries `match`. Default /discover sort is `match`.',
  params: [q('cityId', int()), q('maxDistanceKm', int({ minimum: 1, maximum: 100 })), q('page', int({ minimum: 1, default: 1 })), q('limit', int({ minimum: 1, maximum: 50, default: 20 }))],
  data: matchPage,
  message: 'Professional matches fetched successfully.',
}));
add('/seek/matches', 'get', op(T.match, 'Seek: people with a specific expertise, ranked', {
  description: 'Weights: required expertise 45% · intent 25% · experience & industry 15% · location 10% · shared interests 5%. Needs skillIds or q.',
  params: [
    q('skillIds', str(), 'Comma-separated skill ids'), q('q', str({ maxLength: 80 }), 'Keywords (job title / skill names)'),
    q('intentIds', str(), 'Comma-separated reason ids'), q('industryId', int()), q('experienceLevelId', int(), 'Minimum experience'),
    q('cityId', int()), q('maxDistanceKm', int({ minimum: 1, maximum: 500 })), q('page', int({ minimum: 1, default: 1 })), q('limit', int({ minimum: 1, maximum: 50, default: 20 })),
  ],
  data: matchPage,
  errors: ['400 SEEK_QUERY_REQUIRED'],
}));

// Chat (1:1, connections only)
add('/chats', 'get', op(T.chat, 'Inbox › Messages (latest first)', {
  params: [q('search', str({ maxLength: 60 }), 'Member name'), ...pageParams],
  data: arr(ref('Chat')),
  paged: true,
  description: 'Only chats that have at least one message. `data.totalUnread` = badge count. Live updates: socket events `message:new`, `message:read`, `chat:read`, `typing`.',
}));
add('/chats', 'post', op(T.chat, 'Open the chat with a connection', { body: obj({ userId: int() }, ['userId']), bodyExample: { userId: 2 }, data: ref('Chat'), errors: ['400 CANNOT_CHAT_SELF', '403 NOT_CONNECTED'] }));
add('/chats/{id}', 'get', op(T.chat, 'One chat', { params: [pathId()], data: ref('Chat'), errors: ['404 NOT_FOUND'] }));
add('/chats/{id}/messages', 'get', op(T.chat, 'Messages (oldest → newest in the page)', {
  params: [pathId(), q('before', int(), 'Load older: messages with id < before'), q('after', int(), 'Catch up: messages with id > after'), q('limit', int({ minimum: 1, maximum: 100, default: 30 }))],
  data: obj({ items: arr(ref('ChatMessage')), hasMore: bool, otherLastReadId: int(), canSend: bool }),
  errors: ['404 NOT_FOUND'],
}));
add('/chats/{id}/messages', 'post', op(T.chat, 'Send a text message', {
  params: [pathId()],
  body: obj({ body: str({ minLength: 1, maxLength: env.rules.messageMax }), clientId: nullable(str({ maxLength: 64, description: 'Random id per message; a retried send with the same id is stored once (200 instead of 201)' })) }, ['body']),
  bodyExample: { body: 'Hi! Coffee this week?', clientId: 'a1b2c3' },
  status: 201,
  data: ref('ChatMessage'),
  errors: ['400 VALIDATION_ERROR', '403 NOT_CONNECTED', '404 NOT_FOUND'],
}));
add('/chats/{id}/read', 'post', op(T.chat, 'Mark as read (up to messageId, default latest)', {
  params: [pathId()],
  body: obj({ messageId: int() }),
  data: obj({ conversationId: int(), lastReadId: int(), unreadCount: int(), totalUnread: int() }),
  errors: ['404 NOT_FOUND'],
}));

// Admin
add('/admin/auth/login', 'post', op(T.aAuth, 'Admin login', { auth: null, body: obj({ email: str({ format: 'email' }), password: str() }, ['email', 'password']), bodyExample: { email: 'admin@syyncin.app', password: 'Admin#12345' }, errors: ['401 INVALID_CREDENTIALS'] }));
add('/admin/auth/refresh', 'post', op(T.aAuth, 'Refresh admin tokens', { auth: null, body: obj({ refreshToken: str() }, ['refreshToken']) }));
add('/admin/auth/logout', 'post', op(T.aAuth, 'Admin logout', { auth: null, body: obj({ refreshToken: str() }, ['refreshToken']) }));
add('/admin/auth/me', 'get', op(T.aAuth, 'Current admin', { auth: 'admin' }));
add('/admin/stats', 'get', op(T.aDash, 'Dashboard: users, funnel, sign-ups, top interests, networking', { auth: 'admin' }));

for (const [type, def] of Object.entries(TYPES)) {
  const label = def.label === 'Question' ? 'Mindset question' : def.label;
  const tag = `Admin · ${label === 'Mindset question' ? 'Mindset questions' : `${label}s`.replace(/ys$/, 'ies')}`;
  const fields = Object.fromEntries(Object.entries(def.fields).map(([k, f]) => [k, f.schema]));
  const createSchema = z.object({ ...fields, ...(def.createExtra || {}) });
  const extraFilter = type === 'skills' ? [q('industryId', int())] : type === 'localities' ? [q('cityId', int())] : [];
  add(`/admin/${type}`, 'get', op(tag, `List ${type}`, {
    auth: 'admin',
    params: [q('search', str()), q('status', str({ enum: ['active', 'inactive', 'all'], default: 'all' })), ...extraFilter, ...pageParams],
    data: arr(ref('MasterItem')),
    paged: true,
  }));
  add(`/admin/${type}`, 'post', op(tag, `Create ${label.toLowerCase()}`, { auth: 'admin', body: fromZod(createSchema), status: 201, errors: ['409 DUPLICATE', '400 VALIDATION_ERROR'] }));
  add(`/admin/${type}/reorder`, 'patch', op(tag, 'Reorder (app display order)', { auth: 'admin', body: obj({ ids: arr(int()) }, ['ids']), errors: ['400 VALIDATION_ERROR'] }));
  add(`/admin/${type}/{id}`, 'get', op(tag, `Get one ${label.toLowerCase()}`, { auth: 'admin', params: [pathId()], errors: ['404 NOT_FOUND'] }));
  add(`/admin/${type}/{id}`, 'put', op(tag, `Update ${label.toLowerCase()} (partial)`, { auth: 'admin', params: [pathId()], body: fromZod(z.object(fields).partial()), errors: ['404 NOT_FOUND', '409 DUPLICATE'] }));
  add(`/admin/${type}/{id}/status`, 'patch', op(tag, 'Activate / deactivate', { auth: 'admin', params: [pathId()], body: obj({ isActive: bool }, ['isActive']) }));
  add(`/admin/${type}/{id}`, 'delete', op(tag, 'Delete (deactivates instead if in use)', {
    auth: 'admin',
    params: [pathId()],
    data: obj({ deleted: bool, deactivated: bool, usageCount: int() }),
  }));
}
add('/admin/mindset-questions/{id}/options', 'post', op(T.aOpt, 'Add an option to a question', { auth: 'admin', params: [pathId()], body: obj({ label: str({ maxLength: 60 }) }, ['label']), status: 201, errors: ['404 NOT_FOUND'] }));
add('/admin/mindset-options/{id}', 'put', op(T.aOpt, 'Update option', { auth: 'admin', params: [pathId()], body: obj({ label: str(), isActive: bool, sortOrder: int() }) }));
add('/admin/mindset-options/{id}', 'delete', op(T.aOpt, 'Delete option (deactivates if answered)', { auth: 'admin', params: [pathId()] }));

add('/admin/verifications', 'get', op(T.aVer, 'Verification queue', { auth: 'admin', params: [q('status', str({ enum: ['pending', 'verified', 'rejected', 'all'], default: 'pending' })), q('search', str()), ...pageParams], paged: true }));
add('/admin/verifications/{id}', 'get', op(T.aVer, 'Verification detail', { auth: 'admin', params: [pathId()] }));
add('/admin/verifications/{id}/selfie', 'get', op(T.aVer, 'Selfie image (admin only)', { auth: 'admin', params: [pathId()], raw: { type: 'image/*', description: 'The selfie image' } }));
add('/admin/verifications/{id}', 'patch', op(T.aVer, 'Approve / reject', {
  auth: 'admin',
  params: [pathId()],
  body: obj({ action: str({ enum: ['approve', 'reject'] }), reason: str({ description: 'Required to reject' }) }, ['action']),
  errors: ['409 ALREADY_REVIEWED', '400 VALIDATION_ERROR'],
}));
add('/admin/users', 'get', op(T.aUsers, 'Users', {
  auth: 'admin',
  params: [
    q('search', str()),
    q('status', str({ enum: ['active', 'blocked', 'all'] })),
    q('verificationStatus', str({ enum: ['none', 'pending', 'verified', 'rejected'] })),
    q('onboarding', str({ enum: ['complete', 'incomplete'] })),
    q('cityId', int()),
    ...pageParams,
  ],
  paged: true,
}));
add('/admin/users/{id}', 'get', op(T.aUsers, 'User detail (profile, verifications, network summary)', { auth: 'admin', params: [pathId()] }));
add('/admin/users/{id}/status', 'patch', op(T.aUsers, 'Block / unblock (blocking revokes sessions)', { auth: 'admin', params: [pathId()], body: obj({ status: str({ enum: ['active', 'blocked'] }) }, ['status']) }));

schemas.Notification = obj({
  id: int(),
  type: str({ enum: ['connection_request.received', 'connection_request.accepted'] }),
  title: str({ example: 'New connection request' }),
  body: str({ example: 'Aarav Mehta: “Hi, I’d love to connect.”' }),
  data: obj({ requestId: int(), userId: int(), screen: str({ enum: ['inbox.requests.received', 'inbox.connections'], description: 'Where tapping the notification should go' }) }),
  actor: nullable(obj({ id: int(), fullName: nullable(str()), photoUrl: nullable(str()) })),
  isRead: bool,
  readAt: nullable(str({ format: 'date-time' })),
  createdAt: str({ format: 'date-time' }),
});
add('/notifications', 'get', op(T.notif, 'Notification list (bell)', {
  description: 'Everything that arrived while the app was closed. `data.unreadCount` is included. Live delivery while the app is open happens over Socket.IO — see the API description at the top.',
  params: [q('unreadOnly', bool), ...pageParams],
  data: arr(ref('Notification')),
  paged: true,
}));
add('/notifications/unread-count', 'get', op(T.notif, 'Unread notification count', { data: obj({ unreadCount: int() }) }));
add('/notifications/read-all', 'patch', op(T.notif, 'Mark all as read', { data: obj({ updated: int(), unreadCount: int() }) }));
add('/notifications/{id}/read', 'patch', op(T.notif, 'Mark one as read', { params: [pathId()], data: obj({ id: int(), isRead: bool, unreadCount: int() }), errors: ['404 NOT_FOUND'] }));
add('/notifications/{id}', 'delete', op(T.notif, 'Remove a notification', { params: [pathId()], data: obj({ id: int(), deleted: bool, unreadCount: int() }), errors: ['404 NOT_FOUND'] }));

const adminMember = obj({ id: int(), fullName: nullable(str()), jobTitle: nullable(str()), photoUrl: nullable(str()), status: str({ enum: ['active', 'blocked'] }) });
add('/admin/connection-requests', 'get', op(T.aNet, 'All connection requests', {
  auth: 'admin',
  params: [q('status', str({ enum: ['pending', 'accepted', 'declined', 'withdrawn', 'all'], default: 'all' })), q('search', str(), 'Sender/receiver name or phone, or message text'), q('userId', int(), 'Only requests sent or received by this member'), ...pageParams],
  data: arr(obj({ id: int(), status: str(), message: nullable(str()), createdAt: str(), respondedAt: nullable(str()), sender: adminMember, receiver: adminMember })),
  paged: true,
}));
add('/admin/connection-requests/{id}/cancel', 'patch', op(T.aNet, 'Cancel a pending request (moderation)', { auth: 'admin', params: [pathId()], errors: ['404 NOT_FOUND', '409 REQUEST_CLOSED'] }));
add('/admin/connections', 'get', op(T.aNet, 'All connections', {
  auth: 'admin',
  params: [q('search', str(), 'Either member\'s name or phone'), q('userId', int(), 'Only this member\'s connections'), ...pageParams],
  data: arr(obj({ userA: adminMember, userB: adminMember, connectedAt: str(), requestId: nullable(int()) })),
  paged: true,
}));
add('/admin/connections/{userAId}/{userBId}', 'delete', op(T.aNet, 'Remove a connection (moderation)', { auth: 'admin', params: [pathId('userAId'), pathId('userBId')], errors: ['404 NOT_FOUND'] }));

const spec = {
  openapi: '3.1.0',
  info: {
    title: 'SyyncIn API',
    version: require('../../package.json').version,
    description: [
      'Backend for the SyyncIn app and admin panel.',
      '',
      '**How to try it:** run *App · Auth › Request OTP* (mock mode returns `devCode`), then *Verify OTP*, copy `accessToken` → **Authorize › userAuth**.',
      'For admin endpoints use *Admin · Auth › Admin login* → **Authorize › adminAuth**.',
      '',
      'Demo members (after `npm run db:demo`): log in as **+919000000001** (Krupa Shah) to see KYN, a pending request and two connections.',
      '',
      '**Every response** has the same shape (images excepted):',
      '```json',
      '{ "status": 1, "data": { }, "message": "Request completed successfully." }',
      '```',
      '- `status`: `1` success, `0` failure (validation, auth, not found, server error …) — the HTTP code is set too (200, 201, 400, 401, 403, 404, 409, 413, 415, 429, 500).',
      '- `data`: always an object. Lists → `{ items: [...], pagination: { page, limit, total, totalPages } }`. Failures → `{ code, errors?: [{ field, message }], … }`.',
      '- `message`: always a human-readable sentence you can show the user.',
      '',
      '### Realtime (while the app is open)',
      'Connect with Socket.IO to this host: `path: "/socket.io"`, `auth: { token: <accessToken> }` (transport `websocket`).',
      '',
      '| Event (server → app) | Payload | App should |',
      '|---|---|---|',
      '| `ready` | `{ userId, unreadCount, inbox }` | set the bell + Inbox badges |',
      '| `notification` | a **Notification** (see schema) | show a local notification; tap → `data.screen` |',
      '| `notification:removed` | `{ ids }` | drop those from the list (request withdrawn / cancelled) |',
      '| `inbox:updated` | `{ reason, inbox }` | refresh Inbox lists and badge silently |',
      '',
      'If the connection is refused, `err.message` is `TOKEN_INVALID` (refresh the token and reconnect), `ACCOUNT_BLOCKED` or `UNAUTHORIZED`. Blocked members are disconnected immediately.',
      'Anything that arrived while the app was closed is in `GET /notifications`. Push (FCM) will reuse the same notifications later.',
    ].join('\n'),
  },
  servers: [{ url: '/api/v1', description: 'This server' }],
  tags: Object.values(T).map((name) => ({ name })),
  components: {
    securitySchemes: {
      userAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', description: 'App user access token (15 min)' },
      adminAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', description: 'Admin access token' },
    },
    schemas,
  },
  paths: P,
};

// Keep admin master-data tags after the hand-written ones, in TYPES order.
const seen = new Set(spec.tags.map((t) => t.name));
for (const opMap of Object.values(P)) for (const o of Object.values(opMap)) for (const t of o.tags) if (!seen.has(t)) { seen.add(t); spec.tags.push({ name: t }); }

module.exports = spec;
