# NOVA World Connect — error recovery staging checklist

**Scope:** Private-beta review only. This checklist is not evidence of live Supabase security or a passing browser test.

## Preconditions
- Use an access-controlled staging deployment and two previously invited, independent test accounts; do not create public accounts.
- Confirm RLS policies separately with the least-privileged authenticated sessions.
- Use synthetic messages and profiles only; never paste credentials, session tokens, or private user data into screenshots or logs.
- Record the tested commit SHA, browser, date, outcome, and sanitized issue reference for each scenario.

## Browser and network scenarios
1. **Offline before login:** Disconnect network, submit sign-in, and verify an understandable error without a false signed-in state or credential disclosure.
2. **Offline while sending:** With a synthetic draft, disconnect before sending. Verify failure is visible and the UI does not claim delivery. Restore connectivity and check for duplicates before retrying.
3. **Slow/stale response across logout:** Delay a people/messages request, sign out or switch accounts, then release the response. Confirm no previous-account content reappears.
4. **Expired session:** Invalidate the test session, then request messages, friendships, and posts. Confirm private content is hidden and the user is prompted to authenticate again.
5. **Friend request collision:** From two sessions, issue duplicate or reciprocal requests. Confirm one understandable outcome and no duplicate friendship rows; verify actual database constraints separately.
6. **Permission denied:** Attempt to view or send to an unauthorized account. Confirm generic, non-enumerating errors; independently verify the backend rejects the request.
7. **Blocked account:** Block a test account while its conversation is open. Confirm the composer and pending actions become unavailable; verify server-side block enforcement independently.
8. **Report submission failure:** Simulate a network failure during a synthetic report. Confirm no success message until persistence is confirmed and retries do not create duplicate reports.
9. **Password recovery:** Exercise the staging recovery flow with an invited account. Confirm recovery links and errors do not expose tokens in app logs or page content.
10. **Browser refresh/back navigation:** After logout, refresh and navigate back. Confirm private conversations and drafts are not restored from browser storage or stale DOM state.

## Release gate
A checklist item is **PASS** only with a recorded manual/automated execution and evidence. Static code inspection is **REVIEWED**, not PASS. Supabase RLS and cross-account messaging remain **UNVERIFIED** until independent staging tests demonstrate access denial. Do not merge or deploy publicly based on this document.
