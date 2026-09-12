"""Offline release fixtures: no SSH and no access to production webroots."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("highlight_release", Path(__file__).with_name("publish.py"))
release_tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_tool)

MEASUREMENT = (
    ("Business", "portal/audiencia/queries/live_journey.sql"),
    ("Business", "portal/audiencia/live_journey.cfm"),
    ("Business", "portal/includes/audience_backend.cfm"),
    ("Business", "portal/audiencia/home.cfm"),
    ("RoadRunners", "services/AudienceMeasurementService.cfc"),
    ("RoadRunners", "assets/js/rr-audience.js"),
    ("RoadRunners", "includes/modal/modal_cupom_link_conteudo.cfm"),
    ("RoadRunners", "evento/index.cfm"),
    ("RoadRunners", "evento/parts/barra_acoes.cfm"),
    ("RoadRunners", "evento/parts/edicoes_evento.cfm"),
    ("RoadRunners", "includes/analytics/bootstrap.cfm"),
)


def sha(data):
    return hashlib.sha256(data).hexdigest()


class HighlightReleaseTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="rr-highlight-release-fixture-", dir="/private/tmp" if Path("/private/tmp").exists() else None)
        self.base = Path(self.tmp.name)
        self.roots = {site: self.base / site for site in release_tool.ROOTS}
        self.release = self.base / "release"
        self.release.mkdir(mode=0o700)
        self.new = self.roots["RoadRunners"] / "circuito/live_highlight.cfm"
        self.existing = self.roots["RoadRunners"] / "circuito/index.cfm"
        self.existing.parent.mkdir(parents=True)
        self.before = b"<cfoutput>existing circuit</cfoutput>\n"
        self.existing.write_bytes(self.before)
        self.existing.chmod(0o640)
        os.utime(self.existing, ns=(1650000000000000000, 1650000001000000000))
        self.meta = release_tool.metadata(self.existing)
        self.after = {}
        rows = []
        for site, path in (("RoadRunners", "circuito/live_highlight.cfm"), ("RoadRunners", "circuito/index.cfm")):
            candidate = self.release / "candidate" / site / path
            candidate.parent.mkdir(parents=True, exist_ok=True)
            self.after[path] = f"<cfoutput>new {path}</cfoutput>\n".encode()
            candidate.write_bytes(self.after[path])
            before = "ABSENT" if path.endswith("live_highlight.cfm") else sha(self.before)
            rows.append(f"{site}\t{path}\t{before}\t{sha(self.after[path])}\n")
        (self.release / "runtime.tsv").write_text("".join(rows))
        for site, paths in release_tool.GUARD_FILES.items():
            for path in paths:
                file = self.roots[site] / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_bytes(f"guard {site}/{path}\n".encode())
        for site, paths in release_tool.GUARD_TREES.items():
            for path in paths:
                directory = self.roots[site] / path
                directory.mkdir(parents=True, exist_ok=True)
                (directory / "existing.sql").write_bytes(b"select 1;\n")
        self.engine = release_tool.Release(self.release, self.roots, (os.getuid(), os.getgid()))

    def tearDown(self):
        self.tmp.cleanup()

    def assert_original(self):
        self.assertFalse(self.new.exists())
        self.assertEqual(self.existing.read_bytes(), self.before)
        self.assertEqual(release_tool.metadata(self.existing), self.meta)

    def test_two_file_roundtrip_preserves_backup_metadata_and_new_absence(self):
        self.engine.run("prepare")
        self.assert_original()
        self.engine.run("verify")
        state = json.loads((self.release / "state.json").read_text())
        self.assertEqual(len(state["files"]), 2)
        event = json.loads((self.release / "operations.jsonl").read_text().splitlines()[0])
        self.assertEqual((event["existing"], event["absent"]), (1, 1))
        self.engine.run("publish")
        self.engine.run("verify")
        self.assertEqual(self.new.read_bytes(), self.after["circuito/live_highlight.cfm"])
        self.assertEqual(self.new.stat().st_mode & 0o7777, 0o644)
        self.assertEqual(self.existing.read_bytes(), self.after["circuito/index.cfm"])
        published = release_tool.metadata(self.existing)
        self.assertGreaterEqual(published["mtime_ns"], self.meta["mtime_ns"] + 1_000_000_000)
        self.assertEqual({**published, "mtime_ns": self.meta["mtime_ns"]}, self.meta)
        self.engine.run("rollback")
        self.engine.run("rollback")
        self.engine.run("verify")
        self.assert_original()

    def test_each_of_eleven_measurement_files_is_protected_and_blocks_publish_on_drift(self):
        self.engine.run("prepare")
        for site, path in MEASUREMENT:
            with self.subTest(site=site, path=path):
                protected = self.roots[site] / path
                old = protected.read_bytes()
                protected.write_bytes(b"concurrent measurement edit")
                with self.assertRaises(release_tool.ReleaseError):
                    self.engine.run("publish")
                self.assert_original()
                protected.write_bytes(old)
        self.engine.run("publish")
        self.engine.run("verify")

    def test_existing_runtime_hash_drift_is_preserved_before_any_publication(self):
        self.engine.run("prepare")
        self.existing.write_bytes(b"concurrent circuit edit")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assertEqual(self.existing.read_bytes(), b"concurrent circuit edit")
        self.assertFalse(self.new.exists())

    def test_explicit_rollback_preserves_concurrent_hash_change_and_removes_unchanged_new(self):
        self.engine.run("prepare")
        self.engine.run("publish")
        self.existing.write_bytes(b"newer operator change")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("rollback")
        self.assertEqual(self.existing.read_bytes(), b"newer operator change")
        self.assertFalse(self.new.exists())
        self.assertEqual(json.loads((self.release / "state.json").read_text())["phase"], "rollback_conflict")

    def test_failure_on_second_install_automatically_restores_new_absence(self):
        self.engine.run("prepare")
        actual = self.engine.install

        def fail_second(row, source, meta):
            if row["path"] == "circuito/index.cfm":
                raise OSError("simulated filesystem failure")
            return actual(row, source, meta)

        with patch.object(self.engine, "install", side_effect=fail_second):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("publish")
        self.assert_original()
        self.engine.run("verify")

    def test_new_file_creation_is_exclusive_even_after_last_absence_check(self):
        self.engine.run("prepare")
        actual = self.engine.check_before

        def raced(rows):
            actual(rows)
            if len(rows) == 1 and rows[0]["path"] == "circuito/live_highlight.cfm":
                self.new.write_bytes(b"concurrent new include")

        with patch.object(self.engine, "check_before", side_effect=raced):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("publish")
        self.assertEqual(self.new.read_bytes(), b"concurrent new include")
        self.assertEqual(self.existing.read_bytes(), self.before)

    def test_shared_hardlink_guard_is_readable_but_edit_via_alias_blocks_publish(self):
        guard = self.roots["RoadRunners"] / "config/audience.local.cfm"
        alias = self.base / "shared-audience-config"
        os.link(guard, alias)
        self.engine.run("prepare")
        self.engine.run("verify")
        alias.write_bytes(b"config edited through shared hard link")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assert_original()

    def test_only_two_authorized_paths_in_fixed_order_are_allowed(self):
        manifest = self.release / "runtime.tsv"
        original = manifest.read_text()
        bad_manifests = (
            "".join(reversed(original.splitlines(keepends=True))),
            original.replace("circuito/index.cfm", "assets/js/rr-audience.js"),
            original.replace("RoadRunners", "Business"),
            original.replace("ABSENT", "0" * 64),
        )
        for bad in bad_manifests:
            with self.subTest(manifest=bad):
                manifest.write_text(bad)
                with self.assertRaises(release_tool.ReleaseError):
                    self.engine.run("prepare")
                self.assert_original()
        manifest.write_text(original)

    def test_bad_candidate_symlink_and_hardlink_are_refused(self):
        candidate = self.release / "candidate/RoadRunners/circuito/live_highlight.cfm"
        contents = candidate.read_bytes()
        candidate.write_bytes(b"corrupt candidate")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        candidate.write_bytes(contents)
        alias = self.base / "candidate-alias"
        os.link(candidate, alias)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        candidate.unlink()
        candidate.symlink_to(alias)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        self.assert_original()


if __name__ == "__main__":
    unittest.main(verbosity=2)
