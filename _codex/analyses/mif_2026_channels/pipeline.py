"""Reproducible end-to-end pipeline for the canonical MIF report app."""

from __future__ import annotations

import dataclasses
from copy import deepcopy
import json
from pathlib import Path
import re
from typing import Any

from .artifact import build_report_snapshot
from .config import EVENT_CODE
from .facts import build_fact_bundle
from .mappings import (
    apply_reviewed_mappings,
    load_channel_mapping,
    load_product_mapping,
)
from .metrics import build_analysis
from .narrative import build_decision_questions, describe_event
from .privacy import assert_anonymous, protect_analysis
from .source import load_sources, resolve_report_generated_at


CHART_RATIONALES = {
    "weekly_sales": "line: chronological change and closing-period acceleration",
    "modality_mix": "stacked bar: comparable composition across channels",
    "country_distribution": "horizontal bar: observed country volume with explicit base",
    "state_distribution": "horizontal bar: observed state volume with explicit base",
    "channel_distribution": "table: exact channel volume and event share in alphabetical index",
    "lot_performance": "stacked bar: volume and ticket by ordered lot",
    "product_summary": "horizontal bar: add-on take rate by canonical product",
    "dimension_overlaps": "table: exact pairwise evidence kept separate by dimension",
}

_LOCAL_THREAD_META = re.compile(
    r'<meta\s+name=["\']data-app-local-thread["\']\s+'
    r'content=["\']([0-9a-fA-F-]{36})["\']\s*/?>\s*'
)
_TASK_DEEP_LINK = re.compile(
    r"codex://threads/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(?=\?)"
)


def write_json(path: Path, payload: Any) -> None:
    """Serialize deterministically and atomically replace ``path``."""
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(serialized + "\n", encoding="utf-8")
    temporary.replace(path)


def _normalize_html_text(value: str) -> str:
    """Remove trailing whitespace and retain exactly one final newline."""
    return "\n".join(line.rstrip(" \t") for line in value.splitlines()).rstrip("\n") + "\n"


def _write_text_atomically(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value, encoding="utf-8")
    temporary.replace(path)


def sanitize_shareable_html(index_path: Path, shareable_path: Path) -> None:
    """Normalize the build and create a copy without local task/session identity."""
    original = _normalize_html_text(index_path.read_text(encoding="utf-8"))
    _write_text_atomically(index_path, original)
    task_ids = _LOCAL_THREAD_META.findall(original)
    sanitized = _LOCAL_THREAD_META.sub("", original)
    sanitized = _TASK_DEEP_LINK.sub("codex://threads/new", sanitized)
    for task_id in task_ids:
        sanitized = sanitized.replace(task_id, "")
    _write_text_atomically(shareable_path, _normalize_html_text(sanitized))


def source_qualification(status: str) -> str:
    """Return the exact receipt qualification for the requested snapshot status."""
    if status == "fixture":
        return (
            "Fixture sintética de desenvolvimento; a Task 8 substituirá os dados e mapeamentos."
        )
    if status == "ready":
        return (
            "Fontes frescas finais após o encerramento das inscrições; "
            "mapeamentos completos revisados e saída anônima."
        )
    raise ValueError(f"unsupported report snapshot status: {status}")


def _source_notes(result, sources, status: str) -> dict[str, Any]:
    notes = deepcopy(result.source_notes)
    notes["chart_rationales"] = CHART_RATIONALES
    notes["narrative"] = {
        "event": describe_event(result),
        "channels": {
            dossier["channel_name"]: dossier["executive_summary"]
            for dossier in result.full_dossiers
        },
        "compact_channels": {
            dossier["channel_name"]: dossier["executive_highlight"]
            for dossier in result.long_tail
        },
        "executive_summary": result.datasets["roadrunners_capstone"][0]["executive_summary"],
        "roadrunners_capstone": result.datasets["roadrunners_capstone"][0]["capstone_markdown"],
        "decision_questions": build_decision_questions(result),
    }
    qualification = source_qualification(status)
    notes["source_qualification"] = qualification
    if status == "fixture":
        notes["fixture_status"] = qualification
    else:
        notes.pop("fixture_status", None)
    notes["similarity"] = (
        "seis dimensões independentes; nenhuma avaliação consolidada ou decisão automática"
    )
    notes["sources"] = [
        {
            "source_id": snapshot.source_id,
            "file_name": snapshot.path.name,
            "sha256": snapshot.sha256,
            "row_count": snapshot.row_count,
            "extracted_at": snapshot.extracted_at,
            "event_code": snapshot.event_code,
        }
        for snapshot in sources.snapshots
    ]
    return notes


def run_analysis(
    orders_path: Path,
    participants_path: Path,
    channel_mapping_path: Path,
    product_mapping_path: Path,
    output_dir: Path,
    allow_stale: bool = False,
) -> dict[str, Path]:
    """Run source-to-report analysis and write only anonymous reviewed outputs."""
    sources = load_sources(
        orders_path, participants_path, EVENT_CODE, allow_stale=allow_stale
    )
    facts = build_fact_bundle(sources)
    mapped = apply_reviewed_mappings(
        facts,
        load_channel_mapping(channel_mapping_path),
        load_product_mapping(product_mapping_path),
    )
    result = protect_analysis(build_analysis(mapped))
    snapshot_status = "fixture" if allow_stale else "ready"
    notes = _source_notes(result, sources, snapshot_status)
    result = dataclasses.replace(result, source_notes=notes)

    aggregate_payload = dataclasses.asdict(result)
    reconciliation_payload = deepcopy(mapped.reconciliation)
    generated_at = resolve_report_generated_at(sources.snapshots)
    report_payload = build_report_snapshot(
        result,
        generated_at,
        status=snapshot_status,
    )

    for payload in (
        aggregate_payload,
        reconciliation_payload,
        notes,
        report_payload,
    ):
        assert_anonymous(payload)

    paths = {
        "report_data": output_dir / "src" / "data.json",
        "aggregates": output_dir / "aggregates.json",
        "reconciliation": output_dir / "reconciliation.json",
        "source_notes": output_dir / "source_notes.json",
    }
    write_json(paths["report_data"], report_payload)
    write_json(paths["aggregates"], aggregate_payload)
    write_json(paths["reconciliation"], reconciliation_payload)
    write_json(paths["source_notes"], notes)
    return paths
