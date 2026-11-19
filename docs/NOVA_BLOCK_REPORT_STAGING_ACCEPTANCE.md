# NOVA blocking and reporting — independent staging acceptance checklist

Status: **NOT VERIFIED**. This document is a test plan, not evidence of deployed controls or applied migrations.

## Preconditions
- Use only invited, disposable staging accounts A, B and C. Never use customer accounts or production data.
- Independently inspect staging Supabase RLS policies, grants and deployed schema before enabling browser feature flags.
- Record test date, staging deployment URL and immutable commit SHA, migration identifiers actually applied, tester roles, and redacted query/HTTP outcomes. Do not store tokens, credentials, private messages or identifying reports in this repository.

## Required tests
1. **Block enforcement:** A blocks B. B must not be able to message, follow, request friendship, or view A's restricted content using both the UI and direct authenticated API calls. Record denied status/error without message contents.
2. **Reverse direction:** Verify the same restrictions when B blocks A; confirm no stale cached UI displays restricted content after refresh and sign-out.
3. **Unblock:** A unblocks B. Access must follow the explicit relationship and privacy rules; unblocking must not automatically restore friendship or consent.
4. **Report submission:** A reports B or a post. Verify the report is visible only to authorized moderators and the reporter as explicitly allowed by policy; B and unrelated C cannot enumerate or read it.
5. **Forged identity:** B attempts to create a report or block record claiming to be A using direct authenticated requests. RLS must reject the attempt.
6. **Cross-account isolation:** After A logs out and B logs in on the same browser, A's blocked lists, reports, messages and notifications must not appear in B's session.
7. **Error and retry:** Simulate offline/network failure for block and report actions. The UI must show failure, avoid claiming success, and not duplicate actions on retry.
8. **Admin boundary:** Ordinary A/B/C accounts cannot list all reports, change moderation status, or remove another user's block; authorized moderator access is independently checked.
9. **Deletion and retention:** Verify report attachments and personal information follow the documented retention and access rules; do not claim deletion without database evidence.

## Evidence and release gate
For each case record **PASS / FAIL / NOT RUN**, timestamp, staging commit, relevant policy identifier, test account labels, exact API response/status, and redacted screenshot or query output. A UI-only pass is insufficient for RLS claims. Any missing policy, unrun direct API check, or cross-account failure keeps blocking/reporting feature flags **off**. Do not deploy, merge, or enable flags as part of executing this checklist.
