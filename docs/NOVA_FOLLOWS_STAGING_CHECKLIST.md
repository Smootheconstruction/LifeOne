# NOVA Followers & Leaders — private-beta staging checklist

**Status: code is implemented on development branch; online following is OFF.** Public signup, payments, paid badges, and automated Leader awards remain OFF.

## Prerequisites
1. Keep World Connect accessible only to approved invited adult beta users. Do not merge the draft branch to main.
2. Set up a separate Supabase staging project and independent test accounts A and B. Avoid testing against personal customer records.
3. Review and test `20261105_world_connect_moderation_draft.sql` on staging first (including `public.user_blocks`). Ensure messaging and friend request rules also enforce block relationships before broader social release.
4. Review and apply `20261108_nova_follows_leaders_REVIEW_ONLY.sql` only after prerequisites. Database changes are **not** applied by a GitHub commit. Ensure `nova_follow_pair_blocked` is owned by a trusted role that can check both block directions and cannot be changed by client roles.
5. Inspect all existing `profiles`, `friend_requests`, and `direct_messages` policies independently; the current application is not presumed secure based on these drafts.

## Two-user and adversarial QA (must be performed, not inferred)
- Anonymous requests must not read `nova_follows` or `nova_leader_awards`, and must not insert records.
- User A can follow User B; duplicate follows rejected by PK; A cannot follow A.
- A cannot create a follow on behalf of B, cannot delete B's follows; B cannot delete A's outgoing follow.
- A sees its own outgoing and incoming follows, but not unrelated third-party follow lists.
- Blocking in **either direction** makes a follow INSERT fail, hides the relationship from queries and blocks other interactions as separately enforced.
- Unblocking should trigger a product policy review: old follows remain in storage unless specifically removed.
- User A cannot create or self-award `nova_leader_awards`, change awards, or grant subscription entitlements.
- Only authorized admins may award/revoke leader recognition, with audit records in a separate non-public system.
- Sign out and switch between independent invited accounts: verify all follower, badge, messages and people views reset, and that no cross-account data persists.
- Try high-volume follow and unfollow requests; add server-side rate limiting and abuse monitoring before expansion.
- Verify report/block workflows, account suspension and privacy choices. Validate teen/child safeguards separately; do not connect Kids Learning to adult social experiences.
- Confirm Supabase project Auth disables public self-signup and RLS is enabled; check all grants using unauthenticated and regular account roles.
- Test in multiple browsers and devices; no public access or deployment promotion until independent review.

## Feature activation
`config.js` intentionally sets `window.LIFEONE_FOLLOWS_ENABLED = false`.
Only after verified staging tests and a separate production review should the authorized operator set the gate to true for an approved, controlled beta. This is a UI gate, **not a security boundary**: database RLS must be correct even with the flag removed.

## Paid membership and earned badges
- Pro membership is a descriptive preview; there is no billing, subscription checkout or paid entitlement.
- Leader awards require a separate documented admin process; no client-side automatic badge award based on followers, likes, or payments.
