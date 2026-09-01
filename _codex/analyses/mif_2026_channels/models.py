"""Typed value objects shared by the MIF 2026 analysis pipeline."""

from dataclasses import dataclass, field
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
    chart_metadata: dict[str, Any] = field(default_factory=dict)
