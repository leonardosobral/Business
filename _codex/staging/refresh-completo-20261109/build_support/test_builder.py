"""Offline contract checks; never connects to a database."""
from pathlib import Path
import copy,json,re,subprocess,sys,tempfile,unittest
W=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(W))
import build_candidate as b
BI=b.RR/'_codex/docs/brasil_que_corre_provas/integracao_bi_2026_10_06'
TRIMESTRES=b.RR/'_codex/docs/brasil_que_corre_provas/trimestres_2026_10_05'


def fixtures():
    runs={}
    for path in (BI/'recibos').glob('*.json'):
        doc=json.loads(path.read_text())
        if 'RUN' in doc:
            r=doc['RUN'];runs[str(r['cell_id'])]=r
    runs=b.normalize_runs(runs)
    for cell in (*b.ACTIVITY_CELLS,352,354,421,402):
        if cell not in runs:runs[cell]=b.conserved_run(cell)
    return runs,json.loads((BI/'candidate-2026.json').read_text())


def canonical_updates(sql):
    updates=sql[sql.index(',updates AS('):sql.index('),comparacoes AS')]
    # Only independently dated source labels may differ. All SQL expressions,
    # category rules, denominators, filters and formatting otherwise match.
    return ''.join("'SOURCE'" if kind=='literal' and text.startswith("'Notebook · célula ") else text for kind,text in b._tokens(updates))


class BuilderTests(unittest.TestCase):
    def test_cli_help_works_beside_local_inspect_module(self):
        result=subprocess.run([sys.executable,str(W/'build_candidate.py'),'--help'],capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('--steps',result.stdout)

    def test_cli_builds_historical_candidate_and_offline_manifest(self):
        runs,_=fixtures()
        metadata={str(c):{k:r[k] for k in ('id','cell_version','started_at')} for c,r in runs.items()}
        with tempfile.TemporaryDirectory(prefix='bqc-generator-fixture-') as directory:
            root=Path(directory);(root/'runs.json').write_text(json.dumps(metadata))
            result=subprocess.run([sys.executable,str(W/'build_candidate.py'),'--runs',str(root/'runs.json'),'--baseline',str(BI/'candidate-2026.json'),'--output-dir',str(root/'out'),'--steps','414'],capture_output=True,text=True,timeout=20)
            self.assertEqual(result.returncode,0,result.stderr)
            manifest=json.loads((root/'out/build-manifest.json').read_text())
            self.assertFalse(manifest['publication_changed'])
            self.assertEqual(manifest['bi_reload'],'not_verified_by_generator')
            self.assertTrue((root/'out/cell-414.sql').is_file())

    def test_projection_equations_equal_the_full_historical_builder(self):
        runs,baseline=fixtures()
        actual=b.build_themes(runs,baseline)
        old=(TRIMESTRES/'output-2026.sql').read_text()
        self.assertEqual(canonical_updates(actual),canonical_updates(old))
        self.assertEqual(actual[actual.index(',updates AS('):actual.index('),comparacoes AS')].count(' AS serie'),105)
        self.assertIn('"contrato_versao": 17',actual)
        self.assertIn("jsonb_array_elements(anterior.p->'series') WITH ORDINALITY",actual)
        for cell in b.SOURCE_CELLS.values():
            self.assertRegex(actual,r'cell_id='+str(cell)+r' AND cell_version=\d+ AND frozen')
        # The whole-study builder must actually project these source blocks.
        for block in ("'perfil_cards' AS serie","'outros_esportes' AS serie","'inscricoes_geral_cobertura' AS serie","'coleta_cobertura_cadastral' AS serie","'mapeamento_real' AS serie"):
            self.assertIn(block,actual)
        self.assertEqual(len(baseline['series']),137)

    def test_new_source_metadata_is_used_without_changing_equations(self):
        runs,baseline=fixtures()
        old=b.build_themes(runs,baseline)
        refreshed=copy.deepcopy(runs)
        for r in refreshed.values():
            r['id']+=10000;r['cell_version']+=1;r['started_at']='2026-11-09T15:40:00-03:00'
        actual=b.build_themes(refreshed,baseline)
        self.assertEqual(canonical_updates(actual),canonical_updates(old))
        self.assertIn('coleta 09/11/2026',actual)
        self.assertIn("id=10216 AND cell_id=343 AND cell_version=3 AND frozen",actual)
        self.assertNotIn('Auditoria célula413 congelamento215:4.502.542',actual)

    def test_missing_active_source_fails_instead_of_using_old_data(self):
        runs,baseline=fixtures();runs.pop(361)
        with self.assertRaisesRegex(ValueError,'missing perfil-q3'):
            b.build_themes(runs,baseline)

    def test_bad_source_state_is_rejected(self):
        for extra in ({'frozen':False},{'truncated':True},{'status':'error'}):
            with self.assertRaises(ValueError):b.normalize_runs({'343':dict(id=1,cell_version=2,**extra)})
        self.assertEqual(b.normalize_runs({'343':{'id':1,'cellversion':2,'frozen':1,'truncated':0}})[343]['cell_version'],2)

    def test_run_remapping_preserves_counts_literals_and_event_ids(self):
        sql="SELECT 233 AS count, '233' AS quoted, '{\"celula\":251,\"revisao\":39,\"execucao\":233}'::jsonb AS meta FROM estudo.notebook_runs WHERE id=233 AND cell_id=251 AND cell_version=39 AND frozen"
        actual=b.remap_frozen_references(sql,{251:{'id':10000,'cell_version':40,'started_at':'2026-11-09'}})
        self.assertIn("SELECT 233 AS count, '233' AS quoted",actual)
        self.assertIn('WHERE id=10000 AND cell_id=251 AND cell_version=40 AND frozen',actual)
        self.assertIn('"execucao": 10000',actual)

    def test_derived_queries_point_to_all_new_frozen_inputs(self):
        runs,_=fixtures()
        fresh=copy.deepcopy(runs)
        for r in fresh.values():r['id']+=10000
        a=b.build_derived(377,fresh)
        for cell in b.ACTIVITY_CELLS:self.assertIn(str(fresh[cell]['id']),a)
        ages=b.build_derived(380,fresh)
        for cell in (346,348,352,349,354,357):self.assertIn('('+str(fresh[cell]['id'])+",'",ages)
        for s in (a,ages):b.assert_no_operational_sources(s)

    def test_old_calendar_receipts_reproduce_every_matched_pair(self):
        runs,_=fixtures();sql,actual=b.build_pairs(runs)
        expected=json.loads((BI/'edicoes-q3.json').read_text())
        for key in ('coorte_pareada','somente_vinculo_cadastrado','somente_nome_normalizado','pares','pares_sem_resultados_nos_dois_anos','pares_fora_da_janela','chaves_ambiguas','pares_requerem_revisao','nao_pareados_com_resultados'):
            self.assertEqual(actual[key],expected[key],key)
        summary=json.loads(sql[sql.index("SELECT '")+8:sql.rindex("'::jsonb")].replace("''", "'"))
        self.assertEqual(len(summary['pares']),608)
        self.assertEqual(len({p['id_2025'] for p in summary['pares']}),608)
        self.assertEqual(summary['coorte_pareada']['concluintes_2026'],1210676)

    def test_final_overlay_preserves_official_floripa_and_new_definitions(self):
        runs,_=fixtures();runs[414]=dict(runs[414],id=10500,cell_version=2)
        runs[353]=dict(runs[353],id=10501,cell_version=3)
        runs[387]=dict(runs[387],id=10502,cell_version=3)
        actual=b.build_final(runs)
        self.assertIn('id=10500 AND cell_id=414 AND cell_version=2',actual)
        self.assertIn('id=10501 AND cell_id=353 AND cell_version=3',actual)
        self.assertIn('id=210 AND cell_id=402 AND cell_version=1',actual)
        self.assertIn("'series',newseries.rows",actual)
        self.assertNotIn('WHERE r.id=214',actual)
        self.assertIn('"concluintes": 3592',actual)
        self.assertNotIn("'totais_atuais',",actual)
        self.assertNotIn("'comparativo',",actual)

    def test_final_overlay_refuses_to_silently_drop_floripa(self):
        runs,_=fixtures()
        runs=copy.deepcopy(runs)
        top=runs[353]['result']['rows'][0]['payload']['top10']
        runs[353]['result']['rows'][0]['payload']['top10']=[v for v in top if str(v['id_evento'])!='34529']
        with self.assertRaisesRegex(ValueError,'absent/duplicated'):
            b.build_final(runs)

    def test_public_and_annual_are_candidates_with_real_new_references(self):
        runs,_=fixtures()
        for cell in (251,347,354,421,383,368,387,378):
            runs[cell]=dict(runs[cell],id=runs[cell]['id']+10000,cell_version=runs[cell]['cell_version']+1)
        public=b.build_public(runs)
        self.assertIn('id=10233 AND cell_id=251 AND cell_version=40',public)
        self.assertIn('id=10231 AND cell_id=387 AND cell_version=3',public)
        annual=b.build_annual(runs)
        self.assertIn('"base_inicial_run": 10233',annual)
        self.assertIn('"status": "Em revisão"',annual)
        self.assertIn('"estado": "rascunho_interno"',annual)
        self.assertIn('"periodo_alvo_fim": "2026-12-31"',annual)

    def test_projections_reject_live_operational_sources(self):
        with self.assertRaises(ValueError):b.assert_no_operational_sources('SELECT count(*) FROM public.tb_resultados')
        b.assert_no_operational_sources("SELECT 'FROM public.tb_resultados' AS note FROM estudo.notebook_runs")

if __name__=='__main__':unittest.main()
