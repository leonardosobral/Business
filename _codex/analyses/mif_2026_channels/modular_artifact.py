"""Deterministic, independently cacheable artifacts for the modular MIF report."""

from __future__ import annotations

from copy import deepcopy
from decimal import Decimal, InvalidOperation
import hashlib
import json
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

from .config import EVENT_CODE, PIPELINE_VERSION
from .models import AnalysisResult
from .normalize import normalize_key
from .phases import PHASE_ORDER
from .privacy import assert_anonymous
from .recommendations import recommend_channel
from .strategy import STRATEGY_TRANSFORM_VERSION, build_strategy


TRANSFORM_VERSION = f"{PIPELINE_VERSION}-modular.1"
GENERAL_DATASETS = (
    "event_overview",
    "age_bands",
    "gender_distribution",
    "pace_bands",
    "club_coverage",
    "payment_mix",
    "device_mix",
    "auxiliary_field_coverage",
    "data_quality",
    "roadrunners_capstone",
)
REGISTRATION_MONEY_FIELDS = (
    "allocated_gross_value",
    "allocated_discount_value",
    "allocated_fee_value",
)


def channel_slug(channel_name: object) -> str:
    """Return the stable public file stem used for a canonical channel."""
    normalized = normalize_key(channel_name).lower().replace(" ", "-")
    return normalized or "nao-informado"


def canonical_json_bytes(payload: Any) -> bytes:
    """Serialize JSON canonically so content hashes are reproducible."""
    return (
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def _sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _money(value: object) -> Decimal | None:
    if value is None:
        return None
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return None
    return parsed if parsed.is_finite() else None


def _project_registration_cube(
    rows: list[dict[str, Any]], dimensions: tuple[str, ...]
) -> list[dict[str, Any]]:
    """Collapse a detailed cube into deterministic observed domain cells."""
    grouped: dict[tuple[str, ...], dict[str, Any]] = {}
    for row in rows:
        key = tuple(str(row.get(dimension, "Não informado")) for dimension in dimensions)
        target = grouped.setdefault(
            key,
            {
                **dict(zip(dimensions, key)),
                "paid_registrations": 0,
                **{field: Decimal("0.00") for field in REGISTRATION_MONEY_FIELDS},
                "money_coverage": {
                    field: {"valid": 0, "denominator": 0}
                    for field in REGISTRATION_MONEY_FIELDS
                },
                "_money_complete": {
                    field: True for field in REGISTRATION_MONEY_FIELDS
                },
            },
        )
        target["paid_registrations"] += int(row.get("paid_registrations", 0) or 0)
        row_coverage = row.get("money_coverage", {}) or {}
        for field in REGISTRATION_MONEY_FIELDS:
            coverage = row_coverage.get(field, {}) or {}
            target["money_coverage"][field]["valid"] += int(
                coverage.get("valid", 0) or 0
            )
            target["money_coverage"][field]["denominator"] += int(
                coverage.get("denominator", row.get("paid_registrations", 0)) or 0
            )
            amount = _money(row.get(field))
            if amount is None:
                target["_money_complete"][field] = False
            else:
                target[field] += amount

    projected: list[dict[str, Any]] = []
    for key in sorted(grouped, key=lambda values: tuple(value.casefold() for value in values)):
        row = grouped[key]
        complete = row.pop("_money_complete")
        for field in REGISTRATION_MONEY_FIELDS:
            row[field] = format(row[field], ".2f") if complete[field] else None
        projected.append(row)
    return projected


def _channel_profiles(result: AnalysisResult) -> dict[str, dict[str, Any]]:
    profiles = {
        str(row["channel_name"]): deepcopy(row)
        for row in [*result.full_dossiers, *result.long_tail]
    }
    index_names = [
        str(row["channel_name"]) for row in result.datasets.get("channel_index", [])
    ]
    missing = sorted(set(index_names) - set(profiles), key=str.casefold)
    if missing:
        raise ValueError(f"channel profiles are missing: {', '.join(missing)}")
    slugs = [channel_slug(name) for name in index_names]
    if len(slugs) != len(set(slugs)):
        raise ValueError("channel slugs are not unique")
    return profiles


def _channel_index(
    result: AnalysisResult, profiles: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    rows = []
    for index_row in result.datasets.get("channel_index", []):
        channel_name = str(index_row["channel_name"])
        profile = profiles[channel_name]
        recommendation = recommend_channel(profile, result.overview)
        row = deepcopy(index_row)
        for field in (
            "paid_registrations",
            "gross_value",
            "registration_ticket",
            "executive_summary",
            "executive_highlight",
        ):
            if field in profile:
                row[field] = deepcopy(profile[field])
        row["slug"] = channel_slug(channel_name)
        row["recommendation"] = recommendation
        rows.append(row)
    return rows


def _dataset_subset(
    datasets: dict[str, list[dict[str, Any]]], identifiers: Iterable[str]
) -> dict[str, list[dict[str, Any]]]:
    return {
        identifier: deepcopy(datasets.get(identifier, []))
        for identifier in identifiers
    }


def _manifest(
    payloads: dict[str, Any],
    source_hashes: dict[str, str],
    generated_at: str,
) -> dict[str, Any]:
    source_payload = {
        str(key): str(value)
        for key, value in sorted(source_hashes.items(), key=lambda item: item[0])
    }
    source_sha256 = _sha256(canonical_json_bytes(source_payload))
    entries = {}
    for relative_path, payload in sorted(payloads.items()):
        serialized = canonical_json_bytes(payload)
        artifact_transform_version = str(
            (payload.get("meta") or {}).get("transform_version", TRANSFORM_VERSION)
            if isinstance(payload, dict)
            else TRANSFORM_VERSION
        )
        entries[relative_path] = {
            "path": relative_path,
            "sha256": _sha256(serialized),
            "bytes": len(serialized),
            "source_sha256": source_sha256,
            "transform_version": artifact_transform_version,
        }
    return {
        "event_code": EVENT_CODE,
        "generated_at": generated_at,
        "transform_version": TRANSFORM_VERSION,
        "source_sha256": source_sha256,
        "sources": source_payload,
        "artifacts": entries,
    }


def build_modular_artifacts(
    result: AnalysisResult,
    registration_cube: list[dict[str, Any]],
    product_cube: list[dict[str, Any]],
    source_hashes: dict[str, str],
    *,
    generated_at: str,
    cycle_boundaries: dict[str, str] | None = None,
) -> dict[str, Any]:
    """Build independent report, domain, explorer and channel payloads."""
    profiles = _channel_profiles(result)
    channel_index = _channel_index(result, profiles)
    metadata = {
        "event_code": EVENT_CODE,
        "generated_at": generated_at,
        "transform_version": TRANSFORM_VERSION,
    }
    strategy = build_strategy(
        overview=result.overview,
        summary_datasets=_dataset_subset(
            result.datasets,
            (
                "weekly_sales",
                "lot_performance",
                "modality_mix",
                "state_distribution",
                "product_summary",
            ),
        ),
        registration_cube=registration_cube,
        product_cube=product_cube,
        channel_index=channel_index,
    )
    strategy.pop("transform_version", None)
    strategy["meta"] = {
        "event_code": EVENT_CODE,
        "generated_at": generated_at,
        "transform_version": STRATEGY_TRANSFORM_VERSION,
    }
    payloads: dict[str, Any] = {
        "general.json": {
            "meta": metadata,
            "overview": deepcopy(result.overview),
            "datasets": _dataset_subset(result.datasets, GENERAL_DATASETS),
            "quality": deepcopy(result.quality),
            "source_notes": deepcopy(result.source_notes),
            "chart_metadata": deepcopy(result.chart_metadata),
        },
        "strategy.json": strategy,
        "cycle.json": {
            "meta": metadata,
            "phase_order": list(PHASE_ORDER),
            "phase_boundaries": deepcopy(cycle_boundaries or {}),
            "datasets": _dataset_subset(
                result.datasets,
                ("weekly_sales", "lot_performance", "modality_mix"),
            ),
            "observations": _project_registration_cube(
                registration_cube,
                ("week_start", "phase", "modality", "lot", "channel_name"),
            ),
        },
        "territories.json": {
            "meta": metadata,
            "datasets": _dataset_subset(
                result.datasets,
                ("country_distribution", "state_distribution", "city_distribution"),
            ),
            "observations": _project_registration_cube(
                registration_cube,
                ("week_start", "phase", "modality", "state", "channel_name"),
            ),
        },
        "products.json": {
            "meta": metadata,
            "datasets": _dataset_subset(result.datasets, ("product_summary",)),
            "observations": deepcopy(product_cube),
        },
        "channels/index.json": {
            "meta": metadata,
            "sort": ["gross_value desc", "paid_registrations desc", "channel_name asc"],
            "channels": channel_index,
        },
        "explorer.json": {
            "meta": metadata,
            "dimensions": {
                "registrations": [
                    "week_start",
                    "phase",
                    "modality",
                    "lot",
                    "state",
                    "city",
                    "channel_name",
                ],
                "products": [
                    "week_start",
                    "phase",
                    "modality",
                    "lot",
                    "state",
                    "channel_name",
                    "classification",
                    "product_name",
                ],
            },
            "metrics": {
                "registrations": [
                    "paid_registrations",
                    *REGISTRATION_MONEY_FIELDS,
                ],
                "products": [
                    "registrations_with_product",
                    "product_quantity",
                    "explicit_revenue",
                ],
            },
            "registration_cube": deepcopy(registration_cube),
            "product_cube": deepcopy(product_cube),
        },
    }

    aliases = result.datasets.get("channel_aliases", [])
    for channel_name, profile in profiles.items():
        relative_path = f"channels/{channel_slug(channel_name)}.json"
        payloads[relative_path] = {
            "meta": metadata,
            "channel": profile,
            "recommendation": recommend_channel(profile, result.overview),
            "aliases": [
                deepcopy(row)
                for row in aliases
                if str(row.get("channel_name")) == channel_name
            ],
            "registration_cube": [
                deepcopy(row)
                for row in registration_cube
                if str(row.get("channel_name")) == channel_name
            ],
            "product_cube": [
                deepcopy(row)
                for row in product_cube
                if str(row.get("channel_name")) == channel_name
            ],
        }

    assert_anonymous(payloads)
    artifacts = dict(payloads)
    artifacts["manifest.json"] = _manifest(
        payloads, source_hashes, generated_at
    )
    assert_anonymous(artifacts["manifest.json"])
    return artifacts


def _safe_destination(output_dir: Path, relative_path: str) -> Path:
    candidate = PurePosixPath(relative_path)
    if candidate.is_absolute() or ".." in candidate.parts or candidate.suffix != ".json":
        raise ValueError(f"unsafe modular artifact path: {relative_path}")
    return output_dir.joinpath(*candidate.parts)


def write_if_changed(path: Path, content: bytes) -> bool:
    """Atomically write content only when its canonical bytes changed."""
    if path.exists() and path.read_bytes() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_bytes(content)
    temporary.replace(path)
    return True


def write_modular_artifacts(
    output_dir: Path, artifacts: dict[str, Any]
) -> dict[str, Path]:
    """Write every modular artifact without touching identical destinations."""
    if "manifest.json" not in artifacts:
        raise ValueError("manifest.json is required")
    paths: dict[str, Path] = {}
    for relative_path in sorted(artifacts):
        destination = _safe_destination(output_dir, relative_path)
        write_if_changed(destination, canonical_json_bytes(artifacts[relative_path]))
        paths[relative_path] = destination
    return paths
