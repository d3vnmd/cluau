# Workflow: launch or big update

1. **Quality gates:** lint 0 errors, audit_project table reviewed, independent review on money/data paths, unit
   tests (pure modules) green.
2. **Playtests:** Server & Clients (2–3 players) — join, leave mid-action, rejoin, purchase, trade, respawn;
   real low-end Android; gamepad-only pass; 30-minute soak watching memory.
3. **Data safety:** Open Cloud snapshot before schema changes; key pattern unchanged; BindToClose verified;
   rollback plan.
4. **Monetization compliance:** ProcessReceipt idempotent and audited-safe, odds disclosed, PolicyService paths,
   no dark patterns (monetization-policy.md).
5. **Store page:** icon ≥ 512², 2+ thumbnails 1920×1080 (personalization), honest title/description, content
   questionnaire, localization on (polish-qa-launch.md §9).
6. **Live-ops ready:** ConfigService defaults safe, events and restocks scheduled (LiveOpsService), analytics
   funnels/economy events logged.
7. **Ship:** publish to staging → smoke test → production (Open Cloud CI or manual) → watch errors/metrics for
   the first hours; soft-shutdown plan for hotfixes.
