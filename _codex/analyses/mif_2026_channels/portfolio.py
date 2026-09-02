"""Deterministic portfolio contracts for the frozen MIF 2026 data."""

from __future__ import annotations

from decimal import Decimal, InvalidOperation
from collections.abc import Mapping
from typing import Any, Iterable

from .normalize import normalize_key


COMMERCIAL_TICKET_MIN = Decimal("10.00")
MIN_PROFILE_REGISTRATIONS = 10
MIN_DIMENSION_COVERAGE_PCT = Decimal("70.00")
MIN_PUBLISHABLE_CELL_REGISTRATIONS = 5
EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS = MIN_PROFILE_REGISTRATIONS
EXPOSURE_HIGH_EVENT_SHARE_PCT = Decimal("40.00")
EXPOSURE_MEDIUM_EVENT_SHARE_PCT = Decimal("20.00")
EXPOSURE_PARTNER_CONCENTRATION_PCT = Decimal("60.00")
ACTIONABLE_DIMENSIONS = ("geography", "modality", "temporal", "lot", "product")
PORTFOLIO_TRANSFORM_VERSION = "mif-2026-portfolio.2"
SIMULATOR_DIMENSIONS = ("phase", "modality", "state", "channel_name")
SIMULATOR_TOTAL_ALL = "Todos os canais"
SIMULATOR_TOTAL_COMMERCIAL = "Canais comerciais não orgânicos"
MONEY_FIELDS = (
    "allocated_gross_value",
    "allocated_discount_value",
    "allocated_fee_value",
    "allocated_net_transfer_value",
    "allocated_cashback_value",
)


def _decimal(value: object, default: Decimal = Decimal("0.00")) -> Decimal:
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return default
    return parsed if parsed.is_finite() else default


def _similarity(value: object) -> float | None:
    """Parse a bounded finite similarity without treating invalid data as zero."""
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return None
    if not parsed.is_finite() or parsed < 0 or parsed > 1:
        return None
    return float(parsed)


def commercial_channels(
    rows: Iterable[dict[str, Any]], *, selectable: bool = False
) -> list[dict[str, Any]]:
    """Return ticket-qualified channels in the deterministic commercial order."""
    qualified = [
        dict(row)
        for row in rows
        if _decimal(row.get("registration_ticket")) > COMMERCIAL_TICKET_MIN
        and (not selectable or str(row.get("channel_type", "")).casefold() != "organico")
    ]
    return sorted(
        qualified,
        key=lambda row: (
            -_decimal(row.get("gross_value")),
            -int(row.get("paid_registrations", 0) or 0),
            str(row.get("channel_name", "")).casefold(),
        ),
    )


def classify_exposure(*, selected: int, event_total: int, commercial_total: int) -> str | None:
    """Classify observed exposure with explicit event and partner denominators."""
    if selected < MIN_PUBLISHABLE_CELL_REGISTRATIONS or event_total <= 0:
        return None
    event_share = Decimal(selected) / Decimal(event_total) * 100
    partner_share = (
        Decimal(selected) / Decimal(commercial_total) * 100
        if commercial_total
        else Decimal("0")
    )
    if (
        selected >= EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS
        and event_share >= EXPOSURE_HIGH_EVENT_SHARE_PCT
    ):
        return "alta"
    if (
        selected >= EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS
        and event_share >= EXPOSURE_MEDIUM_EVENT_SHARE_PCT
    ):
        return "média"
    if (
        partner_share >= EXPOSURE_PARTNER_CONCENTRATION_PCT
        and event_share < EXPOSURE_MEDIUM_EVENT_SHARE_PCT
    ):
        return "dependência entre parceiros"
    return "baixa"


def pair_key(left: object, right: object) -> tuple[str, str]:
    """Return the case-insensitive canonical key for an unordered channel pair."""
    return tuple(sorted((str(left), str(right)), key=str.casefold))


def _linear_percentile(values: Iterable[object], percentile: Decimal) -> float | None:
    ordered = sorted(float(_decimal(value)) for value in values)
    if not ordered:
        return None
    if len(ordered) == 1:
        return ordered[0]
    position = float(percentile) / 100 * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def _similarity_rows(similarities: object) -> list[dict[str, Any]]:
    """Normalize frozen overlap rows and dossier comparisons to pair records."""
    rows: list[dict[str, Any]] = []
    if isinstance(similarities, Mapping):
        for dimension, values in similarities.items():
            if str(dimension).removesuffix("_overlap") not in ACTIONABLE_DIMENSIONS:
                continue
            if not isinstance(values, list):
                continue
            for value in values:
                if isinstance(value, Mapping):
                    rows.append({"dimension": str(dimension).removesuffix("_overlap"), **value})
        return rows
    if not isinstance(similarities, list):
        return rows
    for value in similarities:
        if not isinstance(value, Mapping):
            continue
        comparisons = value.get("similar_channels_by_dimension")
        if isinstance(comparisons, list):
            channel = value.get("channel_name")
            for comparison in comparisons:
                if isinstance(comparison, Mapping) and channel is not None:
                    rows.append(
                        {
                            "dimension": comparison.get("dimension"),
                            "channel_a": channel,
                            "channel_b": comparison.get("other_channel"),
                            "similarity_0_1": comparison.get("similarity_0_1"),
                            "coverage_a": comparison.get("channel_coverage"),
                            "coverage_b": comparison.get("other_coverage"),
                        }
                    )
            continue
        rows.append(dict(value))
    return rows


def _canonical_similarity(similarities: object) -> dict[str, list[dict[str, Any]]]:
    """Deduplicate A-B/B-A rows while preserving coverage for each channel."""
    canonical: dict[tuple[str, str, str], dict[str, Any]] = {}
    for row in _similarity_rows(similarities):
        dimension = str(row.get("dimension", "")).removesuffix("_overlap")
        left = row.get("channel_a", row.get("left_channel"))
        right = row.get("channel_b", row.get("right_channel"))
        if dimension not in ACTIONABLE_DIMENSIONS or left is None or right is None:
            continue
        first, second = pair_key(left, right)
        if first == second:
            continue
        if str(left) == first:
            first_coverage, second_coverage = row.get("coverage_a"), row.get("coverage_b")
        else:
            first_coverage, second_coverage = row.get("coverage_b"), row.get("coverage_a")
        similarity = _similarity(row.get("similarity_0_1"))
        if similarity is None:
            continue
        item = {
            "left_channel": first,
            "right_channel": second,
            "similarity_0_1": similarity,
            "left_coverage": _decimal(first_coverage),
            "right_coverage": _decimal(second_coverage),
        }
        key = (dimension, first, second)
        existing = canonical.get(key)
        if existing is None or item["similarity_0_1"] > existing["similarity_0_1"]:
            canonical[key] = item
    grouped = {dimension: [] for dimension in ACTIONABLE_DIMENSIONS}
    for (dimension, _, _), row in sorted(canonical.items()):
        if (
            row["left_coverage"] >= MIN_DIMENSION_COVERAGE_PCT
            and row["right_coverage"] >= MIN_DIMENSION_COVERAGE_PCT
        ):
            grouped[dimension].append(row)
    return grouped


def _qualified_channel_rows(
    channel_index: Iterable[dict[str, Any]], *, selectable: bool
) -> dict[str, dict[str, Any]]:
    """Return ticket-qualified channels eligible for profile comparisons."""
    return {
        str(row.get("channel_name")): row
        for row in commercial_channels(channel_index, selectable=selectable)
        if int(row.get("paid_registrations", 0) or 0) >= MIN_PROFILE_REGISTRATIONS
    }


def _sample_status(row: Mapping[str, Any]) -> str:
    registrations = int(row.get("paid_registrations", 0) or 0)
    if registrations < MIN_PROFILE_REGISTRATIONS:
        return "evidência insuficiente"
    if registrations < 30:
        return "amostra reduzida"
    return "referência disponível"


def _combined_sample_status(*rows: Mapping[str, Any]) -> str:
    statuses = {_sample_status(row) for row in rows}
    if "evidência insuficiente" in statuses:
        return "evidência insuficiente"
    if "amostra reduzida" in statuses:
        return "amostra reduzida"
    return "referência disponível"


def _filter_grouped_pairs(
    grouped: dict[str, list[dict[str, Any]]], allowed_names: set[str]
) -> dict[str, list[dict[str, Any]]]:
    """Keep only pairs whose two endpoints belong to one qualified universe."""
    return {
        dimension: [
            row
            for row in grouped[dimension]
            if row["left_channel"] in allowed_names
            and row["right_channel"] in allowed_names
        ]
        for dimension in ACTIONABLE_DIMENSIONS
    }


def _dimension_benchmarks(
    grouped: dict[str, list[dict[str, Any]]]
) -> dict[str, dict[str, float | int | None]]:
    benchmarks: dict[str, dict[str, float | int | None]] = {}
    for dimension in ACTIONABLE_DIMENSIONS:
        rows = grouped[dimension]
        maxima: dict[str, float] = {}
        for row in rows:
            similarity = float(row["similarity_0_1"])
            for channel in (row["left_channel"], row["right_channel"]):
                maxima[channel] = max(maxima.get(channel, similarity), similarity)
        benchmarks[dimension] = {
            "eligible_pairs": len(rows),
            "p90_similarity_0_1": _linear_percentile(
                (row["similarity_0_1"] for row in rows), Decimal("90")
            ),
            "nearest_peer_p25_similarity_0_1": _linear_percentile(
                maxima.values(), Decimal("25")
            ),
        }
    return benchmarks


def nearest_peer_profiles(
    similarities: object, channel_index: Iterable[dict[str, Any]]
) -> dict[str, dict[str, dict[str, Any]]]:
    """Return a nearest peer per dimension without collapsing dimensions."""
    channel_rows = list(channel_index)
    candidate_rows = _qualified_channel_rows(channel_rows, selectable=True)
    references = _qualified_channel_rows(channel_rows, selectable=False)
    candidate_names = set(candidate_rows)
    reference_names = set(references)
    grouped = _canonical_similarity(similarities)
    benchmarks = _dimension_benchmarks(
        _filter_grouped_pairs(grouped, candidate_names)
    )
    profiles: dict[str, dict[str, dict[str, Any]]] = {
        channel: {} for channel in candidate_rows
    }
    for dimension in ACTIONABLE_DIMENSIONS:
        peers: dict[str, list[tuple[str, float]]] = {
            channel: [] for channel in candidate_rows
        }
        for row in grouped[dimension]:
            left, right = row["left_channel"], row["right_channel"]
            if left in reference_names and right in reference_names:
                similarity = float(row["similarity_0_1"])
                if left in candidate_names:
                    peers[left].append((right, similarity))
                if right in candidate_names:
                    peers[right].append((left, similarity))
        for channel, channel_row in candidate_rows.items():
            peer_candidates = peers[channel]
            if not peer_candidates:
                profiles[channel][dimension] = {
                    "status": "evidência insuficiente",
                    "channel_paid_registrations": int(
                        channel_row.get("paid_registrations", 0) or 0
                    ),
                    "channel_sample_status": _sample_status(channel_row),
                }
                continue
            nearest, similarity = sorted(
                peer_candidates, key=lambda item: (-item[1], item[0].casefold())
            )[0]
            nearest_row = references[nearest]
            profiles[channel][dimension] = {
                "status": _sample_status(channel_row),
                "channel_paid_registrations": int(
                    channel_row.get("paid_registrations", 0) or 0
                ),
                "channel_sample_status": _sample_status(channel_row),
                "nearest_channel": nearest,
                "nearest_channel_paid_registrations": int(
                    nearest_row.get("paid_registrations", 0) or 0
                ),
                "nearest_channel_sample_status": _sample_status(nearest_row),
                "similarity_0_1": round(similarity, 4),
                "p90_similarity_0_1": benchmarks[dimension]["p90_similarity_0_1"],
                "nearest_peer_p25_similarity_0_1": benchmarks[dimension][
                    "nearest_peer_p25_similarity_0_1"
                ],
            }
    return profiles


def redundancy_candidates(
    similarities: object, channel_index: Iterable[dict[str, Any]]
) -> list[dict[str, Any]]:
    """Return pairs with high descriptive similarity in four eligible dimensions."""
    channel_rows = list(channel_index)
    gross_by_channel = {
        str(row.get("channel_name")): _decimal(row.get("gross_value"))
        for row in channel_rows
    }
    candidates_by_name = _qualified_channel_rows(channel_rows, selectable=True)
    eligible = set(candidates_by_name)
    grouped = _canonical_similarity(similarities)
    grouped = _filter_grouped_pairs(grouped, eligible)
    benchmarks = _dimension_benchmarks(grouped)
    candidates: dict[tuple[str, str], list[tuple[str, float]]] = {}
    for dimension, rows in grouped.items():
        threshold = benchmarks[dimension]["p90_similarity_0_1"]
        if threshold is None:
            continue
        for row in rows:
            left, right = row["left_channel"], row["right_channel"]
            if left not in eligible or right not in eligible:
                continue
            similarity = float(row["similarity_0_1"])
            if similarity >= float(threshold):
                candidates.setdefault((left, right), []).append((dimension, similarity))
    results = []
    for (left, right), qualified in candidates.items():
        dimensions = sorted(dimension for dimension, _ in qualified)
        if len(dimensions) < 4 or not {"geography", "temporal"}.intersection(dimensions):
            continue
        results.append(
            {
                "left_channel": left,
                "right_channel": right,
                "qualifying_dimensions": dimensions,
                "qualifying_dimension_count": len(dimensions),
                "left_paid_registrations": int(
                    candidates_by_name[left].get("paid_registrations", 0) or 0
                ),
                "right_paid_registrations": int(
                    candidates_by_name[right].get("paid_registrations", 0) or 0
                ),
                "left_sample_status": _sample_status(candidates_by_name[left]),
                "right_sample_status": _sample_status(candidates_by_name[right]),
                "sample_status": _combined_sample_status(
                    candidates_by_name[left], candidates_by_name[right]
                ),
                "combined_gross_value": format(
                    gross_by_channel.get(left, Decimal("0.00"))
                    + gross_by_channel.get(right, Decimal("0.00")),
                    ".2f",
                ),
                "similarities": {
                    dimension: round(similarity, 4) for dimension, similarity in qualified
                },
            }
        )
    return sorted(
        results,
        key=lambda row: (
            -int(row["qualifying_dimension_count"]),
            -_decimal(row["combined_gross_value"]),
            str(row["left_channel"]).casefold(),
            str(row["right_channel"]).casefold(),
        ),
    )


def coverage_cube(
    registration_cube: Iterable[dict[str, Any]],
    channel_index: Iterable[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Project frozen registrations to the simulator's anonymous four-dimensional cube."""
    rows = list(registration_cube)
    selectable_names = {
        str(row.get("channel_name"))
        for row in commercial_channels(channel_index, selectable=True)
    }
    grouped: dict[tuple[str, str, str, str], dict[str, Any]] = {}
    totals: dict[tuple[str, str, str], dict[str, dict[str, Any]]] = {}

    def add(target: dict[str, Any], row: dict[str, Any]) -> None:
        registrations = int(row.get("paid_registrations", 0) or 0)
        target["paid_registrations"] += registrations
        for field in MONEY_FIELDS:
            value = row.get(field)
            if value is None:
                target["_money_complete"][field] = False
            else:
                target[field] += _decimal(value)

    def empty(dimensions: tuple[str, str, str, str]) -> dict[str, Any]:
        return {
            **dict(zip(SIMULATOR_DIMENSIONS, dimensions)),
            "paid_registrations": 0,
            **{field: Decimal("0.00") for field in MONEY_FIELDS},
            "_money_complete": {field: True for field in MONEY_FIELDS},
        }

    for row in rows:
        phase, modality, state, channel = (
            str(row.get(dimension, "Não informado")) for dimension in SIMULATOR_DIMENSIONS
        )
        key = (phase, modality, state, channel)
        target = grouped.setdefault(key, empty(key))
        add(target, row)
        cell_key = (phase, modality, state)
        cell_totals = totals.setdefault(cell_key, {})
        all_target = cell_totals.setdefault(
            SIMULATOR_TOTAL_ALL,
            empty((*cell_key, SIMULATOR_TOTAL_ALL)),
        )
        add(all_target, row)
        if channel in selectable_names:
            commercial_target = cell_totals.setdefault(
                SIMULATOR_TOTAL_COMMERCIAL,
                empty((*cell_key, SIMULATOR_TOTAL_COMMERCIAL)),
            )
            add(commercial_target, row)

    output = [*grouped.values()]
    for cell_key, cell_totals in totals.items():
        output.append(cell_totals[SIMULATOR_TOTAL_ALL])
        if SIMULATOR_TOTAL_COMMERCIAL in cell_totals:
            output.append(cell_totals[SIMULATOR_TOTAL_COMMERCIAL])
    projected = []
    for row in output:
        complete = row.pop("_money_complete")
        for field in MONEY_FIELDS:
            row[field] = format(row[field], ".2f") if complete[field] else None
        projected.append(row)
    return sorted(
        projected,
        key=lambda row: tuple(str(row[dimension]).casefold() for dimension in SIMULATOR_DIMENSIONS),
    )


def _channel_slug(channel_name: object) -> str:
    normalized = normalize_key(channel_name).lower().replace(" ", "-")
    return normalized or "nao-informado"


def _similarity_source(dossiers: object) -> object:
    if isinstance(dossiers, Mapping) and "similarities" in dossiers:
        return dossiers["similarities"]
    return dossiers


def _dependency_cells(
    cube: Iterable[dict[str, Any]], selectable_names: set[str]
) -> list[dict[str, Any]]:
    by_cell: dict[tuple[str, str, str], dict[str, dict[str, Any]]] = {}
    for row in cube:
        cell = tuple(str(row[dimension]) for dimension in SIMULATOR_DIMENSIONS[:3])
        by_cell.setdefault(cell, {})[str(row["channel_name"])] = row
    dependencies = []
    for cell, entries in by_cell.items():
        all_total = entries.get(SIMULATOR_TOTAL_ALL, {})
        commercial_total = entries.get(SIMULATOR_TOTAL_COMMERCIAL, {})
        for channel_name in selectable_names:
            selected = entries.get(channel_name)
            if not selected:
                continue
            exposure = classify_exposure(
                selected=int(selected.get("paid_registrations", 0) or 0),
                event_total=int(all_total.get("paid_registrations", 0) or 0),
                commercial_total=int(commercial_total.get("paid_registrations", 0) or 0),
            )
            if exposure is None:
                continue
            dependencies.append(
                {
                    "phase": cell[0],
                    "modality": cell[1],
                    "state": cell[2],
                    "channel_name": channel_name,
                    "paid_registrations": int(selected["paid_registrations"]),
                    "event_paid_registrations": int(all_total.get("paid_registrations", 0) or 0),
                    "commercial_paid_registrations": int(commercial_total.get("paid_registrations", 0) or 0),
                    "exposure": exposure,
                    "sample_status": (
                        "amostra celular reduzida"
                        if int(selected["paid_registrations"])
                        < EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS
                        else "amostra celular suficiente"
                    ),
                }
            )
    return sorted(
        dependencies,
        key=lambda row: (
            -int(row["paid_registrations"]),
            str(row["phase"]).casefold(),
            str(row["modality"]).casefold(),
            str(row["state"]).casefold(),
            str(row["channel_name"]).casefold(),
        ),
    )


def _dependency_sample_summary(
    dependencies: Iterable[dict[str, Any]],
) -> dict[str, int | str]:
    """Summarize the published dependency-cell sample without changing exposure."""
    rows = list(dependencies)
    reduced = [
        row
        for row in rows
        if int(row.get("paid_registrations", 0) or 0)
        < EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS
    ]
    published_registrations = sum(
        int(row.get("paid_registrations", 0) or 0) for row in rows
    )
    reduced_registrations = sum(
        int(row.get("paid_registrations", 0) or 0) for row in reduced
    )

    def share(numerator: int, denominator: int) -> str:
        if denominator <= 0:
            return "0.00"
        return format(Decimal(numerator) * 100 / Decimal(denominator), ".2f")

    return {
        "published_cells": len(rows),
        "published_cell_registrations": published_registrations,
        "reduced_cells": len(reduced),
        "reduced_cell_registrations": reduced_registrations,
        "reduced_cell_share_pct": share(len(reduced), len(rows)),
        "reduced_registration_share_pct": share(
            reduced_registrations, published_registrations
        ),
        "publishable_cell_minimum_registrations": MIN_PUBLISHABLE_CELL_REGISTRATIONS,
        "sufficient_cell_minimum_registrations": EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS,
    }


def _dimension_panels(
    peers: dict[str, dict[str, dict[str, Any]]],
    selectable: Iterable[dict[str, Any]],
    benchmarks: dict[str, dict[str, float | int | None]],
) -> dict[str, dict[str, Any]]:
    """Build separate four-group scale/differentiation panels per dimension."""
    selectable_rows = list(selectable)
    by_name = {str(row["channel_name"]): row for row in selectable_rows}
    scale_cutoff = _linear_percentile(
        (row.get("gross_value") for row in selectable_rows), Decimal("75")
    )
    scale_values = ("Escala alta", "Escala menor")
    differentiation_values = (
        "Mais diferenciado relativamente",
        "Semelhante aos pares",
    )
    panels: dict[str, dict[str, Any]] = {}
    for dimension in ACTIONABLE_DIMENSIONS:
        counts = {
            (scale, differentiation): 0
            for scale in scale_values
            for differentiation in differentiation_values
        }
        p25 = benchmarks[dimension]["nearest_peer_p25_similarity_0_1"]
        for channel_name, profile_by_dimension in peers.items():
            profile = profile_by_dimension.get(dimension, {})
            similarity = profile.get("similarity_0_1")
            row = by_name.get(channel_name)
            if row is None or similarity is None or p25 is None:
                continue
            scale = (
                "Escala alta"
                if scale_cutoff is not None
                and float(_decimal(row.get("gross_value"))) >= scale_cutoff
                else "Escala menor"
            )
            differentiation = (
                "Mais diferenciado relativamente"
                if float(similarity) <= float(p25)
                else "Semelhante aos pares"
            )
            counts[(scale, differentiation)] += 1
        top_channels = []
        for row in selectable_rows[:10]:
            channel_name = str(row["channel_name"])
            profile = peers.get(channel_name, {}).get(dimension, {})
            top_channels.append(
                {
                    "channel_name": channel_name,
                    "paid_registrations": int(row.get("paid_registrations", 0) or 0),
                    "gross_value": format(_decimal(row.get("gross_value")), ".2f"),
                    "status": profile.get("status", "evidência insuficiente"),
                    "nearest_channel": profile.get("nearest_channel"),
                    "similarity_0_1": profile.get("similarity_0_1"),
                }
            )
        panels[dimension] = {
            "benchmark": benchmarks[dimension],
            "scale_high_gross_value_cutoff": scale_cutoff,
            "quadrants": [
                {
                    "scale": scale,
                    "differentiation": differentiation,
                    "channels": counts[(scale, differentiation)],
                }
                for scale in scale_values
                for differentiation in differentiation_values
            ],
            "top_channels": top_channels,
            "nearest_peers": {
                channel: profile[dimension]
                for channel, profile in peers.items()
            },
        }
    return panels


def build_portfolio_artifacts(
    *,
    overview: dict[str, Any],
    channel_index: Iterable[dict[str, Any]],
    dossiers: object,
    registration_cube: Iterable[dict[str, Any]],
    generated_at: str,
) -> dict[str, dict]:
    """Build separate static and simulator payloads from frozen MIF artifacts."""
    channels = [dict(row) for row in channel_index]
    similarities = _similarity_source(dossiers)
    grouped = _canonical_similarity(similarities)
    benchmark_names = set(_qualified_channel_rows(channels, selectable=True))
    benchmarks = _dimension_benchmarks(
        _filter_grouped_pairs(grouped, benchmark_names)
    )
    peers = nearest_peer_profiles(similarities, channels)
    redundancy = redundancy_candidates(similarities, channels)
    selectable = commercial_channels(channels, selectable=True)
    selectable_names = {str(row["channel_name"]) for row in selectable}
    cube = coverage_cube(registration_cube, channels)
    dependencies = _dependency_cells(cube, selectable_names)
    selectable_payload = [
        {
            "channel_name": str(row["channel_name"]),
            "slug": _channel_slug(row["channel_name"]),
            "channel_type": str(row.get("channel_type", "Não informado")),
            "paid_registrations": int(row.get("paid_registrations", 0) or 0),
            "gross_value": format(_decimal(row.get("gross_value")), ".2f"),
            "registration_ticket": format(
                _decimal(row.get("registration_ticket")), ".2f"
            ),
        }
        for row in selectable
    ]
    slugs = [row["slug"] for row in selectable_payload]
    if len(slugs) != len(set(slugs)):
        raise ValueError("selectable portfolio channel slugs are not unique")
    metadata = {
        "generated_at": generated_at,
        "transform_version": PORTFOLIO_TRANSFORM_VERSION,
    }
    dimension_panels = _dimension_panels(peers, selectable, benchmarks)
    takeaways = [
        {
            "title": "Semelhanças permanecem dimensionais",
            "evidence": "Geografia, modalidade, temporalidade, lote e produto são apresentados separadamente, sem score mestre.",
        },
        {
            "title": "Exposição observada usa dois denominadores",
            "evidence": "As células com exposição usam o total do evento e o total comercial não orgânico da própria célula.",
        },
    ]
    summary = {
        "meta": metadata,
        "definitions": {
            "commercial_universe": "Canais com ticket por inscrição acima de R$ 10,00; orgânico permanece como referência e denominador.",
            "selectable_universe": "Canais comerciais não orgânicos; orgânico não é selecionável.",
            "similarity": "Semelhanças são descritivas e separadas por dimensão. Os benchmarks p25/p90 usam pares entre canais comerciais não orgânicos com ticket por inscrição acima de R$ 10,00, pelo menos 10 inscrições e cobertura mínima de 70,00% em ambos os canais; orgânico não integra esses benchmarks.",
            "dependency_sample": "Células publicadas com 5–9 inscrições do canal são qualificadas como amostra celular reduzida; a partir de 10 inscrições, como amostra celular suficiente. A classificação de exposição e seus denominadores permanecem inalterados.",
            "product_scope": "Apenas a classificação kit_incluso é excluída do perfil de produto.",
        },
        "overview": dict(overview),
        "dimension_benchmarks": benchmarks,
        "dimension_panels": dimension_panels,
        "redundancy_candidates": redundancy[:10],
        "dependency_cells": dependencies,
        "dependency_sample_summary": _dependency_sample_summary(dependencies),
        "executive_takeaways": takeaways,
    }
    simulator = {
        "meta": metadata,
        "dimensions": list(SIMULATOR_DIMENSIONS),
        "thresholds": {
            "commercial_ticket_min_exclusive": format(COMMERCIAL_TICKET_MIN, ".2f"),
            "minimum_profile_registrations": MIN_PROFILE_REGISTRATIONS,
            "minimum_dimension_coverage_pct": format(
                MIN_DIMENSION_COVERAGE_PCT, ".2f"
            ),
            "maximum_selected_channels": 10,
            "publishable_cell_minimum_registrations": MIN_PUBLISHABLE_CELL_REGISTRATIONS,
            "exposure_classification_minimum_registrations": EXPOSURE_CLASSIFICATION_MINIMUM_REGISTRATIONS,
            "exposure_high_event_share_pct": format(
                EXPOSURE_HIGH_EVENT_SHARE_PCT, ".2f"
            ),
            "exposure_medium_event_share_pct": format(
                EXPOSURE_MEDIUM_EVENT_SHARE_PCT, ".2f"
            ),
            "exposure_partner_concentration_pct": format(
                EXPOSURE_PARTNER_CONCENTRATION_PCT, ".2f"
            ),
        },
        "selectable_channels": selectable_payload,
        "coverage_cube": cube,
    }
    return {
        "portfolio/summary.json": summary,
        "portfolio/simulator.json": simulator,
    }
