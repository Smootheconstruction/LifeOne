// Read-only guard for private-beta browser configuration.
// Run: node tests/private-beta-config.test.mjs
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const config = readFileSync(new URL('../config.js', import.meta.url), 'utf8');
for (const flag of ['LIFEONE_FOLLOWS_ENABLED', 'LIFEONE_SAFETY_ENABLED', 'LIFEONE_SHARED_POSTS_ENABLED']) {
  const matches = [...config.matchAll(new RegExp('\\bwindow\\.' + flag + '\\s*=\\s*(true|false)\\s*;', 'g'))];
  assert.equal(matches.length, 1, flag + ' must be assigned exactly once as a boolean');
  assert.equal(matches[0][1], 'false', flag + ' must remain disabled until independent security review');
}
assert.doesNotMatch(config, /(?:service_role|sb_secret_)[A-Za-z0-9_-]{8,}/i, 'Potential privileged credential in public config');
console.log('PASS: three private-beta flags remain disabled; no obvious privileged credential in config.js');
