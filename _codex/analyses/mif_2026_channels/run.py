"""Command-line entry point for the MIF 2026 channel study pipeline."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any
from uuid import UUID

from .artifact import REPORT_APP_ID
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
    for query_id, query in queries.items():
        if not isinstance(query.get("rows"), list):
            raise ValueError(f"query rows must be a list: {query_id}")
        source = query.get("source", {})
        definitions = source.get("metricDefinitions")
        if not source.get("tables") or not isinstance(definitions, list) or not definitions:
            raise ValueError(f"incomplete source metadata: {query_id}")
        if any(not definition.get("componentIds") for definition in definitions):
            raise ValueError(f"unscoped metric definition: {query_id}")
        sql = str(source.get("sql", ""))
        if "COUNT(*)" not in sql or "GROUP BY cod_evento" not in sql:
            raise ValueError(f"source SQL is not aggregate-only: {query_id}")

    datasets = aggregates.get("datasets")
    if not isinstance(datasets, dict) or set(datasets) != set(DATASET_IDS):
        raise ValueError("aggregate receipt dataset contract mismatch")
    overview = aggregates.get("overview", {})
    event_total = int(overview.get("paid_registrations", 0))
    for query_id in ("channel_index", "modality_mix", "lot_performance"):
        total = sum(int(row.get("paid_registrations", 0)) for row in datasets[query_id])
        if total != event_total:
            raise ValueError(f"reconciliation mismatch for {query_id}")
    if int(reconciliation.get("paid_registration_count", -1)) != event_total:
        raise ValueError("receipt paid-registration count does not reconcile")
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

