"""Static checks for reviewable SQL only. Does not connect to PostgreSQL."""
from pathlib import Path
import hashlib,json,re,unittest
W=Path(__file__).resolve().parent
M=json.loads((W/'captured-contract.json').read_text())

def code(name):
    s=(W/name).read_text()
    s=re.sub(r"'(?:''|[^'])*'", "''",s)
    return re.sub(r'--[^\n]*','',s)

class CandidateTests(unittest.TestCase):
    def test_no_destructive_or_public_writes(self):
        for path in W.glob('*.sql'):
            s=code(path.name)
            self.assertNotRegex(s,r'(?i)\b(?:DROP\s+(?:TABLE|VIEW|SCHEMA)|TRUNCATE|CASCADE)\b',path.name)
            self.assertNotRegex(s,r'(?i)\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM|ALTER\s+(?:TABLE|VIEW)|CREATE\s+(?:OR\s+REPLACE\s+)?(?:TABLE|VIEW))\s+public\.',path.name)
            self.assertNotRegex(s,r'(?i)\b(?:UPDATE|INSERT\s+INTO)\s+estudo\.(?:produtos|web_destinos|web_publicacoes)\b',path.name)
            self.assertNotIn('CREATE OR REPLACE VIEW estudo.lancamento_publico',s)

    def test_source_is_standalone_read_only_twenty_columns(self):
        s=(W/'source-select.sql').read_text()
        self.assertNotRegex(code('source-select.sql'),r'(?i)\b(?:CREATE|INSERT|UPDATE|DELETE|DO|BEGIN|COMMIT)\b')
        self.assertIn("e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'",s)
        self.assertIn('r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE',s)
        self.assertIn('public.get_id_geracao(r.idade_range,extract(year FROM r.data_final)::integer,\n                      r.data_nascimento,r.data_final)',s)
        for excluded in ("r.modalidade <> 'KIDS'","r.tempo_total IS NOT NULL","r.tempo_total>TIME","e.tipo_corrida IN"):
            self.assertNotIn(excluded,s)
        self.assertEqual(len(M['fact_columns']),20)

    def test_one_repeatable_snapshot_nine_months_and_no_intermediate_commit(self):
        for file in ('10-load-version.sql','15-load-and-cutover.sql'):
            s=(W/file).read_text()
            self.assertEqual(len(re.findall(r'^BEGIN ISOLATION LEVEL REPEATABLE READ;',s,re.M)),1)
            self.assertEqual(len(re.findall(r'^COMMIT;',s,re.M)),1)
            self.assertIn("generate_series(DATE '2026-01-01',DATE '2026-09-01',INTERVAL '1 month')",s)
            self.assertIn('txid_current_snapshot()::text',s)
            self.assertIn('GET DIAGNOSTICS v_rows=ROW_COUNT',s)
            self.assertIn('Conservação mensal dos nove meses falhou',s)
            self.assertIn('Conservação de valores/flags/NULL falhou',s)

    def test_hash_guards_and_nullable_fact_contract(self):
        s=(W/'10-load-version.sql').read_text()
        for signature,expected in M['function_md5'].items():
            self.assertIn(signature,s);self.assertIn(expected,s)
        for name,expected in M['views_md5'].items():self.assertIn(expected,s)
        fact=s[s.index('CREATE TABLE estudo.fat_perfil_br_2026_20261109 ('):s.index('CREATE TABLE estudo.fat_perfil_br_2026_20261109_audit')]
        self.assertNotIn('NOT NULL',fact)
        self.assertNotIn('DEFAULT',fact)
        for name,kind in M['fact_columns']:self.assertIn(name+' '+kind,fact)
        self.assertIn('length(sexo)>1',s)
        self.assertNotIn('r.sexo::',s)

    def test_candidates_and_cutover_are_separate_and_both_study_views_switch(self):
        s=code('10-load-version.sql')
        self.assertNotIn('CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS',s)
        for file in ('15-load-and-cutover.sql','30-cutover-study.sql'):
            s=code(file)
            self.assertIn('CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS SELECT * FROM estudo.vwbi_perfil_br_2026_20261109',s)
            self.assertIn('CREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS SELECT * FROM estudo.vw_resultados_2026_20261109',s)
            self.assertIn('activated_views',s)
        self.assertEqual(M['versioned_views_columns'],{'estudo.vwbi_perfil_br_2026':52,'estudo.vw_resultados_2026':36})

    def test_preflight_is_one_json_select_without_pii_or_correlated_date_scan(self):
        s=(W/'00-preflight.sql').read_text()
        self.assertIn('jsonb_build_object(',s)
        self.assertNotRegex(code('00-preflight.sql'),r'(?i)\b(?:CREATE|INSERT|UPDATE|DELETE|DO|BEGIN|COMMIT)\b')
        self.assertEqual(s.count(';'),1)
        self.assertIn('date_keys AS',s)
        self.assertNotIn('(SELECT count(*) FROM public.tbbi_dim_data d WHERE',s)
        load=(W/'10-load-version.sql').read_text()
        self.assertIn('JOIN (SELECT DISTINCT data_inicial FROM _bqc_q3_source',load)
        for field in ('null_pcd','null_distance','null_sex','null_time','generation','duplicate_dimension_ids'):self.assertIn(field,s)

    def test_rollback_preserves_frozen_version_and_checks_concurrent_drift(self):
        s=(W/'40-rollback-study.sql').read_text()
        self.assertIn('activated_views',s)
        self.assertIn('pg_try_advisory_xact_lock',s)
        self.assertNotRegex(code('40-rollback-study.sql'),r'(?i)\bDROP\b')
        self.assertIn('CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS',s)
        self.assertIn('CREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS',s)

    def test_entrypoints_require_real_repeatable_read_and_literal_safety(self):
        for file in ('10-load-version.sql','15-load-and-cutover.sql','30-cutover-study.sql','40-rollback-study.sql'):
            s=(W/file).read_text()
            self.assertIn('BEGIN ISOLATION LEVEL REPEATABLE READ;',s,file)
            self.assertIn('NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE',s,file)
            self.assertIn('Uma aba nova pode compartilhar conexão',s,file)
            self.assertIn('não detecta uma transação REPEATABLE READ anterior',s,file)
            self.assertIn('SET LOCAL standard_conforming_strings=on;',s,file)
            guard="IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION"
            self.assertIn(guard,s,file)
            self.assertLess(s.index(guard),s.index('pg_try_advisory_xact_lock'),file)

    def test_manifest_matches_every_sql_file(self):
        manifest=json.loads((W/'manifest.json').read_text())
        self.assertFalse(manifest['sql_executed'])
        for name,digest in manifest['files'].items():self.assertEqual(hashlib.sha256((W/name).read_bytes()).hexdigest(),digest,name)

if __name__=='__main__':unittest.main()
