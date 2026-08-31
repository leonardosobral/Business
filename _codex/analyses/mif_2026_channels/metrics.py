"""Anonymous event aggregates and evidence-first channel dossiers for MIF 2026."""

from __future__ import annotations

from collections import Counter
from collections.abc import Iterable
from decimal import Decimal, ROUND_HALF_UP
from itertools import combinations
import math
import re
from typing import Any

import pandas as pd

from .config import (
    FORBIDDEN_OUTPUT_KEYS,
    FULL_DOSSIER_MIN_REGISTRATIONS,
    SMALL_CELL_MIN_REGISTRATIONS,
)
from .models import AnalysisResult, FactBundle
from .normalize import normalize_key


MONEY_QUANTUM = Decimal("0.01")
SAMPLE_WARNING = "Base abaixo de 10 inscrições pagas; leitura indicativa"
NOT_MEASURED = "não mensurado"

DATASET_IDS = (
    "event_overview",
    "weekly_sales",
    "lot_performance",
    "modality_mix",
    "country_distribution",
    "state_distribution",
    "city_distribution",
    "age_bands",
    "gender_distribution",
    "pace_bands",
    "club_coverage",
    "payment_mix",
    "device_mix",
    "auxiliary_field_coverage",
    "product_summary",
    "channel_index",
    "channel_aliases",
    "channel_modality_mix",
    "channel_state_mix",
    "channel_lot_mix",
    "channel_weekly_sales",
    "channel_product_mix",
    "channel_profile_coverage",
    "geography_overlap",
    "modality_overlap",
    "lot_overlap",
    "temporal_overlap",
    "profile_overlap",
    "product_overlap",
    "long_tail",
    "data_quality",
)

BRAZIL_MACROREGIONS = {
    "AC": "Norte",
    "AP": "Norte",
    "AM": "Norte",
    "PA": "Norte",
    "RO": "Norte",
    "RR": "Norte",
    "TO": "Norte",
    "AL": "Nordeste",
    "BA": "Nordeste",
    "CE": "Nordeste",
    "MA": "Nordeste",
    "PB": "Nordeste",
    "PE": "Nordeste",
    "PI": "Nordeste",
    "RN": "Nordeste",
    "SE": "Nordeste",
    "DF": "Centro-Oeste",
    "GO": "Centro-Oeste",
    "MT": "Centro-Oeste",
    "MS": "Centro-Oeste",
    "ES": "Sudeste",
    "MG": "Sudeste",
    "RJ": "Sudeste",
    "SP": "Sudeste",
    "PR": "Sul",
    "RS": "Sul",
    "SC": "Sul",
}

AGE_BAND_ORDER = (
    "<18",
    "18–24",
    "25–34",
    "35–44",
    "45–54",
    "55–64",
    "65+",
    "Não informado",
    "Inválido",
)
PACE_BAND_ORDER = (
    "<4:30",
    "4:30–4:59",
    "5:00–5:29",
    "5:30–5:59",
    "6:00–6:29",
    "6:30–6:59",
    "7:00–7:59",
    "8:00+",
    "Não informado",
    "Inválido",
)


def _as_decimal(value: object) -> Decimal | None:
    if value is None or value is pd.NA:
        return None
    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass
    if isinstance(value, Decimal):
        return value
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return Decimal(str(value))
    return None


def _decimal_total(frame: pd.DataFrame, column: str) -> Decimal:
    if column not in frame:
        return Decimal("0")
    return sum(
        (parsed for value in frame[column].tolist() if (parsed := _as_decimal(value)) is not None),
        Decimal("0"),
    )


def _covered_decimal_total(frame: pd.DataFrame, column: str) -> Decimal | None:
    if frame.empty or column not in frame:
        return None
    values = [_as_decimal(value) for value in frame[column].tolist()]
    return None if any(value is None for value in values) else sum(values, Decimal("0"))


def _money(value: Decimal | None) -> str | None:
    return None if value is None else format(value.quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


def weighted_ticket(
    frame: pd.DataFrame, value_column: str, count_column: str | None = None
) -> Decimal | None:
    """Return a weighted ticket at the frame's declared grain."""
    total_value = _decimal_total(frame, value_column)
    denominator = (
        len(frame)
        if count_column is None
        else int(pd.to_numeric(frame[count_column], errors="coerce").fillna(0).sum())
    )
    return (
        None
        if denominator == 0
        else (total_value / denominator).quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP)
    )


def count_distribution(frame: pd.DataFrame, dimension: str) -> list[dict[str, object]]:
    """Count a registration dimension, retaining an explicit missing bucket."""
    if frame.empty:
        return []
    normalized = frame[dimension].where(frame[dimension].notna(), "Não informado")
    counts = Counter(normalized.tolist())
    rows = [
        {
            dimension: value,
            "paid_registrations": count,
            "denominator": len(frame),
            "share_pct": round(count / len(frame) * 100, 2),
        }
        for value, count in counts.items()
    ]
    return sorted(rows, key=lambda row: (-int(row["paid_registrations"]), str(row[dimension]).casefold()))


def geographic_scope(
    paid_registrations: int,
    macroregions: int,
    states: int,
    leading_state_pct: float,
    leading_city_pct: float,
    non_brazil_pct: float,
) -> dict[str, object]:
    """Classify geographic reach descriptively from the agreed visible thresholds."""
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


def percentage_point_delta(
    channel_count: int, channel_total: int, event_count: int, event_total: int
) -> float | None:
    """Return a percentage-point delta only when both bases are visible."""
    if channel_total == 0 or event_total == 0:
        return None
    return round(
        channel_count / channel_total * 100 - event_count / event_total * 100,
        2,
    )


def jensen_shannon_similarity(
    left: dict[str, float], right: dict[str, float]
) -> float:
    """Return bounded similarity without collapsing independent dimensions."""
    keys = sorted(set(left) | set(right))
    p = [max(left.get(key, 0.0), 0.0) for key in keys]
    q = [max(right.get(key, 0.0), 0.0) for key in keys]
    p_total, q_total = sum(p), sum(q)
    if p_total == 0 or q_total == 0:
        raise ValueError("similarity requires two non-empty distributions")
    p, q = [value / p_total for value in p], [value / q_total for value in q]
    midpoint = [(a + b) / 2 for a, b in zip(p, q)]
    divergence = 0.5 * sum(
        a * math.log2(a / middle)
        for a, middle in zip(p, midpoint, strict=True)
        if a
    ) + 0.5 * sum(
        b * math.log2(b / middle)
        for b, middle in zip(q, midpoint, strict=True)
        if b
    )
    return round(1.0 - math.sqrt(max(divergence, 0.0)), 4)


def _status_value(row: pd.Series, field: str) -> object:
    status_column = f"{field}_status"
    status = row.get(status_column)
    if status == "invalido":
        return "Inválido"
    if status == "nao_informado":
        return "Não informado"
    value = row.get(field)
    return "Não informado" if value is None or (not isinstance(value, (list, dict)) and pd.isna(value)) else value


def _dimension_series(frame: pd.DataFrame, field: str) -> pd.Series:
    if frame.empty:
        return pd.Series(dtype=object)
    return frame.apply(lambda row: _status_value(row, field), axis=1)


def _age_band(row: pd.Series) -> str:
    value = _status_value(row, "age")
    if value in {"Inválido", "Não informado"}:
        return str(value)
    try:
        age = int(value)
    except (TypeError, ValueError):
        return "Inválido"
    if age < 0:
        return "Inválido"
    if age < 18:
        return "<18"
    if age < 25:
        return "18–24"
    if age < 35:
        return "25–34"
    if age < 45:
        return "35–44"
    if age < 55:
        return "45–54"
    if age < 65:
        return "55–64"
    return "65+"


def _pace_band(row: pd.Series) -> str:
    value = _status_value(row, "pace_seconds")
    if value in {"Inválido", "Não informado"}:
        return str(value)
    try:
        seconds = int(value)
    except (TypeError, ValueError):
        return "Inválido"
    if seconds <= 0:
        return "Inválido"
    if seconds < 270:
        return "<4:30"
    if seconds < 300:
        return "4:30–4:59"
    if seconds < 330:
        return "5:00–5:29"
    if seconds < 360:
        return "5:30–5:59"
    if seconds < 390:
        return "6:00–6:29"
    if seconds < 420:
        return "6:30–6:59"
    if seconds < 480:
        return "7:00–7:59"
    return "8:00+"


def _band_distribution(
    frame: pd.DataFrame,
    output_key: str,
    builder: Any,
    order: Iterable[str],
) -> list[dict[str, object]]:
    if frame.empty:
        return []
    values = frame.apply(builder, axis=1)
    counts = Counter(values)
    position = {value: index for index, value in enumerate(order)}
    return [
        {
            output_key: value,
            "paid_registrations": count,
            "denominator": len(frame),
            "share_pct": round(count / len(frame) * 100, 2),
        }
        for value, count in sorted(counts.items(), key=lambda item: position[item[0]])
    ]


def _renamed_distribution(
    frame: pd.DataFrame, source: str, output: str
) -> list[dict[str, object]]:
    working = frame.copy()
    working[output] = _dimension_series(frame, source)
    return count_distribution(working, output)


def _coverage(frame: pd.DataFrame, field: str) -> dict[str, float | int]:
    status_column = f"{field}_status"
    if frame.empty:
        valid = invalid = missing = 0
    elif status_column in frame:
        valid = int((frame[status_column] == "valido").sum())
        invalid = int((frame[status_column] == "invalido").sum())
        missing = int((frame[status_column] == "nao_informado").sum())
    else:
        present = frame[field].notna() if field in frame else pd.Series(False, index=frame.index)
        valid, invalid, missing = int(present.sum()), 0, int((~present).sum())
    answered = valid + invalid
    total = len(frame)
    return {
        "answered": answered,
        "valid": valid,
        "invalid": invalid,
        "missing": missing,
        "denominator": total,
        "coverage_pct": round(answered / total * 100, 2) if total else 0.0,
        "valid_coverage_pct": round(valid / total * 100, 2) if total else 0.0,
    }


def _distribution_delta(
    channel_rows: list[dict[str, object]],
    event_rows: list[dict[str, object]],
    segment_key: str,
    channel_total: int,
    event_total: int,
    coverage: dict[str, float | int] | None = None,
) -> list[dict[str, object]]:
    event_by_segment = {str(row[segment_key]): row for row in event_rows}
    result = []
    for row in channel_rows:
        event = event_by_segment.get(str(row[segment_key]), {})
        channel_count = int(row["paid_registrations"])
        event_count = int(event.get("paid_registrations", 0))
        result.append(
            {
                "segment": row[segment_key],
                "channel_count": channel_count,
                "channel_denominator": channel_total,
                "event_count": event_count,
                "event_denominator": event_total,
                "delta_pp": percentage_point_delta(
                    channel_count, channel_total, event_count, event_total
                ),
                "coverage": coverage or {"denominator": channel_total},
            }
        )
    return result


def _attach_event_deltas(
    channel_rows: list[dict[str, object]],
    event_rows: list[dict[str, object]],
    segment_key: str,
    channel_total: int,
    event_total: int,
    coverage: dict[str, float | int],
) -> list[dict[str, object]]:
    deltas = {
        str(row["segment"]): row
        for row in _distribution_delta(
            channel_rows,
            event_rows,
            segment_key,
            channel_total,
            event_total,
            coverage,
        )
    }
    return [
        {
            **row,
            "channel_count": deltas[str(row[segment_key])]["channel_count"],
            "channel_denominator": deltas[str(row[segment_key])]["channel_denominator"],
            "event_count": deltas[str(row[segment_key])]["event_count"],
            "event_denominator": deltas[str(row[segment_key])]["event_denominator"],
            "delta_pp": deltas[str(row[segment_key])]["delta_pp"],
            "coverage": coverage,
        }
        for row in channel_rows
    ]


def _geography_details(frame: pd.DataFrame) -> tuple[
    dict[str, object], list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]
]:
    total = len(frame)
    countries = _renamed_distribution(frame, "country", "country")
    states = _renamed_distribution(frame, "state", "state")
    cities = _renamed_distribution(frame, "city", "city")
    valid_states = [
        str(value)
        for value in _dimension_series(frame, "state")
        if value not in {"Não informado", "Inválido"} and str(value) in BRAZIL_MACROREGIONS
    ]
    valid_cities = [
        str(value)
        for value in _dimension_series(frame, "city")
        if value not in {"Não informado", "Inválido"}
    ]
    state_counts = Counter(valid_states)
    city_counts = Counter(valid_cities)
    leading_state_pct = (
        max(state_counts.values()) / total * 100 if total and state_counts else 0.0
    )
    leading_city_pct = (
        max(city_counts.values()) / total * 100 if total and city_counts else 0.0
    )
    country_values = _dimension_series(frame, "country")
    non_brazil = sum(
        value not in {"Brasil", "Não informado", "Inválido"} for value in country_values
    )
    scope = geographic_scope(
        total,
        len({BRAZIL_MACROREGIONS[value] for value in valid_states}),
        len(set(valid_states)),
        leading_state_pct,
        leading_city_pct,
        non_brazil / total * 100 if total else 0.0,
    )
    scope.update(
        {
            "cities": len(set(valid_cities)),
            "countries": len(
                {
                    str(value)
                    for value in country_values
                    if value not in {"Não informado", "Inválido"}
                }
            ),
            "state_concentration_hhi": round(
                sum((count / total) ** 2 for count in state_counts.values()), 4
            ),
            "city_concentration_hhi": round(
                sum((count / total) ** 2 for count in city_counts.values()), 4
            ),
            "coverage": {
                "country": _coverage(frame, "country"),
                "state": _coverage(frame, "state"),
                "city": _coverage(frame, "city"),
            },
        }
    )
    return scope, countries, states, cities


def _weekly_sales(frame: pd.DataFrame) -> list[dict[str, object]]:
    if frame.empty:
        return []
    dated = frame.loc[_dimension_series(frame, "sale_date") != "Inválido"].copy()
    dated = dated.loc[dated["sale_date"].notna()]
    if dated.empty:
        return []
    dated["week_start"] = pd.to_datetime(dated["sale_date"]).dt.to_period("W-SUN").dt.start_time
    rows = []
    for week, group in dated.groupby("week_start", sort=True):
        rows.append(
            {
                "week_start": week.date().isoformat(),
                "paid_registrations": len(group),
                "allocated_gross_value": _money(_decimal_total(group, "allocated_gross_value")),
            }
        )
    return rows


def _coupon_aliases(frame: pd.DataFrame) -> list[dict[str, object]]:
    columns = ["coupon_title", "coupon_code", "alias_reason"]
    available = [column for column in columns if column in frame]
    if not available:
        return []
    aliases = (
        frame.groupby(available, dropna=False).size().reset_index(name="paid_registrations")
    )
    rows = []
    for row in aliases.to_dict("records"):
        rows.append(
            {
                "coupon_title": None if pd.isna(row.get("coupon_title")) else row.get("coupon_title"),
                "coupon_code": None if pd.isna(row.get("coupon_code")) else row.get("coupon_code"),
                "alias_reason": None if pd.isna(row.get("alias_reason")) else row.get("alias_reason"),
                "paid_registrations": int(row["paid_registrations"]),
            }
        )
    return sorted(rows, key=lambda row: (str(row["coupon_code"] or "").casefold(), str(row["coupon_title"] or "").casefold()))


def _product_mix(
    registrations: pd.DataFrame, products: pd.DataFrame
) -> list[dict[str, object]]:
    if registrations.empty or products.empty:
        return []
    selected = products.loc[
        products["numero_inscricao"].isin(registrations["numero_inscricao"])
    ].copy()
    if selected.empty:
        return []
    rows = []
    for (classification, product), group in selected.groupby(
        ["classification", "canonical_name"], dropna=False, sort=True
    ):
        registrations_with_product = int(group["numero_inscricao"].nunique())
        explicit_values = [
            parsed
            for value in group.get("product_revenue", pd.Series(dtype=object)).tolist()
            if (parsed := _as_decimal(value)) is not None
        ]
        rows.append(
            {
                "classification": str(classification),
                "product_name": str(product),
                "product_quantity": int(pd.to_numeric(group["product_quantity"], errors="coerce").fillna(0).sum()),
                "registrations_with_product": registrations_with_product,
                "take_rate_denominator": len(registrations),
                "take_rate_pct": round(registrations_with_product / len(registrations) * 100, 2),
                "explicit_revenue": _money(sum(explicit_values, Decimal("0"))) if explicit_values else None,
                "explicit_revenue_coverage_pct": round(len(explicit_values) / len(group) * 100, 2),
            }
        )
    return rows


def _profile_rows(frame: pd.DataFrame) -> tuple[
    dict[str, dict[str, float | int]],
    list[dict[str, object]],
    list[dict[str, object]],
    list[dict[str, object]],
    list[dict[str, object]],
]:
    coverage = {
        "age": _coverage(frame, "age"),
        "gender": _coverage(frame, "gender"),
        "pace": _coverage(frame, "pace_seconds"),
        "club": _coverage(frame, "club"),
    }
    ages = _band_distribution(frame, "age_band", _age_band, AGE_BAND_ORDER)
    genders = _renamed_distribution(frame, "gender", "gender")
    paces = _band_distribution(frame, "pace_band", _pace_band, PACE_BAND_ORDER)
    for row in paces:
        row["coverage"] = coverage["pace"]
    valid_clubs = frame.loc[
        _dimension_series(frame, "club").map(lambda value: value not in {"Não informado", "Inválido"})
    ].copy()
    clubs = _renamed_distribution(valid_clubs, "club", "club")
    for row in clubs:
        row["denominator"] = len(frame)
        row["share_pct"] = round(int(row["paid_registrations"]) / len(frame) * 100, 2) if len(frame) else 0.0
        row["coverage"] = coverage["club"]
    return coverage, ages, genders, paces, clubs


def _channel_money(frame: pd.DataFrame, column: str, *, require_coverage: bool = False) -> str | None:
    total = _covered_decimal_total(frame, column) if require_coverage else _decimal_total(frame, column)
    return _money(total)


def _compact_dossier(
    channel_name: str,
    channel_type: str,
    frame: pd.DataFrame,
) -> dict[str, object]:
    _, _, states, _ = _geography_details(frame)
    modalities = _renamed_distribution(frame, "modality", "modality")
    warnings = []
    for field in ("state", "age", "pace_seconds", "club"):
        coverage = _coverage(frame, field)
        if float(coverage["valid_coverage_pct"]) < 70:
            warnings.append(f"Cobertura válida de {field}: {coverage['valid_coverage_pct']:.2f}%")
    aliases = _coupon_aliases(frame)
    return {
        "channel_name": channel_name,
        "channel_type": channel_type,
        "touched_paid_orders": int(frame["numero_pedido"].nunique()),
        "paid_registrations": len(frame),
        "gross_value": _channel_money(frame, "allocated_gross_value") or "0.00",
        "registration_ticket": _money(weighted_ticket(frame, "allocated_gross_value")) or "0.00",
        "principal_modality": modalities[0] if modalities else None,
        "principal_state": states[0] if states else None,
        "coupon_codes": sorted(
            {str(row["coupon_code"]) for row in aliases if row["coupon_code"] is not None},
            key=str.casefold,
        ),
        "coverage_warnings": warnings,
        "sample_warning": SAMPLE_WARNING,
    }


def split_dossiers(
    rows: list[dict[str, object]],
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    """Split full and compact channel records at the agreed paid-registration base."""
    full = [
        row
        for row in rows
        if int(row["paid_registrations"]) >= FULL_DOSSIER_MIN_REGISTRATIONS
    ]
    compact = [
        row
        for row in rows
        if int(row["paid_registrations"]) < FULL_DOSSIER_MIN_REGISTRATIONS
    ]
    key = lambda row: str(row["channel_name"]).casefold()
    return sorted(full, key=key), sorted(compact, key=key)


def build_channel_dossiers(
    registrations: pd.DataFrame,
    orders: pd.DataFrame,
    products: pd.DataFrame,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Build complete and compact dossiers without ranking channels."""
    paid_registrations = (
        registrations.loc[registrations["is_paid"]].copy()
        if "is_paid" in registrations
        else registrations.copy()
    )
    paid_orders = (
        orders.loc[orders["is_paid"]].copy() if "is_paid" in orders else orders.copy()
    )
    if paid_registrations.empty:
        return [], []
    event_total = len(paid_registrations)
    event_modality = _renamed_distribution(paid_registrations, "modality", "modality")
    event_lot = _renamed_distribution(paid_registrations, "lot", "lot")
    _, event_age, event_gender, event_pace, _ = _profile_rows(paid_registrations)
    _, event_countries, event_states, event_cities = _geography_details(
        paid_registrations
    )
    event_products = _product_mix(paid_registrations, products)
    rows: list[dict[str, object]] = []
    compact_rows: list[dict[str, object]] = []

    for channel_name, frame in paid_registrations.groupby("channel_name", sort=False):
        frame = frame.copy()
        channel_type = str(frame["channel_type"].iloc[0])
        if len(frame) < FULL_DOSSIER_MIN_REGISTRATIONS:
            compact_rows.append(
                _compact_dossier(str(channel_name), channel_type, frame)
            )
            continue

        touched_order_ids = set(frame["numero_pedido"])
        touched_paid_orders = paid_orders.loc[
            paid_orders["numero_pedido"].isin(touched_order_ids)
        ]
        touched_count = int(touched_paid_orders["numero_pedido"].nunique())
        modality = _renamed_distribution(frame, "modality", "modality")
        lots = _renamed_distribution(frame, "lot", "lot")
        scope, countries, states, cities = _geography_details(frame)
        profile_coverage, ages, genders, paces, clubs = _profile_rows(frame)
        product_mix = _product_mix(frame, products)
        countries = _attach_event_deltas(
            countries,
            event_countries,
            "country",
            len(frame),
            event_total,
            _coverage(frame, "country"),
        )
        states = _attach_event_deltas(
            states,
            event_states,
            "state",
            len(frame),
            event_total,
            _coverage(frame, "state"),
        )
        cities = _attach_event_deltas(
            cities,
            event_cities,
            "city",
            len(frame),
            event_total,
            _coverage(frame, "city"),
        )
        event_product_lookup = {
            (str(row["classification"]), str(row["product_name"])): row
            for row in event_products
        }
        for row in product_mix:
            event_product = event_product_lookup.get(
                (str(row["classification"]), str(row["product_name"])), {}
            )
            event_count = int(event_product.get("registrations_with_product", 0))
            row.update(
                {
                    "event_registrations_with_product": event_count,
                    "event_take_rate_denominator": event_total,
                    "take_rate_delta_pp": percentage_point_delta(
                        int(row["registrations_with_product"]),
                        len(frame),
                        event_count,
                        event_total,
                    ),
                    "coverage": {
                        "channel_denominator": len(frame),
                        "event_denominator": event_total,
                        "reviewed_product_mapping": True,
                    },
                }
            )
        modality_delta = _distribution_delta(
            modality, event_modality, "modality", len(frame), event_total
        )
        lot_delta = _distribution_delta(lots, event_lot, "lot", len(frame), event_total)
        profile_delta = []
        for dimension, channel_rows, event_rows, segment_key, coverage_field in (
            ("age", ages, event_age, "age_band", "age"),
            ("gender", genders, event_gender, "gender", "gender"),
            ("pace", paces, event_pace, "pace_band", "pace"),
        ):
            for delta in _distribution_delta(
                channel_rows,
                event_rows,
                segment_key,
                len(frame),
                event_total,
                profile_coverage[coverage_field],
            ):
                profile_delta.append({"profile_dimension": dimension, **delta})
        gross = _decimal_total(frame, "allocated_gross_value")
        limitations = [
            "Pedidos tocados não são aditivos entre canais",
            "Patrocínio externo, espaço Expo, barter e cortesias não possuem fonte financeira identificada",
        ]
        for field, label in (
            ("state", "geografia por UF"),
            ("age", "idade"),
            ("pace_seconds", "ritmo"),
            ("club", "clube/assessoria"),
        ):
            if float(_coverage(frame, field)["valid_coverage_pct"]) < 70:
                limitations.append(f"Cobertura válida abaixo de 70% para {label}")
        rows.append(
            {
                "channel_name": str(channel_name),
                "channel_type": channel_type,
                "touched_paid_orders": touched_count,
                "paid_registrations": len(frame),
                "registrations_per_order": round(len(frame) / touched_count, 2) if touched_count else 0.0,
                "gross_value": _money(gross) or "0.00",
                "discount_value": _channel_money(frame, "allocated_discount_value") or "0.00",
                "fee_value": _channel_money(frame, "allocated_fee_value", require_coverage=True),
                "net_transfer_value": _channel_money(frame, "allocated_net_transfer_value", require_coverage=True),
                "cashback_value": _channel_money(frame, "allocated_cashback_value", require_coverage=True),
                "allocated_value_per_touched_order": _money(gross / touched_count) if touched_count else "0.00",
                "registration_ticket": _money(weighted_ticket(frame, "allocated_gross_value")) or "0.00",
                "share_of_event_registrations": round(len(frame) / event_total * 100, 2),
                "coupon_aliases": _coupon_aliases(frame),
                "geographic_scope": scope,
                "countries": countries,
                "modality_mix": modality,
                "modality_delta_pp": modality_delta,
                "lot_mix": lots,
                "lot_delta_pp": lot_delta,
                "top_states": states,
                "top_cities": cities,
                "weekly_sales": _weekly_sales(frame),
                "profile_coverage": profile_coverage,
                "age_bands": ages,
                "gender_mix": genders,
                "pace_bands": paces,
                "club_presence": clubs,
                "product_mix": product_mix,
                "profile_delta_pp": profile_delta,
                "similar_channels_by_dimension": [],
                "distinctive_signals": [],
                "external_considerations_status": NOT_MEASURED,
                "data_limitations": limitations,
            }
        )

    full, _ = split_dossiers(rows)
    _, compact = split_dossiers(compact_rows)
    return full, compact


def _distribution_for_overlap(
    frame: pd.DataFrame, dimension: str
) -> tuple[dict[str, float], float]:
    total = len(frame)
    if dimension == "geography":
        values = _dimension_series(frame, "state")
        valid = [str(value) for value in values if value not in {"Não informado", "Inválido"}]
    elif dimension == "modality":
        values = _dimension_series(frame, "modality")
        valid = [str(value) for value in values if value not in {"Não informado", "Inválido"}]
    elif dimension == "lot":
        values = _dimension_series(frame, "lot")
        valid = [str(value) for value in values if value not in {"Não informado", "Inválido"}]
    elif dimension == "temporal":
        values = _dimension_series(frame, "sale_date")
        valid = [
            pd.Timestamp(value).to_period("W-SUN").start_time.date().isoformat()
            for value in values
            if value not in {"Não informado", "Inválido"}
        ]
    elif dimension == "age":
        valid = [
            _age_band(row)
            for _, row in frame.iterrows()
            if _age_band(row) not in {"Não informado", "Inválido"}
        ]
    elif dimension == "gender":
        values = _dimension_series(frame, "gender")
        valid = [str(value) for value in values if value not in {"Não informado", "Inválido"}]
    elif dimension == "pace":
        valid = [
            _pace_band(row)
            for _, row in frame.iterrows()
            if _pace_band(row) not in {"Não informado", "Inválido"}
        ]
    elif dimension == "club":
        values = _dimension_series(frame, "club")
        valid = [str(value) for value in values if value not in {"Não informado", "Inválido"}]
    elif dimension == "product":
        valid = []
        for products in frame.get("addon_products", pd.Series([[]] * len(frame), index=frame.index)):
            entries = products if isinstance(products, list) else []
            valid.extend(str(product) for product in entries or ["Sem adicional"])
    else:  # pragma: no cover - internal callers enumerate dimensions
        raise ValueError(f"unsupported overlap dimension: {dimension}")
    coverage = 100.0 if dimension == "product" and total else (
        round(len(valid) / total * 100, 2) if total else 0.0
    )
    return dict(Counter(valid)), coverage


def _leading_segments(distribution: dict[str, float]) -> set[str]:
    if not distribution:
        return set()
    largest = max(distribution.values())
    return {segment for segment, value in distribution.items() if value == largest}


def build_dimension_overlaps(
    channel_rows: pd.DataFrame,
) -> dict[str, list[dict[str, Any]]]:
    """Build six independent channel-overlap views without a master score."""
    result: dict[str, list[dict[str, Any]]] = {
        "geography_overlap": [],
        "modality_overlap": [],
        "lot_overlap": [],
        "temporal_overlap": [],
        "profile_overlap": [],
        "product_overlap": [],
    }
    if channel_rows.empty:
        return result
    paid = (
        channel_rows.loc[channel_rows["is_paid"]].copy()
        if "is_paid" in channel_rows
        else channel_rows.copy()
    )
    eligible = {
        str(channel): frame.copy()
        for channel, frame in paid.groupby("channel_name", sort=False)
        if len(frame) >= FULL_DOSSIER_MIN_REGISTRATIONS
    }
    simple_dimensions = (
        ("geography", "geography_overlap"),
        ("modality", "modality_overlap"),
        ("lot", "lot_overlap"),
        ("temporal", "temporal_overlap"),
        ("product", "product_overlap"),
    )
    for channel_a, channel_b in combinations(sorted(eligible, key=str.casefold), 2):
        left_frame, right_frame = eligible[channel_a], eligible[channel_b]
        for dimension, dataset_id in simple_dimensions:
            left, coverage_a = _distribution_for_overlap(left_frame, dimension)
            right, coverage_b = _distribution_for_overlap(right_frame, dimension)
            if len(left) < 1 or len(right) < 1:
                continue
            if dimension != "product" and (
                sum(left.values()) < SMALL_CELL_MIN_REGISTRATIONS
                or sum(right.values()) < SMALL_CELL_MIN_REGISTRATIONS
            ):
                continue
            result[dataset_id].append(
                {
                    "channel_a": channel_a,
                    "channel_b": channel_b,
                    "similarity_0_1": jensen_shannon_similarity(left, right),
                    "shared_leading_segments": sorted(
                        _leading_segments(left) & _leading_segments(right), key=str.casefold
                    ),
                    "coverage_a": coverage_a,
                    "coverage_b": coverage_b,
                }
            )
        for profile_dimension in ("age", "gender", "pace", "club"):
            left, coverage_a = _distribution_for_overlap(left_frame, profile_dimension)
            right, coverage_b = _distribution_for_overlap(right_frame, profile_dimension)
            if (
                sum(left.values()) < SMALL_CELL_MIN_REGISTRATIONS
                or sum(right.values()) < SMALL_CELL_MIN_REGISTRATIONS
            ):
                continue
            result["profile_overlap"].append(
                {
                    "channel_a": channel_a,
                    "channel_b": channel_b,
                    "profile_dimension": profile_dimension,
                    "similarity_0_1": jensen_shannon_similarity(left, right),
                    "shared_leading_segments": sorted(
                        _leading_segments(left) & _leading_segments(right), key=str.casefold
                    ),
                    "coverage_a": coverage_a,
                    "coverage_b": coverage_b,
                }
            )
    return result


def _overview(paid_orders: pd.DataFrame, paid_registrations: pd.DataFrame, facts: FactBundle) -> dict[str, Any]:
    order_count, registration_count = len(paid_orders), len(paid_registrations)
    coupon_assisted = int(
        (
            paid_registrations.get("channel_type", pd.Series(index=paid_registrations.index, dtype=object))
            != "organico"
        ).sum()
    )
    organic = int(
        (
            paid_registrations.get("channel_type", pd.Series(index=paid_registrations.index, dtype=object))
            == "organico"
        ).sum()
    )
    return {
        "paid_orders": order_count,
        "paid_registrations": registration_count,
        "registrations_per_order": round(registration_count / order_count, 2) if order_count else 0.0,
        "gross_value": _money(_decimal_total(paid_orders, "gross_order_value")) or "0.00",
        "discount_value": _money(_decimal_total(paid_orders, "discount_value")) or "0.00",
        "fee_value": _money(_covered_decimal_total(paid_orders, "fee_value")),
        "net_transfer_value": _money(_covered_decimal_total(paid_orders, "net_transfer_value")),
        "cashback_value": _money(_covered_decimal_total(paid_orders, "cashback_value")),
        "order_ticket": _money(weighted_ticket(paid_orders, "gross_order_value")),
        "registration_ticket": _money(weighted_ticket(paid_registrations, "allocated_gross_value")),
        "coupon_assisted_registrations": coupon_assisted,
        "coupon_assisted_denominator": registration_count,
        "coupon_assisted_share_pct": round(coupon_assisted / registration_count * 100, 2) if registration_count else 0.0,
        "organic_registrations": organic,
        "organic_denominator": registration_count,
        "organic_share_pct": round(organic / registration_count * 100, 2) if registration_count else 0.0,
        "source_field_coverage": {
            "orders": facts.reconciliation.get("order_field_coverage", {}),
            "registrations": facts.reconciliation.get("registration_field_coverage", {}),
            "channel_mapping_coverage_pct": facts.reconciliation.get("channel_mapping_coverage_pct"),
            "product_mapping_coverage_pct": facts.reconciliation.get("product_mapping_coverage_pct"),
        },
        "external_considerations_status": NOT_MEASURED,
    }


def _lot_performance(frame: pd.DataFrame) -> list[dict[str, object]]:
    if frame.empty:
        return []
    working = frame.copy()
    working["lot"] = _dimension_series(frame, "lot")
    rows = []
    for lot, group in working.groupby("lot", dropna=False, sort=True):
        rows.append(
            {
                "lot": lot,
                "paid_registrations": len(group),
                "allocated_gross_value": _money(_decimal_total(group, "allocated_gross_value")) or "0.00",
                "allocated_discount_value": _money(_decimal_total(group, "allocated_discount_value")) or "0.00",
                "registration_ticket": _money(weighted_ticket(group, "allocated_gross_value")) or "0.00",
                "event_denominator": len(frame),
                "event_share_pct": round(len(group) / len(frame) * 100, 2),
            }
        )
    return sorted(rows, key=lambda row: (-int(row["paid_registrations"]), str(row["lot"]).casefold()))


def _order_distribution(frame: pd.DataFrame, source: str, output: str) -> list[dict[str, object]]:
    if frame.empty:
        return []
    values = frame[source].where(frame[source].notna(), "Não informado") if source in frame else pd.Series("Não informado", index=frame.index)
    counts = Counter(values)
    return sorted(
        [
            {
                output: value,
                "paid_orders": count,
                "denominator": len(frame),
                "share_pct": round(count / len(frame) * 100, 2),
            }
            for value, count in counts.items()
        ],
        key=lambda row: (-int(row["paid_orders"]), str(row[output]).casefold()),
    )


def _auxiliary_coverage(
    paid_orders: pd.DataFrame,
    paid_registrations: pd.DataFrame,
    reconciliation: dict[str, Any],
) -> list[dict[str, object]]:
    rows = []
    order_coverage = reconciliation.get("order_field_coverage", {})
    for label, frame, field in (
        ("payment_method", paid_orders, "payment_method"),
        ("device", paid_orders, "device_type"),
        ("order_quantity", paid_orders, "declared_registration_count"),
        ("questionnaire_completion", paid_registrations, "questionnaire_present"),
    ):
        source_counts = order_coverage.get(field) if frame is paid_orders else None
        if source_counts:
            valid = int(source_counts.get("valido", 0))
            invalid = int(source_counts.get("invalido", 0))
            missing = int(source_counts.get("nao_informado", 0))
            denominator = valid + invalid + missing
            coverage = {
                "answered": valid + invalid,
                "valid": valid,
                "invalid": invalid,
                "missing": missing,
                "denominator": denominator,
                "coverage_pct": round((valid + invalid) / denominator * 100, 2)
                if denominator
                else 0.0,
                "valid_coverage_pct": round(valid / denominator * 100, 2)
                if denominator
                else 0.0,
            }
        else:
            coverage = _coverage(frame, field)
        rows.append({"field": label, **coverage})
    key_counts: Counter[str] = Counter()
    forbidden_tokens = {
        normalize_key(key).replace(" ", "") for key in FORBIDDEN_OUTPUT_KEYS
    }
    for keys in paid_registrations.get("auxiliary_json_keys", pd.Series(dtype=object)):
        if not isinstance(keys, list):
            continue
        key_counts.update(
            str(key)
            for key in keys
            if not any(
                token and token in normalize_key(key).replace(" ", "")
                for token in forbidden_tokens
            )
        )
    total = len(paid_registrations)
    rows.extend(
        {
            "field": f"json_key:{key}",
            "answered": count,
            "valid": count,
            "invalid": 0,
            "missing": total - count,
            "denominator": total,
            "coverage_pct": round(count / total * 100, 2) if total else 0.0,
            "valid_coverage_pct": round(count / total * 100, 2) if total else 0.0,
        }
        for key, count in sorted(key_counts.items(), key=lambda item: item[0].casefold())
    )
    return rows


def _data_quality(facts: FactBundle, paid_registrations: pd.DataFrame) -> list[dict[str, object]]:
    rows = []
    for column in sorted(
        (column for column in paid_registrations if column.endswith("_status")),
        key=str.casefold,
    ):
        field = column.removesuffix("_status")
        counts = Counter(paid_registrations[column])
        rows.append(
            {
                "grain": "registration",
                "field": field,
                "valid": int(counts.get("valido", 0)),
                "invalid": int(counts.get("invalido", 0)),
                "missing": int(counts.get("nao_informado", 0)),
                "denominator": len(paid_registrations),
                "coverage_pct": round(
                    (counts.get("valido", 0) + counts.get("invalido", 0))
                    / len(paid_registrations)
                    * 100,
                    2,
                )
                if len(paid_registrations)
                else 0.0,
            }
        )
    existing = {(row["grain"], row["field"]) for row in rows}
    for field, counts in facts.reconciliation.get("order_field_coverage", {}).items():
        if ("order", field) in existing:
            continue
        denominator = sum(int(value) for value in counts.values())
        rows.append(
            {
                "grain": "order",
                "field": field,
                "valid": int(counts.get("valido", 0)),
                "invalid": int(counts.get("invalido", 0)),
                "missing": int(counts.get("nao_informado", 0)),
                "denominator": denominator,
                "coverage_pct": round(
                    (int(counts.get("valido", 0)) + int(counts.get("invalido", 0)))
                    / denominator
                    * 100,
                    2,
                )
                if denominator
                else 0.0,
            }
        )
    return sorted(rows, key=lambda row: (str(row["grain"]), str(row["field"])))


def _channel_datasets(
    paid_registrations: pd.DataFrame,
    full: list[dict[str, Any]],
    compact: list[dict[str, Any]],
) -> dict[str, list[dict[str, Any]]]:
    by_name = {row["channel_name"]: row for row in [*full, *compact]}
    channel_index = []
    for channel_name, frame in paid_registrations.groupby("channel_name", sort=False):
        dossier = by_name[str(channel_name)]
        channel_index.append(
            {
                "channel_name": str(channel_name),
                "channel_type": str(frame["channel_type"].iloc[0]),
                "touched_paid_orders": int(frame["numero_pedido"].nunique()),
                "paid_registrations": len(frame),
                "gross_value": dossier["gross_value"],
                "registration_ticket": dossier["registration_ticket"],
                "dossier_type": "full" if len(frame) >= FULL_DOSSIER_MIN_REGISTRATIONS else "compact",
            }
        )
    channel_index.sort(key=lambda row: str(row["channel_name"]).casefold())
    aliases = []
    for channel_name, frame in paid_registrations.groupby("channel_name", sort=False):
        aliases.extend({"channel_name": str(channel_name), **row} for row in _coupon_aliases(frame))
    aliases.sort(key=lambda row: (str(row["channel_name"]).casefold(), str(row["coupon_code"] or "").casefold()))

    def flatten(field: str) -> list[dict[str, Any]]:
        flattened = []
        for dossier in full:
            for row in dossier[field]:
                flattened.append({"channel_name": dossier["channel_name"], **row})
        return flattened

    profile_coverage = []
    for dossier in full:
        profile_coverage.extend(
            {
                "channel_name": dossier["channel_name"],
                "profile_dimension": dimension,
                **coverage,
            }
            for dimension, coverage in dossier["profile_coverage"].items()
        )
    return {
        "channel_index": channel_index,
        "channel_aliases": aliases,
        "channel_modality_mix": flatten("modality_mix"),
        "channel_state_mix": flatten("top_states"),
        "channel_lot_mix": flatten("lot_mix"),
        "channel_weekly_sales": flatten("weekly_sales"),
        "channel_product_mix": flatten("product_mix"),
        "channel_profile_coverage": profile_coverage,
    }


def _decorate_similarity(
    dossiers: list[dict[str, Any]], overlaps: dict[str, list[dict[str, Any]]]
) -> None:
    for dossier in dossiers:
        channel = dossier["channel_name"]
        comparisons = []
        for dataset_id, rows in overlaps.items():
            for row in rows:
                if channel not in {row["channel_a"], row["channel_b"]}:
                    continue
                dimension = dataset_id.removesuffix("_overlap")
                if dataset_id == "profile_overlap":
                    dimension = f"profile:{row['profile_dimension']}"
                comparisons.append(
                    {
                        "dimension": dimension,
                        "other_channel": row["channel_b"] if row["channel_a"] == channel else row["channel_a"],
                        "similarity_0_1": row["similarity_0_1"],
                        "shared_leading_segments": row["shared_leading_segments"],
                        "channel_coverage": row["coverage_a"] if row["channel_a"] == channel else row["coverage_b"],
                        "other_coverage": row["coverage_b"] if row["channel_a"] == channel else row["coverage_a"],
                    }
                )
        dossier["similar_channels_by_dimension"] = sorted(
            comparisons,
            key=lambda row: (str(row["dimension"]), str(row["other_channel"]).casefold()),
        )


def _signal_from_delta(
    paid_registrations: int,
    dimension: str,
    delta: dict[str, object],
) -> dict[str, object] | None:
    value = delta.get("delta_pp")
    if value is None or abs(float(value)) < 10:
        return None
    prefix = "indício em base pequena — " if paid_registrations < 30 else ""
    direction = "acima" if float(value) > 0 else "abaixo"
    return {
        "signal": f"{prefix}{dimension} {delta['segment']}: {abs(float(value)):.2f} pp {direction} do evento",
        "dimension": dimension,
        "segment": delta["segment"],
        "count": delta["channel_count"],
        "denominator": delta["channel_denominator"],
        "event_count": delta["event_count"],
        "event_denominator": delta["event_denominator"],
        "delta_pp": value,
        "coverage": delta["coverage"],
        "comparison": "evento",
    }


def _decorate_distinctive_signals(
    dossiers: list[dict[str, Any]],
    paid_registrations: pd.DataFrame,
    products: pd.DataFrame,
) -> None:
    qualifying = {dossier["channel_name"] for dossier in dossiers}
    unique_owners: dict[tuple[str, str], set[str]] = {}
    for dimension, field in (("country", "country"), ("state", "state"), ("modality", "modality")):
        for channel, frame in paid_registrations.loc[
            paid_registrations["channel_name"].isin(qualifying)
        ].groupby("channel_name"):
            values = {
                str(value)
                for value in _dimension_series(frame, field)
                if value not in {"Não informado", "Inválido"}
            }
            for value in values:
                unique_owners.setdefault((dimension, value), set()).add(str(channel))
    if not products.empty:
        add_ons = products.loc[products["classification"] == "adicional"].merge(
            paid_registrations[["numero_inscricao", "channel_name"]],
            on="numero_inscricao",
            how="inner",
            validate="many_to_one",
        )
        for (product, channel), _ in add_ons.loc[
            add_ons["channel_name"].isin(qualifying)
        ].groupby(["canonical_name", "channel_name"]):
            unique_owners.setdefault(("product", str(product)), set()).add(str(channel))

    for dossier in dossiers:
        signals = []
        for dimension, deltas in (
            ("modalidade", dossier["modality_delta_pp"]),
            ("lote", dossier["lot_delta_pp"]),
            ("perfil", dossier["profile_delta_pp"]),
        ):
            for delta in deltas:
                signal = _signal_from_delta(
                    dossier["paid_registrations"], dimension, delta
                )
                if signal is not None:
                    signals.append(signal)
        for dimension, rows, segment_key in (
            ("país", dossier["countries"], "country"),
            ("UF", dossier["top_states"], "state"),
            ("cidade", dossier["top_cities"], "city"),
        ):
            for row in rows:
                signal = _signal_from_delta(
                    dossier["paid_registrations"],
                    dimension,
                    {
                        "segment": row[segment_key],
                        "channel_count": row["channel_count"],
                        "channel_denominator": row["channel_denominator"],
                        "event_count": row["event_count"],
                        "event_denominator": row["event_denominator"],
                        "delta_pp": row["delta_pp"],
                        "coverage": row["coverage"],
                    },
                )
                if signal is not None:
                    signals.append(signal)
        for row in dossier["product_mix"]:
            signal = _signal_from_delta(
                dossier["paid_registrations"],
                "produto adicional",
                {
                    "segment": row["product_name"],
                    "channel_count": row["registrations_with_product"],
                    "channel_denominator": row["take_rate_denominator"],
                    "event_count": row["event_registrations_with_product"],
                    "event_denominator": row["event_take_rate_denominator"],
                    "delta_pp": row["take_rate_delta_pp"],
                    "coverage": row["coverage"],
                },
            )
            if signal is not None:
                signals.append(signal)
        channel_frame = paid_registrations.loc[
            paid_registrations["channel_name"] == dossier["channel_name"]
        ]
        for (dimension, segment), owners in unique_owners.items():
            if owners != {dossier["channel_name"]}:
                continue
            if dimension == "product":
                matching = products.loc[
                    (products["classification"] == "adicional")
                    & (products["canonical_name"].astype(str) == segment)
                    & products["numero_inscricao"].isin(channel_frame["numero_inscricao"])
                ]
                count = int(matching["numero_inscricao"].nunique())
                coverage = {"reviewed_product_mapping": True, "denominator": len(channel_frame)}
            else:
                field = dimension
                count = int((_dimension_series(channel_frame, field).astype(str) == segment).sum())
                coverage = _coverage(channel_frame, field)
            prefix = "indício em base pequena — " if dossier["paid_registrations"] < 30 else ""
            signals.append(
                {
                    "signal": f"{prefix}{dimension} {segment}: único canal elegível com cobertura",
                    "dimension": dimension,
                    "segment": segment,
                    "count": count,
                    "denominator": dossier["paid_registrations"],
                    "event_count": count,
                    "event_denominator": len(paid_registrations),
                    "delta_pp": percentage_point_delta(
                        count, dossier["paid_registrations"], count, len(paid_registrations)
                    ),
                    "coverage": coverage,
                    "comparison": "único canal elegível",
                }
            )
        dossier["distinctive_signals"] = sorted(
            signals, key=lambda row: (str(row["dimension"]), str(row["segment"]).casefold())
        )


def _assert_result(
    overview: dict[str, Any],
    datasets: dict[str, list[dict[str, Any]]],
    full: list[dict[str, Any]],
    compact: list[dict[str, Any]],
) -> None:
    if set(datasets) != set(DATASET_IDS):
        raise AssertionError("analysis dataset IDs do not match the stable contract")
    event_total = int(overview["paid_registrations"])
    if sum(int(row["paid_registrations"]) for row in datasets["modality_mix"]) != event_total:
        raise AssertionError("modality registrations do not reconcile")
    if sum(int(row["paid_registrations"]) for row in datasets["lot_performance"]) != event_total:
        raise AssertionError("lot registrations do not reconcile")
    if len(full) + len(compact) != len(datasets["channel_index"]):
        raise AssertionError("full and compact dossier counts do not reconcile")
    if sum(int(row["paid_registrations"]) for row in datasets["channel_index"]) != event_total:
        raise AssertionError("channel registrations do not reconcile")

    money_pattern = re.compile(r"^-?\d+\.\d{2}$")

    def inspect(value: object, key: str = "") -> None:
        if isinstance(value, dict):
            for child_key, child in value.items():
                inspect(child, str(child_key))
        elif isinstance(value, list):
            for child in value:
                inspect(child, key)
        elif key.endswith("_pct") and value is not None:
            if not 0 <= float(value) <= 100:
                raise AssertionError(f"percentage outside 0..100: {key}")
        elif isinstance(value, str) and (
            key.endswith("_value")
            or key.endswith("_ticket")
            or key.endswith("_revenue")
        ):
            if not money_pattern.fullmatch(value):
                raise AssertionError(f"invalid money format: {key}")

    inspect(overview)
    inspect(datasets)
    inspect(full)
    inspect(compact)


def build_analysis(facts: FactBundle) -> AnalysisResult:
    """Build the complete anonymous analysis at explicit commercial grains."""
    required_registration_columns = {"is_paid", "channel_name", "channel_type"}
    missing = required_registration_columns - set(facts.registrations)
    if missing:
        raise ValueError(f"mapped registration facts required: {', '.join(sorted(missing))}")
    paid_orders = facts.orders.loc[facts.orders["is_paid"]].copy()
    paid_registrations = facts.registrations.loc[facts.registrations["is_paid"]].copy()
    paid_products = facts.products.loc[
        facts.products["numero_inscricao"].isin(paid_registrations["numero_inscricao"])
    ].copy()

    overview = _overview(paid_orders, paid_registrations, facts)
    modality = _renamed_distribution(paid_registrations, "modality", "modality")
    lots = _lot_performance(paid_registrations)
    countries = _renamed_distribution(paid_registrations, "country", "country")
    states = _renamed_distribution(paid_registrations, "state", "state")
    cities = _renamed_distribution(paid_registrations, "city", "city")
    _, ages, genders, paces, clubs = _profile_rows(paid_registrations)
    products = _product_mix(paid_registrations, paid_products)
    full, compact = build_channel_dossiers(paid_registrations, paid_orders, paid_products)

    overlap_rows = paid_registrations.copy()
    if not paid_products.empty:
        add_ons = (
            paid_products.loc[paid_products["classification"] == "adicional"]
            .groupby("numero_inscricao")["canonical_name"]
            .agg(list)
        )
        overlap_rows["addon_products"] = overlap_rows["numero_inscricao"].map(add_ons)
    if "addon_products" not in overlap_rows:
        overlap_rows["addon_products"] = pd.Series([[] for _ in range(len(overlap_rows))], index=overlap_rows.index)
    else:
        overlap_rows["addon_products"] = overlap_rows["addon_products"].map(
            lambda value: value if isinstance(value, list) else []
        )
    overlaps = build_dimension_overlaps(overlap_rows)
    _decorate_similarity(full, overlaps)
    _decorate_distinctive_signals(full, paid_registrations, paid_products)
    channel_datasets = _channel_datasets(paid_registrations, full, compact)

    datasets: dict[str, list[dict[str, Any]]] = {
        "event_overview": [overview],
        "weekly_sales": _weekly_sales(paid_registrations),
        "lot_performance": lots,
        "modality_mix": modality,
        "country_distribution": countries,
        "state_distribution": states,
        "city_distribution": cities,
        "age_bands": ages,
        "gender_distribution": genders,
        "pace_bands": paces,
        "club_coverage": clubs,
        "payment_mix": _order_distribution(paid_orders, "payment_method", "payment_method"),
        "device_mix": _order_distribution(paid_orders, "device_type", "device_type"),
        "auxiliary_field_coverage": _auxiliary_coverage(
            paid_orders, paid_registrations, facts.reconciliation
        ),
        "product_summary": products,
        **channel_datasets,
        **overlaps,
        "long_tail": compact,
        "data_quality": _data_quality(facts, paid_registrations),
    }
    _assert_result(overview, datasets, full, compact)
    quality = {
        "data_quality": datasets["data_quality"],
        "reconciliation": facts.reconciliation,
    }
    source_notes = {
        "commercial_grains": {
            "event_orders": "pedidos pagos únicos",
            "event_registrations": "inscrições pagas",
            "channel_money": "valores de pedido alocados às inscrições",
            "touched_paid_orders": "não aditivo entre canais",
        },
        "external_considerations": {
            "sponsorship": NOT_MEASURED,
            "expo_space": NOT_MEASURED,
            "barter": NOT_MEASURED,
            "courtesy_valuation": NOT_MEASURED,
        },
        "similarity": "seis dimensões independentes; nenhum score mestre",
        "geographic_scope": "classificação descritiva, não estratégica",
    }
    return AnalysisResult(
        overview=overview,
        datasets=datasets,
        full_dossiers=full,
        long_tail=compact,
        quality=quality,
        source_notes=source_notes,
    )
