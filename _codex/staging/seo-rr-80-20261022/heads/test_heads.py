from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent;B=S.parents[3]
files={k+'/head.cfm':(S/'candidate'/k/'includes/estrutura/head.cfm').read_text() for k in ['rr','business']}
files['rr/event_title_date.cfm']=(B.parent/'RoadRunners/includes/estrutura/event_title_date.cfm').read_text()
files['rr/seo-web-tools-head.cfm']='<!--- Private fixture: tracking and assets are verified on public pages, not executed here. --->'
cases=[dict(template='/evento/',description='"Corrida & Caminhada" acontece em Franco da Rocha.',expected='"Corrida & Caminhada" acontece em Franco da Rocha.'),dict(template='/evento/',description="Corrida d'Água, percurso < 10 km e 100% alegria.",expected="Corrida d'Água, percurso < 10 km e 100% alegria."),dict(template='/evento/',description='Corrida em São Paulo, 28 de março de 2027.',expected='Corrida em São Paulo, 28 de março de 2027.'),dict(template='/noticias/',description='A &amp; B &quot;notícia&quot;',expected='A & B "notícia"')]
files['run.cfm']='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/>
<cfset APPLICATION.nomeSite="Road Runners"/><cfset rows=[]/>
<cfset cases=deserializeJSON(toString(binaryDecode("CASES","base64")))/>
<cftransaction><cfquery>SET TRANSACTION READ ONLY</cfquery>
<cfloop array="#cases#" item="item">
 <cfset VARIABLES.template=item.template/><cfset VARIABLES.description=item.description/><cfset VARIABLES.title="Corrida SEO"/><cfset VARIABLES.keywords="corrida"/><cfset VARIABLES.canonical="https://roadrunners.run/evento/fixture/"/>
 <cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial", "varchar,varchar,varchar,date",[{nome_evento="SEO Fixture",cidade="Manaus",estado="AM",data_inicial=createDate(2027,3,28)}])/>
 <cfsavecontent variable="rendered"><cfinclude template="rr/head.cfm"/></cfsavecontent>
 <cfset arrayAppend(rows,{kind="rr",template=item.template,expected=item.expected,html=rendered})/>
</cfloop></cftransaction>
<cfloop array="#["/cadastro/","/login/","/portal/seo/","/portal/conteudo/"]#" item="templateName">
 <cfset VARIABLES.template=templateName/>
 <cfsavecontent variable="rendered"><cfinclude template="business/head.cfm"/></cfsavecontent>
 <cfset arrayAppend(rows,{kind="business",template=templateName,html=rendered})/>
</cfloop>
<cfoutput>#serializeJSON(rows)#</cfoutput>'''
import base64
files['run.cfm']=files['run.cfm'].replace('CASES',base64.b64encode(json.dumps(cases,ensure_ascii=False).encode()).decode())
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');w=Path(tempfile.mkdtemp(prefix='seo-head-meta-',dir=root/'_codex'));os.chmod(w,0o755);key=secrets.token_hex(24)
try:
 (w/'.htaccess').write_text('Require local\\n')
 (w/'Application.cfc').write_text('component{this.name="'+w.name+'";this.datasource="runnerhub";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():
  f=w/n;f.parent.mkdir(exist_ok=True,parents=True);f.write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+w.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError(cp.stdout[:1800]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(w)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=85);assert cp.returncode==0,cp.stderr[-2000:]
rows=json.loads(cp.stdout);checks=[]
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.meta={};self.intitle=False;self.title=''
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='meta':self.meta[d.get('name') or d.get('property')]=d.get('content')
  if t=='title':self.intitle=True
 def handle_endtag(self,t):
  if t=='title':self.intitle=False
 def handle_data(self,d):
  if self.intitle:self.title+=d
for i,item in enumerate(rows):
 item={k.lower():v for k,v in item.items()};p=Meta();p.feed(item['html'])
 if item['kind']=='rr':
  for key in ['description','og:description','twitter:description']:checks.append(dict(name=f'{i} {key}',passed=p.meta.get(key)==item['expected']))
 else:
  checks.append(dict(name=item['template']+' description policy',passed=bool(p.meta.get('description'))==(item['template']=='/cadastro/')))
  checks.append(dict(name=item['template']+' existing title',passed=p.title=={'/portal/seo/':'SEO · Road Runners Business','/portal/conteudo/':'Conteúdo das provas · Road Runners Business'}.get(item['template'],'Road Runners Business')))
r=dict(checks=checks,failed=[c['name'] for c in checks if not c['passed']],hashes={k:{'includes/estrutura/head.cfm':hashlib.sha256((S/'candidate'/k/'includes/estrutura/head.cfm').read_bytes()).hexdigest()} for k in ['rr','business']})
(S/'tests-green.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(dict(checks=len(checks),failed=r['failed']),ensure_ascii=False));assert not r['failed']
