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

_ORDER_ONLY_QUERIES = frozenset({"payment_mix", "device_mix"})
_QUERY_DEFINITIONS = {
    "weekly_sales": ("Inscrições pagas por semana", "Contagem de inscrições vinculadas a pedidos pagos, agrupada pela semana da venda."),
    "lot_performance": ("Inscrições e valores por lote", "Contagem de inscrições vinculadas a pedidos pagos e valores de pedido alocados, agrupados por lote."),
    "modality_mix": ("Inscrições pagas por modalidade", "Contagem de inscrições vinculadas a pedidos pagos, agrupada por modalidade."),
    "country_distribution": ("Inscrições pagas por país", "Contagem de inscrições vinculadas a pedidos pagos, com denominador explícito, agrupada por país."),
    "state_distribution": ("Inscrições pagas por UF", "Contagem de inscrições vinculadas a pedidos pagos, com denominador explícito, agrupada por UF."),
    "city_distribution": ("Inscrições pagas por cidade", "Contagem de inscrições vinculadas a pedidos pagos, com denominador explícito, agrupada por cidade."),
    "age_bands": ("Inscrições pagas por faixa etária", "Contagem de inscrições vinculadas a pedidos pagos, com cobertura explícita, agrupada por faixa etária."),
    "gender_distribution": ("Inscrições pagas por gênero", "Contagem de inscrições vinculadas a pedidos pagos, com cobertura explícita, agrupada por gênero informado."),
    "pace_bands": ("Inscrições pagas por faixa de ritmo", "Contagem de inscrições vinculadas a pedidos pagos, com cobertura explícita, agrupada por faixa de ritmo."),
    "club_coverage": ("Cobertura de clube ou assessoria", "Contagem válida, ausente e total entre inscrições vinculadas a pedidos pagos."),
    "payment_mix": ("Pedidos pagos por meio de pagamento", "Contagem de pedidos pagos únicos, agrupada pelo meio de pagamento normalizado."),
    "device_mix": ("Pedidos pagos por dispositivo", "Contagem de pedidos pagos únicos, agrupada pelo dispositivo normalizado."),
    "auxiliary_field_coverage": ("Cobertura de campos auxiliares", "Contagens válidas, inválidas e ausentes entre inscrições vinculadas a pedidos pagos."),
    "product_summary": ("Adoção de produtos", "Contagem de inscrições pagas com produto mapeado; adoção usa a base paga coberta como denominador e receita apenas valores explícitos."),
    "channel_index": ("Inscrições e valores alocados por canal", "Contagem de inscrições pagas, pedidos tocados não aditivos e valores de pedido alocados por canal revisado."),
    "channel_aliases": ("Aliases observados por canal", "Contagem de inscrições pagas por identidade de origem e canal canônico revisado."),
    "channel_modality_mix": ("Modalidade por canal", "Contagem de inscrições pagas por canal e modalidade, com denominador do canal."),
    "channel_state_mix": ("UF por canal", "Contagem de inscrições pagas por canal e UF, com cobertura e denominador do canal."),
    "channel_lot_mix": ("Lote por canal", "Contagem de inscrições pagas e valores de pedido alocados por canal e lote."),
    "channel_weekly_sales": ("Semana por canal", "Contagem de inscrições pagas e valores de pedido alocados por canal e semana da venda."),
    "channel_product_mix": ("Produtos por canal", "Contagem de inscrições pagas com produto mapeado por canal; receita inclui somente valores explícitos."),
    "channel_profile_coverage": ("Cobertura de perfil por canal", "Contagens válidas e ausentes de perfil na base de inscrições pagas de cada canal."),
    "geography_overlap": ("Sobreposição geográfica", "Semelhança descritiva entre distribuições geográficas de inscrições pagas, com cobertura separada por canal."),
    "modality_overlap": ("Sobreposição de modalidade", "Semelhança descritiva entre distribuições de modalidade de inscrições pagas, com bases separadas."),
    "lot_overlap": ("Sobreposição de lote", "Semelhança descritiva entre distribuições de lote de inscrições pagas, com bases separadas."),
    "temporal_overlap": ("Sobreposição temporal", "Semelhança descritiva entre distribuições semanais de inscrições pagas, com bases separadas."),
    "profile_overlap": ("Sobreposição de perfil", "Semelhança descritiva por dimensão de perfil entre inscrições pagas, mantendo cobertura separada."),
    "product_overlap": ("Sobreposição de produtos", "Semelhança descritiva entre adoção de produtos na base paga coberta de cada canal."),
    "long_tail": ("Canais de base reduzida", "Contagem de inscrições pagas e valores de pedido alocados para canais abaixo do limite de dossiê completo."),
    "data_quality": ("Qualidade e cobertura", "Contagens válidas, inválidas e ausentes nos grãos de pedido pago e inscrição paga."),
}


def _component_id(query_id: str) -> str:
    return f"mif-{query_id.replace('_', '-')}"


def _channel_slug(channel_name: object) -> str:
    return normalize_key(channel_name).lower().replace(" ", "-")


def _component_ids(query_id: str, result: AnalysisResult) -> list[str]:
    full_channels = [
        row
        for row in result.datasets["channel_index"]
        if row.get("dossier_type") == "full"
    ]
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
                f"mif-dossier-{_channel_slug(channel['channel_name'])}-summary"
                for channel in full_channels
            ],
        ]
    if query_id == "product_summary":
        return ["mif-product-summary-chart", "mif-product-summary"]
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
        component_ids = [
            f"mif-dossier-{_channel_slug(channel['channel_name'])}-{suffix}"
            for channel in full_channels
        ]
        if query_id == "channel_state_mix":
            visible_channels = {
                row["channel_name"]
                for row in result.datasets["channel_state_mix"]
                if row.get("coverage", {}).get("valid_coverage_pct", 0) >= 70
            }
            component_ids = [
                component_id
                for component_id, channel in zip(component_ids, full_channels)
                if channel["channel_name"] in visible_channels
            ]
        return component_ids
    return [_component_id(query_id)]


def report_component_map(result: AnalysisResult) -> dict[str, list[str]]:
    """Return exact deterministic component IDs mounted for each report query."""
    return {query_id: _component_ids(query_id, result) for query_id in DATASET_IDS}


def report_component_catalog(result: AnalysisResult) -> list[str]:
    """Return the flat deterministic component catalog mounted by ReportContent."""
    return sorted(
        {
            component_id
            for component_ids in report_component_map(result).values()
            for component_id in component_ids
        }
    )


def _tables(query_id: str) -> list[str]:
    orders = "public.tb_ticketsports_pedidos"
    participants = "public.tb_ticketsports_participantes"
    if query_id in _ORDER_ONLY_QUERIES:
        return [orders]
    return [orders, participants]


def _aggregate_sql(tables: list[str]) -> str:
    selects = [
        (
            "SELECT cod_evento, COUNT(*) AS source_rows "
            f"FROM {table} WHERE cod_evento = {EVENT_CODE} GROUP BY cod_evento"
        )
        for table in tables
    ]
    return " UNION ALL ".join(selects)


def build_source_metadata(
    query_id: str, generated_at: str, component_ids: list[str]
) -> dict[str, Any]:
    """Build the exact query provenance contract used by analyze and verify."""
    tables = _tables(query_id)
    if query_id == "event_overview":
        orders = ["public.tb_ticketsports_pedidos"]
        both = [*tables]
        definitions = [
            {
                "label": "Visão reconciliada do evento",
                "definition": "Pedidos pagos únicos, inscrições vinculadas, soma do valor bruto e ticket por inscrição, mantidos em grãos separados.",
                "componentIds": ["mif-event-overview"],
                "sourceLineage": [{"tables": both}],
            },
            {
                "label": "Pedidos pagos",
                "definition": "Contagem de pedidos pagos únicos do evento.",
                "componentIds": ["mif-overview-orders"],
                "sourceLineage": [{"tables": orders}],
            },
            {
                "label": "Inscrições pagas",
                "definition": "Contagem de inscrições vinculadas a pedidos pagos do evento.",
                "componentIds": ["mif-overview-registrations"],
                "sourceLineage": [{"tables": both}],
            },
            {
                "label": "Valor bruto",
                "definition": "Soma do valor bruto dos pedidos pagos únicos do evento.",
                "componentIds": ["mif-overview-gross"],
                "sourceLineage": [{"tables": orders}],
            },
            {
                "label": "Ticket por inscrição",
                "definition": "Soma do valor bruto dos pedidos pagos dividida pela contagem de inscrições vinculadas.",
                "componentIds": ["mif-overview-ticket"],
                "sourceLineage": [{"tables": both}],
            },
        ]
    else:
        label, definition = _QUERY_DEFINITIONS[query_id]
        definitions = [
            {
                "label": label,
                "definition": definition,
                "componentIds": component_ids,
                "sourceLineage": [{"tables": tables}],
            }
        ]
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
        "metricDefinitions": definitions,
        "evidenceFlow": [
            "Exportações sintéticas locais filtradas pelo evento 72611",
            "Fatos reconciliados e mapeamentos explicitamente revisados",
            "Agregação, supressão de células pequenas e varredura de anonimidade",
            f"Query revisada {query_id} no snapshot canônico",
        ],
    }


def _source(
    query_id: str, generated_at: str, result: AnalysisResult
) -> dict[str, Any]:
    return build_source_metadata(
        query_id,
        generated_at,
        _component_ids(query_id, result),
    )


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
        "componentCatalog": report_component_catalog(result),
        "packageInfo": {
            "eventCode": EVENT_CODE,
            "pipelineVersion": PIPELINE_VERSION,
            "fullDossierMinRegistrations": FULL_DOSSIER_MIN_REGISTRATIONS,
            "smallCellMinRegistrations": SMALL_CELL_MIN_REGISTRATIONS,
        },
    }
