"""Compact, decision-ready crossings for the closed MIF 2026 sales cycle."""

from __future__ import annotations

from collections import defaultdict
from copy import deepcopy
from decimal import Decimal, InvalidOperation
from typing import Any, Iterable

from .phases import PHASE_ORDER


MODALITY_ORDER = ("42K", "21K", "DESAFIO", "5K", "KIDS")
EARLY_PHASES = {"Lançamento", "Início"}
LATE_PHASES = {"Reta final", "Encerramento"}
NON_COMMERCIAL_TYPES = {"organico", "campanha", "cortesia", "politica"}
RECOMMENDATION_ORDER = (
    "Priorizar",
    "Manter com função definida",
    "Testar ou renegociar",
)
STRATEGY_TRANSFORM_VERSION = "mif-2026-strategy.1"


def _count(row: dict[str, Any], key: str = "paid_registrations") -> int:
    return int(row.get(key, 0) or 0)


def _money(value: object) -> Decimal:
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return Decimal("0.00")
    return parsed if parsed.is_finite() else Decimal("0.00")


def _pct(numerator: int | Decimal, denominator: int | Decimal) -> float:
    if not denominator:
        return 0.0
    return round(float(numerator / denominator * 100), 2)


def _ordered_value(value: str, preferred: Iterable[str]) -> tuple[int, str]:
    order = list(preferred)
    try:
        return order.index(value), value.casefold()
    except ValueError:
        return len(order), value.casefold()


def _group_counts(
    rows: list[dict[str, Any]],
    dimensions: tuple[str, ...],
    *,
    value_key: str = "paid_registrations",
) -> dict[tuple[str, ...], int]:
    grouped: dict[tuple[str, ...], int] = defaultdict(int)
    for row in rows:
        key = tuple(str(row.get(dimension) or "Não informado") for dimension in dimensions)
        grouped[key] += _count(row, value_key)
    return dict(grouped)


def _leader(
    grouped: dict[tuple[str, ...], int],
    prefix: str,
    position: int,
    *,
    excluded: set[str] | None = None,
) -> tuple[str, int]:
    candidates = [
        (key[position], value)
        for key, value in grouped.items()
        if key[0] == prefix and key[position] not in (excluded or set())
    ]
    return max(candidates, key=lambda item: (item[1], item[0]), default=("—", 0))


def _two_way_rows(
    grouped: dict[tuple[str, str], int],
    first_key: str,
    second_key: str,
    share_key: str,
    *,
    first_order: Iterable[str] = (),
    second_order: Iterable[str] = (),
) -> list[dict[str, Any]]:
    totals: dict[str, int] = defaultdict(int)
    for (first, _), value in grouped.items():
        totals[first] += value
    ordered = sorted(
        grouped.items(),
        key=lambda item: (
            _ordered_value(item[0][0], first_order),
            _ordered_value(item[0][1], second_order),
        ),
    )
    return [
        {
            first_key: first,
            second_key: second,
            "paid_registrations": value,
            f"{first_key}_total": totals[first],
            share_key: _pct(value, totals[first]),
        }
        for (first, second), value in ordered
    ]


def _top_dimension_with_other(
    grouped: dict[tuple[str, str], int],
    *,
    limit: int = 10,
    missing_label: str = "Não informado",
) -> dict[tuple[str, str], int]:
    totals: dict[str, int] = defaultdict(int)
    for (first, _), value in grouped.items():
        if first != missing_label:
            totals[first] += value
    top = {
        label
        for label, _ in sorted(
            totals.items(), key=lambda item: (-item[1], item[0].casefold())
        )[:limit]
    }
    projected: dict[tuple[str, str], int] = defaultdict(int)
    for (first, second), value in grouped.items():
        if first == missing_label:
            continue
        projected[(first if first in top else "Outros", second)] += value
    return dict(projected)


def _additional_product_rows(
    product_cube: list[dict[str, Any]], dimension: str
) -> list[dict[str, Any]]:
    additional = [
        row
        for row in product_cube
        if str(row.get("classification", "")).casefold() == "adicional"
    ]
    grouped = _group_counts(
        additional,
        (dimension, "product_name"),
        value_key="registrations_with_product",
    )
    return [
        {
            dimension: first,
            "product_name": product,
            "registrations_with_product": value,
        }
        for (first, product), value in sorted(
            grouped.items(),
            key=lambda item: (
                _ordered_value(item[0][0], MODALITY_ORDER if dimension == "modality" else PHASE_ORDER),
                -item[1],
                item[0][1].casefold(),
            ),
        )
    ]


def _with_take_rates(
    rows: list[dict[str, Any]],
    dimension: str,
    registration_cube: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    totals = _group_counts(registration_cube, (dimension,))
    enriched = []
    for row in rows:
        denominator = totals.get((str(row[dimension]),), 0)
        enriched.append(
            {
                **row,
                "take_rate_denominator": denominator,
                "take_rate_pct": _pct(
                    int(row["registrations_with_product"]), denominator
                ),
            }
        )
    return enriched


def _channel_portfolio(
    channel_index: list[dict[str, Any]], overview: dict[str, Any]
) -> dict[str, Any]:
    gross_total = _money(overview.get("gross_value"))
    ordered = sorted(
        channel_index,
        key=lambda row: (
            -_money(row.get("gross_value")),
            -_count(row),
            str(row.get("channel_name", "")).casefold(),
        ),
    )
    grouped: dict[str, dict[str, Any]] = {}
    for row in ordered:
        category = str(
            (row.get("recommendation") or {}).get("category")
            or "Sem classificação"
        )
        target = grouped.setdefault(
            category,
            {
                "category": category,
                "channels": 0,
                "paid_registrations": 0,
                "gross_value": Decimal("0.00"),
            },
        )
        target["channels"] += 1
        target["paid_registrations"] += _count(row)
        target["gross_value"] += _money(row.get("gross_value"))

    recommendation_groups = []
    for category in sorted(
        grouped,
        key=lambda value: _ordered_value(value, RECOMMENDATION_ORDER),
    ):
        row = grouped[category]
        recommendation_groups.append(
            {
                "category": category,
                "channels": row["channels"],
                "paid_registrations": row["paid_registrations"],
                "gross_value": format(row["gross_value"], ".2f"),
                "gross_share_pct": _pct(row["gross_value"], gross_total),
            }
        )

    def top_share(size: int) -> float:
        return _pct(
            sum((_money(row.get("gross_value")) for row in ordered[:size]), Decimal("0.00")),
            gross_total,
        )

    return {
        "channels": len(ordered),
        "top_1_gross_share_pct": top_share(1),
        "top_2_gross_share_pct": top_share(2),
        "top_3_gross_share_pct": top_share(3),
        "top_10_gross_share_pct": top_share(10),
        "recommendation_groups": recommendation_groups,
    }


def _distance_playbook(
    registration_cube: list[dict[str, Any]],
    channel_index: list[dict[str, Any]],
    total: int,
) -> list[dict[str, Any]]:
    modality_totals = _group_counts(registration_cube, ("modality",))
    by_phase = _group_counts(registration_cube, ("modality", "phase"))
    by_lot = _group_counts(registration_cube, ("modality", "lot"))
    by_state = _group_counts(registration_cube, ("modality", "state"))
    by_channel = _group_counts(registration_cube, ("modality", "channel_name"))
    channel_types = {
        str(row.get("channel_name")): str(row.get("channel_type", ""))
        for row in channel_index
    }
    commercial_names = {
        name
        for name, channel_type in channel_types.items()
        if channel_type.casefold() not in NON_COMMERCIAL_TYPES
    }
    channel_totals = _group_counts(registration_cube, ("channel_name",))
    rows = []
    for (modality,), modality_total in sorted(
        modality_totals.items(),
        key=lambda item: _ordered_value(item[0][0], MODALITY_ORDER),
    ):
        peak_phase, _ = _leader(by_phase, modality, 1)
        lead_lot, _ = _leader(by_lot, modality, 1)
        lead_state, _ = _leader(
            by_state, modality, 1, excluded={"Não informado"}
        )
        commercial_cells = [
            (channel_name, value)
            for (cell_modality, channel_name), value in by_channel.items()
            if cell_modality == modality and channel_name in commercial_names
        ]
        volume_channel, _ = max(
            commercial_cells,
            key=lambda item: (item[1], item[0]),
            default=("—", 0),
        )
        event_share = modality_total / total if total else 0
        specialists = []
        for channel_name, cell in commercial_cells:
            channel_total = channel_totals.get((channel_name,), 0)
            if channel_total < 30 or cell < 10 or not event_share:
                continue
            index = (cell / channel_total) / event_share * 100
            specialists.append((channel_name, index, cell, channel_total))
        specialist = max(
            specialists,
            key=lambda item: (item[1], item[2], item[0]),
            default=("—", 0.0, 0, 0),
        )
        rows.append(
            {
                "modality": modality,
                "paid_registrations": modality_total,
                "event_share_pct": _pct(modality_total, total),
                "peak_phase": peak_phase,
                "lead_lot": lead_lot,
                "lead_state": lead_state,
                "volume_channel": volume_channel,
                "specialist_channel": specialist[0],
                "specialist_index": round(specialist[1], 1),
                "specialist_cell": specialist[2],
            }
        )
    return rows


def _state_timing(registration_cube: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped = _group_counts(registration_cube, ("state", "phase"))
    totals: dict[str, int] = defaultdict(int)
    for (state, _), value in grouped.items():
        if state != "Não informado":
            totals[state] += value
    states = sorted(totals, key=lambda state: (-totals[state], state.casefold()))[:10]
    rows = []
    for state in states:
        phase_cells = {
            phase: grouped.get((state, phase), 0) for phase in PHASE_ORDER
        }
        peak_phase = max(
            PHASE_ORDER,
            key=lambda phase: (phase_cells[phase], -PHASE_ORDER.index(phase)),
        )
        rows.append(
            {
                "state": state,
                "paid_registrations": totals[state],
                "peak_phase": peak_phase,
                "early_share_pct": _pct(
                    sum(phase_cells[phase] for phase in EARLY_PHASES), totals[state]
                ),
                "late_share_pct": _pct(
                    sum(phase_cells[phase] for phase in LATE_PHASES), totals[state]
                ),
            }
        )
    return rows


def _phase_playbook(
    registration_cube: list[dict[str, Any]],
    channel_index: list[dict[str, Any]],
    total: int,
) -> list[dict[str, Any]]:
    phase_totals = _group_counts(registration_cube, ("phase",))
    dimensions = {
        "lead_modality": _group_counts(registration_cube, ("phase", "modality")),
        "lead_lot": _group_counts(registration_cube, ("phase", "lot")),
        "lead_state": _group_counts(registration_cube, ("phase", "state")),
        "lead_channel": _group_counts(registration_cube, ("phase", "channel_name")),
    }
    channel_types = {
        str(row.get("channel_name")): str(row.get("channel_type", ""))
        for row in channel_index
    }
    excluded_channels = {
        name
        for name, channel_type in channel_types.items()
        if channel_type.casefold() in NON_COMMERCIAL_TYPES
    }
    rows = []
    for phase in PHASE_ORDER:
        phase_total = phase_totals.get((phase,), 0)
        if not phase_total:
            continue
        modality, modality_count = _leader(dimensions["lead_modality"], phase, 1)
        lot, _ = _leader(dimensions["lead_lot"], phase, 1)
        state, _ = _leader(
            dimensions["lead_state"], phase, 1, excluded={"Não informado"}
        )
        channel, _ = _leader(
            dimensions["lead_channel"], phase, 1, excluded=excluded_channels
        )
        rows.append(
            {
                "phase": phase,
                "paid_registrations": phase_total,
                "event_share_pct": _pct(phase_total, total),
                "lead_modality": modality,
                "lead_modality_share_pct": _pct(modality_count, phase_total),
                "lead_lot": lot,
                "lead_state": state,
                "lead_channel": channel,
            }
        )
    return rows


def _product_opportunities(
    product_modality: list[dict[str, Any]],
    registration_cube: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    modality_totals = _group_counts(registration_cube, ("modality",))
    rows = []
    for (modality,), total in sorted(
        modality_totals.items(),
        key=lambda item: _ordered_value(item[0][0], MODALITY_ORDER),
    ):
        products = [
            row for row in product_modality if row["modality"] == modality
        ]
        if not products:
            continue
        leading = products[0]
        rows.append(
            {
                "modality": modality,
                "paid_registrations": total,
                "leading_product": leading["product_name"],
                "leading_product_registrations": leading["registrations_with_product"],
                "leading_product_take_rate_pct": _pct(
                    leading["registrations_with_product"], total
                ),
                "top_additional_products": [
                    {
                        "product_name": row["product_name"],
                        "registrations_with_product": row["registrations_with_product"],
                        "take_rate_pct": _pct(
                            row["registrations_with_product"], total
                        ),
                    }
                    for row in products[:3]
                ],
            }
        )
    return rows


def _pt_pct(value: float) -> str:
    return f"{value:.2f}".replace(".", ",") + "%"


def _executive_takeaways(
    phase_playbook: list[dict[str, Any]],
    state_timing: list[dict[str, Any]],
    portfolio: dict[str, Any],
    product_opportunities: list[dict[str, Any]],
) -> list[dict[str, str]]:
    closing = next(
        (row for row in phase_playbook if row["phase"] == "Encerramento"),
        phase_playbook[-1] if phase_playbook else {},
    )
    late_state = max(
        state_timing,
        key=lambda row: (row["late_share_pct"], row["paid_registrations"]),
        default={},
    )
    product_totals: dict[str, int] = defaultdict(int)
    for opportunity in product_opportunities:
        for product in opportunity["top_additional_products"]:
            product_totals[product["product_name"]] += product["registrations_with_product"]
    leading_product, leading_product_count = max(
        product_totals.items(),
        key=lambda item: (item[1], item[0]),
        default=("sem adicional mapeado", 0),
    )
    leading_product_distance = next(
        (
            row["modality"]
            for row in product_opportunities
            if any(
                product["product_name"] == leading_product
                for product in row["top_additional_products"]
            )
        ),
        "—",
    )
    return [
        {
            "title": "O ciclo muda de produto no encerramento",
            "evidence": (
                f"No {closing.get('phase', 'encerramento')}, {closing.get('lead_modality', '—')} "
                f"lidera com {_pt_pct(float(closing.get('lead_modality_share_pct', 0)))} "
                f"das {int(closing.get('paid_registrations', 0))} inscrições da fase."
            ),
            "implication": "Planejar criativos, urgência e oferta de distância por fase; não repetir o mesmo mix durante todo o ciclo.",
        },
        {
            "title": "Estados pedem calendários diferentes",
            "evidence": (
                f"{late_state.get('state', '—')} concentra {_pt_pct(float(late_state.get('late_share_pct', 0)))} "
                f"das próprias vendas na reta final e no encerramento; o pico observado é {late_state.get('peak_phase', '—')}."
            ),
            "implication": "Antecipar mercados que compram no meio e reservar pressão local para os estados com fechamento tardio.",
        },
        {
            "title": "O portfólio já é concentrado; o ganho está na função",
            "evidence": (
                f"Os dois maiores canais respondem por {_pt_pct(float(portfolio.get('top_2_gross_share_pct', 0)))} "
                f"do valor bruto; os dez maiores, por {_pt_pct(float(portfolio.get('top_10_gross_share_pct', 0)))}."
            ),
            "implication": "Reduzir redundância na cauda e preservar canais que tragam território, distância ou timing realmente distintos.",
        },
        {
            "title": "Produto adicional deve ser ofertado por distância",
            "evidence": (
                f"{leading_product} aparece em {leading_product_count} vínculos nos líderes por distância, "
                f"com maior oportunidade observada a partir de {leading_product_distance}."
            ),
            "implication": "Usar ofertas adicionais específicas por prova; itens se sobrepõem e suas taxas não devem ser somadas.",
        },
    ]


def build_strategy(
    *,
    overview: dict[str, Any],
    summary_datasets: dict[str, list[dict[str, Any]]],
    registration_cube: list[dict[str, Any]],
    product_cube: list[dict[str, Any]],
    channel_index: list[dict[str, Any]],
) -> dict[str, Any]:
    """Return compact static crossings and playbooks without detailed cubes."""
    total = sum(_count(row) for row in registration_cube)
    expected = _count(overview)
    if total != expected:
        raise ValueError(
            f"strategy registration total {total} does not reconcile to overview {expected}"
        )

    phase_modality_grouped = _group_counts(
        registration_cube, ("phase", "modality")
    )
    phase_lot_grouped = _group_counts(registration_cube, ("phase", "lot"))
    lot_modality_grouped = _group_counts(registration_cube, ("lot", "modality"))
    state_modality_grouped = _top_dimension_with_other(
        _group_counts(registration_cube, ("state", "modality"))
    )
    state_phase_grouped = _top_dimension_with_other(
        _group_counts(registration_cube, ("state", "phase"))
    )
    channel_modality_grouped = _top_dimension_with_other(
        _group_counts(registration_cube, ("channel_name", "modality")),
        missing_label="",
    )

    product_modality = _with_take_rates(
        _additional_product_rows(product_cube, "modality"),
        "modality",
        registration_cube,
    )
    product_phase = _with_take_rates(
        _additional_product_rows(product_cube, "phase"),
        "phase",
        registration_cube,
    )
    product_lot = _with_take_rates(
        _additional_product_rows(product_cube, "lot"),
        "lot",
        registration_cube,
    )
    datasets = {
        **deepcopy(summary_datasets),
        "phase_modality": _two_way_rows(
            phase_modality_grouped,
            "phase",
            "modality",
            "within_phase_share_pct",
            first_order=PHASE_ORDER,
            second_order=MODALITY_ORDER,
        ),
        "phase_lot": _two_way_rows(
            phase_lot_grouped,
            "phase",
            "lot",
            "within_phase_share_pct",
            first_order=PHASE_ORDER,
        ),
        "lot_modality": _two_way_rows(
            lot_modality_grouped,
            "lot",
            "modality",
            "within_lot_share_pct",
            second_order=MODALITY_ORDER,
        ),
        "state_modality": _two_way_rows(
            state_modality_grouped,
            "state",
            "modality",
            "within_state_share_pct",
            second_order=MODALITY_ORDER,
        ),
        "state_phase": _two_way_rows(
            state_phase_grouped,
            "state",
            "phase",
            "within_state_share_pct",
            second_order=PHASE_ORDER,
        ),
        "channel_modality": _two_way_rows(
            channel_modality_grouped,
            "channel_name",
            "modality",
            "within_channel_share_pct",
            second_order=MODALITY_ORDER,
        ),
        "product_modality_additional": product_modality,
        "product_phase_additional": product_phase,
        "product_lot_additional": product_lot,
    }
    portfolio = _channel_portfolio(channel_index, overview)
    distance_playbook = _distance_playbook(
        registration_cube, channel_index, total
    )
    phase_playbook = _phase_playbook(registration_cube, channel_index, total)
    state_timing = _state_timing(registration_cube)
    product_opportunities = _product_opportunities(
        product_modality, registration_cube
    )
    executive_takeaways = _executive_takeaways(
        phase_playbook, state_timing, portfolio, product_opportunities
    )

    return {
        "transform_version": STRATEGY_TRANSFORM_VERSION,
        "definitions": {
            "phase_order": list(PHASE_ORDER),
            "modality_order": list(MODALITY_ORDER),
            "chart_tail_rule": "Top 10 + Outros somente para categorias exclusivas.",
            "product_tail_rule": "Produtos são sobrepostos; o visual limita ao Top 10 sem somar Outros.",
            "specialist_minimums": {"channel_registrations": 30, "cell_registrations": 10},
        },
        "datasets": datasets,
        "insights": {
            "executive_takeaways": executive_takeaways,
            "phase_playbook": phase_playbook,
            "distance_playbook": distance_playbook,
            "state_timing": state_timing,
            "channel_portfolio": portfolio,
            "product_opportunities": product_opportunities,
        },
        "caveats": [
            "Fase comercial e lote são colineares neste ciclo: a leitura descreve a combinação observada, mas não separa causalmente efeito de tempo e efeito de preço.",
            "Produtos não são categorias mutuamente exclusivas; taxas de adoção devem ser lidas item a item e nunca somadas entre produtos.",
            "Cruzamentos são descritivos e não demonstram causalidade; células pequenas qualificam especialistas como hipótese.",
        ],
    }
