# MIF 2026 Portfolio Decision Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight, PDF-ready portfolio report plus a controlled simulator for channel differentiation, multidimensional overlap, and observed coverage concentration.

**Architecture:** Extend the frozen modular pipeline with a focused `portfolio.py` transform that emits a small static summary and a separate simulator cube. Serve the artifacts through independent authenticated CFML pages, reuse the current report renderer and visual system, and keep scenario calculations in a portfolio-specific JavaScript module.

**Tech Stack:** Python 3, pandas, deterministic JSON, Node.js test runner, vanilla JavaScript, SVG/HTML, CSS, ColdFusion CFML.

**Spec:** `docs/superpowers/specs/2026-09-02-mif-2026-portfolio-decision-design.md`

## Global Constraints

- Work in the current checkout; do not create a git worktree.
- Never modify `/inscricoes/`; verify its checksum before and after deployment.
- Use only the frozen 2026 artifacts; do not query the database.
- Commercial views require `registration_ticket > 10.00`; complete-event totals remain unchanged.
- Organic is a denominator/reference and is never selectable for removal.
- Similarity remains separate by dimension; no opaque master score.
- Scenario copy says `cobertura em risco`, never `vendas perdidas`.
- Categorical charts use Top 10 + `Outros`, with `Outros` last.
- Product profiles exclude only `kit_incluso`.
- `portfolio/summary.json` stays below 750 KB; `portfolio/simulator.json` stays below 2 MB.
- All new pages and artifacts remain authenticated and anonymous.

---

### Task 1: Portfolio analytics contracts

**Files:**
- Create: `_codex/analyses/mif_2026_channels/portfolio.py`
- Create: `_codex/tests/mif_2026_channels/test_portfolio.py`

**Interfaces:**
- Consumes: overview, channel index rows, dossier payloads, registration cube, generation timestamp.
- Produces: `build_portfolio_artifacts(*, overview, channel_index, dossiers, registration_cube, generated_at) -> dict[str, dict]`.
- Produces helpers: `commercial_channels`, `nearest_peer_profiles`, `redundancy_candidates`, `coverage_cube`, `classify_exposure`.

- [ ] **Step 1: Write the failing universe and exposure tests**

```python
def test_commercial_universe_excludes_organic_and_ticket_boundary():
    rows = [
        {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "200.00"},
        {"channel_name": "Cortesia", "channel_type": "cortesia", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.00"},
        {"channel_name": "Sports Week", "channel_type": "parceiro", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.01"},
    ]
    assert [row["channel_name"] for row in commercial_channels(rows, selectable=True)] == ["Sports Week"]


def test_exposure_uses_event_and_partner_denominators():
    assert classify_exposure(selected=40, event_total=100, commercial_total=50) == "alta"
    assert classify_exposure(selected=20, event_total=100, commercial_total=50) == "média"
    assert classify_exposure(selected=12, event_total=100, commercial_total=20) == "dependência entre parceiros"
    assert classify_exposure(selected=4, event_total=5, commercial_total=4) is None
```

- [ ] **Step 2: Run RED**

```bash
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest _codex.tests.mif_2026_channels.test_portfolio -v
```

Expected: import failure because `portfolio.py` is absent.

- [ ] **Step 3: Implement the universe and exposure boundary**

```python
COMMERCIAL_TICKET_MIN = Decimal("10.00")
MIN_PROFILE_REGISTRATIONS = 10
MIN_DIMENSION_COVERAGE_PCT = Decimal("70.00")

def classify_exposure(*, selected, event_total, commercial_total):
    if selected < 5 or event_total <= 0:
        return None
    event_share = Decimal(selected) / Decimal(event_total) * 100
    partner_share = Decimal(selected) / Decimal(commercial_total) * 100 if commercial_total else Decimal("0")
    if selected >= 10 and event_share >= 40:
        return "alta"
    if selected >= 10 and event_share >= 20:
        return "média"
    if partner_share >= 60 and event_share < 20:
        return "dependência entre parceiros"
    return "baixa"
```

`commercial_channels(..., selectable=True)` additionally removes `channel_type == "organico"` and sorts by gross DESC, registrations DESC, canonical name.

- [ ] **Step 4: Write failing differentiation and redundancy tests**

```python
def test_nearest_peer_is_dimension_specific_and_requires_coverage():
    result = nearest_peer_profiles(similarity_fixture(), channel_index_fixture())
    assert result["ALFA"]["geography"]["nearest_channel"] == "BETA"
    assert result["ALFA"]["temporal"]["nearest_channel"] == "GAMA"
    assert result["ALFA"]["product"]["status"] == "evidência insuficiente"

def test_redundancy_requires_four_dimensions_including_geography_or_temporal():
    rows = redundancy_candidates(similarity_fixture(), channel_index_fixture())
    assert [(row["left_channel"], row["right_channel"]) for row in rows] == [("ALFA", "BETA")]
```

- [ ] **Step 5: Implement dimension-specific similarity**

```python
ACTIONABLE_DIMENSIONS = ("geography", "modality", "temporal", "lot", "product")

def pair_key(left, right):
    return tuple(sorted((str(left), str(right)), key=str.casefold))
```

Canonicalize A–B/B–A, require both coverages at least 70%, compute linear-interpolated p90 per dimension, and compute p25 over each channel's nearest-peer maximum. A redundancy candidate qualifies in at least four actionable dimensions and includes geography or temporal. Sort by qualifying-dimension count DESC, combined gross DESC, names.

- [ ] **Step 6: Write failing output-separation test**

```python
def test_static_summary_never_contains_simulator_cube():
    artifacts = build_portfolio_artifacts(**portfolio_fixture())
    assert "coverage_cube" not in artifacts["portfolio/summary.json"]
    assert artifacts["portfolio/simulator.json"]["dimensions"] == ["phase", "modality", "state", "channel_name"]
```

- [ ] **Step 7: Implement the outputs**

`summary.json` contains metadata, definitions, overview, dimension benchmarks, five dimension panels, Top 10 redundancy candidates, Top 10 dependency cells, and executive takeaways. `simulator.json` contains selectable channels, thresholds, and a projected cube at `phase × modality × state × channel_name`, plus `Todos os canais` and `Canais comerciais não orgânicos` totals per cell. Remove city and week; serialize money as fixed two-decimal strings.

- [ ] **Step 8: Run GREEN and commit**

```bash
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest _codex.tests.mif_2026_channels.test_portfolio -v
git add _codex/analyses/mif_2026_channels/portfolio.py _codex/tests/mif_2026_channels/test_portfolio.py
git commit -m "feat: add MIF portfolio analytics"
```

---

### Task 2: Modular artifacts and portable verification

**Files:**
- Modify: `_codex/analyses/mif_2026_channels/modular_artifact.py`
- Modify: `_codex/analyses/mif_2026_channels/run.py`
- Modify: `_codex/tests/mif_2026_channels/test_modular_artifact.py`

**Interfaces:**
- Consumes: `build_portfolio_artifacts` from Task 1.
- Produces: allowlisted, hashed portfolio artifacts with `PORTFOLIO_TRANSFORM_VERSION`.

- [ ] **Step 1: Add failing artifact-set and size tests**

```python
expected |= {"portfolio/summary.json", "portfolio/simulator.json"}
self.assertLess(manifest["artifacts"]["portfolio/summary.json"]["bytes"], 750_000)
self.assertLess(manifest["artifacts"]["portfolio/simulator.json"]["bytes"], 2_000_000)
self.assertNotIn("coverage_cube", artifacts["portfolio/summary.json"])
```

- [ ] **Step 2: Run RED**

Run `python -m unittest _codex.tests.mif_2026_channels.test_modular_artifact -v`; expect artifact-set mismatch.

- [ ] **Step 3: Integrate the artifact builder**

Build dossier payloads before the manifest, call `build_portfolio_artifacts`, and merge the two results. Route both exact portfolio paths through `expected_artifact_transform_version`; no wildcard portfolio paths are allowed.

- [ ] **Step 4: Extend `verify_modular_outputs`**

Verify summary overview equality, selectable slug uniqueness, ticket `> 10.00`, non-organic selection, simulator total equality, byte limits, and recursive absence of `numero_pedido`, `numero_inscricao`, `email`, `documento`, `cpf`, `city`, and `week_start`.

- [ ] **Step 5: Run focused and full Python suites**

```bash
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest _codex.tests.mif_2026_channels.test_portfolio _codex.tests.mif_2026_channels.test_modular_artifact -v
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py'
```

- [ ] **Step 6: Commit**

```bash
git add _codex/analyses/mif_2026_channels/portfolio.py _codex/analyses/mif_2026_channels/modular_artifact.py _codex/analyses/mif_2026_channels/run.py _codex/tests/mif_2026_channels/test_portfolio.py _codex/tests/mif_2026_channels/test_modular_artifact.py
git commit -m "feat: publish MIF portfolio artifacts"
```

---

### Task 3: Reproducible analytical audit

**Files:**
- Create: `_codex/analyses/mif_2026_channels/notebooks/mif_2026_portfolio_audit.ipynb`

**Interfaces:**
- Consumes: canonical `modular_dist/portfolio/summary.json` and `simulator.json`.
- Produces: saved, anonymous evidence for thresholds and decision outputs.

- [ ] **Step 1: Create the notebook with six executable cells**

Cells read the two JSON files and display: overview reconciliation; p25/p90 benchmarks; Top 10 redundancy pairs; dependency cells; ROADRUNNERS, SPORTS WEEK and PCD status; artifact sizes plus final assertions.

- [ ] **Step 2: Execute and verify**

Use the bundled Python/Jupyter runtime. The final cell asserts 14,027 paid orders, 15,713 paid registrations, gross `4321891.20`, summary below 750 KB, simulator below 2 MB, and absence of `kit_incluso`/PII keys.

- [ ] **Step 3: Commit**

```bash
git add _codex/analyses/mif_2026_channels/notebooks/mif_2026_portfolio_audit.ipynb
git commit -m "docs: audit MIF portfolio evidence"
```

---

### Task 4: Portfolio renderer and simulator engine

**Files:**
- Create: `relatorios/maratona-floripa-2026/assets/portfolio.js`
- Create: `_codex/tests/mif-report-portfolio.test.js`

**Interfaces:**
- Consumes: `MifReport`, summary payload, simulator payload.
- Produces: `MifPortfolio.renderSummary`, `simulate`, `renderSimulation`, `buildShareUrl`.

- [ ] **Step 1: Write failing simulator tests**

```javascript
test('simulation rejects invalid selections', () => {
  assert.throws(() => portfolio.simulate(data, ['missing']), /Canal desconhecido/);
  assert.throws(() => portfolio.simulate(data, Array.from({length: 11}, (_, i) => `c${i}`)), /até 10 canais/);
});

test('scenario remains descriptive', () => {
  const result = portfolio.simulate(data, ['sports-week']);
  assert.equal(result.cells[0].remaining_alternative, 'ROADRUNNERS');
  assert.doesNotMatch(JSON.stringify(result), /vendas perdidas|perda prevista/i);
});
```

- [ ] **Step 2: Run RED**

Run `node --test _codex/tests/mif-report-portfolio.test.js`; expect module-not-found.

- [ ] **Step 3: Implement deterministic simulation**

Aggregate by `phase\u0000modality\u0000state`, retain all selected totals, suppress detailed cells below five selected registrations, classify exposure using payload thresholds, find the largest remaining commercial channel per cell, and sort by exposure, selected registrations DESC, phase, modality, state.

- [ ] **Step 4: Write failing renderer tests**

Require six chapter IDs, five separate dimension panels, Top 10 redundancy/dependency outputs, CAPS channel names, Top 10 + `Outros`, `Pré-lançamento`, safe escaping, and the explicit non-causal method sentence.

- [ ] **Step 5: Implement renderers using shared primitives**

Reuse `MifReport.renderBarChart`, `renderMatrixChart`, `renderTable`, formatters, and escaping. Define:

```javascript
const SUMMARY_SECTIONS = ['portfolio-resumo', 'portfolio-diferenciacao', 'portfolio-redundancia', 'portfolio-dependencias', 'portfolio-simulador', 'portfolio-metodo'];
```

Simulation output includes four KPI cards, Top 10 states, distances and phases, then the full publishable-cell table.

- [ ] **Step 6: Run GREEN and commit**

```bash
node --test _codex/tests/mif-report-portfolio.test.js _codex/tests/mif-report-renderer.test.js
git add relatorios/maratona-floripa-2026/assets/portfolio.js _codex/tests/mif-report-portfolio.test.js
git commit -m "feat: add MIF portfolio renderer"
```

---

### Task 5: Static report and simulator pages

**Files:**
- Create: `relatorios/maratona-floripa-2026/portfolio/index.cfm`
- Create: `relatorios/maratona-floripa-2026/portfolio/simulador.cfm`
- Create: `relatorios/maratona-floripa-2026/assets/portfolio.css`
- Create: `_codex/tests/mif-report-portfolio-page.test.js`
- Create: `_codex/tests/mif-report-portfolio-simulator-page.test.js`
- Modify: `_codex/tests/mif-report-deployment-contract.test.js`

**Interfaces:**
- Static page consumes only `portfolio/summary.json`.
- Simulator consumes only `portfolio/simulator.json` and repeated URL parameters `canal=<slug>`.

- [ ] **Step 1: Write failing CFML contract tests**

Assert authentication precedes data access; the static page never mentions `simulator.json`; the simulator never loads summary, explorer or dossiers; both use escaped embedded JSON; actions include Análise geral, Dossiês, counterpart page and PDF.

- [ ] **Step 2: Run RED**

Run `node --test _codex/tests/mif-report-portfolio*-page.test.js _codex/tests/mif-report-deployment-contract.test.js`; expect missing pages.

- [ ] **Step 3: Implement the static page**

Follow the existing header, hero, chapter nav and JSON-escaping pattern. Call `MifPortfolio.renderSummary(document.getElementById('mif-portfolio-root'), payload)` and load only the shared report assets plus portfolio assets.

- [ ] **Step 4: Implement the simulator page**

Render a searchable gross-DESC checkbox list. Enforce 1–10 selections, restore with `URLSearchParams.getAll('canal')`, calculate client-side without form submission, replace the URL deterministically, and show a visible error for invalid slugs.

- [ ] **Step 5: Implement responsive/print CSS**

Add four-cell quadrants, dimension sections, pair evidence cards, selector layout, printable selected-channel receipt, visible mobile navigation, and `break-inside: avoid`. Do not duplicate global Run Pro tokens.

- [ ] **Step 6: Run page and renderer tests, then commit**

```bash
node --test _codex/tests/mif-report-portfolio*.test.js _codex/tests/mif-report-deployment-contract.test.js
git add relatorios/maratona-floripa-2026/portfolio relatorios/maratona-floripa-2026/assets/portfolio.css _codex/tests/mif-report-portfolio-page.test.js _codex/tests/mif-report-portfolio-simulator-page.test.js _codex/tests/mif-report-deployment-contract.test.js
git commit -m "feat: add MIF portfolio decision pages"
```

---

### Task 6: Navigation integration

**Files:**
- Modify: `relatorios/maratona-floripa-2026/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/canais/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/canais/dossie.cfm`
- Modify: `relatorios/maratona-floripa-2026/explorador/index.cfm`
- Modify: `_codex/tests/mif-report-general-contract.test.js`
- Modify: `_codex/tests/mif-report-channel-contract.test.js`
- Modify: `_codex/tests/mif-report-explorer-page.test.js`

**Interfaces:**
- Produces one `Portfólio 2027` action in each current report header.

- [ ] **Step 1: Add failing navigation assertions**

General links to `portfolio/`; channel index, dossier and explorer link to `../portfolio/`. Require exactly one occurrence in the right-side action group and prohibit `.report-back`.

- [ ] **Step 2: Run RED, add links, and bump changed asset versions**

Keep `← Análise geral` on the right in every subpage. Do not change page body content.

- [ ] **Step 3: Run all report tests and commit**

```bash
node --test _codex/tests/mif-report-*.test.js
git add relatorios/maratona-floripa-2026/index.cfm relatorios/maratona-floripa-2026/canais/index.cfm relatorios/maratona-floripa-2026/canais/dossie.cfm relatorios/maratona-floripa-2026/explorador/index.cfm _codex/tests/mif-report-general-contract.test.js _codex/tests/mif-report-channel-contract.test.js _codex/tests/mif-report-explorer-page.test.js
git commit -m "feat: link MIF portfolio report"
```

---

### Task 7: Canonical generation and analytical validation

**Files:**
- Generate: `_codex/analyses/mif_2026_channels/modular_dist/portfolio/summary.json`
- Generate: `_codex/analyses/mif_2026_channels/modular_dist/portfolio/simulator.json`
- Modify: `_codex/analyses/mif_2026_channels/modular_dist/manifest.json`
- Modify: `_codex/analyses/mif_2026_channels/notebooks/mif_2026_portfolio_audit.ipynb`

**Interfaces:**
- Produces canonical reviewed portfolio evidence for deployment.

- [ ] **Step 1: Generate into a temporary destination from the frozen canonical sources**

Use the existing build receipt and mapping files; no fixture or stale fallback.

- [ ] **Step 2: Compare immutable totals and prior artifacts**

Require `paid_orders = 14027`, `paid_registrations = 15713`, and `gross_value = 4321891.20`. Existing non-portfolio payloads must be byte-identical except manifest receipts; unexpected changes stop the task.

- [ ] **Step 3: Validate analytical outputs**

Inspect scale cutoff, five p25 differentiation cutoffs, five p90 pair thresholds, Top 10 pairs, dependency cells, ROADRUNNERS/SPORTS WEEK/PCD treatment, sample warnings, and denominators. Reject small-sample-dominated conclusions.

- [ ] **Step 4: Execute notebook and portable verifier**

Save anonymous outputs. Run `verify_modular_outputs` against the generated manifest and enforce both byte-size limits.

- [ ] **Step 5: Replace only validated generated files and commit**

Use the modular writer so unchanged files retain bytes and mtimes. Commit only the two new JSON files, manifest, and notebook outputs.

---

### Task 8: Final review, deployment, and production QA

**Files:**
- Verify all files from Tasks 1–7.
- Deploy: report route plus the two portfolio JSON files and updated private manifest.

**Interfaces:**
- Produces verified production pages and a recoverable backup.

- [ ] **Step 1: Run the complete local gate**

```bash
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py'
node --test _codex/tests/mif-report-*.test.js
node --check relatorios/maratona-floripa-2026/assets/report.js
node --check relatorios/maratona-floripa-2026/assets/portfolio.js
git diff --check
test -z "$(git diff HEAD --name-only -- inscricoes)"
```

- [ ] **Step 2: Request independent code and analytical review**

The reviewer checks formulas, pair symmetry, threshold semantics, scenario denominators, privacy, copy, isolation, byte limits, and `/inscricoes/`. Fix all Critical/Important findings and repeat the gate.

- [ ] **Step 3: Back up production**

Create timestamped archives of the public MIF route and `/var/lib/runnerhub/reports/mif-2026`.

- [ ] **Step 4: Deploy incrementally**

Rsync the report route without `--delete`; rsync only the two new private JSON files and updated manifest; compile the MIF CFML directory.

- [ ] **Step 5: Validate production**

Check safe unauthenticated redirects, authenticated six-chapter static render without simulator data, a ROADRUNNERS + SPORTS WEEK shared scenario, Top 10 + `Outros`, console logs, print view, local/remote hashes, and unchanged `/inscricoes/index.cfm` hash.

- [ ] **Step 6: Leave the static report open and hand off**

Return production URLs, commits, test counts, backup path, artifact sizes, major findings, and the non-causal scenario caveat.
