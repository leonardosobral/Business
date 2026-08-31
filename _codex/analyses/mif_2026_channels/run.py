"""Command-line entry point for the MIF 2026 channel study pipeline."""

from __future__ import annotations

import argparse
from decimal import Decimal
import json
from pathlib import Path
import re
import sys
from typing import Any
from types import SimpleNamespace
from uuid import UUID

from .artifact import REPORT_APP_ID, report_component_catalog, report_component_map
from .config import EVENT_CODE
from .facts import build_fact_bundle
from .mappings import emit_channel_mapping_draft, emit_product_mapping_draft
from .metrics import DATASET_IDS
from .pipeline import CHART_RATIONALES, run_analysis
from .privacy import assert_anonymous
from .source import load_sources


_RAW_BOUNDARY_KEYS = frozenset(
    {"facts", "raw_facts", "numero_pedido", "numero_inscricao", "body"}
)
_FORBIDDEN_DECISION_LANGUAGE = re.compile(
    r"\b(?:score|rank(?:ed|ing)?|keep[\s_/-]*cut)\b", re.IGNORECASE
)


def _read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _reject_raw_boundary(value: Any, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = str(key).strip().lower()
            if normalized in _RAW_BOUNDARY_KEYS:
                raise ValueError(f"forbidden raw-data key at {path}.{key}")
            _reject_raw_boundary(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_raw_boundary(child, f"{path}[{index}]")


def _reject_decision_language(value: Any, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if _FORBIDDEN_DECISION_LANGUAGE.search(str(key)):
                raise ValueError(f"forbidden decision field at {path}.{key}: {key}")
            _reject_decision_language(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_decision_language(child, f"{path}[{index}]")
    elif isinstance(value, str) and _FORBIDDEN_DECISION_LANGUAGE.search(value):
        token = _FORBIDDEN_DECISION_LANGUAGE.search(value).group(0)
        raise ValueError(f"forbidden decision language at {path}: {token}")


def _validate_reconciliation(
    overview: dict[str, Any], reconciliation: dict[str, Any], source_notes: dict[str, Any]
) -> None:
    event_orders = int(overview.get("paid_orders", -1))
    event_registrations = int(overview.get("paid_registrations", -1))
    if int(reconciliation.get("paid_order_count", -2)) != event_orders:
        raise ValueError("receipt paid-order count does not reconcile")
    if int(reconciliation.get("paid_registration_count", -2)) != event_registrations:
        raise ValueError("receipt paid-registration count does not reconcile")
    if Decimal(str(reconciliation.get("paid_order_gross", "NaN"))) != Decimal(
        str(overview.get("gross_value", "NaN"))
    ):
        raise ValueError("receipt paid-order gross does not reconcile")
    if Decimal(str(reconciliation.get("allocated_registration_gross", "NaN"))) != Decimal(
        str(overview.get("gross_value", "NaN"))
    ):
        raise ValueError("allocated registration gross does not reconcile")
    for key in (
        "channel_mapping_coverage_pct",
        "product_mapping_coverage_pct",
        "registration_join_coverage_pct",
    ):
        value = float(reconciliation.get(key, -1))
        if not 0 <= value <= 100:
            raise ValueError(f"invalid reconciliation coverage: {key}")
    sources = source_notes.get("sources")
    if not isinstance(sources, list) or {source.get("source_id") for source in sources} != {
        "orders",
        "participants",
    }:
        raise ValueError("source receipt must identify orders and participants")
    expected_rows = {
        "orders": int(reconciliation.get("source_order_rows", -1)),
        "participants": int(reconciliation.get("source_registration_rows", -1)),
    }
    for source in sources:
        source_id = source["source_id"]
        if source.get("event_code") != EVENT_CODE:
            raise ValueError(f"source event code mismatch: {source_id}")
        if int(source.get("row_count", -2)) != expected_rows[source_id]:
            raise ValueError(f"source row count mismatch: {source_id}")
        if not re.fullmatch(r"[0-9a-f]{64}", str(source.get("sha256", ""))):
            raise ValueError(f"invalid source hash: {source_id}")
        if not source.get("file_name") or not source.get("extracted_at"):
            raise ValueError(f"incomplete source receipt: {source_id}")


def verify_outputs(
    report_data_path: Path,
    aggregates_path: Path,
    reconciliation_path: Path,
    source_notes_path: Path,
) -> None:
    """Validate the canonical snapshot and receipts without raw exports."""
    snapshot = _read_json(report_data_path)
    aggregates = _read_json(aggregates_path)
    reconciliation = _read_json(reconciliation_path)
    source_notes = _read_json(source_notes_path)
    payloads = (snapshot, aggregates, reconciliation, source_notes)
    for payload in payloads:
        _reject_raw_boundary(payload)
        _reject_decision_language(payload)
        assert_anonymous(payload)

    if snapshot.get("id") != REPORT_APP_ID:
        raise ValueError("report app ID does not match the stable contract")
    UUID(snapshot["id"])
    if snapshot.get("surface") != "report":
        raise ValueError("report surface is required")
    if snapshot.get("status") not in {"fixture", "ready"}:
        raise ValueError("snapshot status must be fixture or ready")
    if snapshot.get("filters") != []:
        raise ValueError("report snapshot must not contain hidden filters")
    queries = snapshot.get("queries")
    if not isinstance(queries, dict) or set(queries) != set(DATASET_IDS):
        raise ValueError("snapshot must contain the 31 stable queries")
    datasets = aggregates.get("datasets")
    if not isinstance(datasets, dict) or set(datasets) != set(DATASET_IDS):
        raise ValueError("aggregate receipt dataset contract mismatch")
    aggregate_result = SimpleNamespace(
        datasets=datasets,
        full_dossiers=aggregates.get("full_dossiers", []),
    )
    expected_catalog = report_component_catalog(aggregate_result)
    expected_component_map = report_component_map(aggregate_result)
    if snapshot.get("componentCatalog") != expected_catalog:
        raise ValueError("report component catalog mismatch")
    referenced_components: set[str] = set()
    for query_id, query in queries.items():
        if not isinstance(query.get("rows"), list):
            raise ValueError(f"query rows must be a list: {query_id}")
        if query["rows"] != datasets[query_id]:
            raise ValueError(f"query rows mismatch aggregate receipt: {query_id}")
        source = query.get("source", {})
        definitions = source.get("metricDefinitions")
        if not source.get("tables") or not isinstance(definitions, list) or not definitions:
            raise ValueError(f"incomplete source metadata: {query_id}")
        if any(not isinstance(definition.get("componentIds"), list) for definition in definitions):
            raise ValueError(f"invalid component scope: {query_id}")
        query_components: set[str] = set()
        for definition in definitions:
            component_ids = definition["componentIds"]
            unknown = set(component_ids) - set(expected_component_map[query_id])
            if unknown:
                raise ValueError(
                    f"source definition references nonexistent component: {query_id}"
                )
            referenced_components.update(component_ids)
            query_components.update(component_ids)
        if query_components != set(expected_component_map[query_id]):
            raise ValueError(f"incomplete component source scope: {query_id}")
        sql = str(source.get("sql", ""))
        if "COUNT(*)" not in sql or "GROUP BY cod_evento" not in sql:
            raise ValueError(f"source SQL is not aggregate-only: {query_id}")

    if referenced_components != set(expected_catalog):
        raise ValueError("not every report component has source metadata")
    overview = aggregates.get("overview", {})
    event_total = int(overview.get("paid_registrations", 0))
    for query_id in ("channel_index", "modality_mix", "lot_performance"):
        total = sum(int(row.get("paid_registrations", 0)) for row in datasets[query_id])
        if total != event_total:
            raise ValueError(f"reconciliation mismatch for {query_id}")
    _validate_reconciliation(overview, reconciliation, source_notes)
    if source_notes.get("chart_rationales") != CHART_RATIONALES:
        raise ValueError("chart rationale receipt is incomplete")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    draft = commands.add_parser("draft-mappings")
    draft.add_argument("--orders", type=Path, required=True)
    draft.add_argument("--participants", type=Path, required=True)
    draft.add_argument("--channel-output", type=Path, required=True)
    draft.add_argument("--product-output", type=Path, required=True)
    draft.add_argument("--allow-stale", action="store_true")

    analyze = commands.add_parser("analyze")
    analyze.add_argument("--orders", type=Path, required=True)
    analyze.add_argument("--participants", type=Path, required=True)
    analyze.add_argument("--channel-map", type=Path, required=True)
    analyze.add_argument("--product-map", type=Path, required=True)
    analyze.add_argument("--output-dir", type=Path, required=True)
    analyze.add_argument("--allow-stale", action="store_true")

    verify = commands.add_parser("verify")
    verify.add_argument("--report-data", type=Path, required=True)
    verify.add_argument("--aggregates", type=Path, required=True)
    verify.add_argument("--reconciliation", type=Path, required=True)
    verify.add_argument("--source-notes", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "draft-mappings":
            sources = load_sources(
                args.orders,
                args.participants,
                EVENT_CODE,
                allow_stale=args.allow_stale,
            )
            facts = build_fact_bundle(sources)
            args.channel_output.parent.mkdir(parents=True, exist_ok=True)
            args.product_output.parent.mkdir(parents=True, exist_ok=True)
            emit_channel_mapping_draft(facts.registrations, args.channel_output)
            emit_product_mapping_draft(facts.products, args.product_output)
            print("draft mappings written; every row remains unreviewed")
        elif args.command == "analyze":
            paths = run_analysis(
                args.orders,
                args.participants,
                args.channel_map,
                args.product_map,
                args.output_dir,
                allow_stale=args.allow_stale,
            )
            print(json.dumps({key: str(path) for key, path in paths.items()}, sort_keys=True))
        else:
            verify_outputs(
                args.report_data,
                args.aggregates,
                args.reconciliation,
                args.source_notes,
            )
            print("verification passed")
    except (AssertionError, KeyError, OSError, TypeError, ValueError) as error:
        print(f"{args.command} failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
