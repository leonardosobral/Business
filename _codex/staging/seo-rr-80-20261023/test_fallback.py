from pathlib import Path
import ast,hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent;n='includes/estrutura/menu_apps_data.cfm'
previous=(S/'runtime/baseline'/n).read_text().split('function runnerAppsMenuNormalizeItem')[0].replace('runnerAppsMenuFallbackData','previousRunnerAppsMenuFallbackData')+'</cfscript>'
current=(S/'runtime/candidate'/n).read_text()
fixture='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/>
<cfset REQUEST.runnerAppsMenuItems=[]/><cfinclude template="previous.cfm"/><cfinclude template="current.cfm"/>
<cfscript>
catalog={roadRunnersAlt="Road Runners",roadRunners="Road Runners",openResultsAlt="Open Results",openResults="Open Results",runnersStoreAlt="Runners Store",runnersStore="Runners Store",desafioSupraAlt="Brasil Gigante",desafioSupra="Brasil Gigante",circuitoCatarinenseAlt="Circuito Catarinense",circuitoCatarinense="Circuito Catarinense",todoSantoDiaAlt="Todo Santo Dia",todoSantoDia="Todo Santo Dia",poweredBy="Powered by"};
rows=[];
for(base in ["https://roadrunners.run","https://beta.roadrunners.run","https://dev.roadrunners.run"]){
 for(path in ["/","/en/","/es/"]){
  arrayAppend(rows,{home=base & path,previous=previousRunnerAppsMenuFallbackData(catalog,base & path),current=runnerAppsMenuFallbackData(catalog,base & path)});
 }
}
writeOutput(serializeJSON(rows));</cfscript>'''
tree=ast.parse((S.parent/'seo-impact-20261021/test_menu.py').read_text())
remote=next(ast.literal_eval(x.value) for x in tree.body if isinstance(x,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='remote' for t in x.targets))
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'previous.cfm':previous,'current.cfm':current,'run.cfm':fixture}),capture_output=True,text=True,timeout=65);assert cp.returncode==0,cp.stderr[-2000:]
rows=json.loads(cp.stdout);checks=[]
for x in rows:
 x={k.lower():v for k,v in x.items()};a=x['previous'];b=x['current'];home=x['home']
 checks.append(dict(name=home+' exact remaining items',passed=b['items']==[i for i in a['items'] if i['href']!='https://store.roadrunners.run/']))
 expected=[]
 for g in a['groups']:
  g=dict(g);g['items']=[i for i in g['items'] if i['href']!='https://store.roadrunners.run/'];expected.append(g)
 checks.append(dict(name=home+' group contract',passed=b['groups']==expected))
 checks.append(dict(name=home+' powered by',passed=b['poweredBy']==a['poweredBy']))
 checks.append(dict(name=home+' localized home',passed=b['items'][0]['href']==home))
out=dict(checks=checks,failed=[x['name'] for x in checks if not x['passed']],source_hash=hashlib.sha256(current.encode()).hexdigest())
(S/'fallback-tests.json').write_text(json.dumps(out,indent=2));print(json.dumps(dict(checks=len(checks),failed=out['failed'])));assert not out['failed']
