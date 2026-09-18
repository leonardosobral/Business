"""Exercise the paid-banner release boundary without a production connection."""
import importlib
import sys
from pathlib import Path
from unittest.mock import patch
import unittest

from test_house_banner_publisher import BannerPublisherTests, PUBLISHER


class PaidBannerPublisherTests(BannerPublisherTests):
    def setUp(self):
        super().setUp()
        self.addCleanup(setattr, PUBLISHER, 'ALLOWED', PUBLISHER.ALLOWED)
        scripts = Path(__file__).resolve().parents[1] / 'scripts'
        with patch.dict(sys.modules, {'deploy_house_banner_scope': PUBLISHER}), patch.object(
                sys, 'path', [str(scripts), *sys.path]):
            importlib.import_module('deploy_paid_banners')

    def test_paid_workspace_candidate_can_be_packaged(self):
        self.rows[0]['path'] = 'portal/includes/paid_banner_home.cfm'
        self.write_manifest()
        # The shared publisher's scope validation must reach transport for this
        # newly added runtime, not reject it as a HOUSE-only release.
        with patch.object(PUBLISHER.subprocess, 'run', side_effect=RuntimeError('transport boundary')):
            with self.assertRaisesRegex(RuntimeError, 'transport boundary'):
                self.invoke(PUBLISHER.subprocess.run)

    def test_sql_and_private_configuration_cannot_be_published(self):
        for site, path in [
            ('RoadRunners', '_codex/sql/2026-09-16_ads_paid_banners.sql'),
            ('RoadRunners', 'config/ads.local.cfm'),
            ('Business', 'Application.cfm'),
            ('RoadRunners', 'includes/eventos_ads.cfm'),
        ]:
            with self.subTest(site=site, path=path):
                self.rows[0].update(site=site, path=path)
                self.write_manifest()
                with patch.object(PUBLISHER.subprocess, 'run') as transport:
                    with self.assertRaisesRegex(AssertionError, 'Out-of-scope'):
                        self.invoke(transport)
                    transport.assert_not_called()


if __name__ == '__main__':
    unittest.main()
