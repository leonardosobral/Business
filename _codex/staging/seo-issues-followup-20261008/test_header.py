from pathlib import Path
from html.parser import HTMLParser
import base64,hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['candidate','published']
remote='''from pathlib import Path
import base64,json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');work=Path(tempfile.mkdtemp(prefix='seo-marathon-h1-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for group in ['baseline','candidate']:
  (work/(group+'.cfm')).write_text(p['files'][group] if group=='baseline' or p['mode']=='candidate' else (root/'includes/estrutura/header_tema.cfm').read_text())
 cases=[]
 for route in ['/maratona/','/org/','/timer/','/circuito/','/evento/']:
  for themed in [False,True]:
   for compact in [False,True]:cases.append({'route':route,'themed':themed,'compact':compact})
 rows=[]
 for i,c in enumerate(cases):
  setup="""<cfsetting showdebugoutput="false"/><cfscript>
request.i18n={common={themeHeader={website="Site oficial",instagram="Instagram"}}};
request.t=function(required string path, struct args={}) {return args.name ?: path;};
qAgrega=queryNew("nome_evento_agregado,tipo_agregacao,tag","varchar,varchar,varchar",[{nome_evento_agregado="Maratona de Teste",tipo_agregacao="maratona",tag="teste"}]);
qFornecedor=queryNew("nome_fornecedor,tag,tag_tipo","varchar,varchar,varchar",[{nome_fornecedor="Organizador de Teste",tag="org-teste",tag_tipo="org"}]);
qTema=queryNew("id_tema,logo,cor_fonte,cor_botoes,website,instagram","integer,varchar,varchar,varchar,varchar,varchar",[{id_tema=THEME_ID,logo="maratona-internacional-de-sao-paulo",cor_fonte="black",cor_botoes="black",website="https://example.com",instagram=""}]);
variables.template="ROUTE";variables.eventThemeHeaderCompact=COMPACT;
</cfscript>"""
  setup=setup.replace('THEME_ID','26' if c['themed'] else '1').replace('ROUTE',c['route']).replace('COMPACT','true' if c['compact'] else 'false')
  out={}
  for group in ['baseline','candidate']:
   entry='test-'+str(i)+'-'+group+'.cfm';(work/entry).write_text(setup+'<cfinclude template="'+group+'.cfm"/>')
   cp=subprocess.run(['curl','-sS','--max-time','20','--resolve','roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-w','\\n%{http_code}','https://roadrunners.run/_codex/'+work.name+'/'+entry],capture_output=True,text=True,timeout=25)
   body,_,status=cp.stdout.rpartition('\\n');out[group]={'status':int(status or 0),'body':base64.b64encode(body.encode()).decode(),'returncode':cp.returncode}
  rows.append({**c,**out})
 print(json.dumps({'rows':rows}))
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':{g:(S/g/'rr/includes/estrutura/header_tema.cfm').read_text() for g in ['baseline','candidate']}}),capture_output=True,text=True,timeout=200)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout)
class H1(HTMLParser):
 def __init__(self):super().__init__();self.count=0;self.on=False;self.text='';self.images=[]
 def handle_starttag(self,t,a):
  if t=='h1':self.count+=1;self.on=True
  if t=='img' and self.on:self.images.append(dict(a).get('alt',''))
 def handle_endtag(self,t):
  if t=='h1':self.on=False
 def handle_data(self,d):
  if self.on:self.text+=d
for row in r['rows']:
 bodies={};heads={}
 for g in ['baseline','candidate']:
  b=base64.b64decode(row[g].pop('body')).decode();bodies[g]=b;assert row[g]['status']==200 and not row[g]['returncode'],row
  assert 'Error Occurred While Processing Request' not in b,row
  h=H1();h.feed(b);heads[g]=h
 expected=0 if row['route']=='/evento/' else 1
 assert heads['candidate'].count==expected,row
 if row['route']=='/maratona/':
  assert heads['baseline'].count==0,row
  assert 'Maratona de Teste' in heads['candidate'].text or any('Maratona de Teste' in a for a in heads['candidate'].images),row
  # Apart from the new wrapper, content is identical. CF emits one extra trailing blank when h1 is evaluated.
  without=bodies['candidate'].replace('<h1 class="m-0" style="font-size: inherit; line-height: inherit; font-weight: inherit;">','').replace('</h1>','')
  assert [line.rstrip() for line in without.splitlines()]==[line.rstrip() for line in bodies['baseline'].splitlines()],row
 else:assert bodies['baseline']==bodies['candidate'],row
 row['passed']=True
r['source_hash']=hashlib.sha256((S/'candidate/rr/includes/estrutura/header_tema.cfm').read_bytes()).hexdigest();r['mode']=mode
(S/(mode+'-header-passed.json')).write_text(json.dumps(r,indent=2));print(json.dumps({'mode':mode,'scenarios':len(r['rows']),'new_marathon_cases':4,'unchanged_controls':16}))
