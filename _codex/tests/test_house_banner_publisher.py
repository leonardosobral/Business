"""Exercise release packaging without a network connection or webroot writes."""
import ast
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shlex
import tarfile
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

REPO = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('banner_publisher', REPO / '_codex/scripts/deploy_house_banner_scope.py')
PUBLISHER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PUBLISHER)


class BannerPublisherTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='banner-publisher-test-')
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name).resolve() / 'Business'
        self.root.mkdir()
        library = self.root / '_codex/staging/live-measurement/release-tools/publish.py'
        library.parent.mkdir(parents=True)
        library.write_bytes((REPO / library.relative_to(self.root)).read_bytes())
        self.source = self.root / 'portal/banners/home.cfm'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('<cfoutput>fixture</cfoutput>')
        self.manifest = self.root / 'manifest.json'
        self.receipt = self.root / 'receipt.json'
        self.rows = [{'site': 'Business', 'path': 'portal/banners/home.cfm',
                      'candidate': str(self.source), 'before': 'a' * 64,
                      'after': hashlib.sha256(self.source.read_bytes()).hexdigest()}]
        self.write_manifest()

    def write_manifest(self):
        self.manifest.write_text(json.dumps({'files': self.rows}))

    def invoke(self, transport):
        with patch.object(PUBLISHER, 'ROOT', self.root), patch.object(PUBLISHER.subprocess, 'run', transport), patch(
                'sys.argv', ['publisher', 'prepare', str(self.manifest), str(self.receipt)]):
            PUBLISHER.main()

    def test_prepare_packages_only_declared_runtime_and_compilable_remote_program(self):
        calls = []

        def transport(command, **kwargs):
            calls.append(command)
            program = shlex.split(command[-1])[2]
            ast.parse(program)
            self.assertIn("successful\\s+1\\b", program)
            self.assertNotIn('\x08', program)
            self.assertIn("module.Release(release).run('prepare')", program)
            with tarfile.open(fileobj=io.BytesIO(kwargs['input']), mode='r:') as archive:
                self.assertEqual(set(archive.getnames()), {
                    'publisher.py', 'runtime.tsv', 'candidate/Business/portal/banners/home.cfm'})
                self.assertEqual(archive.extractfile('candidate/Business/portal/banners/home.cfm').read(), self.source.read_bytes())
            return SimpleNamespace(returncode=0, stderr=b'', stdout=json.dumps({
                'directory': '/var/backups/house-banner-scope.abc123', 'mode': 'prepare',
                'phase': 'prepared', 'guard_count': 30, 'compile_log': '/private/compile.log'}).encode())

        with patch('builtins.print'):
            self.invoke(transport)
        self.assertEqual(len(calls), 1)
        self.assertEqual(json.loads(self.receipt.read_text())['phase'], 'prepared')

    def test_out_of_scope_target_rejected_before_transport(self):
        self.rows[0]['path'] = 'Application.cfc'
        self.write_manifest()
        with patch.object(PUBLISHER.subprocess, 'run') as transport:
            with self.assertRaisesRegex(AssertionError, 'Out-of-scope'):
                self.invoke(transport)
            transport.assert_not_called()

    def test_changed_candidate_rejected_before_transport(self):
        self.source.write_text('concurrent change')
        with patch.object(PUBLISHER.subprocess, 'run') as transport:
            with self.assertRaisesRegex(AssertionError, 'Candidate drift'):
                self.invoke(transport)
            transport.assert_not_called()


if __name__ == '__main__':
    unittest.main()
