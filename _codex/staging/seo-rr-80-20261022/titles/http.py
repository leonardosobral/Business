from pathlib import Path
import ast,html,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('before','after')
tree=ast.parse((S.parent/'amazonia_http.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
remote=remote.replace("prefix,year,method,edge=job;path=prefix+str(year)+'-corrida-das-cores-da-amazonia/'","path,method,edge=job")
remote=remote.split("mode=json.load(sys.stdin)")[0]+"jobs=[(p,'GET',False) for p in json.load(sys.stdin)]\nwith ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(fetch,jobs))\nprint(json.dumps(r,ensure_ascii=False))"
cases=json.loads((S/'tests-green.json').read_text())['rows']
newtags=['2026-trackfield-run-series-2025-sao-jose-do-rio-preto','2026-trackfield-run-series-2025-shopping-vitoria-ii','2026-corrida-e-caminhada-outubro-rosa-aspec','2026-corrida-e-caminhada-outubro-rosa-ba']
tags=newtags+['2026-corrida-da-virada-2026-sp','2026-together-run-pe']
paths=[prefix+tag+'/' for prefix in ['/evento/','/en/event/','/es/evento/'] for tag in tags]
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=180)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/('http-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
assert all(v['status']==200 for v in r),[(v['path'],v['status']) for v in r if v['status']!=200]
if mode=='after':
 before=json.loads((S/'http-before.json').read_text())
 for old,new in zip(before,r):
  assert old['path']==new['path']
  for field in ['meta','canonical','alternates','schema']:assert old['metadata'][field]==new['metadata'][field],(new['path'],field)
  tag=new['path'].rstrip('/').split('/')[-1];lang='en' if new['path'].startswith('/en/') else 'es' if new['path'].startswith('/es/') else 'pt-BR'
  row=next(x for x in cases if x['tag']==tag and x['lang']==lang)
  assert new['metadata']['title']==html.unescape(row['title']),(new['path'],'expected title')
 print(json.dumps({'pages_200':len(r),'metadata_preserved':len(r),'new_distinct_titles':len(newtags)*3}))
else:print(json.dumps({'baseline_pages_200':len(r)}))
