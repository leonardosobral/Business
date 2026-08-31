"""Canonical report snapshot and pipeline contracts for the MIF study."""

import csv
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest

from _codex.analyses.mif_2026_channels.artifact import (
    REPORT_APP_ID,
    build_report_snapshot,
)
from _codex.analyses.mif_2026_channels.metrics import DATASET_IDS
from _codex.analyses.mif_2026_channels.pipeline import (
    run_analysis,
    sanitize_shareable_html,
    write_json,
)
from _codex.tests.mif_2026_channels.fixtures import (
    analysis_result,
    write_reviewed_mappings,
    write_source_exports,
)


class ReportSnapshotTests(unittest.TestCase):
    def test_snapshot_is_fixture_report_with_all_stable_source_backed_queries(self):
        """Dropping a stable query or provenance would break the canonical report boundary."""
        snapshot = build_report_snapshot(
            analysis_result(), "2026-08-30T22:00:00-03:00"
        )

        self.assertEqual(snapshot["id"], REPORT_APP_ID)
        self.assertEqual(snapshot["surface"], "report")
        self.assertEqual(snapshot["status"], "fixture")
        self.assertEqual(snapshot["filters"], [])
        self.assertEqual(set(snapshot["queries"]), set(DATASET_IDS))
        self.assertEqual(len(snapshot["queries"]), 31)
        for query_id, query in snapshot["queries"].items():
            source = query["source"]
            self.assertTrue(source["metricDefinitions"], query_id)
            self.assertTrue(
                all(definition.get("componentIds") for definition in source["metricDefinitions"]),
                query_id,
            )
            self.assertIn("COUNT(*)", source["sql"])
            self.assertNotIn("numero_pedido", source["sql"].lower())
            self.assertNotIn("numero_inscricao", source["sql"].lower())
        self.assertEqual(
            {table for query in snapshot["queries"].values() for table in query["source"]["tables"]},
            {
                "public.tb_ticketsports_pedidos",
                "public.tb_ticketsports_participantes",
            },
        )

    def test_snapshot_contains_no_raw_facts_or_direct_identifiers(self):
        """Serializing raw facts or identifier fields would leak the reviewed-data boundary."""
        snapshot = build_report_snapshot(
            analysis_result(), "2026-08-30T22:00:00-03:00"
        )
        text = json.dumps(snapshot, ensure_ascii=False).lower()

        self.assertNotIn('"facts"', text)
        self.assertNotIn("numero_pedido", text)
        self.assertNotIn("numero_inscricao", text)
        self.assertNotIn("example.com", text)


class PipelineTests(unittest.TestCase):
    def test_shareable_removes_local_task_metadata_without_touching_index(self):
        """Leaking a desktop task UUID would make the standalone export session-bound."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "index.html"
            shareable = root / "shareable.html"
            task_id = "01a05524-22e1-78a0-bae0-d1b34e729785"
            original = (
                '<meta name="data-app-local-thread" content="' + task_id + '">\n'
                '<div id="root">conteúdo preservado</div>\n'
                f'<a href="codex://threads/{task_id}?prompt=teste">Perguntar</a>\n'
            )
            index.write_text(original, encoding="utf-8")

            sanitize_shareable_html(index, shareable)

            self.assertEqual(index.read_text(encoding="utf-8"), original)
            result = shareable.read_text(encoding="utf-8")
            self.assertNotIn("data-app-local-thread", result)
            self.assertNotIn(task_id, result)
            self.assertIn("conteúdo preservado", result)
            self.assertIn("codex://threads/new?prompt=teste", result)

    def test_write_json_atomically_replaces_the_destination(self):
        """Writing the destination in place would expose a partial receipt to readers."""
        with TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            path.write_text('{"version": 1}', encoding="utf-8")
            original_inode = path.stat().st_ino

            write_json(path, {"version": 2, "label": "revisão sintética"})

            self.assertNotEqual(path.stat().st_ino, original_inode)
            self.assertEqual(json.loads(path.read_text(encoding="utf-8"))["version"], 2)
            self.assertFalse(path.with_suffix(".json.tmp").exists())

    def test_pipeline_writes_canonical_snapshot_and_three_receipts_only(self):
        """A legacy artifact or raw-fact output would create a second unsafe report boundary."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_map, product_map = write_reviewed_mappings(root)
            app_dir = root / "report_app"

            paths = run_analysis(
                orders,
                participants,
                channel_map,
                product_map,
                app_dir,
                allow_stale=True,
            )

            self.assertEqual(
                set(paths),
                {"report_data", "aggregates", "reconciliation", "source_notes"},
            )
            self.assertEqual(paths["report_data"], app_dir / "src" / "data.json")
            self.assertFalse((app_dir / "artifact.json").exists())
            self.assertFalse(any(path.name.startswith("facts") for path in app_dir.rglob("*")))
            for path in paths.values():
                self.assertTrue(path.exists(), path)
            combined = "\n".join(
                path.read_text(encoding="utf-8") for path in paths.values()
            ).lower()
            self.assertNotIn("pessoa.teste", combined)
            self.assertNotIn("example.test", combined)
            self.assertNotIn("segredo-teste", combined)
            self.assertNotIn("numero_inscricao", combined)
            self.assertNotIn("numero_pedido", combined)
            self.assertEqual(
                json.loads(paths["report_data"].read_text(encoding="utf-8"))["status"],
                "fixture",
            )


class CliTests(unittest.TestCase):
    module = "_codex.analyses.mif_2026_channels.run"

    def _run(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-m", self.module, *arguments],
            cwd=Path(__file__).parents[3],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_analyze_and_verify_succeed_without_raw_source_arguments(self):
        """Verify must validate portable receipts without reopening row-level exports."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_map, product_map = write_reviewed_mappings(root)
            app_dir = root / "report_app"
            analyze = self._run(
                "analyze",
                "--orders", str(orders),
                "--participants", str(participants),
                "--channel-map", str(channel_map),
                "--product-map", str(product_map),
                "--output-dir", str(app_dir),
                "--allow-stale",
            )
            self.assertEqual(analyze.returncode, 0, analyze.stderr)

            verify = self._run(
                "verify",
                "--report-data", str(app_dir / "src" / "data.json"),
                "--aggregates", str(app_dir / "aggregates.json"),
                "--reconciliation", str(app_dir / "reconciliation.json"),
                "--source-notes", str(app_dir / "source_notes.json"),
            )
            self.assertEqual(verify.returncode, 0, verify.stderr)
            self.assertIn("verification passed", verify.stdout.lower())

    def test_verify_rejects_raw_fact_or_identifier_content(self):
        """A valid-looking receipt must still fail when raw identifiers are injected."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_map, product_map = write_reviewed_mappings(root)
            app_dir = root / "report_app"
            paths = run_analysis(
                orders, participants, channel_map, product_map, app_dir, allow_stale=True
            )
            aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
            aggregates["facts"] = [{"numero_inscricao": 2001}]
            paths["aggregates"].write_text(
                json.dumps(aggregates), encoding="utf-8"
            )

            verify = self._run(
                "verify",
                "--report-data", str(paths["report_data"]),
                "--aggregates", str(paths["aggregates"]),
                "--reconciliation", str(paths["reconciliation"]),
                "--source-notes", str(paths["source_notes"]),
            )
            self.assertNotEqual(verify.returncode, 0)
            self.assertIn("forbidden", verify.stderr.lower())

    def test_draft_mappings_emits_unreviewed_observed_identities(self):
        """Pre-marking generated identities reviewed would bypass the human review gate."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_output = root / "channel-draft.csv"
            product_output = root / "product-draft.csv"

            completed = self._run(
                "draft-mappings",
                "--orders", str(orders),
                "--participants", str(participants),
                "--channel-output", str(channel_output),
                "--product-output", str(product_output),
                "--allow-stale",
            )

            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertTrue(channel_output.exists())
            self.assertTrue(product_output.exists())
            with channel_output.open(encoding="utf-8", newline="") as handle:
                self.assertTrue(
                    all(row["reviewed"] == "False" for row in csv.DictReader(handle))
                )
            with product_output.open(encoding="utf-8", newline="") as handle:
                self.assertTrue(
                    all(row["reviewed"] == "False" for row in csv.DictReader(handle))
                )


if __name__ == "__main__":
    unittest.main()
