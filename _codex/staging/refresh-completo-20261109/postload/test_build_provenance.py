import copy
import importlib.util
import json
from pathlib import Path
import sys
import unittest

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from build_provenance import annotate_final

class ProvenanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runs={str(cid):json.loads((HERE/'runs'/f'{cid}.json').read_text()) for cid in (353,413)}
        cls.source={'audit':json.loads((HERE.parent/'postload-audit/metadata.json').read_text())['audit'],
                    'verification':json.loads((HERE.parent/'postload-audit/verification.json').read_text())}

    def test_adds_loaded_source_without_rewriting_calculation_or_historical_json(self):
        historical=json.dumps({'valor':'9007199254740993.1234567890123456789','nota':'Histórico: congelamento 218','captura':'2026-10-05','execucao':210},ensure_ascii=False)
        sql="SELECT 9007199254740993::bigint AS exact, '"+historical+"'::jsonb AS historical, 'célula 353 rev2 · congelamento 218; captura 402/210 em05/10/2026' AS provenance FROM estudo.notebook_runs WHERE id=210"
        result=annotate_final(sql,self.runs,self.source)
        self.assertIn('bi_fonte_versionada',result)
        self.assertIn('9007199254740993::bigint',result)
        self.assertIn("'"+historical+"'::jsonb",result)
        self.assertIn('célula 353 rev2 · congelamento 309; captura 402/210 em05/10/2026',result)
        self.assertNotIn('public.tbbi_fat_perfil_br_2026',result)
        self.assertIn('fat_perfil_br_2026_20261109',result)
        self.assertIn('snapshot_id',result)
        self.assertIn('308969104:308969104:',result)
        self.assertIn('hash_auditoria',result)
        self.assertIn('"quantidade":18',result)
        self.assertIn('"execucao":316',result)
        self.assertIn('"fonte_celula":353',result)
        self.assertIn('"fonte_execucao":309',result)
        self.assertNotIn("'valor',",result)
        self.assertNotIn("'denominador',",result)

    def test_preserves_inputs_and_official_capture_while_refreshing_plain_portal_notes(self):
        before=copy.deepcopy((self.runs,self.source))
        result=annotate_final("SELECT '{}'::jsonb AS payload, 'congelamento 218: regra vigente; número218 e2180' AS note, 'Notebook · célula 402 rev1 · congelamento 210 · captura 05/10/2026' AS official FROM estudo.notebook_runs",self.runs,self.source)
        self.assertIn('congelamento 309: regra vigente; número218 e2180',result)
        self.assertIn('célula 402 rev1 · congelamento 210 · captura 05/10/2026',result)
        self.assertEqual(before,(self.runs,self.source))
        self.assertNotIn('origem_resultado',result)
        marker_sql="SELECT jsonb_build_object('texto','CONFIG SOURCE REFERENCE_TESTS') AS payload"
        self.assertIn(marker_sql,annotate_final(marker_sql,self.runs,self.source))

    def test_rejects_unverified_or_stale_sources(self):
        bad=copy.deepcopy(self.source);bad['verification']['checks']['active_views_keep_all_rows']=False
        with self.assertRaises(ValueError):annotate_final("SELECT '{}'::jsonb AS payload",self.runs,bad)
        mismatch=copy.deepcopy(self.source);mismatch['verification']['snapshot_id']='wrong'
        with self.assertRaises(ValueError):annotate_final("SELECT '{}'::jsonb AS payload",self.runs,mismatch)
        bad_runs=copy.deepcopy(self.runs);bad_runs['413']['run']['started_at']='2026-10-06T23:00:00-03:00'
        with self.assertRaises(ValueError):annotate_final("SELECT '{}'::jsonb AS payload",bad_runs,self.source)
        with self.assertRaises(ValueError):annotate_final("SELECT * FROM public.tb_resultados",self.runs,self.source)

if __name__=='__main__':unittest.main()
