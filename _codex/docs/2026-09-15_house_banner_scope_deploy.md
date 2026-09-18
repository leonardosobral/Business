# HOUSE banners — release handoff

Status: **PUBLISHED AND VERIFIED — 2026-09-16**. Migration committed in production; 16 runtime files published with backup/baseline guards. Avaí HOUSE is ACTIVE, limited to SC. Other banners retain their prior scope and status.

## Production execution evidence — 2026-09-16

- Existing authenticated DataGrip RunnerHub connection, `runnerhub` / `runner_dba`: opened the exact reviewed SQL file and executed its complete transaction. Output records successful COMMIT at 07:54:09. A separate console_6 SELECT confirmed the migration registry row plus EXECUTE for ads_delivery (selector) and ads_business (save v2), all true. No public-schema writes or campaign data edits in this migration.
- Scoped publisher `publish` and subsequent `verify` both returned phase `published`, directory `/var/backups/house-banner-scope.a69ce55fa8f3`, guard_count 111. Native compilation was 15/15. No unrelated files or git state published.
- Real Business UI: paused only Avaí `28c3eb44-60ec-4745-9128-25969c4172ba`, opened Edit, selected states. An empty selection was blocked with `Selecione pelo menos uma opção.` Selected only SC and saved through the native multipart form; success message and scope summary confirmed. Reactivated that same banner. Existing desktop/mobile files were retained; no image replacement or new test banner was created.
- Avaí remains ACTIVE with `{ "pages": [], "regions": ["SC"], "pages_mode": "ALL", "regions_mode": "SELECTED" }`. Dates remain 2026-09-01 20:26 UTC to 2026-09-20 20:26 UTC, destination remains Movnow, desktop1200x1200/mobile720x350 metadata, weight1/priority1 and new-tab setting preserved.
- Read-only before/after HOUSE query: all six other HOUSE campaign rows (including the hidden paused pilot) retain absent scope metadata and previous status/start/end. The five other banners shown in Business remain unrestricted; paused/expired ones were not activated.
- Production `ads.banner_scope_matches` against saved campaign metadata: Avaí SC/home=true, SP/home=false, unknown-UF/home=false; all other HOUSE rows true for those scope contexts. This verifies targeting, not complete eligibility of paused/expired rows.
- Live RoadRunners desktop home in SC context rendered the Avaí image successfully; visually inspected its banner in the sidebar. State selector → São Paulo rendered unrestricted Mizuno Neo Vista 3 instead. At390px, reloading that SP page rendered the responsive Mizuno banner visibly. No ad link was clicked and no synthetic click/viewability endpoint was invoked.
- New Business form visually checked at1280px,820px,390px. UF grid fits mobile; page choices and period fit tablet; technical fields removed as planned. Temporary viewport override reset. Existing shell requires a reload after changing desktop/mobile breakpoint; checked each loaded breakpoint.
- New binary uploads were covered by automated CFML image/save tests (including GIF canvas/frame bounds); production test used edit-with-retained-images to avoid replacing the live user's assets or adding disposable production campaigns. Two optional DOM geometry reads timed out in the browser adapter; screenshots verified the UI instead.

Rollback remains the guarded runtime rollback command below. Protective SQL remains installed. Avaí scope restoration, if explicitly requested, is through its administrative pause/edit/reactivate flow; no other banners need data rollback.

## Scope

- Business: simplified form (Content / Where / Period), automatic image dimensions, accessible description, advanced defaults, page/UF scope, edit preservation and scoped upload cleanup.
- RoadRunners: HOUSE selector and locked delivery scope enforcement, source page/UF carried through desktop/mobile/AJAX. No CPC ranking, financial history or authentication changes.
- SQL: `../RoadRunners/_codex/sql/2026-09-15_ads_house_banner_scope.sql`, ads schema contracts only. SHA-256 `414173032c19b3d93217a2a0cbb9409e785870e727b381d23247f0c3dcfdc7c9`.

## Prepared release

- Manifest: `2026-09-15_house_banner_scope_release.json` (16 explicit runtime paths).
- Receipt: `2026-09-15_house_banner_scope_prepare_v2.json` (supersedes the first preparation after GIF review fix).
- Server private folder: `/var/backups/house-banner-scope.a69ce55fa8f3`. Prior `bc9cded2788c` remains private and was never published; do not use its obsolete receipt.
- Guarded prepare phase passed; 111 protected files checked; recoverable original files saved by publisher.
- Native Adobe compiler result: `successful 15`, `total 15`, exit 0. This was private compilation, not publication or a browser test.
- Two production sidebar files differ from checkout for unrelated layout changes. Candidates in the plan's SDD workspace retain their production layout and add only this task's six context lines. Do not replace them with stale local full files.

## Evidence

- PostgreSQL isolated canonical contracts: scope/save/selection/legacy/permissions, incompatible baseline atomic rejection, HOUSE no debit, EVENT auction and financial contracts passed. Migration applied twice locally. Production pg_proc source hashes matched preconditions at preflight.
- Parent fresh CFML checks: form/render/image decoding, region/page context, service selection/receipt contract and save lifecycle passed. Security regression passed 76 checks / 0 failures when run serially. An earlier concurrent shared-CommandBox run failed temporary-directory cleanup; serial rerun passed.
- Node UI + HTTPS + CF symbol regression: 6 tests / 0 failures.
- Publisher packaging: 3 tests passed; existing guarded publisher: 15 tests passed.
- Task 1 review approved. Task 2 approved after GIF canvas/frame regression correction (parent fresh GREEN verified). Final integration review approved, no Critical/Important findings; only nonblocking fixed-delay concurrency-test observation. Full reports in `.superpowers/sdd/2026-09-15_house_banner_scope_plan/`.

## Execution checklist (completed)

1. Independent code review completed. Any later candidate change requires regenerating manifest and a new prepare receipt/compile. Never edit a prepared payload.
2. Once Mac is unlocked, apply the reviewed migration on existing authenticated DataGrip connection, own console_6 (do not touch user's console_4). Verify transaction commit, ads.schema_migrations row and new function signatures/EXECUTE permissions. No credential discovery, new grant, or alternate access bypass.
3. Use scoped publisher `publish` against this manifest/receipt, rechecking all before-hashes. RoadRunners files precede Business. Never publish before database readiness.
4. Verify published hashes and real Business UI at 390/820/1280px; reset viewport afterwards. Exercise selection validation and edit preservation. Do not create artificial CPC clicks or viewability beacons.
5. Edit only HOUSE campaign `28c3eb44-60ec-4745-9128-25969c4172ba` (`Avai`, account 1). It was ACTIVE; pause, save scope regions SELECTED [SC] and pages ALL [], then reactivate. Preserve assets, target, dates, priority/weight and original status. Verify saved scope; leave all other banners untouched/unrestricted, including paused banners.
6. Confirm read-only eligibility for SC versus SP and unknown UF and page scope. Distinguish eligibility from actual on-screen impression; test actual rendering when available.

## Commands

From Business, only after migration and review gates:

```sh
python3 _codex/scripts/deploy_house_banner_scope.py publish _codex/docs/2026-09-15_house_banner_scope_release.json _codex/docs/2026-09-15_house_banner_scope_prepare_v2.json
python3 _codex/scripts/deploy_house_banner_scope.py verify _codex/docs/2026-09-15_house_banner_scope_release.json _codex/docs/2026-09-15_house_banner_scope_prepare_v2.json
```

If runtime rollback is required, use the same tool with `rollback`; it refuses drift and restores only its own targets from validated backups. Leave protective ads SQL installed. No commit, branch, push or PR is authorized/performed.

Retain this plan's SDD workspace: it contains production-aware release candidates and review evidence, and there are intentionally no commits from which to reconstruct it.
