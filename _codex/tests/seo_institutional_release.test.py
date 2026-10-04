import ast,contextlib,io,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/seo-institutional-20261003'
class ReleaseGuards(unittest.TestCase):
 def setup_queue(self,root):
  (root/'baseline/Business/portal/includes').mkdir(parents=True)
  (root/'baseline/Business/portal/includes/seo_queue_data.cfm').write_bytes((STAGE/'baseline/Business/portal/includes/seo_queue_data.cfm').read_bytes())
  (root/'snapshot.json').write_bytes((STAGE/'snapshot.json').read_bytes())
 def execute_queue(self,root,preview=False):
  import sys
  before=sys.argv;sys.argv=['build_queue.py']+(['--preview'] if preview else [])
  try:
   with contextlib.redirect_stdout(io.StringIO()):exec((STAGE/'build_queue.py').read_text(),{'__file__':str(root/'build_queue.py')})
  finally:sys.argv=before
 def test_preview_preserves_every_existing_resolution(self):
  import re
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);self.setup_queue(root);self.execute_queue(root,True)
   states=lambda p:dict((id,value) for value,id in re.findall(r'resolved = (true|false),\s+id = "([^"]+)"',p.read_text()))
   actual=states(root/'candidate/portal/includes/seo_queue_data.cfm');old=states(root/'baseline/Business/portal/includes/seo_queue_data.cfm')
   self.assertEqual({id:actual[id] for id in old},old);self.assertEqual(actual['RR-10'],'false')
 def test_missing_or_unmatched_audit_cannot_resolve_institutional(self):
  for kind in ['missing','wrong_run','unknown','wrong_url','duplicate','stale']:
   with self.subTest(kind=kind),tempfile.TemporaryDirectory() as directory:
    root=Path(directory);self.setup_queue(root);snapshot=json.loads((root/'snapshot.json').read_text());rr=snapshot['sites'][0]
    urls=['https://roadrunners.run'+p for p in ['/sobre/','/en/about/','/es/sobre/','/ajuda/','/en/help/','/es/ayuda/','/privacidade/','/en/privacy/','/es/privacidad/']]
    public={'ok':True,'checked_at_utc':'2026-01-01T00:00:00Z','pages':[{'url':u,'kind':'institutional','ok':True} for u in urls]}
    audit={'runId':rr['runId'],'auditAt':rr['auditAt'],'institutional':[{'url':u,'status':'pass'} for u in urls]}
    if kind=='wrong_run':audit['runId']='wrong'
    if kind=='unknown':audit['institutional'][0]['status']='unknown'
    if kind=='wrong_url':audit['institutional'][0]['url']='https://roadrunners.run/other/'
    if kind=='duplicate':audit['institutional'][0]=audit['institutional'][1]
    if kind=='stale':public['checked_at_utc']='2099-01-01T00:00:00Z'
    (root/'public-verification.json').write_text(json.dumps(public))
    if kind!='missing':(root/'audit-verification.json').write_text(json.dumps(audit))
    with self.assertRaisesRegex(RuntimeError,'Institutional|Require an audit'):self.execute_queue(root)
    self.assertFalse((root/'candidate/portal/includes/seo_queue_data.cfm').exists())
 def test_matching_evidence_resolves_only_institutional(self):
  import re
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);self.setup_queue(root);rr=json.loads((root/'snapshot.json').read_text())['sites'][0]
   urls=['https://roadrunners.run'+p for p in ['/sobre/','/en/about/','/es/sobre/','/ajuda/','/en/help/','/es/ayuda/','/privacidade/','/en/privacy/','/es/privacidad/']]
   public={'ok':True,'checked_at_utc':'2026-01-01T00:00:00Z','pages':[{'url':u,'kind':'institutional','ok':True} for u in urls]+[{'kind':'external_news','ok':True} for _ in range(6)]}
   audit={'runId':rr['runId'],'auditAt':rr['auditAt'],'institutional':[{'url':u,'status':'pass'} for u in urls],'marathons':{'url':'https://roadrunners.run/maratonas/','status':'pass','h1_count':1}}
   (root/'public-verification.json').write_text(json.dumps(public));(root/'audit-verification.json').write_text(json.dumps(audit));(root/'editorial-policy-verification.json').write_text(json.dumps({'records':[{},{}]}))
   (root/'marathons').mkdir();(root/'marathons/public-verification.json').write_text(json.dumps({'url':'https://roadrunners.run/maratonas/','ok':True,'h1_count':1,'checked_at_utc':'2026-01-01T00:00:00Z'}))
   self.execute_queue(root)
   states=dict((id,value) for value,id in re.findall(r'resolved = (true|false),\s+id = "([^"]+)"',(root/'candidate/portal/includes/seo_queue_data.cfm').read_text()))
   self.assertEqual(len(states),15);self.assertEqual(list(states.values()).count('true'),12);self.assertEqual(states['RR-10'],'true')
   self.assertEqual(states['RR-09'],'true');self.assertEqual(states['RR-08'],'false');self.assertEqual(states['RR-07'],'true')
 def test_changed_dependencies_prevent_any_publication(self):
  for filename,prod,backup,count in [('release.py','/var/www/business.roadrunners.run','/var/backups/seo-institutional-business-20261003',2),('rr_release.py','/var/www/roadrunners.com.br','/var/backups/seo-institutional-roadrunners-20261003',5),('marathons/rr_release.py','/var/www/roadrunners.com.br','/var/backups/seo-marathons-roadrunners-20261003',1)]:
   with self.subTest(script=filename),tempfile.TemporaryDirectory() as directory:
    root=Path(directory)/'root';root.mkdir();stage=Path(directory)/'backup'
    helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0];ns={'__file__':str(ROOT/'_codex/scripts/deploy_estudo.py')};exec(helpers,ns)
    (root/'data.cfm').write_text('original');(root/'dependency.cfm').write_text('original dependency')
    ns['prepare'](root,stage,{'data.cfm':'candidate'},{'data.cfm':ns['digest'](b'original')})
    (stage/'watch.json').write_text(json.dumps({'dependency.cfm':ns['digest'](b'original dependency')}));(stage/'compiled.json').write_text(json.dumps({'manifest_sha256':ns['digest']((stage/'manifest.json').read_bytes()),'templates':count}))
    (root/'dependency.cfm').write_text('concurrent edit')
    tree=ast.parse((STAGE/filename).read_text());remote=next(n.value.right.value for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
    remote=remote.replace(prod,str(root)).replace(backup,str(stage));ns['sys']=type('Input',(),{'stdin':io.StringIO('{"mode":"publish"}')})()
    with self.assertRaisesRegex(RuntimeError,'Production conflict'):
     with contextlib.redirect_stdout(io.StringIO()):exec(remote,ns)
    self.assertEqual((root/'data.cfm').read_text(),'original')
if __name__=='__main__':unittest.main()
