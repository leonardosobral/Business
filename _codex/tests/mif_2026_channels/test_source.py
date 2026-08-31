from pathlib import Path
from tempfile import TemporaryDirectory
import json
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.source import (
    load_sources,
    read_export,
    write_source_manifest,
)
from _codex.tests.mif_2026_channels.fixtures import orders_rows, participant_rows


class SourceTests(unittest.TestCase):
    def test_read_export_rejects_missing_body(self):
        """A missing raw payload must not enter the analysis pipeline."""
        with TemporaryDirectory() as directory:
            path = Path(directory) / "orders.csv"
            pd.DataFrame([{"cod_evento": 72611, "numero_pedido": 10}]).to_csv(path, index=False)

            with self.assertRaisesRegex(ValueError, "body"):
                read_export(path, frozenset({"cod_evento", "numero_pedido", "body"}))

    def test_load_sources_filters_event_and_records_hashes(self):
        """Wrong-event rows must be excluded and each export traceable by hash."""
        with TemporaryDirectory() as directory:
            orders_path = Path(directory) / "orders.xlsx"
            participants_path = Path(directory) / "participants.xlsx"
            pd.DataFrame(
                orders_rows() + [{"cod_evento": 99999, "numero_pedido": 999, "body": "{}"}]
            ).to_excel(orders_path, index=False)
            pd.DataFrame(participant_rows()).to_excel(participants_path, index=False)

            bundle = load_sources(orders_path, participants_path, event_code=72611, allow_stale=True)

            self.assertEqual(set(bundle.orders["cod_evento"]), {72611})
            self.assertEqual(len(bundle.source_hashes["orders"]), 64)
            self.assertEqual(bundle.event_code, 72611)

    def test_final_run_requires_fresh_extraction_timestamp(self):
        """A final run must reject exports without SQL extraction evidence."""
        with TemporaryDirectory() as directory:
            orders_path = Path(directory) / "orders.csv"
            participants_path = Path(directory) / "participants.csv"
            pd.DataFrame(orders_rows()).to_csv(orders_path, index=False)
            pd.DataFrame(participant_rows()).to_csv(participants_path, index=False)

            with self.assertRaisesRegex(ValueError, "extracted_at"):
                load_sources(orders_path, participants_path, event_code=72611, allow_stale=False)

    def test_final_run_rejects_any_stale_extraction_timestamp(self):
        """One stale row cannot be masked by a newer timestamp in the same export."""
        with TemporaryDirectory() as directory:
            orders_path = Path(directory) / "orders.csv"
            participants_path = Path(directory) / "participants.csv"
            orders = orders_rows()
            orders[0]["extracted_at"] = "2026-08-30T00:00:00-03:00"
            orders[1]["extracted_at"] = "2026-08-29T23:59:59-03:00"
            participants = participant_rows()
            for participant in participants:
                participant["extracted_at"] = "2026-08-30T00:00:00-03:00"
            pd.DataFrame(orders).to_csv(orders_path, index=False)
            pd.DataFrame(participants).to_csv(participants_path, index=False)

            with self.assertRaisesRegex(ValueError, "extracted_at"):
                load_sources(orders_path, participants_path, event_code=72611, allow_stale=False)

    def test_source_manifest_excludes_raw_rows_and_identifiers(self):
        """Traceability output must describe source files without leaking source payloads."""
        with TemporaryDirectory() as directory:
            orders_path = Path(directory) / "orders.csv"
            participants_path = Path(directory) / "participants.csv"
            manifest_path = Path(directory) / "manifest.json"
            pd.DataFrame(orders_rows()).to_csv(orders_path, index=False)
            pd.DataFrame(participant_rows()).to_csv(participants_path, index=False)

            bundle = load_sources(orders_path, participants_path, event_code=72611, allow_stale=True)
            write_source_manifest(bundle, manifest_path)

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(set(manifest), {"event_code", "sources"})
            self.assertEqual(set(manifest["sources"][0]), {
                "file_name", "sha256", "row_count", "extracted_at", "event_code", "table_name", "query_predicate"
            })
            self.assertNotIn("Pessoa Teste A", manifest_path.read_text(encoding="utf-8"))
