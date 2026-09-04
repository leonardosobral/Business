"""Territorial strategy aggregates derived from frozen MIF 2026 artifacts."""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable, Mapping
from decimal import Decimal, InvalidOperation
from typing import Any


STATE_STRATEGY_TRANSFORM_VERSION = "mif-2026-state-strategy.1"
COMMERCIAL_TICKET_MIN = Decimal("10.00")
MIN_CLASSIFIABLE_REGISTRATIONS = 30
MIN_VALID_STATE_COVERAGE_PCT = Decimal("70.00")
MIN_RELEVANT_STATE_REGISTRATIONS = 5
MIN_RELEVANT_REGION_REGISTRATIONS = 5
NATIONAL_MIN_RELEVANT_STATES = 10
NATIONAL_MIN_RELEVANT_REGIONS = 4
NATIONAL_MAX_LEADING_STATE_SHARE_PCT = Decimal("40.00")
MULTIREGIONAL_MIN_RELEVANT_STATES = 5
MULTIREGIONAL_MIN_RELEVANT_REGIONS = 3
MULTIREGIONAL_MAX_LEADING_STATE_SHARE_PCT = Decimal("60.00")
MIN_PUBLISHABLE_STATE_CHANNEL_REGISTRATIONS = 5
FEATURED_CHANNELS = ("ROADRUNNERS", "MANIADECORRIDA")

STATE_TO_REGION = {
    "AC": "Norte",
    "AL": "Nordeste",
    "AM": "Norte",
    "AP": "Norte",
    "BA": "Nordeste",
    "CE": "Nordeste",
    "DF": "Centro-Oeste",
    "ES": "Sudeste",
    "GO": "Centro-Oeste",
    "MA": "Nordeste",
    "MG": "Sudeste",
    "MS": "Centro-Oeste",
    "MT": "Centro-Oeste",
    "PA": "Norte",
    "PB": "Nordeste",
    "PE": "Nordeste",
    "PI": "Nordeste",
    "PR": "Sul",
    "RJ": "Sudeste",
    "RN": "Nordeste",
    "RO": "Norte",
    "RR": "Norte",
    "RS": "Sul",
    "SC": "Sul",
    "SE": "Nordeste",
    "SP": "Sudeste",
    "TO": "Norte",
}


def _decimal(value: object, default: Decimal = Decimal("0")) -> Decimal:
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return default
    return parsed if parsed.is_finite() else default


def _percent(numerator: int | Decimal, denominator: int | Decimal) -> str | None:
    denominator_value = _decimal(denominator)
    if denominator_value <= 0:
        return None
    return format(_decimal(numerator) / denominator_value * 100, ".2f")


def _money(value: Decimal | None) -> str | None:
    return None if value is None else format(value, ".2f")


def _is_organic(row: Mapping[str, Any]) -> bool:
    return str(row.get("channel_type", "")).strip().casefold() == "organico"


def _commercial_channels(
    channel_index: Iterable[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in channel_index
        if not _is_organic(row)
        and _decimal(row.get("registration_ticket")) > COMMERCIAL_TICKET_MIN
    ]
    return sorted(
        rows,
        key=lambda row: (
            -_decimal(row.get("gross_value")),
            -int(row.get("paid_registrations", 0) or 0),
            str(row.get("channel_name", "")).casefold(),
        ),
    )


def classify_reach(
    *,
    paid_registrations: int,
    valid_coverage_pct: object,
    active_ufs: int,
    active_regions: int,
    leading_state_share_pct: object,
) -> str:
    """Classify observed reach using the thresholds published with the artifact."""
    coverage = _decimal(valid_coverage_pct)
    leading_share = _decimal(leading_state_share_pct, Decimal("100"))
    if (
        paid_registrations < MIN_CLASSIFIABLE_REGISTRATIONS
        or coverage < MIN_VALID_STATE_COVERAGE_PCT
    ):
        return "Evidência insuficiente"
    if (
        active_ufs >= NATIONAL_MIN_RELEVANT_STATES
        and active_regions >= NATIONAL_MIN_RELEVANT_REGIONS
        and leading_share <= NATIONAL_MAX_LEADING_STATE_SHARE_PCT
    ):
        return "Nacional"
    if (
        active_ufs >= MULTIREGIONAL_MIN_RELEVANT_STATES
        and active_regions >= MULTIREGIONAL_MIN_RELEVANT_REGIONS
        and leading_share <= MULTIREGIONAL_MAX_LEADING_STATE_SHARE_PCT
    ):
        return "Multirregional"
    return "Regional"


def _aggregate_observations(
    observations: Iterable[Mapping[str, Any]],
) -> tuple[
    dict[str, dict[str, Any]],
    dict[tuple[str, str], dict[str, Any]],
    dict[tuple[str, str], int],
    dict[tuple[str, str], int],
]:
    state_totals: dict[str, dict[str, Any]] = {}
    state_channels: dict[tuple[str, str], dict[str, Any]] = {}
    state_modalities: dict[tuple[str, str], int] = defaultdict(int)
    state_phases: dict[tuple[str, str], int] = defaultdict(int)
    for row in observations:
        state = str(row.get("state", "")).strip().upper()
        if state not in STATE_TO_REGION:
            continue
        channel = str(row.get("channel_name", "")).strip()
        registrations = int(row.get("paid_registrations", 0) or 0)
        gross_raw = row.get("allocated_gross_value")
        gross = None if gross_raw is None else _decimal(gross_raw)
        state_row = state_totals.setdefault(
            state,
            {"paid_registrations": 0, "gross_value": Decimal("0"), "gross_complete": True},
        )
        state_row["paid_registrations"] += registrations
        if gross is None:
            state_row["gross_complete"] = False
        else:
            state_row["gross_value"] += gross

        channel_row = state_channels.setdefault(
            (state, channel),
            {"paid_registrations": 0, "gross_value": Decimal("0"), "gross_complete": True},
        )
        channel_row["paid_registrations"] += registrations
        if gross is None:
            channel_row["gross_complete"] = False
        else:
            channel_row["gross_value"] += gross

        state_modalities[(state, str(row.get("modality", "Não informado")))] += registrations
        state_phases[(state, str(row.get("phase", "Não informado")))] += registrations
    return state_totals, state_channels, state_modalities, state_phases


def _geography_pairs(
    dossiers: object,
    allowed_channels: set[str],
) -> list[dict[str, Any]]:
    if isinstance(dossiers, Mapping):
        raw_dossiers = dossiers.get("channels", dossiers.get("dossiers", []))
    else:
        raw_dossiers = dossiers
    if not isinstance(raw_dossiers, list):
        return []
    canonical: dict[tuple[str, str], dict[str, Any]] = {}
    for dossier in raw_dossiers:
        if not isinstance(dossier, Mapping):
            continue
        left = str(dossier.get("channel_name", ""))
        for comparison in dossier.get("similar_channels_by_dimension", []) or []:
            if (
                not isinstance(comparison, Mapping)
                or comparison.get("dimension") != "geography"
            ):
                continue
            right = str(comparison.get("other_channel", ""))
            if left not in allowed_channels or right not in allowed_channels or left == right:
                continue
            first, second = sorted((left, right), key=str.casefold)
            if left == first:
                first_coverage = _decimal(comparison.get("channel_coverage"))
                second_coverage = _decimal(comparison.get("other_coverage"))
            else:
                first_coverage = _decimal(comparison.get("other_coverage"))
                second_coverage = _decimal(comparison.get("channel_coverage"))
            similarity = _decimal(comparison.get("similarity_0_1"), Decimal("-1"))
            if similarity < 0 or similarity > 1:
                continue
            row = {
                "left_channel": first,
                "right_channel": second,
                "similarity_0_1": float(similarity),
                "left_coverage_pct": format(first_coverage, ".2f"),
                "right_coverage_pct": format(second_coverage, ".2f"),
            }
            key = (first, second)
            existing = canonical.get(key)
            if existing is None or row["similarity_0_1"] > existing["similarity_0_1"]:
                canonical[key] = row
    return [canonical[key] for key in sorted(canonical, key=lambda pair: tuple(value.casefold() for value in pair))]


def _channel_profile(
    index_row: Mapping[str, Any],
    state_counts: Mapping[str, int],
) -> dict[str, Any]:
    paid = int(index_row.get("paid_registrations", 0) or 0)
    valid = sum(state_counts.values())
    coverage = _percent(valid, paid) or "0.00"
    ordered_states = sorted(
        state_counts.items(), key=lambda item: (-item[1], item[0])
    )
    active_states = [state for state, count in ordered_states if count >= MIN_RELEVANT_STATE_REGISTRATIONS]
    region_counts: dict[str, int] = defaultdict(int)
    for state, count in state_counts.items():
        region_counts[STATE_TO_REGION[state]] += count
    active_regions = sorted(
        region
        for region, count in region_counts.items()
        if count >= MIN_RELEVANT_REGION_REGISTRATIONS
    )
    leading_state = ordered_states[0][0] if ordered_states else None
    leading_share = _percent(ordered_states[0][1], valid) if ordered_states else None
    top_three = sum(count for _, count in ordered_states[:3])
    south = sum(count for state, count in state_counts.items() if STATE_TO_REGION[state] == "Sul")
    hhi = (
        sum((Decimal(count) / Decimal(valid)) ** 2 for count in state_counts.values())
        if valid
        else None
    )
    reach = classify_reach(
        paid_registrations=paid,
        valid_coverage_pct=coverage,
        active_ufs=len(active_states),
        active_regions=len(active_regions),
        leading_state_share_pct=leading_share,
    )
    return {
        "channel_name": str(index_row.get("channel_name", "")),
        "channel_type": str(index_row.get("channel_type", "")),
        "slug": str(index_row.get("slug", "")),
        "paid_registrations": paid,
        "gross_value": str(index_row.get("gross_value", "0.00")),
        "registration_ticket": str(index_row.get("registration_ticket", "0.00")),
        "valid_state_registrations": valid,
        "valid_state_coverage_pct": coverage,
        "active_ufs": len(active_states),
        "active_regions": len(active_regions),
        "active_region_names": active_regions,
        "leading_state": leading_state,
        "leading_state_share_valid_pct": leading_share,
        "top_3_state_share_valid_pct": _percent(top_three, valid),
        "outside_south_share_valid_pct": _percent(valid - south, valid),
        "state_concentration_hhi": None if hhi is None else float(hhi.quantize(Decimal("0.0001"))),
        "reach_classification": reach,
        "reach_rationale": (
            f"{len(active_states)} UFs e {len(active_regions)} regiões com ao menos "
            f"{MIN_RELEVANT_STATE_REGISTRATIONS} inscrições; principal UF = "
            f"{leading_share or 'não disponível'}% da base estadual válida."
        ),
        "state_distribution": [
            {
                "state": state,
                "region": STATE_TO_REGION[state],
                "paid_registrations": count,
                "share_valid_pct": _percent(count, valid),
                "relevant": count >= MIN_RELEVANT_STATE_REGISTRATIONS,
            }
            for state, count in ordered_states
        ],
    }


def compare_channels(
    left_profile: Mapping[str, Any],
    right_profile: Mapping[str, Any],
    geography_pairs: Iterable[Mapping[str, Any]],
    *,
    geography_p90_similarity_0_1: object,
) -> dict[str, Any]:
    """Describe territorial overlap without claiming causal duplication."""
    left_name = str(left_profile.get("channel_name", ""))
    right_name = str(right_profile.get("channel_name", ""))
    left_counts = {
        str(row["state"]): int(row.get("paid_registrations", 0) or 0)
        for row in left_profile.get("state_distribution", []) or []
    }
    right_counts = {
        str(row["state"]): int(row.get("paid_registrations", 0) or 0)
        for row in right_profile.get("state_distribution", []) or []
    }
    left_valid = sum(left_counts.values())
    right_valid = sum(right_counts.values())
    states = sorted(set(left_counts) | set(right_counts))
    overlap = Decimal("0")
    left_distinctive: list[str] = []
    right_distinctive: list[str] = []
    state_comparison = []
    for state in states:
        left_count = left_counts.get(state, 0)
        right_count = right_counts.get(state, 0)
        left_share = Decimal(left_count) / Decimal(left_valid) * 100 if left_valid else Decimal("0")
        right_share = Decimal(right_count) / Decimal(right_valid) * 100 if right_valid else Decimal("0")
        overlap += min(left_share, right_share)
        delta = left_share - right_share
        if left_count >= MIN_RELEVANT_STATE_REGISTRATIONS and delta >= Decimal("3"):
            left_distinctive.append(state)
        if right_count >= MIN_RELEVANT_STATE_REGISTRATIONS and delta <= Decimal("-3"):
            right_distinctive.append(state)
        state_comparison.append(
            {
                "state": state,
                "left_paid_registrations": left_count,
                "right_paid_registrations": right_count,
                "left_share_valid_pct": format(left_share, ".2f"),
                "right_share_valid_pct": format(right_share, ".2f"),
                "left_minus_right_pp": format(delta, ".2f"),
            }
        )
    pair_key = tuple(sorted((left_name, right_name), key=str.casefold))
    pair = next(
        (
            row
            for row in geography_pairs
            if (str(row.get("left_channel")), str(row.get("right_channel"))) == pair_key
        ),
        None,
    )
    similarity = None if pair is None else float(pair.get("similarity_0_1"))
    p90 = None if geography_p90_similarity_0_1 is None else float(_decimal(geography_p90_similarity_0_1))
    overlap_classification = (
        "Evidência insuficiente"
        if similarity is None or p90 is None
        else "Sobreposição forte"
        if similarity >= p90
        else "Perfis complementares"
    )
    shared_relevant = sorted(
        state
        for state in states
        if left_counts.get(state, 0) >= MIN_RELEVANT_STATE_REGISTRATIONS
        and right_counts.get(state, 0) >= MIN_RELEVANT_STATE_REGISTRATIONS
    )
    combined_relevant = sorted(
        state
        for state in states
        if left_counts.get(state, 0) + right_counts.get(state, 0)
        >= MIN_RELEVANT_STATE_REGISTRATIONS
    )
    return {
        "left_channel": left_name,
        "right_channel": right_name,
        "left_paid_registrations": int(left_profile.get("paid_registrations", 0) or 0),
        "right_paid_registrations": int(right_profile.get("paid_registrations", 0) or 0),
        "combined_paid_registrations": int(left_profile.get("paid_registrations", 0) or 0)
        + int(right_profile.get("paid_registrations", 0) or 0),
        "combined_gross_value": format(
            _decimal(left_profile.get("gross_value")) + _decimal(right_profile.get("gross_value")),
            ".2f",
        ),
        "geography_similarity_0_1": similarity,
        "geography_p90_similarity_0_1": p90,
        "distribution_overlap_pct": format(overlap, ".2f"),
        "overlap_classification": overlap_classification,
        "combined_relevant_states": combined_relevant,
        "shared_relevant_states": shared_relevant,
        "left_distinctive_states": left_distinctive,
        "right_distinctive_states": right_distinctive,
        "state_comparison": sorted(
            state_comparison,
            key=lambda row: (
                -(row["left_paid_registrations"] + row["right_paid_registrations"]),
                row["state"],
            ),
        ),
        "interpretation": (
            "A semelhança compara a distribuição estadual observada; não mede "
            "incrementalidade, canibalização ou vendas perdidas."
        ),
    }


def build_state_strategy(
    *,
    overview: Mapping[str, Any],
    channel_index: Iterable[Mapping[str, Any]],
    dossiers: object,
    territory_observations: Iterable[Mapping[str, Any]],
    geography_benchmark: Mapping[str, Any],
    generated_at: str,
    featured_channels: tuple[str, str] = FEATURED_CHANNELS,
) -> dict[str, Any]:
    """Build the compact, private state-strategy payload."""
    index_rows = list(channel_index)
    observations = list(territory_observations)
    commercial = _commercial_channels(index_rows)
    commercial_by_name = {str(row["channel_name"]): row for row in commercial}
    state_totals, state_channel_totals, state_modalities, state_phases = _aggregate_observations(
        observations
    )

    channel_state_counts: dict[str, dict[str, int]] = {
        name: {} for name in commercial_by_name
    }
    for (state, channel), values in state_channel_totals.items():
        if channel in commercial_by_name:
            channel_state_counts[channel][state] = int(values["paid_registrations"])
    channels = [
        _channel_profile(row, channel_state_counts[str(row["channel_name"])])
        for row in commercial
    ]
    channels_by_name = {row["channel_name"]: row for row in channels}

    valid_state_registrations = sum(
        int(values["paid_registrations"]) for values in state_totals.values()
    )
    event_paid = int(overview.get("paid_registrations", 0) or 0)
    commercial_paid = sum(int(row.get("paid_registrations", 0) or 0) for row in commercial)
    commercial_by_state: dict[str, int] = defaultdict(int)
    for channel, state_counts in channel_state_counts.items():
        for state, count in state_counts.items():
            commercial_by_state[state] += count

    state_rows = []
    for state, values in state_totals.items():
        paid = int(values["paid_registrations"])
        gross = values["gross_value"] if values["gross_complete"] else None
        published_channels = [
            (channel, int(state_channel_totals[(state, channel)]["paid_registrations"]))
            for channel in commercial_by_name
            if (state, channel) in state_channel_totals
            and int(state_channel_totals[(state, channel)]["paid_registrations"])
            >= MIN_PUBLISHABLE_STATE_CHANNEL_REGISTRATIONS
        ]
        published_channels.sort(key=lambda item: (-item[1], item[0].casefold()))
        leader = published_channels[0] if published_channels else None
        state_rows.append(
            {
                "state": state,
                "region": STATE_TO_REGION[state],
                "paid_registrations": paid,
                "gross_value": _money(gross),
                "registration_ticket": _money(gross / paid if gross is not None and paid else None),
                "event_share_pct": _percent(paid, event_paid),
                "commercial_paid_registrations": commercial_by_state.get(state, 0),
                "commercial_share_of_state_pct": _percent(commercial_by_state.get(state, 0), paid),
                "leading_channel": None if leader is None else leader[0],
                "leading_channel_registrations": None if leader is None else leader[1],
                "leading_channel_state_share_pct": None if leader is None else _percent(leader[1], paid),
                "publishable_channel_count": len(published_channels),
            }
        )
    state_rows.sort(key=lambda row: (-row["paid_registrations"], row["state"]))

    state_channel_rows = []
    suppressed_registrations = 0
    for (state, channel), values in state_channel_totals.items():
        if channel not in commercial_by_name:
            continue
        paid = int(values["paid_registrations"])
        if paid < MIN_PUBLISHABLE_STATE_CHANNEL_REGISTRATIONS:
            suppressed_registrations += paid
            continue
        gross = values["gross_value"] if values["gross_complete"] else None
        channel_valid = channels_by_name[channel]["valid_state_registrations"]
        state_channel_rows.append(
            {
                "state": state,
                "region": STATE_TO_REGION[state],
                "channel_name": channel,
                "channel_slug": str(commercial_by_name[channel].get("slug", "")),
                "paid_registrations": paid,
                "gross_value": _money(gross),
                "event_state_share_pct": _percent(paid, state_totals[state]["paid_registrations"]),
                "commercial_state_share_pct": _percent(paid, commercial_by_state[state]),
                "channel_valid_state_share_pct": _percent(paid, channel_valid),
            }
        )
    state_channel_rows.sort(
        key=lambda row: (
            next(index for index, state in enumerate(state_rows) if state["state"] == row["state"]),
            -row["paid_registrations"],
            row["channel_name"].casefold(),
        )
    )

    pairs = _geography_pairs(dossiers, set(commercial_by_name))
    p90 = geography_benchmark.get("p90_similarity_0_1")
    featured_pair = None
    if all(name in channels_by_name for name in featured_channels):
        featured_pair = compare_channels(
            channels_by_name[featured_channels[0]],
            channels_by_name[featured_channels[1]],
            pairs,
            geography_p90_similarity_0_1=p90,
        )

    return {
        "meta": {
            "event_code": 72611,
            "generated_at": generated_at,
            "transform_version": STATE_STRATEGY_TRANSFORM_VERSION,
        },
        "overview": {
            "event_paid_registrations": event_paid,
            "event_gross_value": str(overview.get("gross_value", "0.00")),
            "valid_state_registrations": valid_state_registrations,
            "state_coverage_pct": _percent(valid_state_registrations, event_paid),
            "commercial_paid_registrations": commercial_paid,
            "commercial_channel_count": len(commercial),
            "classified_channel_count": sum(
                row["reach_classification"] != "Evidência insuficiente" for row in channels
            ),
            "national_channel_count": sum(
                row["reach_classification"] == "Nacional" for row in channels
            ),
        },
        "thresholds": {
            "commercial_ticket_min_exclusive": format(COMMERCIAL_TICKET_MIN, ".2f"),
            "minimum_classifiable_registrations": MIN_CLASSIFIABLE_REGISTRATIONS,
            "minimum_valid_state_coverage_pct": format(MIN_VALID_STATE_COVERAGE_PCT, ".2f"),
            "minimum_relevant_state_registrations": MIN_RELEVANT_STATE_REGISTRATIONS,
            "minimum_relevant_region_registrations": MIN_RELEVANT_REGION_REGISTRATIONS,
            "national_minimum_relevant_states": NATIONAL_MIN_RELEVANT_STATES,
            "national_minimum_relevant_regions": NATIONAL_MIN_RELEVANT_REGIONS,
            "national_maximum_leading_state_share_pct": format(NATIONAL_MAX_LEADING_STATE_SHARE_PCT, ".2f"),
            "multiregional_minimum_relevant_states": MULTIREGIONAL_MIN_RELEVANT_STATES,
            "multiregional_minimum_relevant_regions": MULTIREGIONAL_MIN_RELEVANT_REGIONS,
            "multiregional_maximum_leading_state_share_pct": format(MULTIREGIONAL_MAX_LEADING_STATE_SHARE_PCT, ".2f"),
            "minimum_publishable_state_channel_registrations": MIN_PUBLISHABLE_STATE_CHANNEL_REGISTRATIONS,
        },
        "definitions": {
            "reach": "Alcance observado nas inscrições pagas do evento, sem inferência de incrementalidade.",
            "relevant_state": "UF com ao menos cinco inscrições pagas do canal.",
            "overlap": "Semelhança entre distribuições estaduais; não representa pedidos duplicados nem canibalização comprovada.",
            "commercial_universe": "Canais não orgânicos com ticket por inscrição acima de R$ 10,00.",
        },
        "states": state_rows,
        "channels": channels,
        "state_channels": state_channel_rows,
        "state_modalities": [
            {"state": state, "modality": modality, "paid_registrations": paid}
            for (state, modality), paid in sorted(
                state_modalities.items(), key=lambda item: (item[0][0], -item[1], item[0][1])
            )
        ],
        "state_phases": [
            {"state": state, "phase": phase, "paid_registrations": paid}
            for (state, phase), paid in sorted(
                state_phases.items(), key=lambda item: (item[0][0], -item[1], item[0][1])
            )
        ],
        "geography_benchmark": dict(geography_benchmark),
        "geography_pairs": pairs,
        "featured_pair": featured_pair,
        "privacy": {
            "state_channel_minimum_registrations": MIN_PUBLISHABLE_STATE_CHANNEL_REGISTRATIONS,
            "suppressed_state_channel_registrations": suppressed_registrations,
            "suppression_scope": "Somente o detalhe estado × canal; totais estaduais permanecem completos.",
        },
        "sort": {
            "states": ["paid_registrations desc", "state asc"],
            "channels": ["gross_value desc", "paid_registrations desc", "channel_name asc"],
            "state_channels": ["state volume desc", "paid_registrations desc", "channel_name asc"],
        },
    }
