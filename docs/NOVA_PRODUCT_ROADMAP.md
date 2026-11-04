# LifeOne NOVA — Product Roadmap
**Motto:** One World. One Connection. Endless Possibilities.
**Status:** Proposed development plan, not a release promise.
**Funding scenario:** $100,000 pre-seed validation round; spending and timelines subject to review.

## Product pillars
1. NOVA Life Coach AI — daily goals, résumé and interview assistance, learning recommendations.
2. Kids Academy — math, reading, science, games, parent-managed progress; no unmoderated messaging or adult discovery.
3. Career Connect — job and employer profiles, applications, safe communications, verified employers and anti-fraud controls.
4. Creator Marketplace — rights-cleared music and video, creator profiles, follower discovery, subscriptions and sales experiments.
5. Global Connect — moderated communities, language translation, privacy and reporting controls.
6. Rewards — XP, badges, educational milestones; no cash-equivalent rewards at pilot stage.
7. Local Services — business discovery, service requests, scheduling, provider verification.

## Current state
- Gemini AI is live and working on main.
- Development branch includes Media Lounge, Creator Studio local drafts, and early Kids Learning and Jobs & Hiring previews.
- World Connect is a private-beta prototype requiring independent security testing.
- Creator drafts do NOT publish media. Hiring drafts do NOT post jobs. Learning preview does NOT create child accounts.
- Keep existing live application unchanged until features pass tests and are approved.

## Phases and release gates
### Phase 1: Core stability and safety (months 1–3, planning estimate)
- Regression test navigation across mobile and desktop after every frontend change.
- Confirm authentication, data access controls, and private messages with isolated test users.
- Finish responsible reporting/blocking design for adults.
- Introduce non-sensitive, local-only Life Coach and Rewards previews.
- Milestone: reliable navigation, tested privacy controls, dependable Gemini.

### Phase 2: Pilot utility (months 4–6)
- Secure owner-scoped creator uploads with content moderation and rights/takedown process.
- Adult-only private creator cohort and measurable usage analytics.
- Strengthen job tools without ingesting résumés or publishing unverified roles.
- Prototype child learning in isolated, parent-controlled architecture; consult applicable child-privacy requirements before public collection.
- Milestone: 20–30 creators in a supervised beta; successful safety tests.

### Phase 3: Trusted community (months 7–9)
- Trial verified business hiring, protected application flows, and job posting review.
- Expand adult social connections with reporting, moderation, and privacy controls.
- Pilot language support and creator discovery.
- Milestone: useful engagement and retention measurements; no critical privacy findings.

### Phase 4: Sustainable growth (months 10–12)
- Pilot provider-verified Local Services booking or inquiry flows.
- Test creator subscription or digital-sales demand subject to content licensing and payment compliance.
- Iterate Rewards using opt-in, non-cash achievements.
- Milestone: credible unit economics and investor-ready outcomes.

## Guardrails
- Never expose children to adult profiles, direct messaging, unmoderated social search, or behavioral advertising.
- Verify relevant privacy and child-data laws (including COPPA where applicable) before operating child accounts.
- Never claim live job listings, hiring applications, creator publishing, or monetization before backend implementation and testing.
- Follow accessible, fair, and anti-scam hiring practices; protect applicant data and verify businesses.
- Never distribute copyrighted recordings or videos without necessary rights.
- Do not interrupt existing Gemini backend; do not merge the development PR until security and multi-user tests pass.

## Success metrics
- Stability: zero known navigation-blocking failures; mobile interaction testing.
- Product: verified active users, 7- and 30-day retention, creators publishing and repeat usage.
- Trust: resolved abuse reports, moderation response, no known unauthorized data access.
- Economics: monthly infrastructure expense per active user, paid conversion tests where appropriate.

## Next near-term tasks
1. Add navigation smoke/regression checks to protect against selector/runtime crashes.
2. Scope safe Life Coach and Rewards local-only experiences.
3. Independently verify Supabase RLS and multi-user permission boundaries.
4. Plan the secure creator storage design, hiring verification and child-zone isolation separately.

This roadmap is editable and subject to funding, feedback, product quality and legal review.
