from pathlib import Path
from html.parser import HTMLParser
import hashlib,html,json,re,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('red','green');root=S/('baseline' if mode=='red' else 'candidate')
news=(root/'noticias/index.cfm').read_text()
helpers=news.split('function newsPlainText(')[1].split('function newsSummaryParagraphs(')[0];helpers='function newsPlainText('+helpers
assignment=re.findall(r'^\s*<cfset VARIABLES.description = newsMetaDescription\([^\n]+',news,re.M);assert len(assignment)==1
encoding='<cfset VARIABLES.description = encodeForHTMLAttribute(VARIABLES.description)/>' if '<cfset VARIABLES.description = encodeForHTMLAttribute(VARIABLES.description)/>' in news else ''
titleLines={name:re.findall(r'^<cfset VARIABLES.title = [^\n]+', (root/name).read_text(),re.M)[0] for name in ['org/index.cfm','timer/index.cfm']}
cases=[{'title':'Corrida da Serra abre inscrições para 2027','preferred':'','summary':'','expected':'Corrida da Serra abre inscrições para 2027'},{'title':'Maratona revela a medalha de 2026','preferred':'','summary':'','expected':'Maratona revela a medalha de 2026'},{'title':'<b>Corrida "Noite & Dia"</b>','preferred':'','summary':'','expected':'Corrida "Noite & Dia"'},{'title':'Título ignorado','preferred':'Descrição editorial própria','summary':'Resumo secundário','expected':'Descrição editorial própria'},{'title':'Título ignorado','preferred':'','summary':'Resumo <strong>disponível</strong> da matéria.','expected':'Resumo disponível da matéria.'},{'title':'Título ignorado','preferred':'Resumo com "aspas" & corrida','summary':'','expected':'Resumo com "aspas" & corrida'},{'title':'Título ignorado','preferred':'','summary':'Resumo com "aspas" & corrida','expected':'Resumo com "aspas" & corrida'}]
fixture='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'''+helpers+'''
APPLICATION.nomeSite="Road Runners";resultRows=[];supplierRows=[];
cases=deserializeJSON(toString(binaryDecode("__CASES__","base64")));
</cfscript>
<cfloop array="#cases#" item="item">
 <cfset VARIABLES.noticia={title=item.title}/><cfset VARIABLES.noticiaSummaryMetaDescription=item.preferred/><cfset VARIABLES.noticiaSummaryText=item.summary/>
 __ASSIGNMENT__
 <cfset plainDescription=VARIABLES.description/>
 __ENCODING__
 <cfsavecontent variable="markup"><meta name="description" content="<cfoutput>#VARIABLES.description#</cfoutput>" /></cfsavecontent>
 <cfset arrayAppend(resultRows,{description=plainDescription,markup=markup,expected=item.expected})/>
</cfloop>
<cfloop array="#['Corre Brasil','Fornecedor "A & B"','Fornecedor de corrida']#" item="supplier">
 <cfset qFornecedor={nome_fornecedor=supplier}/>
 __ORG__
 <cfset orgTitle=VARIABLES.title/>
 __TIMER__
 <cfset arrayAppend(supplierRows,{name=supplier,org=orgTitle,timer=VARIABLES.title})/>
</cfloop>
<cfoutput>#serializeJSON({news=resultRows,suppliers=supplierRows})#</cfoutput><cfcatch><cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'''
import base64
fixture=fixture.replace('__CASES__',base64.b64encode(json.dumps(cases).encode()).decode()).replace('__ASSIGNMENT__',assignment[0]).replace('__ENCODING__',encoding).replace('__ORG__',titleLines['org/index.cfm']).replace('__TIMER__',titleLines['timer/index.cfm'])
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-metadata-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'run.cfm').write_text(p['source']);cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stdout[:1500]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'source':fixture}),capture_output=True,text=True,timeout=65);assert cp.returncode==0,cp.stderr[-2000:]
result=json.loads(cp.stdout);assert 'NEWS' in result,result
class P(HTMLParser):
 def __init__(self):super().__init__();self.values=[]
 def handle_starttag(self,t,a):
  if t=='meta':self.values.append(dict(a))
checks=[]
for i,r in enumerate(result['NEWS']):
 r={k.lower():v for k,v in r.items()};p=P();p.feed(r['markup'])
 checks.append({'name':f'news {i} meaningful description','passed':r['description']==r['expected']})
 checks.append({'name':f'news {i} well-formed attribute','passed':p.values==[{'name':'description','content':r['expected']}]})
for r in result['SUPPLIERS']:
 r={k.lower():v for k,v in r.items()}
 checks.append({'name':r['name']+' role distinguishes title','passed':html.unescape(r['org'])!=html.unescape(r['timer'])})
 checks.append({'name':r['name']+' organizer identity','passed':html.unescape(r['org'])==r['name']+' | Organizadores - Road Runners'})
 checks.append({'name':r['name']+' timer identity','passed':html.unescape(r['timer'])==r['name']+' | Cronometragem - Road Runners'})
failed=[r['name'] for r in checks if not r['passed']]
(S/f'tests-{mode}.json').write_text(json.dumps({'checks':checks,'failed':failed,'hashes':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in ['noticias/index.cfm','org/index.cfm','timer/index.cfm']}},indent=2))
print(json.dumps({'checks':len(checks),'failed':failed},ensure_ascii=False));assert bool(failed)==(mode=='red')
