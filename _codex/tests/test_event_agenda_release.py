"""Exercise the exact derived publisher against temporary files, never SSH."""
import importlib.util
from pathlib import Path
import sys
import types
import unittest

root = Path(__file__).resolve().parents[2]
deploy = root / '_codex/scripts/deploy_event_agenda.py'
# Only assembly of the publisher; stop before any packaging or external action.
prefix = deploy.read_text().split("\nif mode=='prepare':", 1)[0]
context = {'__file__': str(deploy), '__name__': 'offline_assembly'}
saved_argv = sys.argv
try:
    sys.argv = [str(deploy), 'prepare']
    exec(compile(prefix, str(deploy), 'exec'), context)
finally:
    sys.argv = saved_argv
publisher = types.ModuleType('agenda_release')
exec(compile(context['publisher'], 'derived-publish.py', 'exec'), publisher.__dict__)
spec = importlib.util.spec_from_file_location('fixture_helpers', root / '_codex/staging/live-measurement/release-tools/test_publish.py')
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
helpers.release_tool = publisher


class AgendaReleaseTest(unittest.TestCase):
    setUp = helpers.ReleaseTest.setUp
    tearDown = helpers.ReleaseTest.tearDown
    assert_original = helpers.ReleaseTest.assert_original

    def test_authorized_existing_query_roundtrip(self):
        self.engine.run('prepare')
        self.engine.run('publish')
        self.engine.run('verify')
        for site, name in publisher.ORDER:
            self.assertEqual((self.roots[site] / name).read_bytes(), self.new[f'{site}/{name}'])
        self.engine.run('rollback')
        self.assert_original()
        self.engine.run('verify')

    def test_concurrent_target_change_is_still_rejected(self):
        self.engine.run('prepare')
        site, name = publisher.ORDER[0]
        target = self.roots[site] / name
        target.write_bytes(b'concurrent edit')
        with self.assertRaises(publisher.ReleaseError):
            self.engine.run('publish')
        self.assertEqual(target.read_bytes(), b'concurrent edit')

    def test_unrelated_query_change_is_still_rejected(self):
        self.engine.run('prepare')
        sibling = self.roots['Business'] / 'portal/audiencia/queries/existing.sql'
        sibling.write_bytes(b'concurrent unrelated query')
        with self.assertRaises(publisher.ReleaseError):
            self.engine.run('publish')
        self.assert_original()

    def test_candidate_tampering_is_still_rejected(self):
        self.engine.run('prepare')
        site, name = publisher.ORDER[0]
        (self.release / 'candidate' / site / name).write_bytes(b'tampered candidate')
        with self.assertRaises(publisher.ReleaseError):
            self.engine.run('publish')
        self.assert_original()

    def test_published_target_hash_is_still_verified(self):
        self.engine.run('prepare')
        self.engine.run('publish')
        site, name = publisher.ORDER[0]
        (self.roots[site] / name).write_bytes(b'changed after publication')
        with self.assertRaises(publisher.ReleaseError):
            self.engine.run('verify')


if __name__ == '__main__':
    unittest.main(verbosity=2)
