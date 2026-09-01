# SDD ledger — plan: docs/superpowers/plans/2026-08-30-mif-2026-channel-sales-study.md

## Setup

- Execution directory: `/Users/Shared/Projects/RunnerHub/Business`
- Starting branch: `main`
- Merge base / starting HEAD: `df9ebdc3869f655a6c3875c145a3bc36ed530785`
- Baseline: bundled Node `--test _codex/tests/*.test.js` — 13/13 passing, 0 failures.
- Data route: `gather-business-context` → `product-business-analysis` + `analyze-data-quality` → `visualize-data` → `build-report` → `validate-data`.

## Preflight rulings

- Ruling: work directly on `main` — the user explicitly rejected a worktree and authorized in-place execution — if wrong, implementation commits land directly on the current branch but remain individually revertible.
- Ruling: create the task commits required by Subagent-Driven Development — the user selected this execution mode after asking to proceed with committed work — if wrong, the cost is additional local commits that can be reverted without rewriting remote history.
- Ruling: use the installed Data plugin `0.2.34-13ceeea1f599`, its shared Data App template, and `scripts/data-app.mjs build` for Tasks 7–8 instead of the older portable-artifact builder named in the plan — the approved spec requires one autonomous HTML but does not bind the obsolete builder — if wrong, the report file layout differs from the implementation plan while preserving the requested deliverable and reviewed-data contract.
- Ruling: treat the copied app's `src/data.json` as canonical report content and produce `dist/index.html` plus sanitized `dist/shareable.html`; retain `aggregates.json`, `reconciliation.json`, and `source_notes.json`, but do not create a parallel `artifact.json` renderer — current Data App rules require one runtime and one source tree — if wrong, consumers expecting the planned legacy `artifact.json` must instead use `src/data.json`.
- Ruling: add one executed companion notebook for source quality, reconciliation, and headline spot checks — current Data Quality and Product/Business Analysis skills require an inspectable notebook for non-trivial Python analysis — if wrong, the extra reviewed artifact adds maintenance without changing the report.
- Ruling: do not issue an automatic keep/cut recommendation even though the generic Product/Business Analysis workflow normally ends with one — the user's explicit decision and approved spec require comparable evidence and human decision questions only — if wrong, the report is less prescriptive than a generic decision memo.
- Ruling: perform only the report-content desktop/mobile/print checks specified by the approved design, not a broad shared-runtime/editor sweep — the user-approved acceptance criteria request those final-format checks while the Data App contract reserves general runtime QA for plugin maintainers — if wrong, a shared-runtime issue outside authored content may remain untested.
- Ruling: legacy ignored XLSX dumps may develop and test the method but never support final 2026 claims; Task 8 remains incomplete until a fresh event-scoped source is available — this is explicit in the approved spec — if wrong, the cost is delaying final findings rather than silently publishing stale totals.
- Ruling: preserve the user's concurrent commit `3151406` that added the previously untracked implementation plan during Task 3, and scope the Task 3 review from that commit to the implementer's commit — the user owns concurrent repository changes — if wrong, review history includes a user-authored documentation commit outside the task diff, but no user work is rewritten or dropped.
- Ruling: preserve and exclude from every MIF stage/commit the user's concurrent result-import changes (`_codex/docs/result_import_queue.md`, `administracao/importacoes-resultados/*`, `_codex/tests/result-import-queue.test.js`, `assets/js/result-import-queue.js`) observed during Task 5 — they are unrelated user work in a shared dirty checkout — if wrong, the MIF task leaves a separate in-progress feature untouched rather than risking cross-feature edits.

## Preflight interface scan

| Producer | Consumer | Shared file/interface | Finding |
| --- | --- | --- | --- |
| Task 1 | Task 2 | `config.py`, package imports, `EVENT_DATE` | Compatible; Task 2 consumes exact constants created in Task 1. |
| Task 1 | Task 3 | `SourceBundle`, `SourceSnapshot`, source frames | Compatible; Task 3 consumes the composite-key source contract. |
| Task 1 | Task 7 | `AnalysisResult`, source freshness metadata | Compatible after Data App ruling; `AnalysisResult` feeds `src/data.json` rather than legacy `artifact.json`. |
| Task 2 | Task 3 | parsing and normalization functions | Compatible; validity status distinguishes invalid from missing. |
| Task 2 | Task 4 | `normalize_key` | Compatible; exact normalized title/code tuple remains the join key. |
| Task 3 | Task 4 | `FactBundle` and three fact frames | Compatible; Task 4 returns a new mapped `FactBundle`. |
| Task 3 | Task 5 | allocated order values and reconciliation | Compatible; Task 5 must use allocated financial values and non-additive touched-order counts. |
| Task 4 | Task 5 | `channel_name`, `channel_type`, product classification | Compatible; Task 5 receives only reviewed mappings. |
| Task 5 | Task 6 | `AnalysisResult`, dossiers, overlap datasets | Compatible; Task 6 suppresses small cells and writes neutral narratives. |
| Task 5 | Task 7 | anonymous datasets and source notes | Compatible after Data App ruling; stable query IDs replace legacy manifest dataset IDs one-for-one. |
| Task 6 | Task 7 | `protect_analysis`, anonymity scan, narratives | Compatible; privacy precedes serialization and report authoring. |
| Task 7 | Task 8 | CLI, reviewed JSON, copied report app, build command | Compatible after Data App ruling; Task 8 refreshes the same app and builds `dist/shareable.html`. |

## Preflight internal scan

| Task | Self-consistency | Finding |
| --- | --- | --- |
| Task 1 | Files, tests, source schema, SQL | Consistent; final freshness uses SQL-emitted `extracted_at`, not file mtime. |
| Task 2 | Tests and normalizer contracts | Consistent; `coverage_status` preserves invalid/missing distinction. |
| Task 3 | Tests, fact grains, allocation | Consistent; order totals allocate to registrations and mixed-channel money stays additive. |
| Task 4 | Draft/review mapping lifecycle | Consistent; synthetic mappings are temporary development fixtures, replaced by fresh reviewed mappings. |
| Task 5 | Metrics, threshold, similarity | Consistent; six dimension-specific views remain separate and no master score exists. |
| Task 6 | Privacy, narrative, decision questions | Consistent; small-cell suppression excludes top-level channel totals. |
| Task 7 | Tests and output contract | Plan's old builder conflicts with current Data App contract; ruled above before implementation. |
| Task 8 | Fresh source, report build, QA | Plan's old output names/build command conflict with current Data App contract; ruled above; fresh-source dependency remains binding. |

## Task progress

- Task 1: fix round 1/5 (2 addressed, 0 open; commits `ca53763..f7946cd`).
- Task 1: complete (commits `df9ebdc..f7946cd`, scoped re-review clean; controller verification: focused 7/7, cumulative Python 7/7, diff checks clean).
- Task 2: fix round 1/5 (2 addressed, 0 open; commits `5ee4e9d..f0e0a9a`).
- Task 2: complete (commits `f7946cd..f0e0a9a`, scoped re-review clean; controller verification: focused 15/15, cumulative MIF 22/22, diff checks clean).
- Task 3: fix round 1/5 (2 addressed, 0 open; commits `c8f08f1..4c56227`).
- Task 3: complete (task commits `3151406..4c56227`, scoped re-review clean; controller verification: focused 16/16, cumulative MIF 38/38, diff checks clean).
- Task 4: complete (commit `a368fd7`, task review approved; controller verification: focused 10/10, cumulative MIF 48/48, diff checks clean).
- Task 5: fix round 1/5 (3 Critical/Important and 1 Minor addressed; 1 Critical remained open; commits `79f0097..ae10844`).
- Task 5: fix round 2/5 (1 addressed, 0 open; commits `ae10844..bfd22d6`).
- Task 5: complete (commits `a368fd7..bfd22d6`, scoped re-review clean; controller verification: focused 25/25, cumulative MIF 73/73, task and working-tree diff checks clean; unrelated user changes preserved).
- Task 6: fix round 1/5 (2 addressed, 0 open; commits `d096f24..d24e07c`).
- Task 6: complete (commits `bfd22d6..d24e07c`, scoped re-review clean; controller verification: focused 12/12, cumulative MIF 85/85, task and working-tree diff checks clean; unrelated user changes preserved).
- Task 7: fix round 1/5 (3 addressed, 1 residual open; commits `677060c..e636669`).
- Task 7: fix round 2/5 (3 literal bypasses addressed; broader semantic/freshness gaps and 2 regressions remained; commits `e636669..0ee3f2f`).
- Task 7: fix round 3/5 (4 addressed; paid-order auxiliary denominator and timezone ordering remained; commits `0ee3f2f..0a71b26`).
- Task 7: fix round 4/5 (paid-order coverage and chronological freshness addressed; zero-paid and legacy `--allow-stale` edges remained; commits `0a71b26..5ea14b2`).
- Task 7: fix round 5/5 (zero-paid and fixture-only stale marker addressed; commits `5ea14b2..c2ab751`).
- Task 7: complete (commits `d24e07c..c2ab751`, final scoped re-review clean; controller verification: focused artifact 24/24, cumulative MIF 109/109, canonical CLI verify and diff checks clean; snapshot remains explicitly `fixture`; unrelated user changes and `/inscricoes/` preserved).
- Task 8: implementation complete pending controller visual QA/review (product parser commit `578356a`; fresh event `72611` receipts verified; reviewed complete mappings; canonical snapshot `ready` with 31 queries; notebook 5/5 cells and 0 errors; independent financial/ticket verification and paid-only product totals fixed; chart-only Top 10 + `Outros` keeps ten ranked leaders followed by `Outros`, plus explicit lot/modality order, covered by 8/8 Node tests; full MIF suite 124/124; official Data App build, 140 protected hashes, theme, shareable scan, and diff checks green; unrelated result-import work and `/inscricoes/` preserved).
