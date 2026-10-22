# Event rewrite validation — implementation plan

> **For agentic workers:** Execute inline using test-driven development; review the scoped patch before publication.

**Goal:** Correct the three diagnosed rejection cases without relaxing factual integrity.

**Architecture:** Keep the existing CFML service and authenticated endpoint. Strip only recognized orphan stylesheet prefixes and their known template instructions, reject placeholder-only sources before a provider call, and compare equivalent duration spellings separately from clocks. Propagate allowlisted validation codes and Portuguese explanations to cron results; persist the primary code in the existing audit column.

**Tech Stack:** Adobe ColdFusion 2025, Java regex, existing PostgreSQL audit schema.

**Spec:** Approved in this conversation: source cleanup, equivalent duration validation, detailed rejection history, factual protections preserved.

## Global constraints

- Do not change credentials, model, schedule, source data, schema, or historical decisions.
- Do not reset rejected queues in bulk; two source documents lack useful event content.
- Publish only scoped runtime files after native CFML tests, baseline checks, and recoverable backup.
- No commit or push authorized.

## Review focus

- CSS cleanup must preserve real numbers, URLs, and prose containing braces.
- Durations cannot become start times, change value, or exchange units.
- Placeholder sources must not consume an AI call or produce invented descriptions.
- Rejection details must never expose provider text, source text, or secrets.
- Translation and key-selection behavior must remain covered by existing regressions.

## Task 1 — service regression and integrity rules

- [x] Add failing tests for orphan CSS, placeholder preflight, duration equivalence and changes, clock separation, and safe reason codes.
- [x] Run them in an isolated, loopback-only native CFML harness with a fake provider; record RED.
- [x] Implement targeted normalization, duration fact comparison, and safe validation details in `services/EventDescriptionRewriteService.cfc`.
- [x] Run new and existing rewrite/translation tests; require GREEN.

## Task 2 — cron diagnostics and publication

- [x] Test that both endpoint rejection catches use allowlisted details and preserve typed dependency handling.
- [x] Add reason arrays and explanatory messages to per-event results while storing the primary code in existing audit rows.
- [x] Run credential-selection regression and native endpoint checks.
- [x] Review the scoped diff; resolve actionable findings.
- [x] Compare production baseline, back up both runtime files, publish atomically, and verify actual runtime.

## Verification ledger

- Native Adobe CF: 198 assertions, 29 endpoint guards, six dummy credential-selection cases passed. Observed sources 43854/44883 reject before any provider request; the completed 43916 candidate passes local validation.
- Review fixes covered RED→GREEN: fractional duration must not lose its fraction; translated labels do not change literal time checks; CSS selectors cannot cross editorial lines or start from arbitrary prose.
- Existing accented-unit regression exposed Java word-boundary behavior for singular `pé`; `(?iuU)` preserves the intended Unicode unit comparison.
- Full disposable local PostgreSQL/Lucee integration suite could not start because the configured runtimes are not installed. No production database integration tests were substituted for it.
- Decision: preserve all historical audits and do not requeue historical rejections. Retrying only 43916 would require a separate deliberate queue intervention; source cleanup alone cannot supply missing event content for 43854/44883.
- Original credential and schedule configuration remain outside this patch; no commits or branch changes.
- Published both runtime files with verified original baselines and backup `/var/backups/business-rewrite-validation-20261015-_12lr2gx`; endpoint GET returned the expected 405 JSON and runtime hashes matched candidates.
- Confirmed the actual subsequent scheduled run in the authenticated Business history: event 48091 PT updated, 48090 PT rejected with numbers/distances/URLs codes, 48091 EN rejected with numbers/units/dates codes. This confirms the new per-item diagnostics and a successful write without triggering a new run.
- A separate live preview for 43916 was blocked before execution by the approval reviewer (external transmission). Asked for explicit approval; no workaround or new external call was made.
- Read-only SSH inspection of current sources then timed out twice. Used the authenticated event editor instead, without submitting forms. The new rejected candidates were not persisted by the existing audit design, so their exact differences cannot be reconstructed from the codes alone. No further validation relaxation or source edits were made.
