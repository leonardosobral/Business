"""Local-only cutover regression tests. Production baselines are simulated here."""
import importlib.util
import atexit
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
REAL_BUSINESS = HERE.parents[3]
REAL_RR = REAL_BUSINESS.parent / 'RoadRunners'
# Immutable pre-cutover snapshots keep regression tests valid after the controller
# intentionally deploys/synchronizes the compatible version into the checkout.
_fixture_dir = tempfile.TemporaryDirectory(prefix='consumer-cutover-inputs-')
atexit.register(_fixture_dir.cleanup)
BUSINESS = Path(_fixture_dir.name) / 'Business'
RR = Path(_fixture_dir.name) / 'RoadRunners'
snapshots=HERE.parent/'postload-consumers/snapshots/local'
for site,root in [('business',BUSINESS),('portal',RR)]:
    for source in (snapshots/site).rglob('*'):
        if source.is_file():
            target=root/source.relative_to(snapshots/site)
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
for relative in ['_codex/staging/imprensa-estudos-20261019/reader-builder.py',
                 '_codex/scripts/check_rr_teams_release_hold.mjs','.rsync-filter',
                 'atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm',
                 'includes/estrutura/header.cfm','includes/backend/backend_profile_settings.cfm',
                 'api/profile/teams.cfm','teams/includes/start.cfm']:
    target=RR/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(REAL_RR/relative,target)


def module():
    path = HERE / 'consumer_cutover.py'
    if not path.exists(): raise AssertionError('The cutover helper has not been implemented')
    s = importlib.util.spec_from_file_location('consumer_cutover', path)
    m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
    return m


def ids():
    return {'publication_id': 8101, 'publication_run': 8102, 'public_run': 8103,
            'public_revision': 6, 'paired_run': 8104, 'paired_revision': 3,
            'annual_run': 8105, 'annual_revision': 4}


def baseline(m):
    import json
    old = json.loads((HERE.parent/'notebook-before.json').read_text())
    return {'captured_at': '2026-11-09T23:00:00-03:00',
            'files': {p: {'local_sha256': m.sha(m.path_for(p, BUSINESS, RR).read_bytes()),
                          'production_sha256': m.sha(m.path_for(p, BUSINESS, RR).read_bytes())}
                      for p in m.REQUIRED_FILES},
            'generator_sha256': m.sha(m.reader_path(RR).read_bytes()),
            'database': {'product_id': 1, 'publication_id': 41, 'publication_run': 233,
                         'public_run': 239, 'public_revision': 5, 'paired_cell': 387,
                         'public_cell': 420, 'annual_cell': 418,
                         'view_definition': old['public_definition'],
                         'view_sha256': m.sha(old['public_definition'].encode()),
                         'security_barrier': True,'contract_version':17,
                         'destination2026':{'ano':2026,'cell_id':251,'publicacao_id':41,'versao':22},
                         'destination2025':{'ano':2025,'cell_id':249,'publicacao_id':37,'versao':19}}}


def evidence():
    return {'publication': {'id':8101, 'run':8102, 'year':2026, 'cell':251,
                            'payload_sha256':'a'*64, 'paired_run':8104, 'paired_revision':3,'contract_version':18},
            'runs':[{'id':8103, 'cell':420, 'revision':6, 'frozen':True, 'status':'ok', 'truncated':False, 'row_count':1, 'payload_sha256':'b'*64},
                    {'id':8104, 'cell':387, 'revision':3, 'frozen':True, 'status':'ok', 'truncated':False, 'row_count':1},
                    {'id':8105, 'cell':418, 'revision':4, 'frozen':True, 'status':'ok', 'truncated':False, 'row_count':1}],
            'annual_latest_run':8105}


class ConsumerCutover(unittest.TestCase):
    def test_new_ids_are_mandatory_and_reject_placeholders_or_old_pins(self):
        m=module()
        for bad in [{}, {**ids(),'publication_id':None}, {**ids(),'public_run':'TODO'},
                    {**ids(),'public_run':239}, {**ids(),'paired_run':True}]:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                m.validate_inputs(baseline(m),bad,evidence(),BUSINESS,RR)

    def test_production_drift_or_local_drift_blocks_before_writing(self):
        m=module(); b=baseline(m); key=next(iter(b['files']))
        b['files'][key]['production_sha256']='f'*64
        with self.assertRaises(ValueError): m.validate_inputs(b,ids(),evidence(),BUSINESS,RR)
        b=baseline(m); b['files'][key]['local_sha256']='f'*64
        with self.assertRaises(ValueError): m.validate_inputs(b,ids(),evidence(),BUSINESS,RR)
        b=baseline(m); b['database']['view_sha256']='f'*64
        with self.assertRaises(ValueError): m.validate_inputs(b,ids(),evidence(),BUSINESS,RR)

    def test_unfrozen_or_unlinked_evidence_and_annual_mismatch_are_rejected(self):
        m=module()
        for kind in ['unfrozen','link','annual']:
            e=evidence()
            if kind=='unfrozen':e['runs'][0]['frozen']=False
            if kind=='link':e['publication']['paired_run']=9999
            if kind=='annual':e['annual_latest_run']=9999
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                m.validate_inputs(baseline(m),ids(),e,BUSINESS,RR)

    def test_candidates_preserve_auth_metrics_and_canonical_projection(self):
        m=module(); b=baseline(m)
        with tempfile.TemporaryDirectory(prefix='study-consumer-cutover-') as temp:
            out=Path(temp)/'candidate'
            report=m.build(b,ids(),evidence(),out,BUSINESS,RR)
            self.assertEqual(len(report['runtime_files']),8)
            src=(BUSINESS/'estudos/includes/StudyAccess.cfc').read_text()
            new=(out/'candidate/business/estudos/includes/StudyAccess.cfc').read_text()
            self.assertEqual(m.repoint_cfc(new,8101,8103,6,41,239,5),src)
            self.assertIn('publicacao_id=8101',new)
            self.assertIn('WHERE id=8103 AND cell_id=420 AND cell_version=6',new)
            press=(out/'candidate/portal/brasilquecorreprovas/imprensa/principal/dados.cfm').read_text()
            self.assertIn('publicacao_id=8101',press)
            self.assertIn('VARIABLES.pressYear',press)
            self.assertIn('FROM estudo.web_payloads WHERE ano=:ano',press)
            old_press=(RR/'brasilquecorreprovas/imprensa/principal/dados.cfm').read_text()
            self.assertEqual(press.split('<cfelse>',1)[1],old_press.split('<cfelse>',1)[1])
            old_index=(RR/'brasilquecorreprovas/imprensa/principal/index.cfm').read_text()
            new_index=(out/'candidate/portal/brasilquecorreprovas/imprensa/principal/index.cfm').read_text()
            branch="<cfif VARIABLES.pressYear EQ '2025'>"
            self.assertEqual(old_index.split(branch,1)[1].split('<cfelse>',1)[0],new_index.split(branch,1)[1].split('<cfelse>',1)[0])
            js=(out/'candidate/business/estudos/leitor/parcial.js').read_text()
            self.assertIn('meta.narrativa?.execucao!==8103',js)
            self.assertIn('consumer-8101-8103', (out/'candidate/business/estudo/anual/index.cfm').read_text())
            sql=(out/'database-cutover-DBA.sql').read_text()
            self.assertIn('BEGIN;',sql);self.assertIn('publicacao_id=8101',sql)
            self.assertIn('Comparative rates or public release contract changed',sql)
            self.assertIn('jsonb_array_length',sql)
            self.assertIn("(i->'comparativo') - ARRAY",sql)
            self.assertIn("(n.release->'historias'->'mulheres') - ARRAY",sql)
            self.assertIn('UPDATE estudo.web_destinos SET publicacao_id=8101,versao=versao+1 WHERE ano=2026 AND cell_id=251 AND publicacao_id=41 AND versao=22',sql)
            self.assertIn('2025 destination changed',sql)
            self.assertIn("p.payload->'meta'->>'contrato_versao'='18'",sql)
            self.assertNotRegex(sql,r'UPDATE estudo.web_destinos[^;]*ano=2025')
            self.assertNotRegex(sql,r'(?i)\b(GRANT|REVOKE|ALTER ROLE|UPDATE estudo.notebook_runs)\b')
            self.assertTrue((out/'runtime.patch').is_file())
            self.assertEqual(report['ids'],ids())
            self.assertTrue(report['teams_hold']['checkout'])
            self.assertTrue(report['teams_hold']['candidate'])
            subprocess.run(['node',str(RR/'_codex/scripts/check_rr_teams_release_hold.mjs'),
                            '--root',str(out/'candidate/portal')],capture_output=True,check=True)


if __name__=='__main__':unittest.main()
