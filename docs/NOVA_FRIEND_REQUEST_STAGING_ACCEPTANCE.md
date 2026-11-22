# NOVA friend-request staging acceptance matrix

Scope: isolated `world-connect.html` private beta on `feature/world-connect-private-beta`. **Not evidence of a passed test.** Run only on a protected staging deployment with two pre-invited, independent test accounts; do not create accounts from this page or use real customer data.

## Preconditions
- Confirm invitation-only Auth configuration and independently inspect RLS policies for `profiles`, `friend_requests`, `direct_messages`, and `user_blocks`.
- Verify staging access restrictions, test-only accounts A/B, and that moderation/blocking features remain disabled until server-side enforcement is proven.
- Capture sanitized evidence: outcome, time, test case ID, and database policy version. Never record passwords, tokens, message bodies, or personal email addresses.

## Cases (mark PASS/FAIL/NOT RUN)
| ID | Scenario | Expected outcome |
| --- | --- | --- |
| FR-01 | A opens Explore and requests B | One pending outbound request; button cannot accidentally create duplicates |
| FR-02 | A repeats request quickly, including two tabs | At most one active request; clear, non-sensitive feedback |
| FR-03 | B opens Friends and accepts A | Both accounts show friendship after refresh; messages only then become eligible |
| FR-04 | B declines a fresh request | No friendship and no messaging access |
| FR-05 | A attempts to accept or delete B's incoming request by forged request ID | Database rejects unauthorized operation; no state changes |
| FR-06 | A attempts a request on behalf of B with a forged sender ID | RLS rejects impersonation |
| FR-07 | A signs out while a request or friends fetch is pending; B signs in | A's identity, request buttons, list, and async results never appear under B |
| FR-08 | A requests B while B has blocked A | Server rejects the request and prevents friendship/messaging, regardless of UI |
| FR-09 | Disconnect network during send/accept | Button recovers; user gets retry guidance without duplicate action |
| FR-10 | A tries to fetch unrelated C's private requests | No unauthorized rows returned |
| FR-11 | Reload after acceptance on both accounts | Persistent friendship agrees with authorized database state |
| FR-12 | A tries sending a direct message before acceptance | Server rejects it, even if browser code is bypassed |

## Release gate
Any failed unauthorized-access or block-enforcement case blocks enabling social features. Static code checks and green CI alone cannot establish Supabase RLS correctness. Obtain independent cross-account test evidence and review before changing feature flags, merging, or deploying publicly.
