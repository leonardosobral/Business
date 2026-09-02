"""Incremental modular artifact contracts for the MIF 2026 report."""

from copy import deepcopy
from dataclasses import replace
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
    channel_slug,
    write_modular_artifacts,
)
from _codex.analyses.mif_2026_channels.phases import (
    build_sale_cycle_boundaries,
    effective_sale_dates,
)
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
    def test_builds_exact_domain_index_dossier_and_manifest_files(self):
        result, _, _, artifacts = modular_fixture()
        channel_names = [
            row["channel_name"]
            for row in result.datasets["channel_index"]
        ]
        expected = {
            "manifest.json",
            "general.json",
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


if __name__ == "__main__":
    unittest.main()
