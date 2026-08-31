# MIF 2026 Channel Sales Study Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a frozen, detailed, self-contained HTML study of Maratona Internacional de Floripa 2026 sales and channel profiles, using event `72611`, without changing `/inscricoes/`.

**Architecture:** A read-only Python analysis pipeline will turn fresh TicketSports order and participant exports into three reconciled fact tables: orders, registrations, and products. Reviewed mapping files will consolidate multiple coupon codes into one channel while preserving every original code; deterministic metrics and narratives will feed a canonical Data Analytics report artifact, which the bundled report builder will validate and render as one portable HTML file.

**Tech Stack:** Python 3.12, pandas 2.2.3, openpyxl 3.1.5, standard-library `unittest`, JSON/CSV, SQL read-only extracts, Node.js 24, and the bundled Data Analytics portable report builder.

**Spec:** `docs/superpowers/specs/2026-08-30-mif-2026-channel-sales-study-design.md`

## Global Constraints

- Do not modify, add routes to, import from, or deploy changes under `/inscricoes/`; it remains exactly as it is.
- The analysis is a separate, closed 2026 snapshot for TicketSports event code `72611`, not a live dashboard.
- Fresh read-only data from `public.tb_ticketsports_pedidos` and `public.tb_ticketsports_participantes` is required for the final report; the existing ignored XLSX files may be used only to develop and test the pipeline.
- Raw extracts and direct identifiers must stay outside the repository. Only reviewed mappings, anonymous aggregates, reconciliation evidence, the canonical artifact, and the final HTML may be versioned.
- The order grain is `(cod_evento, numero_pedido)`; the registration grain is `(cod_evento, numero_inscricao)`; the product grain is one normalized row per product item attached to a registration.
- Include only paid sales in commercial metrics. Keep non-paid rows only in a data-quality reconciliation that cannot be mistaken for revenue.
- Calculate event ticket averages from totals at the correct grain. Never average channel, lot, or modality averages to obtain an overall ticket.
- Consolidate channels only through deterministic normalization plus explicit reviewed aliases. Retain original coupon titles, coupon codes, volumes, and merge justification in every consolidated dossier.
- Treat Sports Week as a strategic channel. Treat PCD and Benefício as policy/mechanism categories unless the source data proves a separately managed commercial partner.
- Produce a full dossier for consolidated channels with at least `10` paid registrations and a compact, still browseable record for channels below `10`.
- Do not output a score, ranking, automatic classification, or automatic keep/cut recommendation. Present comparable evidence, overlaps, distinctive traits, limitations, and decision questions.
- Do not infer product revenue from product text. Classify each observed item as `kit_incluso`, `adicional`, or `desconhecido`; report revenue only when a source field explicitly supports it.
- Do not infer external demographic, income, or market attributes from city, state, club, pace, name, or coupon. Missing coverage must be visible in the report.
- No raw names, emails, phone numbers, CPF/CNPJ, addresses, birthdays, or registration/order identifiers may appear in the canonical artifact or final HTML.
- Suppress potentially identifying cross-tab cells with fewer than `3` registrations. Channel totals may remain visible in the compact long tail because they do not expose a person-level combination.
- The report must be one self-contained HTML file, generated from the canonical artifact by the bundled Data Analytics report builder. Do not create a separate hand-coded report runtime.
- Validate uniqueness, composite joins, category sums, paid totals, mapping coverage, product classification, field coverage, anonymity, desktop layout, mobile layout, and print/PDF layout before calling the report complete.
- Commit checkpoints in this plan are conditional on explicit user authorization at execution time; without that authorization, run the gate and leave the reviewed changes uncommitted.

## Runtime Constants

Use these exact local runtimes for reproducible execution on the current host:

```bash
MIF_PYTHON=/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
MIF_NODE=/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
MIF_REPORT_PLUGIN=/Users/leonardosobral/.codex/plugins/cache/openai-curated-remote/data-analytics/0.2.8-13ceeea1f599
MIF_RAW_DIR=/private/tmp/mif-2026-channel-study-source
MIF_REPORT_DIR=_codex/reports/mif-2026-channel-study
```

## File Structure

### Analysis package

- Create `_codex/analyses/__init__.py`: marks the analyses directory as a Python package.
- Create `_codex/analyses/mif_2026_channels/__init__.py`: exports the pipeline version.
- Create `_codex/analyses/mif_2026_channels/config.py`: immutable event, threshold, status, privacy, and output constants.
- Create `_codex/analyses/mif_2026_channels/models.py`: typed dataclasses shared across source loading, fact construction, analysis, and artifact generation.
- Create `_codex/analyses/mif_2026_channels/source.py`: reads CSV/XLSX exports, validates source columns, filters event `72611`, records hashes and source freshness, and parses JSON safely.
- Create `_codex/analyses/mif_2026_channels/normalize.py`: canonical text, status, number, date, modality, geography, age, pace, coupon, and payment normalizers.
- Create `_codex/analyses/mif_2026_channels/facts.py`: builds and reconciles the order, registration, and product fact tables at their exact grains.
- Create `_codex/analyses/mif_2026_channels/mappings.py`: emits mapping drafts, validates reviewed channel/product mappings, assigns consolidated channels, and preserves source aliases.
- Create `_codex/analyses/mif_2026_channels/metrics.py`: produces event, lot, modality, geography, profile, product, channel, similarity, and long-tail aggregates.
- Create `_codex/analyses/mif_2026_channels/narrative.py`: produces deterministic factual Portuguese summaries and decision questions without rankings or recommendations.
- Create `_codex/analyses/mif_2026_channels/privacy.py`: suppresses small cells and scans nested output for forbidden fields and direct identifiers.
- Create `_codex/analyses/mif_2026_channels/artifact.py`: converts the anonymous analysis result into the canonical portable report artifact.
- Create `_codex/analyses/mif_2026_channels/pipeline.py`: coordinates loading, facts, mappings, reconciliation, metrics, privacy, and artifact serialization.
- Create `_codex/analyses/mif_2026_channels/run.py`: command-line entry point for draft mappings, final analysis, and verification.
- Create `_codex/analyses/mif_2026_channels/requirements.txt`: pins `pandas==2.2.3` and `openpyxl==3.1.5`.
- Create `_codex/analyses/mif_2026_channels/channel_mapping.csv`: complete reviewed mapping of observed coupon title/code pairs to consolidated channels.
- Create `_codex/analyses/mif_2026_channels/product_mapping.csv`: complete reviewed classification of observed product identities.

### Source, tests, and outputs

- Create `_codex/sql/2026-08-30_mif_2026_channel_sales_extract.sql`: read-only, event-scoped extraction queries.
- Create `_codex/tests/mif_2026_channels/__init__.py`: test package marker.
- Create `_codex/tests/mif_2026_channels/fixtures.py`: small synthetic order and participant source rows with no real PII.
- Create `_codex/tests/mif_2026_channels/test_source.py`: source schema, freshness, hash, and JSON parsing tests.
- Create `_codex/tests/mif_2026_channels/test_normalize.py`: deterministic normalizer tests.
- Create `_codex/tests/mif_2026_channels/test_facts.py`: grains, composite joins, registration allocation, product explosion, and reconciliation tests.
- Create `_codex/tests/mif_2026_channels/test_mappings.py`: exact alias consolidation and completeness tests.
- Create `_codex/tests/mif_2026_channels/test_metrics.py`: weighted ticket, lots, modalities, geography, profiles, products, channel dossiers, and overlap tests.
- Create `_codex/tests/mif_2026_channels/test_privacy_narrative.py`: suppression, identifier scanning, and neutral narrative tests.
- Create `_codex/tests/mif_2026_channels/test_artifact_pipeline.py`: canonical artifact, source traceability, and end-to-end snapshot tests.
- Modify `.gitignore`: prevent accidental staging of `_codex/analyses/mif_2026_channels/data/raw/`, `channel_mapping.draft.csv`, and `product_mapping.draft.csv`.
- Generate `_codex/reports/mif-2026-channel-study/artifact.json`: canonical anonymous report artifact.
- Generate `_codex/reports/mif-2026-channel-study/aggregates.json`: anonymous bounded analysis snapshot used by the artifact.
- Generate `_codex/reports/mif-2026-channel-study/reconciliation.json`: source counts, paid filters, join coverage, category sums, mapping coverage, and field coverage.
- Generate `_codex/reports/mif-2026-channel-study/source_notes.json`: hashes, extraction timestamp, predicates, metric definitions, limitations, and chart map.
- Generate `_codex/reports/mif-2026-channel-study/report.html`: final self-contained study.

---

### Task 1: Source contract, package types, and fresh extraction query

**Files:**
- Create: `_codex/analyses/__init__.py`
- Create: `_codex/analyses/mif_2026_channels/__init__.py`
- Create: `_codex/analyses/mif_2026_channels/config.py`
- Create: `_codex/analyses/mif_2026_channels/models.py`
- Create: `_codex/analyses/mif_2026_channels/source.py`
- Create: `_codex/analyses/mif_2026_channels/requirements.txt`
- Create: `_codex/sql/2026-08-30_mif_2026_channel_sales_extract.sql`
- Create: `_codex/tests/mif_2026_channels/__init__.py`
- Create: `_codex/tests/mif_2026_channels/fixtures.py`
- Create: `_codex/tests/mif_2026_channels/test_source.py`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: TicketSports exports containing `cod_evento`, the row key, `body`, and an extraction timestamp column `extracted_at` for a final run. Legacy-development and synthetic runs may omit `extracted_at` only when `allow_stale=True` is explicit.
- Produces: `SourceSnapshot`, `SourceBundle`, `AnalysisResult`, `read_export(path: Path, required_columns: frozenset[str]) -> pd.DataFrame`, `load_sources(orders_path: Path, participants_path: Path, event_code: int, allow_stale: bool) -> SourceBundle`, and `write_source_manifest(bundle: SourceBundle, output_path: Path) -> None`.

- [ ] **Step 1: Write synthetic fixtures and failing source tests**

Create fixtures whose JSON fields contain one paid order with two registrations, one unpaid order, products, coupon aliases, modality, lot, geography, birth date, gender, pace, club, and payment metadata. Use synthetic names such as `Pessoa Teste A`; no production value may enter the test tree.

```python
# _codex/tests/mif_2026_channels/test_source.py
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.source import load_sources, read_export
from _codex.tests.mif_2026_channels.fixtures import orders_rows, participant_rows


class SourceTests(unittest.TestCase):
    def test_read_export_rejects_missing_body(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "orders.csv"
            pd.DataFrame([{"cod_evento": 72611, "numero_pedido": 10}]).to_csv(path, index=False)
            with self.assertRaisesRegex(ValueError, "body"):
                read_export(path, frozenset({"cod_evento", "numero_pedido", "body"}))

    def test_load_sources_filters_event_and_records_hashes(self):
        with TemporaryDirectory() as directory:
            orders_path = Path(directory) / "orders.xlsx"
            participants_path = Path(directory) / "participants.xlsx"
            pd.DataFrame(orders_rows() + [{"cod_evento": 99999, "numero_pedido": 999, "body": "{}"}]).to_excel(orders_path, index=False)
            pd.DataFrame(participant_rows()).to_excel(participants_path, index=False)

            bundle = load_sources(orders_path, participants_path, event_code=72611, allow_stale=True)

            self.assertEqual(set(bundle.orders["cod_evento"]), {72611})
            self.assertEqual(len(bundle.source_hashes["orders"]), 64)
            self.assertEqual(bundle.event_code, 72611)
```

- [ ] **Step 2: Run the source tests and verify the imports fail**

Run:

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_source -v
```

Expected: failure because `_codex.analyses.mif_2026_channels.source` does not exist.

- [ ] **Step 3: Define immutable constants and shared dataclasses**

Use these signatures and fields so later tasks share one vocabulary:

```python
# config.py
from datetime import date

EVENT_CODE = 72611
EVENT_DATE = date(2026, 8, 30)
PAID_STATUS = "pago"
FULL_DOSSIER_MIN_REGISTRATIONS = 10
SMALL_CELL_MIN_REGISTRATIONS = 3
PIPELINE_VERSION = "1.0.0"
FORBIDDEN_OUTPUT_KEYS = frozenset({
    "nome", "email", "telefone", "celular", "cpf", "cnpj", "endereco",
    "logradouro", "numero_pedido", "numero_inscricao", "data_nascimento",
})
```

```python
# models.py
from dataclasses import dataclass
from pathlib import Path
from typing import Any
import pandas as pd


@dataclass(frozen=True)
class SourceSnapshot:
    source_id: str
    path: Path
    sha256: str
    row_count: int
    extracted_at: str
    event_code: int


@dataclass(frozen=True)
class SourceBundle:
    event_code: int
    orders: pd.DataFrame
    participants: pd.DataFrame
    snapshots: tuple[SourceSnapshot, SourceSnapshot]
    source_hashes: dict[str, str]


@dataclass(frozen=True)
class FactBundle:
    orders: pd.DataFrame
    registrations: pd.DataFrame
    products: pd.DataFrame
    reconciliation: dict[str, Any]


@dataclass(frozen=True)
class AnalysisResult:
    overview: dict[str, Any]
    datasets: dict[str, list[dict[str, Any]]]
    full_dossiers: list[dict[str, Any]]
    long_tail: list[dict[str, Any]]
    quality: dict[str, Any]
    source_notes: dict[str, Any]
```

- [ ] **Step 4: Implement schema-checked CSV/XLSX loading, hashing, and freshness enforcement**

Implement `read_export` with `pd.read_csv(dtype=object)` or `pd.read_excel(dtype=object)` by suffix, exact missing-column errors, event filtering, and SHA-256 streaming. `load_sources(..., allow_stale=False)` must require the `extracted_at` value emitted by the SQL below to be on or after `2026-08-30T00:00:00-03:00`; file modification time and `data_pedido` are not accepted as extraction time. `allow_stale=True` exists only for synthetic and legacy-development runs.

```python
def read_export(path: Path, required_columns: frozenset[str]) -> pd.DataFrame:
    readers = {".csv": pd.read_csv, ".xlsx": pd.read_excel}
    reader = readers.get(path.suffix.lower())
    if reader is None:
        raise ValueError(f"unsupported export format: {path.suffix}")
    frame = reader(path, dtype=object)
    missing = sorted(required_columns - set(frame.columns))
    if missing:
        raise ValueError(f"missing required columns: {', '.join(missing)}")
    return frame
```

The source manifest must store only file name, SHA-256, row count, extraction time, event code, table name, and query predicate; never serialize raw rows.

- [ ] **Step 5: Add the exact read-only SQL extraction contract**

Create one SQL file with two separately exportable result sets and no mutation statement:

```sql
-- Orders result set
SELECT
    cod_evento,
    numero_pedido,
    data_pedido,
    CURRENT_TIMESTAMP AS extracted_at,
    body
FROM public.tb_ticketsports_pedidos
WHERE cod_evento = 72611
ORDER BY numero_pedido;

-- Participants result set
SELECT
    cod_evento,
    numero_inscricao,
    numero_pedido,
    CURRENT_TIMESTAMP AS extracted_at,
    body
FROM public.tb_ticketsports_participantes
WHERE cod_evento = 72611
ORDER BY numero_inscricao;
```

The executor must use an already configured read-only database connection. If no callable read-only connection exists, request updated event-scoped XLSX or CSV exports with these exact columns; do not expose a web endpoint and do not use the ignored legacy files as final evidence.

- [ ] **Step 6: Add defensive raw-data ignore rules and dependency pins**

Append exactly:

```gitignore
_codex/analyses/mif_2026_channels/data/raw/
_codex/analyses/mif_2026_channels/channel_mapping.draft.csv
_codex/analyses/mif_2026_channels/product_mapping.draft.csv
```

Set `requirements.txt` to:

```text
pandas==2.2.3
openpyxl==3.1.5
```

- [ ] **Step 7: Run the source gate**

Run:

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_source -v
git diff --check
```

Expected: all source tests pass and `git diff --check` prints nothing.

- [ ] **Step 8: Commit the source contract checkpoint when authorized**

```bash
git add .gitignore _codex/analyses _codex/sql/2026-08-30_mif_2026_channel_sales_extract.sql _codex/tests/mif_2026_channels
git commit -m "feat: establish MIF 2026 analysis source contract"
```

### Task 2: Deterministic normalization of TicketSports fields

**Files:**
- Create: `_codex/analyses/mif_2026_channels/normalize.py`
- Create: `_codex/tests/mif_2026_channels/test_normalize.py`
- Modify: `_codex/tests/mif_2026_channels/fixtures.py`

**Interfaces:**
- Consumes: Python values parsed from TicketSports JSON and `EVENT_DATE` from `config.py`.
- Produces: `parse_json_object(value: object) -> dict[str, Any]`, `normalize_text(value: object) -> str | None`, `normalize_key(value: object) -> str`, `parse_decimal(value: object) -> Decimal | None`, `parse_date(value: object) -> date | None`, `coverage_status(raw_value: object, parsed_value: object) -> str`, `normalize_status(value: object) -> str`, `normalize_modality(value: object) -> str`, `normalize_lot(value: object) -> str`, `normalize_country(value: object) -> str | None`, `normalize_state(value: object) -> str | None`, `normalize_city(value: object) -> str | None`, `normalize_gender(value: object) -> str`, `age_on_event_date(value: object) -> int | None`, and `pace_to_seconds(value: object) -> int | None`.

- [ ] **Step 1: Write failing normalizer tests with Brazilian and API formats**

```python
# _codex/tests/mif_2026_channels/test_normalize.py
from decimal import Decimal
import unittest

from _codex.analyses.mif_2026_channels.normalize import (
    age_on_event_date,
    normalize_key,
    normalize_modality,
    normalize_lot,
    normalize_status,
    pace_to_seconds,
    parse_decimal,
    parse_date,
    coverage_status,
)


class NormalizeTests(unittest.TestCase):
    def test_decimal_accepts_api_and_brazilian_formats(self):
        self.assertEqual(parse_decimal("273.27"), Decimal("273.27"))
        self.assertEqual(parse_decimal("1.234,56"), Decimal("1234.56"))

    def test_key_removes_accents_spacing_and_case(self):
        self.assertEqual(normalize_key("  Corre  Criciúma_100 "), "CORRE CRICIUMA 100")

    def test_status_and_modality_are_canonical(self):
        self.assertEqual(normalize_status(" PAGO "), "pago")
        self.assertEqual(normalize_modality("Maratona 42 km"), "42K")
        self.assertEqual(normalize_modality("Meia Maratona - 21KM"), "21K")
        self.assertEqual(normalize_lot("Lote 6"), "6")
        self.assertEqual(str(parse_date("30/08/2026")), "2026-08-30")

    def test_age_and_pace_are_bounded(self):
        self.assertEqual(age_on_event_date("1990-08-31"), 35)
        self.assertEqual(pace_to_seconds("05:30"), 330)
        self.assertIsNone(pace_to_seconds("99:99"))
        self.assertEqual(coverage_status("99:99", None), "invalido")
        self.assertEqual(coverage_status("", None), "nao_informado")
```

- [ ] **Step 2: Run the tests and verify the module import fails**

Run:

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_normalize -v
```

Expected: failure because `normalize.py` does not exist.

- [ ] **Step 3: Implement canonical text, JSON, decimal, and date parsing**

Use `unicodedata.normalize("NFKD", text)`, remove combining marks, replace non-alphanumeric runs with one space, and uppercase mapping keys. `normalize_text` returns `None` for `None`, pandas/NumPy missing values, and whitespace-only values. `parse_decimal` must reject non-finite values; `parse_json_object` must accept dictionaries and JSON strings but reject lists and malformed JSON with a zero-based export row position supplied by the caller. Error messages must not include raw JSON, person data, order IDs, or registration IDs.

```python
def normalize_key(value: object) -> str:
    text = normalize_text(value) or ""
    ascii_text = "".join(
        char for char in unicodedata.normalize("NFKD", text)
        if not unicodedata.combining(char)
    )
    return re.sub(r"[^A-Za-z0-9]+", " ", ascii_text).strip().upper()
```

- [ ] **Step 4: Implement bounded business normalizers**

Map modality text by explicit patterns to `42K`, `21K`, `5K`, `DESAFIO`, `KIDS`, or `OUTRA: <normalized source>`. Normalize lots `1` through `99` to their numeric string and return `Não informado` for blanks; preserve unexpected nonblank values as `OUTRO: <normalized source>`. Normalize `Brasil`, `Brazil`, and `BR` to `BRASIL`; preserve other reviewed country names; accept UF codes only when country is Brazil or absent. Normalize gender only from explicit source aliases to `Feminino`, `Masculino`, `Não binário/outro informado`, `Não informado`, or `Inválido`. Calculate age on `2026-08-30` and return `None` outside `5..100`. Parse pace in `MM:SS` or `HH:MM:SS` and return `None` outside `120..1200` seconds per kilometre.

```python
BRAZIL_ALIASES = {"BR", "BRASIL", "BRAZIL"}
VALID_UFS = frozenset("AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO".split())


def normalize_country(value: object) -> str | None:
    key = normalize_key(value)
    if not key:
        return None
    return "BRASIL" if key in BRAZIL_ALIASES else key


def age_on_event_date(value: object) -> int | None:
    born = parse_date(value)
    if born is None:
        return None
    age = EVENT_DATE.year - born.year - ((EVENT_DATE.month, EVENT_DATE.day) < (born.month, born.day))
    return age if 5 <= age <= 100 else None


def pace_to_seconds(value: object) -> int | None:
    parts = [int(part) for part in str(value).strip().split(":") if part.isdigit()]
    seconds = parts[0] * 60 + parts[1] if len(parts) == 2 else (parts[0] * 3600 + parts[1] * 60 + parts[2] if len(parts) == 3 else -1)
    return seconds if 120 <= seconds <= 1200 else None


def coverage_status(raw_value: object, parsed_value: object) -> str:
    if normalize_text(raw_value) is None:
        return "nao_informado"
    return "valido" if parsed_value is not None else "invalido"
```

- [ ] **Step 5: Run focused and full normalization gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_normalize -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass and no whitespace error is reported.

- [ ] **Step 6: Commit the normalization checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/normalize.py _codex/tests/mif_2026_channels
git commit -m "feat: normalize MIF 2026 TicketSports fields"
```

### Task 3: Three fact tables and financial reconciliation

**Files:**
- Create: `_codex/analyses/mif_2026_channels/facts.py`
- Create: `_codex/tests/mif_2026_channels/test_facts.py`
- Modify: `_codex/tests/mif_2026_channels/fixtures.py`

**Interfaces:**
- Consumes: `SourceBundle`, normalizers from Task 2, and event/status constants.
- Produces: `build_order_fact(bundle: SourceBundle) -> pd.DataFrame`, `_parse_registration_rows(source: pd.DataFrame) -> pd.DataFrame`, `_allocate_covered_order_values(joined: pd.DataFrame, allocator: Callable[[Decimal, list[Decimal]], list[Decimal]]) -> pd.DataFrame`, `build_registration_fact(bundle: SourceBundle, orders: pd.DataFrame) -> pd.DataFrame`, `build_product_fact(registrations: pd.DataFrame) -> pd.DataFrame`, `build_fact_bundle(bundle: SourceBundle) -> FactBundle`, and `assert_reconciled(facts: FactBundle) -> None`.

- [ ] **Step 1: Write failing tests for grains, composite joins, and multi-registration orders**

```python
# _codex/tests/mif_2026_channels/test_facts.py
from decimal import Decimal
import unittest

from _codex.analyses.mif_2026_channels.facts import build_fact_bundle
from _codex.tests.mif_2026_channels.fixtures import source_bundle


class FactTests(unittest.TestCase):
    def test_order_and_registration_grains_are_unique(self):
        facts = build_fact_bundle(source_bundle())
        self.assertFalse(facts.orders.duplicated(["cod_evento", "numero_pedido"]).any())
        self.assertFalse(facts.registrations.duplicated(["cod_evento", "numero_inscricao"]).any())

    def test_two_registrations_join_to_one_order_without_duplicating_order_revenue(self):
        facts = build_fact_bundle(source_bundle())
        paid_orders = facts.orders.loc[facts.orders["is_paid"]]
        paid_registrations = facts.registrations.loc[facts.registrations["is_paid"]]
        self.assertEqual(len(paid_orders), 1)
        self.assertEqual(len(paid_registrations), 2)
        self.assertEqual(paid_orders["gross_order_value"].sum(), Decimal("600.00"))
        self.assertEqual(paid_registrations["allocated_gross_value"].sum(), Decimal("600.00"))

    def test_product_fact_explodes_every_product_item(self):
        facts = build_fact_bundle(source_bundle())
        self.assertEqual(len(facts.products), 3)
        self.assertEqual(set(facts.products["product_position"]), {0, 1})
```

- [ ] **Step 2: Run tests and verify fact builders are missing**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_facts -v
```

Expected: failure because `facts.py` does not exist.

- [ ] **Step 3: Implement the order fact at composite order grain**

Extract these exact normalized fields: `cod_evento`, `numero_pedido`, `order_date`, `payment_date`, `status`, `is_paid`, `gross_order_value`, `discount_value`, `fee_value`, `net_transfer_value`, `cashback_value`, `installments`, `payment_method`, `device_type`, `declared_registration_count`, and `parsed_registration_count`.

If an API field is absent, leave it null and record coverage; never derive `net_transfer_value` from unrelated fields. Reject duplicate `(cod_evento, numero_pedido)` rows with their count in the exception.

```python
ORDER_JSON_FIELDS = {
    "order_date": "dataPedido",
    "payment_date": "dataPagamento",
    "status": "status",
    "gross_order_value": "valor",
    "discount_value": "desconto",
    "fee_value": "taxa",
    "net_transfer_value": "valorRepassePedido",
    "cashback_value": "cashback",
    "installments": "qtdParcela",
    "payment_method": "formaDePagamento",
    "device_type": "tipoDispositivo",
    "declared_registration_count": "qtdeInscricao",
}


def build_order_fact(bundle: SourceBundle) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for source_row in bundle.orders.to_dict("records"):
        body = parse_json_object(source_row["body"])
        row = {"cod_evento": int(source_row["cod_evento"]), "numero_pedido": source_row["numero_pedido"]}
        row.update({target: body.get(source) for target, source in ORDER_JSON_FIELDS.items()})
        row["status"] = normalize_status(row["status"])
        row["is_paid"] = row["status"] == PAID_STATUS
        rows.append(row)
    result = pd.DataFrame(rows)
    duplicates = result.duplicated(["cod_evento", "numero_pedido"], keep=False)
    if duplicates.any():
        raise ValueError(f"duplicate composite order keys: {int(duplicates.sum())}")
    return result
```

- [ ] **Step 4: Implement registration fact and value allocation**

Join participants to orders on both `cod_evento` and `numero_pedido` with `validate="many_to_one"`. Extract coupon title/code, modality, lot, sale/registration dates, reported registration price components, country/state/city, birth-derived age, gender, pace, club, questionnaire completion presence, and the unclassified product array. For every parsed field, keep a parallel `*_status` value of `valido`, `invalido`, or `nao_informado` using `coverage_status`; this preserves invalid values in coverage without converting them to zero. Keep a JSON-key coverage inventory for auxiliary fields, but do not propagate free-text questionnaire answers to any aggregate or output.

Preserve explicit registration price fields as `reported_registration_*` source values. Independently allocate every covered paid order gross, discount, fee, net transfer, and source-backed cashback across all registrations in that order, using reported registration gross as weights when available; if no valid weight exists, allocate evenly and set `allocation_method="equal_missing_registration_prices"`. Store the five allocated fields separately, use them for additive channel/event metrics, and require each covered amount to reconcile to the corresponding order total within `R$ 0,01` after cent rounding. Report reported-versus-allocated differences in data quality rather than mixing the two bases.

The coupon belongs to the registration grain. For a paid order containing registrations from more than one consolidated channel, count the order once in each channel's `touched_paid_orders` but never duplicate money: commercial channel values always sum the registration-level allocations. The report labels `allocated_value_per_touched_order` explicitly and states that touched-order counts are non-additive across channels.

```python
def allocate_cents(total: Decimal, weights: list[Decimal]) -> list[Decimal]:
    if not weights or sum(weights) <= 0:
        weights = [Decimal("1")] * len(weights)
    raw = [total * weight / sum(weights) for weight in weights]
    cents = [value.quantize(Decimal("0.01"), rounding=ROUND_DOWN) for value in raw]
    remainder = int((total - sum(cents)) * 100)
    for index in sorted(range(len(raw)), key=lambda i: raw[i] - cents[i], reverse=True)[:remainder]:
        cents[index] += Decimal("0.01")
    return cents


def build_registration_fact(bundle: SourceBundle, orders: pd.DataFrame) -> pd.DataFrame:
    parsed = _parse_registration_rows(bundle.participants)
    joined = parsed.merge(orders, on=["cod_evento", "numero_pedido"], how="left", validate="many_to_one", suffixes=("", "_order"))
    if joined.loc[joined["is_paid"].isna(), ["cod_evento", "numero_inscricao"]].shape[0]:
        raise ValueError("paid registration join coverage is incomplete")
    return _allocate_covered_order_values(joined, allocate_cents)
```

`_parse_registration_rows` is a private helper in `facts.py` that returns the exact registration fields listed above and `_allocate_covered_order_values` applies `allocate_cents` independently to gross, discount, fee, net transfer, and cashback for each composite order key. Both helpers are covered indirectly by the public fact tests; they are not exported across tasks.

- [ ] **Step 5: Implement product explosion without revenue inference**

Create one row per product item with `cod_evento`, `numero_inscricao`, `numero_pedido`, `product_position`, `product_id`, `product_name`, `product_quantity`, `explicit_unit_value`, `explicit_total_value`, and `raw_product_keys`. Do not carry any name, email, document, phone, address, or birthday into this fact.

```python
def build_product_fact(registrations: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for registration in registrations.to_dict("records"):
        for position, product in enumerate(registration.pop("raw_products", []) or []):
            rows.append({
                "cod_evento": registration["cod_evento"],
                "numero_inscricao": registration["numero_inscricao"],
                "numero_pedido": registration["numero_pedido"],
                "product_position": position,
                "product_id": product.get("id") or product.get("codigo"),
                "product_name": product.get("nome") or product.get("produto"),
                "product_quantity": product.get("quantidade", 1),
                "explicit_unit_value": product.get("valorUnitario"),
                "explicit_total_value": product.get("valorTotal"),
                "raw_product_keys": sorted(product),
            })
    return pd.DataFrame(rows)
```

- [ ] **Step 6: Implement reconciliation evidence and hard assertions**

`FactBundle.reconciliation` must contain at least:

```python
{
    "source_order_rows": int,
    "source_registration_rows": int,
    "paid_order_count": int,
    "paid_registration_count": int,
    "paid_order_gross": "decimal string",
    "allocated_registration_gross": "decimal string",
    "paid_order_discount": "decimal string or null",
    "allocated_registration_discount": "decimal string or null",
    "paid_order_fee": "decimal string or null",
    "allocated_registration_fee": "decimal string or null",
    "paid_order_net_transfer": "decimal string or null",
    "allocated_registration_net_transfer": "decimal string or null",
    "registration_join_coverage_pct": float,
    "orders_with_multiple_registrations": int,
    "unmatched_registration_count": int,
    "invalid_json_count": int,
}
```

`assert_reconciled` must fail on duplicate composite keys, unmatched paid registrations, any covered paid financial mismatch above one cent, negative impossible counts, or event codes other than `72611`.

```python
def assert_reconciled(facts: FactBundle) -> None:
    if facts.orders.duplicated(["cod_evento", "numero_pedido"]).any():
        raise ValueError("duplicate order grain")
    if facts.registrations.duplicated(["cod_evento", "numero_inscricao"]).any():
        raise ValueError("duplicate registration grain")
    if set(facts.orders["cod_evento"].dropna().astype(int)) != {EVENT_CODE}:
        raise ValueError("unexpected event code")
    for order_key, allocated_key in (
        ("paid_order_gross", "allocated_registration_gross"),
        ("paid_order_discount", "allocated_registration_discount"),
        ("paid_order_fee", "allocated_registration_fee"),
        ("paid_order_net_transfer", "allocated_registration_net_transfer"),
    ):
        left, right = facts.reconciliation.get(order_key), facts.reconciliation.get(allocated_key)
        if left is not None and right is not None and abs(Decimal(left) - Decimal(right)) > Decimal("0.01"):
            raise ValueError(f"financial reconciliation failed: {order_key}")
```

- [ ] **Step 7: Run focused and cumulative gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_facts -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass, including the multi-registration revenue test.

- [ ] **Step 8: Commit the fact-model checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/facts.py _codex/tests/mif_2026_channels
git commit -m "feat: build reconciled MIF sales facts"
```

### Task 4: Reviewed channel consolidation and product classification

**Files:**
- Create: `_codex/analyses/mif_2026_channels/mappings.py`
- Create: `_codex/analyses/mif_2026_channels/channel_mapping.csv`
- Create: `_codex/analyses/mif_2026_channels/product_mapping.csv`
- Create: `_codex/tests/mif_2026_channels/test_mappings.py`
- Modify: `_codex/tests/mif_2026_channels/fixtures.py`

**Interfaces:**
- Consumes: registration/product facts and `normalize_key`.
- Produces: `emit_channel_mapping_draft(registrations: pd.DataFrame, path: Path) -> None`, `load_channel_mapping(path: Path, require_reviewed: bool = True) -> pd.DataFrame`, `assign_channels(registrations: pd.DataFrame, mapping: pd.DataFrame) -> pd.DataFrame`, `emit_product_mapping_draft(products: pd.DataFrame, path: Path) -> None`, `load_product_mapping(path: Path, require_reviewed: bool = True) -> pd.DataFrame`, `classify_products(products: pd.DataFrame, mapping: pd.DataFrame) -> pd.DataFrame`, and `apply_reviewed_mappings(facts: FactBundle, channel_mapping: pd.DataFrame, product_mapping: pd.DataFrame) -> FactBundle`.

- [ ] **Step 1: Write failing tests for exact aliases, organic sales, and review completeness**

```python
# _codex/tests/mif_2026_channels/test_mappings.py
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.mappings import assign_channels, load_channel_mapping


class MappingTests(unittest.TestCase):
    def test_two_correcriciuma_codes_consolidate_and_remain_auditable(self):
        registrations = pd.DataFrame([
            {"coupon_title": "CORRECRICIUMA", "coupon_code": "CORRECRICIUMA"},
            {"coupon_title": "CORRECRICIUMA", "coupon_code": "CORRECRICIUMA_100"},
        ])
        mapping = pd.DataFrame([
            {"coupon_title_key": "CORRECRICIUMA", "coupon_code_key": "CORRECRICIUMA", "channel_name": "Corre Criciúma", "channel_type": "assessoria", "alias_reason": "mesmo parceiro, código principal", "reviewed": True},
            {"coupon_title_key": "CORRECRICIUMA", "coupon_code_key": "CORRECRICIUMA 100", "channel_name": "Corre Criciúma", "channel_type": "assessoria", "alias_reason": "mesmo parceiro, ação limitada", "reviewed": True},
        ])
        assigned = assign_channels(registrations, mapping)
        self.assertEqual(set(assigned["channel_name"]), {"Corre Criciúma"})
        self.assertEqual(set(assigned["coupon_code"]), {"CORRECRICIUMA", "CORRECRICIUMA_100"})

    def test_unreviewed_mapping_is_rejected(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "mapping.csv"
            pd.DataFrame([{
                "coupon_title_key": "CANAL A",
                "coupon_code_key": "CANAL A",
                "coupon_title_example": "Canal A",
                "coupon_code_example": "CANAL_A",
                "paid_registrations": 1,
                "channel_name": "Canal A",
                "channel_type": "parceiro",
                "alias_reason": "identidade exata",
                "reviewed": False,
            }]).to_csv(path, index=False)
            with self.assertRaisesRegex(ValueError, "reviewed"):
                load_channel_mapping(path)
```

- [ ] **Step 2: Run tests and verify mapping functions are missing**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_mappings -v
```

Expected: failure because `mappings.py` does not exist.

- [ ] **Step 3: Implement deterministic channel draft emission and validation**

The channel draft has these exact columns:

```text
coupon_title_key,coupon_code_key,coupon_title_example,coupon_code_example,paid_registrations,channel_name,channel_type,alias_reason,reviewed
```

Blank coupon title/code pairs are assigned in code to `Orgânico / sem cupom` with type `organico`. Every nonblank observed pair must appear once in a reviewed CSV row. Allowed channel types are `parceiro`, `influenciador`, `assessoria`, `comunidade`, `campanha`, `evento_acao`, `politica`, `beneficio`, `cortesia`, `organico`, and `outro`. No fuzzy match is permitted.

```python
CHANNEL_MAPPING_COLUMNS = [
    "coupon_title_key", "coupon_code_key", "coupon_title_example", "coupon_code_example",
    "paid_registrations", "channel_name", "channel_type", "alias_reason", "reviewed",
]


def emit_channel_mapping_draft(registrations: pd.DataFrame, path: Path) -> None:
    paid = registrations.loc[registrations["is_paid"]].copy()
    paid["coupon_title_key"] = paid["coupon_title"].map(normalize_key)
    paid["coupon_code_key"] = paid["coupon_code"].map(normalize_key)
    observed = paid.groupby(["coupon_title_key", "coupon_code_key"], dropna=False).agg(
        coupon_title_example=("coupon_title", "first"),
        coupon_code_example=("coupon_code", "first"),
        paid_registrations=("numero_inscricao", "size"),
    ).reset_index()
    observed = observed.loc[(observed["coupon_title_key"] != "") | (observed["coupon_code_key"] != "")]
    observed.assign(channel_name="", channel_type="", alias_reason="", reviewed=False)[CHANNEL_MAPPING_COLUMNS].to_csv(path, index=False)
```

- [ ] **Step 4: Implement channel assignment with full alias retention**

Join on the tuple `(coupon_title_key, coupon_code_key)` with `validate="many_to_one"`. Fail if any paid non-organic registration is unmatched. Preserve source fields and add `channel_name`, `channel_type`, and `alias_reason` without replacing `coupon_title` or `coupon_code`.

`apply_reviewed_mappings` returns a new frozen `FactBundle` containing the same order fact, the assigned registration fact, the classified product fact, and reconciliation extended with channel/product mapping coverage.

```python
def assign_channels(registrations: pd.DataFrame, mapping: pd.DataFrame) -> pd.DataFrame:
    result = registrations.copy()
    result["coupon_title_key"] = result["coupon_title"].map(normalize_key)
    result["coupon_code_key"] = result["coupon_code"].map(normalize_key)
    organic = (result["coupon_title_key"] == "") & (result["coupon_code_key"] == "")
    result = result.merge(mapping, on=["coupon_title_key", "coupon_code_key"], how="left", validate="many_to_one")
    result.loc[organic, ["channel_name", "channel_type", "alias_reason"]] = ["Orgânico / sem cupom", "organico", "sem cupom"]
    missing = result["is_paid"] & result["channel_name"].isna()
    if missing.any():
        raise ValueError(f"unmapped paid coupon pairs: {int(missing.sum())}")
    return result


def apply_reviewed_mappings(facts: FactBundle, channel_mapping: pd.DataFrame, product_mapping: pd.DataFrame) -> FactBundle:
    registrations = assign_channels(facts.registrations, channel_mapping)
    products = classify_products(facts.products, product_mapping)
    reconciliation = {
        **facts.reconciliation,
        "channel_mapping_coverage_pct": 100.0,
        "product_mapping_coverage_pct": 100.0,
    }
    return FactBundle(facts.orders, registrations, products, reconciliation)
```

- [ ] **Step 5: Implement product draft emission and reviewed classification**

The product draft has these exact columns:

```text
product_id_key,product_name_key,product_id_example,product_name_example,observed_items,canonical_name,classification,classification_reason,reviewed
```

Allowed classifications are `kit_incluso`, `adicional`, and `desconhecido`. A product may expose revenue only when `explicit_unit_value` or `explicit_total_value` exists in the raw product item; otherwise its revenue field remains null.

```python
def classify_products(products: pd.DataFrame, mapping: pd.DataFrame) -> pd.DataFrame:
    result = products.copy()
    result["product_id_key"] = result["product_id"].map(normalize_key)
    result["product_name_key"] = result["product_name"].map(normalize_key)
    result = result.merge(mapping, on=["product_id_key", "product_name_key"], how="left", validate="many_to_one")
    if result["classification"].isna().any():
        raise ValueError(f"unclassified product identities: {int(result['classification'].isna().sum())}")
    result["product_revenue"] = result["explicit_total_value"].where(
        result["explicit_total_value"].notna(),
        result["explicit_unit_value"] * result["product_quantity"],
    )
    return result
```

- [ ] **Step 6: Seed the synthetic reviewed mapping files and verify drafts**

The committed CSVs at this checkpoint contain every synthetic observed identity, including both Corre Criciúma aliases, Sports Week as `evento_acao`, PCD as `politica`, Benefício as `beneficio`, organic, one included shirt, one paid add-on, and one unknown product. Task 8 replaces the synthetic rows with the complete reviewed set from the fresh snapshot before final generation.

- [ ] **Step 7: Run mapping and cumulative gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_mappings -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass; unreviewed or unmatched pairs fail loudly.

- [ ] **Step 8: Commit the mapping checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/mappings.py _codex/analyses/mif_2026_channels/channel_mapping.csv _codex/analyses/mif_2026_channels/product_mapping.csv _codex/tests/mif_2026_channels
git commit -m "feat: add reviewed MIF channel and product mappings"
```

### Task 5: Event metrics, channel dossiers, and dimension-specific similarity

**Files:**
- Create: `_codex/analyses/mif_2026_channels/metrics.py`
- Create: `_codex/tests/mif_2026_channels/test_metrics.py`
- Modify: `_codex/tests/mif_2026_channels/fixtures.py`

**Interfaces:**
- Consumes: mapped `FactBundle`, `FULL_DOSSIER_MIN_REGISTRATIONS`, and `SMALL_CELL_MIN_REGISTRATIONS`.
- Produces: `build_analysis(facts: FactBundle) -> AnalysisResult`, `weighted_ticket(frame: pd.DataFrame, value_column: str, count_column: str | None = None) -> Decimal | None`, `build_channel_dossiers(registrations: pd.DataFrame, orders: pd.DataFrame, products: pd.DataFrame) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]`, and `build_dimension_overlaps(channel_rows: pd.DataFrame) -> dict[str, list[dict[str, Any]]]`.

- [ ] **Step 1: Write failing weighted-ticket and dossier-threshold tests**

```python
# _codex/tests/mif_2026_channels/test_metrics.py
from decimal import Decimal
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.metrics import weighted_ticket, build_channel_dossiers
from _codex.tests.mif_2026_channels.fixtures import channel_metric_frames


class MetricTests(unittest.TestCase):
    def test_overall_ticket_is_not_mean_of_channel_means(self):
        rows = pd.DataFrame([
            {"value": Decimal("1000.00"), "registrations": 10},
            {"value": Decimal("900.00"), "registrations": 1},
        ])
        self.assertEqual(weighted_ticket(rows, "value", "registrations"), Decimal("172.73"))

    def test_full_dossier_threshold_is_ten_paid_registrations(self):
        registrations, orders, products = channel_metric_frames(counts={"Canal A": 10, "Canal B": 9})
        full, compact = build_channel_dossiers(registrations, orders, products)
        self.assertEqual([row["channel_name"] for row in full], ["Canal A"])
        self.assertEqual([row["channel_name"] for row in compact], ["Canal B"])
```

- [ ] **Step 2: Run metrics tests and verify the module is missing**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_metrics -v
```

Expected: failure because `metrics.py` does not exist.

- [ ] **Step 3: Implement event, weekly, lot, modality, and commercial aggregates**

Return anonymous datasets with exact stable IDs:

```text
event_overview
weekly_sales
lot_performance
modality_mix
country_distribution
state_distribution
city_distribution
age_bands
gender_distribution
pace_bands
club_coverage
payment_mix
device_mix
auxiliary_field_coverage
product_summary
channel_index
channel_aliases
channel_modality_mix
channel_state_mix
channel_lot_mix
channel_weekly_sales
channel_product_mix
channel_profile_coverage
geography_overlap
modality_overlap
lot_overlap
temporal_overlap
profile_overlap
product_overlap
long_tail
data_quality
```

Event overview must include paid orders, paid registrations, registrations per order, gross, discounts, fees when covered, net transfer when covered, source-backed cashback when covered, order ticket, registration ticket, coupon-assisted share, organic share, and source field coverage. `lot_performance` includes paid registrations, allocated gross, discounts, registration ticket, and event share for every lot. `auxiliary_field_coverage` records payment method, device, order quantity, questionnaire completion, and other safe JSON-key coverage without exposing free-text answers. Lot and modality sums must reconcile exactly to paid registration counts, with explicit `Não informado` categories.

```python
MONEY_QUANTUM = Decimal("0.01")


def weighted_ticket(frame: pd.DataFrame, value_column: str, count_column: str | None = None) -> Decimal | None:
    total_value = sum(frame[value_column].dropna(), Decimal("0"))
    denominator = len(frame) if count_column is None else int(frame[count_column].fillna(0).sum())
    return None if denominator == 0 else (total_value / denominator).quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP)


def count_distribution(frame: pd.DataFrame, dimension: str) -> list[dict[str, object]]:
    normalized = frame[dimension].fillna("Não informado")
    counts = normalized.value_counts(dropna=False).rename_axis(dimension).reset_index(name="paid_registrations")
    counts["share_pct"] = (counts["paid_registrations"] / len(frame) * 100).round(2)
    return counts.to_dict("records")
```

`build_analysis` filters `facts.orders` and `facts.registrations` by `is_paid` once, derives every registration distribution through `count_distribution`, derives money from allocated registration values or unique order values at the stated grain, and constructs `AnalysisResult` with the stable dataset IDs above.

- [ ] **Step 4: Implement full and compact channel records**

Each full dossier dictionary contains:

```python
{
    "channel_name": str,
    "channel_type": str,
    "touched_paid_orders": int,
    "paid_registrations": int,
    "registrations_per_order": float,
    "gross_value": str,
    "discount_value": str,
    "fee_value": str | None,
    "net_transfer_value": str | None,
    "cashback_value": str | None,
    "allocated_value_per_touched_order": str,
    "registration_ticket": str,
    "share_of_event_registrations": float,
    "coupon_aliases": list[dict[str, object]],
    "geographic_scope": dict[str, object],
    "countries": list[dict[str, object]],
    "modality_mix": list[dict[str, object]],
    "modality_delta_pp": list[dict[str, object]],
    "lot_mix": list[dict[str, object]],
    "lot_delta_pp": list[dict[str, object]],
    "top_states": list[dict[str, object]],
    "top_cities": list[dict[str, object]],
    "weekly_sales": list[dict[str, object]],
    "profile_coverage": dict[str, float],
    "age_bands": list[dict[str, object]],
    "gender_mix": list[dict[str, object]],
    "pace_bands": list[dict[str, object]],
    "club_presence": list[dict[str, object]],
    "product_mix": list[dict[str, object]],
    "profile_delta_pp": list[dict[str, object]],
    "similar_channels_by_dimension": list[dict[str, object]],
    "distinctive_signals": list[dict[str, object]],
    "external_considerations_status": str,
    "data_limitations": list[str],
}
```

Compact records keep channel/type, touched paid orders, paid registrations, gross, registration ticket, principal modality, principal state, all coupon codes, coverage warnings, and the exact `sample_warning="Base abaixo de 10 inscrições pagas; leitura indicativa"`. Sort full and compact records alphabetically, never by an implicit desirability score. Because touched-order counts can overlap between channels, their sum must never be presented as the event order count.

```python
def split_dossiers(rows: list[dict[str, object]]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    full = [row for row in rows if int(row["paid_registrations"]) >= FULL_DOSSIER_MIN_REGISTRATIONS]
    compact = [row for row in rows if int(row["paid_registrations"]) < FULL_DOSSIER_MIN_REGISTRATIONS]
    key = lambda row: str(row["channel_name"]).casefold()
    return sorted(full, key=key), sorted(compact, key=key)
```

- [ ] **Step 5: Implement geography/profile/product coverage rules**

Include countries, Brazilian macroregions, number of represented states/cities, share in the leading state/city, and concentration. For full dossiers, add one descriptive `geographic_scope` backed by visible figures: `nacional` when there are at least 4 Brazilian macroregions, at least 8 UFs, and the leading UF is below 40%; `multirregional` when there are at least 3 macroregions, at least 5 UFs, and the leading UF is below 55%; `local` when one city has at least 60% or one UF has at least 80%; otherwise `regional`. Use `amostra pequena — sem classificação estável` below 10 paid registrations and `internacional/fora do Brasil` only when non-Brazilian registrations are the majority. The label is descriptive evidence, not a strategic score.

Age bands are `<18`, `18–24`, `25–34`, `35–44`, `45–54`, `55–64`, `65+`, `Não informado`, and `Inválido`. Pace bands are `<4:30`, `4:30–4:59`, `5:00–5:29`, `5:30–5:59`, `6:00–6:29`, `6:30–6:59`, `7:00–7:59`, `8:00+`, `Não informado`, and `Inválido`, based on validated seconds per kilometre. Pace and club metrics must include answered, valid, invalid, and missing coverage before any distribution. Country/state/city, dates, money, age, and pace use their `*_status` fields so malformed source values appear in `data_quality` as invalid instead of being merged silently with missing values. Calculate percentage-point differences from the event for modality, lot, geography, age, gender, pace, and product take rate only when both numerator and denominator are visible.

```python
def geographic_scope(paid_registrations: int, macroregions: int, states: int, leading_state_pct: float, leading_city_pct: float, non_brazil_pct: float) -> dict[str, object]:
    if paid_registrations < FULL_DOSSIER_MIN_REGISTRATIONS:
        label = "amostra pequena — sem classificação estável"
    elif non_brazil_pct > 50:
        label = "internacional/fora do Brasil"
    elif macroregions >= 4 and states >= 8 and leading_state_pct < 40:
        label = "nacional"
    elif macroregions >= 3 and states >= 5 and leading_state_pct < 55:
        label = "multirregional"
    elif leading_city_pct >= 60 or leading_state_pct >= 80:
        label = "local"
    else:
        label = "regional"
    return {
        "label": label,
        "macroregions": macroregions,
        "states": states,
        "leading_state_pct": round(leading_state_pct, 2),
        "leading_city_pct": round(leading_city_pct, 2),
        "non_brazil_pct": round(non_brazil_pct, 2),
    }


def percentage_point_delta(channel_count: int, channel_total: int, event_count: int, event_total: int) -> float | None:
    if channel_total == 0 or event_total == 0:
        return None
    return round(channel_count / channel_total * 100 - event_count / event_total * 100, 2)
```

For products, separate `kit_incluso`, `adicional`, and `desconhecido`, reporting take rate by paid registration. Monetary product metrics remain absent when explicit product values are unavailable. Set external sponsorship, Expo space, barter, and courtesy valuation to `não mensurado` unless a separately identified authoritative source is added; never subtract these unknowns from channel value.

- [ ] **Step 6: Implement six separate similarity/overlap views**

For geography, modality, lot, temporal, profile, and add-on product distributions, compute pairwise Jensen-Shannon similarity only when both channels have at least `10` paid registrations and both distributions meet the dimension's coverage rule. Profile comparisons stay separated by `profile_dimension` (`age`, `gender`, `pace`, or `club`) inside `profile_overlap`; do not average those subdimensions. Output one dataset per dimension with `channel_a`, `channel_b`, `similarity_0_1`, `shared_leading_segments`, `coverage_a`, and `coverage_b`. Never combine dimensions into one number and never sort the report as a master rank.

Add `distinctive_signals` only when a channel differs from the event by at least `10` percentage points in a covered segment or is the only qualifying channel covering a country, UF, modality, or reviewed add-on. Always include the underlying count, denominator, event comparison, and coverage. For bases below 30 registrations, prefix the signal with `indício em base pequena`.

```python
def jensen_shannon_similarity(left: dict[str, float], right: dict[str, float]) -> float:
    keys = sorted(set(left) | set(right))
    p = [max(left.get(key, 0.0), 0.0) for key in keys]
    q = [max(right.get(key, 0.0), 0.0) for key in keys]
    p_total, q_total = sum(p), sum(q)
    if p_total == 0 or q_total == 0:
        raise ValueError("similarity requires two non-empty distributions")
    p, q = [value / p_total for value in p], [value / q_total for value in q]
    midpoint = [(a + b) / 2 for a, b in zip(p, q)]
    divergence = 0.5 * sum(a * math.log2(a / m) for a, m in zip(p, midpoint) if a) + 0.5 * sum(b * math.log2(b / m) for b, m in zip(q, midpoint) if b)
    return round(1.0 - math.sqrt(max(divergence, 0.0)), 4)
```

- [ ] **Step 7: Add reconciliation assertions for every aggregate**

Tests must verify:

```python
self.assertEqual(sum(row["paid_registrations"] for row in modality_mix), event_total)
self.assertEqual(sum(row["paid_registrations"] for row in lot_performance), event_total)
self.assertEqual(full_count + compact_count, channel_count)
self.assertEqual(sum(row["paid_registrations"] for row in channel_index), event_total)
```

Also assert no division by zero, no negative share, every percentage is in `0..100`, and all money strings have two decimal places.

- [ ] **Step 8: Run metrics and cumulative gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_metrics -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass and the weighted-ticket regression produces `172.73`.

- [ ] **Step 9: Commit the metrics checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/metrics.py _codex/tests/mif_2026_channels
git commit -m "feat: calculate MIF channel performance dossiers"
```

### Task 6: Privacy guardrails and neutral decision narrative

**Files:**
- Create: `_codex/analyses/mif_2026_channels/privacy.py`
- Create: `_codex/analyses/mif_2026_channels/narrative.py`
- Create: `_codex/tests/mif_2026_channels/test_privacy_narrative.py`

**Interfaces:**
- Consumes: `AnalysisResult`, forbidden keys, full dossiers, dimension overlaps, and coverage metrics.
- Produces: `suppress_small_cells(rows: list[dict[str, Any]], count_key: str, minimum: int = 3) -> list[dict[str, Any]]`, `protect_analysis(result: AnalysisResult) -> AnalysisResult`, `assert_anonymous(payload: Any) -> None`, `describe_event(result: AnalysisResult) -> str`, `describe_channel(dossier: dict[str, Any], event_overview: dict[str, Any]) -> str`, and `build_decision_questions(result: AnalysisResult) -> list[str]`.

- [ ] **Step 1: Write failing privacy and neutrality tests**

```python
# _codex/tests/mif_2026_channels/test_privacy_narrative.py
import unittest

from _codex.analyses.mif_2026_channels.narrative import describe_channel
from _codex.analyses.mif_2026_channels.privacy import assert_anonymous, suppress_small_cells
from _codex.tests.mif_2026_channels.fixtures import event_overview, narrative_dossier


class PrivacyNarrativeTests(unittest.TestCase):
    def test_forbidden_key_and_email_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "email"):
            assert_anonymous({"channel": "A", "email": "pessoa@example.com"})
        with self.assertRaisesRegex(ValueError, "email-like"):
            assert_anonymous({"note": "contato pessoa@example.com"})

    def test_small_cross_tab_cells_are_suppressed(self):
        result = suppress_small_cells([{"state": "SC", "count": 2}, {"state": "PR", "count": 3}], "count")
        self.assertEqual(result, [{"state": "Outros / suprimido", "count": 2, "suppressed": True}, {"state": "PR", "count": 3, "suppressed": False}])

    def test_channel_text_is_evidence_not_keep_cut_advice(self):
        text = describe_channel(narrative_dossier(), event_overview()).lower()
        for forbidden in ("manter", "cortar", "eliminar", "priorizar", "nota", "ranking"):
            self.assertNotIn(forbidden, text)
        self.assertIn("42k", text)
        self.assertIn("cobertura", text)
```

- [ ] **Step 2: Run tests and verify the modules are missing**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_privacy_narrative -v
```

Expected: failure because the privacy and narrative modules do not exist.

- [ ] **Step 3: Implement small-cell suppression without hiding channel totals**

Aggregate suppressed rows into one `Outros / suprimido` row for cross-tabs and preserve the suppressed total. Apply this only to channel-by-city, channel-by-age, channel-by-gender, channel-by-pace, and channel-by-club detail. Do not suppress top-level channel paid-registration totals in `channel_index` or `long_tail`.

```python
def suppress_small_cells(rows: list[dict[str, Any]], count_key: str, minimum: int = 3) -> list[dict[str, Any]]:
    small = [row for row in rows if int(row.get(count_key, 0)) < minimum]
    kept = [{**row, "suppressed": False} for row in rows if int(row.get(count_key, 0)) >= minimum]
    if not small:
        return kept
    label_key = next(key for key in small[0] if key != count_key)
    suppressed = {label_key: "Outros / suprimido", count_key: sum(int(row[count_key]) for row in small), "suppressed": True}
    return [suppressed, *kept]
```

`protect_analysis` applies `suppress_small_cells` to the city, age, gender, pace, and club cross-tab datasets and to the corresponding nested dossier lists, returns a new `AnalysisResult`, and leaves channel totals/long tail unchanged.

- [ ] **Step 4: Implement recursive anonymity checks**

Walk dictionaries and lists recursively. Reject case/accent-normalized keys in `FORBIDDEN_OUTPUT_KEYS`, email-like strings, CPF/CNPJ formatted strings, and Brazilian phone-like strings when the containing field is free text. Permit legitimate anonymous metrics, dates aggregated to week, coupon codes, and money values. Return one error containing the JSON path of every finding.

```python
EMAIL_RE = re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I)
DOCUMENT_RE = re.compile(r"\b(?:\d{3}\.\d{3}\.\d{3}-\d{2}|\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})\b")
PHONE_RE = re.compile(r"(?<!\d)(?:\+?55\s*)?\(?\d{2}\)?\s*9?\d{4}[- ]?\d{4}(?!\d)")


def assert_anonymous(payload: Any) -> None:
    findings: list[str] = []

    def visit(value: Any, path: str, key_name: str = "") -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                if normalize_key(key).lower().replace(" ", "_") in FORBIDDEN_OUTPUT_KEYS:
                    findings.append(f"{path}.{key}: forbidden key")
                visit(child, f"{path}.{key}", str(key))
        elif isinstance(value, list):
            for index, child in enumerate(value):
                visit(child, f"{path}[{index}]", key_name)
        elif isinstance(value, str):
            if EMAIL_RE.search(value):
                findings.append(f"{path}: email-like value")
            if DOCUMENT_RE.search(value):
                findings.append(f"{path}: document-like value")
            if key_name in {"body", "note", "description", "summary"} and PHONE_RE.search(value):
                findings.append(f"{path}: phone-like value")

    visit(payload, "$")
    if findings:
        raise ValueError("; ".join(findings))
```

- [ ] **Step 5: Implement deterministic evidence-first narratives**

Channel summaries must state paid registrations/orders, event share, modality mix, geographic spread/concentration, lot timing, average ticket, add-on take rate, available profile coverage, and source aliases. Use comparative statements only when a denominator and coverage exist. End with `Limitações de leitura` rather than a recommendation.

Event narrative must explain the correct grains, non-additive touched-order counts, and weighted tickets. Sports Week gets the same full evidence treatment as any strategic channel. PCD and Benefício texts explicitly state `mecanismo/política no cadastro, não presumido como parceiro comercial` unless reviewed mapping evidence assigns a commercial partner.

```python
def describe_channel(dossier: dict[str, Any], event_overview: dict[str, Any]) -> str:
    scope = dossier["geographic_scope"]["label"]
    leading_modality = dossier["modality_mix"][0]
    limitations = "; ".join(dossier["data_limitations"]) or "nenhuma limitação adicional identificada"
    return (
        f"O canal registrou {dossier['paid_registrations']} inscrições pagas em "
        f"{dossier['touched_paid_orders']} pedidos tocados, com {dossier['share_of_event_registrations']:.2f}% "
        f"das inscrições do evento e ticket por inscrição de R$ {dossier['registration_ticket']}. "
        f"A abrangência observada é {scope}; a modalidade mais frequente é "
        f"{leading_modality['modality']} ({leading_modality['share_pct']:.2f}%). "
        f"Cobertura dos campos de perfil: {dossier['profile_coverage']}. "
        f"Limitações de leitura: {limitations}."
    )
```

- [ ] **Step 6: Build human decision questions instead of a score**

Generate questions grounded in the overlap datasets, for example:

```python
[
    "Quais canais cobrem estados ou modalidades pouco atendidos pelos demais?",
    "Quais pares apresentam público semelhante na mesma dimensão e merecem revisão contratual conjunta?",
    "Onde a concentração regional é intencional e onde ela limita alcance?",
    "Quais canais têm mix de modalidade ou adicional realmente distinto, com cobertura suficiente para sustentar a leitura?",
]
```

Do not attach yes/no answers or an action label.

- [ ] **Step 7: Run privacy, narrative, and cumulative gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_privacy_narrative -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass; direct identifiers and keep/cut language are rejected.

- [ ] **Step 8: Commit the privacy and narrative checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/privacy.py _codex/analyses/mif_2026_channels/narrative.py _codex/tests/mif_2026_channels
git commit -m "feat: add anonymous neutral MIF study narrative"
```

### Task 7: Canonical report artifact and end-to-end CLI

**Files:**
- Create: `_codex/analyses/mif_2026_channels/artifact.py`
- Create: `_codex/analyses/mif_2026_channels/pipeline.py`
- Create: `_codex/analyses/mif_2026_channels/run.py`
- Create: `_codex/tests/mif_2026_channels/test_artifact_pipeline.py`
- Modify: `_codex/analyses/mif_2026_channels/models.py`
- Modify: `_codex/tests/mif_2026_channels/fixtures.py`

**Interfaces:**
- Consumes: `SourceBundle`, `FactBundle`, reviewed mapping files, `AnalysisResult`, narrative/privacy functions, and source metadata.
- Produces: `build_report_artifact(result: AnalysisResult, generated_at: str) -> dict[str, Any]`, `run_analysis(orders_path: Path, participants_path: Path, channel_mapping_path: Path, product_mapping_path: Path, output_dir: Path, allow_stale: bool = False) -> dict[str, Path]`, `write_json(path: Path, payload: Any) -> None`, and CLI exit status `0` only after all validations pass.

- [ ] **Step 1: Write failing canonical-artifact and end-to-end tests**

```python
# _codex/tests/mif_2026_channels/test_artifact_pipeline.py
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import unittest

from _codex.analyses.mif_2026_channels.artifact import build_report_artifact
from _codex.analyses.mif_2026_channels.pipeline import run_analysis
from _codex.tests.mif_2026_channels.fixtures import analysis_result, write_source_exports, write_reviewed_mappings


class ArtifactPipelineTests(unittest.TestCase):
    def test_artifact_uses_report_surface_and_source_backed_blocks(self):
        artifact = build_report_artifact(analysis_result(), "2026-08-30T22:00:00-03:00")
        self.assertEqual(artifact["surface"], "report")
        self.assertEqual(artifact["manifest"]["title"], "Maratona de Floripa 2026 — estudo de vendas e canais")
        self.assertTrue(artifact["manifest"]["blocks"])
        self.assertEqual(artifact["snapshot"]["status"], "ready")
        self.assertIn("channel_index", artifact["snapshot"]["datasets"])
        self.assertEqual({source["id"] for source in artifact["sources"]}, {"ticketsports_orders_72611", "ticketsports_participants_72611"})

    def test_pipeline_writes_only_anonymous_outputs(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_map, product_map = write_reviewed_mappings(root)
            paths = run_analysis(orders, participants, channel_map, product_map, root / "report", allow_stale=True)
            artifact_text = paths["artifact"].read_text(encoding="utf-8")
            self.assertNotIn("pessoa@example.com", artifact_text.lower())
            self.assertTrue(paths["reconciliation"].exists())
            self.assertTrue(paths["source_notes"].exists())
```

- [ ] **Step 2: Run tests and verify artifact/pipeline modules are missing**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_artifact_pipeline -v
```

Expected: failure because `artifact.py` and `pipeline.py` do not exist.

- [ ] **Step 3: Implement a bounded canonical report artifact**

The top-level contract is:

```python
{
    "surface": "report",
    "manifest": {
        "title": "Maratona de Floripa 2026 — estudo de vendas e canais",
        "blocks": list,
        "cards": list,
        "charts": list,
        "tables": list,
        "sources": list,
    },
    "snapshot": {
        "version": 1,
        "generatedAt": generated_at,
        "status": "ready",
        "datasets": result.datasets,
    },
    "sources": list,
    "package_info": {
        "event_code": 72611,
        "pipeline_version": "1.0.0",
        "full_dossier_min_registrations": 10,
        "small_cell_min_registrations": 3,
    },
}
```

The first block is Markdown beginning with the exact same `#` title. Then add: executive summary, metric strip, methodology/grains, weekly sales, lots, modalities, geography, profile and auxiliary-field coverage, products, channel index, one alphabetical section per full dossier, compact long-tail table, six separate overlap sections, decision questions, limitations, source definitions, and reconciliation.

Use native metric-strip, chart, table, and Markdown blocks only. Every data-backed card/chart/table has `sourceId`; every source ID appears in both `manifest.sources` and top-level `sources` with the real table name, `cod_evento = 72611`, paid-status rule, extraction time, and metric definition. The artifact's visible source SQL is aggregate-only (`SELECT cod_evento, COUNT(*) AS source_rows ... GROUP BY cod_evento`) so technical order/registration identifiers and their values never enter the HTML; the reproducible row-level extraction remains in the versioned SQL file outside the report payload. Provide a channel index and heading anchors so browser text search and document navigation can find every channel.

- [ ] **Step 4: Define native charts and tables with stable IDs**

Use line charts for weekly sales, horizontal bars for country/state/city/product counts, stacked bars for modality/lot mixes, and tables for exact commercial figures and long-tail channels. For every full dossier, include compact modality and lot charts; include a geography chart only when at least 70% of registrations have valid geography. Every chart title or adjacent Markdown block states the paid-registration base, period, unit, and denominator. Store the chart rationale in `source_notes.json` as:

```python
{
    "weekly_sales": "line: chronological change and closing-period acceleration",
    "modality_mix": "stacked bar: comparable composition across channels",
    "country_distribution": "horizontal bar: ranked observed country reach",
    "state_distribution": "horizontal bar: ranked categorical concentration",
    "channel_distribution": "horizontal bar: exact volume and event share without a desirability score",
    "lot_performance": "stacked bar: volume and ticket by ordered lot",
    "product_summary": "horizontal bar: add-on take rate by canonical product",
    "dimension_overlaps": "table: exact pairwise evidence without visual rank implication",
}
```

Use BRL formatting for money, Brazilian Portuguese labels, ISO dates in data, and display dates as `dd/mm/aaaa` or week labels. Use labels, patterns, or direct values in addition to color; do not use radar charts, decorative charts, or any chart implying an aggregate desirability score.

- [ ] **Step 5: Implement pipeline serialization and immutable output receipts**

`run_analysis` must execute this sequence: `load_sources` → `build_fact_bundle` → `load_channel_mapping`/`load_product_mapping` → `apply_reviewed_mappings` → `build_analysis` → small-cell suppression → narrative generation → anonymity scan → artifact generation → JSON serialization. Write JSON with UTF-8, `ensure_ascii=False`, sorted keys where order is not semantically significant, and atomic replace from a sibling `.tmp` file.

Return paths under these exact keys: `artifact`, `aggregates`, `reconciliation`, and `source_notes`. Do not write raw facts to the report directory.

```python
def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
    temporary.replace(path)


def run_analysis(
    orders_path: Path,
    participants_path: Path,
    channel_mapping_path: Path,
    product_mapping_path: Path,
    output_dir: Path,
    allow_stale: bool = False,
) -> dict[str, Path]:
    sources = load_sources(orders_path, participants_path, EVENT_CODE, allow_stale)
    facts = build_fact_bundle(sources)
    mapped = apply_reviewed_mappings(
        facts,
        load_channel_mapping(channel_mapping_path),
        load_product_mapping(product_mapping_path),
    )
    result = protect_analysis(build_analysis(mapped))
    aggregate_payload = dataclasses.asdict(result)
    assert_anonymous(aggregate_payload)
    generated_at = max(snapshot.extracted_at for snapshot in sources.snapshots)
    artifact_payload = build_report_artifact(result, generated_at)
    assert_anonymous(artifact_payload)
    paths = {
        "artifact": output_dir / "artifact.json",
        "aggregates": output_dir / "aggregates.json",
        "reconciliation": output_dir / "reconciliation.json",
        "source_notes": output_dir / "source_notes.json",
    }
    write_json(paths["artifact"], artifact_payload)
    write_json(paths["aggregates"], aggregate_payload)
    write_json(paths["reconciliation"], mapped.reconciliation)
    write_json(paths["source_notes"], result.source_notes)
    return paths
```

- [ ] **Step 6: Implement three explicit CLI modes**

```text
python -m _codex.analyses.mif_2026_channels.run draft-mappings --orders PATH --participants PATH --channel-output PATH --product-output PATH --allow-stale
python -m _codex.analyses.mif_2026_channels.run analyze --orders PATH --participants PATH --channel-map PATH --product-map PATH --output-dir PATH [--allow-stale]
python -m _codex.analyses.mif_2026_channels.run verify --artifact PATH --aggregates PATH --reconciliation PATH --source-notes PATH
```

`draft-mappings` emits observed identities but never marks them reviewed. `analyze` defaults to fresh-source enforcement. `verify` reruns reconciliation, schema, coverage, source-reference, neutrality, and anonymity checks without needing raw data.

- [ ] **Step 7: Run end-to-end and cumulative unit gates**

```bash
$MIF_PYTHON -m unittest _codex.tests.mif_2026_channels.test_artifact_pipeline -v
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
```

Expected: all tests pass; the synthetic pipeline writes four anonymous JSON files.

- [ ] **Step 8: Validate a synthetic artifact with the canonical validator and report builder**

Generate the synthetic artifact in a temporary test directory, pass its JSON to the Data Analytics `validate_artifact` tool, and require no validation errors. Then run:

```bash
$MIF_NODE $MIF_REPORT_PLUGIN/skills/build-report/scripts/deliver_portable_artifact.mjs --input /private/tmp/mif-2026-artifact-test/artifact.json --output /private/tmp/mif-2026-artifact-test/report.html
```

Expected: exit code `0`, a self-contained HTML file, and a delivery receipt with `verification: passed`. A `structural_only` receipt is not the final acceptance gate because desktop/mobile/print validation remains required.

- [ ] **Step 9: Commit the artifact and pipeline checkpoint when authorized**

```bash
git add _codex/analyses/mif_2026_channels/artifact.py _codex/analyses/mif_2026_channels/pipeline.py _codex/analyses/mif_2026_channels/run.py _codex/analyses/mif_2026_channels/models.py _codex/tests/mif_2026_channels
git commit -m "feat: generate portable MIF channel study artifact"
```

### Task 8: Fresh 2026 snapshot, reviewed mappings, final HTML, and audit

**Files:**
- Modify: `_codex/analyses/mif_2026_channels/channel_mapping.csv`
- Modify: `_codex/analyses/mif_2026_channels/product_mapping.csv`
- Generate: `_codex/reports/mif-2026-channel-study/artifact.json`
- Generate: `_codex/reports/mif-2026-channel-study/aggregates.json`
- Generate: `_codex/reports/mif-2026-channel-study/reconciliation.json`
- Generate: `_codex/reports/mif-2026-channel-study/source_notes.json`
- Generate: `_codex/reports/mif-2026-channel-study/report.html`

**Interfaces:**
- Consumes: fresh event-scoped exports, final reviewed mappings, CLI from Task 7, canonical report builder, and all prior verification gates.
- Produces: a final anonymous, source-backed, self-contained HTML report and its reviewable canonical inputs.

- [ ] **Step 1: Acquire and fingerprint fresh event-scoped exports**

Create the exact external directory `/private/tmp/mif-2026-channel-study-source`. Run `_codex/sql/2026-08-30_mif_2026_channel_sales_extract.sql` through an existing configured read-only connection and export:

```text
/private/tmp/mif-2026-channel-study-source/orders_72611.xlsx
/private/tmp/mif-2026-channel-study-source/participants_72611.xlsx
```

If the connection is not available, request those two updated exports from the user and place them at the same paths. Confirm that both contain only `cod_evento = 72611`, both include the SQL-emitted `extracted_at` column, and that their extraction time is on or after `2026-08-30T00:00:00-03:00`.

- [ ] **Step 2: Generate complete unreviewed mapping drafts**

```bash
$MIF_PYTHON -m _codex.analyses.mif_2026_channels.run draft-mappings \
  --orders /private/tmp/mif-2026-channel-study-source/orders_72611.xlsx \
  --participants /private/tmp/mif-2026-channel-study-source/participants_72611.xlsx \
  --channel-output _codex/analyses/mif_2026_channels/channel_mapping.draft.csv \
  --product-output _codex/analyses/mif_2026_channels/product_mapping.draft.csv
```

Expected: both draft files exist, every observed nonblank coupon tuple appears exactly once, and every observed product identity appears exactly once.

- [ ] **Step 3: Review and replace the complete channel mapping**

Review each draft row against its exact title/code pair. Merge only aliases supported by the name/code evidence; otherwise retain a distinct channel. Preserve the approved Corre Criciúma consolidation for `CORRECRICIUMA` and `CORRECRICIUMA_100` if both remain in the fresh source. Classify Sports Week as `evento_acao`, PCD as `politica`, and Benefício as `beneficio` unless a separately managed partner is proven. Set a concrete `alias_reason` and `reviewed=true` for every row, then replace `channel_mapping.csv` with the complete reviewed file.

Run this coverage check:

```bash
$MIF_PYTHON -m _codex.analyses.mif_2026_channels.run analyze \
  --orders /private/tmp/mif-2026-channel-study-source/orders_72611.xlsx \
  --participants /private/tmp/mif-2026-channel-study-source/participants_72611.xlsx \
  --channel-map _codex/analyses/mif_2026_channels/channel_mapping.csv \
  --product-map _codex/analyses/mif_2026_channels/product_mapping.draft.csv \
  --output-dir /private/tmp/mif-2026-channel-map-check
```

Expected: it may fail only because the product draft is unreviewed; it must not report an unmatched or unreviewed channel row.

- [ ] **Step 4: Review and replace the complete product mapping**

For every observed product identity, choose `kit_incluso`, `adicional`, or `desconhecido` based only on source identity and documented event kit knowledge. Assign a canonical product name, write a concrete `classification_reason`, set `reviewed=true`, and replace `product_mapping.csv`. Leave ambiguous items `desconhecido`; do not convert a product name into a price.

- [ ] **Step 5: Generate final anonymous JSON artifacts**

```bash
$MIF_PYTHON -m _codex.analyses.mif_2026_channels.run analyze \
  --orders /private/tmp/mif-2026-channel-study-source/orders_72611.xlsx \
  --participants /private/tmp/mif-2026-channel-study-source/participants_72611.xlsx \
  --channel-map _codex/analyses/mif_2026_channels/channel_mapping.csv \
  --product-map _codex/analyses/mif_2026_channels/product_mapping.csv \
  --output-dir _codex/reports/mif-2026-channel-study
```

Expected: four JSON files are written; the run fails if the source is stale, a mapping is incomplete, paid sales do not reconcile, coverage is missing from a displayed profile metric, or anonymity scanning finds a direct identifier.

- [ ] **Step 6: Run the independent JSON verification gate**

```bash
$MIF_PYTHON -m _codex.analyses.mif_2026_channels.run verify \
  --artifact _codex/reports/mif-2026-channel-study/artifact.json \
  --aggregates _codex/reports/mif-2026-channel-study/aggregates.json \
  --reconciliation _codex/reports/mif-2026-channel-study/reconciliation.json \
  --source-notes _codex/reports/mif-2026-channel-study/source_notes.json
```

Expected: exit code `0` and a summary confirming event `72611`, fresh source hashes, exact category reconciliations, `100%` reviewed mapping coverage, no forbidden identifiers, no master score/rank, and both full/compact channel coverage.

- [ ] **Step 7: Validate the canonical artifact before delivery**

Pass `_codex/reports/mif-2026-channel-study/artifact.json` to the Data Analytics `validate_artifact` tool. Require a valid report surface, resolvable source IDs, valid native block/chart/table contracts, and no artifact errors before invoking the builder.

- [ ] **Step 8: Build the final self-contained HTML**

```bash
$MIF_NODE $MIF_REPORT_PLUGIN/skills/build-report/scripts/deliver_portable_artifact.mjs \
  --input _codex/reports/mif-2026-channel-study/artifact.json \
  --output _codex/reports/mif-2026-channel-study/report.html
```

Expected: exit code `0`, the HTML contains no external data dependency, and the receipt reports `verification: passed`.

- [ ] **Step 9: Perform desktop, mobile, print, navigation, and content QA**

Open the final HTML locally. Verify at desktop and narrow mobile widths that title, executive metrics, charts, tables, full dossiers, compact long tail, overlap sections, sources, and limitations render without clipping. Use browser find for `Corre Criciúma`, `Sports Week`, `PCD`, and one channel below `10`; each must be discoverable. Open print preview and confirm page breaks do not hide headers or split metric values illegibly.

Search the rendered HTML text for email patterns, CPF/CNPJ formatting, phone patterns, `numero_pedido`, `numero_inscricao`, and synthetic test identities; all must be absent. Search for `ranking`, `score`, `manter`, `cortar`, `eliminar`, and `priorizar`; none may appear as an automatic channel verdict.

- [ ] **Step 10: Run final repository gates**

```bash
$MIF_PYTHON -m unittest discover -s _codex/tests/mif_2026_channels -p 'test_*.py' -v
git diff --check
git status --short
```

Expected: all tests pass; `git diff --check` prints nothing; status contains only the planned analysis package, SQL, tests, reviewed mappings, plan, and anonymous report artifacts. No `/inscricoes/` path and no raw export may appear.

- [ ] **Step 11: Open the finished report for user review**

Open `_codex/reports/mif-2026-channel-study/report.html` in the Codex file/browser panel and report the exact paid-order count, paid-registration count, gross value, full-dossier count, compact-channel count, source extraction timestamp, and verification receipt. State any source-field coverage limitation that materially affects interpretation.

- [ ] **Step 12: Commit the final study when authorized**

```bash
git add docs/superpowers/plans/2026-08-30-mif-2026-channel-sales-study.md \
  _codex/analyses/mif_2026_channels/channel_mapping.csv \
  _codex/analyses/mif_2026_channels/product_mapping.csv \
  _codex/reports/mif-2026-channel-study
git commit -m "docs: publish MIF 2026 channel sales study"
```

Do not add `/private/tmp/mif-2026-channel-study-source` or the two ignored mapping drafts. Ask the user before deleting the exact temporary raw-source directory; if approved, remove only that directory and state that the raw extracts are no longer locally recoverable from the workspace.
