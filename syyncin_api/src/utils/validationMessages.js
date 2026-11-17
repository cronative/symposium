/**
 * Turn zod's default issue text ("Invalid input: expected number, received NaN")
 * into something an app can show ("Industry id must be a number.").
 * Messages we wrote ourselves in the schemas are kept as they are.
 */
const DEFAULT_TEXT = /^(Invalid input|Invalid option|Invalid string|Invalid|Too small|Too big|Unrecognized key)/;

const NAMES = { dob: 'Date of birth', linkedinUrl: 'LinkedIn URL', radiusKm: 'Discovery radius', lat: 'Latitude', lng: 'Longitude', idToken: 'Sign-in token', termsAccepted: 'Terms acceptance' };

/** "industryId" → "Industry", "interestIds" → "Interests", "answers.0.optionId" → "Option" */
function label(path) {
  let last = [...path].reverse().find((p) => typeof p === 'string') || 'value';
  if (NAMES[last]) return NAMES[last];
  if (/[a-z]Ids$/.test(last)) last = `${last.slice(0, -3)}s`;
  else if (/[a-z]Id$/.test(last)) last = last.slice(0, -2);
  const words = last.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/[_-]+/g, ' ').toLowerCase();
  return words.charAt(0).toUpperCase() + words.slice(1);
}

const unit = (origin, n) => (origin === 'array' || origin === 'set' ? (n === 1 ? 'item' : 'items') : n === 1 ? 'character' : 'characters');

function friendly(issue) {
  if (!DEFAULT_TEXT.test(issue.message || '')) return issue.message;
  const name = label(issue.path || []);
  switch (issue.code) {
    case 'invalid_type':
      if (/received undefined/.test(issue.message)) return `${name} is required.`;
      if (issue.expected === 'number' || issue.expected === 'int') return `${name} must be a number.`;
      if (issue.expected === 'boolean') return `${name} must be true or false.`;
      if (issue.expected === 'array') return `${name} must be a list.`;
      if (issue.expected === 'object') return `${name} must be an object.`;
      return `${name} must be a ${issue.expected}.`;
    case 'too_small':
      if (issue.origin === 'string' || issue.origin === 'array') {
        return issue.minimum === 1
          ? `${name} is required.`
          : `${name} must have at least ${issue.minimum} ${unit(issue.origin, issue.minimum)}.`;
      }
      return `${name} must be ${issue.inclusive ? 'at least' : 'greater than'} ${issue.minimum}.`;
    case 'too_big':
      if (issue.origin === 'string' || issue.origin === 'array') return `${name} can have at most ${issue.maximum} ${unit(issue.origin, issue.maximum)}.`;
      return `${name} must be ${issue.inclusive ? 'at most' : 'less than'} ${issue.maximum}.`;
    case 'invalid_value':
      return `${name} must be one of: ${(issue.values || []).join(', ')}.`;
    case 'invalid_format':
      if (issue.format === 'date') return `${name} must be a date in YYYY-MM-DD format.`;
      if (issue.format === 'email') return `${name} must be a valid email address.`;
      return `${name} has an invalid format.`;
    case 'unrecognized_keys':
      return `Unknown field${issue.keys.length > 1 ? 's' : ''}: ${issue.keys.join(', ')}.`;
    default:
      return `${name} is invalid.`;
  }
}

module.exports = { friendly };
