from pathlib import Path
import base64,json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=ROOT/'_codex/staging/seo-structure-20261003'
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
from html.parser import HTMLParser
from urllib.request import Request,urlopen
class Headings(HTMLParser):
 def __init__(self):super().__init__();self.headings=[];self.current=None;self.script=None;self.schemas=[]
 def handle_starttag(self,tag,attrs):
  attrs=dict(attrs)
  if tag in ['h1','h2','h3']:self.current={'tag':tag,'text':'','class':attrs.get('class','')}
  if tag=='script' and attrs.get('type')=='application/ld+json':self.script=''
 def handle_data(self,data):
  if self.current is not None:self.current['text']+=data
  if self.script is not None:self.script+=data
 def handle_endtag(self,tag):
  if tag in ['h1','h2','h3'] and self.current is not None:self.headings.append(self.current);self.current=None
  if tag=='script' and self.script is not None:
   try:self.schemas.append(json.loads(self.script))
   except ValueError:pass
   self.script=None
files={}
projects=[('RoadRunners','/var/www/roadrunners.com.br',['busca/index.cfm','includes/busca_home.cfm','includes/estrutura/home_hero_busca.cfm','includes/card_evento_individual.cfm','evento/index.cfm','includes/backend/backend_evento.cfm','includes/estrutura/head.cfm']),('OpenResults','/var/www/openresults.run',['index.cfm','evento/index.cfm','includes/seo_event_schema.cfm','includes/backend_evento.cfm','robots.txt']),('Business','/var/www/business.roadrunners.run',['portal/includes/seo_queue_data.cfm'])]
for project,root,names in projects:
 for name in names:
  f=Path(root)/name
  if f.is_file():files[project+'/'+name]=base64.b64encode(f.read_bytes()).decode()
queries={
 'supplier_types':"SELECT id_fornecedor_tipo,descricao_tipo FROM tb_fornecedores_tipos ORDER BY id_fornecedor_tipo",
 'organizer_coverage':"SELECT count(*) AS active_events,count(*) FILTER(WHERE EXISTS(SELECT 1 FROM tb_evento_corridas_fornecedores c WHERE c.id_evento=e.id_evento AND c.id_fornecedor_tipo=1)) AS with_organizer_relation,count(*) FILTER(WHERE EXISTS(SELECT 1 FROM tb_evento_corridas_fornecedores c JOIN tb_fornecedores f ON f.id_fornecedor=c.id_fornecedor WHERE c.id_evento=e.id_evento AND c.id_fornecedor_tipo=1 AND length(trim(f.nome_fornecedor))>0)) AS with_named_organizer FROM tb_evento_corridas e WHERE e.ativo=true",
 'mismatched_roles':"SELECT e.id_evento,e.tag,e.nome_evento,c.id_fornecedor,c.id_fornecedor_tipo AS event_role,f.tag_tipo AS supplier_type,f.nome_fornecedor FROM tb_evento_corridas e JOIN tb_evento_corridas_fornecedores c ON c.id_evento=e.id_evento JOIN tb_fornecedores f ON f.id_fornecedor=c.id_fornecedor WHERE e.ativo=true AND c.id_fornecedor_tipo=1 AND f.tag_tipo<>'org' ORDER BY e.data_final DESC LIMIT 8",
 'timer_only_events':"SELECT e.id_evento,e.tag,e.nome_evento FROM tb_evento_corridas e WHERE e.ativo=true AND EXISTS(SELECT 1 FROM tb_evento_corridas_fornecedores c JOIN tb_fornecedores f ON f.id_fornecedor=c.id_fornecedor WHERE c.id_evento=e.id_evento AND c.id_fornecedor_tipo<>1) AND NOT EXISTS(SELECT 1 FROM tb_evento_corridas_fornecedores c WHERE c.id_evento=e.id_evento AND c.id_fornecedor_tipo=1) ORDER BY e.data_final DESC LIMIT 4",
 'organizer_events':"SELECT e.id_evento,e.tag,e.nome_evento,f.nome_fornecedor FROM tb_evento_corridas e JOIN tb_evento_corridas_fornecedores c ON c.id_evento=e.id_evento AND c.id_fornecedor_tipo=1 JOIN tb_fornecedores f ON f.id_fornecedor=c.id_fornecedor WHERE e.ativo=true ORDER BY e.data_final DESC LIMIT 4"
}
db={}
for name,sql in queries.items():
 try:db[name]=bridge(Path('/var/www/business.roadrunners.run'),raw_query(sql)+'report={rows=[]};for(row in q){arrayAppend(report.rows,row);}')
 except Exception as e:db[name]={'error':str(e)}
http=[]
urls=['https://roadrunners.run/busca/','https://roadrunners.run/en/search/','https://roadrunners.run/es/busqueda/','https://openresults.run/','https://roadrunners.run/noticias/gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio/','https://roadrunners.run/evento/2026-maratona-salvador-2026/']
for url in urls:
 with urlopen(Request(url,headers={'User-Agent':'RunnerHub-SEO-structure/20261003'}),timeout=20) as response:
  body=response.read(2*1024*1024).decode('utf8',errors='replace');parser=Headings();parser.feed(body)
  http.append({'url':url,'status':response.status,'headings':parser.headings,'schemas':parser.schemas})
print(json.dumps({'files':files,'db':db,'http':http},ensure_ascii=False))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=220)
if p.returncode:raise RuntimeError(p.stderr[-1800:])
r=json.loads(p.stdout)
for name,value in r.pop('files').items():
 path=STAGE/'baseline'/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(base64.b64decode(value))
(STAGE/'diagnostic.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
for row in r['http']:row['headings']=[h for h in row['headings'] if h['tag']=='h1'];row.pop('schemas',None)
print(json.dumps(r,ensure_ascii=False))
