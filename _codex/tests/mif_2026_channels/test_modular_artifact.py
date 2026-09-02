"""Incremental modular artifact contracts for the MIF 2026 report."""

from copy import deepcopy
from dataclasses import replace
import hashlib
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from _codex.analyses.mif_2026_channels.crossings import (
    build_product_cube,
    build_registration_cube,
)
from _codex.analyses.mif_2026_channels.modular_artifact import (
    build_modular_artifacts,
    canonical_json_bytes,
    channel_slug,
    write_modular_artifacts,
)
from _codex.analyses.mif_2026_channels.phases import (
    build_sale_cycle_boundaries,
    effective_sale_dates,
)
from _codex.analyses.mif_2026_channels.run import verify_modular_outputs
from _codex.tests.mif_2026_channels.fixtures import (
    analysis_result,
    channel_metric_facts,
)


SOURCE_HASHES = {"orders": "a" * 64, "participants": "b" * 64}


def modular_fixture():
    facts = channel_metric_facts()
    boundaries = build_sale_cycle_boundaries(
        effective_sale_dates(facts.registrations)
    )
    result = analysis_result()
    registration_cube = build_registration_cube(facts, boundaries)
    product_cube = build_product_cube(facts, boundaries)
    artifacts = build_modular_artifacts(
        result,
        registration_cube,
        product_cube,
        SOURCE_HASHES,
        generated_at="2026-08-30T22:00:00-03:00",
    )
    return result, registration_cube, product_cube, artifacts


class ModularArtifactTests(unittest.TestCase):
    @staticmethod
    def _replace_artifact(root, relative_path, payload):
        content = canonical_json_bytes(payload)
        path = root / relative_path
        path.write_bytes(content)
        manifest_path = root / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["artifacts"][relative_path]["sha256"] = hashlib.sha256(content).hexdigest()
        manifest["artifacts"][relative_path]["bytes"] = len(content)
        manifest_path.write_bytes(canonical_json_bytes(manifest))

    def test_builds_exact_domain_index_dossier_and_manifest_files(self):
        result, _, _, artifacts = modular_fixture()
        channel_names = [
            row["channel_name"]
            for row in result.datasets["channel_index"]
        ]
        expected = {
            "manifest.json",
            "general.json",
            "strategy.json",
            "cycle.json",
            "territories.json",
            "products.json",
            "channels/index.json",
            "explorer.json",
            *{
                f"channels/{channel_slug(channel_name)}.json"
                for channel_name in channel_names
            },
        }
        expected |= {"portfolio/summary.json", "portfolio/simulator.json"}

        self.assertEqual(set(artifacts), expected)
        manifest = artifacts["manifest.json"]
        self.assertEqual(
            set(manifest["artifacts"]), expected - {"manifest.json"}
        )
        for relative_path, receipt in manifest["artifacts"].items():
            self.assertEqual(receipt["path"], relative_path)
            self.assertEqual(len(receipt["sha256"]), 64)
            self.assertGreater(receipt["bytes"], 0)
            self.assertEqual(len(receipt["source_sha256"]), 64)
            self.assertTrue(receipt["transform_version"])
        self.assertLess(manifest["artifacts"]["portfolio/summary.json"]["bytes"], 750_000)
        self.assertLess(manifest["artifacts"]["portfolio/simulator.json"]["bytes"], 2_000_000)
        self.assertNotIn("coverage_cube", artifacts["portfolio/summary.json"])

        strategy = artifacts["strategy.json"]
        self.assertNotIn("observations", strategy)
        self.assertNotIn("registration_cube", strategy)
        self.assertNotIn("product_cube", strategy)
        self.assertEqual(
            sum(
                row["paid_registrations"]
                for row in strategy["datasets"]["phase_modality"]
            ),
            result.overview["paid_registrations"],
        )
        self.assertEqual(
            manifest["artifacts"]["strategy.json"]["transform_version"],
            strategy["meta"]["transform_version"],
        )
        self.assertNotEqual(
            manifest["artifacts"]["strategy.json"]["transform_version"],
            manifest["artifacts"]["general.json"]["transform_version"],
        )

    def test_identical_write_preserves_every_file_mtime(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            paths = write_modular_artifacts(root, artifacts)
            forced_mtimes = {}
            for position, path in enumerate(paths.values()):
                forced = 1_600_000_000_000_000_000 + position
                os.utime(path, ns=(forced, forced))
                forced_mtimes[path] = path.stat().st_mtime_ns

            second_paths = write_modular_artifacts(root, artifacts)

            self.assertEqual(paths, second_paths)
            self.assertEqual(
                {path: path.stat().st_mtime_ns for path in paths.values()},
                forced_mtimes,
            )

    def test_one_dossier_change_rewrites_only_dossier_index_and_manifest(self):
        result, registration_cube, product_cube, artifacts = modular_fixture()
        target_name = result.full_dossiers[0]["channel_name"]
        target_path = f"channels/{channel_slug(target_name)}.json"
        with TemporaryDirectory() as directory:
            root = Path(directory)
            paths = write_modular_artifacts(root, artifacts)
            before = {name: path.stat().st_mtime_ns for name, path in paths.items()}

            changed_result = deepcopy(result)
            changed_result.full_dossiers[0]["executive_summary"] += " Destaque revisado."
            changed_artifacts = build_modular_artifacts(
                changed_result,
                registration_cube,
                product_cube,
                SOURCE_HASHES,
                generated_at="2026-08-30T22:00:00-03:00",
            )
            write_modular_artifacts(root, changed_artifacts)
            changed = {
                name
                for name, path in paths.items()
                if path.stat().st_mtime_ns != before[name]
            }

            self.assertEqual(
                changed,
                {target_path, "channels/index.json", "manifest.json"},
            )

    def test_all_outputs_are_canonical_json_without_direct_identifiers(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            paths = write_modular_artifacts(root, artifacts)
            combined = "\n".join(
                path.read_text(encoding="utf-8") for path in paths.values()
            ).casefold()

            self.assertNotIn("numero_inscricao", combined)
            self.assertNotIn("numero_pedido", combined)
            for path in paths.values():
                payload = json.loads(path.read_text(encoding="utf-8"))
                self.assertIsNotNone(payload)
                self.assertTrue(path.read_bytes().endswith(b"\n"))

    def test_portfolio_artifacts_are_portably_verifiable(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)

            verify_modular_outputs(root / "manifest.json")

    def test_portfolio_receipts_pin_every_transform_dependency(self):
        _, _, _, artifacts = modular_fixture()

        receipts = artifacts["manifest.json"]["artifacts"]
        expected_keys = {
            "channel_index_sha256",
            "dossier_similarities_sha256",
            "explorer_registration_cube_sha256",
            "transform_contract_sha256",
            "transform_version",
        }
        summary_dependencies = receipts["portfolio/summary.json"]["dependencies"]
        simulator_dependencies = receipts["portfolio/simulator.json"]["dependencies"]

        self.assertEqual(summary_dependencies, simulator_dependencies)
        self.assertEqual(set(summary_dependencies), expected_keys)
        for key in expected_keys - {"transform_version"}:
            self.assertRegex(summary_dependencies[key], r"^[0-9a-f]{64}$")
        self.assertEqual(
            summary_dependencies["transform_version"],
            artifacts["portfolio/summary.json"]["meta"]["transform_version"],
        )

    def test_portfolio_verification_rejects_dependency_receipt_mismatch(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            manifest_path = root / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["artifacts"]["portfolio/summary.json"]["dependencies"][
                "channel_index_sha256"
            ] = "0" * 64
            manifest_path.write_bytes(canonical_json_bytes(manifest))

            with self.assertRaisesRegex(ValueError, "portfolio dependency receipt mismatch"):
                verify_modular_outputs(manifest_path)

    def test_portfolio_verification_rejects_incomplete_selectable_catalog(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            simulator = deepcopy(artifacts["portfolio/simulator.json"])
            simulator["selectable_channels"].pop()
            self._replace_artifact(root, "portfolio/simulator.json", simulator)

            with self.assertRaisesRegex(ValueError, "selectable channel catalog mismatch"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_threshold_drift(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            simulator = deepcopy(artifacts["portfolio/simulator.json"])
            simulator["thresholds"]["exposure_high_event_share_pct"] = "39.99"
            self._replace_artifact(root, "portfolio/simulator.json", simulator)

            with self.assertRaisesRegex(ValueError, "portfolio threshold contract mismatch"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_incomplete_pair_evidence(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            summary = deepcopy(artifacts["portfolio/summary.json"])
            summary["redundancy_candidates"][0]["dimension_evidence"].pop("product")
            self._replace_artifact(root, "portfolio/summary.json", summary)

            with self.assertRaisesRegex(ValueError, "five dimension evidence"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_missing_cube_money(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            simulator = deepcopy(artifacts["portfolio/simulator.json"])
            simulator["coverage_cube"][0].pop("allocated_gross_value")
            self._replace_artifact(root, "portfolio/simulator.json", simulator)

            with self.assertRaisesRegex(ValueError, "portfolio simulator money contract"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_kit_incluso_outside_definition(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            summary = deepcopy(artifacts["portfolio/summary.json"])
            summary["unexpected"] = {"classification": "kit_incluso"}
            self._replace_artifact(root, "portfolio/summary.json", summary)

            with self.assertRaisesRegex(ValueError, "kit_incluso outside product scope"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_manifest_byte_receipt_mismatch(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            manifest_path = root / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["artifacts"]["portfolio/simulator.json"]["bytes"] += 1
            manifest_path.write_bytes(canonical_json_bytes(manifest))

            with self.assertRaisesRegex(ValueError, "modular artifact byte count mismatch"):
                verify_modular_outputs(manifest_path)

    def test_portfolio_verification_rejects_overview_divergence(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            summary = deepcopy(artifacts["portfolio/summary.json"])
            summary["overview"]["paid_registrations"] = 999
            self._replace_artifact(root, "portfolio/summary.json", summary)

            with self.assertRaisesRegex(ValueError, "portfolio overview mismatch"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_allows_city_source_coverage_in_equal_overview(self):
        result, registration_cube, product_cube, _ = modular_fixture()
        overview = deepcopy(result.overview)
        overview["source_field_coverage"] = {
            "registrations": {"city": {"valid": 2, "denominator": 2}}
        }
        artifacts = build_modular_artifacts(
            replace(result, overview=overview),
            registration_cube,
            product_cube,
            SOURCE_HASHES,
            generated_at="2026-08-30T22:00:00-03:00",
        )
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)

            verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_city_coverage_in_simulator(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            simulator = deepcopy(artifacts["portfolio/simulator.json"])
            simulator["overview"] = {
                "source_field_coverage": {
                    "registrations": {"city": {"valid": 2, "denominator": 2}}
                }
            }
            self._replace_artifact(root, "portfolio/simulator.json", simulator)

            with self.assertRaisesRegex(ValueError, "forbidden portfolio field"):
                verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_missing_or_malformed_selectable_type(self):
        _, _, _, artifacts = modular_fixture()
        for channel_type in (None, "   ", "desconhecido"):
            with self.subTest(channel_type=channel_type), TemporaryDirectory() as directory:
                root = Path(directory)
                write_modular_artifacts(root, artifacts)
                simulator = deepcopy(artifacts["portfolio/simulator.json"])
                simulator["selectable_channels"][0]["channel_type"] = channel_type
                self._replace_artifact(root, "portfolio/simulator.json", simulator)

                with self.assertRaisesRegex(ValueError, "selectable channel type"):
                    verify_modular_outputs(root / "manifest.json")

    def test_portfolio_verification_rejects_selectable_type_mismatched_with_index(self):
        _, _, _, artifacts = modular_fixture()
        with TemporaryDirectory() as directory:
            root = Path(directory)
            write_modular_artifacts(root, artifacts)
            simulator = deepcopy(artifacts["portfolio/simulator.json"])
            simulator["selectable_channels"][0]["channel_type"] = "assessoria"
            self._replace_artifact(root, "portfolio/simulator.json", simulator)

            with self.assertRaisesRegex(ValueError, "selectable channel type mismatch"):
                verify_modular_outputs(root / "manifest.json")


if __name__ == "__main__":
    unittest.main()
