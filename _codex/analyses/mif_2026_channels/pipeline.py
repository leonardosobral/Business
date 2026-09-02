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
from .crossings import build_product_cube, build_registration_cube
from .facts import build_fact_bundle
from .mappings import (
    apply_reviewed_mappings,
    load_channel_mapping,
    load_product_mapping,
)
from .metrics import build_analysis
from .models import AnalysisResult, FactBundle, SourceBundle
from .modular_artifact import build_modular_artifacts, write_modular_artifacts
from .narrative import build_decision_questions, describe_event
from .phases import build_sale_cycle_boundaries, effective_sale_dates
from .privacy import assert_anonymous, protect_analysis
from .source import load_sources, resolve_report_generated_at


CHART_RATIONALES = {
    "weekly_sales": "line: chronological change and closing-period acceleration",
    "modality_mix": "stacked bar: comparable composition across channels",
    "country_distribution": "horizontal bar: observed country volume with explicit base",
    "state_distribution": "horizontal bar: observed state volume with explicit base",
    "channel_distribution": "table: exact channel volume and event share ordered by allocated gross value, paid registrations, and channel name",
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


@dataclasses.dataclass(frozen=True)
class AnalysisContext:
    """Reusable reconciled state shared by monolithic and modular writers."""

    sources: SourceBundle
    mapped_facts: FactBundle
    result: AnalysisResult
    snapshot_status: str


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


def build_analysis_context(
    orders_path: Path,
    participants_path: Path,
    channel_mapping_path: Path,
    product_mapping_path: Path,
    *,
    allow_stale: bool = False,
) -> AnalysisContext:
    """Load, reconcile, map and protect the source data exactly once."""
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
    return AnalysisContext(
        sources=sources,
        mapped_facts=mapped,
        result=result,
        snapshot_status=snapshot_status,
    )


def run_analysis(
    orders_path: Path,
    participants_path: Path,
    channel_mapping_path: Path,
    product_mapping_path: Path,
    output_dir: Path,
    allow_stale: bool = False,
) -> dict[str, Path]:
    """Run source-to-report analysis and write only anonymous reviewed outputs."""
    context = build_analysis_context(
        orders_path,
        participants_path,
        channel_mapping_path,
        product_mapping_path,
        allow_stale=allow_stale,
    )
    sources = context.sources
    mapped = context.mapped_facts
    result = context.result
    snapshot_status = context.snapshot_status
    notes = result.source_notes

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


def run_modular_analysis(
    orders_path: Path,
    participants_path: Path,
    channel_mapping_path: Path,
    product_mapping_path: Path,
    output_dir: Path,
    allow_stale: bool = False,
) -> dict[str, Path]:
    """Build the reconciled facts once and emit independently cacheable bundles."""
    context = build_analysis_context(
        orders_path,
        participants_path,
        channel_mapping_path,
        product_mapping_path,
        allow_stale=allow_stale,
    )
    sale_dates = effective_sale_dates(context.mapped_facts.registrations)
    boundaries = build_sale_cycle_boundaries(sale_dates)
    registration_cube = build_registration_cube(context.mapped_facts, boundaries)
    product_cube = build_product_cube(context.mapped_facts, boundaries)
    generated_at = resolve_report_generated_at(context.sources.snapshots)
    artifacts = build_modular_artifacts(
        context.result,
        registration_cube,
        product_cube,
        context.sources.source_hashes,
        generated_at=generated_at,
        cycle_boundaries={
            "start": boundaries.start.date().isoformat(),
            "launch_end": boundaries.launch_end.date().isoformat(),
            "early_end": boundaries.early_end.date().isoformat(),
            "middle_end": boundaries.middle_end.date().isoformat(),
            "final_sprint_end": boundaries.final_sprint_end.date().isoformat(),
            "end": boundaries.end.date().isoformat(),
        },
    )
    return write_modular_artifacts(output_dir, artifacts)
