"""Canonical report snapshot and pipeline contracts for the MIF study."""

import csv
from copy import deepcopy
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
                all(isinstance(definition.get("componentIds"), list) for definition in source["metricDefinitions"]),
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

    def test_paid_registration_and_allocation_sources_include_both_tables(self):
        """Registration counts and allocated money cannot cite participants alone."""
        snapshot = build_report_snapshot(
            analysis_result(), "2026-08-30T22:00:00-03:00"
        )
        expected = {
            "public.tb_ticketsports_pedidos",
            "public.tb_ticketsports_participantes",
        }
        for query_id in (
            "weekly_sales",
            "lot_performance",
            "product_summary",
            "channel_index",
            "channel_product_mix",
            "long_tail",
        ):
            self.assertEqual(set(snapshot["queries"][query_id]["source"]["tables"]), expected)

        definitions = snapshot["queries"]["event_overview"]["source"]["metricDefinitions"]
        by_component = {
            component_id: definition
            for definition in definitions
            for component_id in definition["componentIds"]
        }
        self.assertIn("pedidos pagos únicos", by_component["mif-overview-orders"]["definition"].lower())
        self.assertIn("inscrições vinculadas", by_component["mif-overview-registrations"]["definition"].lower())
        self.assertIn("soma do valor bruto", by_component["mif-overview-gross"]["definition"].lower())
        self.assertIn("dividida", by_component["mif-overview-ticket"]["definition"].lower())
        self.assertEqual(
            set(by_component["mif-overview-ticket"]["sourceLineage"][0]["tables"]),
            expected,
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
    def test_shareable_removes_local_task_metadata_and_normalizes_both_html_files(self):
        """Leaking a desktop task UUID would make the standalone export session-bound."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "index.html"
            shareable = root / "shareable.html"
            task_id = "01a05524-22e1-78a0-bae0-d1b34e729785"
            original = (
                '<meta name="data-app-local-thread" content="' + task_id + '">  \n'
                '<div id="root">conteúdo preservado</div>\t\n'
                f'<a href="codex://threads/{task_id}?prompt=teste">Perguntar</a>\n\n'
            )
            index.write_text(original, encoding="utf-8")

            sanitize_shareable_html(index, shareable)

            normalized_index = index.read_text(encoding="utf-8")
            self.assertIn("data-app-local-thread", normalized_index)
            self.assertFalse(any(line.endswith((" ", "\t")) for line in normalized_index.splitlines()))
            self.assertTrue(normalized_index.endswith("\n"))
            self.assertFalse(normalized_index.endswith("\n\n"))
            result = shareable.read_text(encoding="utf-8")
            self.assertNotIn("data-app-local-thread", result)
            self.assertNotIn(task_id, result)
            self.assertIn("conteúdo preservado", result)
            self.assertIn("codex://threads/new?prompt=teste", result)
            self.assertFalse(any(line.endswith((" ", "\t")) for line in result.splitlines()))
            self.assertTrue(result.endswith("\n"))
            self.assertFalse(result.endswith("\n\n"))

    def test_report_chart_contract_uses_supported_types_and_explicit_evidence_description(self):
        """The authored chart contract must expose period, unit, and denominator."""
        module_path = (
            Path(__file__).parents[2]
            / "analyses/mif_2026_channels/report_app/src/content/report/report-contract.js"
        )
        script = f"""
          import {{ CHART_SPECS, evidenceDescription }} from {json.dumps(module_path.as_uri())};
          const description = evidenceDescription(
            [{{week_start: '2026-05-25', paid_registrations: 2}},
             {{week_start: '2026-06-01', paid_registrations: 3}}],
            {{periodField: 'week_start', unit: 'inscrições pagas', denominator: 5}}
          );
          console.log(JSON.stringify({{specs: CHART_SPECS, description}}));
        """
        completed = subprocess.run(
            ["node", "--input-type=module", "-e", script],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        contract = json.loads(completed.stdout)
        self.assertEqual(contract["specs"]["lot_performance"]["type"], "stackedBar")
        for query_id in ("country_distribution", "state_distribution", "city_distribution", "product_summary"):
            self.assertEqual(contract["specs"][query_id]["type"], "horizontalBar")
        self.assertIn("Período:", contract["description"])
        self.assertIn("Unidade:", contract["description"])
        self.assertIn("Denominador:", contract["description"])

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

    def _outputs(self, root: Path):
        orders, participants = write_source_exports(root)
        channel_map, product_map = write_reviewed_mappings(root)
        return run_analysis(
            orders,
            participants,
            channel_map,
            product_map,
            root / "report_app",
            allow_stale=True,
        )

    def _verify(self, paths) -> subprocess.CompletedProcess[str]:
        return self._run(
            "verify",
            "--report-data", str(paths["report_data"]),
            "--aggregates", str(paths["aggregates"]),
            "--reconciliation", str(paths["reconciliation"]),
            "--source-notes", str(paths["source_notes"]),
        )

    def test_verify_rejects_query_rows_that_diverge_from_aggregate_receipt(self):
        """Tampering with weekly evidence must not survive receipt verification."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            snapshot["queries"]["weekly_sales"]["rows"][0]["paid_registrations"] += 1
            write_json(paths["report_data"], snapshot)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("weekly_sales", completed.stderr)

    def test_verify_rejects_coherently_emptied_required_weekly_dataset(self):
        """Matching receipts cannot make a paid event's required weekly evidence empty."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
            snapshot["queries"]["weekly_sales"]["rows"] = []
            aggregates["datasets"]["weekly_sales"] = []
            write_json(paths["report_data"], snapshot)
            write_json(paths["aggregates"], aggregates)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("weekly_sales", completed.stderr)

    def test_verify_rejects_query_source_tables_that_diverge_from_provenance_contract(self):
        """Registration evidence must retain the exact orders-and-participants lineage."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            snapshot["queries"]["weekly_sales"]["source"]["tables"] = [
                "public.tb_ticketsports_participantes"
            ]
            write_json(paths["report_data"], snapshot)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("source", completed.stderr.lower())
            self.assertIn("weekly_sales", completed.stderr)

    def test_verify_requires_complete_reviewed_mapping_and_join_coverage(self):
        """Final reviewed outputs must fail closed below complete contractual coverage."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            reconciliation = json.loads(
                paths["reconciliation"].read_text(encoding="utf-8")
            )
            reconciliation["channel_mapping_coverage_pct"] = 0
            write_json(paths["reconciliation"], reconciliation)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("channel_mapping_coverage_pct", completed.stderr)

    def test_verify_rejects_score_field(self):
        """Decision-score fields are forbidden even when aggregate data stays anonymous."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            notes = json.loads(paths["source_notes"].read_text(encoding="utf-8"))
            notes["score"] = 100
            write_json(paths["source_notes"], notes)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("score", completed.stderr.lower())

    def test_verify_rejects_nonexistent_component_reference(self):
        """Source definitions may only reference components mounted by the report app."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            snapshot["queries"]["weekly_sales"]["source"]["metricDefinitions"][0][
                "componentIds"
            ].append("mif-component-that-does-not-exist")
            write_json(paths["report_data"], snapshot)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("component", completed.stderr.lower())

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
