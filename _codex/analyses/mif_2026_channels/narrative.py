"""Deterministic evidence-first narratives for the MIF 2026 analysis."""

from __future__ import annotations

from typing import Any

from .models import AnalysisResult


MECHANISM_POLICY_TEXT = (
    "mecanismo/política no cadastro, não presumido como parceiro comercial"
)


def _coverage_text(profile_coverage: dict[str, dict[str, Any]]) -> str:
    labels = {
        "age": "idade",
        "gender": "gênero",
        "pace": "ritmo",
        "club": "clube/assessoria",
    }
    parts = []
    for key in ("age", "gender", "pace", "club"):
        coverage = profile_coverage.get(key, {})
        if not coverage:
            continue
        valid = int(coverage.get("valid", 0))
        denominator = int(coverage.get("denominator", 0))
        percentage = float(coverage.get("valid_coverage_pct", 0.0))
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
        count = int(alias.get("paid_registrations", 0))
        values.append(f"{identity or 'sem título/código'} ({count} inscrições)")
    return "; ".join(values)


def describe_channel(
    dossier: dict[str, Any], event_overview: dict[str, Any]
) -> str:
    """Describe one full channel dossier without a score or automated advice."""
    paid_registrations = int(dossier["paid_registrations"])
    touched_orders = int(dossier["touched_paid_orders"])
    event_registrations = int(event_overview.get("paid_registrations", 0))
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
        and dossier.get("channel_type") in {"politica", "beneficio"}
    ):
        mechanism_note = f" Classificação: {MECHANISM_POLICY_TEXT}."

    add_on_text = "nenhum adicional observado"
    if add_on:
        add_on_text = (
            f"{add_on.get('product_name')} em {int(add_on.get('registrations_with_product', 0))}/"
            f"{int(add_on.get('take_rate_denominator', paid_registrations))} inscrições "
            f"({float(add_on.get('take_rate_pct', 0.0)):.2f}%), com cobertura de mapeamento "
            f"de {float(add_on_coverage.get('product_mapping_coverage_pct', 0.0)):.2f}%"
        )

    return (
        f"{dossier['channel_name']} registrou {paid_registrations} inscrições pagas em "
        f"{touched_orders} pedidos tocados, não aditivos entre canais, equivalentes a "
        f"{float(dossier.get('share_of_event_registrations', 0.0)):.2f}% da base de "
        f"{event_registrations} inscrições do evento. O ticket médio ponderado por inscrição "
        f"foi R$ {dossier.get('registration_ticket', '0.00')}, na base de "
        f"{paid_registrations} inscrições. Mix de modalidade: "
        f"{leading_modality.get('modality', 'não disponível')} liderou com "
        f"{int(leading_modality.get('paid_registrations', 0))}/"
        f"{int(leading_modality.get('denominator', paid_registrations))} "
        f"({float(leading_modality.get('share_pct', 0.0)):.2f}%). "
        f"A abrangência observada foi {geography.get('label', 'não disponível')}, com "
        f"{int(geography.get('states', 0))} UFs e {int(geography.get('cities', 0))} cidades; "
        f"a concentração foi HHI {float(geography.get('city_concentration_hhi', 0.0)):.4f} "
        f"por cidade e {float(geography.get('leading_city_pct', 0.0)):.2f}% na principal cidade. "
        f"No recorte de lote, {leading_lot.get('lot', 'não disponível')} reuniu "
        f"{int(leading_lot.get('paid_registrations', 0))}/"
        f"{int(leading_lot.get('denominator', paid_registrations))} inscrições; "
        f"o pico semanal observado começou em {peak_week.get('week_start', 'data não disponível')} "
        f"com {int(peak_week.get('paid_registrations', 0))} inscrições. "
        f"Adoção de adicional: {add_on_text}. Cobertura de perfil: "
        f"{_coverage_text(dossier.get('profile_coverage', {}))}. "
        f"Aliases de origem: {_alias_text(dossier.get('coupon_aliases', []))}."
        f"{mechanism_note} Limitações de leitura: {limitations}."
    )


def describe_event(result: AnalysisResult) -> str:
    """Describe event commerce with explicit grains, bases, and limitations."""
    overview = result.overview
    orders = int(overview.get("paid_orders", 0))
    registrations = int(overview.get("paid_registrations", 0))
    coverage = overview.get("source_field_coverage", {})
    channel_coverage = coverage.get("channel_mapping_coverage_pct")
    product_coverage = coverage.get("product_mapping_coverage_pct")
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

    return (
        f"Grãos: o evento contém {orders} pedidos pagos únicos e {registrations} inscrições pagas; "
        f"pedidos tocados não são aditivos entre canais, pois um pedido pode conter inscrições "
        f"atribuídas a canais diferentes. O ticket médio ponderado de pedido foi R$ "
        f"{overview.get('order_ticket', '0.00')} na base de {orders} pedidos; o ticket médio "
        f"ponderado de inscrição foi R$ {overview.get('registration_ticket', '0.00')} na base "
        f"de {registrations} inscrições. Coberturas de fonte: canais {channel_coverage_text}; "
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
