import ast,contextlib,hashlib,io,json,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/seo-languages-20261003'
class ReleaseGuards(unittest.TestCase):
 def test_dependencies_changed_after_compile_prevent_any_publication(self):
  for filename,prod,backup,count in [('release.py','/var/www/business.roadrunners.run','/var/backups/seo-languages-business-20261003',2),('rr_release.py','/var/www/roadrunners.com.br','/var/backups/seo-hreflang-roadrunners-20261003',1)]:
   with self.subTest(script=filename),tempfile.TemporaryDirectory(prefix='seo-release-guard-') as directory:
    root=Path(directory)/'root';root.mkdir();stage=Path(directory)/'backup'
    helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0]
    ns={'__file__':str(ROOT/'_codex/scripts/deploy_estudo.py')};exec(helpers,ns)
    (root/'data.cfm').write_text('original');(root/'head.cfm').write_text('original head')
    ns['prepare'](root,stage,{'data.cfm':'candidate'},{'data.cfm':ns['digest'](b'original')})
    (stage/'watch.json').write_text(json.dumps({'head.cfm':ns['digest'](b'original head')}))
    (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':ns['digest']((stage/'manifest.json').read_bytes()),'templates':count}))
    (root/'head.cfm').write_text('concurrent head')
    tree=ast.parse((STAGE/filename).read_text());remote=next(n.value.right.value for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
    remote=remote.replace(prod,str(root)).replace(backup,str(stage));ns['sys']=type('Input',(),{'stdin':io.StringIO('{"mode":"publish"}')})()
    with self.assertRaisesRegex(RuntimeError,'Production conflict|Dependency'):
     with contextlib.redirect_stdout(io.StringIO()):exec(remote,ns)
    self.assertEqual((root/'data.cfm').read_text(),'original')
 def test_queue_requires_positive_search_results_from_the_same_audit(self):
  cases=[None,{'runId':'wrong','auditAt':'2026-10-03T20:00:00Z','pages':[{'status':'pass'}]*3}, {'runId':'run-current','auditAt':'2026-10-03T20:00:00Z','pages':[{'status':'unknown'}]*3}]
  for audit in cases:
   with self.subTest(audit=audit),tempfile.TemporaryDirectory(prefix='seo-queue-audit-guard-') as directory:
    root=Path(directory);(root/'baseline/portal/includes').mkdir(parents=True)
    (root/'baseline/portal/includes/seo_queue_data.cfm').write_bytes((STAGE/'baseline/portal/includes/seo_queue_data.cfm').read_bytes())
    snapshot=json.loads((STAGE/'snapshot.json').read_text());rr=next(s for s in snapshot['sites'] if s['id']=='roadrunners');rr['runId']='run-current';rr['auditAt']='2026-10-03T20:00:00Z'
    (root/'snapshot.json').write_text(json.dumps(snapshot));(root/'search-public-verification.json').write_text(json.dumps({'ok':True,'pages':[{}]*3,'checked_at_utc':'2026-10-03T19:30:00Z'}))
    if audit:(root/'search-audit-verification.json').write_text(json.dumps(audit))
    with self.assertRaisesRegex(RuntimeError,'Search audit'):
     with contextlib.redirect_stdout(io.StringIO()):exec((STAGE/'build_queue.py').read_text(),{'__file__':str(root/'build_queue.py')})
    self.assertFalse((root/'candidate/portal/includes/seo_queue_data.cfm').exists())
if __name__=='__main__':unittest.main()
