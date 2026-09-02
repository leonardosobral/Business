"""Evidence-first commercial role recommendations for modular channel dossiers."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation
from typing import Any


STRATEGIC_CHANNELS = frozenset({"ROADRUNNERS", "SPORTS WEEK", "PCD"})
MIN_STRONG_SAMPLE = 30
PRIORITY_EVENT_SHARE_PCT = 5.0
LOW_SCALE_EVENT_SHARE_PCT = 0.5
MATERIAL_DELTA_PP = 8.0
HIGH_ORGANIC_SIMILARITY = 0.90
MIN_REDUNDANT_DIMENSIONS = 3


def _number(value: object, default: float = 0.0) -> float:
    try:
        parsed = float(value)
    except (TypeError, ValueError):
        return default
    return parsed


def _decimal(value: object) -> Decimal:
    try:
        return Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return Decimal("0.00")


def _event_share(dossier: dict[str, Any], overview: dict[str, Any]) -> float:
    explicit = dossier.get("share_of_event_registrations")
    if explicit is not None:
        return _number(explicit)
    denominator = int(overview.get("paid_registrations", 0) or 0)
    return (
        int(dossier.get("paid_registrations", 0) or 0) / denominator * 100
        if denominator
        else 0.0
    )


def _gross_share(dossier: dict[str, Any], overview: dict[str, Any]) -> float:
    denominator = _decimal(overview.get("gross_value"))
    return (
        float(_decimal(dossier.get("gross_value")) / denominator * 100)
        if denominator
        else 0.0
    )


def _signal_rows(dossier: dict[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    configurations = (
        ("modality_delta_pp", "distância", "segment", "delta_pp"),
        ("lot_delta_pp", "lote", "segment", "delta_pp"),
        ("phase_delta_pp", "fase", "segment", "delta_pp"),
        ("top_states", "estado", "state", "delta_pp"),
        ("product_mix", "produto", "product_name", "take_rate_delta_pp"),
    )
    for field, dimension, segment_field, delta_field in configurations:
        for row in dossier.get(field, []) or []:
            delta = row.get(delta_field)
            if delta is None:
                continue
            rows.append(
                {
                    "dimension": dimension,
                    "segment": str(row.get(segment_field, "Não informado")),
                    "delta_pp": _number(delta),
                }
            )
    for row in dossier.get("distinctive_signals", []) or []:
        delta = row.get("delta_pp")
        if delta is None:
            continue
        rows.append(
            {
                "dimension": str(row.get("dimension", "segmento")),
                "segment": str(row.get("segment", "Não informado")),
                "delta_pp": _number(delta),
            }
        )
    unique = {
        (row["dimension"], row["segment"], round(row["delta_pp"], 6)): row
        for row in rows
    }
    return sorted(
        unique.values(),
        key=lambda row: (-abs(row["delta_pp"]), row["dimension"], row["segment"]),
    )


def _organic_similarities(dossier: dict[str, Any]) -> list[float]:
    return [
        _number(row.get("similarity_0_1"))
        for row in dossier.get("similar_channels_by_dimension", []) or []
        if row.get("other_channel") == "Orgânico / sem cupom"
        and row.get("similarity_0_1") is not None
    ]


def recommend_channel(
    dossier: dict[str, Any], overview: dict[str, Any]
) -> dict[str, Any]:
    """Return an explicit category with its visible evidence and no master score."""
    paid = int(dossier.get("paid_registrations", 0) or 0)
    event_share = _event_share(dossier, overview)
    gross_share = _gross_share(dossier, overview)
    signals = _signal_rows(dossier)
    material = [row for row in signals if abs(row["delta_pp"]) >= MATERIAL_DELTA_PP]
    positive = [row for row in material if row["delta_pp"] > 0]
    organic = _organic_similarities(dossier)
    redundant_dimensions = sum(
        value >= HIGH_ORGANIC_SIMILARITY for value in organic
    )

    small_sample = paid < MIN_STRONG_SAMPLE
    scale_is_relevant = max(event_share, gross_share) >= PRIORITY_EVENT_SHARE_PCT
    has_specific_complementary_role = bool(positive)
    scale_is_low = (
        event_share <= LOW_SCALE_EVENT_SHARE_PCT
        and gross_share <= LOW_SCALE_EVENT_SHARE_PCT
    )
    redundancy_is_high = redundant_dimensions >= MIN_REDUNDANT_DIMENSIONS

    if small_sample:
        category = "Testar/renegociar"
    elif scale_is_relevant and has_specific_complementary_role:
        category = "Priorizar"
    elif has_specific_complementary_role:
        category = "Manter com função definida"
    elif scale_is_low and redundancy_is_high:
        category = "Reduzir/descontinuar"
    else:
        category = "Testar/renegociar"

    lead = positive[0] if positive else (material[0] if material else None)
    if lead is not None:
        direction = "acima" if lead["delta_pp"] > 0 else "abaixo"
        role = (
            f"{lead['dimension']} — {lead['segment']}: "
            f"{abs(lead['delta_pp']):.2f} pp {direction} do evento"
        )
    elif redundancy_is_high:
        role = "perfil amplamente semelhante ao orgânico"
    elif scale_is_relevant:
        role = "escala ampla sem diferenciação material comprovada"
    else:
        role = "papel ainda não definido com evidência suficiente"

    evidence = [
        f"{paid} inscrições pagas ({event_share:.2f}% do evento)",
        f"valor bruto equivalente a {gross_share:.2f}% do evento",
    ]
    if lead is not None:
        evidence.append(role)
    if organic:
        evidence.append(
            f"semelhança média com orgânico de {sum(organic) / len(organic):.4f} "
            f"em {len(organic)} dimensões observadas"
        )
    if small_sample:
        evidence.append(
            f"base abaixo de {MIN_STRONG_SAMPLE} inscrições; recomendação forte bloqueada"
        )

    return {
        "channel_name": str(dossier.get("channel_name", "Não informado")),
        "category": category,
        "role": role,
        "evidence": evidence,
        "sample_qualification": "amostra reduzida" if small_sample else "base observada",
        "criteria": {
            "scale_is_relevant": scale_is_relevant,
            "has_specific_complementary_role": has_specific_complementary_role,
            "scale_is_low": scale_is_low,
            "redundancy_is_high": redundancy_is_high,
            "material_delta_pp": MATERIAL_DELTA_PP,
            "priority_event_share_pct": PRIORITY_EVENT_SHARE_PCT,
            "low_scale_event_share_pct": LOW_SCALE_EVENT_SHARE_PCT,
            "high_organic_similarity": HIGH_ORGANIC_SIMILARITY,
        },
    }
