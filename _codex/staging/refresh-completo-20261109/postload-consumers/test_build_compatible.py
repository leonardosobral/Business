"""Two-pair transition tests, using synthetic new IDs and no remote operations."""
import importlib.util
import json
from pathlib import Path
import re
import tempfile
import unittest

HERE=Path(__file__).resolve().parent


def load(name,path):
    if not path.exists():raise AssertionError('Two-pair compatible builder is not implemented yet')
    spec=importlib.util.spec_from_file_location(name,path)
    mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod


class CompatibleConsumers(unittest.TestCase):
    def helper(self):return load('compatible',HERE/'build_compatible.py')
    def fixture(self):
        return load('cutover_fixture',HERE.parent/'consumer-cutover/test_consumer_cutover.py')

    def test_only_two_corresponding_publication_narrative_pairs_exist(self):
        m=self.helper();f=self.fixture();base=f.baseline(m.cutover)
        original=(f.BUSINESS/'estudos/includes/StudyAccess.cfc').read_text()
        result=m.compatible_cfc(original,base['database'],f.ids())
        self.assertIn('(41::bigint,239::bigint,5::integer)',result)
        self.assertIn('(8101::bigint,8103::bigint,6::integer)',result)
        self.assertIn('ON n.publication_id=p.publicacao_id',result)
        self.assertNotIn('FROM paired_source p CROSS JOIN paired_public n',result)
        self.assertEqual(len(re.findall(r'\(\d+::bigint,\d+::bigint,\d+::integer\)',result)),2)
        self.assertIn("'execucao',narrative_run,'revisao',narrative_revision",result)
        restored=result
        for old,new in reversed(m.cfc_replacements(base['database'],f.ids())):
            self.assertEqual(restored.count(new),1)
            restored=restored.replace(new,old,1)
        self.assertEqual(restored,original,'Metrics, auth and fallback must be byte-identical outside the explicit pin join')

    def test_js_accepts_exactly_the_two_numeric_ids_and_keeps_other_validation(self):
        m=self.helper();f=self.fixture();old=(f.BUSINESS/'estudos/leitor/parcial.js').read_text()
        new=m.compatible_js(old,239,8103)
        self.assertIn('![239,8103].includes(meta.narrativa?.execucao)',new)
        self.assertEqual(new.replace('![239,8103].includes(meta.narrativa?.execucao)','meta.narrativa?.execucao!==239'),old)

    def test_invalid_ids_or_baseline_drift_do_not_create_output(self):
        m=self.helper();f=self.fixture();b=f.baseline(m.cutover)
        with tempfile.TemporaryDirectory(prefix='two-pair-reject-') as tmp:
            target=Path(tmp)/'out'
            with self.assertRaises(ValueError):m.build(b,{**f.ids(),'public_run':None},f.evidence(),target,f.BUSINESS,f.RR)
            self.assertFalse(target.exists())
            b['files']['business/estudos/includes/StudyAccess.cfc']['production_sha256']='f'*64
            with self.assertRaises(ValueError):m.build(b,f.ids(),f.evidence(),target,f.BUSINESS,f.RR)
            self.assertFalse(target.exists())

    def test_two_packages_preserve_2025_and_final_baseline_matches_compatible(self):
        m=self.helper();f=self.fixture()
        with tempfile.TemporaryDirectory(prefix='two-pair-build-') as tmp:
            target=Path(tmp)/'out'
            report=m.build(f.baseline(m.cutover),f.ids(),f.evidence(),target,f.BUSINESS,f.RR)
            self.assertEqual(report['approved_pairs'],[{'publication_id':41,'public_run':239,'revision':5},
                                                      {'publication_id':8101,'public_run':8103,'revision':6}])
            compat=target/'compatible';final=target/'final-only'
            cm=json.loads((compat/'manifest.json').read_text());fm=json.loads((final/'manifest.json').read_text())
            self.assertEqual(len(cm['runtime_files']),8)
            for key,value in fm['runtime_files'].items():
                self.assertEqual(value['before_sha256'],cm['runtime_files'][key]['candidate_sha256'])
            press=(compat/'candidate/portal/brasilquecorreprovas/imprensa/principal/dados.cfm').read_text()
            self.assertIn('ON n.publication_id=p.publicacao_id',press)
            self.assertIn('(41::bigint,239::bigint,5::integer)',press)
            old=(f.RR/'brasilquecorreprovas/imprensa/principal/dados.cfm').read_text()
            self.assertEqual(press.split('<cfelse>',1)[1],old.split('<cfelse>',1)[1])
            new_only=(final/'candidate/business/estudos/includes/StudyAccess.cfc').read_text()
            self.assertNotIn('approved_pairs',new_only)
            self.assertIn('a.publicacao_id=8101',new_only)
            self.assertTrue(report['teams_hold']['compatible'])
            self.assertTrue((target/'compatible/runtime.patch').is_file())
            self.assertIn('expected compatible',fm['baseline_origin'])


if __name__=='__main__':unittest.main()
