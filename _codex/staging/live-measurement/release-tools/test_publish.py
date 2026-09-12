"""Offline filesystem tests. Never reads or writes the real webroots."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("live_release", Path(__file__).with_name("publish.py"))
release_tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release_tool)


def sha(data):
    return hashlib.sha256(data).hexdigest()


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="rr-release-fixture-", dir="/private/tmp" if Path("/private/tmp").exists() else None)
        self.base = Path(self.tmp.name)
        self.roots = {site: self.base / site for site in release_tool.ROOTS}
        self.release = self.base / "release"
        self.release.mkdir(mode=0o700)
        self.original = {}
        self.new = {}
        rows = []
        for site, path in release_tool.ORDER:
            key = f"{site}/{path}"
            target = self.roots[site] / path
            target.parent.mkdir(parents=True, exist_ok=True)
            old, new = (f"before {key}\n".encode(), f"after {key}\n".encode())
            self.new[key] = new
            before = "ABSENT"
            if (site, path) not in release_tool.NEW_FILES:
                target.write_bytes(old)
                target.chmod(0o640)
                os.utime(target, ns=(1650000000000000000, 1650000001000000000))
                self.original[key] = (old, release_tool.metadata(target))
                before = sha(old)
            candidate = self.release / "candidate" / key
            candidate.parent.mkdir(parents=True, exist_ok=True)
            candidate.write_bytes(new)
            rows.append(f"{site}\t{path}\t{before}\t{sha(new)}\n")
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
        for site, path in release_tool.ORDER:
            key = f"{site}/{path}"
            file = self.roots[site] / path
            if key in self.original:
                data, meta = self.original[key]
                self.assertEqual(file.read_bytes(), data, key)
                self.assertEqual(release_tool.metadata(file), meta, key)
            else:
                self.assertFalse(file.exists(), key)

    def test_prepare_does_not_change_runtime_and_roundtrip_restores_metadata_and_absence(self):
        self.engine.run("prepare")
        self.assert_original()
        state = json.loads((self.release / "state.json").read_text())
        self.assertEqual(len(state["files"]), 11)
        self.assertEqual(sum(row["before"] == "ABSENT" for row in state["files"]), 2)
        self.engine.run("publish")
        self.engine.run("verify")
        for site, path in release_tool.ORDER:
            key = f"{site}/{path}"
            file = self.roots[site] / path
            self.assertEqual(file.read_bytes(), self.new[key])
            if key in self.original:
                published = release_tool.metadata(file)
                original_meta = self.original[key][1]
                self.assertGreaterEqual(published["mtime_ns"], original_meta["mtime_ns"] + 1_000_000_000)
                self.assertEqual({**published, "mtime_ns": original_meta["mtime_ns"]}, original_meta)
            else:
                self.assertEqual(file.stat().st_mode & 0o7777, 0o644)
        self.engine.run("rollback")
        self.assert_original()
        self.engine.run("verify")

    def test_rejects_wrong_order_path_or_absence_before_any_write(self):
        manifest = self.release / "runtime.tsv"
        original = manifest.read_text()
        rows = original.splitlines(keepends=True)
        for bad in ("".join(reversed(rows)), original.replace("portal/audiencia/home.cfm", "../Application.cfc"), original.replace("ABSENT", "0" * 64, 1)):
            with self.subTest(bad=bad[:100]):
                manifest.write_text(bad)
                with self.assertRaises(release_tool.ReleaseError):
                    self.engine.run("prepare")
                self.assert_original()
        manifest.write_text(original)

    def test_rejects_bad_candidate_and_existing_new_file(self):
        site, path = release_tool.ORDER[0]
        candidate = self.release / "candidate" / site / path
        candidate.write_bytes(b"tampered")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        candidate.write_bytes(self.new[f"{site}/{path}"])
        site, path = next(iter(release_tool.NEW_FILES))
        (self.roots[site] / path).write_bytes(b"concurrent existing file")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        self.assertFalse((self.release / "before").exists())

    def test_rejects_target_or_candidate_symlink_and_symlink_parent(self):
        site, path = release_tool.ORDER[0]
        candidate = self.release / "candidate" / site / path
        content = candidate.read_bytes()
        other = self.base / "other"
        other.write_bytes(content)
        candidate.unlink()
        candidate.symlink_to(other)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        candidate.unlink()
        candidate.write_bytes(content)
        parent = candidate.parent
        relocated = parent.with_name(parent.name + "-moved")
        parent.rename(relocated)
        parent.symlink_to(relocated, target_is_directory=True)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        parent.unlink()
        relocated.rename(parent)
        target = self.roots[site] / path
        if target.exists():
            target.unlink()
        target.symlink_to(other)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")

    def test_publish_rechecks_all_baselines_and_guards_before_first_replacement(self):
        self.engine.run("prepare")
        site, path = release_tool.ORDER[-1]
        file = self.roots[site] / path
        file.write_bytes(b"concurrent runtime change")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        first_site, first_path = release_tool.ORDER[0]
        first = self.roots[first_site] / first_path
        self.assertFalse(first.exists())
        file.write_bytes(self.original[f"{site}/{path}"][0])
        release_tool.apply_metadata(file, self.original[f"{site}/{path}"][1])
        guard = self.roots["RoadRunners"] / "circuito/index.cfm"
        guard.write_bytes(b"concurrent protected change")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assertFalse(first.exists())

    def test_existing_sql_addition_is_a_guard_failure_but_new_query_is_allowed(self):
        self.engine.run("prepare")
        file = self.roots["Business"] / "portal/audiencia/queries/another.sql"
        file.write_bytes(b"select 2;")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        file.unlink()
        self.engine.run("publish")
        self.engine.run("verify")

    def test_backup_tamper_stops_publish_without_runtime_changes(self):
        self.engine.run("prepare")
        key = next(iter(self.original))
        (self.release / "before" / key).write_bytes(b"tampered backup")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assert_original()

    def test_partial_failure_rolls_back_in_reverse_and_preserves_concurrent_change(self):
        self.engine.run("prepare")
        actual = self.engine.install
        calls = []
        first_site, first_path = release_tool.ORDER[0]
        conflicted = self.roots[first_site] / first_path

        def fail_at_fourth(row, source, meta):
            calls.append((row["site"], row["path"]))
            if len(calls) == 4:
                conflicted.write_bytes(b"newer operator change")
                raise OSError("simulated failure after partial publication")
            return actual(row, source, meta)

        with patch.object(self.engine, "install", side_effect=fail_at_fourth):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("publish")
        self.assertEqual(conflicted.read_bytes(), b"newer operator change")
        state = json.loads((self.release / "state.json").read_text())
        self.assertEqual(state["phase"], "rollback_conflict")
        self.assertTrue(any(first_path in item for item in state["rollbackConflicts"]))
        for site, path in release_tool.ORDER[1:]:
            key = f"{site}/{path}"
            target = self.roots[site] / path
            if key in self.original:
                self.assertEqual(target.read_bytes(), self.original[key][0])
            else:
                self.assertFalse(target.exists())

    def test_verification_failure_triggers_automatic_rollback_and_keeps_guard_change(self):
        self.engine.run("prepare")
        actual = self.engine.install
        guard = self.roots["RoadRunners"] / "circuito/index.cfm"

        def mutate_guard_at_last(row, source, meta):
            result = actual(row, source, meta)
            if (row["site"], row["path"]) == release_tool.ORDER[-1]:
                guard.write_bytes(b"changed externally during publish")
            return result

        with patch.object(self.engine, "install", side_effect=mutate_guard_at_last):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("publish")
        self.assert_original()
        self.assertEqual(guard.read_bytes(), b"changed externally during publish")

    def test_rollback_does_not_need_candidate_and_is_idempotent(self):
        self.engine.run("prepare")
        self.engine.run("publish")
        site, path = release_tool.ORDER[0]
        (self.release / "candidate" / site / path).unlink()
        self.engine.run("rollback")
        self.engine.run("rollback")
        self.assert_original()

    def test_new_file_created_after_final_absence_check_is_never_overwritten(self):
        self.engine.run("prepare")
        actual = self.engine.check_before
        site, path = release_tool.ORDER[0]
        raced = self.roots[site] / path

        def race_after_check(rows):
            actual(rows)
            if len(rows) == 1 and (rows[0]["site"], rows[0]["path"]) == (site, path):
                raced.write_bytes(b"concurrent file created in the last interval")

        with patch.object(self.engine, "check_before", side_effect=race_after_check):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("publish")
        self.assertEqual(raced.read_bytes(), b"concurrent file created in the last interval")
        self.assertEqual(json.loads((self.release / "state.json").read_text())["phase"], "rollback_conflict")

    def test_hardlinked_candidate_is_refused(self):
        site, path = release_tool.ORDER[0]
        candidate = self.release / "candidate" / site / path
        os.link(candidate, self.base / "hardlinked-candidate")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        self.assert_original()

    def test_hardlinked_readonly_guard_is_allowed_but_change_via_alias_blocks_publish(self):
        guard = self.roots["RoadRunners"] / "config/audience.local.cfm"
        alias = self.base / "shared-audience-config"
        os.link(guard, alias)
        self.engine.run("prepare")
        self.engine.run("verify")
        alias.write_bytes(b"configuration changed via its other hard link")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assert_original()

    def test_hardlinked_runtime_and_backup_are_still_refused(self):
        site, path = release_tool.ORDER[2]
        target = self.roots[site] / path
        alias = self.base / "runtime-alias"
        os.link(target, alias)
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("prepare")
        alias.unlink()
        self.engine.run("prepare")
        backup = self.release / "before" / site / path
        os.link(backup, self.base / "backup-alias")
        with self.assertRaises(release_tool.ReleaseError):
            self.engine.run("publish")
        self.assert_original()

    def test_different_filesystem_is_refused(self):
        site, path = release_tool.ORDER[0]
        different_parent = (self.roots[site] / path).parent
        original_stat = Path.stat

        def changed_device(path, *args, **kwargs):
            result = original_stat(path, *args, **kwargs)
            if path == different_parent:
                values = list(result)
                values[2] += 1
                return os.stat_result(values)
            return result

        with patch.object(Path, "stat", new=changed_device):
            with self.assertRaises(release_tool.ReleaseError):
                self.engine.run("prepare")
        self.assert_original()


if __name__ == "__main__":
    unittest.main(verbosity=2)
