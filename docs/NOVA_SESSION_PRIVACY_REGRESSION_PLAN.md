# NOVA World Connect — session privacy regression test plan

**Scope:** private development preview only. This is a test specification, not evidence of passing tests. Do not enable feature flags, run production migrations, create public accounts, or treat browser UI checks as proof of Supabase RLS.

## Setup and evidence
- Use a dedicated staging Supabase project with two independently invited adult test accounts (A and B), a third unrelated test account (C), and an anonymous browser session. Do not use customer records.
- Record test date, branch SHA, preview deployment ID/URL, browser/device, staging project identifier (not credentials), tester, result (pass/fail/blocked), and redacted screenshots or network response codes.
- In each test, inspect both visible UI and authenticated network requests. Do not save JWTs, message bodies, email addresses, or service-role keys in screenshots, logs, or GitHub issues.
- A successful Vercel build, hidden button, or client feature flag is **not** authorization evidence.

## Browser/session privacy cases
| ID | Procedure | Expected result |
| --- | --- | --- |
| P01 | Sign in as A; open messages, friends, profile and post composer. Sign out. | A's avatar, names, message previews, drafts, friend list and post data disappear immediately; protected views are inaccessible. |
| P02 | After P01, use browser Back/Forward and refresh. | No previous account data is rendered from history, cached state, or storage. |
| P03 | Sign in as B in the same browser after A. | No A-specific messages, profile edits, selected conversation, private posts, or pending actions appear under B. |
| P04 | While A's message/friend fetch is in flight, sign out and sign in as B. Resolve A's delayed request. | Late response is ignored; no cross-account UI contamination. |
| P05 | Sign in as A in one tab and sign out in another. | First tab invalidates protected views on auth change and rejects stale compose/send actions. |
| P06 | Disable network during send/friend-request submission; retry after reconnect. | UI shows failure or retry status; never falsely claims success or duplicates actions without server confirmation. |
| P07 | Open staging in a fresh anonymous browser and navigate directly to protected routes. | No private data or protected actions accessible; unauthorized responses verified server-side. |
| P08 | Paste long HTML-looking names, messages and captions from test accounts. | Content appears as inert text; no script execution or unsafe link activation. |

## Server-side adversarial checks (independent reviewer required)
| ID | Procedure | Expected result |
| --- | --- | --- |
| R01 | As A, request B/C messages and profiles outside permitted relationships using direct Supabase calls. | RLS rejects unauthorized rows even if UI gates are bypassed. |
| R02 | As A, attempt friend request, accept, delete and message operations on behalf of B. | Writes rejected except explicitly permitted owner/recipient actions. |
| R03 | Block A→B and B→A separately; attempt messages, friend requests, follows and shared-post reads/writes. | Both block directions enforced in database policies, not only UI. |
| R04 | As anonymous user, query private tables and attempt writes. | No private rows and no unauthorized writes. |
| R05 | As A, attempt to read or change private reports, moderation outcomes, or admin-only awards. | Reports stay confidential; privilege escalation denied. |

## Release decision
- Mark every row **PASS**, **FAIL**, or **BLOCKED** with evidence links and exact SHA; a row with no evidence remains **NOT RUN**.
- Do not claim authenticated two-user messaging, moderation safety, deployed migrations, or production readiness until independent reviewer evidence exists.
- Keep follows, safety and shared-post flags OFF until database and cross-account verification plus moderator workflow review are complete.
- Escalate any P01–P05 or R01–R05 failure as a privacy/security blocker before expanding beta access.
