"""Canonical report snapshot and pipeline contracts for the MIF study."""

import csv
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest

import pandas as pd

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
from _codex.analyses.mif_2026_channels.run import verify_outputs
from _codex.tests.mif_2026_channels.fixtures import (
    analysis_result,
    orders_rows,
    participant_rows,
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

    def test_ready_snapshot_uses_final_provenance_without_fixture_claims(self):
        """A fresh final snapshot must not retain development-only provenance."""
        snapshot = build_report_snapshot(
            analysis_result(),
            "2026-08-31T01:00:00-03:00",
            status="ready",
        )

        self.assertEqual(snapshot["status"], "ready")
        self.assertIn(
            "fontes frescas finais",
            snapshot["report"]["qualification"].casefold(),
        )
        text = json.dumps(snapshot, ensure_ascii=False).casefold()
        for forbidden in (
            "fixture",
            "base sintética",
            "task 7",
            "task 8",
            "serve apenas para provar",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, text)
        for query in snapshot["queries"].values():
            source = query["source"]
            self.assertIn("fontes frescas finais", source["label"].casefold())
            self.assertTrue(
                any("extrações frescas" in step.casefold() for step in source["evidenceFlow"])
            )


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

    def test_fresh_pipeline_is_ready_verifiable_and_final_qualified(self):
        """Default fresh analysis must produce the final ready contract end to end."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            channel_map, product_map = write_reviewed_mappings(root)
            paths = run_analysis(
                orders,
                participants,
                channel_map,
                product_map,
                root / "report_app",
            )

            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            notes = json.loads(paths["source_notes"].read_text(encoding="utf-8"))
            self.assertEqual(snapshot["status"], "ready")
            self.assertEqual(len(snapshot["queries"]), 31)
            self.assertNotIn("fixture_status", notes)
            self.assertIn(
                "fontes frescas finais",
                notes["source_qualification"].casefold(),
            )
            self.assertEqual(
                {source["extracted_at"] for source in notes["sources"]},
                {"2026-08-30T22:00:00-03:00"},
            )
            combined = "\n".join(
                path.read_text(encoding="utf-8") for path in paths.values()
            ).casefold()
            for forbidden in (
                "fixture",
                "base sintética",
                "task 7",
                "task 8",
                "serve apenas para provar",
            ):
                with self.subTest(forbidden=forbidden):
                    self.assertNotIn(forbidden, combined)
            verify_outputs(
                paths["report_data"],
                paths["aggregates"],
                paths["reconciliation"],
                paths["source_notes"],
            )

    def test_ready_report_copy_contains_final_evidence_and_limitations_only(self):
        """The authored ready view must render final copy, not hidden fixture claims."""
        module_path = (
            Path(__file__).parents[2]
            / "analyses/mif_2026_channels/report_app/src/content/report/report-copy.js"
        )
        script = f"""
          import {{ reportCopy }} from {json.dumps(module_path.as_uri())};
          const copy = reportCopy('ready', {{paid_orders: 14027, paid_registrations: 15713}});
          console.log(JSON.stringify({{...copy, channel: copy.channelSummary({{
            channel_name: 'Sports Week', paid_registrations: 949,
            touched_paid_orders: 900, gross_value: '100.00', registration_ticket: '10.00'
          }})}}));
        """
        completed = subprocess.run(
            ["node", "--input-type=module", "-e", script],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        copy = json.loads(completed.stdout)
        text = json.dumps(copy, ensure_ascii=False).casefold()
        for forbidden in (
            "fixture",
            "base sintética",
            "task 8 fará",
            "serve apenas para provar",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, text)
        for required in (
            "pedidos pagos únicos",
            "inscrições pagas",
            "itens vinculados a inscrições pagas",
            "cobertura",
            "patrocínio",
            "expo",
            "permutas",
            "cortesias",
            "não são mensurados",
        ):
            with self.subTest(required=required):
                self.assertIn(required, text)


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

    def _variant_outputs(
        self,
        root: Path,
        *,
        organic_registration: bool = False,
        unpaid_participant: bool = False,
        zero_paid_orders: bool = False,
    ):
        orders_data = deepcopy(orders_rows())
        participants_data = deepcopy(participant_rows())
        if zero_paid_orders:
            for order in orders_data:
                order_body = json.loads(order["body"])
                order_body["status"] = "aguardando_pagamento"
                order["body"] = json.dumps(order_body)
        if organic_registration:
            order = deepcopy(orders_data[0])
            order["numero_pedido"] = 1003
            order["data_pedido"] = "2026-06-03T12:00:00-03:00"
            order_body = json.loads(order["body"])
            order_body.pop("cupom", None)
            order_body.update(
                {
                    "dataPedido": "2026-06-03",
                    "dataPagamento": "2026-06-03",
                    "valor": "300.00",
                    "desconto": "30.00",
                    "taxa": "15.00",
                    "valorRepassePedido": "255.00",
                    "cashback": "3.00",
                    "qtdeInscricao": 1,
                }
            )
            order["body"] = json.dumps(order_body)
            orders_data.append(order)

            participant = deepcopy(participants_data[0])
            participant["numero_inscricao"] = 2003
            participant["numero_pedido"] = 1003
            participant_body = json.loads(participant["body"])
            participant_body.pop("tituloCupom", None)
            participant_body.pop("codigoCupom", None)
            participant_body.update(
                {
                    "dataVenda": "2026-06-03",
                    "dataInscricao": "2026-06-03",
                    "valorUnitario": "300.00",
                    "valorTaxa": "15.00",
                    "valorDesconto": "30.00",
                    "valorDescontoCupom": "0.00",
                    "valorRepasse": "255.00",
                }
            )
            participant["body"] = json.dumps(participant_body)
            participants_data.append(participant)

        if unpaid_participant:
            order_body = json.loads(orders_data[1]["body"])
            order_body["qtdeInscricao"] = 1
            orders_data[1]["body"] = json.dumps(order_body)
            participant = deepcopy(participants_data[0])
            participant["numero_inscricao"] = 2004
            participant["numero_pedido"] = 1002
            participants_data.append(participant)

        orders = root / "orders.csv"
        participants = root / "participants.csv"
        extracted_at = "2026-08-30T22:00:00-03:00"
        pd.DataFrame(orders_data).assign(extracted_at=extracted_at).to_csv(
            orders, index=False
        )
        pd.DataFrame(participants_data).assign(extracted_at=extracted_at).to_csv(
            participants, index=False
        )
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

    def _replace_overview_value(self, paths, key: str, value: object) -> None:
        """Keep the duplicated overview payloads coherent for tamper probes."""
        aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
        snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
        aggregates["overview"][key] = value
        aggregates["datasets"]["event_overview"][0][key] = value
        snapshot["queries"]["event_overview"]["rows"][0][key] = value
        write_json(paths["aggregates"], aggregates)
        write_json(paths["report_data"], snapshot)

    def test_verify_rejects_tampered_non_gross_financial_receipts(self):
        """Changing both sides of a non-gross receipt must not bypass verification."""
        components = {
            "discount": ("paid_order_discount", "allocated_registration_discount"),
            "fee": ("paid_order_fee", "allocated_registration_fee"),
            "net transfer": (
                "paid_order_net_transfer",
                "allocated_registration_net_transfer",
            ),
            "cashback": ("paid_order_cashback", "allocated_registration_cashback"),
        }
        for label, keys in components.items():
            with self.subTest(component=label), TemporaryDirectory() as directory:
                paths = self._outputs(Path(directory))
                reconciliation = json.loads(
                    paths["reconciliation"].read_text(encoding="utf-8")
                )
                aggregates = json.loads(
                    paths["aggregates"].read_text(encoding="utf-8")
                )
                for key in keys:
                    reconciliation[key] = "1.23"
                    aggregates["quality"]["reconciliation"][key] = "1.23"
                write_json(paths["reconciliation"], reconciliation)
                write_json(paths["aggregates"], aggregates)

                completed = self._verify(paths)

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(label, completed.stderr.lower())

    def test_verify_rejects_tampered_overview_financial_components(self):
        """Overview money must reconcile to the independent order/allocation receipts."""
        components = {
            "discount": "discount_value",
            "fee": "fee_value",
            "net transfer": "net_transfer_value",
            "cashback": "cashback_value",
        }
        for label, overview_key in components.items():
            with self.subTest(component=label), TemporaryDirectory() as directory:
                paths = self._outputs(Path(directory))
                self._replace_overview_value(paths, overview_key, "1.23")

                completed = self._verify(paths)

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(label, completed.stderr.lower())

    def test_verify_recomputes_event_tickets_from_exact_paid_bases(self):
        """A copied or averaged ticket must fail the exact paid-order/registration bases."""
        for ticket in ("order_ticket", "registration_ticket"):
            with self.subTest(ticket=ticket), TemporaryDirectory() as directory:
                paths = self._outputs(Path(directory))
                self._replace_overview_value(paths, ticket, "1.23")

                completed = self._verify(paths)

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(ticket.replace("_", " "), completed.stderr.lower())

    def test_verify_rejects_optional_money_that_conflicts_with_source_availability(self):
        """Covered zero is a value; unavailable optional money must stay null."""
        components = {
            "fee": (
                "fee_value",
                "paid_order_fee",
                "allocated_registration_fee",
            ),
            "net transfer": (
                "net_transfer_value",
                "paid_order_net_transfer",
                "allocated_registration_net_transfer",
            ),
            "cashback": (
                "cashback_value",
                "paid_order_cashback",
                "allocated_registration_cashback",
            ),
        }
        for label, (source_field, order_key, allocated_key) in components.items():
            with self.subTest(component=label), TemporaryDirectory() as directory:
                paths = self._outputs(Path(directory))
                reconciliation = json.loads(
                    paths["reconciliation"].read_text(encoding="utf-8")
                )
                aggregates = json.loads(
                    paths["aggregates"].read_text(encoding="utf-8")
                )
                paid_orders = reconciliation["paid_order_count"]
                unavailable = {
                    "valido": 0,
                    "invalido": 0,
                    "nao_informado": paid_orders,
                }
                reconciliation["paid_order_field_coverage"][source_field] = unavailable
                aggregates["quality"]["reconciliation"][
                    "paid_order_field_coverage"
                ][source_field] = unavailable
                write_json(paths["reconciliation"], reconciliation)
                write_json(paths["aggregates"], aggregates)

                completed = self._verify(paths)

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(label, completed.stderr.lower())

                for key in (order_key, allocated_key):
                    reconciliation[key] = None
                    aggregates["quality"]["reconciliation"][key] = None
                write_json(paths["reconciliation"], reconciliation)
                write_json(paths["aggregates"], aggregates)
                self._replace_overview_value(paths, source_field, None)
                completed = self._verify(paths)
                self.assertEqual(completed.returncode, 0, completed.stderr)

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
            aggregates = json.loads(
                paths["aggregates"].read_text(encoding="utf-8")
            )
            aggregates["quality"]["reconciliation"][
                "channel_mapping_coverage_pct"
            ] = 0
            write_json(paths["reconciliation"], reconciliation)
            write_json(paths["aggregates"], aggregates)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("channel_mapping_coverage_pct", completed.stderr)

    def test_verify_rejects_coherently_truncated_auxiliary_coverage(self):
        """A nonempty receipt cannot discard required fields or use a zero fake base."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            truncated = [
                {
                    "field": "payment_method",
                    "answered": 0,
                    "valid": 0,
                    "invalid": 0,
                    "missing": 0,
                    "denominator": 0,
                    "coverage_pct": 0.0,
                    "valid_coverage_pct": 0.0,
                }
            ]
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
            snapshot["queries"]["auxiliary_field_coverage"]["rows"] = truncated
            aggregates["datasets"]["auxiliary_field_coverage"] = truncated
            write_json(paths["report_data"], snapshot)
            write_json(paths["aggregates"], aggregates)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("auxiliary_field_coverage", completed.stderr)

    def test_verify_rejects_stale_source_receipt_timestamp(self):
        """Query freshness cannot mask a stale extraction receipt from 1900."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            notes = json.loads(paths["source_notes"].read_text(encoding="utf-8"))
            notes["sources"][0]["extracted_at"] = "1900-01-01T00:00:00-03:00"
            write_json(paths["source_notes"], notes)

            completed = self._verify(paths)

            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("fresh", completed.stderr.lower())

    def test_verify_accepts_legitimate_organic_alias_in_paid_event(self):
        """Alias rows include the organic identity and reconcile to all paid registrations."""
        with TemporaryDirectory() as directory:
            paths = self._variant_outputs(
                Path(directory), organic_registration=True
            )

            completed = self._verify(paths)

            self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_verify_accepts_paid_quality_base_when_source_has_unpaid_participant(self):
        """Registration quality is measured on paid registrations, not every source row."""
        with TemporaryDirectory() as directory:
            paths = self._variant_outputs(Path(directory), unpaid_participant=True)

            completed = self._verify(paths)

            self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_auxiliary_order_coverage_uses_paid_order_base(self):
        """Commercial order coverage excludes source orders that are not paid."""
        with TemporaryDirectory() as directory:
            paths = self._outputs(Path(directory))
            aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
            self.assertEqual(aggregates["overview"]["paid_orders"], 1)
            rows = {
                row["field"]: row
                for row in aggregates["datasets"]["auxiliary_field_coverage"]
            }
            for field in ("payment_method", "device", "order_quantity"):
                row = rows[field]
                self.assertEqual(row["denominator"], 1, field)
                self.assertEqual(
                    row["valid"] + row["invalid"] + row["missing"],
                    row["denominator"],
                    field,
                )

            completed = self._verify(paths)
            self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_zero_paid_event_has_zero_money_and_verifies(self):
        """An empty commercial base is valid, but a nonzero receipt remains invalid."""
        with TemporaryDirectory() as directory:
            paths = self._variant_outputs(
                Path(directory), zero_paid_orders=True
            )
            aggregates = json.loads(paths["aggregates"].read_text(encoding="utf-8"))
            reconciliation = json.loads(
                paths["reconciliation"].read_text(encoding="utf-8")
            )
            overview = aggregates["overview"]
            auxiliary = aggregates["datasets"]["auxiliary_field_coverage"]

            self.assertEqual(overview["paid_orders"], 0)
            self.assertEqual(overview["gross_value"], "0.00")
            self.assertEqual(reconciliation["paid_order_gross"], "0.00")
            self.assertEqual(reconciliation["allocated_registration_gross"], "0.00")
            self.assertEqual(len(auxiliary), 4)
            self.assertTrue(all(row["denominator"] == 0 for row in auxiliary))
            completed = self._verify(paths)
            self.assertEqual(completed.returncode, 0, completed.stderr)

            reconciliation["paid_order_gross"] = "1.00"
            aggregates["quality"]["reconciliation"][
                "paid_order_gross"
            ] = "1.00"
            write_json(paths["reconciliation"], reconciliation)
            write_json(paths["aggregates"], aggregates)
            completed = self._verify(paths)
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("gross", completed.stderr.lower())

    def test_legacy_allow_stale_without_timestamps_is_fixture_verifiable(self):
        """Missing extraction evidence has a deterministic fixture-only marker."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            for path in (orders, participants):
                frame = pd.read_csv(path, dtype=object).drop(columns="extracted_at")
                frame.to_csv(path, index=False)
            channel_map, product_map = write_reviewed_mappings(root)
            paths = run_analysis(
                orders,
                participants,
                channel_map,
                product_map,
                root / "report_app",
                allow_stale=True,
            )
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))
            notes = json.loads(paths["source_notes"].read_text(encoding="utf-8"))

            self.assertEqual(snapshot["status"], "fixture")
            self.assertEqual(snapshot["generatedAt"], "not_provided_allow_stale")
            self.assertEqual(
                {source["extracted_at"] for source in notes["sources"]},
                {"not_provided_allow_stale"},
            )
            completed = self._verify(paths)
            self.assertEqual(completed.returncode, 0, completed.stderr)

            snapshot["status"] = "ready"
            write_json(paths["report_data"], snapshot)
            completed = self._verify(paths)
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("ready", completed.stderr.lower())

    def test_analyze_chooses_generated_at_by_chronological_instant(self):
        """Different offsets must not turn lexicographic order into report freshness."""
        with TemporaryDirectory() as directory:
            root = Path(directory)
            orders, participants = write_source_exports(root)
            orders_frame = pd.read_csv(orders, dtype=object)
            participants_frame = pd.read_csv(participants, dtype=object)
            orders_frame["extracted_at"] = "2026-08-31T00:30:00+00:00"
            participants_frame["extracted_at"] = "2026-08-30T23:45:00-03:00"
            orders_frame.to_csv(orders, index=False)
            participants_frame.to_csv(participants, index=False)
            channel_map, product_map = write_reviewed_mappings(root)
            paths = run_analysis(
                orders,
                participants,
                channel_map,
                product_map,
                root / "report_app",
                allow_stale=True,
            )
            snapshot = json.loads(paths["report_data"].read_text(encoding="utf-8"))

            self.assertEqual(
                snapshot["generatedAt"], "2026-08-30T23:45:00-03:00"
            )
            completed = self._verify(paths)
            self.assertEqual(completed.returncode, 0, completed.stderr)

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
