import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('domains_snapshot', ROOT / '_codex/scripts/seo_domains_snapshot.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
DOM = (ROOT / '_codex/staging/seo-domains-20261025/semrush-month-dom.txt').read_text()
STAMP = '2026-10-25T15:03:00-03:00'


class SnapshotTests(unittest.TestCase):
    def test_capture_is_watchlist_not_project_cards(self):
        data = module.parse_dom(DOM, STAMP)
        self.assertEqual(data['count'], 27)
        self.assertEqual({row['country'] for row in data['domains']}, {'BR'})
        rr = next(row for row in data['domains'] if row['domain'] == 'roadrunners.run')
        op = next(row for row in data['domains'] if row['domain'] == 'openresults.run')
        self.assertEqual(rr['ranks']['traffic'], 17)
        self.assertEqual(rr['ranks']['keywords'], 17)
        self.assertEqual(rr['metrics']['traffic']['change'], 191.3)
        self.assertEqual(op['metrics']['traffic']['value'], 764)
        self.assertNotEqual(op['metrics']['traffic']['value'], 22)  # Project card has a different base.
        self.assertEqual(data, json.loads((ROOT / '_codex/analyses/seo_domains/2026-10-25T150300-0300.json').read_text()))

    def test_abbreviations_and_units(self):
        self.assertEqual(module.compact('1,3K'), 1300)
        self.assertEqual(module.compact('1.3K'), 1300)
        self.assertEqual(module.compact('1,9M'), 1900000)
        self.assertEqual(module.compact('0'), 0)
        self.assertIsNone(module.compact('n.d.'))
        self.assertTrue(module.metric('Chart 22 -3 Chart', 'points')['changeAvailable'])
        with self.assertRaises(ValueError): module.metric('Chart 22 -3% Chart', 'points')
        with self.assertRaises(ValueError): module.metric('100 +1 Chart', 'percent')

    def test_missing_is_not_zero(self):
        absent = module.metric('n.d. n.d. Chart', 'percent')
        zero = module.metric('0 0% Chart', 'percent')
        self.assertFalse(absent['available'])
        self.assertFalse(absent['changeAvailable'])
        self.assertTrue(zero['available'])
        self.assertTrue(zero['changeAvailable'])

    def test_reject_changed_scope_or_period(self):
        for changed in [DOM.replace('radio "Mês" [checked]', 'radio "Mês"'), DOM.replace('gridcell "roadrunners.run BR"', 'gridcell "roadrunners.run US"'), DOM.replace('Domínios de ref. Authority Score', 'Backlinks Authority Score')]:
            with self.assertRaises(ValueError): module.parse_dom(changed, STAMP)
        with self.assertRaises(ValueError): module.parse_dom(DOM, '2026-10-25T15:03:00')

    def test_reject_incomplete_or_duplicate_rows(self):
        incomplete = DOM.replace('        - gridcell "3,2K +191.3% Chart":', '        - ignored:')
        with self.assertRaises(ValueError): module.parse_dom(incomplete, STAMP)
        duplicate = DOM.replace('gridcell "openresults.run BR"', 'gridcell "roadrunners.run BR"')
        with self.assertRaises(ValueError): module.parse_dom(duplicate, STAMP)

    def test_runtime_keeps_admin_get_only_and_direct_guards(self):
        rendered = module.render(module.parse_dom(DOM, STAMP))
        self.assertIn('require_admin.cfm', rendered)
        self.assertIn('statuscode="403"', rendered)
        self.assertIn('statuscode="405"', rendered)
        self.assertIn('name="Allow" value="GET"', rendered)
        self.assertNotIn('statustext', rendered)


if __name__ == '__main__':
    unittest.main()
