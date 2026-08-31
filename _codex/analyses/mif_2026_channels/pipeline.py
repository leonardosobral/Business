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
from .narrative import build_decision_questions, describe_channel, describe_event
from .privacy import assert_anonymous, protect_analysis
from .source import load_sources


CHART_RATIONALES = {
    "weekly_sales": "line: chronological change and closing-period acceleration",
    "modality_mix": "stacked bar: comparable composition across channels",
    "country_distribution": "horizontal bar: ranked observed country reach",
    "state_distribution": "horizontal bar: ranked categorical concentration",
    "channel_distribution": "horizontal bar: exact volume and event share without a desirability score",
    "lot_performance": "stacked bar: volume and ticket by ordered lot",
    "product_summary": "horizontal bar: add-on take rate by canonical product",
    "dimension_overlaps": "table: exact pairwise evidence without visual rank implication",
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


def sanitize_shareable_html(index_path: Path, shareable_path: Path) -> None:
    """Create a standalone HTML copy without local task/session identity."""
    original = index_path.read_text(encoding="utf-8")
    task_ids = _LOCAL_THREAD_META.findall(original)
    sanitized = _LOCAL_THREAD_META.sub("", original)
    sanitized = _TASK_DEEP_LINK.sub("codex://threads/new", sanitized)
    for task_id in task_ids:
        sanitized = sanitized.replace(task_id, "")
    shareable_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = shareable_path.with_suffix(shareable_path.suffix + ".tmp")
    temporary.write_text(sanitized, encoding="utf-8")
    temporary.replace(shareable_path)


def _source_notes(result, sources) -> dict[str, Any]:
    notes = deepcopy(result.source_notes)
    notes["chart_rationales"] = CHART_RATIONALES
    notes["narrative"] = {
        "event": describe_event(result),
        "channels": {
            dossier["channel_name"]: describe_channel(dossier, result.overview)
            for dossier in result.full_dossiers
        },
        "decision_questions": build_decision_questions(result),
    }
    notes["fixture_status"] = (
        "Fixture sintética de desenvolvimento; a Task 8 substituirá os dados e mapeamentos."
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
    notes = _source_notes(result, sources)
    result = dataclasses.replace(result, source_notes=notes)

    aggregate_payload = dataclasses.asdict(result)
    reconciliation_payload = deepcopy(mapped.reconciliation)
    generated_at = max(snapshot.extracted_at for snapshot in sources.snapshots)
    report_payload = build_report_snapshot(result, generated_at)

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
