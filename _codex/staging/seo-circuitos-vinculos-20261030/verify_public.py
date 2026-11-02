from pathlib import Path
from html import unescape
import urllib.request,urllib.error,json,re,concurrent.futures
S=Path(__file__).resolve().parent;d=json.loads((S/'decisions.json').read_text());inv={e['id_evento']:e for e in json.loads((S/'inventory.json').read_text())['events']}
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect)
def fetch(path):
 req=urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'})
 try:
  with opener.open(req,timeout=40) as r:return r.status,r.read().decode(),dict(r.headers)
 except urllib.error.HTTPError as e:return e.code,e.read().decode(),dict(e.headers)
report=[]
for circuit,expected in [('estacoes',24),('live-run-xp',12)]:
 path='/circuito/'+circuit+'/';status,body,headers=fetch(path);(S/('public-'+circuit+'.html')).write_text(body);assert status==200
 count=int(re.search(r'Próximos<span[^>]*>(\d+)',body)[1]);assert count==expected,(circuit,count,expected,'Application query cache may retain the prior result for five minutes')
 for x in d['addMemberships']:
  if x['agregador_tag']==circuit:assert '/evento/'+inv[x['id_evento']]['tag']+'/' in body,(circuit,x['id_evento'])
 if circuit=='live-run-xp':assert inv[45366]['tag'] not in body
 report.append({'path':path,'status':status,'upcoming':count})
def eventCheck(x):
 e=inv[x['id_evento']];path='/evento/'+e['tag']+'/';status,body,headers=fetch(path);body=unescape(body);assert status==200,(e['id_evento'],status);assert 'Error Occurred While' not in body
 assert '/circuito/'+x['agregador_tag']+'/' in body,(e['id_evento'],'Circuit link absent')
 assert 'href="https://roadrunners.run'+path+'"' in body,(e['id_evento'],'Canonical')
 if e['id_evento']==48557:
  assert '15km' in body or '15 km' in body
  assert 'https://www.appliveexperience.com.br/evento/live-run-ribeirao-preto-ii-2026' in body
 return {'id_evento':e['id_evento'],'path':path,'status':status,'circuit':x['agregador_tag']}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:report+=list(pool.map(eventCheck,d['addMemberships']))
for prefix in ['/evento/','/en/event/','/es/evento/']:
 path=prefix+inv[45366]['tag']+'/';status,body,headers=fetch(path);loc=headers.get('Location',headers.get('location',''));assert status==301 and loc.endswith(prefix+inv[37570]['tag']+'/'),(status,path,loc);report.append({'path':path,'status':status,'location':loc})
for prefix in ['/en/event/','/es/evento/']:
 path=prefix+inv[48557]['tag']+'/';status,body,headers=fetch(path);assert status==200 and ('15km' in body or '15 km' in body);report.append({'path':path,'status':status})
(S/'public-verified.json').write_text(json.dumps(report,indent=2));print(json.dumps({'circuits':2,'eventPages':22,'redirects':3,'translatedRibeiraoPages':2,'checks':len(report),'passed':True}))
