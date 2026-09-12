<!--- Offline rendering only: no application bootstrap, datasource or network. --->
<cfscript>
testEnv=createObject("java","java.lang.System").getenv();
if (!testEnv.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || testEnv.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
REQUEST.t=function(key){return key;};
testOutputDir=getDirectoryFromPath(getCurrentTemplatePath());
checks=0;
function check(required boolean ok,required string label){
    if (!arguments.ok) throw(type="CircuitHighlightTestFailure",message=arguments.label);
    VARIABLES.checks++;
}
fixtureRows=[];
for (r in [
    {id=1,tag="sao-paulo",city="São Paulo",uf="SP",days=1,status=""},
    {id=5,tag="campinas-cancelada",city="Campinas",uf="SP",days=2,status="cancelado"},
    {id=3,tag="jaragua",city="Jaraguá do Sul",uf="SC",days=3,status=""},
    {id=6,tag="campinas-mg",city="Campinas",uf="MG",days=4,status=""},
    {id=2,tag="campinas",city="Campinas",uf="SP",days=5,status=""},
    {id=4,tag="sao-caetano",city="São Caetano do Sul",uf="SP",days=7,status=""}
]){
    arrayAppend(fixtureRows,{id_evento=r.id,tag=r.tag,data_inicial=dateAdd("d",r.days,now()),data_final=dateAdd("d",r.days,now()),
        nome_evento="LIVE! " & r.city,cidade=r.city,estado=r.uf,cupom="15%",status_evento=r.status,tipo_corrida="rua",categorias="5,10",badges="[]"});
}
baseEvents=queryNew("id_evento,tag,data_inicial,data_final,nome_evento,cidade,estado,cupom,status_evento,tipo_corrida,categorias,badges",
    "integer,varchar,timestamp,timestamp,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar",fixtureRows);
function renderCase(required string name,required struct geo,required string first,required numeric highlight,string circuit="live-run-xp"){
    REQUEST.LocationContext=arguments.geo;
    structDelete(REQUEST,"liveEventCardCssLoaded");
    VARIABLES.qAgrega=queryNew("tag","varchar",[{tag=arguments.circuit}]);
    VARIABLES.qEventosAba=duplicate(VARIABLES.baseEvents);
    var before=serializeJSON(VARIABLES.qEventosAba);
    savecontent variable="local.html" { include "circuito/live_highlight.cfm"; }
    var links=reMatch('href="/evento/[^" ]+/"',html);
    check(arrayLen(links)==6,arguments.name & ": every event remains visible exactly once");
    check(links[1]=='href="/evento/' & arguments.first & '/"',arguments.name & ": correct first event");
    for(var eventTag in ["sao-paulo","campinas-cancelada","jaragua","campinas-mg","campinas","sao-caetano"]){
        check(arrayLen(reMatch('href="/evento/' & eventTag & '/"',html))==1,arguments.name & ": unique " & eventTag);
    }
    check(serializeJSON(VARIABLES.qEventosAba)==before,arguments.name & ": cached query is not mutated");
    check(arrayLen(reMatch('data-highlighted-event=',html))==(arguments.highlight ? 1 : 0),arguments.name & ": expected emphasis count");
    if(arguments.highlight) check(find('data-highlighted-event="' & arguments.highlight & '"',html)>0,arguments.name & ": highlight identity");
    var remaining=links;
    if(arguments.highlight) arrayDeleteAt(remaining,1);
    var expected=[];
    for(var row in VARIABLES.baseEvents){if(row.id_evento!=arguments.highlight) arrayAppend(expected,'href="/evento/' & row.tag & '/"');}
    check(arrayToList(remaining)==arrayToList(expected),arguments.name & ": other events retain their order");
    check(!findNoCase('<select',html) && !findNoCase('window.location',html),arguments.name & ": no city filter or redirect");
    fileWrite(VARIABLES.testOutputDir & arguments.name & '.html','<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><body><main style="max-width:680px;margin:24px auto;padding:12px">' & html & '</main></body></html>','UTF-8');
}
renderCase("city",{pais="BR",uf="SP",cidade="Campinas",isFallback=false},"campinas",2);
renderCase("accent",{pais="BR",uf="SP",cidade="  SAO-CAETANO DO SUL  ",isFallback=false},"sao-caetano",4);
renderCase("state",{pais="BR",uf="SC",cidade="Blumenau",isFallback=false},"jaragua",3);
renderCase("homonym",{pais="BR",uf="MG",cidade="Campinas",isFallback=false},"campinas-mg",6);
renderCase("unknown",{},"sao-paulo",0);
renderCase("foreign",{pais="US",uf="SP",cidade="Campinas",isFallback=false},"sao-paulo",0);
renderCase("fallback",{pais="BR",uf="SP",cidade="Campinas",isFallback=true},"sao-paulo",0);
renderCase("invalid",{pais="BR",uf=[],cidade=[],isFallback="unknown"},"sao-paulo",0);
renderCase("other",{pais="BR",uf="SP",cidade="Campinas",isFallback=false},"sao-paulo",0,"outro-circuito");
VARIABLES.qEventosAba=queryNew(VARIABLES.baseEvents.columnList);
savecontent variable="emptyHtml" { include "circuito/live_highlight.cfm"; }
check(!find('data-highlighted-event=',emptyHtml) && !find('href="/evento/',emptyHtml),"empty upcoming list remains empty");
writeOutput("PASS: circuit highlight, " & checks & " rendering assertions; original list complete and immutable.");
</cfscript>
