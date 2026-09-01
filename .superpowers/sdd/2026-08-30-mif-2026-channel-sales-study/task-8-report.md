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
- GREEN: 8/8 focused Node tests pass. Country, state, city, product, and per-channel state rankings are sorted by the displayed primary measure, retain the top 10 categories plus one recomputed `Outros` bucket, resolve ties deterministically, and consolidate a pre-existing `Outros` without duplication.
- Canonical event chart rows are bounded from 21 countries, 29 states, 1,039 cities, and 20 products to 11 displayed buckets each; all totals reconcile. Across 83 full-channel state datasets, 19 require Top 10 + `Outros` and all preserve their original total.
- Source inspectors and paginated tables continue to receive every reviewed row. Ranking descriptions visibly disclose `Top 10 + Outros` and the full source category count. Weekly charts remain chronological; 8 lots and 5 modalities use explicit business order without grouping or truncation.
- Complete post-fix Python suite: 124/124 passing.

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

- Canonical CLI `verify`: passed with `status=ready`, 31 stable queries, exact receipt reconstruction, exact additive reconciliation, anonymity, and neutral-language gates.
- Notebook: executed against fresh external sources; 5/5 code cells, zero errors, bounded aggregate-only outputs, and no persisted raw/PII/development markers.
- Official prebuilt Data App build: passed.
- Protected runtime: 140 files verified.
- Theme: byte-identical to installed `codex-classic`; SHA-256 `d6885cb4e6cd5201935773f47148888bcd634e9cc13df9951803a7beacac25f2`.
- Runtime SHA-256: `bce021364672c86cb27997c683af6351677752ff905dc8c7cdc96d06ece8dc00`.
- Compiler SHA-256: `ec65601079c80bef7210f2c9760ff7f2db6adef28516ffff280d4c86f91d4078`.
- Snapshot SHA-256 at build: `b1dd79b60179a7c5cd1b43bf48682ca16ee07e3225472cfae9e438b16d87e0af`.
- Sanitized `dist/index.html` SHA-256: `123466c05b4578360e45d30b2ea8dd83898106c7ae8c9341ecd6ffab2a899904`.
- Sanitized `dist/shareable.html` SHA-256: `dc9fe5a5ff3bfa793a2a783debef509bd4c4fdcf05ca9f14a0e5d0c2829a56ef`.
- Programmatic report-content QA: Corre Criciúma, Sports Week, PCD, and Benefício present; 73 compact channels; required grains/bases/coverage/limitations present; no local thread identity; no automatic decision language in the ready copy.
- `git diff --check`: passed.
- Desktop/mobile/print visual QA remains an explicit controller handoff; inspect the four event rankings, at least one grouped and one ungrouped channel-state chart, source-table pagination, and the lot/modality order in the final shareable build.

The copied template's repository-wide Node test sweep is not an artifact gate and was not made runnable by installing dependencies: it requires local React/Vite modules and plugin-repository example assets that are absent from this checkout. The official builder, protected-runtime verifier, authored-copy behavior test, canonical data verifier, and full MIF suite are the applicable green gates. Broad desktop/mobile/print browser QA remains with the controller per the Task 8 handoff.
