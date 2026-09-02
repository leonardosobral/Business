"""Deterministic evidence-first narratives for the MIF 2026 analysis."""

from __future__ import annotations

import math
from datetime import date
from typing import Any

from .config import SMALL_CELL_MIN_REGISTRATIONS
from .models import AnalysisResult
from .normalize import normalize_key


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


def _pt_number(value: Any, decimals: int = 2) -> str:
    parsed = _number(value)
    if parsed is None:
        raise ValueError("number is unavailable")
    rendered = f"{parsed:,.{decimals}f}"
    return rendered.replace(",", "\u0000").replace(".", ",").replace("\u0000", ".")


def _pt_count(value: Any) -> str | None:
    parsed = _nonnegative_count(value)
    return None if parsed is None else f"{parsed:,}".replace(",", ".")


def _count_phrase(value: Any, singular: str, plural: str) -> str | None:
    parsed = _nonnegative_count(value)
    rendered = _pt_count(parsed)
    if parsed is None or rendered is None:
        return None
    return f"{rendered} {singular if parsed == 1 else plural}"


def _pt_date(value: Any) -> str | None:
    months = (
        "jan.", "fev.", "mar.", "abr.", "mai.", "jun.",
        "jul.", "ago.", "set.", "out.", "nov.", "dez.",
    )
    try:
        parsed = date.fromisoformat(str(value))
    except (TypeError, ValueError):
        return None
    return f"{parsed.day} {months[parsed.month - 1]} {parsed.year}"


def _money_text(value: Any) -> str | None:
    parsed = _number(value)
    return None if parsed is None else f"R$ {_pt_number(parsed)}"


def _signed(value: Any, suffix: str) -> str | None:
    parsed = _number(value)
    if parsed is None:
        return None
    return f"{parsed:+.2f}".replace(".", ",") + suffix


def _lot_label(value: Any) -> str:
    label = str(value or "").strip()
    if not label or label.casefold() in {"não informado", "invalido", "inválido", "—"}:
        return label or "Não informado"
    return label if label.casefold().startswith("lote ") else f"Lote {label}"


def _complete_delta(
    rows: list[dict[str, Any]], segment: object
) -> dict[str, Any] | None:
    for row in rows:
        if str(row.get("segment")) != str(segment):
            continue
        channel_count = _nonnegative_count(row.get("channel_count"))
        channel_base = _positive_denominator(row.get("channel_denominator"))
        event_count = _nonnegative_count(row.get("event_count"))
        event_base = _positive_denominator(row.get("event_denominator"))
        delta = _number(row.get("delta_pp"))
        if (
            channel_count is not None
            and channel_base is not None
            and channel_count <= channel_base
            and event_count is not None
            and event_base is not None
            and event_count <= event_base
            and delta is not None
        ):
            return row
    return None


def _valid_distribution_row(
    row: dict[str, Any], segment_key: str
) -> tuple[str, int, int, float] | None:
    segment = row.get(segment_key)
    count = _nonnegative_count(row.get("paid_registrations"))
    denominator = _positive_denominator(row.get("denominator"))
    share = _percentage(row.get("share_pct"))
    if (
        segment in {None, "Não informado", "Inválido"}
        or count is None
        or denominator is None
        or count > denominator
        or share is None
    ):
        return None
    return str(segment), count, denominator, share


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
            f"{labels[key]} {_pt_number(percentage)}% ({_pt_count(valid)}/{_pt_count(denominator)} válidos)"
        )
    return "; ".join(parts) or "não disponível"


def _alias_text(aliases: list[dict[str, Any]]) -> str:
    if not aliases:
        return "nenhum alias informado"
    ranked = sorted(
        aliases,
        key=lambda alias: (
            -(_nonnegative_count(alias.get("paid_registrations")) or 0),
            normalize_key(alias.get("coupon_title")).casefold(),
            normalize_key(alias.get("coupon_code")).casefold(),
            str(alias.get("coupon_title") or "").casefold(),
            str(alias.get("coupon_code") or "").casefold(),
        ),
    )
    values = []
    for alias in ranked[:3]:
        title = alias.get("coupon_title")
        code = alias.get("coupon_code")
        identity = " / ".join(str(value) for value in (title, code) if value)
        count = _nonnegative_count(alias.get("paid_registrations"))
        count_text = (
            _count_phrase(count, "inscrição", "inscrições")
            if count is not None
            else "base não disponível"
        )
        values.append(f"{identity or 'sem título/código'} ({count_text})")
    if len(ranked) <= 3:
        return "; ".join(values)
    remaining = len(ranked) - 3
    remaining_text = _count_phrase(remaining, "identidade", "identidades")
    return (
        f"{_count_phrase(len(ranked), 'identidade', 'identidades')}: "
        f"{'; '.join(values)}; e mais {remaining_text}"
    )


def describe_channel(
    dossier: dict[str, Any], event_overview: dict[str, Any]
) -> str:
    """Describe one full channel dossier from complete, visible evidence only."""
    name = str(dossier.get("channel_name", "Canal"))
    paid = _nonnegative_count(dossier.get("paid_registrations"))
    touched = _nonnegative_count(dossier.get("touched_paid_orders"))
    event_paid = _positive_denominator(event_overview.get("paid_registrations"))
    share = _percentage(dossier.get("share_of_event_registrations"))
    gross = _money_text(dossier.get("gross_value"))
    ticket = _number(dossier.get("registration_ticket"))
    event_ticket = _number(event_overview.get("registration_ticket"))
    ticket_delta = (
        (ticket / event_ticket - 1) * 100
        if ticket is not None and event_ticket not in {None, 0}
        else None
    )
    scale_parts = [
        _count_phrase(paid, "inscrição paga", "inscrições pagas")
        if paid is not None else "base paga não disponível"
    ]
    if share is not None and event_paid is not None:
        scale_parts.append(f"{_pt_number(share)}% do evento (base {_pt_count(event_paid)})")
    else:
        scale_parts.append("participação no evento não disponível")
    if gross:
        scale_parts.append(f"{gross} de valor bruto alocado")
    if ticket is not None and ticket_delta is not None:
        scale_parts.append(
            f"ticket por inscrição de {_money_text(ticket)} ({_signed(ticket_delta, '%')} vs. evento; evento {_money_text(event_ticket)})"
        )
    else:
        scale_parts.append("comparação de ticket não disponível")
    if touched is not None:
        scale_parts.append(
            f"{_count_phrase(touched, 'pedido tocado', 'pedidos tocados')} não aditivos"
        )

    scope = dossier.get("geographic_scope", {})
    state_coverage = scope.get("coverage", {}).get("state", {})
    valid_state_base = _nonnegative_count(state_coverage.get("valid"))
    state_base = _positive_denominator(state_coverage.get("denominator"))
    state_coverage_pct = _percentage(state_coverage.get("valid_coverage_pct"))
    geo_parts: list[str] = []
    if (
        scope.get("label")
        and _nonnegative_count(scope.get("states")) is not None
        and valid_state_base is not None
        and state_base is not None
        and valid_state_base <= state_base
        and state_coverage_pct is not None
    ):
        geo_parts.append(
            f"escopo observado {scope['label']}, {_pt_count(scope.get('states'))} UFs; cobertura válida de UF {_pt_number(state_coverage_pct)}% ({_pt_count(valid_state_base)}/{_pt_count(state_base)})"
        )
        valid_states = [
            row for row in dossier.get("top_states", [])
            if row.get("state") not in {None, "Não informado", "Inválido"}
            and _complete_delta([{
                "segment": row.get("state"),
                "channel_count": row.get("channel_count"),
                "channel_denominator": row.get("channel_denominator"),
                "event_count": row.get("event_count"),
                "event_denominator": row.get("event_denominator"),
                "delta_pp": row.get("delta_pp"),
            }], row.get("state"))
        ]
        if valid_states:
            row = valid_states[0]
            geo_parts.append(
                f"UF líder {row['state']} com {_pt_number(row['share_pct'])}% ({_signed(row['delta_pp'], '%')} vs. evento)"
            )
        valid_cities = [
            row for row in dossier.get("top_cities", [])
            if row.get("city") not in {None, "Não informado", "Inválido"}
            and _nonnegative_count(row.get("paid_registrations")) is not None
            and int(row.get("paid_registrations", 0)) >= SMALL_CELL_MIN_REGISTRATIONS
            and _number(row.get("delta_pp")) is not None
        ]
        if valid_cities:
            row = valid_cities[0]
            geo_parts.append(
                f"cidade líder {row['city']} com {_pt_number(row['share_pct'])}% ({_signed(row['delta_pp'], '%')} vs. evento)"
            )
    if not geo_parts:
        geo_parts.append("escopo e comparações regionais não disponíveis com bases completas")

    modality_parts = []
    for row in dossier.get("modality_mix", []):
        parsed = _valid_distribution_row(row, "modality")
        delta = _complete_delta(dossier.get("modality_delta_pp", []), row.get("modality"))
        if parsed is None or delta is None:
            continue
        segment, count, denominator, segment_share = parsed
        modality_parts.append(
            f"{segment}: {_pt_count(count)}/{_pt_count(denominator)} ({_pt_number(segment_share)}%; {_signed(delta['delta_pp'], '%')} vs. evento)"
        )
        if len(modality_parts) == 2:
            break
    modality_text = "; ".join(modality_parts) if modality_parts else "modalidades não disponíveis para comparação completa"

    lot_parts = []
    for row in dossier.get("lot_mix", []):
        parsed = _valid_distribution_row(row, "lot")
        delta = _complete_delta(dossier.get("lot_delta_pp", []), row.get("lot"))
        if parsed is None or delta is None:
            continue
        segment, count, denominator, segment_share = parsed
        lot_parts.append(
            f"lote líder {_lot_label(segment)}: {_pt_count(count)}/{_pt_count(denominator)} ({_pt_number(segment_share)}%; {_signed(delta['delta_pp'], '%')} vs. evento)"
        )
        break
    weeks = [
        row for row in dossier.get("weekly_sales", [])
        if row.get("week_start") and _nonnegative_count(row.get("paid_registrations")) is not None
    ]
    if weeks:
        peak = sorted(
            weeks,
            key=lambda row: (-int(row["paid_registrations"]), str(row["week_start"])),
        )[0]
        peak_date = _pt_date(peak["week_start"])
        if peak_date is not None:
            lot_parts.append(
                f"semana de pico {peak_date}, com "
                f"{_count_phrase(peak['paid_registrations'], 'inscrição', 'inscrições')}"
            )
    when_text = "; ".join(lot_parts) if lot_parts else "lote e pico semanal não disponíveis"

    product_parts = []
    product_candidates = sorted(
        (
            row for row in dossier.get("product_mix", [])
            if row.get("classification") != "kit_incluso"
        ),
        key=lambda row: (
            -(_nonnegative_count(row.get("registrations_with_product")) or 0),
            normalize_key(row.get("product_name")).casefold(),
            str(row.get("product_name") or "").casefold(),
        ),
    )
    for row in product_candidates:
        count = _nonnegative_count(row.get("registrations_with_product"))
        denominator = _positive_denominator(row.get("take_rate_denominator"))
        rate = _percentage(row.get("take_rate_pct"))
        delta = _number(row.get("take_rate_delta_pp"))
        mapping = _percentage(row.get("coverage", {}).get("product_mapping_coverage_pct"))
        if None in {count, denominator, rate, delta, mapping} or count > denominator:
            continue
        revenue = _money_text(row.get("explicit_revenue"))
        revenue_text = (
            f"receita explícita {revenue}"
            if revenue is not None
            else "receita explícita não disponível"
        )
        product_parts.append(
            f"{row['product_name']}: {_pt_count(count)}/{_pt_count(denominator)} "
            f"({_pt_number(rate)}%; {_signed(delta, '%')} vs. evento), "
            f"{revenue_text}; cobertura de mapeamento {_pt_number(mapping)}%"
        )
        break
    product_text = "; ".join(product_parts) if product_parts else "produto além do kit não disponível para comparação completa"

    closest = []
    by_dimension: dict[str, list[dict[str, Any]]] = {}
    for row in dossier.get("similar_channels_by_dimension", []):
        similarity = _number(row.get("similarity_0_1"))
        coverage_a = _percentage(row.get("channel_coverage"))
        coverage_b = _percentage(row.get("other_coverage"))
        if (
            row.get("dimension")
            and row.get("other_channel")
            and similarity is not None
            and 0 <= similarity <= 1
            and coverage_a is not None
            and coverage_b is not None
        ):
            by_dimension.setdefault(str(row["dimension"]), []).append(row)
    dimension_labels = {
        "geography": "geografia",
        "lot": "lote",
        "modality": "modalidade",
        "product": "produtos",
        "temporal": "tempo",
        "profile:age": "perfil: idade",
        "profile:gender": "perfil: gênero",
        "profile:pace": "perfil: ritmo",
        "profile:club": "perfil: clube/assessoria",
    }
    for dimension in sorted(by_dimension, key=str.casefold):
        row = sorted(
            by_dimension[dimension],
            key=lambda item: (-float(item["similarity_0_1"]), str(item["other_channel"]).casefold()),
        )[0]
        closest.append(
            f"{dimension_labels.get(dimension, dimension)}: {row['other_channel']} "
            f"({_pt_number(row['similarity_0_1'], 4)}; coberturas "
            f"{_pt_number(row['channel_coverage'])}%/{_pt_number(row['other_coverage'])}%)"
        )
    similarity_text = (
        "; ".join(closest)
        if closest
        else "pares comparáveis não disponíveis nas dimensões com cobertura suficiente"
    )
    mechanism = ""
    if name in {"PCD", "Benefício"} and dossier.get("channel_type") not in COMMERCIAL_CHANNEL_TYPES:
        mechanism = f" Classificação: {MECHANISM_POLICY_TEXT}."
    limitations = "; ".join(dossier.get("data_limitations", [])) or "nenhuma limitação adicional identificada"

    return (
        f"## {name}\n\n"
        f"- **Escala e valor** — {'; '.join(scale_parts)}.\n"
        f"- **Onde vende** — {'; '.join(geo_parts)}.\n"
        f"- **O que vende** — {modality_text}.\n"
        f"- **Quando vende** — {when_text}.\n"
        f"- **Produtos e diferenciação** — {product_text}.\n"
        f"- **Semelhanças e leitura** — {similarity_text}. As dimensões permanecem separadas; não há indicador combinado nem decisão automática.{mechanism}\n\n"
        f"Coberturas de perfil: {_coverage_text(dossier.get('profile_coverage', {}))}. "
        f"Aliases observados: {_alias_text(dossier.get('coupon_aliases', []))}. "
        f"Limitações: {limitations}."
    )


def describe_compact_channel(row: dict[str, Any]) -> str:
    """Return a cautious one-line executive highlight for a compact channel."""
    paid = _nonnegative_count(row.get("paid_registrations"))
    ticket = _money_text(row.get("registration_ticket"))
    parts = [
        _count_phrase(paid, "inscrição paga", "inscrições pagas")
        if paid is not None else "base paga não disponível",
        f"ticket por inscrição {ticket}" if ticket else "ticket não disponível",
    ]
    modality = row.get("principal_modality") or {}
    parsed_modality = _valid_distribution_row(modality, "modality")
    if parsed_modality is not None:
        segment, count, denominator, share = parsed_modality
        parts.append(
            f"modalidade observada {segment}: {_pt_count(count)}/{_pt_count(denominator)} "
            f"({_pt_number(share)}%)"
        )
    state = row.get("principal_state") or {}
    state_coverage = row.get("state_coverage", {})
    parsed_state = _valid_distribution_row(state, "state")
    coverage_pct = _percentage(state_coverage.get("valid_coverage_pct"))
    if parsed_state is not None and coverage_pct is not None and coverage_pct >= 70:
        segment, count, denominator, share = parsed_state
        parts.append(
            f"UF observada {segment}: {_pt_count(count)}/{_pt_count(denominator)} "
            f"({_pt_number(share)}%)"
        )
    warning = str(row.get("sample_warning") or "Base abaixo de 10 inscrições pagas; leitura indicativa")
    return f"{'; '.join(parts)}. {warning}."


def build_executive_summary(
    overview: dict[str, Any], capstone: dict[str, Any], full_count: int, compact_count: int
) -> str:
    """Build the report's answer-first entry point from one reconciled row."""
    paid = _nonnegative_count(overview.get("paid_registrations"))
    orders = _nonnegative_count(overview.get("paid_orders"))
    gross = _money_text(overview.get("gross_value"))
    road = _nonnegative_count(capstone.get("paid_registrations")) if capstone.get("available") else None
    road_share = _percentage(capstone.get("event_share_pct")) if capstone.get("available") else None
    road_text = (
        f"ROADRUNNERS é o maior canal com cupom observado, com "
        f"{_count_phrase(road, 'inscrição', 'inscrições')} e {_pt_number(road_share)}% do evento"
        if road is not None and road_share is not None
        else "a leitura do canal próprio ROADRUNNERS não está disponível nesta base"
    )
    return (
        "## Resumo executivo\n\n"
        f"- **Escala do evento.** {_count_phrase(paid, 'inscrição paga', 'inscrições pagas') if paid is not None else 'Base não disponível'} em "
        f"{_count_phrase(orders, 'pedido', 'pedidos') if orders is not None else 'pedidos não disponíveis'}; valor bruto {gross or 'não disponível'}.\n"
        f"- **Cobertura dos canais.** {_pt_count(full_count)} canais têm dossiê completo e {_pt_count(compact_count)} permanecem em leitura compacta por base inferior a 10 inscrições.\n"
        f"- **Canal próprio.** {road_text}; composição, cobertura e semelhanças continuam evidências separadas."
    )


def describe_roadrunners_capstone(row: dict[str, Any]) -> str:
    """Render the ROADRUNNERS conclusion from its single reconciled aggregate row."""
    if not row.get("available"):
        return "## ROADRUNNERS — leitura estratégica do canal próprio\n\nEvidência não disponível nesta base."
    lots = ", ".join(
        f"{_lot_label(lot['lot'])} {_pt_number(lot['share_pct'])}% ({_signed(lot['delta_pp'], '%')} vs. evento)"
        for lot in row.get("main_lot_mix", [])
    ) or "não disponível"
    additions = "; ".join(
        f"{product['product_name']} {_pt_number(product['take_rate_pct'])}% ({_signed(product['take_rate_delta_pp'], '%')} vs. evento)"
        for product in row.get("add_on_strengths", [])
    ) or "não disponíveis"
    similarity = row.get("organic_similarity", {})
    peak_date = _pt_date(row.get("peak_week_start")) or "data não disponível"
    return (
        "## ROADRUNNERS — leitura estratégica do canal próprio\n\n"
        f"- **Escala e valor.** 1º canal com cupom observado: {_count_phrase(row['paid_registrations'], 'inscrição', 'inscrições')}, {_pt_number(row['event_share_pct'])}% do evento e {_pt_number(row['coupon_assisted_share_pct'])}% das inscrições assistidas por cupom. Valor bruto alocado {_money_text(row['gross_value'])} ({_pt_number(row['gross_event_share_pct'])}% do bruto do evento); ticket {_money_text(row['registration_ticket'])} vs. {_money_text(row['event_registration_ticket'])} no evento ({_signed(row['registration_ticket_delta_pct'], '%')}).\n"
        f"- **Distância e alcance.** 21K + 42K somam {_pt_number(row['long_distance_share_pct'])}% vs. {_pt_number(row['event_long_distance_share_pct'])}% no evento ({_signed(row['long_distance_delta_pp'], '%')}); {_pt_count(row['observed_states'])} UFs com cobertura válida de {_pt_number(row['state_valid_coverage_pct'])}%. SP está {_signed(row['state_deltas'][0]['delta_pp'], '%')} e SC {_signed(row['state_deltas'][1]['delta_pp'], '%')} vs. evento.\n"
        f"- **Tempo, lote e produtos.** Pico na semana de {peak_date} com {_count_phrase(row['peak_week_paid_registrations'], 'inscrição', 'inscrições')}. Mix principal de lote: {lots}. Produtos além do kit: {additions}; receita explícita de produto não disponível na fonte.\n"
        f"- **Semelhança e leitura.** Frente ao Orgânico / sem cupom, as semelhanças são geografia {_pt_number(similarity['geography'], 4)}, modalidade {_pt_number(similarity['modality'], 4)} e produtos {_pt_number(similarity['product'], 4)}. Escala e alcance são pontos mais claros que uma composição singularmente diferenciada; isso não substitui a leitura separada das dimensões nem incorpora patrocínio, Expo, permuta ou cortesias, que não foram mensurados."
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
        f"{_pt_number(channel_coverage)}%"
        if channel_coverage is not None
        else "não disponível"
    )
    product_coverage_text = (
        f"{_pt_number(product_coverage)}%"
        if product_coverage is not None
        else "não disponível"
    )
    external = result.source_notes.get("external_considerations", {})
    external_text = "; ".join(
        f"{key} {value}" for key, value in external.items()
    ) or "considerações externas sem fonte identificada"

    if orders is not None and registrations is not None:
        grains_text = (
            f"Grãos: o evento contém {_pt_count(orders)} pedidos pagos únicos e "
            f"{_pt_count(registrations)} inscrições pagas;"
        )
    else:
        orders_text = _pt_count(orders) if orders is not None else "não disponível"
        registrations_text = (
            _pt_count(registrations) if registrations is not None else "não disponível"
        )
        grains_text = (
            f"Grãos: pedidos pagos únicos: {orders_text}; "
            f"inscrições pagas: {registrations_text};"
        )

    order_ticket = overview.get("order_ticket")
    order_ticket_text = "O ticket médio ponderado de pedido: não disponível."
    if order_ticket is not None and orders is not None and orders > 0:
        order_ticket_text = (
            f"O ticket médio ponderado de pedido foi {_money_text(order_ticket)} "
            f"na base de {_pt_count(orders)} pedidos."
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
            f"O ticket médio ponderado de inscrição foi {_money_text(registration_ticket)} "
            f"na base de {_pt_count(registrations)} inscrições."
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
            "Quais canais têm mix de modalidade ou produto além do kit realmente distinto, "
            "com cobertura suficiente para sustentar a leitura?"
        ),
    ]
