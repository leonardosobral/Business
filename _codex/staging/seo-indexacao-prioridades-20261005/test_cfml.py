from pathlib import Path
import re,json,subprocess,shlex,sys,hashlib
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['red','green','integration-red']
src=P/('baseline' if mode=='red' else 'published-first' if mode=='integration-red' else 'candidate')/'rr'
circuit=(src/'circuito/index.cfm').read_text().split('<!--- HEAD --->')[0]
def include_url_defaults(match):
 path=match.group(1).removeprefix('../')
 if path not in ['includes/estrutura/variaveis.cfm','includes/backend/backend_feed.cfm']:return ''
 return '\n'.join(re.findall(r'<cfparam\s+name="URL\.[^>]+>',(P/'baseline/rr'/path).read_text(),re.I))
circuit=re.sub(r'<cfinclude\s+template="([^"]+)"\s*/>', include_url_defaults, circuit, flags=re.I)
boot='<cfsetting showdebugoutput="false"/><cfscript>VARIABLES.queryString="";APPLICATION.baseCanonica="https://roadrunners.run";APPLICATION.nomeSite="Road Runners";function logQueryDebug(){}</cfscript>'
out='<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({canonical=VARIABLES.canonical,title=VARIABLES.title,description=VARIABLES.description})#</cfoutput>'
files={'circuit.cfm':boot+circuit+out}
query_end='<cfset logQueryDebug("qAgrega", qAgregaMeta, "circuito/agrega", "sem cache", qAgrega)/>'
assert circuit.count(query_end)==1
fixtures={'ambiguous':'<cfset queryAddRow(qAgrega,1)/><cfloop list="#qAgrega.columnList#" index="fixtureColumn"><cfset querySetCell(qAgrega,fixtureColumn,qAgrega[fixtureColumn][1],2)/></cfloop>', 'unsafe':'<cfset querySetCell(qAgrega,"tag","unsafe/tag")/>', 'form':'<cfset FORM.fixture="present"/>'}
for name,setup in fixtures.items():
 anchor='<!--- BACKEND --->' if name=='form' else query_end
 files[name+'.cfm']=boot+circuit.replace(anchor,setup+anchor if name=='form' else anchor+setup,1)+out
for year in ['2024','2025']:
 text=(src/('desafiosupra/'+year+'/index.cfm')).read_text();meta=text.split('<!--- META INFO --->')[1].split('<!--- HEAD --->')[0]
 files[year+'.cfm']=boot+'<cfset URL.tag=""/><cfset VARIABLES.template="/desafiosupra/'+year+'/"/>'+meta+out
cases=[('alias','circuit.cfm?tag=fca-corridaderua','GET',301),('canonical','circuit.cfm?tag=circuito-catarinense-corrida-de-rua','GET',200),('live','circuit.cfm?tag=live-run-xp','GET',200),('head-alias','circuit.cfm?tag=fca-corridaderua','HEAD',301),('post','circuit.cfm?tag=fca-corridaderua','POST',200),('filter','circuit.cfm?tag=fca-corridaderua&ano=2025','GET',200),('tracking','circuit.cfm?tag=fca-corridaderua&utm_source=seo','GET',200),('action','circuit.cfm?tag=fca-corridaderua&acao=teste','GET',200),('year-2024','2024.cfm','GET',200),('year-2025','2025.cfm','GET',200)]
cases += [('ambiguous','ambiguous.cfm?tag=fca-corridaderua','GET',200),('unsafe','unsafe.cfm?tag=fca-corridaderua','GET',200),('form','form.cfm?tag=fca-corridaderua','GET',200)]
cases += [('explicit-default-filter','circuit.cfm?tag=fca-corridaderua&distancia=1,42','GET',200),('explicit-default-page','circuit.cfm?tag=fca-corridaderua&page=0','GET',200)]
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-index-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p['files'].items():(work/n).write_text(v)
 report={}
 for name,path,method,status in p['cases']:
  headers=work/'headers.txt'
  args=['curl','-sS','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-D',str(headers),'-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+path]
  if method=='HEAD':args.insert(1,'--head')
  elif method!='GET':args[1:1]=['-X',method]
  cp=subprocess.run(args,capture_output=True,text=True,timeout=30)
  if cp.returncode:raise RuntimeError(cp.stderr)
  body,_,code=cp.stdout.rpartition('\\n');report[name]={'status':int(code),'body':body,'headers':headers.read_text()}
 print(json.dumps(report))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'cases':cases}),capture_output=True,text=True,timeout=330)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);checks=[]
def check(name,ok):checks.append({'name':name,'passed':bool(ok)})
for name,path,method,status in cases:
 x=r[name];check(name+' status',x['status']==status)
 if name in ['alias','head-alias']:
  loc=re.search(r'^location:\s*(.*?)\s*$',x['headers'],re.I|re.M);check(name+' exact destination',loc and loc.group(1).endswith('/circuito/circuito-catarinense-corrida-de-rua/') and ';' not in loc.group(1))
 elif x['status']==200:
  data=json.loads(x['body']);x['meta']=data
  if name in ['ambiguous','unsafe']:check(name+' does not guess canonical',data['CANONICAL']=='https://roadrunners.run/circuito/fca-corridaderua/')
  elif name in ['post','filter','tracking','action','canonical','form','explicit-default-filter','explicit-default-page']:check(name+' one canonical',data['CANONICAL']=='https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/')
  elif name=='live':check('other circuit unchanged',data['CANONICAL']=='https://roadrunners.run/circuito/live-run-xp/' and data['TITLE']=='Circuito Live! Run XP - Road Runners')
  else:
   year=name[-4:];check(name+' canonical unchanged',data['CANONICAL']=='https://roadrunners.run/desafiosupra/'+year+'/');check(name+' year in title',year in data['TITLE']);check(name+' year in description',year in data['DESCRIPTION'])
check('different annual titles',r['year-2024']['meta']['TITLE']!=r['year-2025']['meta']['TITLE']);check('different annual descriptions',r['year-2024']['meta']['DESCRIPTION']!=r['year-2025']['meta']['DESCRIPTION'])
failed=[x['name'] for x in checks if not x['passed']]
receipt={'mode':mode,'scenarios':len(cases),'checks':checks,'failed':failed,'source_hashes':{n:hashlib.sha256((src/n).read_bytes()).hexdigest() for n in ['circuito/index.cfm','desafiosupra/2024/index.cfm','desafiosupra/2025/index.cfm']}}
(P/('tests-'+mode+'.json')).write_text(json.dumps(receipt,indent=2));print(json.dumps({'mode':mode,'scenarios':len(cases),'checks':len(checks),'failed':failed}));assert bool(failed)==(mode in ['red','integration-red'])
