from pathlib import Path
import re,json,shlex,subprocess,hashlib
s=Path(__file__).resolve().parent;root=Path.cwd();name='circuitocatarinense/corridaderua/index.cfm'
def extract(mode):
 t=(s/mode/name).read_text();main=re.search(r'<cfquery name="qRankingCatarina">(.*?)</cfquery>',t,re.S).group(1).strip()
 qoq={n:re.search(r'<cfquery name="'+n+r'" dbtype="query">(.*?)</cfquery>',t,re.S).group(1).strip() for n in ['qRankingCatarinaF','qRankingCatarinaM','qRankingAssessoriaCatarina']}
 return main,qoq
old,queries=extract('baseline');new,qnew=extract('candidate');assert queries==qnew
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace('runner_dba','runnerhub')
remote=helpers+'''
p=json.load(sys.stdin);body='report={cases=[]};'
for label,sql in p['sql'].items():
 body+='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')+raw_query(sql,'qRankingCatarina')+'}'
 for n,q in p['qoq'].items():body+='cfquery(name="'+n+'",dbtype="query"){writeOutput(toString(binaryDecode("'+base64.b64encode(q.encode()).decode()+'","base64")));}'
 body+='arrayAppend(report.cases,{label='+json.dumps(label)+',rows=qRankingCatarina.recordCount,female=qRankingCatarinaF.recordCount,male=qRankingCatarinaM.recordCount,teams=qRankingAssessoriaCatarina.recordCount,team_hash=hash(serializeJSON(qRankingAssessoriaCatarina),"SHA-256")});'
print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))
'''
payload={'sql':{'baseline':old,'candidate':new,'empty':new.replace("'catarinensecorridaderua'","'__seo_fixture_no_registration__'")},'qoq':queries}
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=110)
if p.returncode:raise RuntimeError(p.stderr[-2500:])
r=json.loads(p.stdout);cases=[{k.lower():v for k,v in x.items()} for x in r.get('cases',r.get('CASES'))];a,b,e=cases
for k in ['rows','female','male','teams','team_hash']:assert a[k]==b[k],(k,a[k],b[k])
for k in ['rows','female','male','teams']:assert e[k]==0,e
(s/'consumer-tests.json').write_text(json.dumps(cases,indent=2))
profile=json.loads((s/'candidate-profile.json').read_text());assert profile.get('execution_ms',profile.get('EXECUTION_MS'))<1500
same=json.loads((s/'sql-equivalence.json').read_text());assert same['different_rows']==0 and same['synthetic_differences']==0
(s/'candidate-render-passed.json').write_text(json.dumps({'hashes':{name:hashlib.sha256((s/'candidate'/name).read_bytes()).hexdigest()},'watch':json.loads((s/'watch.json').read_text()),'rows':b['rows'],'datasource':'runnerhub','consumer_cases':3,'sql_equivalence':same,'execution_ms':profile.get('execution_ms',profile.get('EXECUTION_MS'))},indent=2))
print(json.dumps({'consumer_cases_passed':3,'rows':b['rows'],'female':b['female'],'male':b['male'],'teams':b['teams']}))
