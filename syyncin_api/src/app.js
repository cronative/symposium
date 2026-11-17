const path = require('path');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { notFound, errorHandler } = require('./middleware');
const { ok } = require('./utils/http');

const app = express();
app.set('trust proxy', 1);
app.disable('x-powered-by');

// Swagger UI — mounted before helmet so its assets aren't blocked by the default CSP.
if (env.docs.enabled) {
  const swaggerUi = require('swagger-ui-express');
  const spec = require('./docs/openapi');
  app.get('/docs/openapi.json', (_req, res) => res.json(spec));
  app.use('/docs', swaggerUi.serve, swaggerUi.setup(spec, {
    customSiteTitle: 'SyyncIn API',
    customCss: '.swagger-ui .topbar{display:none} .swagger-ui .info{margin:24px 0}',
    swaggerOptions: { persistAuthorization: true, docExpansion: 'none', filter: true, tagsSorter: undefined, operationsSorter: undefined, displayRequestDuration: true, tryItOutEnabled: true },
  }));
  app.get('/', (_req, res) => res.redirect('/docs'));
}

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: env.corsOrigins.includes('*') ? true : env.corsOrigins }));
app.use(express.json({ limit: '100kb' }));
if (env.nodeEnv !== 'test') app.use(morgan(env.isProd ? 'combined' : 'dev'));

// Profile photos are public; selfies are NOT (admin-only route streams them).
app.use(`/${env.uploads.dir}/photos`, express.static(path.resolve(env.uploads.dir, 'photos'), { maxAge: '7d', index: false }));

app.get('/health', (_req, res) => ok(res, { uptime: Math.round(process.uptime()) }, 'Server is healthy.'));

const api = express.Router();

// SyyncMatch rankings are cached briefly; any successful profile / settings / network /
// admin change drops the cache so recommendations never lag behind.
const matchEngine = require('./services/match/engine');
api.use((req, res, next) => {
  if (req.method !== 'GET' && /^\/(me|onboarding|connections|admin|verification)\b/.test(req.path)) {
    res.on('finish', () => { if (res.statusCode < 400) matchEngine.bump(); });
  }
  next();
});
const authLimiter = rateLimit({ windowMs: 60_000, limit: env.isProd ? 30 : 1000, standardHeaders: 'draft-7', legacyHeaders: false });

api.use('/auth', authLimiter, require('./modules/auth/routes'));
api.use('/admin/auth/login', authLimiter);
api.use('/', require('./modules/app/routes'));
api.use('/meta', require('./modules/meta/routes'));
api.use('/onboarding', require('./modules/onboarding/routes'));
api.use('/verification', require('./modules/verification/routes'));
api.use('/', require('./modules/discover/routes'));
api.use('/', require('./modules/connections/routes'));
api.use('/', require('./modules/chat/routes'));
api.use('/', require('./modules/match/routes'));
api.use('/notifications', require('./modules/notifications/routes'));
api.use('/admin', require('./modules/admin/routes'));

app.use('/api/v1', api);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
