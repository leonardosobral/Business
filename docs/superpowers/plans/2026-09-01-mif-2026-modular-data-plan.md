# MIF 2026 Modular Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar agregados multidimensionais, dossiês independentes e artefatos versionados sem refazer a extração ou o HTML monolítico.

**Architecture:** O pipeline existente continua sendo a fonte reconciliada. Uma camada modular adiciona fases comerciais, cubos anônimos de inscrições e produtos, recomendações justificadas e arquivos separados por domínio/canal, escritos somente quando o conteúdo mudar.

**Tech Stack:** Python 3.12, pandas, unittest, JSON, SHA-256.

**Spec:** `docs/superpowers/specs/2026-09-01-mif-2026-modular-sales-report-design.md`

## Global Constraints

- Trabalhar diretamente no checkout atual; não criar worktree.
- Não alterar `/inscricoes/`.
- Preservar os grãos de pedido, inscrição e produto.
- Não persistir identificadores de pedido, inscrição ou participante nos artefatos.
- Usar semanas iniciadas na segunda-feira e as cinco fases aprovadas.
- Gráficos terão Top 10 + Outros; tabelas manterão a base completa.
- A extração fechada usa `/private/tmp/mif-2026-channel-study-source/orders_72611.csv` e `/private/tmp/mif-2026-channel-study-source/participants_72611.csv`.
- Executar Python com `/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`.

---

### Task 1: Fases comerciais reutilizáveis

**Files:**
- Create: `_codex/analyses/mif_2026_channels/phases.py`
- Modify: `_codex/analyses/mif_2026_channels/metrics.py`
- Create: `_codex/tests/mif_2026_channels/test_phases.py`

**Interfaces:**
- Produces: `SaleCycleBoundaries`, `effective_sale_dates(frame)`, `build_sale_cycle_boundaries(dates)`, `assign_sale_phases(dates, boundaries)`.
- Consumes: colunas `sale_date`, `sale_date_status` e `order_date` do fato de inscrições.

- [ ] **Step 1: Write the failing phase tests**

```python
def test_sale_cycle_uses_launch_and_relative_boundaries():
    dates = pd.Series(pd.to_datetime(["2025-06-02", "2025-06-16", "2025-09-20", "2026-03-01", "2026-07-15", "2026-08-24"]))
    boundaries = build_sale_cycle_boundaries(dates)
    assert assign_sale_phases(dates, boundaries).tolist() == [
        "Lançamento", "Início", "Início", "Meio", "Reta final", "Encerramento"
    ]

def test_effective_sale_date_only_falls_back_when_sale_date_is_missing():
    frame = pd.DataFrame({
        "sale_date": [None, None, pd.Timestamp("2025-06-05")],
        "sale_date_status": ["nao_informado", "invalido", "valido"],
        "order_date": pd.to_datetime(["2025-06-03", "2025-06-04", "2025-06-06"]),
    })
    assert effective_sale_dates(frame).tolist() == [pd.Timestamp("2025-06-03"), None, pd.Timestamp("2025-06-05")]
```

- [ ] **Step 2: Run the tests and confirm the missing module failure**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_phases -v`

Expected: `ModuleNotFoundError: _codex.analyses.mif_2026_channels.phases`.

- [ ] **Step 3: Implement boundaries and phase assignment**

```python
PHASE_ORDER = ("Lançamento", "Início", "Meio", "Reta final", "Encerramento")

@dataclass(frozen=True)
class SaleCycleBoundaries:
    start: pd.Timestamp
    end: pd.Timestamp
    launch_end: pd.Timestamp
    early_end: pd.Timestamp
    middle_end: pd.Timestamp
    final_sprint_end: pd.Timestamp

def build_sale_cycle_boundaries(dates: pd.Series) -> SaleCycleBoundaries:
    valid = pd.to_datetime(dates, errors="coerce").dropna().sort_values()
    if valid.empty:
        raise ValueError("sale cycle requires at least one valid date")
    start, end = valid.iloc[0].normalize(), valid.iloc[-1].normalize()
    span = end - start
    early_end = start + span * 0.25
    return SaleCycleBoundaries(
        start=start,
        end=end,
        launch_end=min(start + pd.Timedelta(days=13), early_end),
        early_end=early_end,
        middle_end=start + span * 0.70,
        final_sprint_end=start + span * 0.90,
    )
```

Implement `assign_sale_phases` with ordered inclusive boundaries and `effective_sale_dates` using the existing fallback contract. Replace `_effective_sale_dates` in `metrics.py` with the imported public helper.

- [ ] **Step 4: Run phase and existing metric tests**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_phases _codex.tests.mif_2026_channels.test_metrics -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add _codex/analyses/mif_2026_channels/phases.py _codex/analyses/mif_2026_channels/metrics.py _codex/tests/mif_2026_channels/test_phases.py
git commit -m "feat: model MIF sales phases"
```

### Task 2: Cubos anônimos de inscrições e produtos

**Files:**
- Create: `_codex/analyses/mif_2026_channels/crossings.py`
- Create: `_codex/tests/mif_2026_channels/test_crossings.py`

**Interfaces:**
- Consumes: `FactBundle` já mapeado e `SaleCycleBoundaries`.
- Produces: `build_registration_cube(facts, boundaries) -> list[dict]` e `build_product_cube(facts, boundaries) -> list[dict]`.

- [ ] **Step 1: Write failing cube tests**

Create a four-registration fixture covering two phases, two modalities, two lots, two states and two channels. Assert:

```python
cube = build_registration_cube(mapped_facts, boundaries)
assert sum(row["paid_registrations"] for row in cube) == 4
assert {row["phase"] for row in cube} == {"Lançamento", "Encerramento"}
assert all("numero_inscricao" not in row and "numero_pedido" not in row for row in cube)
assert sum(Decimal(row["allocated_gross_value"]) for row in cube) == Decimal("1000.00")
```

For products, assert distinct registrations, quantity and explicit revenue without copying identifiers.

- [ ] **Step 2: Run the tests and confirm the missing module failure**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_crossings -v`

Expected: `ModuleNotFoundError`.

- [ ] **Step 3: Implement observed-cell aggregation**

Registration grouping fields:

```python
REGISTRATION_DIMENSIONS = (
    "week_start", "phase", "modality", "lot", "state", "city", "channel_name"
)
```

Each row contains only those dimensions plus `paid_registrations`, `allocated_gross_value`, `allocated_discount_value`, `allocated_fee_value` and coverage markers. Group only observed combinations; never create a Cartesian product.

Product grouping fields:

```python
PRODUCT_DIMENSIONS = (
    "week_start", "phase", "modality", "lot", "state", "channel_name", "classification", "product_name"
)
```

Use `numero_inscricao` only inside the in-memory group to compute `registrations_with_product`, then drop it from output.

- [ ] **Step 4: Run crossing, privacy and reconciliation tests**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_crossings _codex.tests.mif_2026_channels.test_privacy_narrative _codex.tests.mif_2026_channels.test_facts -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add _codex/analyses/mif_2026_channels/crossings.py _codex/tests/mif_2026_channels/test_crossings.py
git commit -m "feat: build MIF multidimensional cubes"
```

### Task 3: Recomendações reproduzíveis de canais

**Files:**
- Create: `_codex/analyses/mif_2026_channels/recommendations.py`
- Create: `_codex/tests/mif_2026_channels/test_recommendations.py`

**Interfaces:**
- Consumes: um dossiê completo, overview do evento e comparações com orgânico.
- Produces: `recommend_channel(dossier, overview) -> dict` com `category`, `role`, `evidence` e `sample_qualification`.

- [ ] **Step 1: Write failing category tests**

Cover all four approved categories plus a 10–29 registration sample. Assert that a small sample cannot receive `Reduzir/descontinuar`, every category has at least two evidence strings, and ROADRUNNERS, Sports Week and PCD remain explicitly included.

- [ ] **Step 2: Run the tests and confirm the missing module failure**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_recommendations -v`

Expected: `ModuleNotFoundError`.

- [ ] **Step 3: Implement evidence-first rules**

Use visible inputs only: registrations, gross value, ticket delta, modality/state/phase deltas, product signals and similarity to organic. Return no master score. Apply this precedence:

```python
if paid_registrations < 30:
    category = "Testar/renegociar"
elif scale_is_relevant and differentiation_is_material:
    category = "Priorizar"
elif has_specific_complementary_role:
    category = "Manter com função definida"
elif scale_is_low and redundancy_is_high:
    category = "Reduzir/descontinuar"
else:
    category = "Testar/renegociar"
```

Define every boolean from named evidence thresholds in constants and include the matched evidence in output.

- [ ] **Step 4: Run recommendation and narrative tests**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_recommendations _codex.tests.mif_2026_channels.test_privacy_narrative -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add _codex/analyses/mif_2026_channels/recommendations.py _codex/tests/mif_2026_channels/test_recommendations.py
git commit -m "feat: classify MIF channel roles"
```

### Task 4: Artefatos modulares e escrita incremental

**Files:**
- Create: `_codex/analyses/mif_2026_channels/modular_artifact.py`
- Modify: `_codex/analyses/mif_2026_channels/pipeline.py`
- Create: `_codex/tests/mif_2026_channels/test_modular_artifact.py`

**Interfaces:**
- Consumes: `AnalysisResult`, cubos, recomendações e hashes de fonte.
- Produces: `build_modular_artifacts(...) -> dict[str, Any]` e `write_modular_artifacts(output_dir, artifacts) -> dict[str, Path]`.

- [ ] **Step 1: Write failing artifact tests**

Assert exact files `manifest.json`, `general.json`, `cycle.json`, `territories.json`, `products.json`, `channels/index.json`, `channels/<slug>.json` and `explorer.json`. Re-run the writer with identical input and assert every file mtime remains unchanged. Change one channel and assert only its dossier, channel index and manifest change.

- [ ] **Step 2: Run the tests and confirm the missing module failure**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_modular_artifact -v`

Expected: `ModuleNotFoundError`.

- [ ] **Step 3: Implement deterministic bundles and hashes**

Use canonical JSON (`ensure_ascii=False`, `sort_keys=True`, compact separators) and SHA-256. `write_if_changed(path, bytes)` must compare bytes before replacing atomically. Manifest entries contain `path`, `sha256`, `bytes`, `source_sha256` and `transform_version`.

- [ ] **Step 4: Run artifact and anonymity tests**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_modular_artifact _codex.tests.mif_2026_channels.test_artifact_pipeline -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add _codex/analyses/mif_2026_channels/modular_artifact.py _codex/analyses/mif_2026_channels/pipeline.py _codex/tests/mif_2026_channels/test_modular_artifact.py
git commit -m "feat: emit incremental MIF artifacts"
```

### Task 5: CLI, full production build and verification

**Files:**
- Modify: `_codex/analyses/mif_2026_channels/run.py`
- Modify: `_codex/tests/mif_2026_channels/test_artifact_pipeline.py`
- Generate: `_codex/analyses/mif_2026_channels/modular_dist/**`

**Interfaces:**
- Produces CLI command `analyze-modular` with the same source/mapping inputs as `analyze` plus `--output-dir`.
- Produces CLI command `verify-modular --manifest <path>`.

- [ ] **Step 1: Add failing CLI contract tests**

Invoke both commands through `subprocess.run` and assert `analyze-modular` writes the manifest while `verify-modular` prints `modular verification passed`.

- [ ] **Step 2: Run the targeted test and confirm parser failure**

Run: `python3 -m unittest _codex.tests.mif_2026_channels.test_artifact_pipeline.ModularArtifactPipelineTests -v`

Expected: FAIL because `analyze-modular` is not recognized.

- [ ] **Step 3: Wire commands to the modular pipeline**

The analyze command loads sources, builds facts, applies reviewed mappings once, builds the existing analysis and modular artifacts, then writes only anonymous outputs. The verify command checks manifest hashes, required bundles, reconciliations, phase partitions and forbidden keys.

- [ ] **Step 4: Build the production modular output**

Run:

```bash
python3 -m _codex.analyses.mif_2026_channels.run analyze-modular \
  --orders /private/tmp/mif-2026-channel-study-source/orders_72611.csv \
  --participants /private/tmp/mif-2026-channel-study-source/participants_72611.csv \
  --channel-map _codex/analyses/mif_2026_channels/channel_mapping.csv \
  --product-map _codex/analyses/mif_2026_channels/product_mapping.csv \
  --output-dir _codex/analyses/mif_2026_channels/modular_dist
```

Expected: manifest and all domain/channel files are written without raw identifiers.

- [ ] **Step 5: Run full verification**

Run:

```bash
python3 -m unittest discover -s _codex/tests/mif_2026_channels
python3 -m _codex.analyses.mif_2026_channels.run verify-modular --manifest _codex/analyses/mif_2026_channels/modular_dist/manifest.json
```

Expected: all tests PASS and `modular verification passed`.

- [ ] **Step 6: Commit**

```bash
git add _codex/analyses/mif_2026_channels/run.py _codex/tests/mif_2026_channels/test_artifact_pipeline.py _codex/analyses/mif_2026_channels/modular_dist
git commit -m "feat: build modular MIF dataset"
```
