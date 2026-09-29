"""Read-only public HTTP smoke checks; never triggers an intentional internal error."""
import json,urllib.request,urllib.error,uuid
from pathlib import Path
base='https://roadrunners.run'
checks=[('/',200,None),('/404/',404,'Esse caminho não foi encontrado'),('/en/404/',404,'This path'),('/es/404/',404,'camino'),('/errors/500.html',200,'Uma pausa no percurso'),('/codex-missing-'+uuid.uuid4().hex+'.txt',404,'Esse caminho não foi encontrado')]
results=[]
for path,want,phrase in checks:
 req=urllib.request.Request(base+path,headers={'User-Agent':'RunnerHub-Deployment-Verification/1.0'})
 try:r=urllib.request.urlopen(req,timeout=30)
 except urllib.error.HTTPError as e:r=e
 body=r.read().decode('utf-8',errors='replace')
 result={'path':path,'status':r.status,'expected':want,'content_ok':phrase is None or phrase.lower() in body.lower(),'final_url':r.url}
 results.append(result)
print(json.dumps(results,ensure_ascii=False))
Path('_codex/staging/error-handler/release-http.json').write_text(json.dumps(results,indent=2,ensure_ascii=False))
assert all(x['status']==x['expected'] and x['content_ok'] for x in results),'HTTP verification failed'
