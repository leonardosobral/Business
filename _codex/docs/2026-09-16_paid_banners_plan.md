# Paid banners CPC — implementation plan

Spec: `_codex/docs/2026-09-16_paid_banners_design.md` (approved, including paid-first inventory).

## Global Constraints

- Paid BANNER uses the canonical Ads wallet, ledger, immutable delivery price, budget, holds, replay protection and refunds. HOUSE stays free, unchanged and admin-only.
- Paid eligible banners precede HOUSE. No paid candidate means HOUSE fallback; errors must never relabel paid as HOUSE.
- BANNER has no event. EVENT authorization, ranking and two listing spots remain unchanged.
- Account roles OWNER/ADMIN/OPERADOR manage their account only; VISUALIZADOR reads only; real global admin reviews. Pending new account may prepare but not serve. Pending membership in an existing account does not grant access.
- Save/submit atomic; new or edited content needs current approval. Stale review cannot activate a newer version.
- Migration changes only ads objects and never writes public. No production migration or real campaign activation during development.
- Preserve all existing dirty changes. No commit, branch, tag, push or PR authorized. Work in place with scoped before snapshots; review added files/full scoped diffs, not unrelated HEAD diff. Keep audit artifacts because there will be no commit history for this task.
- Production publication is authorized only after checks, production baseline comparison, recoverable backup and real verification. Database deployment remains operator-controlled. Feature must remain off until dependencies verified.
- Implementers must not spawn subagents. Use apply_patch for source edits. Test first with real PostgreSQL finance contracts, not mocked debit behavior.

## Task 1: Database product, review and finance contract

Own only new files in RoadRunners `_codex/sql/2026-09-16_ads_paid_banners*.sql`, Business `_codex/scripts/test_ads_paid_banners.mjs`, optional fixture helper under Business `_codex/tests/paid-banner-*`, and your report. Do not edit runtime, existing migrations, or other files.

Implement an additive idempotent migration and behavioral contract suite for CPC BANNER. Start with a failing contract in a fresh socket-only local PostgreSQL (reuse approach, not fake finance, from `_codex/scripts/test_ads_house_banner_scope.mjs`). Load actual current function definitions from existing migrations and preserve September billing/review corrections. Do not connect to or mutate production. Read related AGENTS and spec. If baseline cannot be reconstructed safely, report exact missing dependency rather than weaken assertions.

The migration must enforce full lifecycle: authorized account save, submit, latest-version global review, pause/edit invalidating approval, activation only approved eligible content; scope and creative validation; shared canonical CPC charging/viewability/token contracts; constraints allowing BANNER CPC but no fake event; paid selector using regional specificity and bid with canonical auction price and locked serving revalidation. Existing EVENT/HOUSE flows must regress cleanly. Only ads schema changes, owner ads_owner, definer search_path pg_catalog, least execute grants and no runtime table DML. Guard deployed function replacements against drift; reexecution must not overwrite unexpected future code.

Public API for Business:
`ads.save_paid_banner_campaign(p_campaign_id uuid, p_account_id bigint, p_actor_id integer, p_values jsonb, p_submit boolean DEFAULT false)` returning `campaign_id uuid, advertisement_id uuid, creative_id uuid, placement_id uuid, campaign_status text, review_status text, campaign_review_request_id bigint`.
`p_values` keys: name, placement_key (only existing responsive placement), image_url_desktop, width_desktop, height_desktop, image_url_mobile, width_mobile, height_mobile, alt_text, destination_url (public HTTPS), open_new_tab boolean, starts_at, ends_at (ISO timestamptz), cpc_bid, budget_total, budget_daily (nullable), target_device (ALL/DESKTOP/MOBILE), banner_scope_v1 (existing normalized regions/pages contract). Reject unknown/invalid security-critical enums. No account/actor from JSON. Return review status NONE for draft. Use existing generic prepare_campaign_for_edit/change_campaign_status only if they remain safe for banners; define `submit_paid_banner_review(uuid,bigint,int)` and `review_paid_banner_campaign(uuid,text,int,text,text,bigint)` as specialized public adapters where preserving EVENT semantics requires separation. Review result shape must be documented in report before UI work.

Public API for delivery:
`ads.select_paid_banner_candidate(text,timestamptz,text,character,text,text)` with same argument order and returned fields as `select_house_banner_candidate` (placement,time,device,country,region,page), plus CPC immutable price where needed. `serve_delivery`, `record_cpc_viewable`, `charge_cpc_click_token` remain canonical interfaces. Reuse canonical charge lock order and refund pathway, not a second ledger implementation. Report exact signatures and any necessary consumers.

Tests: create/edit own vs foreign/read-only; invalid URL/scope; HOUSE unchanged; no EVENT fake/null regression; atomic failed submit; pending account cannot serve; reviewed revision staleness/edit; paid-first eligibility contract including SC vs BA/unknown region/pages; bid cap/floor; immutable token price; replay one debit; mixed EVENT+BANNER shared wallet concurrent low balance; budget total/daily/holds; refund idempotency; migration rerun and drift rejection. Capture RED/GREEN and commands. Scope can be split into migration parts if needed, keep public API above stable and report sequencing.

## Task 2: Business banner workspace

After Task 1 review, implement separate paid workspace includes under portal/includes/paid_banner*, route it through /portal/banners/, preserving explicit admin HOUSE view. Reuse ads/includes/access.cfm, CSRF and validated upload helpers. Add account Banners navigation; default submit and secondary draft, review/edit flows, shared wallet links, summary/detail dashboard with type-specific metrics. Keep prior HOUSE dashboard unchanged. Add boundary/render tests and compile CFML. Consume Task 1 exact APIs, never DML financial tables. Account filters mandatory on every read/write, actor from authenticated profile. No production test mutations.

## Task 3: RoadRunners paid-first delivery

After database contract review, extend AdsV1BannerDeliveryService and banner renderer/config/endpoints for gated BANNER CPC while preserving HOUSE fallback and event paths. Gate isolated per environment defaults false. Use specialized paid selector before HOUSE, canonical serving/receipt/click/viewable endpoints, stored destination and price. No paid-as-HOUSE fallback. Add executable service/endpoint/tracker regression tests and desktop/mobile checks.

## Task 4: Integration, independent review, migration handoff and publication

Run all focused SQL, CFML and JS regressions; independently review auth, financial concurrency, delivery and runtime boundaries. Assemble scoped deployment manifest with preexisting changes preserved, production baseline/backup and CF compile. Give operator migration and contract scripts; do not publish an enabled incomplete financial feature. If DB dependency missing, persist all progress and explain the precise operator step. After verified migration publish authorized runtime and verify real pages without charging clicks, activating or creating real campaigns. Record evidence and rollback flag.
