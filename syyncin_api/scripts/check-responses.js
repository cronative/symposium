/**
 * npm run check:responses — fails if any route writes a response without the shared helpers
 * (ok / created / okList / errors in src/utils/http.js), so every endpoint keeps the
 * { status, data, message } format. Binary/file routes are allowed explicitly below.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '../src');
const ALLOWED = [
  { file: 'app.js', pattern: /res\.json\(spec\)/ }, // raw OpenAPI document for Swagger UI
];
const FORBIDDEN = /\bres\s*\.\s*(json|send|end)\s*\(|\bres\s*\.\s*status\s*\(/;

const files = [];
(function walk(dir) {
  for (const f of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, f.name);
    if (f.isDirectory()) walk(p);
    else if (f.name.endsWith('.js') && !p.endsWith(path.join('utils', 'http.js'))) files.push(p);
  }
})(ROOT);

const problems = [];
for (const file of files) {
  fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
    if (!FORBIDDEN.test(line)) return;
    const rel = path.relative(ROOT, file);
    if (ALLOWED.some((a) => rel === a.file && a.pattern.test(line))) return;
    problems.push(`${rel}:${i + 1}  ${line.trim()}`);
  });
}

if (problems.length) {
  console.error('✗ Use ok() / created() / okList() from src/utils/http.js instead of writing responses directly:\n  ' + problems.join('\n  '));
  process.exit(1);
}
console.log(`✓ ${files.length} files — every response goes through the shared helper`);
