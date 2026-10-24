from pathlib import Path
import json,shlex,subprocess,sys,hashlib,html,re,base64
P=Path('/Users/Shared/Projects/RunnerHub/Business/_codex/staging/seo-event-routes-20261008');mode=sys.argv[1];assert mode in ['red','green','published-red','review-red']
src=Path('/Users/Shared/Projects/RunnerHub/Business/_codex/staging/seo-impact-20261021/candidate/rr/includes/estrutura/event_title_date.cfm')
event=(P/'baseline/rr/evento/index.cfm').read_text()
title=event.split('<cfset VARIABLES.eventTitleTypeLabel = ""/>')[1].split('<cfset VARIABLES.structuredDataJsonLd')[0]
title='<cfset VARIABLES.eventTitleTypeLabel = ""/>'+title.split('<cfset VARIABLES.keywords')[0]
run='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfscript>
APPLICATION.nomeSite="Road Runners";checks=[];titles=[];
function check(required string name,required boolean pass){arrayAppend(checks,{name=name,passed=pass});}
langs=[{code="pt-BR",label="corrida de rua"},{code="en",label="Road race"},{code="es",label="Carrera de ruta"}];
ids=[37730,45554,45643,45646,45906];
</cfscript><cfquery name="qRaces">SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE id_evento IN(37730,45554,45643,45646,45906) ORDER BY id_evento</cfquery>
<cfloop array="#langs#" index="language"><cfset languageTitles=[]/>
<cfloop query="qRaces">
<cfset qEvento=queryNew(qRaces.columnList)/><cfset queryAddRow(qEvento)/><cfloop list="#qRaces.columnList#" index="col"><cfset querySetCell(qEvento,col,qRaces[col][qRaces.currentRow])/></cfloop>
<cfset eventMetaCatalog={roadRaceTitle=language.label,freeTrainingTitle="Treino"}/>
<cfinclude template="title_base.cfm"/><cfinclude template="title.cfm"/>
<cfscript>
check(language.code & " city " & qEvento.id_evento,find(qEvento.cidade,VARIABLES.title)>0);
check(language.code & " date " & qEvento.id_evento,find(dateFormat(qEvento.data_inicial,"dd/mm/yyyy"),VARIABLES.title)>0);
check(language.code & " brand " & qEvento.id_evento,find(APPLICATION.nomeSite,VARIABLES.title)>0);
arrayAppend(languageTitles,VARIABLES.title);arrayAppend(titles,{id=qEvento.id_evento,lang=language.code,title=VARIABLES.title});
</cfscript></cfloop><cfscript>check(language.code & " five distinct titles",arrayLen(structKeyArray(arrayToStruct(languageTitles)))==5);</cfscript></cfloop>
<cfscript>
function arrayToStruct(required array values){var result={};for(var value in arguments.values)result[value]=true;return result;}
</cfscript>
<!--- Preserve behavior for same-name stages already fixed by dates. --->
<cfquery name="qStages">SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE id_evento IN(37531,37568,40833) ORDER BY id_evento</cfquery>
<cfloop query="qStages"><cfset qEvento=queryNew(qStages.columnList)/><cfset queryAddRow(qEvento)/><cfloop list="#qStages.columnList#" index="col"><cfset querySetCell(qEvento,col,qStages[col][qStages.currentRow])/></cfloop><cfset eventMetaCatalog={roadRaceTitle="corrida de rua",freeTrainingTitle="Treino"}/><cfinclude template="title_base.cfm"/><cfinclude template="title.cfm"/>
<cfscript>check("existing date title " & qEvento.id_evento,find(dateFormat(qEvento.data_inicial,"dd/mm/yyyy"),VARIABLES.title)>0 && len(VARIABLES.title)<=70);arrayAppend(titles,{id=qEvento.id_evento,lang="pt-BR",title=VARIABLES.title});</cfscript></cfloop>
<!--- Unknown, unique and markup-bearing names must not get invented data or raw HTML. --->
<cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial,tipo_corrida","varchar,varchar,varchar,date,varchar",[{nome_evento="Unique Fixture Race SEO 20261005",cidade="Curitiba",estado="PR",data_inicial=createDate(2026,11,22),tipo_corrida="rua"}])/>
<cfset VARIABLES.title="Unique original title"/><cfinclude template="title.cfm"/><cfset check("unique title unchanged",VARIABLES.title EQ "Unique original title")/>
<cfset qEvento=queryNew("nome_evento,data_inicial", "varchar,varchar",[{nome_evento="Missing date",data_inicial=""}])/>
<cfset VARIABLES.title="Missing date preserved"/><cfinclude template="title.cfm"/><cfset check("missing date unchanged",VARIABLES.title EQ "Missing date preserved")/>
<cfset protectedOriginalTitles=deserializeJSON(toString(binaryDecode("__PROTECTED_TITLES__","base64")))/>
<cfquery name="qProtected">SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE id_evento IN(46596,46597) ORDER BY id_evento</cfquery>
<cfloop query="qProtected"><cfset qEvento=queryNew(qProtected.columnList)/><cfset queryAddRow(qEvento)/><cfloop list="#qProtected.columnList#" index="col"><cfset querySetCell(qEvento,col,qProtected[col][qProtected.currentRow])/></cfloop>
<cfset eventMetaCatalog={roadRaceTitle="corrida de rua",freeTrainingTitle="Treino"}/><cfinclude template="title_base.cfm"/><cfinclude template="title.cfm"/>
<cfset check("already distinct prefix title preserved " & qEvento.id_evento,VARIABLES.title EQ protectedOriginalTitles[qEvento.id_evento & ""])/><cfset arrayAppend(titles,{id=qEvento.id_evento,lang="protected",title=VARIABLES.title,old=protectedOriginalTitles[qEvento.id_evento & ""]})/>
</cfloop>
<!--- The Semrush 08/10 cases share prefixes despite case differences. --->
<cfquery name="qNewTitles">SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial,tipo_corrida FROM tb_evento_corridas WHERE id_evento IN(23725,25734,37918,45372) ORDER BY id_evento</cfquery>
<cfloop array="#langs#" index="language"><cfset newLanguageTitles=[]/>
<cfloop query="qNewTitles"><cfset qEvento=queryNew(qNewTitles.columnList)/><cfset queryAddRow(qEvento)/><cfloop list="#qNewTitles.columnList#" index="col"><cfset querySetCell(qEvento,col,qNewTitles[col][qNewTitles.currentRow])/></cfloop>
<cfset eventMetaCatalog={roadRaceTitle=language.label,freeTrainingTitle="Treino"}/><cfinclude template="title_base.cfm"/><cfinclude template="title.cfm"/>
<cfscript>
check(language.code & " new date " & qEvento.id_evento,find(dateFormat(qEvento.data_inicial,"dd/mm/yyyy"),VARIABLES.title)>0);
check(language.code & " new city " & qEvento.id_evento,find(qEvento.cidade,VARIABLES.title)>0);
arrayAppend(newLanguageTitles,lCase(VARIABLES.title));arrayAppend(titles,{id=qEvento.id_evento,lang=language.code,title=VARIABLES.title});
</cfscript></cfloop><cfset check(language.code & " new titles distinct ignoring case",arrayLen(structKeyArray(arrayToStruct(newLanguageTitles))) EQ 4)/></cfloop>
<!--- Transaction-local fixtures exercise collisions and escaping without changing event records. --->
<cftransaction>
<cfquery>CREATE TEMP TABLE tb_evento_corridas(nome_evento varchar,cidade varchar,estado varchar,data_inicial date,ativo boolean) ON COMMIT DROP</cfquery>
<cfscript>
fixturePrefix="Fixture collision & " & repeatString("Race ",10);
fixtureNames=[fixturePrefix & "Alpha",fixturePrefix & "Beta"];
for(fixtureName in fixtureNames){
 queryExecute("INSERT INTO tb_evento_corridas VALUES(:name,:city,:state,:date,true)",{
  name={value=fixtureName,cfsqltype="cf_sql_varchar"},city={value='City <safe> "quoted"',cfsqltype="cf_sql_varchar"},state={value="PR",cfsqltype="cf_sql_varchar"},date={value="2026-10-11",cfsqltype="cf_sql_date"}},{datasource="runner_dba"});
}
fixtureTitles=[];
</cfscript>
<cfloop array="#fixtureNames#" index="fixtureName">
<cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial,tipo_corrida","varchar,varchar,varchar,date,varchar",[{nome_evento=fixtureName,cidade='City <safe> "quoted"',estado="PR",data_inicial="2026-10-11",tipo_corrida="rua"}])/>
<cfset VARIABLES.title="Original duplicate"/><cfset VARIABLES.eventTitleTypeLabel="corrida de rua"/><cfinclude template="title.cfm"/>
<cfscript>
check("same place date preserves full identity " & right(fixtureName,5),find(HTMLEditFormat(fixtureName),VARIABLES.title)>0);
check("city HTML escaped " & right(fixtureName,5),find("&lt;safe&gt;",VARIABLES.title)>0 && find("<safe>",VARIABLES.title)==0);
arrayAppend(fixtureTitles,VARIABLES.title);
</cfscript></cfloop>
<cfset check("same place date different names stay distinct",fixtureTitles[1] NEQ fixtureTitles[2])/>
<!--- Same-name date differentiation retains its original behavior and limit. --->
<cfscript>
fixtureName='Fixture dated "<race>"';
for(fixtureDate in ["2026-03-08","2026-05-17"]){queryExecute("INSERT INTO tb_evento_corridas VALUES(:name,'','',:date,true)",{name={value=fixtureName,cfsqltype="cf_sql_varchar"},date={value=fixtureDate,cfsqltype="cf_sql_date"}},{datasource="runner_dba"});}
</cfscript>
<cfloop array="#["2026-03-08","2026-05-17"]#" index="fixtureDate"><cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial","varchar,varchar,varchar,date",[{nome_evento=fixtureName,cidade="",estado="",data_inicial=fixtureDate}])/>
<cfset VARIABLES.title="Original duplicate"/><cfinclude template="title.cfm"/>
<cfset arrayAppend(titles,{id="dated-fixture",lang="fixture",title=VARIABLES.title,repeated=qEventTitleDate.repeated_name,truncated=structKeyExists(VARIABLES,"eventTruncatedName") ? VARIABLES.eventTruncatedName : false})/>
<cfset check("dated HTML escaped " & fixtureDate,find("&lt;race&gt;",VARIABLES.title) GT 0 AND len(VARIABLES.title) LTE 100)/>
</cfloop>
<!--- A repeated full name must retain dated titles even when two other names share its prefix. --->
<cfscript>
fixtureRepeatedName=fixturePrefix & "Repeated";
for(fixtureDate in ["2026-03-08","2026-05-17"]){queryExecute("INSERT INTO tb_evento_corridas VALUES(:name,'Other city','SC',:date,true)",{name={value=fixtureRepeatedName,cfsqltype="cf_sql_varchar"},date={value=fixtureDate,cfsqltype="cf_sql_date"}},{datasource="runner_dba"});}
</cfscript>
<cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial","varchar,varchar,varchar,date",[{nome_evento=fixtureRepeatedName,cidade="Other city",estado="SC",data_inicial="2026-03-08"}])/>
<cfset VARIABLES.title="Original duplicate"/><cfset VARIABLES.eventTitleTypeLabel="corrida de rua"/><cfinclude template="title.cfm"/>
<cfset check("repeated name among other colliding prefixes preserves original 2026-03-08",VARIABLES.title EQ "Fixture collision &amp; Race - corrida de rua | 08/03/2026 | Road Runners" )/>
<cfset qEvento=queryNew("nome_evento,cidade,estado,data_inicial","varchar,varchar,varchar,date",[{nome_evento=fixtureRepeatedName,cidade="Other city",estado="SC",data_inicial="2026-05-17"}])/>
<cfset VARIABLES.title="Original duplicate"/><cfset VARIABLES.eventTitleTypeLabel="corrida de rua"/><cfinclude template="title.cfm"/>
<cfset check("repeated name among other colliding prefixes preserves original 2026-05-17",VARIABLES.title EQ "Fixture collision &amp; Race - corrida de rua | 17/05/2026 | Road Runners" )/>
</cftransaction>
<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({checks=checks,titles=titles})#</cfoutput>
'''
old=json.loads((P/'current-pages.json').read_text())['pages'];events=json.loads((P/'events.json').read_text())['events']
protected={str(e['id_evento']):next(x['title'] for x in old if x['url']=='https://roadrunners.run/evento/'+e['tag']+'/') for e in events if e['id_evento'] in [46596,46597]}
run=run.replace('__PROTECTED_TITLES__',base64.b64encode(json.dumps(protected).encode()).decode())
run=run.split('<cftransaction>')[0]+'<cftransaction>'+run.split('<cftransaction>')[1].replace('template="title.cfm"','template="title_temp.cfm"')
run=run.split('<!--- Transaction-local fixtures exercise')[0]+'<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({checks=checks,titles=titles})#</cfoutput>'
run=run.replace('<cfinclude template="title.cfm"/>','<cfinclude template="title.cfm"/><cfset VARIABLES.title=canonicalize(VARIABLES.title,false,false)/>')
files={'title.cfm':re.sub(r' cachedwithin="[^"]+"', '', src.read_text()),'title_base.cfm':title,'run.cfm':run}
files['title_temp.cfm']=files['title.cfm'].replace('SELECT EXISTS (','SELECT /* __FIXTURE_CONTEXT__ */ EXISTS (').replace('SELECT coalesce','SELECT /* __FIXTURE_CONTEXT__ */ coalesce').replace('SELECT lower(left(nome_evento','SELECT /* __FIXTURE_CONTEXT__ */ lower(left(nome_evento').replace('SELECT left(nome_evento','SELECT /* __FIXTURE_CONTEXT__ */ left(nome_evento')
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-title-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():(work/n).write_text(v.replace('__FIXTURE_CONTEXT__',work.name))
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError(cp.stdout[:3000])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=80)
assert cp.returncode==0,cp.stderr[-3200:]
r=json.loads(cp.stdout);failed=[x['NAME'] for x in r['CHECKS'] if not x['PASSED']]
r.update({'failed':failed,'fixture_cache_disabled':True,'source_hash':hashlib.sha256(src.read_bytes()).hexdigest()})
(Path(__file__).resolve().parent/('title-controls-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'checks':len(r['CHECKS']),'failed':failed},ensure_ascii=False))
assert bool(failed)==(mode in ['red','published-red','review-red'])
