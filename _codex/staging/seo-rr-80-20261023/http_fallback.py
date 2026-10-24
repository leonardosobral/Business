from pathlib import Path
import ast,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('before','after')
tree=ast.parse((S.parent/'seo-rr-80-20261022/amazonia_http.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in n.targets))
remote=remote.replace("prefix,year,method,edge=job;path=prefix+str(year)+'-corrida-das-cores-da-amazonia/'","path,method,edge=job")
remote=remote.replace("self.in_json=False;self.buf='';self.schema=[]","self.in_json=False;self.buf='';self.schema=[];self.store=0")
remote=remote.replace("a=dict(attrs)","a=dict(attrs)\n  if t=='a' and a.get('href','').startswith('https://store.roadrunners.run'):self.store+=1")
remote=remote.replace("r['metadata']=dict(title=p.title","r['store_links']=p.store;r['metadata']=dict(title=p.title")
remote=remote.split("mode=json.load(sys.stdin)")[0]+"jobs=[(p,'GET',False) for p in json.load(sys.stdin)]\nwith ThreadPoolExecutor(max_workers=2) as pool:r=list(pool.map(fetch,jobs))\nprint(json.dumps(r,ensure_ascii=False))"
paths=['/','/en/','/es/','/estado/ba/','/evento/2026-101-corrida-internacional-de-sao-silvestre/']
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=100);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/('fallback-http-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));assert all(x['status']==200 for x in r),[(x['path'],x['status']) for x in r]
if mode=='after':
 before=json.loads((S/'fallback-http-before.json').read_text())
 for old,new in zip(before,r):
  assert old['path']==new['path'] and old['store_links']>0 and new['store_links']==0,new['path']
  for key in ['title','meta','canonical','alternates']:assert old['metadata'][key]==new['metadata'][key],(new['path'],key)
print(json.dumps(dict(mode=mode,pages_200=len(r),store_links=sum(x['store_links'] for x in r))))
