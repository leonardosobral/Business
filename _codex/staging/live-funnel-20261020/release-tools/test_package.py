"""Package-only tests, with fake candidate and captured baseline files; no remote activity."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_support import publisher, load_package, archive_files
from build_manifest import build


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='rr-package-test-', dir='/private/tmp')
        self.base = Path(self.temp.name)
        self.release = self.base / 'release'
        self.baseline = self.base / 'baseline'
        evidence = []
        for site, path in publisher.ORDER:
            candidate = self.release / 'candidate' / site / path
            candidate.parent.mkdir(parents=True, exist_ok=True)
            candidate.write_bytes(f'new {site}/{path}'.encode())
            if (site, path) not in publisher.NEW_FILES:
                source = self.baseline / site / path
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_bytes(f'old {site}/{path}'.encode())
                evidence.append({'site': site, 'path': path, 'sha': hashlib.sha256(source.read_bytes()).hexdigest()})
        self.evidence = self.base / 'capture.json'
        self.evidence.write_text(json.dumps(evidence))

    def tearDown(self):
        self.temp.cleanup()

    def test_manifest_binds_twelve_ordered_candidates_and_archive_exact_bytes(self):
        self.assertEqual(build(self.release, self.baseline, [self.evidence]), 12)
        rows, digest, files = load_package(self.release)
        self.assertEqual([(r['site'], r['path']) for r in rows], list(publisher.ORDER))
        self.assertEqual(sum(r['before'] == 'ABSENT' for r in rows), 2)
        with tarfile.open(fileobj=io.BytesIO(archive_files(files)), mode='r:') as archive:
            self.assertEqual(len(archive.getmembers()), 12)
            for row in rows:
                name = f"{row['site']}/{row['path']}"
                self.assertEqual(hashlib.sha256(archive.extractfile(name).read()).hexdigest(), row['after'])

    def test_manifest_never_overwrites_prior_manifest_or_changed_baseline(self):
        site, path = publisher.ORDER[2]
        baseline = self.baseline / site / path
        original = baseline.read_bytes()
        baseline.write_bytes(b'captured bytes changed')
        with self.assertRaises(publisher.ReleaseError):
            build(self.release, self.baseline, [self.evidence])
        self.assertFalse((self.release / 'runtime.tsv').exists())
        baseline.write_bytes(original)
        build(self.release, self.baseline, [self.evidence])
        with self.assertRaises(FileExistsError):
            build(self.release, self.baseline, [self.evidence])

    def test_partial_package_requires_explicit_subset_and_remains_ordered(self):
        site, path = publisher.ORDER[-1]
        (self.release / 'candidate' / site / path).unlink()
        with self.assertRaises(publisher.ReleaseError):
            build(self.release, self.baseline, [self.evidence])
        self.assertEqual(build(self.release, self.baseline, [self.evidence], allow_subset=True), 11)
        rows, _, _ = load_package(self.release)
        self.assertEqual([(r['site'], r['path']) for r in rows], list(publisher.ORDER[:-1]))

    def test_extra_candidate_and_tampered_candidate_are_rejected(self):
        extra = self.release / 'candidate/RoadRunners/Application.cfc'
        extra.write_bytes(b'unreviewed')
        with self.assertRaises(publisher.ReleaseError):
            build(self.release, self.baseline, [self.evidence])
        extra.unlink()
        build(self.release, self.baseline, [self.evidence])
        site, path = publisher.ORDER[0]
        (self.release / 'candidate' / site / path).write_bytes(b'tampered')
        with self.assertRaises(publisher.ReleaseError):
            load_package(self.release)

    def test_remote_wrappers_have_no_execution_on_import(self):
        root = Path(__file__).resolve().parents[1]
        with patch('subprocess.run', side_effect=AssertionError('remote operation during import')):
            for name in ('compile_private', 'release_remote'):
                spec = importlib.util.spec_from_file_location(name, root / f'{name}.py')
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                self.assertTrue(callable(module.main))


if __name__ == '__main__':
    unittest.main(verbosity=2)
