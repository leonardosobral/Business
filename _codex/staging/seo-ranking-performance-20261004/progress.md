# SEO Semrush — ranking performance 2026-10-04

Scope: RR-20 snapshot 6ac29b3456eeefef0a3ff73b. Diagnose and optimize RoadRunners ranking query; publish only proven fix and update Business queue evidence.

Ruling: use scoped staging candidates and runtime baseline/backup rather than Git worktree; user prohibits Git mutations and work spans already dirty independent repositories. No commit/branch/PR.

Plan: establish metadata/latency baseline; profile ranking SQL; reproduce performance failure; optimize if proven; prove multiset equivalence and meaningful latency reduction; compile and review; deploy/verify public pages; update and publish Business queue.

Other triage: inspect filtered EN search and two ABAVSE URLs, with no date changes without source evidence.

Baseline SQL: 7,372 ms, 401 rows, 24 subplans executed 401 times (score expressions repeated for totals/participation). Performance budget test failed as expected.
Ruling: first unfiltered score aggregation was slower (13,546 ms; merge join materialized ~81 million intermediate rows) and never published. Restrict aggregation to registered participants and materialize their relevant results first; inspect plan again.

Final verification repeated explicitly with the production runnerhub datasource: baseline 7,149.512 ms; candidate 36.095 ms; exact multiset/hash equivalence, 401 rows, zero synthetic differences; CF QoQ 135 female, 266 male, 7 teams preserved; empty case zero. One template compiled. Independent SQL review found no blocker; public full-page comparison remains required.

Published and verified: ranking public 0.297623/0.3122 s vs 8.057152 s, exact six table hashes including order and metadata. One runtime hash and five dependency hashes verified. Local guarded sync complete. Business panel two templates published, 19 candidate and 19 published checks passed, nine watched dependencies intact; RR-21 complete technical delivery, supplier re-audit pending. Queue29/22/7; no vendor counters changed or new paid calls.
