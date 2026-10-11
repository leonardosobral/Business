from pathlib import Path
import base64,hashlib,json,re,shlex,subprocess,sys
root=Path.cwd();stage=Path(__file__).resolve().parent;mode=sys.argv[1]
names=list(json.loads((stage/'before.json').read_text()))
cases=[(None,'avatar/athlete/large.png',None,'/assets/user.png?'),(None,'avatar/athlete/large.png','https://images.example.test/valid.jpg','https://images.example.test/valid.jpg'),('',None,None,'/assets/user.png?'),(' ',None,None,'/assets/user.png?'),('photo.jpg',None,None,'https://roadrunners.run/assets/paginas/photo.jpg'),(None,' https://images.example.test/a.jpg ',None,'https://images.example.test/a.jpg'),(None,'/assets/paginas/valid.jpg',None,'/assets/paginas/valid.jpg'),(None,'',None,'/assets/user.png?'),(None,None,'avatar/athlete/large.png','/assets/user.png?'),(None,None,'/assets/user.png','/assets/user.png'),(None,'http://images.example.test/a.jpg',None,'http://images.example.test/a.jpg'),(None,None,None,'/assets/user.png?'),(None,'invalid', ' https://images.example.test/b.jpg ','https://images.example.test/b.jpg')]
def lit(v):return 'NULL::text' if v is None else "'"+v.replace("'","''")+"'::text"
values=','.join('('+','.join([str(i)]+[lit(v) for v in c])+')' for i,c in enumerate(cases))
queries=[]
for name in names:
 s=(stage/mode/name).read_text();m=re.search(r"COALESCE\(\s*'https://roadrunners.run/assets/paginas/'[\s\S]*?\) as imagem_usuario",s);assert m,name
 expr=m.group(0).rsplit(' as ',1)[0].replace('pag.path_imagem','path_imagem').replace('usr.strava_profile','strava_profile').replace('usr.imagem_usuario','user_image')
 queries.append("WITH cases(id,path_imagem,strava_profile,user_image,expected) AS (VALUES "+values+") SELECT id, ("+expr+") IS NOT DISTINCT FROM expected AS passed FROM cases ORDER BY id")
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''\np=json.load(sys.stdin);body='report={cases=[]};'
for i,sql in enumerate(p['queries']):
 body+=raw_query(sql,'q'+str(i))+'for(row in q'+str(i)+'){arrayAppend(report.cases,{id=row.id,passed=row.passed});}'
print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'queries':queries}),text=True,capture_output=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);r=r.get('cases',r.get('CASES'));failed=[x for x in r if not x.get('passed',x.get('PASSED'))];print(json.dumps({'mode':mode,'scenarios':len(r),'failed':len(failed)}));assert not failed,failed
if mode=='candidate':(stage/'candidate-render-passed.json').write_text(json.dumps({'scenarios':len(r),'hashes':{n:hashlib.sha256((stage/'candidate'/n).read_bytes()).hexdigest() for n in names},'watch':json.loads((stage/'watch.json').read_text())},indent=2))
