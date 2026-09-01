"""Privacy guardrails for anonymous MIF 2026 analysis outputs."""

from __future__ import annotations

from copy import deepcopy
from dataclasses import replace
import re
from typing import Any

from .config import FORBIDDEN_OUTPUT_KEYS
from .models import AnalysisResult
from .normalize import normalize_key


EMAIL_RE = re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I)
DOCUMENT_RE = re.compile(
    r"\b(?:\d{3}\.\d{3}\.\d{3}-\d{2}|\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})\b"
)
PHONE_RE = re.compile(
    r"(?<!\d)(?:\+?55\s*)?\(?\d{2}\)?\s*9?\d{4}[- ]?\d{4}(?!\d)"
)

_NORMALIZED_FORBIDDEN_KEYS = frozenset(
    normalize_key(key).lower().replace(" ", "_") for key in FORBIDDEN_OUTPUT_KEYS
)
_FREE_TEXT_KEYS = frozenset({"body", "note", "description", "summary"})


def suppress_small_cells(
    rows: list[dict[str, Any]],
    count_key: str,
    minimum: int = 3,
) -> list[dict[str, Any]]:
    """Aggregate cells below ``minimum`` while preserving their combined count."""
    small = [row for row in rows if int(row.get(count_key, 0)) < minimum]
    kept = [
        {**row, "suppressed": False}
        for row in rows
        if int(row.get(count_key, 0)) >= minimum
    ]
    if not small:
        return kept
    label_key = next(key for key in small[0] if key != count_key)
    suppressed = {
        label_key: "Outros / suprimido",
        count_key: sum(int(row.get(count_key, 0)) for row in small),
        "suppressed": True,
    }
    return [suppressed, *kept]


def _suppress_channel_dataset(
    rows: list[dict[str, Any]], count_key: str
) -> list[dict[str, Any]]:
    """Suppress a flattened channel cross-tab independently for each channel."""
    if not rows or "channel_name" not in rows[0]:
        return suppress_small_cells(rows, count_key)
    channel_order = list(dict.fromkeys(str(row["channel_name"]) for row in rows))
    result: list[dict[str, Any]] = []
    for channel_name in channel_order:
        channel_rows = [
            {key: value for key, value in row.items() if key != "channel_name"}
            for row in rows
            if str(row["channel_name"]) == channel_name
        ]
        result.extend(
            {"channel_name": channel_name, **row}
            for row in suppress_small_cells(channel_rows, count_key)
        )
    return result


def assert_anonymous(payload: Any) -> None:
    """Reject direct identifiers and PII-like values, reporting every JSON path."""
    findings: list[str] = []

    def visit(value: Any, path: str, key_name: str = "") -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                normalized_key = normalize_key(key).lower().replace(" ", "_")
                if normalized_key in _NORMALIZED_FORBIDDEN_KEYS:
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
            normalized_key = normalize_key(key_name).lower().replace(" ", "_")
            if normalized_key in _FREE_TEXT_KEYS and PHONE_RE.search(value):
                findings.append(f"{path}: phone-like value")

    visit(payload, "$")
    if findings:
        raise ValueError("; ".join(findings))


def protect_analysis(result: AnalysisResult) -> AnalysisResult:
    """Return an anonymous copy with suppression only in defined channel cross-tabs."""
    protected = deepcopy(result)
    datasets = protected.datasets
    for dataset_id in (
        "channel_city_mix",
        "channel_city_distribution",
        "channel_age_mix",
        "channel_age_bands",
        "channel_gender_mix",
        "channel_gender_distribution",
        "channel_pace_mix",
        "channel_pace_bands",
        "channel_club_presence",
        "channel_club_coverage",
    ):
        if dataset_id in datasets:
            datasets[dataset_id] = _suppress_channel_dataset(
                datasets[dataset_id], "paid_registrations"
            )

    dossier_fields = (
        "top_cities",
        "age_bands",
        "gender_mix",
        "pace_bands",
        "club_presence",
    )
    for dossier in protected.full_dossiers:
        for field in dossier_fields:
            if field in dossier:
                dossier[field] = suppress_small_cells(
                    dossier[field], "paid_registrations"
                )

    protected = replace(
        protected,
        datasets=datasets,
        full_dossiers=protected.full_dossiers,
    )
    assert_anonymous(protected.overview)
    assert_anonymous(protected.datasets)
    assert_anonymous(protected.full_dossiers)
    assert_anonymous(protected.long_tail)
    assert_anonymous(protected.quality)
    assert_anonymous(protected.source_notes)
    assert_anonymous(protected.chart_metadata)
    return protected
