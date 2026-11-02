from pathlib import Path
from html import unescape
import json,urllib.request,urllib.error,re,concurrent.futures
S=Path(__file__).resolve().parent;urls=json.loads((S.parent/'seo-reaudit-20261030/duplicate-description-urls.json').read_text())
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect)
def fetch(path):
 try:
  with opener.open(urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'}),timeout=35) as r:return r.status,r.read().decode(),dict(r.headers)
 except urllib.error.HTTPError as e:return e.code,e.read().decode(),dict(e.headers)
def check(url):
 path=url.removeprefix('https://roadrunners.run');status,h,headers=fetch(path);h=unescape(h)
 if status==301:return {'path':path,'status':status,'location':headers.get('Location',headers.get('location',''))}
 assert status==200,(path,status)
 desc=re.search(r'<meta name="description" content="([^"]+)"',h)[1];assert desc and 'href="'+url+'"' in h,(path,'metadata')
 if '/estado/' in path:
  page=int(re.search(r'pagina=(\d+)',path)[1]) if 'pagina=' in path else 1
  assert f'Página {page} de ' in desc,(path,desc)
 else:assert '2026-10-25' not in h if 'outubro-rosa' in path else True
 return {'path':path,'status':status,'description':desc}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:report=list(pool.map(check,urls))
regionals=[r for r in report if '/estado/' in r['path']];assert len(regionals)==30 and len(set(r['description'] for r in regionals))==30
pairs=[('2026-corrida-adc-zf-clube','2027-corrida-adc-zf-clube'),('2026-corrida-e-caminhada-outubro-rosa-ro','2026-corrida-e-caminhada-outubro-rosa-chupinguaia')]
for source,target in pairs:
 for prefix in ['/evento/','/en/event/','/es/evento/']:
  path=prefix+source+'/';status,h,headers=fetch(path);loc=headers.get('Location',headers.get('location',''));assert status==301 and loc.endswith(prefix+target+'/'),(path,status,loc);report.append({'path':path,'status':status,'location':loc})
 for prefix in ['/en/event/','/es/evento/']:
  path=prefix+target+'/';status,h,headers=fetch(path);assert status==200 and 'href="https://roadrunners.run'+path+'"' in unescape(h);report.append({'path':path,'status':status})
(S/'public-verified.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps({'reportedUrls':34,'regionalDescriptionsDistinct':30,'localizedRedirects':6,'translatedTargets':4,'checks':len(report),'passed':True}))
