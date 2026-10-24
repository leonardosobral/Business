from pathlib import Path
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('before','after')
slugs=['a-muralha-marathon-abre-inscricoes-hoje-para-edicao-2027','alison-dos-santos-concorre-ao-premio-de-atleta-mundial-do-ano-da-world-athletics','circuito-caixa-chega-a-sao-paulo-em-15-de-novembro','ibcc-promove-64-corrida-contra-o-cancer-de-mama-no-ibirapuera','maratona-de-berlim-quando-o-plano-muda-no-meio-da-prova','maratona-de-nova-york-revela-medalha-da-edicao-de-2026','maratona-de-toquio-amplia-voluntariado-internacional-para-edicao-de-2027','ticket-sports-lanca-pesquisa-sobre-trail-running-no-brasil']
paths=['/noticias/'+s+'/' for s in slugs]+['/org/corre-brasil/','/timer/corre-brasil/','/noticias/']
remote='''
from html.parser import HTMLParser
import hashlib,json,subprocess,sys
class P(HTMLParser):
 def __init__(self):super().__init__();self.intitle=False;self.title='';self.description='';self.canonical=[];self.robots='';self.injson=False;self.currentjson='';self.schemas=[]
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='title':self.intitle=True
  if t=='meta' and d.get('name')=='description':self.description=d.get('content','')
  if t=='meta' and d.get('name')=='robots':self.robots=d.get('content','')
  if t=='link' and d.get('rel')=='canonical':self.canonical.append(d.get('href',''))
  if t=='script' and d.get('type')=='application/ld+json':self.injson=True;self.currentjson=''
 def handle_endtag(self,t):
  if t=='title':self.intitle=False
  if t=='script' and self.injson:self.schemas.append(json.loads(self.currentjson));self.injson=False
 def handle_data(self,d):
  if self.intitle:self.title+=d
  if self.injson:self.currentjson+=d
def core(x):
 if isinstance(x,list):return [core(v) for v in x]
 if isinstance(x,dict):return {k:core(v) for k,v in x.items() if k!='description'}
 return x
rows=[]
for path in json.load(sys.stdin):
 cp=subprocess.run(['curl','-sS','--max-time','35','--resolve','roadrunners.run:443:127.0.0.1','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=40);assert cp.returncode==0,cp.stderr
 body,status=cp.stdout.rsplit('\\n',1);assert status=='200',(path,status)
 p=P();p.feed(body);rows.append({'path':path,'status':200,'title':p.title,'description':p.description,'canonical':p.canonical,'robots':p.robots,'schema_core_hash':hashlib.sha256(json.dumps(core(p.schemas),ensure_ascii=False,sort_keys=True).encode()).hexdigest()})
print(json.dumps(rows))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=260);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/f'public-{mode}.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
if mode=='after':
 old=json.loads((S/'public-before.json').read_text());changed=0
 for a,b in zip(old,r):
  for key in ['path','status','canonical','robots','schema_core_hash']:assert a[key]==b[key],(a['path'],key)
  if a['path'].startswith('/noticias/'):
   assert a['title']==b['title'];assert b['description'] and b['description']!='Notícia publicada no ecossistema Road Runners.'
   changed+=a['description']!=b['description']
 assert r[8]['title']!=r[9]['title']
 print(json.dumps({'pages_200':len(r),'changed_news_descriptions':changed,'supplier_titles_distinct':True,'canonical_robots_and_schema_core_preserved':True}))
else:print(json.dumps({'baseline_pages_200':len(r),'generic_news_descriptions':sum(x['description']=='Notícia publicada no ecossistema Road Runners.' for x in r)}))
