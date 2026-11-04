# NOVA Career Connect — Implementation gates

**Status:** Server-side schema prepared for review. **No migration has been applied; no shared job board is live.**

The SQL draft is at `supabase/migrations/20261104_nova_career_connect_draft.sql`.

## Functional intent
- Companies register employer profiles and must pass manual verification.
- Verified employers submit job drafts for moderation; only trusted administrators publish listings.
- Workers search published vacancies and apply through their authenticated accounts.
- Applicant messages remain visible only to the applicant and the verified employer.

## Before applying the SQL
1. Confirm existing Supabase tables, authentication, policies and grants; run on a nonproduction staging database first.
2. Review all RLS policies for cross-account access and test unauthenticated, worker, verified and unverified employer accounts.
3. Define a secure administrative employer-verification and posting-moderation process; do not expose privileged service keys in browser code.
4. Add abuse reporting, posting expiry, employer identification, accessibility, fair-hiring rules, retention and deletion safeguards.
5. Add anti-spam/rate limiting, email/application notifications, compensation disclosure where required, and clear privacy terms.
6. Build and test separate employer and worker interfaces against the secured backend.
7. Only after sign-off, migrate production and enable real publishing; avoid displaying 'posted' or 'applied' before confirmation.

## Current experience
The existing Jobs & Hiring screen saves **local** draft job announcements on the employer's device, not to Supabase. A user viewing another device cannot yet discover those jobs.

## Product checkpoint
- Confirm publication and application with two separate authorized accounts.
- Verify a third unauthorized account cannot read unpublished listings or applications.
- Test rejected/pending/expired states and moderator actions.
- Verify no applicant information leaks through public job listings.
