"""Boundary checks for external SEO evidence; fixtures are synthetic."""
import copy
import importlib.util
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / 'scripts/seo_semrush_snapshot.py'

def fixture():
    return {
        'schema_version': 1, 'source': 'Semrush MCP', 'target': 'roadrunners.run',
        'database': 'br', 'device': 'desktop', 'collected_at': '2026-10-04T17:15:54Z',
        'reports': [
            {'report': 'domain_rank', 'params': {'target': 'roadrunners.run', 'database': 'br'}, 'response': {'data': 'Domain;Organic Keywords;Organic Traffic;X0;X1;X2\nroadrunners.run;100;80;2;8;15\n'}},
            {'report': 'resource_organic', 'params': {'target': 'roadrunners.run', 'database': 'br'}, 'response': {'data': 'Keyword;Position;Previous Position;Search Volume;Url;Keyword Difficulty;Timestamp\n"corrida; sp";16;0;720;https://roadrunners.run/estado/sp/;27;1790243149\n'}},
            {'report': 'domain_organic_organic', 'params': {'domain': 'roadrunners.run', 'database': 'br'}, 'response': {'data': 'Domain;Competitor Relevance;Common Keywords;Organic Keywords;Organic Traffic\nexample.org;0.1;4;120;90\n'}},
            {'report': 'campaigns', 'response': {'data': {'targets': None}}}
        ]
    }

class SnapshotTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        assert MODULE.exists(), 'The Semrush evidence normalizer has not been implemented'
        spec = importlib.util.spec_from_file_location('seo_semrush_snapshot', MODULE)
        cls.mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.mod)

    def test_deduplicates_overlapping_samples_and_preserves_unknown_previous_position(self):
        a = fixture(); a['reports'].append(copy.deepcopy(a['reports'][1]))
        got = self.mod.build_snapshot(a)
        self.assertEqual(len(got['keywords']), 1)
        self.assertEqual(got['sampleRows'], 2)
        self.assertEqual(got['keywords'][0]['keyword'], 'corrida; sp')
        self.assertIsNone(got['keywords'][0]['previousPosition'])
        self.assertEqual(got['overview']['top10'], 10)
        self.assertEqual(got['overview']['keywords'], 100)

    def test_running_audit_never_promotes_prior_error_counts(self):
        state = {'collected_at': '2026-10-04T17:30:00Z', 'response': {'data': {
            'id': 26661911, 'url': 'roadrunners.run', 'status': 'RUNNING',
            'errors': 2, 'warnings': 1088, 'last_audit': 1759845137290,
            'running_pages_crawled': 24, 'running_pages_limit': 500}}}
        got = self.mod.build_snapshot(fixture(), state)['audit']
        self.assertEqual(got['status'], 'running')
        self.assertEqual(got['crawled'], 24)
        self.assertNotIn('errors', got)
        self.assertEqual(got['lastFinishedAt'], '2025-10-07T13:52:17.290000+00:00')
        state['response']['data']['status'] = 'CHECKING'
        self.assertEqual(self.mod.build_snapshot(fixture(), state)['audit']['status'], 'running')

    def test_missing_data_is_unknown_and_real_zero_is_preserved(self):
        got = self.mod.build_snapshot(fixture())
        self.assertEqual(got['audit']['status'], 'unknown')
        self.assertEqual(got['tracking'], 'not_configured')
        a = fixture(); a['reports'][0]['response']['data'] = a['reports'][0]['response']['data'].replace(';100;80;', ';0;0;').replace(';2;8;15\n', ';0;0;0\n')
        self.assertEqual(self.mod.build_snapshot(a)['overview']['trafficEstimate'], 0)

    def test_rejects_wrong_market_and_unsafe_landing_urls(self):
        for mutate in ('market', 'url', 'domain', 'malformed'):
            a = fixture()
            if mutate == 'market': a['database'] = 'us'
            if mutate == 'url': a['reports'][1]['response']['data'] = a['reports'][1]['response']['data'].replace('https://roadrunners.run/estado/sp/', 'javascript:alert(1)')
            if mutate == 'domain': a['reports'][0]['response']['data'] = a['reports'][0]['response']['data'].replace('roadrunners.run;', 'other.example;')
            if mutate == 'malformed': a['reports'][1]['response']['data'] = 'ERROR 50 :: NOT ENOUGH UNITS'
            with self.subTest(mutate=mutate), self.assertRaises(ValueError): self.mod.build_snapshot(a)

    def test_stale_finished_audit_is_historical_not_current(self):
        state = {'collected_at': '2026-10-04T17:30:00Z', 'response': {'data': {
            'id': 26661911, 'url': 'roadrunners.run', 'status': 'FINISHED',
            'errors': 2, 'warnings': 1088, 'last_audit': 1759845137290,
            'pages_crawled': 500, 'pages_limit': 500}}}
        got = self.mod.build_snapshot(fixture(), state)['audit']
        self.assertEqual(got['status'], 'historical')
        self.assertNotIn('errors', got)

    def test_opportunity_ids_do_not_shift_when_earlier_keyword_is_absent(self):
        a = fixture()
        a['reports'][1]['response']['data'] = a['reports'][1]['response']['data'].replace('"corrida; sp"', 'corridas es')
        self.assertEqual(self.mod.build_snapshot(a)['opportunities'][0]['id'], 'SR-02')

if __name__ == '__main__': unittest.main()
