from pathlib import Path
import urllib.request,urllib.error,json
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*a,**k):return None
opener=urllib.request.build_opener(NoRedirect);out=[]
for route in ['/portal/seo/?aba=ga4&site=roadrunners','/portal/includes/seo_search_evidence.cfm','/portal/conteudo/seo_growth_baseline.cfm']:
 req=urllib.request.Request('https://business.roadrunners.run'+route,headers={'User-Agent':'RunnerHub-SEO-Verification/1.0'})
 try:r=opener.open(req,timeout=30)
 except urllib.error.HTTPError as e:r=e
 body=r.read().decode('utf-8','replace');assert '10.026 cliques' not in body and '21.335 páginas' not in body,route
 assert r.status in [301,302,303,307,308,403],(route,r.status)
 out.append({'route':route,'status':r.status,'noMetricsLeaked':True})
Path(__file__).with_name('public-access.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
