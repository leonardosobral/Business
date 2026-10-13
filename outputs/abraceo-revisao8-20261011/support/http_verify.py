from pathlib import Path
import json,hashlib,base64,subprocess,concurrent.futures
P=Path(__file__).parent;payload=json.loads((P/'payload.json').read_text())
def logo(item):
 n,b=item;r=subprocess.run(['curl','-fLsS','--max-time','30','https://business.roadrunners.run/'+n],capture_output=True,timeout=35);assert r.returncode==0 and hashlib.sha256(r.stdout).digest()==hashlib.sha256(base64.b64decode(b)).digest(),n;return dict(path=n,hash_matches=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:logos=list(pool.map(logo,payload['files'].items()))
r=subprocess.run(['curl','-fsS','--max-time','30','https://business.roadrunners.run/estudos/primeiro-acesso/'],capture_output=True,text=True,timeout=35);assert r.returncode==0 and 'Entre com o Google' in r.stdout
r=subprocess.run(['curl','-sS','--max-time','30','-w','\n%{http_code}','--data','operation=lookup&mode=CNPJ&value=28674754000146','https://business.roadrunners.run/estudos/primeiro-acesso/api.cfm'],capture_output=True,text=True,timeout=35);assert r.returncode==0 and r.stdout.rsplit('\n',1)[1]=='401'
result=dict(logos=logos,first_access_page='200 / login required',anonymous_lookup='401');(P/'http-verified.json').write_text(json.dumps(result,indent=2));print({'logos':len(logos),'hashes_match':True,'page':200,'anonymous_lookup':401})
