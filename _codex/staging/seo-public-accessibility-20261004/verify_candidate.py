from pathlib import Path
from html.parser import HTMLParser
import base64,hashlib,json,re,shlex,subprocess
S=Path(__file__).resolve().parent;R=Path.cwd()
class P(HTMLParser):
 def __init__(self):super().__init__();self.h1=0;self.in_h1=False;self.bad=[];self.images=[];self.names=[]
 def handle_starttag(self,t,a):
  if t=='h1':self.h1+=1;self.in_h1=True
  if t=='img':self.images.append(dict(a))
  if self.in_h1 and t in ['div','h2','h3','h6']:self.bad.append(t)
 def handle_endtag(self,t):
  if t=='h1':self.in_h1=False
 def handle_data(self,d):
  if self.in_h1:self.names.append(d)
for name in ['evento/index.cfm','login/index.cfm']:
 old=(S/'baseline'/name).read_text();new=(S/'candidate'/name).read_text()
 if name.startswith('evento'):
  assert new.replace(' alt="<cfoutput>#encodeForHTMLAttribute(qEvento.nome_evento)#</cfoutput>"','',1)==old
 else:assert new.replace('<h1 class="h6">Identifique-se para prosseguir</h1>','<h6>Identifique-se para prosseguir</h6>',1)==old
# Bound the extracted poster to its single line, not unrelated HTML.
poster=next(l.strip() for l in (S/'candidate/evento/index.cfm').read_text().splitlines() if '<img class="img-fluid rounded-3 w-100"' in l)
payload={'poster':poster}
helpers=(R/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')").replace('business.roadrunners.run','roadrunners.run').replace('result=json.loads(p.stdout)',"\n  try:result=json.loads(p.stdout)\n  except ValueError:raise RuntimeError('Private fixture response: '+p.stdout[:2500]+' stderr '+p.stderr[:300])")
helpers=helpers.replace("  (work/'run.cfm').write_text","  for v in ['baseline','candidate']:shutil.copyfile(Path('/var/backups/seo-public-accessibility-20261004-v2')/v/'includes/estrutura/header_tema.cfm',work/(v+'-header.cfm'))\n  (work/'poster-test.cfm').write_text(fixture_payload['poster'])\n  (work/'run.cfm').write_text")
remote=helpers+r'''
fixture_payload=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br')
body='''+"r'''"+'''
REQUEST.i18n={common={themeHeader={website="Site",instagram="Instagram"}}};
REQUEST.t=function(key,args={}) {return "Logo " & args.name;};
qFornecedor=queryNew("nome_fornecedor,tag_tipo,tag","varchar,varchar,varchar",[{nome_fornecedor="Organizador teste",tag_tipo="org",tag="teste"}]);
qAgrega=queryNew("nome_evento_agregado,tipo_agregacao,tag","varchar,varchar,varchar",[{nome_evento_agregado="Circuito teste",tipo_agregacao="circuito",tag="teste"}]);
report={cases=[]};
for(version in ["baseline","candidate"]){
 for(theme in [1,2,3]){
  qTema=queryNew("id_tema,logo,cor_fonte,cor_botoes,website,instagram","integer,varchar,varchar,varchar,varchar,varchar",[{id_tema=theme,logo=(theme==3 ? "tema-logo" : "missing-fixture-logo"),cor_fonte="black",cor_botoes="black",website="https://example.com/",instagram=""}]);
  for(route in ["/org/","/timer/","/circuito/","/evento/"]){
   VARIABLES.template=route;qFornecedor.tag_tipo=(route=="/timer/" ? "timer" : "org");
   headerPath=version & "-header.cfm"; savecontent variable="markup" {include headerPath;}
   arrayAppend(report.cases,{version=version,theme=theme,route=route,html=markup});
  }
 }
}
qEvento=queryNew("url_imagem,nome_evento","varchar,varchar",[{url_imagem="https://example.com/poster.png",nome_evento='Corrida "A" <B> & C'}]);
savecontent variable="report.poster" {include "poster-test.cfm";}
''' + "'''"+r'''
print(json.dumps(bridge(root,body)))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=140)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
def lower(x):
 if isinstance(x,dict):return {k.lower():lower(v) for k,v in x.items()}
 if isinstance(x,list):return [lower(v) for v in x]
 return x
r=lower(json.loads(cp.stdout));tests=[]
for x in r['cases']:
 p=P();p.feed(x['html']);expected=1 if x['version']=='candidate' and x['route']!='/evento/' else 0
 assert p.h1==expected and not p.bad,x
 if expected:assert ''.join(p.names).strip(),x
 if x['theme']==3:assert any(a.get('src')=='/assets/logos/tema-logo.svg' for a in p.images),x
 tests.append({k:v for k,v in x.items() if k!='html'}|{'h1':p.h1,'valid_heading_children':not p.bad})
p=P();p.feed(r['poster']);assert len(p.images)==1 and p.images[0]['alt']=='Corrida "A" <B> & C' and p.images[0]['src']=='https://example.com/poster.png'
receipt={'hashes':{n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in json.loads((S/'before.json').read_text())},'watch':json.loads((S/'watch.json').read_text()),'header_cases':tests,'encoded_poster_alt':True,'login_only_heading_changed':True,'event_only_alt_changed':True}
(S/'candidate-render-passed.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2));print(json.dumps({'header_renders':len(tests),'encoded_poster_alt':True,'auth_queries_unchanged':True}))
