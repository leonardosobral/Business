"""Command-line entry point for the MIF 2026 channel study pipeline."""

from __future__ import annotations

import argparse
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
import json
from pathlib import Path
import re
import sys
from typing import Any
from types import SimpleNamespace
from uuid import UUID

from .artifact import (
    REPORT_APP_ID,
    build_source_metadata,
    report_qualification,
    report_component_catalog,
    report_component_map,
)
from .config import EVENT_CODE
from .facts import build_fact_bundle
from .mappings import emit_channel_mapping_draft, emit_product_mapping_draft
from .metrics import AUXILIARY_FIELD_CONTRACT, DATASET_IDS
from .pipeline import CHART_RATIONALES, run_analysis, source_qualification
from .privacy import assert_anonymous
from .source import (
    ALLOW_STALE_EXTRACTION_MARKER,
    FINAL_EXTRACTION_MIN_TIMESTAMP,
    load_sources,
    parse_extraction_timestamp,
)


_RAW_BOUNDARY_KEYS = frozenset(
    {"facts", "raw_facts", "numero_pedido", "numero_inscricao", "body"}
)
_FORBIDDEN_DECISION_LANGUAGE = re.compile(
    r"\b(?:score|rank(?:ed|ing)?|keep[\s_/-]*cut)\b", re.IGNORECASE
)
_READY_DEVELOPMENT_LANGUAGE = re.compile(
    r"fixture|base sint[ée]tica|task\s*[78]|serve apenas para provar",
    re.IGNORECASE,
)
_REGISTRATION_PARTITION_CONTRACTS = {
    "weekly_sales": None,
    "lot_performance": "event_denominator",
    "modality_mix": "denominator",
    "country_distribution": "denominator",
    "state_distribution": "denominator",
    "city_distribution": "denominator",
    "age_bands": "denominator",
    "gender_distribution": "denominator",
    "pace_bands": "denominator",
    "channel_index": None,
}
_ORDER_PARTITION_CONTRACTS = {
    "payment_mix": "denominator",
    "device_mix": "denominator",
}
_FULL_CHANNEL_PARTITIONS = (
    "channel_modality_mix",
    "channel_lot_mix",
    "channel_weekly_sales",
)
_MONEY_QUANTUM = Decimal("0.01")
_FINANCIAL_COMPONENTS = (
    (
        "gross",
        "gross_order_value",
        "gross_value",
        "paid_order_gross",
        "allocated_registration_gross",
        "required",
    ),
    (
        "discount",
        "discount_value",
        "discount_value",
        "paid_order_discount",
        "allocated_registration_discount",
        "explicit_zero",
    ),
    (
        "fee",
        "fee_value",
        "fee_value",
        "paid_order_fee",
        "allocated_registration_fee",
        "optional",
    ),
    (
        "net transfer",
        "net_transfer_value",
        "net_transfer_value",
        "paid_order_net_transfer",
        "allocated_registration_net_transfer",
        "optional",
    ),
    (
        "cashback",
        "cashback_value",
        "cashback_value",
        "paid_order_cashback",
        "allocated_registration_cashback",
        "optional",
    ),
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


def _reject_ready_development_language(value: Any, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if _READY_DEVELOPMENT_LANGUAGE.search(str(key)):
                raise ValueError(f"ready snapshot contains development language at {path}.{key}")
            _reject_ready_development_language(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_ready_development_language(child, f"{path}[{index}]")
    elif isinstance(value, str) and _READY_DEVELOPMENT_LANGUAGE.search(value):
        raise ValueError(f"ready snapshot contains development language at {path}")


def _required_decimal(value: object, label: str) -> Decimal:
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError) as error:
        raise ValueError(f"invalid financial receipt: {label}") from error
    if not parsed.is_finite():
        raise ValueError(f"invalid financial receipt: {label}")
    return parsed


def _money_coverage(
    reconciliation: dict[str, Any], source_field: str, paid_orders: int, label: str
) -> tuple[int, int, int]:
    coverage = reconciliation.get("paid_order_field_coverage", {}).get(source_field)
    if paid_orders == 0 and coverage is None:
        return 0, 0, 0
    if not isinstance(coverage, dict):
        raise ValueError(f"missing paid-order {label} coverage")
    try:
        valid = int(coverage["valido"])
        invalid = int(coverage["invalido"])
        missing = int(coverage["nao_informado"])
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError(f"invalid paid-order {label} coverage") from error
    if min(valid, invalid, missing) < 0 or valid + invalid + missing != paid_orders:
        raise ValueError(f"invalid paid-order {label} coverage")
    return valid, invalid, missing


def _validate_financial_reconciliation(
    overview: dict[str, Any], reconciliation: dict[str, Any]
) -> None:
    paid_orders = int(overview.get("paid_orders", -1))
    paid_registrations = int(overview.get("paid_registrations", -1))
    component_totals: dict[str, Decimal] = {}

    for (
        label,
        source_field,
        overview_key,
        order_key,
        allocated_key,
        availability,
    ) in _FINANCIAL_COMPONENTS:
        valid, invalid, missing = _money_coverage(
            reconciliation, source_field, paid_orders, label
        )
        overview_value = overview.get(overview_key)
        order_value = reconciliation.get(order_key)
        allocated_value = reconciliation.get(allocated_key)

        if paid_orders == 0:
            expected_overview = "0.00" if availability != "optional" else None
            if overview_value != expected_overview:
                raise ValueError(f"zero-base {label} overview availability mismatch")
            if order_value != "0.00" or allocated_value != "0.00":
                raise ValueError(f"zero-base {label} receipts must be explicit zero")
            component_totals[label] = Decimal("0.00")
            continue

        if availability == "required" and (valid != paid_orders or invalid or missing):
            raise ValueError(f"paid-order {label} must be fully covered")
        if availability == "explicit_zero" and invalid:
            raise ValueError(f"paid-order {label} cannot contain invalid values")
        available = availability != "optional" or valid == paid_orders
        if availability == "optional" and not available:
            if any(value is not None for value in (overview_value, order_value, allocated_value)):
                raise ValueError(f"unavailable {label} must remain null")
            continue
        if availability == "optional" and (invalid or missing):
            raise ValueError(f"paid-order {label} availability is inconsistent")

        overview_total = _required_decimal(overview_value, f"overview {label}")
        order_total = _required_decimal(order_value, f"paid order {label}")
        allocated_total = _required_decimal(
            allocated_value, f"allocated registration {label}"
        )
        if order_total != overview_total:
            raise ValueError(f"receipt paid-order {label} does not reconcile")
        if allocated_total != overview_total:
            raise ValueError(f"allocated registration {label} does not reconcile")
        if availability == "explicit_zero" and valid == 0 and overview_total != 0:
            raise ValueError(f"missing paid-order {label} must be explicit zero")
        component_totals[label] = overview_total

    gross = component_totals["gross"]
    expected_tickets = {
        "order ticket": (
            overview.get("order_ticket"),
            None
            if paid_orders == 0
            else (gross / paid_orders).quantize(_MONEY_QUANTUM, rounding=ROUND_HALF_UP),
        ),
        "registration ticket": (
            overview.get("registration_ticket"),
            None
            if paid_registrations == 0
            else (gross / paid_registrations).quantize(
                _MONEY_QUANTUM, rounding=ROUND_HALF_UP
            ),
        ),
    }
    for label, (actual_value, expected_value) in expected_tickets.items():
        if expected_value is None:
            if actual_value is not None:
                raise ValueError(f"zero-base {label} must be unavailable")
        elif _required_decimal(actual_value, label) != expected_value:
            raise ValueError(f"{label} does not reconcile to its exact paid base")


def _validate_reconciliation(
    overview: dict[str, Any],
    reconciliation: dict[str, Any],
    source_notes: dict[str, Any],
    generated_at: object,
    snapshot_status: str,
) -> None:
    event_orders = int(overview.get("paid_orders", -1))
    event_registrations = int(overview.get("paid_registrations", -1))
    if int(reconciliation.get("paid_order_count", -2)) != event_orders:
        raise ValueError("receipt paid-order count does not reconcile")
    if int(reconciliation.get("paid_registration_count", -2)) != event_registrations:
        raise ValueError("receipt paid-registration count does not reconcile")
    _validate_financial_reconciliation(overview, reconciliation)
    for key in (
        "channel_mapping_coverage_pct",
        "product_mapping_coverage_pct",
        "registration_join_coverage_pct",
    ):
        value = float(reconciliation.get(key, -1))
        if value != 100:
            raise ValueError(f"incomplete contractual coverage: {key}")
    overview_coverage = overview.get("source_field_coverage", {})
    for key in ("channel_mapping_coverage_pct", "product_mapping_coverage_pct"):
        if float(overview_coverage.get(key, -1)) != 100:
            raise ValueError(f"incomplete overview coverage: {key}")
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
    if expected_rows["orders"] < event_orders:
        raise ValueError("source order rows cannot be below paid-order count")
    if expected_rows["participants"] < event_registrations:
        raise ValueError("source registration rows cannot be below paid-registration count")
    source_timestamps = []
    has_allow_stale_marker = False
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
        if source["extracted_at"] == ALLOW_STALE_EXTRACTION_MARKER:
            if snapshot_status != "fixture":
                raise ValueError("ready snapshot cannot use allow-stale freshness marker")
            has_allow_stale_marker = True
            continue
        parsed_timestamp = parse_extraction_timestamp(source["extracted_at"], source_id)
        if parsed_timestamp < FINAL_EXTRACTION_MIN_TIMESTAMP:
            raise ValueError(f"source freshness below final contract: {source_id}")
        source_timestamps.append(parsed_timestamp)
    if has_allow_stale_marker:
        if generated_at != ALLOW_STALE_EXTRACTION_MARKER:
            raise ValueError("fixture freshness marker does not match source receipts")
        return
    generated_timestamp = parse_extraction_timestamp(generated_at, "report snapshot")
    if generated_timestamp != max(source_timestamps):
        raise ValueError("report freshness does not match source receipts")


def _sum_rows(rows: list[dict[str, Any]], field: str, query_id: str) -> int:
    try:
        return sum(int(row[field]) for row in rows)
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError(f"invalid semantic metric for {query_id}: {field}") from error


def _validate_partition(
    query_id: str,
    rows: list[dict[str, Any]],
    metric: str,
    denominator_field: str | None,
    expected_total: int,
) -> None:
    if _sum_rows(rows, metric, query_id) != expected_total:
        raise ValueError(f"semantic reconciliation mismatch for {query_id}")
    if denominator_field is not None and any(
        int(row.get(denominator_field, -1)) != expected_total for row in rows
    ):
        raise ValueError(f"invalid denominator for {query_id}")


def _validate_coverage_identity(
    row: dict[str, Any], expected_denominator: int, query_id: str
) -> None:
    try:
        valid = int(row["valid"])
        invalid = int(row["invalid"])
        missing = int(row["missing"])
        answered = int(row["answered"])
        denominator = int(row["denominator"])
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError(f"invalid coverage counts for {query_id}") from error
    if min(valid, invalid, missing) < 0:
        raise ValueError(f"negative coverage counts for {query_id}")
    if denominator != expected_denominator or valid + invalid + missing != denominator:
        raise ValueError(f"invalid denominator identity for {query_id}")
    if answered != valid + invalid:
        raise ValueError(f"invalid answered identity for {query_id}")
    expected_coverage = round(answered / denominator * 100, 2) if denominator else 0.0
    expected_valid_coverage = round(valid / denominator * 100, 2) if denominator else 0.0
    if float(row.get("coverage_pct", -1)) != expected_coverage or float(
        row.get("valid_coverage_pct", -1)
    ) != expected_valid_coverage:
        raise ValueError(f"invalid coverage percentage for {query_id}")


def _validate_auxiliary_coverage(
    rows: list[dict[str, Any]],
    reconciliation: dict[str, Any],
    paid_orders: int,
    paid_registrations: int,
) -> None:
    by_field: dict[str, dict[str, Any]] = {}
    for row in rows:
        field = str(row.get("field", ""))
        if not field or field in by_field:
            raise ValueError("invalid auxiliary_field_coverage field catalog")
        by_field[field] = row

    required_fields = {label for label, _, _ in AUXILIARY_FIELD_CONTRACT}
    if not required_fields.issubset(by_field):
        raise ValueError("incomplete auxiliary_field_coverage field catalog")
    extras = set(by_field) - required_fields
    if any(
        not field.startswith("json_key:") or field == "json_key:"
        for field in extras
    ):
        raise ValueError("unexpected auxiliary_field_coverage field")

    paid_order_coverage = reconciliation.get("paid_order_field_coverage", {})
    for label, grain, source_field in AUXILIARY_FIELD_CONTRACT:
        if grain == "order":
            expected_denominator = paid_orders
            counts = paid_order_coverage.get(source_field)
            if paid_orders == 0 and counts is None:
                counts = {"valido": 0, "invalido": 0, "nao_informado": 0}
            if not isinstance(counts, dict):
                raise ValueError(
                    f"missing paid auxiliary_field_coverage source counts: {label}"
                )
            expected_counts = {
                "valid": int(counts.get("valido", 0)),
                "invalid": int(counts.get("invalido", 0)),
                "missing": int(counts.get("nao_informado", 0)),
            }
            if any(
                by_field[label].get(key) != value
                for key, value in expected_counts.items()
            ):
                raise ValueError(
                    f"auxiliary_field_coverage source counts mismatch: {label}"
                )
        else:
            expected_denominator = paid_registrations
        _validate_coverage_identity(
            by_field[label], expected_denominator, "auxiliary_field_coverage"
        )
    for field in extras:
        _validate_coverage_identity(
            by_field[field], paid_registrations, "auxiliary_field_coverage"
        )


def _validate_dataset_contracts(
    datasets: dict[str, list[dict[str, Any]]],
    aggregates: dict[str, Any],
    reconciliation: dict[str, Any],
) -> dict[str, Any]:
    overview = aggregates.get("overview")
    if not isinstance(overview, dict) or datasets["event_overview"] != [overview]:
        raise ValueError("event_overview dataset does not match aggregate overview")
    event_registrations = int(overview.get("paid_registrations", -1))
    event_orders = int(overview.get("paid_orders", -1))
    if event_registrations < 0 or event_orders < 0:
        raise ValueError("event overview counts must be non-negative")

    for field, overview_key in (
        ("allocated_gross_value", "gross_value"),
        ("allocated_discount_value", "discount_value"),
    ):
        total = sum(
            (_required_decimal(row.get(field), f"lot {field}") for row in datasets["lot_performance"]),
            Decimal("0"),
        )
        if total != _required_decimal(overview.get(overview_key), f"overview {overview_key}"):
            raise ValueError(f"lot {overview_key} does not reconcile")

    for query_id, denominator_field in _REGISTRATION_PARTITION_CONTRACTS.items():
        _validate_partition(
            query_id,
            datasets[query_id],
            "paid_registrations",
            denominator_field,
            event_registrations,
        )
    for query_id, denominator_field in _ORDER_PARTITION_CONTRACTS.items():
        _validate_partition(
            query_id,
            datasets[query_id],
            "paid_orders",
            denominator_field,
            event_orders,
        )

    if _sum_rows(
        datasets["channel_aliases"], "paid_registrations", "channel_aliases"
    ) != event_registrations:
        raise ValueError("semantic reconciliation mismatch for channel_aliases")

    channel_rows = datasets["channel_index"]
    full_channels = {
        row["channel_name"]: int(row["paid_registrations"])
        for row in channel_rows
        if row.get("dossier_type") == "full"
    }
    compact_channels = {
        row["channel_name"]: int(row["paid_registrations"])
        for row in channel_rows
        if row.get("dossier_type") == "compact"
    }
    for query_id in _FULL_CHANNEL_PARTITIONS:
        actual = {
            channel_name: sum(
                int(row.get("paid_registrations", 0))
                for row in datasets[query_id]
                if row.get("channel_name") == channel_name
            )
            for channel_name in full_channels
        }
        if actual != full_channels:
            raise ValueError(f"full-channel reconciliation mismatch for {query_id}")
    long_tail = {
        row["channel_name"]: int(row["paid_registrations"])
        for row in datasets["long_tail"]
    }
    if long_tail != compact_channels or aggregates.get("long_tail") != datasets["long_tail"]:
        raise ValueError("long_tail does not match compact channel contract")

    full_dossier_names = {
        dossier.get("channel_name") for dossier in aggregates.get("full_dossiers", [])
    }
    if full_dossier_names != set(full_channels):
        raise ValueError("full dossier catalog does not match channel_index")

    for query_id in ("channel_state_mix", "channel_product_mix"):
        for row in datasets[query_id]:
            channel_name = row.get("channel_name")
            if channel_name not in full_channels:
                raise ValueError(f"unknown full channel in {query_id}")
            denominator = row.get("denominator", row.get("take_rate_denominator", -1))
            if int(denominator) != full_channels[channel_name]:
                raise ValueError(f"invalid channel denominator for {query_id}")
    profile_dimensions: dict[str, set[str]] = {name: set() for name in full_channels}
    for row in datasets["channel_profile_coverage"]:
        channel_name = row.get("channel_name")
        if channel_name not in full_channels:
            raise ValueError("unknown full channel in channel_profile_coverage")
        if int(row.get("denominator", -1)) != full_channels[channel_name]:
            raise ValueError("invalid channel denominator for channel_profile_coverage")
        profile_dimensions[channel_name].add(str(row.get("profile_dimension")))
    if any(dimensions != {"age", "gender", "pace", "club"} for dimensions in profile_dimensions.values()):
        raise ValueError("incomplete channel_profile_coverage dimensions")

    if (event_orders or event_registrations) and not datasets["data_quality"]:
        raise ValueError("data_quality is required for a non-empty paid event")
    if (event_orders or event_registrations) and not datasets["auxiliary_field_coverage"]:
        raise ValueError("auxiliary_field_coverage is required for a non-empty paid event")
    _validate_auxiliary_coverage(
        datasets["auxiliary_field_coverage"],
        reconciliation,
        event_orders,
        event_registrations,
    )
    for row in datasets["data_quality"]:
        expected = (
            int(reconciliation.get("source_order_rows", -1))
            if row.get("grain") == "order"
            else event_registrations
        )
        if row.get("grain") not in {"order", "registration"} or int(
            row.get("denominator", -1)
        ) != expected:
            raise ValueError("invalid data_quality denominator")
    return overview


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
    snapshot_status = snapshot["status"]
    if snapshot.get("report") != report_qualification(snapshot_status):
        raise ValueError(f"{snapshot_status} snapshot qualification mismatch")
    if source_notes.get("source_qualification") != source_qualification(
        snapshot_status
    ):
        raise ValueError(f"{snapshot_status} source qualification mismatch")
    if snapshot_status == "fixture":
        if source_notes.get("fixture_status") != source_qualification("fixture"):
            raise ValueError("fixture source qualification mismatch")
    else:
        if "fixture_status" in source_notes:
            raise ValueError("ready source notes cannot contain fixture status")
        for payload in (snapshot, aggregates, source_notes):
            _reject_ready_development_language(payload)
    if snapshot.get("filters") != []:
        raise ValueError("report snapshot must not contain hidden filters")
    queries = snapshot.get("queries")
    if not isinstance(queries, dict) or set(queries) != set(DATASET_IDS):
        raise ValueError("snapshot must contain the 31 stable queries")
    datasets = aggregates.get("datasets")
    if not isinstance(datasets, dict) or set(datasets) != set(DATASET_IDS):
        raise ValueError("aggregate receipt dataset contract mismatch")
    quality = aggregates.get("quality")
    if not isinstance(quality, dict) or quality.get("reconciliation") != reconciliation:
        raise ValueError("aggregate quality reconciliation receipt mismatch")
    if quality.get("data_quality") != datasets["data_quality"]:
        raise ValueError("aggregate quality data receipt mismatch")
    overview = _validate_dataset_contracts(datasets, aggregates, reconciliation)
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
        expected_source = build_source_metadata(
            query_id,
            snapshot.get("generatedAt"),
            expected_component_map[query_id],
            status=snapshot_status,
        )
        if source != expected_source:
            raise ValueError(f"source provenance contract mismatch: {query_id}")
        sql = str(source.get("sql", ""))
        if "COUNT(*)" not in sql or "GROUP BY cod_evento" not in sql:
            raise ValueError(f"source SQL is not aggregate-only: {query_id}")

    if referenced_components != set(expected_catalog):
        raise ValueError("not every report component has source metadata")
    _validate_reconciliation(
        overview,
        reconciliation,
        source_notes,
        snapshot.get("generatedAt"),
        snapshot["status"],
    )
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
