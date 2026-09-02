"""Anonymous observed-cell cubes for modular MIF analysis."""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import pandas as pd

from .models import FactBundle
from .phases import (
    SaleCycleBoundaries,
    assign_sale_phases,
    effective_sale_dates,
)


REGISTRATION_DIMENSIONS = (
    "week_start",
    "phase",
    "modality",
    "lot",
    "state",
    "city",
    "channel_name",
)
PRODUCT_DIMENSIONS = (
    "week_start",
    "phase",
    "modality",
    "lot",
    "state",
    "channel_name",
    "classification",
    "product_name",
)
REGISTRATION_MONEY_COLUMNS = (
    "allocated_gross_value",
    "allocated_discount_value",
    "allocated_fee_value",
)
UNKNOWN = "Não informado"


def _money_total(values: pd.Series, *, require_complete: bool) -> str | None:
    covered = [value for value in values if isinstance(value, Decimal)]
    if not covered or (require_complete and len(covered) != len(values)):
        return None
    return format(sum(covered, Decimal("0.00")), ".2f")


def _registration_dimensions(
    registrations: pd.DataFrame, boundaries: SaleCycleBoundaries
) -> pd.DataFrame:
    prepared = registrations.copy()
    sale_dates = effective_sale_dates(prepared)
    week_starts = sale_dates.dt.to_period("W-SUN").dt.start_time
    prepared["week_start"] = week_starts.map(
        lambda value: value.date().isoformat() if pd.notna(value) else UNKNOWN
    )
    prepared["phase"] = assign_sale_phases(sale_dates, boundaries).fillna(UNKNOWN)
    for dimension in ("modality", "lot", "state", "city", "channel_name"):
        if dimension not in prepared:
            prepared[dimension] = UNKNOWN
        prepared[dimension] = prepared[dimension].map(
            lambda value: UNKNOWN if pd.isna(value) or not str(value).strip() else str(value)
        )
    return prepared


def build_registration_cube(
    facts: FactBundle, boundaries: SaleCycleBoundaries
) -> list[dict[str, Any]]:
    """Aggregate paid registrations by every observed approved dimension cell."""
    paid = facts.registrations.loc[facts.registrations["is_paid"]].copy()
    if paid.empty:
        return []
    prepared = _registration_dimensions(paid, boundaries)
    rows: list[dict[str, Any]] = []
    for keys, group in prepared.groupby(list(REGISTRATION_DIMENSIONS), sort=True):
        row = dict(zip(REGISTRATION_DIMENSIONS, keys))
        row["paid_registrations"] = len(group)
        coverage: dict[str, dict[str, int]] = {}
        for column in REGISTRATION_MONEY_COLUMNS:
            values = (
                group[column]
                if column in group
                else pd.Series([None] * len(group), index=group.index)
            )
            valid = int(values.map(lambda value: isinstance(value, Decimal)).sum())
            row[column] = _money_total(values, require_complete=True)
            coverage[column] = {"valid": valid, "denominator": len(group)}
        row["money_coverage"] = coverage
        rows.append(row)
    return rows


def build_product_cube(
    facts: FactBundle, boundaries: SaleCycleBoundaries
) -> list[dict[str, Any]]:
    """Aggregate non-kit paid-registration products without exporting identifiers."""
    paid = facts.registrations.loc[facts.registrations["is_paid"]].copy()
    if paid.empty or facts.products.empty:
        return []
    context = _registration_dimensions(paid, boundaries)[
        [
            "numero_inscricao",
            "week_start",
            "phase",
            "modality",
            "lot",
            "state",
            "channel_name",
        ]
    ]
    products = facts.products.merge(
        context,
        on="numero_inscricao",
        how="inner",
        validate="many_to_one",
    ).copy()
    if products.empty:
        return []
    products["product_name"] = products.get(
        "canonical_name", pd.Series([UNKNOWN] * len(products), index=products.index)
    ).map(lambda value: UNKNOWN if pd.isna(value) or not str(value).strip() else str(value))
    products["classification"] = products.get(
        "classification", pd.Series([UNKNOWN] * len(products), index=products.index)
    ).map(lambda value: UNKNOWN if pd.isna(value) or not str(value).strip() else str(value))
    products = products.loc[products["classification"] != "kit_incluso"].copy()
    if products.empty:
        return []

    rows: list[dict[str, Any]] = []
    for keys, group in products.groupby(list(PRODUCT_DIMENSIONS), sort=True):
        row = dict(zip(PRODUCT_DIMENSIONS, keys))
        row["registrations_with_product"] = int(group["numero_inscricao"].nunique())
        quantities = pd.to_numeric(group.get("product_quantity"), errors="coerce")
        row["product_quantity"] = int(quantities.fillna(0).sum())
        revenue = group.get(
            "product_revenue",
            pd.Series([None] * len(group), index=group.index),
        )
        valid_revenue = int(revenue.map(lambda value: isinstance(value, Decimal)).sum())
        row["explicit_revenue"] = _money_total(revenue, require_complete=False)
        row["explicit_revenue_coverage"] = {
            "valid_items": valid_revenue,
            "items": len(group),
            "coverage_pct": round(valid_revenue / len(group) * 100, 2),
        }
        rows.append(row)
    return rows
