"""Deterministic builder for the canonical MIF report Data App snapshot."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from .config import (
    EVENT_CODE,
    FULL_DOSSIER_MIN_REGISTRATIONS,
    PIPELINE_VERSION,
    SMALL_CELL_MIN_REGISTRATIONS,
)
from .metrics import DATASET_IDS
from .models import AnalysisResult
from .normalize import normalize_key


REPORT_APP_ID = "4551d11e-c315-4402-be71-218fa11e3148"
REPORT_TITLE = "Maratona de Floripa 2026 — estudo de vendas e canais"

_ORDER_QUERIES = frozenset({"event_overview", "payment_mix", "device_mix"})
_BOTH_SOURCE_QUERIES = frozenset(
    {
        "event_overview",
        "channel_index",
        "channel_weekly_sales",
        "channel_lot_mix",
        "channel_product_mix",
        "long_tail",
        "data_quality",
    }
)


def _component_id(query_id: str) -> str:
    return f"mif-{query_id.replace('_', '-')}"


def _channel_slug(channel_name: object) -> str:
    return normalize_key(channel_name).lower().replace(" ", "-")


def _component_ids(query_id: str, result: AnalysisResult) -> list[str]:
    if query_id == "event_overview":
        return [
            "mif-event-overview",
            "mif-overview-orders",
            "mif-overview-registrations",
            "mif-overview-gross",
            "mif-overview-ticket",
        ]
    if query_id == "channel_index":
        return [
            "mif-channel-index",
            *[
                f"mif-dossier-{_channel_slug(dossier['channel_name'])}-summary"
                for dossier in result.full_dossiers
            ],
        ]
    dossier_suffixes = {
        "channel_modality_mix": "modality",
        "channel_lot_mix": "lot",
        "channel_state_mix": "state",
        "channel_weekly_sales": "weekly",
        "channel_product_mix": "product",
        "channel_profile_coverage": "profile",
    }
    suffix = dossier_suffixes.get(query_id)
    if suffix:
        return [
            f"mif-dossier-{_channel_slug(dossier['channel_name'])}-{suffix}"
            for dossier in result.full_dossiers
        ] or [_component_id(query_id)]
    return [_component_id(query_id)]


def _tables(query_id: str) -> list[str]:
    orders = "public.tb_ticketsports_pedidos"
    participants = "public.tb_ticketsports_participantes"
    if query_id in _BOTH_SOURCE_QUERIES:
        return [orders, participants]
    if query_id in _ORDER_QUERIES:
        return [orders]
    return [participants]


def _aggregate_sql(tables: list[str]) -> str:
    selects = [
        (
            "SELECT cod_evento, COUNT(*) AS source_rows "
            f"FROM {table} WHERE cod_evento = {EVENT_CODE} GROUP BY cod_evento"
        )
        for table in tables
    ]
    return " UNION ALL ".join(selects)


def _source(
    query_id: str, generated_at: str, result: AnalysisResult
) -> dict[str, Any]:
    tables = _tables(query_id)
    return {
        "label": (
            "Fixture sintética revisada: agregados de inscrições pagas "
            f"para {query_id}"
        ),
        "sql": _aggregate_sql(tables),
        "tables": tables,
        "filters": [
            f"cod_evento = {EVENT_CODE}",
            "status normalizado = pago",
            "Task 7 usa somente fixture sintética de desenvolvimento",
        ],
        "freshness": generated_at,
        "metricDefinitions": [
            {
                "label": f"Agregado revisado — {query_id}",
                "definition": (
                    "Linhas agregadas e anônimas da fixture sintética, calculadas "
                    "sobre inscrições pagas; bases e denominadores permanecem nos campos revisados."
                ),
                "componentIds": _component_ids(query_id, result),
                "sourceLineage": [{"tables": tables}],
            }
        ],
        "evidenceFlow": [
            "Exportações sintéticas locais filtradas pelo evento 72611",
            "Fatos reconciliados e mapeamentos explicitamente revisados",
            "Agregação, supressão de células pequenas e varredura de anonimidade",
            f"Query revisada {query_id} no snapshot canônico",
        ],
    }


def build_report_snapshot(
    result: AnalysisResult,
    generated_at: str,
) -> dict[str, Any]:
    """Build the sole canonical ``src/data.json`` report snapshot."""
    if set(result.datasets) != set(DATASET_IDS):
        raise ValueError("analysis datasets do not match the 31-query contract")
    queries = {
        query_id: {
            "rows": deepcopy(result.datasets[query_id]),
            "source": _source(query_id, generated_at, result),
        }
        for query_id in DATASET_IDS
    }
    return {
        "id": REPORT_APP_ID,
        "title": REPORT_TITLE,
        "surface": "report",
        "generatedAt": generated_at,
        "status": "fixture",
        "filters": [],
        "report": {
            "fixtureQualification": (
                "Fixture sintética de desenvolvimento; não representa o resultado final de 2026."
            )
        },
        "queries": queries,
        "packageInfo": {
            "eventCode": EVENT_CODE,
            "pipelineVersion": PIPELINE_VERSION,
            "fullDossierMinRegistrations": FULL_DOSSIER_MIN_REGISTRATIONS,
            "smallCellMinRegistrations": SMALL_CELL_MIN_REGISTRATIONS,
        },
    }
