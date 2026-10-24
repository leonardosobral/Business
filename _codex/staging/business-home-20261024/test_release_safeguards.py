"""Local filesystem checks for the release guard/rollback paths; no network."""
from pathlib import Path
import importlib.util
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('home_release', Path(__file__).with_name('release_remote.py'))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class Safeguards(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory(prefix='business-home-release-test-')
        self.root = Path(self.work.name).resolve() / 'runtime'
        self.root.mkdir()
        release.ROOT = self.root
        self.stage = Path(self.work.name).resolve() / 'backup'
        self.stage.mkdir()
        self.existing = self.root / 'existing.cfm'
        self.existing.write_bytes(b'before')
        self.existing.chmod(0o640)
        self.info = release.metadata(self.existing)
        self.baseline = {
            'existing.cfm': {'exists': True, 'sha256': release.digest(b'before'), **self.info},
            'new.cfm': {'exists': False},
        }
        (self.stage / 'baseline').mkdir()
        (self.stage / 'baseline/existing.cfm').write_bytes(b'before')
        self.manifest = {
            'baseline': self.baseline,
            'candidate': {'existing.cfm': release.digest(b'after'), 'new.cfm': release.digest(b'new')},
        }

    def tearDown(self):
        self.work.cleanup()

    def test_current_baseline_then_content_drift(self):
        release.guard(self.baseline)
        self.existing.write_bytes(b'concurrent')
        with self.assertRaisesRegex(RuntimeError, 'baseline conflict'):
            release.guard(self.baseline)

    def test_metadata_drift(self):
        self.existing.chmod(0o644)
        with self.assertRaisesRegex(RuntimeError, 'metadata conflict'):
            release.guard(self.baseline)

    def test_new_path_appearing_is_conflict(self):
        (self.root / 'new.cfm').write_bytes(b'other task')
        with self.assertRaisesRegex(RuntimeError, 'baseline conflict'):
            release.guard(self.baseline)

    def test_symlink_and_traversal_are_rejected(self):
        (self.root / 'link.cfm').symlink_to(self.existing)
        for name in ('link.cfm', '../outside.cfm', '/tmp/absolute.cfm'):
            with self.subTest(name=name), self.assertRaises(RuntimeError):
                release.safe_path(name)

    def test_atomic_replace_preserves_metadata(self):
        release.atomic_replace(self.existing, b'after', self.info)
        self.assertEqual(self.existing.read_bytes(), b'after')
        self.assertEqual(release.metadata(self.existing), self.info)
        self.assertEqual(list(self.root.glob('.business-home-*')), [])

    def test_rollback_recovers_existing_and_withdraws_new(self):
        release.atomic_replace(self.existing, b'after', self.info)
        (self.root / 'new.cfm').write_bytes(b'new')
        restored = release.restore(self.stage, self.manifest, ['existing.cfm', 'new.cfm'])
        self.assertEqual(restored, ['new.cfm', 'existing.cfm'])
        self.assertEqual(self.existing.read_bytes(), b'before')
        self.assertFalse((self.root / 'new.cfm').exists())
        self.assertEqual((self.stage / 'withdrawn/new.cfm').read_bytes(), b'new')

    def test_rollback_refuses_concurrent_change_before_any_restore(self):
        release.atomic_replace(self.existing, b'after', self.info)
        (self.root / 'new.cfm').write_bytes(b'other task')
        with self.assertRaisesRegex(RuntimeError, 'Concurrent change prevents rollback'):
            release.restore(self.stage, self.manifest, ['existing.cfm', 'new.cfm'])
        self.assertEqual(self.existing.read_bytes(), b'after')
        self.assertEqual((self.root / 'new.cfm').read_bytes(), b'other task')


if __name__ == '__main__':
    unittest.main()
