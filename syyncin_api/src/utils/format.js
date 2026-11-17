const env = require('../config/env');

/** "+919812345210" → "+91 98•••••210", "nikunj@gmail.com" → "ni•••@gmail.com" */
function maskDestination(identifier, channel) {
  if (channel === 'email') {
    const [name, domain] = identifier.split('@');
    return `${name.slice(0, 2)}•••@${domain}`;
  }
  const digits = identifier.replace(/\D/g, '');
  const local = digits.slice(-10);
  const cc = digits.length > 10 ? digits.slice(0, digits.length - 10) : '91';
  return `+${cc} ${local.slice(0, 2)}•••••${local.slice(-3)}`;
}

/** Normalise a phone/email identifier. Returns { identifier, channel } or null. */
function parseIdentifier(raw) {
  const v = String(raw || '').trim();
  if (/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v)) return { identifier: v.toLowerCase(), channel: 'email' };
  const digits = v.replace(/[\s\-()]/g, '');
  if (/^\+?\d{10,15}$/.test(digits)) {
    const d = digits.replace(/^\+/, '');
    const e164 = d.length === 10 ? `+91${d}` : `+${d}`; // default country code: India
    return { identifier: e164, channel: 'sms' };
  }
  return null;
}

function ageOn(dobIso, today = new Date()) {
  const dob = new Date(`${dobIso}T00:00:00Z`);
  let age = today.getUTCFullYear() - dob.getUTCFullYear();
  const m = today.getUTCMonth() - dob.getUTCMonth();
  if (m < 0 || (m === 0 && today.getUTCDate() < dob.getUTCDate())) age--;
  return age;
}

const fileUrl = (relPath) => (relPath ? `${env.publicBaseUrl}/${relPath.replace(/^\/+/, '')}` : null);

/** snake_case DB row → camelCase API object (shallow). */
function camel(row) {
  if (!row) return row;
  const out = {};
  for (const [k, v] of Object.entries(row)) {
    const key = k.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    out[key] = k === 'is_active' || k === 'nearby_discovery' ? Boolean(v) : v;
  }
  return out;
}

module.exports = { maskDestination, parseIdentifier, ageOn, fileUrl, camel };
