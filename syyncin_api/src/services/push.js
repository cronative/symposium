/**
 * Push notifications — placeholder until FCM/APNs is added.
 * notifications.create() already calls send() for every notification, so adding push later means:
 *   1. a `device_tokens` table + POST /me/devices to register FCM tokens from the app,
 *   2. implementing send() with firebase-admin (PUSH_PROVIDER=fcm).
 * Nothing else in the API has to change.
 */
const env = require('../config/env');

async function send(_userId, _notification) {
  if (env.push.provider === 'none') return { sent: false, reason: 'push not configured' };
  // TODO(fcm): look up device tokens for the user and call admin.messaging().sendEachForMulticast(...)
  return { sent: false, reason: `provider ${env.push.provider} not implemented yet` };
}

module.exports = { send };
