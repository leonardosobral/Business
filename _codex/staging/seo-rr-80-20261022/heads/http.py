from pathlib import Path
import ast,json,shlex,subprocess,sys
from urllib.parse import quote
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('before','after')
tree=ast.parse((S.parent/'amazonia_http.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
remote=remote.replace("prefix,year,method,edge=job;path=prefix+str(year)+'-corrida-das-cores-da-amazonia/'","host,path,method,edge=job")
remote=remote.replace("'roadrunners.run:443:127.0.0.1'","host+':443:127.0.0.1'").replace("'https://roadrunners.run'+path","'https://'+host+path").replace('dict(path=path,method=method','dict(host=host,path=path,method=method')
remote=remote.split("mode=json.load(sys.stdin)")[0]+"jobs=[(h,p,'GET',False) for h,p in json.load(sys.stdin)]\nwith ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(fetch,jobs))\nprint(json.dumps(r,ensure_ascii=False))"
tag=quote('2026-"corrida-e-caminhada-franco-verao-26"',safe='')
paths=[('roadrunners.run',prefix+t+'/') for prefix in ['/evento/','/en/event/','/es/evento/'] for t in [tag,'2026-corrida-da-virada-2026-sp']]
paths += [('business.roadrunners.run','/cadastro/'),('business.roadrunners.run','/login/')]
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=120);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/('http-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));assert all(v['status']==(404 if v['host']=='business.roadrunners.run' and v['path']=='/login/' else 200) for v in r),[(v['path'],v['status']) for v in r]
if mode=='after':
 before=json.loads((S/'http-before.json').read_text())
 for old,new in zip(before,r):
  assert (old['host'],old['path'])==(new['host'],new['path'])
  assert old['status']==new['status']
  if new['status']==404:continue
  for field in ['title','canonical','alternates','schema']:assert old['metadata'][field]==new['metadata'][field],(new['path'],field)
  if new['host']=='roadrunners.run' and tag in new['path']:
   assert len(new['metadata']['meta']['description'])>50 and '"Corrida e Caminhada Franco Verão 26"' in new['metadata']['meta']['description'],new['metadata']['meta']
  elif new['path']=='/cadastro/':assert len(new['metadata']['meta']['description'])>50
  else:assert old['metadata']['meta']==new['metadata']['meta']
 print(json.dumps(dict(pages_200=sum(x['status']==200 for x in r),control_404_preserved=True,fixed_description_pages=4,other_metadata_preserved=True)))
else:print(json.dumps(dict(pages_200=sum(x['status']==200 for x in r),control_404=True,quoted_descriptions=[x['metadata']['meta'].get('description') for x in r if tag in x['path']])))
