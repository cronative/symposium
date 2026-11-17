# SyyncIn API

Node.js + Express + MySQL backend for the SyyncIn app (onboarding → profile setup → selfie verification) and the admin panel.

**Tested:** `npm test` (= `check:responses` + `test:e2e`) exercises 116 endpoint/method combinations with 714 assertions — including the `{ status, data, message }` envelope on every single response — against a real MySQL-compatible database (MariaDB 10.11); all pass.

**API docs (Swagger):** start the server and open **http://localhost:4000/docs** — every app + admin endpoint (115) with request/response schemas, error codes and *Try it out*. Raw spec: `/docs/openapi.json` (import into Postman/Insomnia). Hide it on a public server with `DOCS_ENABLED=false`.

## Setup

```bash
npm install
cp .env.example .env                       # set DB_* and secrets
npm run db:migrate                         # creates DB, tables, seed data from the Figma screens (safe to re-run; adds new columns)
npm run db:demo                            # optional: 9 demo members for KYN / Inbox (log in as +919000000001 = Krupa Shah)
npm run admin:create -- --email admin@syyncin.app --password "Admin#12345" --name "Nik" --role super_admin
npm run dev                                # http://localhost:4000/api/v1
```

Postman: import `postman/SyyncIn.postman_collection.json` (120 requests). Run **App › Auth › Request OTP → Verify OTP** and **Admin › Auth › Login**; tokens and the mock OTP are saved to collection variables automatically.

## Conventions

- Base URL `/api/v1`, JSON, `Authorization: Bearer <accessToken>`.
- **Every response** (success or failure) has exactly this shape — the only exception is the admin selfie image:

  ```json
  { "status": 1, "data": {}, "message": "Request completed successfully." }
  ```

  | Field | Rule |
  |---|---|
  | `status` | `1` success · `0` any failure (validation, auth, not found, conflict, server error) |
  | `data` | Always an object. Lists → `{ "items": [...], "pagination": { "page", "limit", "total", "totalPages" } }`. Failures → `{ "code": "VALIDATION_ERROR", "errors": [{ "field", "message" }] }` (+ context such as `requestId`, `remainingAttempts`, `currentStep`) |
  | `message` | Always a human-readable sentence — show it to the user |

  HTTP codes are set as well: `200` OK · `201` created · `400` validation/bad request · `401` not signed in / token expired · `403` blocked / not allowed / profile incomplete · `404` not found · `409` conflict (duplicate, already connected, step locked) · `413` file too large · `415` wrong file type · `429` rate limited · `500` server error. Branch on `data.code`, not on the text.

  **Adding an endpoint:** respond with `ok(res, data, 'Message.')`, `created(res, data, 'Message.')` or `okList(res, items, paging, total, 'Message.')` from `src/utils/http.js`, and throw `ApiError` / `errors.*` for failures — the error middleware formats them. `npm run check:responses` fails if a route writes `res.json()` directly, and the e2e test checks the envelope on every response.
- Access token 15 min; refresh token 30 days, **rotated on every refresh** (old one stops working).

## App APIs

| Method | Path | Notes |
|---|---|---|
| GET | `/app/config` | Terms/Privacy URLs, OTP timings, rules (min age, min interests …) |
| POST | `/auth/otp/request` | `{identifier, termsAccepted:true}` → `requestId, maskedDestination, expiresIn, resendAfter` (+`devCode` in mock mode) |
| POST | `/auth/otp/resend` | `{requestId}` (after 30 s) |
| POST | `/auth/otp/verify` | `{requestId, code}` → tokens + `user{isNew, onboardingStep, verificationStatus}` |
| POST | `/auth/social` | `{provider: google\|linkedin\|apple, idToken, termsAccepted:true}` |
| POST | `/auth/refresh` · `/auth/logout` | `{refreshToken}` |
| GET | `/me` | Full profile + `onboarding.step` (Splash routes on this) |
| POST/DELETE | `/me/photo` | multipart `photo` (jpg/png/webp ≤ 5 MB) |
| GET | `/meta/industries` · `/meta/experience-levels` · `/meta/interests` · `/meta/reasons` · `/meta/mindset-questions` | Active items in admin order |
| GET | `/meta/skills?q=&industryId=` · `/meta/cities?q=` · `/meta/localities?cityId=&q=` | Search |
| GET | `/onboarding/status` | Saved answers for resume |
| PUT | `/onboarding/basic` | `{fullName, dob?, linkedinUrl?, gender?}` — age ≥ `MIN_AGE` if dob given |
| PUT | `/onboarding/work` | `{jobTitle, industryId, company?, experienceLevelId, skillIds[≤5]}` |
| PUT | `/onboarding/interests` | `{interestIds[≥3], reasonIds[1–3]}` |
| PUT | `/onboarding/mindset` | `{answers:[{questionId, optionId}]}` — every active question |
| PUT | `/onboarding/community` | `{cityId, localityId?, lat?, lng?, connectMode, radiusKm(5/10/25/50), availability[], nearbyDiscovery}` |
| POST | `/verification/selfie` | multipart `selfie` → `pending` (or `verified` if `AUTO_APPROVE_SELFIE=true`) |
| GET | `/verification/latest` · `/verification/:id` | Status polling |

### KYN, members, connections, edit profile (need a finished profile → else `403 PROFILE_INCOMPLETE`)

| Method | Path | Notes |
|---|---|---|
| GET | `/discover` | KYN Home. `search`, `quick=all\|nearby\|professionals\|similar`, `industryId`, `interestIds=1,4`, `experienceLevelId`, `cityId`, `maxDistanceKm`, `sort=nearest\|name\|newest`, `verifiedOnly`, paging. Defaults: your city + radius. "Show N people" = same query with `limit=1` → `meta.total` |
| GET | `/discover/filters` | Everything the Filters screen needs + defaults |
| GET | `/users/:id` | Professional Profile (skills, intent, mindset with `shared` flags; LinkedIn only once connected) |
| GET | `/users/:id/icebreakers` | 3 message suggestions for Send Connection Request |
| PUT · DELETE | `/users/:id/save` | Bookmark · `GET /me/saved` lists them |
| POST | `/connections/requests` | `{userId, message?≤300}` → 409 `ALREADY_CONNECTED` / `REQUEST_ALREADY_SENT` / `REQUEST_RECEIVED` (accept it instead), 403 `NOT_ACCEPTING_REQUESTS`, 429 `DAILY_REQUEST_LIMIT` |
| GET | `/connections/requests?direction=received\|sent&status=pending\|all` | Inbox › Requests |
| POST | `/connections/requests/:id/accept` · `/decline` | Receiver only |
| DELETE | `/connections/requests/:id` | Sender withdraws |
| GET · DELETE | `/connections` · `/connections/:userId` | My Connections (`isNew` for 3 days) · remove |
| GET | `/inbox/summary` | Badge counts |
| PUT | `/me/profile` | Edit Profile — any of `basic, work, interests, mindset, community, settings`; same rules as onboarding; all-or-nothing |
| PATCH | `/me/settings` | `{openToConnect?, nearbyDiscovery?}` |

### Notifications & realtime

| Method | Path | Notes |
|---|---|---|
| GET | `/notifications?unreadOnly=&page=` | Bell list (+ `data.unreadCount`) — whatever arrived while the app was closed |
| GET | `/notifications/unread-count` | |
| PATCH | `/notifications/:id/read` · `/notifications/read-all` | |
| DELETE | `/notifications/:id` | |

**Live while the app is open:** Socket.IO on the same host, `path: '/socket.io'`, `auth: { token: accessToken }`. Events: `ready {userId, unreadCount, inbox}` · `notification` (new request / request accepted → show a local notification, tap → `data.screen`) · `notification:removed {ids}` (request withdrawn or cancelled by admin) · `inbox:updated {reason, inbox}` (refresh lists + badge silently). Refused connections give `err.message = TOKEN_INVALID | ACCOUNT_BLOCKED | UNAUTHORIZED`; blocking a member disconnects them immediately. Declines are silent (no notification to the sender).
Push (FCM) later: implement `src/services/push.js` + device-token registration — every notification already passes through it.

Every card (KYN, profile, requests, connections, saved) has the same shape: `id, fullName, initials, photoUrl, jobTitle, company, industry, experienceLevel, city, locality, distanceKm, verified, openToConnect, interests, sharedInterests, isSaved, connection{status: none|pending_sent|pending_received|connected, requestId}`.
Distances use the member's pin (`lat/lng` from the community step) or their city centre.

Onboarding steps: `1 basic · 2 work · 3 interests · 4 mindset · 5 community · 6 selfie · 7 done`.
A step can only be saved once the user has reached it (`409 STEP_LOCKED`); re-saving an earlier step never moves progress back.

## Admin APIs

| Method | Path |
|---|---|
| POST | `/admin/auth/login` · `/admin/auth/refresh` · `/admin/auth/logout` |
| GET | `/admin/auth/me` |
| GET | `/admin/stats` — dashboard counts, onboarding funnel, sign-ups by day, top interests, networking (connections, requests, acceptance rate, requests by day) |

**Master data — same 7 endpoints for each type:**
`industries`, `experience-levels`, `skills`, `interests`, `reasons`, `cities`, `localities`, `mindset-questions`

| Method | Path | Notes |
|---|---|---|
| GET | `/admin/{type}?search=&status=active\|inactive\|all&page=&limit=` | + `industryId` (skills), `cityId` (localities) |
| GET | `/admin/{type}/:id` | mindset questions include `options` |
| POST | `/admin/{type}` | mindset questions accept `options: ["A","B",…]` |
| PUT | `/admin/{type}/:id` | partial update |
| PATCH | `/admin/{type}/:id/status` | `{isActive}` |
| PATCH | `/admin/{type}/reorder` | `{ids:[…]}` → order = app display order |
| DELETE | `/admin/{type}/:id` | **unused → deleted; in use → deactivated** (response says which) |

| Method | Path |
|---|---|
| POST | `/admin/mindset-questions/:id/options` |
| PUT · DELETE | `/admin/mindset-options/:id` |
| GET | `/admin/verifications?status=pending\|verified\|rejected\|all&search=` |
| GET | `/admin/verifications/:id` · `/admin/verifications/:id/selfie` (image, admin-only) |
| PATCH | `/admin/verifications/:id` `{action: approve\|reject, reason}` (reason required to reject) |
| GET | `/admin/users?search=&status=&verificationStatus=&onboarding=complete\|incomplete&cityId=` |
| GET | `/admin/connection-requests?status=pending\|accepted\|declined\|withdrawn\|all&search=&userId=` |
| PATCH | `/admin/connection-requests/:id/cancel` — moderation: removes a pending request from both Inboxes |
| GET | `/admin/connections?search=&userId=` |
| DELETE | `/admin/connections/:userAId/:userBId` — moderation: remove a connection |
| GET | `/admin/users/:id` |
| PATCH | `/admin/users/:id/status` `{status: active\|blocked}` — blocking signs the user out everywhere |

## Error codes the app should handle

`VALIDATION_ERROR` (400, `data.errors[]` per field) · `INVALID_IDENTIFIER` · `OTP_INVALID` (`remainingAttempts`) · `OTP_EXPIRED` · `OTP_TOO_MANY_ATTEMPTS` · `OTP_RESEND_TOO_SOON` (`retryAfter`) · `OTP_RATE_LIMITED` · `OTP_NOT_FOUND` · `TOKEN_INVALID` / `REFRESH_INVALID` (→ refresh or sign in) · `ACCOUNT_BLOCKED` · `STEP_LOCKED` · `AGE_RESTRICTED` · `MIN_INTERESTS` · `REASONS_RANGE` · `TOO_MANY_SKILLS` · `MINDSET_INCOMPLETE` · `INVALID_SELECTION` · `ALREADY_VERIFIED` · `UNSUPPORTED_FILE` · `UPLOAD_ERROR` · `DUPLICATE` (409) · `PROFILE_INCOMPLETE` · `ONBOARDING_INCOMPLETE` · `CANNOT_CONNECT_SELF` · `ALREADY_CONNECTED` · `REQUEST_ALREADY_SENT` · `REQUEST_RECEIVED` (`requestId`) · `REQUEST_CLOSED` · `NOT_ACCEPTING_REQUESTS` · `DAILY_REQUEST_LIMIT` · `NOT_FOUND` · `ROUTE_NOT_FOUND` · `INVALID_JSON` · `INTERNAL_ERROR` (500)

## Security notes

- OTP codes are HMAC-hashed, single-use, expire in 60 s, max 5 attempts, max 5 requests/hour per number/email.
- Refresh tokens are stored hashed; rotation on use; all revoked when a user is blocked.
- Selfies are stored outside the public folder and only streamed to authenticated admins.
- In production, set `NODE_ENV=production`, strong `JWT_ACCESS_SECRET` / `OTP_SECRET` (startup fails otherwise), and an OTP provider in `src/services/otpProvider.js`. `devCode` and mock social tokens are disabled in production.

## Plugging in real services

| What | Where |
|---|---|
| SMS / email OTP (MSG91, Twilio, SES) | `src/services/otpProvider.js` |
| Google / Apple / LinkedIn token verification | `verifySocialToken()` in `src/modules/auth/routes.js` |
| S3 instead of local disk | `imageUpload()` in `src/middleware/index.js` |
| Automated selfie check (Rekognition, HyperVerge) | `POST /verification/selfie` in `src/modules/verification/routes.js` |
