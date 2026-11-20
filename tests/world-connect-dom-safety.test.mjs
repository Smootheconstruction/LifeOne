// Static browser privacy regression guard for the isolated private-beta page.
// Run: node tests/world-connect-dom-safety.test.mjs
// This is not a substitute for authenticated RLS or cross-account testing.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../world-connect.html', import.meta.url), 'utf8');

// Untrusted profile names, posts and messages must not enter HTML parsing sinks.
for (const [name, pattern] of [
  ['innerHTML', /\.innerHTML\s*=/],
  ['outerHTML', /\.outerHTML\s*=/],
  ['insertAdjacentHTML', /\.insertAdjacentHTML\s*\(/],
  ['document.write', /\bdocument\.write\s*\(/],
  ['eval', /\beval\s*\(/],
  ['Function constructor', /\bnew\s+Function\s*\(/],
]) {
  assert.doesNotMatch(html, pattern, name + ' is unsafe for untrusted content');
}
assert.match(html, /n\.textContent\s*=\s*txt\s*\?\?\s*''/, 'Text rendering helper must use textContent');

// Never introduce browser storage of message bodies or credentials in this page.
assert.doesNotMatch(html, /\b(?:localStorage|sessionStorage)\s*\./, 'Avoid browser storage of private content');
assert.match(html, /id="password"[^>]*type="password"/, 'Sign-in password must use a masked input');
assert.match(html, /id="message"[^>]*maxlength="2000"/, 'Message length limit must remain present');

// Prevent accidental self-service account creation from the browser.
assert.doesNotMatch(html, /\.auth\.signUp\s*\(/, 'Private beta must not offer public signup');
console.log('PASS: World Connect static DOM and private-beta signup safeguards');
