"""Command-line entry point for the MIF 2026 channel study pipeline."""

from __future__ import annotations

import argparse
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
import hashlib
import json
from pathlib import Path, PurePosixPath
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
from .mappings import (
    ALLOWED_CHANNEL_TYPES,
    emit_channel_mapping_draft,
    emit_product_mapping_draft,
)
from .metrics import (
    AUXILIARY_FIELD_CONTRACT,
    DATASET_IDS,
    PRODUCT_CHART_AGGREGATION_RULE,
    PRODUCT_CHART_TOP_N,
    build_roadrunners_capstone,
)
from .narrative import (
    build_executive_summary,
    describe_channel,
    describe_compact_channel,
    describe_roadrunners_capstone,
)
from .normalize import normalize_key
from .modular_artifact import (
    TRANSFORM_VERSION,
    canonical_json_bytes,
    channel_slug,
    expected_artifact_transform_version,
    portfolio_dependency_receipt,
    refresh_state_strategy_artifact,
    state_strategy_dependency_receipt,
)
from .portfolio import (
    ACTIONABLE_DIMENSIONS,
    COMMERCIAL_TICKET_MIN,
    EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS,
    EXPOSURE_HIGH_EVENT_SHARE_PCT,
    EXPOSURE_MEDIUM_EVENT_SHARE_PCT,
    EXPOSURE_PARTNER_CONCENTRATION_PCT,
    MIN_DIMENSION_COVERAGE_PCT,
    MIN_PROFILE_REGISTRATIONS,
    MIN_PUBLISHABLE_CELL_REGISTRATIONS,
    MONEY_FIELDS as PORTFOLIO_MONEY_FIELDS,
    build_portfolio_artifacts,
)
from .pipeline import (
    CHART_RATIONALES,
    run_analysis,
    run_modular_analysis,
    source_qualification,
)
from .privacy import assert_anonymous
from .source import (
    ALLOW_STALE_EXTRACTION_MARKER,
    FINAL_EXTRACTION_MIN_TIMESTAMP,
    load_sources,
    parse_extraction_timestamp,
)
from .state_strategy import build_state_strategy


_RAW_BOUNDARY_KEYS = frozenset(
    {"facts", "raw_facts", "numero_pedido", "numero_inscricao", "body"}
)
_PORTFOLIO_ARTIFACTS = frozenset(
    {"portfolio/summary.json", "portfolio/simulator.json"}
)
_PORTFOLIO_BYTE_LIMITS = {
    "portfolio/summary.json": 750_000,
    "portfolio/simulator.json": 2_000_000,
}
_STATE_STRATEGY_ARTIFACT = "states/strategy.json"
_STATE_STRATEGY_BYTE_LIMIT = 750_000
_PORTFOLIO_FORBIDDEN_KEYS = frozenset(
    {
        "numero_pedido",
        "numero_inscricao",
        "email",
        "documento",
        "cpf",
        "city",
        "week_start",
    }
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
    expected_channel_rows = sorted(
        channel_rows,
        key=lambda row: (
            -_required_decimal(row.get("gross_value"), "channel gross_value"),
            -int(row.get("paid_registrations", -1)),
            normalize_key(row.get("channel_name")).casefold(),
            str(row.get("channel_name", "")).casefold(),
            str(row.get("channel_name", "")),
        ),
    )
    if channel_rows != expected_channel_rows:
        raise ValueError("channel performance order does not match gross, registrations, and name")
    channel_names = [str(row.get("channel_name")) for row in channel_rows]
    if len(channel_names) != len(set(channel_names)):
        raise ValueError("channel_index contains duplicate channel names")
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
    expected_compact_names = [
        str(row["channel_name"])
        for row in channel_rows
        if row.get("dossier_type") == "compact"
    ]
    if [str(row.get("channel_name")) for row in datasets["long_tail"]] != expected_compact_names:
        raise ValueError("long_tail order does not match channel performance order")
    channel_by_name = {str(row["channel_name"]): row for row in channel_rows}
    for row in datasets["long_tail"]:
        channel_row = channel_by_name[str(row["channel_name"])]
        if _required_decimal(row.get("gross_value"), "long_tail gross_value") != _required_decimal(
            channel_row.get("gross_value"), "channel gross_value"
        ):
            raise ValueError("long_tail gross_value does not match channel_index")
    long_tail = {
        row["channel_name"]: int(row["paid_registrations"])
        for row in datasets["long_tail"]
    }
    if long_tail != compact_channels or aggregates.get("long_tail") != datasets["long_tail"]:
        raise ValueError("long_tail does not match compact channel contract")

    full_dossier_names = [
        str(dossier.get("channel_name"))
        for dossier in aggregates.get("full_dossiers", [])
    ]
    expected_full_names = [
        str(row["channel_name"])
        for row in channel_rows
        if row.get("dossier_type") == "full"
    ]
    if full_dossier_names != expected_full_names:
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


def _validate_generated_narratives(
    datasets: dict[str, list[dict[str, Any]]],
    aggregates: dict[str, Any],
    source_notes: dict[str, Any],
    overview: dict[str, Any],
) -> None:
    """Rebuild generated prose and capstone from their independent aggregates."""
    full = aggregates.get("full_dossiers")
    compact = aggregates.get("long_tail")
    if not isinstance(full, list) or not isinstance(compact, list):
        raise ValueError("executive narrative aggregate catalog is incomplete")
    channel_index = {
        str(row.get("channel_name")): row for row in datasets["channel_index"]
    }
    expected_channels = {}
    for dossier in full:
        channel_name = str(dossier.get("channel_name"))
        expected = describe_channel(dossier, overview)
        if dossier.get("executive_summary") != expected:
            raise ValueError(f"executive narrative does not reconcile: {channel_name}")
        if channel_index.get(channel_name, {}).get("executive_summary") != expected:
            raise ValueError(f"executive narrative index does not reconcile: {channel_name}")
        expected_channels[channel_name] = expected

    expected_compact = {}
    for dossier in compact:
        channel_name = str(dossier.get("channel_name"))
        expected = describe_compact_channel(dossier)
        if dossier.get("executive_highlight") != expected:
            raise ValueError(f"compact executive narrative does not reconcile: {channel_name}")
        if channel_index.get(channel_name, {}).get("executive_highlight") != expected:
            raise ValueError(f"compact executive narrative index does not reconcile: {channel_name}")
        expected_compact[channel_name] = expected

    expected_capstone = build_roadrunners_capstone(
        overview,
        datasets["modality_mix"],
        full,
        compact,
    )
    expected_capstone["capstone_markdown"] = describe_roadrunners_capstone(
        expected_capstone
    )
    expected_capstone["executive_summary"] = build_executive_summary(
        overview, expected_capstone, len(full), len(compact)
    )
    if datasets.get("roadrunners_capstone") != [expected_capstone]:
        raise ValueError("roadrunners capstone does not reconcile")

    narrative = source_notes.get("narrative")
    if not isinstance(narrative, dict):
        raise ValueError("executive narrative receipt is incomplete")
    if narrative.get("channels") != expected_channels:
        raise ValueError("executive narrative source receipt does not reconcile")
    if narrative.get("compact_channels") != expected_compact:
        raise ValueError("compact executive narrative source receipt does not reconcile")
    if narrative.get("executive_summary") != expected_capstone["executive_summary"]:
        raise ValueError("executive summary source receipt does not reconcile")
    if narrative.get("roadrunners_capstone") != expected_capstone["capstone_markdown"]:
        raise ValueError("roadrunners capstone source receipt does not reconcile")


def _validate_chart_metadata(
    snapshot: dict[str, Any],
    aggregates: dict[str, Any],
    datasets: dict[str, list[dict[str, Any]]],
    overview: dict[str, Any],
) -> None:
    metadata = aggregates.get("chart_metadata")
    if snapshot.get("chartMetadata") != metadata:
        raise ValueError("product chart metadata receipt mismatch")
    if not isinstance(metadata, dict) or set(metadata) != {"product_summary"}:
        raise ValueError("product chart metadata contract mismatch")
    product = metadata["product_summary"]
    expected_keys = {
        "category_field",
        "primary_metric",
        "top_n",
        "source_category_count",
        "tail_category_count",
        "tail_categories",
        "summed_category_registrations",
        "distinct_registrations_with_product",
        "product_quantity",
        "tail_registration_multiplicity",
        "take_rate_denominator",
        "take_rate_pct",
        "aggregation_rule",
    }
    if not isinstance(product, dict) or set(product) != expected_keys:
        raise ValueError("product chart metadata contract mismatch")

    rows = datasets["product_summary"]
    ranked = sorted(
        rows,
        key=lambda row: (
            -int(row.get("registrations_with_product", -1)),
            normalize_key(row.get("product_name")).casefold(),
            str(row.get("product_name")),
        ),
    )
    tail = ranked[PRODUCT_CHART_TOP_N:]
    expected_tail_categories = [str(row["product_name"]) for row in tail]
    expected_summed = sum(int(row["registrations_with_product"]) for row in tail)
    expected_quantity = sum(int(row["product_quantity"]) for row in tail)
    denominator = int(overview["paid_registrations"])
    distinct = product.get("distinct_registrations_with_product")
    multiplicity = product.get("tail_registration_multiplicity")
    multiplicity_valid = isinstance(multiplicity, list)
    previous_product_count = 0
    multiplicity_distinct = 0
    multiplicity_pairs = 0
    if multiplicity_valid:
        for row in multiplicity:
            if not isinstance(row, dict) or set(row) != {
                "tail_product_count", "paid_registrations"
            }:
                multiplicity_valid = False
                break
            product_count = row["tail_product_count"]
            registration_count = row["paid_registrations"]
            if (
                not isinstance(product_count, int)
                or isinstance(product_count, bool)
                or not isinstance(registration_count, int)
                or isinstance(registration_count, bool)
                or product_count <= previous_product_count
                or product_count > len(tail)
                or registration_count <= 0
            ):
                multiplicity_valid = False
                break
            previous_product_count = product_count
            multiplicity_distinct += registration_count
            multiplicity_pairs += product_count * registration_count
    expected_rate = (
        round(int(distinct) / denominator * 100, 2)
        if isinstance(distinct, int) and denominator
        else 0.0
    )
    valid = (
        product["category_field"] == "product_name"
        and product["primary_metric"] == "registrations_with_product"
        and product["top_n"] == PRODUCT_CHART_TOP_N
        and product["source_category_count"] == len(rows)
        and product["tail_category_count"] == len(tail)
        and product["tail_categories"] == expected_tail_categories
        and product["summed_category_registrations"] == expected_summed
        and product["product_quantity"] == expected_quantity
        and multiplicity_valid
        and multiplicity_distinct == distinct
        and multiplicity_pairs == expected_summed
        and product["take_rate_denominator"] == denominator
        and isinstance(distinct, int)
        and 0 <= distinct <= min(expected_summed, denominator)
        and product["take_rate_pct"] == expected_rate
        and product["aggregation_rule"] == PRODUCT_CHART_AGGREGATION_RULE
    )
    if not valid:
        raise ValueError("product chart distinct-union metadata does not reconcile")


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
        raise ValueError("snapshot must contain the 32 stable queries")
    datasets = aggregates.get("datasets")
    if not isinstance(datasets, dict) or set(datasets) != set(DATASET_IDS):
        raise ValueError("aggregate receipt dataset contract mismatch")
    quality = aggregates.get("quality")
    if not isinstance(quality, dict) or quality.get("reconciliation") != reconciliation:
        raise ValueError("aggregate quality reconciliation receipt mismatch")
    if quality.get("data_quality") != datasets["data_quality"]:
        raise ValueError("aggregate quality data receipt mismatch")
    overview = _validate_dataset_contracts(datasets, aggregates, reconciliation)
    _validate_generated_narratives(datasets, aggregates, source_notes, overview)
    _validate_chart_metadata(snapshot, aggregates, datasets, overview)
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


def _modular_path(root: Path, relative_path: str) -> Path:
    candidate = PurePosixPath(relative_path)
    if candidate.is_absolute() or ".." in candidate.parts or candidate.suffix != ".json":
        raise ValueError(f"unsafe modular artifact path: {relative_path}")
    destination = root.joinpath(*candidate.parts)
    if destination.resolve().parent != root.resolve() and root.resolve() not in destination.resolve().parents:
        raise ValueError(f"modular artifact escapes its root: {relative_path}")
    return destination


def _sum_modular_registrations(rows: object, label: str) -> int:
    if not isinstance(rows, list):
        raise ValueError(f"invalid modular observations: {label}")
    try:
        return sum(int(row["paid_registrations"]) for row in rows)
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError(f"invalid modular registration metric: {label}") from error


def _contains_forbidden_strategy_cube(value: object) -> bool:
    """Reject detailed observation structures anywhere in the compact strategy tree."""
    forbidden = {"observations", "registration_cube", "product_cube"}
    if isinstance(value, dict):
        return bool(forbidden.intersection(value)) or any(
            _contains_forbidden_strategy_cube(child) for child in value.values()
        )
    if isinstance(value, list):
        return any(_contains_forbidden_strategy_cube(child) for child in value)
    return False


def _reject_portfolio_forbidden_keys(
    value: object,
    path: str = "$",
    *,
    allow_summary_city_coverage: bool = False,
) -> None:
    """Reject fields that would make the portfolio output identifying or too granular."""
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = str(key).strip().casefold()
            is_overview_coverage_field = (
                allow_summary_city_coverage
                and normalized == "city"
                and path == "$.overview.source_field_coverage.registrations"
            )
            if normalized == "kit_incluso":
                raise ValueError(f"kit_incluso outside product scope definition at {path}.{key}")
            if normalized in _PORTFOLIO_FORBIDDEN_KEYS and not is_overview_coverage_field:
                raise ValueError(f"forbidden portfolio field at {path}.{key}")
            _reject_portfolio_forbidden_keys(
                child,
                f"{path}.{key}",
                allow_summary_city_coverage=allow_summary_city_coverage,
            )
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_portfolio_forbidden_keys(
                child,
                f"{path}[{index}]",
                allow_summary_city_coverage=allow_summary_city_coverage,
            )
    elif (
        isinstance(value, str)
        and "kit_incluso" in value.casefold()
        and not (
            allow_summary_city_coverage
            and path == "$.definitions.product_scope"
            and value
            == "Apenas a classificação kit_incluso é excluída do perfil de produto."
        )
    ):
        raise ValueError(f"kit_incluso outside product scope definition at {path}")


def verify_modular_outputs(manifest_path: Path) -> None:
    """Verify hashes, privacy and cross-bundle reconciliations without raw sources."""
    manifest = _read_json(manifest_path)
    assert_anonymous(manifest)
    if manifest.get("event_code") != EVENT_CODE:
        raise ValueError("modular event code mismatch")
    if manifest.get("transform_version") != TRANSFORM_VERSION:
        raise ValueError("modular transform version mismatch")
    sources = manifest.get("sources")
    if not isinstance(sources, dict) or set(sources) != {"orders", "participants"}:
        raise ValueError("modular source hashes are incomplete")
    if any(not re.fullmatch(r"[0-9a-f]{64}", str(value)) for value in sources.values()):
        raise ValueError("invalid modular source hash")
    source_sha256 = hashlib.sha256(canonical_json_bytes(sources)).hexdigest()
    if manifest.get("source_sha256") != source_sha256:
        raise ValueError("modular combined source hash mismatch")

    receipts = manifest.get("artifacts")
    if not isinstance(receipts, dict):
        raise ValueError("modular artifact receipts are missing")
    required = {
        "general.json",
        "strategy.json",
        "cycle.json",
        "territories.json",
        "products.json",
        "channels/index.json",
        "explorer.json",
        _STATE_STRATEGY_ARTIFACT,
        *_PORTFOLIO_ARTIFACTS,
    }
    if not required.issubset(receipts):
        raise ValueError("required modular bundles are missing")
    if any(
        path not in required
        and not re.fullmatch(r"channels/[a-z0-9]+(?:-[a-z0-9]+)*\.json", path)
        for path in receipts
    ):
        raise ValueError("unexpected modular artifact path")

    root = manifest_path.parent
    payloads: dict[str, Any] = {}
    for relative_path, receipt in receipts.items():
        if not isinstance(receipt, dict) or receipt.get("path") != relative_path:
            raise ValueError(f"invalid modular receipt: {relative_path}")
        path = _modular_path(root, relative_path)
        if not path.is_file():
            raise ValueError(f"modular artifact is missing: {relative_path}")
        content = path.read_bytes()
        if hashlib.sha256(content).hexdigest() != receipt.get("sha256"):
            raise ValueError(f"modular artifact hash mismatch: {relative_path}")
        if len(content) != int(receipt.get("bytes", -1)):
            raise ValueError(f"modular artifact byte count mismatch: {relative_path}")
        if (
            relative_path in _PORTFOLIO_BYTE_LIMITS
            and len(content) >= _PORTFOLIO_BYTE_LIMITS[relative_path]
        ):
            raise ValueError(f"portfolio artifact exceeds byte limit: {relative_path}")
        if (
            relative_path == _STATE_STRATEGY_ARTIFACT
            and len(content) >= _STATE_STRATEGY_BYTE_LIMIT
        ):
            raise ValueError("state strategy artifact exceeds byte limit")
        if receipt.get("source_sha256") != source_sha256:
            raise ValueError(f"modular source hash mismatch: {relative_path}")
        payload = json.loads(content)
        artifact_transform_version = expected_artifact_transform_version(relative_path)
        if receipt.get("transform_version") != artifact_transform_version:
            raise ValueError(f"modular transform mismatch: {relative_path}")
        if (
            not isinstance(payload, dict)
            or not isinstance(payload.get("meta"), dict)
            or payload["meta"].get("transform_version") != artifact_transform_version
        ):
            raise ValueError(f"modular transform mismatch: {relative_path}")
        _reject_raw_boundary(payload)
        assert_anonymous(payload)
        if relative_path in _PORTFOLIO_ARTIFACTS:
            _reject_portfolio_forbidden_keys(
                payload,
                allow_summary_city_coverage=(
                    relative_path == "portfolio/summary.json"
                ),
            )
        payloads[relative_path] = payload

    expected_portfolio_dependencies = portfolio_dependency_receipt(payloads)
    for relative_path in _PORTFOLIO_ARTIFACTS:
        if receipts[relative_path].get("dependencies") != expected_portfolio_dependencies:
            raise ValueError(
                f"portfolio dependency receipt mismatch: {relative_path}"
            )

    expected_state_dependencies = state_strategy_dependency_receipt(payloads)
    if receipts[_STATE_STRATEGY_ARTIFACT].get("dependencies") != expected_state_dependencies:
        raise ValueError("state strategy dependency receipt mismatch")

    general = payloads["general.json"]
    overview = general.get("overview")
    if not isinstance(overview, dict):
        raise ValueError("modular event overview is missing")
    paid_registrations = int(overview.get("paid_registrations", -1))
    if paid_registrations < 0:
        raise ValueError("modular registration base is invalid")
    strategy = payloads["strategy.json"]
    strategy_datasets = strategy.get("datasets")
    if not isinstance(strategy_datasets, dict):
        raise ValueError("modular strategy datasets are missing")
    if _sum_modular_registrations(
        strategy_datasets.get("phase_modality"), "strategy.json"
    ) != paid_registrations:
        raise ValueError("modular strategy registration mismatch")
    if _contains_forbidden_strategy_cube(strategy):
        raise ValueError("modular strategy contains detailed cubes")
    for relative_path in ("cycle.json", "territories.json"):
        if _sum_modular_registrations(
            payloads[relative_path].get("observations"), relative_path
        ) != paid_registrations:
            raise ValueError(f"modular partition mismatch: {relative_path}")
    explorer = payloads["explorer.json"]
    if _sum_modular_registrations(
        explorer.get("registration_cube"), "explorer.json"
    ) != paid_registrations:
        raise ValueError("modular explorer registration mismatch")

    portfolio_summary = payloads["portfolio/summary.json"]
    if portfolio_summary.get("overview") != overview:
        raise ValueError("portfolio overview mismatch")
    if "coverage_cube" in portfolio_summary:
        raise ValueError("portfolio summary contains simulator cube")
    definitions = portfolio_summary.get("definitions")
    if (
        not isinstance(definitions, dict)
        or definitions.get("product_scope")
        != "Apenas a classificação kit_incluso é excluída do perfil de produto."
    ):
        raise ValueError("portfolio product scope definition mismatch")
    dimension_panels = portfolio_summary.get("dimension_panels")
    if not isinstance(dimension_panels, dict) or set(dimension_panels) != set(
        ACTIONABLE_DIMENSIONS
    ):
        raise ValueError("portfolio dimension panel contract mismatch")
    redundancy_rows = portfolio_summary.get("redundancy_candidates")
    if not isinstance(redundancy_rows, list) or len(redundancy_rows) > 10:
        raise ValueError("portfolio redundancy contract mismatch")
    for pair in redundancy_rows:
        evidence = pair.get("dimension_evidence") if isinstance(pair, dict) else None
        if not isinstance(evidence, dict) or set(evidence) != set(ACTIONABLE_DIMENSIONS):
            raise ValueError("portfolio pair must expose five dimension evidence receipts")
        qualified_dimensions = set(pair.get("qualifying_dimensions", []))
        for dimension, dimension_receipt in evidence.items():
            if not isinstance(dimension_receipt, dict) or set(dimension_receipt) != {
                "similarity_0_1",
                "left_coverage_pct",
                "right_coverage_pct",
                "p90_similarity_0_1",
                "qualified",
                "reason",
            }:
                raise ValueError("portfolio pair dimension evidence is incomplete")
            if not isinstance(dimension_receipt.get("qualified"), bool):
                raise ValueError("portfolio pair dimension qualification is invalid")
            if bool(dimension_receipt["qualified"]) != (
                dimension in qualified_dimensions
            ):
                raise ValueError("portfolio pair dimension qualification mismatch")
            if not str(dimension_receipt.get("reason", "")).strip():
                raise ValueError("portfolio pair dimension reason is missing")
            for coverage_key in ("left_coverage_pct", "right_coverage_pct"):
                coverage = dimension_receipt.get(coverage_key)
                if coverage is not None and not Decimal("0") <= _required_decimal(
                    coverage, f"portfolio {coverage_key}"
                ) <= Decimal("100"):
                    raise ValueError("portfolio pair dimension coverage is invalid")
            for similarity_key in ("similarity_0_1", "p90_similarity_0_1"):
                similarity = dimension_receipt.get(similarity_key)
                if similarity is not None and not Decimal("0") <= _required_decimal(
                    similarity, f"portfolio {similarity_key}"
                ) <= Decimal("1"):
                    raise ValueError("portfolio pair dimension similarity is invalid")

    portfolio_simulator = payloads["portfolio/simulator.json"]
    if portfolio_simulator.get("dimensions") != [
        "phase",
        "modality",
        "state",
        "channel_name",
    ]:
        raise ValueError("portfolio simulator dimensions mismatch")
    expected_thresholds = {
        "commercial_ticket_min_exclusive": format(COMMERCIAL_TICKET_MIN, ".2f"),
        "minimum_profile_registrations": MIN_PROFILE_REGISTRATIONS,
        "minimum_dimension_coverage_pct": format(
            MIN_DIMENSION_COVERAGE_PCT, ".2f"
        ),
        "maximum_selected_channels": 10,
        "publishable_cell_minimum_registrations": MIN_PUBLISHABLE_CELL_REGISTRATIONS,
        "exposure_classification_minimum_registrations": EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS,
        "exposure_high_event_share_pct": format(
            EXPOSURE_HIGH_EVENT_SHARE_PCT, ".2f"
        ),
        "exposure_medium_event_share_pct": format(
            EXPOSURE_MEDIUM_EVENT_SHARE_PCT, ".2f"
        ),
        "exposure_partner_concentration_pct": format(
            EXPOSURE_PARTNER_CONCENTRATION_PCT, ".2f"
        ),
    }
    if portfolio_simulator.get("thresholds") != expected_thresholds:
        raise ValueError("portfolio threshold contract mismatch")
    channel_index = payloads["channels/index.json"].get("channels")
    if not isinstance(channel_index, list):
        raise ValueError("modular channel index is invalid")
    channel_index_types = {
        str(row.get("channel_name", "")): row.get("channel_type")
        for row in channel_index
    }
    expected_selectable_channels = [
        {
            "channel_name": str(row.get("channel_name", "")),
            "slug": channel_slug(row.get("channel_name")),
            "channel_type": str(row.get("channel_type", "Não informado")),
            "paid_registrations": int(row.get("paid_registrations", 0) or 0),
            "gross_value": format(
                _required_decimal(row.get("gross_value"), "portfolio channel gross"),
                ".2f",
            ),
            "registration_ticket": format(
                _required_decimal(
                    row.get("registration_ticket"), "portfolio registration ticket"
                ),
                ".2f",
            ),
        }
        for row in channel_index
        if _required_decimal(
            row.get("registration_ticket"), "portfolio registration ticket"
        )
        > COMMERCIAL_TICKET_MIN
        and str(row.get("channel_type", "")).strip().casefold() != "organico"
    ]
    selectable_channels = portfolio_simulator.get("selectable_channels")
    if not isinstance(selectable_channels, list):
        raise ValueError("portfolio selectable channels are invalid")
    selectable_names: set[str] = set()
    selectable_slugs: set[str] = set()
    selectable_types: dict[str, str] = {}
    for row in selectable_channels:
        if not isinstance(row, dict):
            raise ValueError("portfolio selectable channel is invalid")
        channel_name = str(row.get("channel_name", ""))
        slug = str(row.get("slug", ""))
        if not channel_name or not slug or slug in selectable_slugs:
            raise ValueError("portfolio selectable channel slugs are invalid")
        if channel_name in selectable_names:
            raise ValueError("portfolio selectable channel names are duplicated")
        if _required_decimal(
            row.get("registration_ticket"), "portfolio registration ticket"
        ) <= Decimal("10.00"):
            raise ValueError("portfolio selectable channel ticket is ineligible")
        raw_channel_type = row.get("channel_type")
        if not isinstance(raw_channel_type, str):
            raise ValueError("portfolio selectable channel type is invalid")
        channel_type = raw_channel_type.strip().casefold()
        if not channel_type or channel_type not in ALLOWED_CHANNEL_TYPES:
            raise ValueError("portfolio selectable channel type is invalid")
        if channel_type == "organico":
            raise ValueError("portfolio organic channel is selectable")
        index_channel_type = channel_index_types.get(channel_name)
        if not isinstance(index_channel_type, str) or (
            index_channel_type.strip().casefold() != channel_type
        ):
            raise ValueError("portfolio selectable channel type mismatch")
        selectable_names.add(channel_name)
        selectable_slugs.add(slug)
        selectable_types[channel_name] = channel_type
    if selectable_channels != expected_selectable_channels:
        raise ValueError("portfolio selectable channel catalog mismatch")

    coverage_cube = portfolio_simulator.get("coverage_cube")
    if not isinstance(coverage_cube, list):
        raise ValueError("portfolio simulator cube is invalid")
    cell_rows: dict[tuple[str, str, str], list[dict[str, Any]]] = {}
    for row in coverage_cube:
        if not isinstance(row, dict):
            raise ValueError("portfolio simulator row is invalid")
        try:
            cell = (str(row["phase"]), str(row["modality"]), str(row["state"]))
            str(row["channel_name"])
            int(row["paid_registrations"])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError("portfolio simulator row is invalid") from error
        for money_field in PORTFOLIO_MONEY_FIELDS:
            if money_field not in row or (
                row[money_field] is not None
                and not re.fullmatch(r"-?\d+\.\d{2}", str(row[money_field]))
            ):
                raise ValueError(
                    f"portfolio simulator money contract mismatch: {money_field}"
                )
        cell_rows.setdefault(cell, []).append(row)

    portfolio_total = 0
    total_label = "Todos os canais"
    commercial_total_label = "Canais comerciais não orgânicos"
    for rows in cell_rows.values():
        all_totals = [row for row in rows if row["channel_name"] == total_label]
        commercial_totals = [
            row for row in rows if row["channel_name"] == commercial_total_label
        ]
        details = [
            row
            for row in rows
            if row["channel_name"] not in {total_label, commercial_total_label}
        ]
        if len(all_totals) != 1:
            raise ValueError("portfolio simulator all-channel total is invalid")
        all_total = int(all_totals[0]["paid_registrations"])
        if sum(int(row["paid_registrations"]) for row in details) != all_total:
            raise ValueError("portfolio simulator all-channel total mismatch")
        commercial_total = sum(
            int(row["paid_registrations"])
            for row in details
            if str(row["channel_name"]) in selectable_names
        )
        if len(commercial_totals) > 1 or (
            commercial_totals
            and int(commercial_totals[0]["paid_registrations"]) != commercial_total
        ):
            raise ValueError("portfolio simulator commercial total mismatch")
        if commercial_total and not commercial_totals:
            raise ValueError("portfolio simulator commercial total is missing")
        for money_field in PORTFOLIO_MONEY_FIELDS:
            def summed_money(money_rows: list[dict[str, Any]]) -> str | None:
                if any(row[money_field] is None for row in money_rows):
                    return None
                return format(
                    sum(
                        (Decimal(str(row[money_field])) for row in money_rows),
                        Decimal("0"),
                    ),
                    ".2f",
                )

            if all_totals[0][money_field] != summed_money(details):
                raise ValueError(
                    f"portfolio simulator money total mismatch: {money_field}"
                )
            if commercial_totals:
                commercial_details = [
                    row
                    for row in details
                    if str(row["channel_name"]) in selectable_names
                ]
                if commercial_totals[0][money_field] != summed_money(
                    commercial_details
                ):
                    raise ValueError(
                        f"portfolio simulator commercial money mismatch: {money_field}"
                    )
        portfolio_total += all_total
    if portfolio_total != paid_registrations:
        raise ValueError("portfolio simulator registration mismatch")

    channel_index = payloads["channels/index.json"].get("channels")
    if not isinstance(channel_index, list):
        raise ValueError("modular channel index is invalid")
    expected_order = sorted(
        channel_index,
        key=lambda row: (
            -_required_decimal(row.get("gross_value"), "modular channel gross"),
            -int(row.get("paid_registrations", -1)),
            normalize_key(row.get("channel_name")).casefold(),
            str(row.get("channel_name", "")).casefold(),
            str(row.get("channel_name", "")),
        ),
    )
    if channel_index != expected_order:
        raise ValueError("modular channel index order mismatch")
    if sum(int(row.get("paid_registrations", 0)) for row in channel_index) != paid_registrations:
        raise ValueError("modular channel index partition mismatch")
    channel_index_types = {
        str(row.get("channel_name", "")): row.get("channel_type")
        for row in channel_index
    }
    expected_selectable_channels = [
        {
            "channel_name": str(row.get("channel_name", "")),
            "slug": channel_slug(row.get("channel_name")),
            "channel_type": str(row.get("channel_type", "Não informado")),
            "paid_registrations": int(row.get("paid_registrations", 0) or 0),
            "gross_value": format(
                _required_decimal(row.get("gross_value"), "portfolio channel gross"),
                ".2f",
            ),
            "registration_ticket": format(
                _required_decimal(
                    row.get("registration_ticket"), "portfolio registration ticket"
                ),
                ".2f",
            ),
        }
        for row in channel_index
        if _required_decimal(
            row.get("registration_ticket"), "portfolio registration ticket"
        )
        > COMMERCIAL_TICKET_MIN
        and str(row.get("channel_type", "")).strip().casefold() != "organico"
    ]
    if selectable_channels != expected_selectable_channels:
        raise ValueError("portfolio selectable channel catalog mismatch")
    for dimension, panel in dimension_panels.items():
        if (
            not isinstance(panel, dict)
            or panel.get("scale_population_channels")
            != len(expected_selectable_channels)
            or panel.get("sort")
            != [
                "gross_value desc",
                "paid_registrations desc",
                "channel_name asc",
            ]
            or not isinstance(panel.get("channels"), list)
            or len(panel["channels"]) != len(expected_selectable_channels)
            or panel.get("top_channels") != panel["channels"][:10]
        ):
            raise ValueError(
                f"portfolio dimension panel contract mismatch: {dimension}"
            )
    executive_summary = portfolio_summary.get("executive_summary")
    if not isinstance(executive_summary, dict) or set(executive_summary) != {
        "commercial_channel_count",
        "commercial_paid_registrations",
        "commercial_event_share_pct",
        "concentration_basis",
        "top_1",
        "top_3",
        "top_10",
        "principal_dependencies",
        "implication_2027",
    }:
        raise ValueError("portfolio executive summary contract mismatch")
    redundancy_summary = portfolio_summary.get("redundancy_summary")
    if (
        not isinstance(redundancy_summary, dict)
        or redundancy_summary.get("displayed_pairs") != len(redundancy_rows)
        or int(redundancy_summary.get("total_qualified_pairs", -1))
        < len(redundancy_rows)
    ):
        raise ValueError("portfolio redundancy summary mismatch")
    for channel_name, channel_type in selectable_types.items():
        index_channel_type = channel_index_types.get(channel_name)
        if not isinstance(index_channel_type, str) or (
            index_channel_type.strip().casefold() != channel_type
        ):
            raise ValueError("portfolio selectable channel type mismatch")
    expected_dossiers = {f"channels/{row.get('slug')}.json" for row in channel_index}
    actual_dossiers = set(receipts) - required
    if expected_dossiers != actual_dossiers:
        raise ValueError("modular channel dossier catalog mismatch")
    for row in channel_index:
        dossier_path = f"channels/{row['slug']}.json"
        dossier = payloads[dossier_path]
        channel = dossier.get("channel")
        if not isinstance(channel, dict) or channel.get("channel_name") != row.get("channel_name"):
            raise ValueError(f"modular dossier identity mismatch: {dossier_path}")
        if int(channel.get("paid_registrations", -1)) != int(row.get("paid_registrations", -2)):
            raise ValueError(f"modular dossier base mismatch: {dossier_path}")
        if _sum_modular_registrations(
            dossier.get("registration_cube"), dossier_path
        ) != int(row.get("paid_registrations", -1)):
            raise ValueError(f"modular dossier cube mismatch: {dossier_path}")
        if dossier.get("recommendation") != row.get("recommendation"):
            raise ValueError(f"modular recommendation mismatch: {dossier_path}")

    expected_portfolio = build_portfolio_artifacts(
        overview=overview,
        channel_index=channel_index,
        dossiers=[
            payloads[f"channels/{row['slug']}.json"]["channel"]
            for row in channel_index
        ],
        registration_cube=explorer["registration_cube"],
        generated_at=str(portfolio_summary["meta"].get("generated_at", "")),
    )
    for relative_path in _PORTFOLIO_ARTIFACTS:
        if payloads[relative_path] != expected_portfolio[relative_path]:
            raise ValueError(f"portfolio full contract mismatch: {relative_path}")
    expected_state_strategy = build_state_strategy(
        overview=overview,
        channel_index=channel_index,
        dossiers=[
            payloads[f"channels/{row['slug']}.json"]["channel"]
            for row in channel_index
        ],
        territory_observations=payloads["territories.json"]["observations"],
        geography_benchmark=portfolio_summary["dimension_benchmarks"]["geography"],
        generated_at=str(payloads[_STATE_STRATEGY_ARTIFACT]["meta"].get("generated_at", "")),
    )
    if payloads[_STATE_STRATEGY_ARTIFACT] != expected_state_strategy:
        raise ValueError("state strategy full contract mismatch")


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

    analyze_modular = commands.add_parser("analyze-modular")
    analyze_modular.add_argument("--orders", type=Path, required=True)
    analyze_modular.add_argument("--participants", type=Path, required=True)
    analyze_modular.add_argument("--channel-map", type=Path, required=True)
    analyze_modular.add_argument("--product-map", type=Path, required=True)
    analyze_modular.add_argument("--output-dir", type=Path, required=True)
    analyze_modular.add_argument("--allow-stale", action="store_true")

    verify = commands.add_parser("verify")
    verify.add_argument("--report-data", type=Path, required=True)
    verify.add_argument("--aggregates", type=Path, required=True)
    verify.add_argument("--reconciliation", type=Path, required=True)
    verify.add_argument("--source-notes", type=Path, required=True)

    verify_modular = commands.add_parser("verify-modular")
    verify_modular.add_argument("--manifest", type=Path, required=True)
    refresh_states = commands.add_parser("refresh-state-strategy")
    refresh_states.add_argument("--manifest", type=Path, required=True)
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
        elif args.command == "analyze-modular":
            paths = run_modular_analysis(
                args.orders,
                args.participants,
                args.channel_map,
                args.product_map,
                args.output_dir,
                allow_stale=args.allow_stale,
            )
            print(json.dumps({key: str(path) for key, path in paths.items()}, sort_keys=True))
        elif args.command == "verify":
            verify_outputs(
                args.report_data,
                args.aggregates,
                args.reconciliation,
                args.source_notes,
            )
            print("verification passed")
        elif args.command == "verify-modular":
            verify_modular_outputs(args.manifest)
            print("modular verification passed")
        else:
            paths = refresh_state_strategy_artifact(args.manifest)
            verify_modular_outputs(args.manifest)
            print(json.dumps({key: str(path) for key, path in paths.items()}, sort_keys=True))
    except (AssertionError, KeyError, OSError, TypeError, ValueError) as error:
        print(f"{args.command} failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
