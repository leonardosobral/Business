from pathlib import Path
import base64,concurrent.futures,hashlib,json,urllib.request
p=Path(__file__).parent;payload=json.loads((p/'payload.json').read_text()); files={n:v for n,v in payload['files'].items() if n.startswith('assets/')}
def check(item):
 n,b=item;req=urllib.request.Request('https://business.roadrunners.run/'+n,headers={'User-Agent':'RunnerHub-ABRACEO-verification/1.0'})
 with urllib.request.urlopen(req,timeout=30) as r:content=r.read();status=r.status;ctype=r.headers.get('Content-Type','')
 assert status==200 and ctype.startswith('image/') and hashlib.sha256(content).digest()==hashlib.sha256(base64.b64decode(b)).digest(),n
 return {'arquivo':n,'http':status,'sha256':hashlib.sha256(content).hexdigest()}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:result=list(pool.map(check,files.items()))
(p/'logos-http-verificados.json').write_text(json.dumps(result,indent=2));print({'logos_publicos_http_200_e_hash_correto':len(result)})
