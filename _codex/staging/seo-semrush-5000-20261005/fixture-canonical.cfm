<cfsetting showdebugoutput="false"/><cfprocessingdirective pageencoding="utf-8"/>
<cfscript>
report={checks=[],headers=[],titles=[]};
function check(required string name,required boolean passed){arrayAppend(report.checks,{name=name,passed=passed});}
function testBuildPath(required string key){return key=="event" ? "/evento/" & REQUEST.currentRouteParams.tag & "/" : "/busca/";}
function testTranslate(required string key,struct params={}){return structKeyExists(params,"name") ? params.name : key;}
REQUEST.Usuario={logado=false};REQUEST.currentBaseUrl="https://roadrunners.run";
REQUEST.i18nBuildPath=testBuildPath;REQUEST.t=testTranslate;
REQUEST.currentRouteParams={};VARIABLES.template="/estado/";
cases=['normal-tag','2026-' & chr(34) & 'corrida' & chr(34),'2026-corrida-' & chr(35) & '04','2026-rock' & chr(10) & '-run','tag & with space'];
</cfscript>
<cfloop array="#cases#" index="testTag">
 <cfset tag=testTag/>
 <cfinclude template="card.cfm"/>
 <cfscript>
 expected="/evento/" & replace(encodeForURL(testTag),"+","%20","all") & "/";
 check("Encoded card route: " & serializeJSON(testTag),VARIABLES.eventCardDetailPath==expected);
 check("Route params restored",structIsEmpty(REQUEST.currentRouteParams));
 </cfscript>
</cfloop>
<cfscript>
VARIABLES.template="/timer/";
REQUEST.i18n={common={themeHeader={website="Site",instagram="Instagram"}}};
qFornecedor=queryNew("tag_tipo,tag,nome_fornecedor","varchar,varchar,varchar",[{tag_tipo="assessoria",tag="branca-esportes-saude-e-lazer",nome_fornecedor="Branca Esportes"}]);
</cfscript>
<cfloop array="#[1,2]#" index="themeId">
 <cfset qTema=queryNew("id_tema,logo,website,instagram,cor_fonte,cor_botoes","integer,varchar,varchar,varchar,varchar,varchar",[{id_tema=themeId,logo="",website="https://example.com",instagram="",cor_fonte="black",cor_botoes="black"}])/>
 <cfsavecontent variable="headerHtml"><cfinclude template="theme.cfm"/></cfsavecontent>
 <cfset arrayAppend(report.headers,{theme=themeId,html=headerHtml})/>
</cfloop>
<cfscript>
transaction {
 queryExecute("CREATE TEMP TABLE tb_evento_corridas(id_evento integer, tag varchar, tag_301 varchar, ativo boolean,nome_evento varchar,data_inicial date) ON COMMIT DROP",{}, {datasource="runner_dba"});
 queryExecute("INSERT INTO tb_evento_corridas(id_evento,tag,tag_301,ativo) VALUES (1,'canonical-tag',null,true),(2,'old-tag','canonical-tag',true),(3,'LIVE-II',null,true),(4,'ambiguous',null,true),(5,'AMBIGUOUS',null,true),(6,'loop-a','loop-b',true),(7,'loop-b','loop-a',true)",{}, {datasource="runner_dba"});
 svc=createObject("component","EventRedirectService");

 for(testCanonicalTag in ['LIVE-II','2025-live-run-xp-brasilia-I-2025','2026-endorfina-run-santo-andre-II','2026-' & chr(34) & 'corrida' & chr(34),'2026-corrida-' & chr(35) & '04','2026-rock' & chr(10) & '-run','tag & with space']) {
  for(testPrefix in ['/evento/','/en/event/','/es/evento/']) {
   testEncodedTag=replace(encodeForURL(testCanonicalTag),'+','%20','all');
   testBaseUrl='https://roadrunners.run' & testPrefix & lCase(testEncodedTag) & '/';
   check('Canonical preserves registered tag and language',structKeyExists(svc,'canonicalUrlFor') && svc.canonicalUrlFor(testBaseUrl,testCanonicalTag)=='https://roadrunners.run' & testPrefix & testEncodedTag & '/');
  }
 }
 check("Canonical event has no redirect",svc.resolveTarget("canonical-tag")=="");
 check("Existing valid redirect preserved",svc.resolveTarget("old-tag")=="canonical-tag");
 check("Unique case variation redirects to registered tag",svc.resolveTarget("live-ii")=="LIVE-II");
 check("Exact mixed-case tag has no redirect",svc.resolveTarget("LIVE-II")=="");
 check("Unknown event has no redirect",svc.resolveTarget("unknown")=="");
 check("Case collision never redirects",svc.resolveTarget("AmBiGuOuS")=="");
 check("Loop never redirects",svc.resolveTarget("loop-a")=="");
 check("POST never redirects",!svc.isReadRequest("POST",{tag="old-tag"}));
 check("Action request never redirects",!svc.isReadRequest("GET",{tag="old-tag",acao="inscricao"}));
 check("Trailing slash resolves consistently",svc.resolveTarget("live-ii/")=="LIVE-II");
 APPLICATION.nomeSite="Road Runners";VARIABLES.template="/evento/";
 for (testName in ['LIVE! RUN XP São Paulo 2026',repeatString('Etapa longa ',12),'Corrida ' & chr(34) & '<race>' & chr(34)]) {
  for (testDate in ['2026-03-08','2026-05-17']) {
   queryExecute("INSERT INTO tb_evento_corridas(ativo,nome_evento,data_inicial) VALUES(true,:name,:date)",{name={value=testName,cfsqltype="cf_sql_varchar"},date={value=testDate,cfsqltype="cf_sql_date"}},{datasource="runner_dba"});
  }
  for (testDate in ['2026-03-08','2026-05-17']) {
   qEvento=queryNew("nome_evento,data_inicial","varchar,date",[{nome_evento=testName,data_inicial=testDate}]);
   VARIABLES.title=testName & ' - corrida de rua - Road Runners';VARIABLES.eventTitleTypeLabel="corrida de rua";
   include "title.cfm";
   check("Repeated event includes its registered date",find(dateFormat(testDate,"dd/mm/yyyy"),VARIABLES.title) GT 0);
   arrayAppend(report.titles,{value=VARIABLES.title,name=testName,date=testDate});
  }
 }
 qEvento=queryNew("nome_evento,data_inicial","varchar,date",[{nome_evento="Nome único",data_inicial="2026-03-08"}]);
 VARIABLES.title="Nome único - Road Runners";include "title.cfm";
 check("Unique event title preserved",VARIABLES.title=="Nome único - Road Runners");
}
</cfscript>
<cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON(report)#</cfoutput>
