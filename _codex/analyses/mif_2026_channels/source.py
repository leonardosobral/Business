"""Read and trace fresh, event-scoped TicketSports source exports."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path

import pandas as pd

from .models import SourceBundle, SourceSnapshot


FINAL_EXTRACTION_MIN_TIMESTAMP = datetime(
    2026, 8, 30, tzinfo=timezone(timedelta(hours=-3))
)
_SOURCE_SPECS = (
    ("orders", "numero_pedido", "public.tb_ticketsports_pedidos"),
    ("participants", "numero_inscricao", "public.tb_ticketsports_participantes"),
)
_SOURCE_REQUIRED_COLUMNS = {
    "orders": frozenset({"cod_evento", "numero_pedido", "data_pedido", "body"}),
    "participants": frozenset({"cod_evento", "numero_inscricao", "numero_pedido", "body"}),
}
_STALE_EXTRACTION_MARKER = "not_provided_allow_stale"


def read_export(path: Path, required_columns: frozenset[str]) -> pd.DataFrame:
    """Read a CSV or XLSX export and require its declared source columns."""
    readers = {".csv": pd.read_csv, ".xlsx": pd.read_excel}
    reader = readers.get(path.suffix.lower())
    if reader is None:
        raise ValueError(f"unsupported export format: {path.suffix}")
    frame = reader(path, dtype=object)
    missing = sorted(required_columns - set(frame.columns))
    if missing:
        raise ValueError(f"missing required columns: {', '.join(missing)}")
    return frame


def load_sources(
    orders_path: Path,
    participants_path: Path,
    event_code: int,
    allow_stale: bool,
) -> SourceBundle:
    """Load, filter, hash, and freshness-check the two required source exports."""
    source_inputs = (("orders", orders_path), ("participants", participants_path))
    frames: dict[str, pd.DataFrame] = {}
    snapshots: list[SourceSnapshot] = []

    for source_id, path in source_inputs:
        required_columns = _SOURCE_REQUIRED_COLUMNS[source_id]
        if not allow_stale:
            required_columns = required_columns | frozenset({"extracted_at"})

        frame = read_export(path, required_columns)
        filtered = _filter_event(frame, event_code, source_id)
        extracted_at = _extraction_timestamp(filtered, source_id, allow_stale)
        frames[source_id] = filtered
        snapshots.append(
            SourceSnapshot(
                source_id=source_id,
                path=path,
                sha256=_sha256(path),
                row_count=len(filtered),
                extracted_at=extracted_at,
                event_code=event_code,
            )
        )

    source_hashes = {snapshot.source_id: snapshot.sha256 for snapshot in snapshots}
    return SourceBundle(
        event_code=event_code,
        orders=frames["orders"],
        participants=frames["participants"],
        snapshots=(snapshots[0], snapshots[1]),
        source_hashes=source_hashes,
    )


def write_source_manifest(bundle: SourceBundle, output_path: Path) -> None:
    """Write source traceability metadata without serializing any raw rows."""
    sources = []
    for snapshot in bundle.snapshots:
        _, table_name = _source_details(snapshot.source_id)
        sources.append(
            {
                "file_name": snapshot.path.name,
                "sha256": snapshot.sha256,
                "row_count": snapshot.row_count,
                "extracted_at": snapshot.extracted_at,
                "event_code": snapshot.event_code,
                "table_name": table_name,
                "query_predicate": f"cod_evento = {bundle.event_code}",
            }
        )
    output_path.write_text(
        json.dumps({"event_code": bundle.event_code, "sources": sources}, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def _source_details(source_id: str) -> tuple[str, str]:
    for known_source_id, row_key, table_name in _SOURCE_SPECS:
        if source_id == known_source_id:
            return row_key, table_name
    raise ValueError(f"unknown source: {source_id}")


def _filter_event(frame: pd.DataFrame, event_code: int, source_id: str) -> pd.DataFrame:
    event_values = pd.to_numeric(frame["cod_evento"], errors="coerce")
    filtered = frame.loc[event_values == event_code].copy()
    if filtered.empty:
        raise ValueError(f"{source_id} export contains no rows for event {event_code}")
    filtered.loc[:, "cod_evento"] = event_code
    return filtered


def _extraction_timestamp(frame: pd.DataFrame, source_id: str, allow_stale: bool) -> str:
    if "extracted_at" not in frame.columns:
        if allow_stale:
            return _STALE_EXTRACTION_MARKER
        raise ValueError(f"{source_id} export is missing required extracted_at column")

    values = frame["extracted_at"].tolist()
    if not values or any(pd.isna(value) or not str(value).strip() for value in values):
        if allow_stale:
            return _STALE_EXTRACTION_MARKER
        raise ValueError(f"{source_id} export has no usable extracted_at value")

    parsed = [parse_extraction_timestamp(value, source_id) for value in values]
    latest = max(parsed)
    if not allow_stale and min(parsed) < FINAL_EXTRACTION_MIN_TIMESTAMP:
        raise ValueError(
            f"{source_id} export extracted_at must be on or after "
            f"{FINAL_EXTRACTION_MIN_TIMESTAMP.isoformat()}"
        )
    return latest.isoformat()


def parse_extraction_timestamp(value: object, source_id: str) -> datetime:
    """Parse one source timestamp and require an explicit timezone offset."""
    try:
        parsed = datetime.fromisoformat(str(value).strip().replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError(f"{source_id} export has invalid extracted_at value") from error
    if parsed.tzinfo is None:
        raise ValueError(f"{source_id} export extracted_at must include a timezone offset")
    return parsed


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
