// Static regression checks for account-switch privacy in the isolated beta page.
// Run: node tests/world-connect-session-isolation.test.mjs
// Static assertions do not verify Supabase RLS or authenticated cross-account behavior.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../world-connect.html', import.meta.url), 'utf8');
assert.match(html, /const changed=user\?\.id!==userNow\?\.id/, 'Detect account changes');
assert.match(html, /if\(changed\)\{friend=null;/, 'Discard selected conversation on account change');
for (const id of ['conversation','peopleList','requests','friendsList','chatFriends','followDiscover','followFollowing','followFollowers','mySharedPosts','sharedDiscoverPosts','safetyBlocked']) {
  assert.ok(html.includes("'"+id+"'"), 'Account-switch reset must include '+id);
}
assert.match(html, /\$\('message'\)\.value=''/, 'Clear unsent message text');
assert.match(html, /\$\('sendForm'\)\.classList\.add\('hidden'\)/, 'Hide message composer');
assert.match(html, /\$\('safetyPerson'\)\.replaceChildren\(new Option\('Select an account',''\)\)/, 'Clear moderation target');
assert.match(html, /if\(!user\|\|user\.id!==account\)return/, 'Reject stale asynchronous account results');
console.log('PASS: static account-switch privacy guards');
