# Geolocation throughput Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline; the user approved implementation, tests and publication.

**Goal:** Restore autonomous useful progress without discarding confirmed locations or spending provider credits on repeated inputs.

**Architecture:** Keep the existing durable worker, reservations, strict evidence policies and destination compare-and-swap. Separate provider availability from municipal suggestions, retain partial progress and retry transient research with bounded backoff. Count persisted outcomes independently of the newest analysis state.

**Tech Stack:** Adobe ColdFusion 2025, PostgreSQL, existing Python source fetcher.

**Spec:** User-approved scope in this conversation, 22 October 2026; diagnostics in `_codex/tests/geocoding/optimization_diagnostic.cfm`.

## Global Constraints

- GPT-6 Astra and current credential unchanged; Geoapify 3,000/day and one request/second.
- No city suggestion becomes a canonical race or kit location.
- No destructive migration, permission change, Git write or unrelated deployment.
- Baseline-check production, recoverable backup, scoped atomic publication and real verification.

## Review Focus

- One failed source must not discard other readable official documents.
- AI cooldown must not prevent private municipal suggestions or cause more AI calls.
- A newer failed analysis must not erase the count of coordinates already filled.
- Scheduled retries must retain operator decisions and not starve fresh events.
- Cache reuse must invalidate when actual event identity or document text changes.

### Task 1: Queue and result semantics

Files: `services/geocoding/LocationStore.cfc`, native `optimization_store.cfm`.

- [x] RED: persisted coordinate count survives a newer failed analysis; field-only approval does not count; deferred items do not occupy ready capacity; scheduled retry is claimable only when due.
- [x] GREEN: `aiAvailability(limit)` is read-only; `seed` counts ready work; `claim` accepts explicitly scheduled incomplete research and bounded stale transient errors; `finish` persists backoff; `overview` counts current persisted locations using historical provenance.

### Task 2: Economical independent processing

Files: `AIClient.cfc`, `DocumentReader.cfc`, `Store.cfc`, `LocationWorker.cfc`; native optimization worker/cache fixtures.

- [x] RED: stable actual-input cache key, useful partial research, city fallback during cooldown, failed first event does not block a second, retry retains useful state.
- [x] GREEN: add stable extraction cache key; short-lived partial/failure document cache; process municipal fallback without source/AI calls during cooldown; continue per-event failures; preserve prior proposals and use bounded retry backoff.

### Task 3: Explain and publish

Files: geolocation view, scoped publication script/receipt, validation evidence.

- [x] Test native regression suite plus Radar, quota and access checks. No paid AI test during recorded credit exhaustion.
- [x] Show durable counter definition, separate deferred research from pending review and explain automatic retries.
- [x] Independent review, address important findings, then guarded publication and actual browser/DB verification.

## Execution ledger

- User explicitly approved implementation/testing/publication. Continue without another planning pause.
- Ruling: use existing checkout; project policy requires a user request for Git branch/commit and none was made. Test runtime copies are isolated and private.
- Read-only diagnostic: 35 events retained applied coordinates but were excluded by latest-status counters; latest 60 runs completed no event; Geoapify 24/3,000; recorded AI credit-exhaustion cooldown. These are snapshots, not a guaranteed historical reconstruction.
- Pre-flight: queue retry fields are existing columns; no schema change. Worker consumes the store's read-only availability and retry semantics. Test doubles must override availability to avoid dependence on live cooldown.
- Task 1 complete: native optimization_store RED (durable counter) then GREEN; scheduling and future-ready-capacity assertions passed.
- Task 2 complete: cache/worker RED then GREEN. Native ai_resume/provider_failure passed. Added temporary-source caching (5 minutes negative, 15 minutes useful partial) and input-exact seven-day extraction cache.
- Review: four Important findings reproduced RED together, then GREEN: stale trust, approved retry, exception retention and retry fairness. Independent follow-up reported no remaining Important/Critical findings.
- Ruling: preserve operator rejection but never restore stale trust/evidence over fresh validation. Unreconfirmed proposals become untrusted; prior confirmed destinations remain protected by CAS.
- Final verification: 39 native suites plus 11 Python reader tests passed. Six-file publication succeeded at 2026-10-22T12:52:41Z; backup `/var/backups/business-geocoding-sources-ca7px1e0`. Other-front menu and policy/config files hash-guarded and unchanged.
- Real browser verified: Preenchidos=95 with durable definition; Astra and quota unchanged; credit-exhaustion cooldown explicit. First real cron after publication processed 5 events in 1,625 ms with 4 cache hits, 1 Geoapify request and 0 AI calls. This validates municipal-stage progress, not renewed availability of the AI provider.
- Second real cron at 12:54:01Z processed 5 more events in 1,900 ms, again 4 cache hits / 1 Geoapify / 0 OpenAI. Read-only validation receipt checks 14 runtime/preserved file hashes; no Git writes were performed.
