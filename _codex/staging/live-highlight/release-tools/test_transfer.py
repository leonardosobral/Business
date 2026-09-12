"""Offline checks for package construction; subprocess/SSH must never run."""
import hashlib
import importlib.util
import io
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE))
import release_remote
import compile_private


class TransferTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="rr-highlight-package-", dir="/private/tmp" if Path("/private/tmp").exists() else None)
        self.release = Path(self.tmp.name)
        rows = []
        for i, (site, path) in enumerate(release_remote.ORDER):
            candidate = self.release / "candidate" / site / path
            candidate.parent.mkdir(parents=True, exist_ok=True)
            content = f"<cfoutput>fixture {path}</cfoutput>".encode()
            candidate.write_bytes(content)
            rows.append(f"{site}\t{path}\t{'ABSENT' if i == 0 else 'a' * 64}\t{hashlib.sha256(content).hexdigest()}\n")
        (self.release / "runtime.tsv").write_text("".join(rows))

    def tearDown(self):
        self.tmp.cleanup()

    def test_valid_archive_has_exact_two_roadrunners_templates_and_no_other_members(self):
        with patch("subprocess.run", side_effect=AssertionError("offline test attempted a subprocess")):
            archive, hashes = compile_private.build_compile_archive(self.release)
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as tar:
            self.assertEqual([member.name for member in tar.getmembers()], [f"{site}/{path}" for site, path in release_remote.ORDER])
            for member in tar.getmembers():
                self.assertTrue(member.isfile())
                self.assertEqual(hashlib.sha256(tar.extractfile(member).read()).hexdigest(), hashes[member.name])

    def test_rejects_extra_member_wrong_site_traversal_wrong_absence_and_swapped_order(self):
        path = self.release / "runtime.tsv"
        original = path.read_text()
        for wrong in (original + original.splitlines(keepends=True)[0], original.replace("RoadRunners", "Business"),
                      original.replace("circuito/index.cfm", "../Application.cfc"),
                      original.replace("ABSENT", "b" * 64), "".join(reversed(original.splitlines(keepends=True)))):
            with self.subTest(manifest=wrong):
                path.write_text(wrong)
                with self.assertRaises(ValueError):
                    compile_private.build_compile_archive(self.release)
        path.write_text(original)

    def test_bad_candidate_hash_symlink_and_hardlink_are_rejected_locally(self):
        site, path = release_remote.ORDER[0]
        candidate = self.release / "candidate" / site / path
        original = candidate.read_bytes()
        candidate.write_bytes(b"changed candidate")
        with self.assertRaises(ValueError):
            release_remote.read_package(self.release)
        candidate.write_bytes(original)
        alias = self.release / "alias"
        alias.hardlink_to(candidate)
        with self.assertRaises(ValueError):
            release_remote.read_package(self.release)
        candidate.unlink()
        candidate.symlink_to(alias)
        with self.assertRaises(ValueError):
            release_remote.read_package(self.release)

    def test_compile_remote_checks_exact_names_count_regular_members_and_hashes(self):
        archive, hashes = compile_private.build_compile_archive(self.release)
        # Run only the pure archive validator, never the remote compiler/SSH.
        members = compile_private.validate_compile_archive(archive, hashes)
        self.assertEqual(set(members), set(hashes))
        for names in (
            {"Business/circuito/live_highlight.cfm": b"x", "RoadRunners/circuito/index.cfm": b"y"},
            {"../escape.cfm": b"x", "RoadRunners/circuito/index.cfm": b"y"},
            {"RoadRunners/circuito/index.cfm": b"x"},
        ):
            with self.subTest(names=names):
                with self.assertRaises(ValueError):
                    compile_private.validate_compile_archive(release_remote.make_archive(names), hashes)
        with self.assertRaises(ValueError):
            compile_private.validate_compile_archive(archive, {key: "0" * 64 for key in hashes})


if __name__ == "__main__":
    unittest.main(verbosity=2)
