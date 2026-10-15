# Game Workshop reporting and branch safety

Work only in Trauts1970/roller-coaster-creator. Keep unfinished game code on dev/roller-coaster-v0.1; main holds dashboard status and stable documentation. After meaningful saved milestones, update .game-workshop/status.json on main without merging unfinished code. Preserve concurrent changes; inspect current refs before writes.

Report verified facts only. Allowed checklist values: Unverified, Needed, In progress, Ready to test, Complete. A successful code build does not mean a Steam Deck playtest passed; only mark it Complete after user confirmation. Never invent build versions or download URLs.

## GitHub Pro usage policy (user authorized 2026-10-14 Pacific)

The user now authorizes useful GitHub Pro features, including Actions, within the included allowances in every billing period. This supersedes the previous blanket avoidance of Actions. Optimize development throughput, not quota consumption. No paid overages, extra subscriptions, larger paid runners, or paid storage increases are authorized.

Check the current plan, billing-period boundaries, account-wide usage across ALL repositories, and enforced account-wide spending controls before starting metered work. Do not assume an upgrade reset earlier usage. Repository run counts cannot establish account-wide remaining quota. If usage or spending controls cannot be verified, continue local builds/tests and ordinary source/status work; do not start metered jobs.

Verify product-level $0 overage budgets with "Stop usage when budget limit is reached" for applicable metered products before relying on cloud usage. Enable included-usage alerts. GitHub documents that new budgets do not cover usage predating their creation; review current-period usage too. Never report billing protection as configured without observing it. The current GitHub connector does not expose account billing/budget controls; these remain unverified.

Use standard Linux runners for this Linux/Steam Deck project. Prefer manual milestone workflows with explicit timeouts, concurrency cancellation, no automatic rerun loops, and no workflows triggered by dashboard-only changes. Keep a conservative reserve for concurrent work and delayed reporting; use local builds near quota or when usage is unknown. Do not schedule unattended metered work without an account-wide quota enforcement strategy.

Avoid Actions artifacts for distributed builds; prefer versioned GitHub Releases for validated packages. If temporary artifacts are needed, check remaining shared storage and set short retention (normally one day). Track current retained bytes AND accrued storage usage; deletion does not restore storage already accrued. Keep caches bounded within their included allowance and do not raise cache limits. Do not delete other games' releases, saves, or artifacts without applicable authorization.

Reference allowances verified from official GitHub Docs on 2026-10-15 UTC: Pro Actions 3,000 minutes/month and 1 GB artifact storage; Codespaces 180 core-hours/month and 20 GB-month storage; LFS 10 GB-month storage and 10 GB/month bandwidth. These are reference values, not observed remaining account quota. Recheck current terms and applicable shared pools before use.
- https://docs.github.com/en/billing/reference/product-usage-included
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.github.com/en/billing/how-tos/set-up-budgets
- https://docs.github.com/en/billing/concepts/budgets-and-alerts

Preserve saves/settings across installs. Keep Game Workshop updates lightweight.
