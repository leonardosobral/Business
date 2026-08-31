"""Deterministic evidence-first narratives for the MIF 2026 analysis."""

from __future__ import annotations

import math
from typing import Any

from .models import AnalysisResult


MECHANISM_POLICY_TEXT = (
    "mecanismo/política no cadastro, não presumido como parceiro comercial"
)
# Full dossiers are downstream of mappings loaded with ``require_reviewed=True``;
# their channel type is therefore the persisted classification evidence.
COMMERCIAL_CHANNEL_TYPES = frozenset({
    "parceiro",
    "influenciador",
    "assessoria",
    "comunidade",
    "campanha",
    "evento_acao",
})


def _number(value: Any) -> float | None:
    if value is None or isinstance(value, bool):
        return None
    try:
        parsed = float(value)
    except (TypeError, ValueError):
        return None
    return parsed if math.isfinite(parsed) else None


def _nonnegative_count(value: Any) -> int | None:
    parsed = _number(value)
    if parsed is None or parsed < 0 or not parsed.is_integer():
        return None
    return int(parsed)


def _positive_denominator(value: Any) -> int | None:
    parsed = _nonnegative_count(value)
    return parsed if parsed is not None and parsed > 0 else None


def _percentage(value: Any) -> float | None:
    parsed = _number(value)
    return parsed if parsed is not None and 0 <= parsed <= 100 else None


def _coverage_text(profile_coverage: dict[str, dict[str, Any]]) -> str:
    labels = {
        "age": "idade",
        "gender": "gênero",
        "pace": "ritmo",
        "club": "clube/assessoria",
    }
    parts = []
    for key in ("age", "gender", "pace", "club"):
        if key not in profile_coverage:
            continue
        coverage = profile_coverage.get(key, {})
        valid = _nonnegative_count(coverage.get("valid"))
        denominator = _positive_denominator(coverage.get("denominator"))
        percentage = _percentage(coverage.get("valid_coverage_pct"))
        if (
            valid is None
            or denominator is None
            or valid > denominator
            or percentage is None
        ):
            parts.append(f"{labels[key]} não disponível")
            continue
        parts.append(
            f"{labels[key]} {percentage:.2f}% ({valid}/{denominator} válidos)"
        )
    return "; ".join(parts) or "não disponível"


def _alias_text(aliases: list[dict[str, Any]]) -> str:
    if not aliases:
        return "nenhum alias informado"
    values = []
    for alias in aliases:
        title = alias.get("coupon_title")
        code = alias.get("coupon_code")
        identity = " / ".join(str(value) for value in (title, code) if value)
        count = _nonnegative_count(alias.get("paid_registrations"))
        count_text = f"{count} inscrições" if count is not None else "base não disponível"
        values.append(f"{identity or 'sem título/código'} ({count_text})")
    return "; ".join(values)


def describe_channel(
    dossier: dict[str, Any], event_overview: dict[str, Any]
) -> str:
    """Describe one full channel dossier without a score or automated advice."""
    paid_registrations = int(dossier["paid_registrations"])
    touched_orders = int(dossier["touched_paid_orders"])
    event_registrations = _positive_denominator(
        event_overview.get("paid_registrations")
    )
    event_share = _percentage(dossier.get("share_of_event_registrations"))
    modality = dossier.get("modality_mix", [])
    leading_modality = modality[0] if modality else {}
    lots = dossier.get("lot_mix", [])
    leading_lot = lots[0] if lots else {}
    weeks = dossier.get("weekly_sales", [])
    peak_week = max(
        weeks,
        key=lambda row: int(row.get("paid_registrations", 0)),
        default={},
    )
    geography = dossier.get("geographic_scope", {})
    add_ons = [
        row
        for row in dossier.get("product_mix", [])
        if row.get("classification") == "adicional"
    ]
    add_on = add_ons[0] if add_ons else {}
    add_on_coverage = add_on.get("coverage", {})
    limitations = "; ".join(dossier.get("data_limitations", []))
    if not limitations:
        limitations = "nenhuma limitação adicional identificada"

    mechanism_note = ""
    if (
        str(dossier.get("channel_name")) in {"PCD", "Benefício"}
        and dossier.get("channel_type") not in COMMERCIAL_CHANNEL_TYPES
    ):
        mechanism_note = f" Classificação: {MECHANISM_POLICY_TEXT}."

    share_text = "Participação no evento: não disponível."
    if event_registrations is not None and event_share is not None:
        share_text = (
            f"Participação no evento: {event_share:.2f}% da base de "
            f"{event_registrations} inscrições."
        )

    registration_ticket = dossier.get("registration_ticket")
    ticket_text = "Ticket médio ponderado por inscrição: não disponível."
    if registration_ticket is not None and paid_registrations > 0:
        ticket_text = (
            f"O ticket médio ponderado por inscrição foi R$ {registration_ticket}, "
            f"na base de {paid_registrations} inscrições."
        )

    modality_count = _nonnegative_count(leading_modality.get("paid_registrations"))
    modality_denominator = _positive_denominator(leading_modality.get("denominator"))
    modality_share = _percentage(leading_modality.get("share_pct"))
    modality_text = "Mix de modalidade: não disponível."
    if (
        leading_modality.get("modality")
        and modality_count is not None
        and modality_denominator is not None
        and modality_count <= modality_denominator
        and modality_share is not None
    ):
        modality_text = (
            f"Mix de modalidade: {leading_modality['modality']} liderou com "
            f"{modality_count}/{modality_denominator} ({modality_share:.2f}%)."
        )

    geography_coverage = geography.get("coverage", {})
    geography_available = (
        geography.get("label") is not None
        and _nonnegative_count(geography.get("states")) is not None
        and _nonnegative_count(geography.get("cities")) is not None
        and _number(geography.get("city_concentration_hhi")) is not None
        and _percentage(geography.get("leading_city_pct")) is not None
        and _positive_denominator(
            geography_coverage.get("state", {}).get("denominator")
        )
        is not None
        and _percentage(
            geography_coverage.get("state", {}).get("valid_coverage_pct")
        )
        is not None
        and _positive_denominator(
            geography_coverage.get("city", {}).get("denominator")
        )
        is not None
        and _percentage(
            geography_coverage.get("city", {}).get("valid_coverage_pct")
        )
        is not None
    )
    geography_text = "Abrangência e concentração: não disponível."
    if geography_available:
        geography_text = (
            f"A abrangência observada foi {geography['label']}, com "
            f"{int(geography['states'])} UFs e {int(geography['cities'])} cidades; "
            f"a concentração foi HHI {float(geography['city_concentration_hhi']):.4f} "
            f"por cidade e {float(geography['leading_city_pct']):.2f}% na principal cidade."
        )

    lot_count = _nonnegative_count(leading_lot.get("paid_registrations"))
    lot_denominator = _positive_denominator(leading_lot.get("denominator"))
    lot_text = "Recorte de lote: não disponível."
    if (
        leading_lot.get("lot")
        and lot_count is not None
        and lot_denominator is not None
        and lot_count <= lot_denominator
    ):
        lot_text = (
            f"No recorte de lote, {leading_lot['lot']} reuniu "
            f"{lot_count}/{lot_denominator} inscrições."
        )

    peak_week_count = _nonnegative_count(peak_week.get("paid_registrations"))
    week_text = "Pico semanal: não disponível."
    if peak_week.get("week_start") and peak_week_count is not None:
        week_text = (
            f"O pico semanal observado começou em {peak_week['week_start']} "
            f"com {peak_week_count} inscrições."
        )

    add_on_count = _nonnegative_count(add_on.get("registrations_with_product"))
    add_on_denominator = _positive_denominator(add_on.get("take_rate_denominator"))
    add_on_rate = _percentage(add_on.get("take_rate_pct"))
    mapping_coverage = _percentage(
        add_on_coverage.get("product_mapping_coverage_pct")
    )
    add_on_text = "Adoção de adicional: não disponível."
    if (
        add_on.get("product_name")
        and add_on_count is not None
        and add_on_denominator is not None
        and add_on_count <= add_on_denominator
        and add_on_rate is not None
        and mapping_coverage is not None
    ):
        add_on_text = (
            f"Adoção de adicional: {add_on['product_name']} em "
            f"{add_on_count}/{add_on_denominator} inscrições ({add_on_rate:.2f}%), "
            f"com cobertura de mapeamento de {mapping_coverage:.2f}%."
        )

    return (
        f"{dossier['channel_name']} registrou {paid_registrations} inscrições pagas em "
        f"{touched_orders} pedidos tocados, não aditivos entre canais. {share_text} "
        f"{ticket_text} {modality_text} {geography_text} {lot_text} {week_text} "
        f"{add_on_text} Cobertura de perfil: "
        f"{_coverage_text(dossier.get('profile_coverage', {}))}. "
        f"Aliases de origem: {_alias_text(dossier.get('coupon_aliases', []))}."
        f"{mechanism_note} Limitações de leitura: {limitations}."
    )


def describe_event(result: AnalysisResult) -> str:
    """Describe event commerce with explicit grains, bases, and limitations."""
    overview = result.overview
    orders = _nonnegative_count(overview.get("paid_orders"))
    registrations = _nonnegative_count(overview.get("paid_registrations"))
    coverage = overview.get("source_field_coverage", {})
    channel_coverage = _percentage(coverage.get("channel_mapping_coverage_pct"))
    product_coverage = _percentage(coverage.get("product_mapping_coverage_pct"))
    channel_coverage_text = (
        f"{float(channel_coverage):.2f}%"
        if channel_coverage is not None
        else "não disponível"
    )
    product_coverage_text = (
        f"{float(product_coverage):.2f}%"
        if product_coverage is not None
        else "não disponível"
    )
    external = result.source_notes.get("external_considerations", {})
    external_text = "; ".join(
        f"{key} {value}" for key, value in external.items()
    ) or "considerações externas sem fonte identificada"

    if orders is not None and registrations is not None:
        grains_text = (
            f"Grãos: o evento contém {orders} pedidos pagos únicos e "
            f"{registrations} inscrições pagas;"
        )
    else:
        orders_text = str(orders) if orders is not None else "não disponível"
        registrations_text = (
            str(registrations) if registrations is not None else "não disponível"
        )
        grains_text = (
            f"Grãos: pedidos pagos únicos: {orders_text}; "
            f"inscrições pagas: {registrations_text};"
        )

    order_ticket = overview.get("order_ticket")
    order_ticket_text = "O ticket médio ponderado de pedido: não disponível."
    if order_ticket is not None and orders is not None and orders > 0:
        order_ticket_text = (
            f"O ticket médio ponderado de pedido foi R$ {order_ticket} "
            f"na base de {orders} pedidos."
        )

    registration_ticket = overview.get("registration_ticket")
    registration_ticket_text = (
        "O ticket médio ponderado de inscrição: não disponível."
    )
    if (
        registration_ticket is not None
        and registrations is not None
        and registrations > 0
    ):
        registration_ticket_text = (
            f"O ticket médio ponderado de inscrição foi R$ {registration_ticket} "
            f"na base de {registrations} inscrições."
        )

    return (
        f"{grains_text} "
        f"pedidos tocados não são aditivos entre canais, pois um pedido pode conter inscrições "
        f"atribuídas a canais diferentes. {order_ticket_text} "
        f"{registration_ticket_text} Coberturas de fonte: canais {channel_coverage_text}; "
        f"produtos {product_coverage_text}; os percentuais de perfil são apresentados com seus "
        f"denominadores nos dossiês. As comparações permanecem separadas por dimensão e só são "
        f"interpretáveis com bases e coberturas explícitas. Limitações de leitura: "
        f"{external_text}."
    )


def build_decision_questions(result: AnalysisResult) -> list[str]:
    """Return evidence-grounded questions reserved for human commercial judgment."""
    overlap_dimensions = [
        dataset_id.removesuffix("_overlap")
        for dataset_id, rows in result.datasets.items()
        if dataset_id.endswith("_overlap") and rows
    ]
    dimensions = ", ".join(overlap_dimensions) or "as dimensões disponíveis"
    return [
        "Quais canais cobrem estados ou modalidades pouco atendidos pelos demais?",
        (
            f"Quais pares apresentam público semelhante em {dimensions} "
            "e merecem revisão contratual conjunta?"
        ),
        "Onde a concentração regional é intencional e onde ela limita alcance?",
        (
            "Quais canais têm mix de modalidade ou adicional realmente distinto, "
            "com cobertura suficiente para sustentar a leitura?"
        ),
    ]
