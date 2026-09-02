"""Reusable commercial phase assignment for the closed MIF sales cycle."""

from __future__ import annotations

from dataclasses import dataclass

import pandas as pd


PHASE_ORDER = ("Lançamento", "Início", "Meio", "Reta final", "Encerramento")


@dataclass(frozen=True)
class SaleCycleBoundaries:
    start: pd.Timestamp
    end: pd.Timestamp
    launch_end: pd.Timestamp
    early_end: pd.Timestamp
    middle_end: pd.Timestamp
    final_sprint_end: pd.Timestamp


def effective_sale_dates(frame: pd.DataFrame) -> pd.Series:
    """Prefer a valid registration sale date and fall back to its order date."""
    dates = frame.get(
        "sale_date",
        pd.Series([None] * len(frame), index=frame.index, dtype=object),
    ).copy()
    statuses = frame.get("sale_date_status")
    if statuses is not None:
        dates = dates.where(statuses == "valido", None)
    if "order_date" in frame:
        fallback = dates.isna()
        if statuses is not None:
            fallback &= statuses == "nao_informado"
        dates = dates.where(~fallback, frame["order_date"])
    return pd.to_datetime(dates, errors="coerce")


def build_sale_cycle_boundaries(dates: pd.Series) -> SaleCycleBoundaries:
    """Build fixed launch and relative commercial boundaries from valid dates."""
    valid = pd.to_datetime(dates, errors="coerce").dropna().sort_values()
    if valid.empty:
        raise ValueError("sale cycle requires at least one valid date")
    start = valid.iloc[0].normalize()
    end = valid.iloc[-1].normalize()
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


def assign_sale_phases(
    dates: pd.Series, boundaries: SaleCycleBoundaries
) -> pd.Series:
    """Assign valid in-cycle dates to the five approved commercial phases."""
    normalized = pd.to_datetime(dates, errors="coerce").dt.normalize()
    phases = pd.Series([None] * len(normalized), index=normalized.index, dtype=object)
    in_cycle = normalized.between(boundaries.start, boundaries.end, inclusive="both")
    phases.loc[in_cycle & (normalized <= boundaries.launch_end)] = "Lançamento"
    phases.loc[
        in_cycle
        & (normalized > boundaries.launch_end)
        & (normalized <= boundaries.early_end)
    ] = "Início"
    phases.loc[
        in_cycle
        & (normalized > boundaries.early_end)
        & (normalized <= boundaries.middle_end)
    ] = "Meio"
    phases.loc[
        in_cycle
        & (normalized > boundaries.middle_end)
        & (normalized <= boundaries.final_sprint_end)
    ] = "Reta final"
    phases.loc[in_cycle & (normalized > boundaries.final_sprint_end)] = "Encerramento"
    return phases
