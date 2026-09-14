# Event description translations — implementation plan

User approved on 14/09/2026 the design discussed in this task: publish EN/ES
descriptions in two columns on the event table, preserve the original and PT,
keep processing history separate, and leave the general event cache view alone.

## Scope and interfaces

- Business owns AI generation, factual checks, queue selection and audit writes.
- RoadRunners renders the published description for `REQUEST.lang`.
- Add nullable `descricao_en text` and `descricao_es text` to
  `public.tb_evento_corridas`; do not replace or expand `vw_evento_corridas`.
  Production verification established that the site's `runner` role cannot
  read the Business audit tables. Therefore a small nullable
  `descricao_traducoes_meta jsonb` also stores source/target version hashes by
  language. Publish this alongside the target text in the same conditional
  update; preserve the other language's metadata. This allows stale/manual
  detection entirely within the event row, without grants or audit joins in
  the site. The user was informed during implementation.
- `EventDescriptionRewriteService.translate(source, language, apiKey, model)`
  accepts en/es and returns `{text,html,model,language}`. Existing rewrite and
  Validation/Provider exceptions remain compatible.
- The existing signed endpoint processes one language task per request within
  its current timeout; default language auto completes PT/EN/ES, optional
  language restricts execution. Keep the active one-minute schedule.
- Separate translation audit tracks source PT text/hash, language, before/after,
  outcome, provider attempts and times. Protect source and destination edits
  using compare-and-set. Reuse previously validated output when source returns
  to a previous version. Never overwrite an unrecognized human translation.
- Translate existing PT descriptions as well as newly rewritten events.
- Retry transient translation provider failures after 5 and 30 minutes, at most
  three failed provider attempts per source/language. Semantic rejection is
  terminal for that version; all other languages and events can continue.
- The page identifies PT fallback while translation is unavailable, and does
  not present an obsolete machine translation as current. Existing translated
  meta-description/JSON-LD phrases remain; localize residual title labels.
- No new language routes, schema permissions, credentials, services or git
  operations. Preserve changes of the concurrent SEO effort.

## Work and verification

- [x] Service: CFML tests for EN/ES success, language verification, factual
  rejection, malicious source, output truncation, HTML and provider failures.
- [x] Queue/schema: real temporary PostgreSQL+CFML tests for all three tasks,
  source changes, missing targets, A→B→A reuse, manual edits, NULL preservation,
  atomic rollback, concurrent lock, bounded retry and dry-run without writes.
- [x] Website: localized selection/rendering tests; inspect desktop/mobile
  real event pages in all three languages after deployment.
- [x] Operations: show pending/rejected/error counts by language in authenticated
  Business monitoring without AI calls or event mutation.
- [x] Capture production baseline, preserve private recoverable backups, pause
  only job15 for the brief migration/deployment window, apply additive schema,
  Adobe-compile initial staged runtime, publish only task files after hash checks.
- [x] Recover the initial site-only incident through guarded rollback; reproduce
  the CFQUERY quote-escaping failure, fix the interpolation boundary, execute
  the full real qEvento query on Adobe for EN/ES/PT, and republish the corrected
  site at 14:29:34 UTC on 14/09/2026.
- [x] Verify real dry-run (no writes), EN/ES writes (only intended fields),
  repeated execution without another translation, rendered pages and active
  one-minute schedule. Restore job's previous body/active setting except for
  the approved new default automatic language processing.
- [x] Record runtime hashes, test evidence, residual limitations and rollback.
- [x] Confirm final complete runtime compilation/hashes and endpoint public
  authentication checks: Adobe 13/13 from verified production copies, GET 405
  and unsigned POST 401.
- [x] Confirm continued processing after the automatic ES rejection for event
  34737 and remove temporary diagnostic routes.

Evidence through the successful continued run at 11:35:10 BRT and the final
receipt at 14:35:57 UTC is recorded in
`_codex/docs/2026-09-14_event_description_translations_publicacao.md`.
All delivery verification and cleanup items are complete. The active queue is
still processing; this is not a claim that every description has been translated.
The existing scheduler waits one configured minute after completion and checks
on minute ticks, producing an observed cadence of approximately two minutes.
Its central implementation was not changed in this task.

The previous design approval authorizes implementation and publication; no
additional approval gate, commits, branches or PRs are requested.
