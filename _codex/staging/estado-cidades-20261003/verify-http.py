from pathlib import Path
import concurrent.futures,json,re,urllib.request
stage=Path(__file__).resolve().parent
targets={
 'state':'https://roadrunners.run/estado/ba/',
 'city':'https://roadrunners.run/estado/ba/alagoinhas/?tempo=0%2C1&distancia=5%2C21&trail=false',
 'api':'https://roadrunners.run/api/eventos.cfm?tag=BA&cidade=alagoinhas&tempo=0%2C1&distancia=5%2C21&trail=false&cupom=true',
 'js':'https://roadrunners.run/assets/js/runnerhub-estado-cidades.js?version=2026-10-03-1',
 'css':'https://roadrunners.run/assets/css/runnerhub-estado-cidades.css?version=2026-10-03-1'
}
def read(item):
 key,url=item
 req=urllib.request.Request(url,headers={'User-Agent':'RunnerHub-Scoped-Verification/1.0'})
 with urllib.request.urlopen(req,timeout=40) as response:
  text=response.read().decode('utf-8');status=response.status
 assert status==200,(key,status)
 assert 'Error Occurred While Processing Request' not in text,key
 assert 'Failed to add HTML header' not in text,key
 (stage/('published-'+key+'.'+('js' if key=='js' else 'css' if key=='css' else 'html'))).write_text(text)
 result={'status':status,'bytes':len(text.encode())}
 if key in ['state','city']:
  assert 'data-estado-city-picker' in text,key
  assert 'data-estado-state-select' in text,key
  canonical=re.search(r'<link[^>]*rel="canonical"[^>]*href="([^"]+)"',text).group(1)
  want='https://roadrunners.run/estado/ba/'+('alagoinhas/' if key=='city' else '')
  assert canonical==want,(key,canonical,want)
  result['canonical']=canonical
 if key=='api':
  assert 'RunnerHubEstadoCities.update' in text
  result['city_facets_delivered']=True
 return key,result
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:r=dict(pool.map(read,targets.items()))
(stage/'http-verification.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r,ensure_ascii=False))
