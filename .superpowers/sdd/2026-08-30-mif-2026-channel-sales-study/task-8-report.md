# Task 8 report — fresh MIF 2026 channel study

## Outcome

Task 8 converted the canonical MIF 2026 Data App from the development fixture to a final fresh snapshot with `status=ready`. The production pipeline now treats fixture and ready provenance deterministically, parses the real TicketSports product schema, uses the extraction-contract order date when participant sale dates are absent, and publishes only anonymous aggregate outputs.

The independent-review fix wave also made verification recompute every commercial money component and both tickets from exact paid bases, restricted commercial product conclusions to paid registrations, and introduced chart-only Top 10 + `Outros` rankings while preserving complete source tables and explicit temporal/operational orders.

The work stayed on `main`, preserved the unrelated result-import changes, left `/inscricoes/` unchanged, retained the external raw exports outside git, and did not publish the app.

## Fresh-source receipts

| Source | Rows | Extracted at (UTC) | SHA-256 |
| --- | ---: | --- | --- |
| orders_72611.csv | 14,886 | 2026-08-31T23:55:57+00:00 | `4d96ecff8174022ba6dade37babf7cc227075f6649371056c92402346a2a0f62` |
| participants_72611.csv | 16,634 | 2026-08-31T23:56:00+00:00 | `119d7e1573f2daa114f080283ba64f155884df5fd746eb06ee73d3329b35146a` |

Both receipts identify event `72611`. No source rows, JSON bodies, direct identifiers, credentials, or raw facts were printed or persisted in the reviewed artifacts.

## Reviewed mappings

- Channel mapping: 1,002 exact coupon title/code pairs consolidated into 155 mapped channels, plus the organic channel assigned explicitly in code.
- Special classifications retained: Corre Criciúma as `assessoria`, Sports Week as `evento_acao`, PCD as `politica`, and Benefício as `beneficio`.
- Product mapping: 33 exact source identities consolidated into 20 canonical products.
- Paid commercial product totals: 15,945 `kit_incluso` and 3,290 `adicional` items linked to paid registrations.
- The larger all-source mapping inventory (16,881 `kit_incluso` and 3,489 `adicional`) is useful only to prove source-identity coverage; it includes unpaid rows and is not used as a commercial conclusion.
- Product revenue is unavailable because no explicit unit or total values were supplied; no price was inferred from product names.
- Registration join, channel mapping, and product mapping coverage are each 100%.

## TDD evidence

### Real product schema

- RED: 3 focused parser tests failed because the real items use normalized `ID_Produto` plus one dynamic product-name key.
- GREEN: 19 focused parser tests passed after explicit alias handling, single-dynamic-key fallback, null-ID handling, raw-key preservation, and fail-closed zero/multiple candidate behavior.
- Phase A cumulative MIF suite: 112/112 passing.

### Ready snapshot and final provenance

- RED: 2 focused failures and 1 error exposed fixture-only status, qualification, and visible copy in the fresh flow.
- GREEN: 27 focused artifact/pipeline tests passed with deterministic `fixture`/`ready` status, exact reconstructed provenance, dynamic source qualifications, and final authored copy.

### Fresh temporal evidence

- Initial fresh `verify` failed the weekly-sales semantic reconciliation because participant sale/registration dates are entirely absent and the body date was not the reliable extraction date.
- RED: 3 focused date/fallback tests failed.
- GREEN: 61 normalize/facts/metrics tests passed after strict ISO datetime support, precedence for the outer `data_pedido` extraction-contract column, and documented registration-to-order date fallback.

### Final mapping regressions

- RED: the first complete 117-test run had 1 failure and 2 errors because legacy tests loaded the new final CSVs while asserting synthetic seed identities/reasons.
- GREEN: those invariants were isolated in local fixtures without changing reviewed mapping decisions; mapping tests passed 10/10 and the complete MIF suite passed 117/117.

### Independent financial verification and paid-only conclusions

- RED: tamper probes showed that changing both sides of discount, fee, net-transfer, or cashback receipts could bypass the former gross-only verifier; ticket mutations, false availability, invalid-date fallback, and a missing paid-order discount also failed their new contracts.
- GREEN: `verify` now independently reconstructs paid-order and allocated-registration totals for every money component, applies explicit-zero versus unavailable rules, recomputes order and registration tickets from exact paid bases, and checks the duplicated quality receipt before accepting the snapshot.
- Missing discount is explicitly allocated as zero only when absent; invalid money remains invalid. Optional fee, net transfer, and cashback remain unavailable unless the paid-order field is fully valid. Invalid participant dates no longer fall back to order date; only `nao_informado` does.
- The final Corre Criciúma regression reads the versioned mapping CSV and proves its two reviewed aliases consolidate to 23 paid registrations while synthetic mapping tests remain isolated.
- Ready report copy and notebook conclusions now state the paid-only commercial product totals: 15,945 kit items and 3,290 additional items.

### Chart-only rankings and operational order

- RED: the focused Node behavior suite first failed because the report had no reusable chart-row preparation contract; the operational-order extension then failed on missing explicit lot/modality ordering.
- GREEN: 8/8 focused Node tests pass. Country, state, city, product, and per-channel state rankings keep the ten individual categories sorted by the displayed primary measure, append one recomputed `Outros` bucket, resolve leader ties deterministically, and consolidate a pre-existing `Outros` without duplication.
- Canonical event chart rows are bounded from 21 countries, 29 states, 1,039 cities, and 20 products to 11 displayed buckets each; all totals reconcile. Across 83 full-channel state datasets, 19 require Top 10 + `Outros` and all preserve their original total.
- Source inspectors and paginated tables continue to receive every reviewed row. Ranking descriptions visibly disclose `Top 10 + Outros` and the full source category count. Weekly charts remain chronological; 8 lots and 5 modalities use explicit business order without grouping or truncation.
- Complete post-fix Python suite: 124/124 passing.

### Controller visual-QA regression

- RED: after the first controller render, 4 of 8 focused Node tests reproduced that the aggregate `Outros` bucket was being sorted back among the ten individual leaders; the ready-snapshot assertion also exposed the same ordering in the canonical event and channel-state charts.
- GREEN: the minimal fix removes only the redundant second sort. The ten individual categories retain descending order and deterministic tie-breaking, while the recomputed `Outros` bucket is always the final chart row regardless of its aggregate magnitude. The visible `Top 10 + Outros` description and complete paginated source rows are unchanged.
- Verification after the visual-QA fix: 8/8 focused Node tests, 124/124 MIF tests, official build, sanitized shareable, 140 protected runtime files, and byte-identical theme all passed.

### Product `Outros` distinct-union correction

- RED: the final independent review reconstructed the deterministic paid-product tail from facts and proved that summing per-product distinct registrations overstated the chart bucket as 781; overlapping registrations across tail products reduce the union to 644.
- GREEN: the paid fact pipeline now publishes a chart-only anonymous receipt for the exact tail: 781 summed category registrations, 644 distinct registrations across their union, 781 additive product units, a 15,713 paid-registration denominator, a 4.10% take rate, and an aggregate multiplicity distribution that reconciles the union without serializing identifiers. The JavaScript transformation validates this receipt before rendering and fails closed if it is absent or inconsistent.
- The complete 20-row `product_summary` evidence table is unchanged. Only the chart aggregate uses the non-additive distinct union; `product_quantity` remains additive, and `Outros` remains fixed after the ten individually ranked products.
- Canonical verification independently checks the ranked tail identities, source-category counts, per-category sum, distinct union, product-unit sum, denominator, rate, and aggregation rule against the fresh paid facts.
- Verification after the correction: 8/8 focused Node tests, 127/127 MIF tests, canonical `verify`, fresh notebook execution, official build, sanitized shareable, 140 protected runtime files, and byte-identical theme all passed.

### Executive narratives and ROADRUNNERS capstone

- RED: focused Python and Node regressions failed because full dossiers still used generic UI copy, compact channels had no executive highlight, the snapshot exposed only 31 queries, and the report had no source-backed ROADRUNNERS conclusion.
- GREEN: the analysis layer now generates six deterministic evidence blocks for every one of the 83 full dossiers: scale/value, geography, modality, timing, products, and dimension-specific similarity. Missing denominators or coverage fail closed; city and product claims respect the small-cell boundary; PCD and Benefício retain their mechanism/policy qualification.
- All 73 compact channels now carry an evidence-bound `executive_highlight` with paid base, ticket, supported leading modality/UF, and an adjacent small-sample warning. The full table evidence remains unchanged.
- The 32nd aggregate query, `roadrunners_capstone`, feeds both the visible answer-first summary and the final `ROADRUNNERS — leitura estratégica do canal próprio` section. The canonical verifier reconstructs its numbers and every generated narrative from the independent aggregate evidence and rejects coherent prose/receipt tampering.
- ROADRUNNERS reconciles as the first coupon channel by paid registrations: 1,876 paid registrations, 11.94% of the event, 23.16% of coupon-assisted registrations, R$ 545,290.12 allocated gross (12.62% of event gross), and R$ 290.67 ticket versus R$ 275.05 for the event (+5.68%). The capstone also records 82.35% in 21K+42K versus 79.11% (+3.24 pp), 27 observed UFs with 93.23% valid coverage, SP +4.72 pp, SC -8.70 pp, the 2026-06-08 peak week with 87 registrations, and separate organic similarities of 0.8891 geography, 0.9672 modality, and 0.9438 products.
- The JSX consumes only generated `executive_summary`, `executive_highlight`, and `capstone_markdown` fields. A visible executive summary follows the report title, and the ROADRUNNERS capstone follows the decision questions before methodology. No combined evaluation or automatic channel action was added.
- Final audit RED/GREEN: a mixed-case country fixture reproduced that `BRASIL` could be counted as foreign and label a domestic channel as international. Country identity is now normalized before the foreign-share test; the fresh aggregate contains one genuinely majority-external scope and zero international labels inconsistent with the measured proportion.
- Verification for this enhancement: 131/131 MIF Python tests, 11/11 focused MIF Node tests, canonical `verify`, fresh notebook execution (5/5 cells, 32 queries), official build, sanitized shareable, and 140 protected runtime files all passed.

### Commercial reading order and narrative QA polish

- RED: focused behavior tests proved that the canonical index, full dossiers, and compact channels still followed name order; a numeric-vs.-lexicographic money fixture, tied values, and an organic-channel fixture all failed the approved commercial order. A coherent index reorder also bypassed semantic verification and failed later only as a provenance mismatch.
- GREEN: `channel_index` now uses exact decimal `gross_value` descending, then paid registrations descending, then normalized deterministic channel name. Full dossier rendering follows the filtered index exactly. `long_tail` retains allocated `gross_value`, uses the same order, and exposes `Valor bruto (R$)` in the visible table. The alias audit remains complete and grouped by channel/coupon rather than inheriting gross order. Canonical verification independently reconstructs order, dossier parity, compact parity, and compact gross values.
- Narrative RED/GREEN: generated-copy regressions reproduced ungrouped reader counts, ISO dates, English overlap labels, an unbounded 71-alias PCD paragraph, singular `1 inscrições`, and first-row rather than highest-adoption product selection. Reader-facing output now uses pt-BR thousands/percentages/dates, translated dimension labels, top-three bounded alias evidence plus an explicit remainder, correct singular/plural, and the leading additional by paid registrations with deterministic ties. The complete alias and product tables remain untouched.
- Fresh aggregate checks confirm ROADRUNNERS uses `Camiseta FINISHER Maratona de Floripa` at 114/1,876 as its leading additional, Sports Week uses `Gravação de medalha` at 69/949, PCD keeps the deterministic 2/71 leader and summarizes 71 aliases as three visible identities plus 68 more, and Corre Criciúma still shows both reviewed identities.
- Final verification for this wave: 137/137 MIF Python tests, 13/13 focused MIF Node tests, canonical `verify`, fresh notebook execution (5/5 cells, zero errors, 32 queries), official Data App build, sanitized shareable, and 140 protected runtime files all passed.

## Final commercial headlines

| Metric | Final value |
| --- | ---: |
| Paid orders | 14,027 |
| Paid registrations | 15,713 |
| Gross value | R$ 4,321,891.20 |
| Discounts | R$ 530,601.25 |
| Fees | R$ 372,816.27 |
| Net transfer | R$ 4,024,811.72 |
| Order ticket | R$ 308.11 |
| Registration ticket | R$ 275.05 |
| Registrations per order | 1.12 |
| Coupon-assisted registrations | 8,101 (51.56%) |
| Organic registrations | 7,612 (48.44%) |
| Full channel dossiers | 83 |
| Compact channels | 73 |

The report presents 156 channels when organic is included. Touched-order counts remain explicitly non-additive between channels.

### Requested special channels

| Channel | Type | Paid registrations | Touched paid orders | Allocated gross | Registration ticket | Dossier |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Corre Criciúma | assessoria | 23 | 19 | R$ 6,189.97 | R$ 269.13 | full |
| Sports Week | evento_acao | 949 | 841 | R$ 233,215.78 | R$ 245.75 | full |
| PCD | politica | 71 | 71 | R$ 9,463.07 | R$ 133.28 | full |
| Benefício | beneficio | 30 | 30 | R$ 4,671.35 | R$ 155.71 | full |

These are descriptive observations, not automatic scores, rankings, or keep/cut recommendations.

## Quality and limitations

- `order_date`: 100% valid and used for the weekly timeline when a linked registration lacks participant dates.
- Participant `sale_date` and `registration_date`: 0% available; the fallback is explicit in source definitions and visible report copy.
- City coverage: 94.16%; state coverage: 94.25%; age answered for 100% of paid registrations, with 27 invalid ages kept visible in quality counts.
- Pace and club/assessoria source fields: 0% available, so they cannot support channel-profile claims.
- Payment date values are not usable in the exported body format; the timeline does not use them.
- Cashback is unavailable.
- Patrocínio, espaço de expo, permutas and the value of cortesias are not measured, attributed, or netted from channel evidence.

## Reproducibility and artifact checks

- Canonical CLI `verify`: passed with `status=ready`, 32 stable queries, exact receipt reconstruction, exact additive reconciliation, generated-narrative reconstruction, anonymity, and neutral-language gates.
- Notebook: executed against fresh external sources; 5/5 code cells, zero errors, bounded aggregate-only outputs, and no persisted raw/PII/development markers.
- Official prebuilt Data App build: passed.
- Protected runtime: 140 files verified.
- Theme: byte-identical to installed `codex-classic`; SHA-256 `d6885cb4e6cd5201935773f47148888bcd634e9cc13df9951803a7beacac25f2`.
- Runtime SHA-256: `bce021364672c86cb27997c683af6351677752ff905dc8c7cdc96d06ece8dc00`.
- Compiler SHA-256: `ec65601079c80bef7210f2c9760ff7f2db6adef28516ffff280d4c86f91d4078`.
- Snapshot SHA-256 at build: `3e6e240fa6779b278e60b35a98be4805320a1fae4baf4f78afdffd95634789d2`.
- Aggregate receipt SHA-256: `590fd27839b20bb2c7cf3a1e844cd570fa2b0de63e9d883ffe1cc49b1cb92e46`.
- Source-notes SHA-256: `07d97ff72f3d9a3364d732a820a9a141a4e98f62068555c0a4305db42d6e2983`.
- Normalized `dist/index.html` SHA-256: `eea39a306c31ecd8532ad266900f53558c97b9d91d8afac66b729a866cf050d4`.
- Sanitized `dist/shareable.html` SHA-256: `30b3bda257143b2762a2e0a428512854ede325f0200b6a91b1a2c3220c1886ad`.
- Programmatic report-content QA: Corre Criciúma, Sports Week, PCD, Benefício, and ROADRUNNERS present; 83 generated full dossiers and 73 compact executive highlights; required grains/bases/coverage/limitations present; no local thread identity; no automatic decision language in the ready copy.
- `git diff --check`: passed.
- Desktop/mobile/print visual QA remains an explicit controller handoff; additionally inspect the value-ordered channel index/dossiers, the compact gross column, bounded PCD aliases, pt-BR narrative formatting, and the corrected additional-product highlights.

The copied template's repository-wide Node test sweep is not an artifact gate and was not made runnable by installing dependencies: it requires local React/Vite modules and plugin-repository example assets that are absent from this checkout. The official builder, protected-runtime verifier, authored-copy behavior test, canonical data verifier, and full MIF suite are the applicable green gates. Broad desktop/mobile/print browser QA remains with the controller per the Task 8 handoff.
