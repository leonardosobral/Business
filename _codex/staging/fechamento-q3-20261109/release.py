from pathlib import Path
import base64,importlib.util,json,subprocess,sys,hashlib

W=Path(__file__).resolve().parent
BUSINESS=W.parents[2]
RR=BUSINESS.parent/'RoadRunners'
spec=importlib.util.spec_from_file_location('scoped_q3',RR/'_codex/scripts/deploy_estudo_q3.py')
q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
STAGE='/var/backups/study-q3-editorial-close-20261109'
PORTAL_ALLOW={
 'brasilquecorreprovas/2026/pagina.html',
 'brasilquecorreprovas/imprensa/principal/index.cfm',
 'brasilquecorreprovas/imprensa/principal/dados.cfm',
 'brasilquecorreprovas/imprensa/principal/parcial-2026.js',
 'brasilquecorreprovas/imprensa/principal/estudo-2026.css',
}
BUSINESS_ALLOW={
 'estudos/includes/StudyAccess.cfc',
 'estudos/leitor/index.cfm','estudos/leitor/parcial.js','estudos/leitor/estudo.js','estudos/leitor/estudo.css',
 'estudos/lancamento/index.cfm','estudos/lancamento/arquivo.cfm',
 'estudos/lancamento/arquivos/brasil-que-corre-provas-guia-rapido-q3.pdf',
 'estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf',
}
def files():
 result={}
 for site,allowed in [('business',BUSINESS_ALLOW),('portal',PORTAL_ALLOW)]:
  base=W/'runtime'/site
  result[site]={str(p.relative_to(base)):base64.b64encode(p.read_bytes()).decode() for p in base.rglob('*') if p.is_file() and str(p.relative_to(base)) in allowed}
  assert result[site]
 return result
def gate():
 check=RR/'_codex/scripts/check_rr_teams_release_hold.mjs'
 for root in [RR,W/'runtime/portal']:
  subprocess.run(['node',str(check),'--root',str(root)],check=True)
def verification_templates():
 for n in ['atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/estrutura/header.cfm','includes/backend/backend_profile_settings.cfm','api/profile/teams.cfm','teams/includes/start.cfm']:
  p=W/'runtime/portal'/n;p.parent.mkdir(parents=True,exist_ok=True)
  source=(RR/n).read_text()
  if n in ('api/profile/teams.cfm','teams/includes/start.cfm'):
   source=source[:source.index('<cfabort/>')+10].strip()+'\n'
  p.write_text(source)
body=q.REMOTE_RELEASE.replace('/opt/ColdFusion/cfusion/bin/cfcompile.sh','/opt/coldfusion2025/cfusion/bin/cfcompile.sh').replace("'-cfruntimeuser','nobody'","'-cfruntimeuser','coldfusion'")
a=body.index("  with tempfile.TemporaryDirectory(prefix='study-q3-compile-'");b=body.index(" print(json.dumps({'prepared'",a)
body=body[:a]+"  if any(n.endswith(('.cfm','.cfc')) for n in files):\n"+'\n'.join(' '+line for line in body[a:b].splitlines())+'\n'+body[b:]
mode=sys.argv[1]
if mode=='baseline':
 r=q.remote(body,{'mode':'baseline','stage':STAGE,'files':files()})
 (W/'release-before.json').write_text(json.dumps(r,indent=2))
elif mode=='prepare':
 verification_templates();gate()
 data=files()
 # Assets and downloads land before the templates that reference them.
 for site in data:data[site]=dict(sorted(data[site].items(),key=lambda kv:kv[0].endswith(('index.cfm','arquivo.cfm','StudyAccess.cfc','pagina.html'))))
 before=json.loads((W/'release-before.json').read_text())
 assert all(set(data[site])==set(before[site]) for site in data)
 r=q.remote(body,{'mode':'prepare','stage':STAGE,'files':data,'before':before})
 q.remote("stage=Path(payload['stage']);(stage/'migration.json').write_text(json.dumps({'schema_change':False,'notebook_query_changes':False,'frozen_results_changed':False}));print(json.dumps({'ready':True}))",{'stage':STAGE})
elif mode=='publish':
 site=sys.argv[2];assert site in ('business','portal')
 if site=='portal':gate()
 r=q.remote(body,{'mode':'publish','stage':STAGE,'site':site})
elif mode=='verify':
 r=q.remote(body,{'mode':'verify','stage':STAGE})
elif mode=='sync':
 before=json.loads((W/'release-before.json').read_text());r={}
 for site,names in files().items():
  root=BUSINESS if site=='business' else RR
  for n,encoded in names.items():
   p=root/n;data=base64.b64decode(encoded);new=hashlib.sha256(data).hexdigest()
   old=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
   assert old in (before[site][n],new),'Local conflict: '+n
 for site,names in files().items():
  root=BUSINESS if site=='business' else RR
  for n,encoded in names.items():
   p=root/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(base64.b64decode(encoded))
  r[site]=len(names)
else:raise SystemExit('Unknown mode')
(W/(mode+('-'+sys.argv[2] if mode=='publish' else '')+'-receipt.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps(r,ensure_ascii=False))
