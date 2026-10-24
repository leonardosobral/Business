# Business Home Implementation Plan

> For agentic workers: apply executing-plans / subagent-driven-development as appropriate; user has approved the visual and requested execution. Do not ask for another implementation or publication approval.

**Goal:** Turn the global-admin home into a compact decision and monitoring page with real KPIs, actionable exceptions, and direct links.

**Architecture:** Keep authentication, header and Meet behavior unchanged. Reuse the existing queue definitions; add an independently failing, cached metrics include; move rendering to a dedicated view and add scoped CSS and accessible tabs. No schema or credentials changes.

**Tech Stack:** CFML, PostgreSQL, MDBootstrap, vanilla JS, existing Node/CommandBox test tools.

**Spec:** User-approved preview at `/Users/leonardosobral/.codex/visualizations/2026/10/24/01a16ea6-69a4-7501-9189-7aef58d7e14f/business-home-proposta.html` plus conversation requirements.

## Global Constraints
- Scope only Business global admin; preserve delegated/account views and all unrelated local edits.
- No branch, commit, push, PR or migration; user did not authorize them.
- Publish scoped runtime only after production baseline, recoverable backup, verification and independent review.
- Missing data is unavailable, never measured zero. Hide successfully loaded zero queues; expose positive and failed sources.
- Visitors are browser identities, not Business account memberships. Investment is internal advertiser consumption, not external media or cash revenue.
- Runtime uses 7/30-day windows including today, matching current destination screens. Explicitly label partial-day comparisons rather than silently use yesterday-only mock periods. Daily Ads cannot support an intraday matched baseline.

## Review Focus
- Missing/failed sources preserve other KPIs; zero baseline does not produce infinite growth.
- 30-day window, internal traffic exclusion, time zones and historical coverage do not inflate growth.
- Ads EVENT/BANNER totals provide both destinations, not a misleading single destination.
- Empty approval/cron/payment queues disappear; failure remains visible and no known queue is silently omitted.
- Tabs and direct anchors work by keyboard, at mobile widths and without JS.

### Task 1: Metrics
Files: new `includes/backend/business_home_metrics.cfm`; focused SQL behavior tests.
Interface: `VARIABLES.businessHomeMetrics` with `days`, source structs `audience`, `ads`, `accounts`, `users`. Each source has `loaded`, `comparison_ready`; flat numeric current names and `previous_` names. Audience: visitors,pageviews,interactions. Ads: impressions,clicks,cost,event_cost,banner_cost. Accounts/users: new_count. All independent and cached.
- [x] Write and run failing tests against SQL on isolated PostgreSQL for bounds, internal/dev exclusion, duplicate visitors, event allowlist and metric scopes.
- [x] Implement small read-only queries; validate URL period; return independent availability and comparison coverage.
- [x] Run tests; validate actual production query types/performance without mutation.

### Task 2: Decision view
Files: `includes/estrutura/home_admin_dashboard.cfm`, new `includes/estrutura/home_admin_decision_view.cfm`, `assets/css/admin-dashboard.css`, new `assets/js/business-home-dashboard.js`.
- [x] Add behavior tests for empty/failing/positive queues and URL-backed tabs.
- [x] Preserve current data definitions and header/Meet; remove unused detail-list queries and inline work tables.
- [x] Render KPIs, compact secondary metrics, positive/unknown exceptions, area tabs with direct destinations, period-preserving refresh links.
- [x] Keep zero as zero for useful business KPIs; show exception rows only >0 or unavailable.
- [x] Compile/render CFML with fixtures; verify interactions and desktop/mobile layouts, existing scoped tests.

### Task 3: Review and publication
Files: task-specific `_codex/staging/business-home-20261024/`, receipt/documentation in `_codex/docs/`.
- [x] Capture source hashes before edit and production baseline; detect conflicts before replace.
- [x] Independent review and fix material findings.
- [x] Stage and compile candidate; probe metrics on real data; backup; atomically publish manifest with final concurrency guard.
- [x] Confirm production hashes and actual authenticated page in both periods; confirm public landing for anonymous access and preserve account/authentication routing files.

## Progress / rulings
- Approved visual received; user requested proceed. Existing checkout reused because user forbids unrequested branches and unrelated changes must be preserved.
- Preview values are illustrative and are never runtime fixtures or fallbacks.

- Completed 24/10/2026: 43 view render checks, 29 focused Node tests, metrics and cron SQL checks passed; three CFML templates compiled in production compiler before publication.
- Review fixes: separate interaction history coverage, and alert only on scheduled jobs overdue by at least 15 minutes outside running state.
- Published five-file manifest at 16:35 UTC. Backup `/var/backups/business-home-20261024-bmev1ttg/baseline`; receipts under `_codex/staging/business-home-20261024/`. Authenticated 7/30-day views and all tabs verified, including keyboard navigation. No account/delegated session was switched for testing.
- Six broad-suite failures were pre-existing/unrelated; details in the task release report. No Git operation or unrelated publication.
