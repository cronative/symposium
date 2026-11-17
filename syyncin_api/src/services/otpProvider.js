const env = require('../config/env');

/**
 * OTP delivery adapters. Default "mock" only logs the code.
 * Add real providers here (MSG91 / Twilio / AWS SES) without touching the routes.
 */
const providers = {
  async mock({ identifier, channel, code }) {
    console.log(`[OTP:mock] ${channel} → ${identifier}: ${code}`);
  },
  // async msg91({ identifier, code }) { ... },
  // async twilio({ identifier, code }) { ... },
};

async function sendOtp(payload) {
  const send = providers[env.otp.provider];
  if (!send) throw new Error(`OTP provider "${env.otp.provider}" is not configured`);
  await send(payload);
}

module.exports = { sendOtp, isMock: () => env.otp.provider === 'mock' };
