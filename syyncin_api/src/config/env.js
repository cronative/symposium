require('dotenv').config({ quiet: true });

const bool = (v, d) => (v === undefined ? d : ['1', 'true', 'yes'].includes(String(v).toLowerCase()));
const int = (v, d) => (v === undefined || v === '' ? d : parseInt(v, 10));

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: int(process.env.PORT, 4000),
  publicBaseUrl: process.env.PUBLIC_BASE_URL || `http://localhost:${int(process.env.PORT, 4000)}`,
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),

  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: int(process.env.DB_PORT, 3306),
    user: process.env.DB_USER || 'syyncin',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'syyncin',
    connectionLimit: int(process.env.DB_POOL, 10),
  },

  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret-change-me',
    accessTtl: process.env.JWT_ACCESS_TTL || '15m',
    refreshTtlDays: int(process.env.JWT_REFRESH_TTL_DAYS, 30),
  },

  otp: {
    provider: process.env.OTP_PROVIDER || 'mock', // mock | msg91 | twilio (add adapters in services/otpProvider.js)
    secret: process.env.OTP_SECRET || 'dev-otp-secret-change-me',
    length: 6,
    expirySeconds: int(process.env.OTP_EXPIRY_SECONDS, 60), // MoM: 1 minute
    resendSeconds: int(process.env.OTP_RESEND_SECONDS, 30),
    maxAttempts: int(process.env.OTP_MAX_ATTEMPTS, 5),
    maxRequestsPerHour: int(process.env.OTP_MAX_REQUESTS_PER_HOUR, 5),
    // Test login: every OTP becomes this code. On by default (123456) outside production;
    // set OTP_FIXED_CODE= (empty) to turn off, or set it explicitly to use it in production.
    fixedCode: process.env.OTP_FIXED_CODE !== undefined
      ? process.env.OTP_FIXED_CODE.trim()
      : (process.env.NODE_ENV === 'production' ? '' : '123456'),
    exposeDevCode: bool(process.env.OTP_EXPOSE_DEV_CODE, true), // returns code in response when provider=mock (never in production)
  },

  rules: {
    minAge: int(process.env.MIN_AGE, 25),
    minInterests: 3,
    maxReasons: 3,
    maxSkills: 5,
    radiusOptionsKm: [5, 10, 25, 50],
    maxRequestsPerDay: int(process.env.MAX_REQUESTS_PER_DAY, 30),
    requestMessageMax: 300,
    nearbyKm: 2, // KYN "Nearby" quick filter
    newConnectionDays: 3, // "New" badge on Inbox › Connections
    messageMax: 2000, // chat message length
  },

  uploads: {
    dir: process.env.UPLOAD_DIR || 'uploads',
    maxImageMb: int(process.env.MAX_IMAGE_MB, 5),
  },

  verification: {
    autoApprove: bool(process.env.AUTO_APPROVE_SELFIE, false), // demo switch; default = manual admin approval
  },

  push: {
    provider: process.env.PUSH_PROVIDER || 'none', // none | fcm (later)
  },

  docs: {
    enabled: bool(process.env.DOCS_ENABLED, true), // Swagger UI at /docs
  },

  app: {
    minVersion: process.env.APP_MIN_VERSION || '0.1.0',
    termsUrl: process.env.TERMS_URL || 'https://syyncin.app/terms',
    privacyUrl: process.env.PRIVACY_URL || 'https://syyncin.app/privacy',
  },
};

env.isProd = env.nodeEnv === 'production';

if (env.isProd) {
  for (const [k, v] of [['JWT_ACCESS_SECRET', env.jwt.accessSecret], ['OTP_SECRET', env.otp.secret]]) {
    if (v.startsWith('dev-')) throw new Error(`${k} must be set in production`);
  }
}

module.exports = env;
