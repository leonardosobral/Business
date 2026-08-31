"""Reviewed, deterministic channel and product mappings for MIF 2026."""

from __future__ import annotations

from decimal import Decimal
from pathlib import Path

import pandas as pd

from .models import FactBundle
from .normalize import normalize_key


CHANNEL_MAPPING_COLUMNS = [
    "coupon_title_key",
    "coupon_code_key",
    "coupon_title_example",
    "coupon_code_example",
    "paid_registrations",
    "channel_name",
    "channel_type",
    "alias_reason",
    "reviewed",
]

PRODUCT_MAPPING_COLUMNS = [
    "product_id_key",
    "product_name_key",
    "product_id_example",
    "product_name_example",
    "observed_items",
    "canonical_name",
    "classification",
    "classification_reason",
    "reviewed",
]

ALLOWED_CHANNEL_TYPES = frozenset(
    {
        "parceiro",
        "influenciador",
        "assessoria",
        "comunidade",
        "campanha",
        "evento_acao",
        "politica",
        "beneficio",
        "cortesia",
        "organico",
        "outro",
    }
)
ALLOWED_PRODUCT_CLASSIFICATIONS = frozenset(
    {"kit_incluso", "adicional", "desconhecido"}
)


def _parse_reviewed(series: pd.Series, label: str) -> pd.Series:
    if pd.api.types.is_bool_dtype(series.dtype):
        return series.astype(bool)
    normalized = series.map(lambda value: normalize_key(value).lower())
    invalid = ~normalized.isin({"true", "false"})
    if invalid.any():
        raise ValueError(f"invalid reviewed value in {label} mapping")
    return normalized == "true"


def _require_columns(frame: pd.DataFrame, columns: list[str], label: str) -> None:
    missing = [column for column in columns if column not in frame.columns]
    if missing:
        raise ValueError(f"incomplete {label} mapping columns: {', '.join(missing)}")


def _validate_channel_mapping(
    mapping: pd.DataFrame, *, require_reviewed: bool
) -> pd.DataFrame:
    required = [
        "coupon_title_key",
        "coupon_code_key",
        "channel_name",
        "channel_type",
        "alias_reason",
        "reviewed",
    ]
    _require_columns(mapping, required, "channel")
    result = mapping.copy()
    for column in ("coupon_title_key", "coupon_code_key"):
        result[column] = result[column].map(normalize_key)
    result["reviewed"] = _parse_reviewed(result["reviewed"], "channel")
    duplicates = result.duplicated(
        ["coupon_title_key", "coupon_code_key"], keep=False
    )
    if duplicates.any():
        raise ValueError(f"duplicate channel mapping identities: {int(duplicates.sum())}")
    allowed_types = (
        ALLOWED_CHANNEL_TYPES
        if require_reviewed
        else ALLOWED_CHANNEL_TYPES | {""}
    )
    invalid_types = ~result["channel_type"].isin(allowed_types)
    if invalid_types.any():
        raise ValueError(f"invalid channel_type rows: {int(invalid_types.sum())}")
    if require_reviewed:
        incomplete = result[["channel_name", "channel_type", "alias_reason"]].apply(
            lambda column: column.map(normalize_key).eq("")
        )
        if incomplete.any(axis=None):
            raise ValueError("incomplete reviewed channel mapping")
        if (~result["reviewed"]).any():
            raise ValueError("channel mapping contains unreviewed rows")
    return result


def _validate_product_mapping(
    mapping: pd.DataFrame, *, require_reviewed: bool
) -> pd.DataFrame:
    required = [
        "product_id_key",
        "product_name_key",
        "canonical_name",
        "classification",
        "classification_reason",
        "reviewed",
    ]
    _require_columns(mapping, required, "product")
    result = mapping.copy()
    for column in ("product_id_key", "product_name_key"):
        result[column] = result[column].map(normalize_key)
    result["reviewed"] = _parse_reviewed(result["reviewed"], "product")
    duplicates = result.duplicated(
        ["product_id_key", "product_name_key"], keep=False
    )
    if duplicates.any():
        raise ValueError(f"duplicate product mapping identities: {int(duplicates.sum())}")
    allowed_classifications = (
        ALLOWED_PRODUCT_CLASSIFICATIONS
        if require_reviewed
        else ALLOWED_PRODUCT_CLASSIFICATIONS | {""}
    )
    invalid = ~result["classification"].isin(allowed_classifications)
    if invalid.any():
        raise ValueError(f"invalid classification rows: {int(invalid.sum())}")
    if require_reviewed:
        incomplete = result[
            ["canonical_name", "classification", "classification_reason"]
        ].apply(lambda column: column.map(normalize_key).eq(""))
        if incomplete.any(axis=None):
            raise ValueError("incomplete reviewed product mapping")
        if (~result["reviewed"]).any():
            raise ValueError("product mapping contains unreviewed rows")
    return result


def emit_channel_mapping_draft(registrations: pd.DataFrame, path: Path) -> None:
    """Write one draft row per exact paid, non-organic coupon identity."""
    paid = registrations.loc[registrations["is_paid"]].copy()
    paid["coupon_title_key"] = paid["coupon_title"].map(normalize_key)
    paid["coupon_code_key"] = paid["coupon_code"].map(normalize_key)
    observed = (
        paid.groupby(["coupon_title_key", "coupon_code_key"], dropna=False)
        .agg(
            coupon_title_example=("coupon_title", "first"),
            coupon_code_example=("coupon_code", "first"),
            paid_registrations=("numero_inscricao", "size"),
        )
        .reset_index()
    )
    observed = observed.loc[
        (observed["coupon_title_key"] != "")
        | (observed["coupon_code_key"] != "")
    ]
    observed.assign(
        channel_name="", channel_type="", alias_reason="", reviewed=False
    )[CHANNEL_MAPPING_COLUMNS].to_csv(path, index=False)


def load_channel_mapping(
    path: Path, require_reviewed: bool = True
) -> pd.DataFrame:
    """Load and validate the exact reviewed channel mapping CSV."""
    mapping = pd.read_csv(path, dtype=str, keep_default_na=False)
    if list(mapping.columns) != CHANNEL_MAPPING_COLUMNS:
        raise ValueError("incomplete channel mapping columns")
    mapping["paid_registrations"] = pd.to_numeric(
        mapping["paid_registrations"], errors="raise"
    )
    return _validate_channel_mapping(mapping, require_reviewed=require_reviewed)


def assign_channels(
    registrations: pd.DataFrame, mapping: pd.DataFrame
) -> pd.DataFrame:
    """Assign reviewed channels by exact normalized title/code pair."""
    validated = _validate_channel_mapping(mapping, require_reviewed=True)
    result = registrations.copy()
    result["coupon_title_key"] = result["coupon_title"].map(normalize_key)
    result["coupon_code_key"] = result["coupon_code"].map(normalize_key)
    result = result.merge(
        validated,
        on=["coupon_title_key", "coupon_code_key"],
        how="left",
        validate="many_to_one",
    )
    organic = (result["coupon_title_key"] == "") & (
        result["coupon_code_key"] == ""
    )
    result.loc[
        organic, ["channel_name", "channel_type", "alias_reason"]
    ] = ["Orgânico / sem cupom", "organico", "sem cupom"]
    missing = result["is_paid"] & result["channel_name"].isna()
    if missing.any():
        raise ValueError(f"unmapped paid coupon pairs: {int(missing.sum())}")
    return result


def emit_product_mapping_draft(products: pd.DataFrame, path: Path) -> None:
    """Write one draft row per exact observed product identity."""
    observed = products.copy()
    observed["product_id_key"] = observed["product_id"].map(normalize_key)
    observed["product_name_key"] = observed["product_name"].map(normalize_key)
    observed = (
        observed.groupby(["product_id_key", "product_name_key"], dropna=False)
        .agg(
            product_id_example=("product_id", "first"),
            product_name_example=("product_name", "first"),
            observed_items=("product_name", lambda values: len(values)),
        )
        .reset_index()
    )
    observed.assign(
        canonical_name="",
        classification="",
        classification_reason="",
        reviewed=False,
    )[PRODUCT_MAPPING_COLUMNS].to_csv(path, index=False)


def load_product_mapping(
    path: Path, require_reviewed: bool = True
) -> pd.DataFrame:
    """Load and validate the exact reviewed product mapping CSV."""
    mapping = pd.read_csv(path, dtype=str, keep_default_na=False)
    if list(mapping.columns) != PRODUCT_MAPPING_COLUMNS:
        raise ValueError("incomplete product mapping columns")
    mapping["observed_items"] = pd.to_numeric(
        mapping["observed_items"], errors="raise"
    )
    return _validate_product_mapping(mapping, require_reviewed=require_reviewed)


def _explicit_revenue(row: pd.Series) -> object:
    total = row["explicit_total_value"]
    if pd.notna(total):
        return total
    unit = row["explicit_unit_value"]
    quantity = row["product_quantity"]
    if pd.isna(unit) or pd.isna(quantity):
        return None
    if isinstance(unit, Decimal):
        return unit * Decimal(str(quantity))
    return unit * quantity


def classify_products(products: pd.DataFrame, mapping: pd.DataFrame) -> pd.DataFrame:
    """Classify exact product identities and expose only explicit product revenue."""
    validated = _validate_product_mapping(mapping, require_reviewed=True)
    result = products.copy()
    result["product_id_key"] = result["product_id"].map(normalize_key)
    result["product_name_key"] = result["product_name"].map(normalize_key)
    result = result.merge(
        validated,
        on=["product_id_key", "product_name_key"],
        how="left",
        validate="many_to_one",
    )
    if result["classification"].isna().any():
        raise ValueError(
            "unclassified product identities: "
            f"{int(result['classification'].isna().sum())}"
        )
    result["product_revenue"] = result.apply(_explicit_revenue, axis=1)
    return result


def apply_reviewed_mappings(
    facts: FactBundle,
    channel_mapping: pd.DataFrame,
    product_mapping: pd.DataFrame,
) -> FactBundle:
    """Return a new fact bundle with reviewed mapping assignments and coverage."""
    registrations = assign_channels(facts.registrations, channel_mapping)
    products = classify_products(facts.products, product_mapping)
    reconciliation = {
        **facts.reconciliation,
        "channel_mapping_coverage_pct": 100.0,
        "product_mapping_coverage_pct": 100.0,
    }
    return FactBundle(facts.orders, registrations, products, reconciliation)
