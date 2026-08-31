"""Build grain-safe MIF order, registration, and product facts."""

from __future__ import annotations

from collections.abc import Callable
from decimal import Decimal, ROUND_DOWN
from typing import Any

import pandas as pd

from .config import EVENT_CODE, PAID_STATUS
from .models import FactBundle, SourceBundle
from .normalize import (
    age_on_event_date,
    coverage_status,
    normalize_city,
    normalize_country,
    normalize_gender,
    normalize_lot,
    normalize_modality,
    normalize_state,
    normalize_status,
    normalize_text,
    pace_to_seconds,
    parse_date,
    parse_decimal,
    parse_json_object,
)


MONEY_QUANTUM = Decimal("0.01")

ORDER_JSON_FIELDS = {
    "order_date": "dataPedido",
    "payment_date": "dataPagamento",
    "status": "status",
    "gross_order_value": "valor",
    "discount_value": "desconto",
    "fee_value": "taxa",
    "net_transfer_value": "valorRepassePedido",
    "cashback_value": "cashback",
    "installments": "qtdParcela",
    "payment_method": "formaDePagamento",
    "device_type": "tipoDispositivo",
    "declared_registration_count": "qtdeInscricao",
}

_ORDER_COLUMNS = [
    "cod_evento",
    "numero_pedido",
    "order_date",
    "payment_date",
    "status",
    "is_paid",
    "gross_order_value",
    "discount_value",
    "fee_value",
    "net_transfer_value",
    "cashback_value",
    "installments",
    "payment_method",
    "device_type",
    "declared_registration_count",
    "parsed_registration_count",
]

_ORDER_MONEY_TO_ALLOCATED = {
    "gross_order_value": "allocated_gross_value",
    "discount_value": "allocated_discount_value",
    "fee_value": "allocated_fee_value",
    "net_transfer_value": "allocated_net_transfer_value",
    "cashback_value": "allocated_cashback_value",
}

_RECONCILIATION_MONEY_KEYS = {
    "gross_order_value": ("paid_order_gross", "allocated_registration_gross"),
    "discount_value": ("paid_order_discount", "allocated_registration_discount"),
    "fee_value": ("paid_order_fee", "allocated_registration_fee"),
    "net_transfer_value": (
        "paid_order_net_transfer",
        "allocated_registration_net_transfer",
    ),
    "cashback_value": ("paid_order_cashback", "allocated_registration_cashback"),
}

_REPORTED_TO_ALLOCATED = {
    "gross": ("reported_registration_gross_value", "allocated_gross_value"),
    "discount": (
        "reported_registration_discount_value",
        "allocated_discount_value",
    ),
    "fee": ("reported_registration_fee_value", "allocated_fee_value"),
    "net_transfer": (
        "reported_registration_net_transfer_value",
        "allocated_net_transfer_value",
    ),
}

_RECONCILIATION_COUNT_KEYS = frozenset(
    {
        "source_order_rows",
        "source_registration_rows",
        "paid_order_count",
        "paid_registration_count",
        "orders_with_multiple_registrations",
        "unmatched_registration_count",
        "invalid_json_count",
    }
)

_SAFE_PRODUCT_VALUE_KEYS = frozenset(
    {
        "id",
        "codigo",
        "nome",
        "produto",
        "quantidade",
        "valorUnitario",
        "valorTotal",
    }
)


def _event_code(value: object) -> int:
    try:
        return int(value)
    except (TypeError, ValueError) as error:
        raise ValueError("invalid event code in source row") from error


def _parse_nonnegative_integer(value: object) -> int | None:
    parsed = parse_decimal(value)
    if parsed is None or parsed < 0 or parsed != parsed.to_integral_value():
        return None
    return int(parsed)


def _first_present(body: dict[str, Any], *keys: str) -> object:
    for key in keys:
        if key in body:
            return body[key]
    return None


def _coupon_value(body: dict[str, Any], top_level_key: str, nested_key: str) -> object:
    if top_level_key in body:
        return body[top_level_key]
    nested = body.get("cupom")
    return nested.get(nested_key) if isinstance(nested, dict) else None


def _field_status(raw_value: object, parsed_value: object, *, invalid: bool = False) -> str:
    return coverage_status(raw_value, None if invalid else parsed_value)


def _sanitize_products(raw_value: object) -> list[dict[str, object]] | None:
    if not isinstance(raw_value, list) or any(
        not isinstance(item, dict) for item in raw_value
    ):
        return None
    return [
        {
            key: value if key in _SAFE_PRODUCT_VALUE_KEYS else None
            for key, value in item.items()
        }
        for item in raw_value
    ]


def build_order_fact(bundle: SourceBundle) -> pd.DataFrame:
    """Return one normalized row for each composite order key."""
    participant_counts: dict[tuple[int, object], int] = {}
    if not bundle.participants.empty:
        counts = (
            bundle.participants.assign(
                cod_evento=bundle.participants["cod_evento"].map(_event_code)
            )
            .groupby(["cod_evento", "numero_pedido"], dropna=False)
            .size()
        )
        participant_counts = {key: int(value) for key, value in counts.items()}

    rows: list[dict[str, object]] = []
    coverage_rows: list[dict[str, str]] = []
    for position, source_row in enumerate(bundle.orders.to_dict("records")):
        body = parse_json_object(source_row["body"], row_position=position)
        event_code = _event_code(source_row["cod_evento"])
        order_key = (event_code, source_row["numero_pedido"])
        raw = {target: body.get(source) for target, source in ORDER_JSON_FIELDS.items()}

        parsed: dict[str, object] = {
            "order_date": parse_date(raw["order_date"]),
            "payment_date": parse_date(raw["payment_date"]),
            "status": normalize_status(raw["status"]),
            "gross_order_value": parse_decimal(raw["gross_order_value"]),
            "discount_value": parse_decimal(raw["discount_value"]),
            "fee_value": parse_decimal(raw["fee_value"]),
            "net_transfer_value": parse_decimal(raw["net_transfer_value"]),
            "cashback_value": parse_decimal(raw["cashback_value"]),
            "installments": _parse_nonnegative_integer(raw["installments"]),
            "payment_method": normalize_text(raw["payment_method"]),
            "device_type": normalize_text(raw["device_type"]),
            "declared_registration_count": _parse_nonnegative_integer(
                raw["declared_registration_count"]
            ),
        }
        row = {
            "cod_evento": event_code,
            "numero_pedido": source_row["numero_pedido"],
            **parsed,
            "is_paid": parsed["status"] == PAID_STATUS,
            "parsed_registration_count": participant_counts.get(order_key, 0),
        }
        rows.append(row)
        coverage_rows.append(
            {
                field: coverage_status(raw[field], parsed[field])
                for field in ORDER_JSON_FIELDS
            }
        )

    result = pd.DataFrame(rows, columns=_ORDER_COLUMNS)
    duplicates = result.duplicated(["cod_evento", "numero_pedido"], keep=False)
    if duplicates.any():
        raise ValueError(f"duplicate composite order keys: {int(duplicates.sum())}")
    result.attrs["field_status_counts"] = _status_counts(coverage_rows)
    return result


def _parse_registration_rows(source: pd.DataFrame) -> pd.DataFrame:
    """Parse safe registration attributes without retaining raw payloads or PII."""
    rows: list[dict[str, object]] = []
    for position, source_row in enumerate(source.to_dict("records")):
        body = parse_json_object(source_row["body"], row_position=position)

        raw_coupon_title = _coupon_value(body, "tituloCupom", "titulo")
        raw_coupon_code = _coupon_value(body, "codigoCupom", "codigo")
        raw_modality = body.get("modalidade")
        raw_lot = body.get("lote")
        raw_sale_date = _first_present(body, "dataVenda", "dataPedido")
        raw_registration_date = body.get("dataInscricao")
        raw_gross = body.get("valorUnitario")
        raw_fee = body.get("valorTaxa")
        raw_discount = body.get("valorDesconto")
        raw_coupon_discount = body.get("valorDescontoCupom")
        raw_net_transfer = body.get("valorRepasse")
        raw_country = body.get("pais")
        raw_state = _first_present(body, "estado", "uf")
        raw_city = body.get("cidade")
        raw_birth = _first_present(
            body, "nascimento", "dataNascimento", "data_nascimento"
        )
        raw_gender = _first_present(body, "sexo", "genero")
        raw_pace = _first_present(body, "ritmo", "pace")
        raw_club = _first_present(body, "nome_grupo", "clube", "assessoria")
        raw_questionnaire = body.get("questionario")
        raw_products_value = body.get("produtos")

        coupon_title = normalize_text(raw_coupon_title)
        coupon_code = normalize_text(raw_coupon_code)
        modality = normalize_modality(raw_modality)
        lot = normalize_lot(raw_lot)
        sale_date = parse_date(raw_sale_date)
        registration_date = parse_date(raw_registration_date)
        reported_gross = parse_decimal(raw_gross)
        reported_fee = parse_decimal(raw_fee)
        reported_discount = parse_decimal(raw_discount)
        reported_coupon_discount = parse_decimal(raw_coupon_discount)
        reported_net_transfer = parse_decimal(raw_net_transfer)
        country = normalize_country(raw_country)
        state = normalize_state(raw_state, raw_country)
        city = normalize_city(raw_city)
        age = age_on_event_date(raw_birth)
        gender = normalize_gender(raw_gender)
        pace_seconds = pace_to_seconds(raw_pace)
        club = normalize_text(raw_club)
        questionnaire_present = (
            None if raw_questionnaire is None else bool(raw_questionnaire)
        )
        raw_products = _sanitize_products(raw_products_value)

        row: dict[str, object] = {
            "cod_evento": _event_code(source_row["cod_evento"]),
            "numero_inscricao": source_row["numero_inscricao"],
            "numero_pedido": source_row["numero_pedido"],
            "coupon_title": coupon_title,
            "coupon_code": coupon_code,
            "modality": modality,
            "lot": lot,
            "sale_date": sale_date,
            "registration_date": registration_date,
            "reported_registration_gross_value": reported_gross,
            "reported_registration_fee_value": reported_fee,
            "reported_registration_discount_value": reported_discount,
            "reported_registration_coupon_discount_value": reported_coupon_discount,
            "reported_registration_net_transfer_value": reported_net_transfer,
            "country": country,
            "state": state,
            "city": city,
            "age": age,
            "gender": gender,
            "pace_seconds": pace_seconds,
            "club": club,
            "questionnaire_present": questionnaire_present,
            "raw_products": raw_products,
            "auxiliary_json_keys": sorted(body),
        }
        raw_and_parsed = {
            "coupon_title": (raw_coupon_title, coupon_title, False),
            "coupon_code": (raw_coupon_code, coupon_code, False),
            "modality": (raw_modality, modality, False),
            "lot": (raw_lot, lot, False),
            "sale_date": (raw_sale_date, sale_date, False),
            "registration_date": (raw_registration_date, registration_date, False),
            "reported_registration_gross_value": (raw_gross, reported_gross, False),
            "reported_registration_fee_value": (raw_fee, reported_fee, False),
            "reported_registration_discount_value": (
                raw_discount,
                reported_discount,
                False,
            ),
            "reported_registration_coupon_discount_value": (
                raw_coupon_discount,
                reported_coupon_discount,
                False,
            ),
            "reported_registration_net_transfer_value": (
                raw_net_transfer,
                reported_net_transfer,
                False,
            ),
            "country": (raw_country, country, False),
            "state": (raw_state, state, False),
            "city": (raw_city, city, False),
            "age": (raw_birth, age, False),
            "gender": (raw_gender, gender, gender == "Inválido"),
            "pace_seconds": (raw_pace, pace_seconds, False),
            "club": (raw_club, club, False),
            "questionnaire_present": (
                raw_questionnaire,
                questionnaire_present,
                False,
            ),
            "raw_products": (raw_products_value, raw_products, False),
        }
        for field, (raw_value, parsed_value, invalid) in raw_and_parsed.items():
            row[f"{field}_status"] = _field_status(
                raw_value, parsed_value, invalid=invalid
            )
        rows.append(row)

    return pd.DataFrame(rows)


def allocate_cents(total: Decimal, weights: list[Decimal]) -> list[Decimal]:
    """Allocate a total in cents with a stable largest-remainder tiebreaker."""
    if not weights:
        return []
    if total < 0:
        return [-value for value in allocate_cents(-total, weights)]
    if sum(weights, Decimal("0")) <= 0:
        weights = [Decimal("1")] * len(weights)
    weight_total = sum(weights, Decimal("0"))
    raw = [total * weight / weight_total for weight in weights]
    cents = [value.quantize(MONEY_QUANTUM, rounding=ROUND_DOWN) for value in raw]
    remainder = int((total - sum(cents, Decimal("0"))) * 100)
    largest = sorted(
        range(len(raw)), key=lambda index: raw[index] - cents[index], reverse=True
    )
    for index in largest[:remainder]:
        cents[index] += MONEY_QUANTUM
    return cents


def _allocate_covered_order_values(
    joined: pd.DataFrame,
    allocator: Callable[[Decimal, list[Decimal]], list[Decimal]],
) -> pd.DataFrame:
    """Allocate covered paid-order values without retaining repeated order money."""
    result = joined.copy()
    for allocated_column in _ORDER_MONEY_TO_ALLOCATED.values():
        result[allocated_column] = pd.Series([None] * len(result), dtype=object)
    result["allocation_method"] = pd.Series([None] * len(result), dtype=object)

    grouped = result.groupby(["cod_evento", "numero_pedido"], sort=False, dropna=False)
    for _, indices in grouped.groups.items():
        row_indices = list(indices)
        if not bool(result.loc[row_indices, "is_paid"].iloc[0]):
            continue
        weights = [
            value if isinstance(value, Decimal) and value > 0 else Decimal("0")
            for value in result.loc[
                row_indices, "reported_registration_gross_value"
            ].tolist()
        ]
        has_weights = sum(weights, Decimal("0")) > 0
        result.loc[row_indices, "allocation_method"] = (
            "reported_registration_gross_weights"
            if has_weights
            else "equal_missing_registration_prices"
        )
        if not has_weights:
            weights = [Decimal("1")] * len(row_indices)

        for order_column, allocated_column in _ORDER_MONEY_TO_ALLOCATED.items():
            total = result.loc[row_indices, order_column].iloc[0]
            if not isinstance(total, Decimal):
                continue
            allocated = allocator(total, weights)
            for row_index, value in zip(row_indices, allocated, strict=True):
                result.at[row_index, allocated_column] = value

    return result.drop(columns=list(_ORDER_MONEY_TO_ALLOCATED))


def build_registration_fact(bundle: SourceBundle, orders: pd.DataFrame) -> pd.DataFrame:
    """Return registration-grain rows linked by the full composite order key."""
    parsed = _parse_registration_rows(bundle.participants)
    joined = parsed.merge(
        orders,
        on=["cod_evento", "numero_pedido"],
        how="left",
        validate="many_to_one",
        suffixes=("", "_order"),
    )
    if joined.loc[
        joined["is_paid"].isna(), ["cod_evento", "numero_inscricao"]
    ].shape[0]:
        raise ValueError("paid registration join coverage is incomplete")
    return _allocate_covered_order_values(joined, allocate_cents)


def build_product_fact(registrations: pd.DataFrame) -> pd.DataFrame:
    """Explode safe product items without inferring revenue from names."""
    rows: list[dict[str, object]] = []
    for registration in registrations.to_dict("records"):
        for position, product in enumerate(registration.get("raw_products") or []):
            rows.append(
                {
                    "cod_evento": registration["cod_evento"],
                    "numero_inscricao": registration["numero_inscricao"],
                    "numero_pedido": registration["numero_pedido"],
                    "product_position": position,
                    "product_id": product.get("id") or product.get("codigo"),
                    "product_name": product.get("nome") or product.get("produto"),
                    "product_quantity": product.get("quantidade", 1),
                    "explicit_unit_value": parse_decimal(product.get("valorUnitario")),
                    "explicit_total_value": parse_decimal(product.get("valorTotal")),
                    "raw_product_keys": sorted(product),
                }
            )
    return pd.DataFrame(
        rows,
        columns=[
            "cod_evento",
            "numero_inscricao",
            "numero_pedido",
            "product_position",
            "product_id",
            "product_name",
            "product_quantity",
            "explicit_unit_value",
            "explicit_total_value",
            "raw_product_keys",
        ],
    )


def _status_counts(rows: list[dict[str, str]]) -> dict[str, dict[str, int]]:
    fields = {field for row in rows for field in row}
    return {
        field: {
            status: sum(row.get(field) == status for row in rows)
            for status in ("valido", "invalido", "nao_informado")
        }
        for field in sorted(fields)
    }


def _covered_decimal_sum(frame: pd.DataFrame, column: str) -> Decimal | None:
    values = [value for value in frame[column].tolist() if isinstance(value, Decimal)]
    return None if not values else sum(values, Decimal("0"))


def _decimal_string(value: Decimal | None) -> str | None:
    return None if value is None else str(value.quantize(MONEY_QUANTUM))


def _registration_field_coverage(
    registrations: pd.DataFrame,
) -> dict[str, dict[str, int]]:
    status_columns = [column for column in registrations if column.endswith("_status")]
    return {
        column.removesuffix("_status"): {
            status: int((registrations[column] == status).sum())
            for status in ("valido", "invalido", "nao_informado")
        }
        for column in status_columns
    }


def _reported_vs_allocated(
    registrations: pd.DataFrame,
) -> dict[str, dict[str, str | None]]:
    paid = registrations.loc[registrations["is_paid"]]
    result: dict[str, dict[str, str | None]] = {}
    for component, (reported_column, allocated_column) in _REPORTED_TO_ALLOCATED.items():
        reported = _covered_decimal_sum(paid, reported_column)
        allocated = _covered_decimal_sum(paid, allocated_column)
        difference = None if reported is None or allocated is None else reported - allocated
        result[component] = {
            "reported": _decimal_string(reported),
            "allocated": _decimal_string(allocated),
            "difference": _decimal_string(difference),
        }
    return result


def _build_reconciliation(
    bundle: SourceBundle, orders: pd.DataFrame, registrations: pd.DataFrame
) -> dict[str, Any]:
    paid_orders = orders.loc[orders["is_paid"]]
    paid_registrations = registrations.loc[registrations["is_paid"]]
    registration_groups = registrations.groupby(
        ["cod_evento", "numero_pedido"], dropna=False
    ).size()
    reconciliation: dict[str, Any] = {
        "source_order_rows": int(len(bundle.orders)),
        "source_registration_rows": int(len(bundle.participants)),
        "paid_order_count": int(len(paid_orders)),
        "paid_registration_count": int(len(paid_registrations)),
        "registration_join_coverage_pct": (
            100.0
            if len(bundle.participants) == 0
            else round(len(registrations) / len(bundle.participants) * 100, 2)
        ),
        "orders_with_multiple_registrations": int((registration_groups > 1).sum()),
        "unmatched_registration_count": int(registrations["is_paid"].isna().sum()),
        "invalid_json_count": 0,
        "order_field_coverage": orders.attrs.get("field_status_counts", {}),
        "registration_field_coverage": _registration_field_coverage(registrations),
        "reported_vs_allocated": _reported_vs_allocated(registrations),
    }
    for order_column, (order_key, allocated_key) in _RECONCILIATION_MONEY_KEYS.items():
        allocated_column = _ORDER_MONEY_TO_ALLOCATED[order_column]
        reconciliation[order_key] = _decimal_string(
            _covered_decimal_sum(paid_orders, order_column)
        )
        reconciliation[allocated_key] = _decimal_string(
            _covered_decimal_sum(paid_registrations, allocated_column)
        )
    return reconciliation


def build_fact_bundle(bundle: SourceBundle) -> FactBundle:
    """Build and reconcile the three fact tables for the configured event."""
    orders = build_order_fact(bundle)
    registrations = build_registration_fact(bundle, orders)
    products = build_product_fact(registrations)
    facts = FactBundle(
        orders=orders,
        registrations=registrations,
        products=products,
        reconciliation=_build_reconciliation(bundle, orders, registrations),
    )
    assert_reconciled(facts)
    return facts


def assert_reconciled(facts: FactBundle) -> None:
    """Fail closed on invalid grains, scope, joins, counts, or covered money."""
    if facts.orders.duplicated(["cod_evento", "numero_pedido"]).any():
        raise ValueError("duplicate order grain")
    if facts.registrations.duplicated(["cod_evento", "numero_inscricao"]).any():
        raise ValueError("duplicate registration grain")

    observed_event_codes = set(facts.orders["cod_evento"].dropna().astype(int))
    observed_event_codes.update(
        facts.registrations["cod_evento"].dropna().astype(int)
    )
    observed_event_codes.update(facts.products["cod_evento"].dropna().astype(int))
    if observed_event_codes != {EVENT_CODE}:
        raise ValueError("unexpected event code")

    for key in _RECONCILIATION_COUNT_KEYS:
        value = facts.reconciliation.get(key)
        if isinstance(value, (int, float)) and value < 0:
            raise ValueError(f"negative reconciliation count: {key}")

    if int(facts.reconciliation.get("unmatched_registration_count", 0)) > 0:
        raise ValueError("unmatched paid registrations")
    if facts.registrations["is_paid"].isna().any():
        raise ValueError("unmatched paid registrations")

    for order_column, (order_key, allocated_key) in _RECONCILIATION_MONEY_KEYS.items():
        left = facts.reconciliation.get(order_key)
        right = facts.reconciliation.get(allocated_key)
        if (left is None) != (right is None):
            raise ValueError(f"financial reconciliation failed: {order_key}")
        if left is not None and abs(Decimal(left) - Decimal(right)) > MONEY_QUANTUM:
            raise ValueError(f"financial reconciliation failed: {order_key}")

        allocated_column = _ORDER_MONEY_TO_ALLOCATED[order_column]
        for order in facts.orders.loc[facts.orders["is_paid"]].to_dict("records"):
            total = order[order_column]
            if not isinstance(total, Decimal):
                continue
            matching = facts.registrations.loc[
                (facts.registrations["cod_evento"] == order["cod_evento"])
                & (facts.registrations["numero_pedido"] == order["numero_pedido"])
                & facts.registrations["is_paid"]
            ]
            allocated = _covered_decimal_sum(matching, allocated_column)
            if allocated is None or abs(total - allocated) > MONEY_QUANTUM:
                raise ValueError(f"financial reconciliation failed: {order_key}")
