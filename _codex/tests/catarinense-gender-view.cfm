<!--- Native rendering test: mixed genders and deliberately unsorted input. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfinclude template="#VARIABLES.catarinenseTestHelper#"/>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
function athlete(required numeric id,required string name,required string gender,struct overrides={}) {
    var r={id=arguments.id,nome=arguments.name,genero=arguments.gender,nodesafio=2,distancia_percorrida=100,data_nascimento='1980-01-01',colocacoes_json='[1,2]',colocacoes_completas=1,ultima_colocacao=0,ultima_completa=1,media_percentual='110',desempenho_completo=1,tag='',cidade='Cidade',estado='SC',imagem_usuario='/assets/user.png',medalha_status='progresso',medalha_entregue_em=''};
    for(var s=1;s<=6;s++) { r['pontos_' & s]=s<=2 ? 50:0; r['participou_' & s]=s<=2 ? 1:0; }
    structAppend(r,arguments.overrides,true); return r;
}
function genderLink(required string html,required string gender) {
    var tags=reMatch('<a[^>]*data-catarinense-gender="' & arguments.gender & '"[^>]*>',arguments.html);
    return arrayLen(tags) ? decodeForHTML(tags[1]) : '';
}
for(key in ['busca','genero','medalha','estado','cidade','regiao','periodo','preset']) if(!structKeyExists(URL,key)) URL[key]='';
requestedGender=lCase(URL.genero); requestedPage=structKeyExists(URL,'pagina') ? val(URL.pagina):1;
rows=[athlete(1,'Ana','FEMININO'),athlete(2,'Zelia','FEMININO',{data_nascimento='1970-01-01'}),
    athlete(3,'Andre','MASCULINO'),athlete(4,'Zeno','MASCULINO',{colocacoes_json='[1,1]'}),
    athlete(5,'Bia','FEMININO',{distancia_percorrida=90,data_nascimento=''}),athlete(6,'Carla','FEMININO',{distancia_percorrida=90}),
    athlete(7,'Sem genero','NAO INFORMADO',{distancia_percorrida=50}),athlete(8,'Sem resultado','FEMININO',{nodesafio=0,distancia_percorrida=0})];
for(i=100;i<=169;i++) arrayAppend(rows,athlete(i,'Atleta ' & i,'MASCULINO',{distancia_percorrida=180-i}));
columns=structKeyList(rows[1]); types=[];
for(key in listToArray(columns)) arrayAppend(types,listFindNoCase('id,nodesafio,distancia_percorrida,colocacoes_completas,ultima_colocacao,ultima_completa,desempenho_completo',key) || reFindNoCase('^(pontos|participou)_',key) ? 'integer':'varchar');
if(structKeyExists(URL,'empty')) rows=[];
qStatsBase=queryNew(columns,arrayToList(types),rows); qStatsBase=catarinenseRank(qStatsBase); qBase=duplicate(qStatsBase);
VARIABLES.challengeTag='catarinensetrailrun'; VARIABLES.challengeCircuitTotalEvents=6; VARIABLES.challengeMedalCsrf='fixture-token';
VARIABLES.challengeCircuitMetrics={inscritos=qBase.recordCount,comResultado=max(0,qBase.recordCount-1),proximaEtapa=0,imediata=0,entregue=0,desempatesPendentes=2};
qStatsEstado=queryNew('estado','varchar',[{estado='SC'}]); qStatsCidade=queryNew('cidade,estado','varchar,varchar',[{cidade='Cidade',estado='SC'}]);
qCatarinenseEvents=queryNew('event_order,percurso,event_tag,nome_evento,data_inicial','integer,integer,varchar,varchar,date');
savecontent variable='html' { include VARIABLES.catarinenseTestPanel; }
ids=[];
for(tag in reMatch('data-catarinense-athlete="[0-9]+"',html)) arrayAppend(ids,val(reReplace(tag,'[^0-9]','','all')));
female=genderLink(html,'feminino'); male=genderLink(html,'masculino'); unknown=genderLink(html,'nao_informado');
if(URL.aba=='ranking') {
    check(len(female)>0 && len(male)>0,'ranking exposes separate female and male selectors');
    check(!find('id="catarinense-genero"',html),'ranking replaces the redundant gender dropdown');
    if(structKeyExists(URL,'empty')) {
        check(!arrayLen(ids),'empty ranking has no athlete rows');
        check(find('aria-current="page"',female)>0,'empty circuit retains a usable selected gender');
    } else if(requestedGender=='masculino') {
        check(find('aria-current="page"',male)>0,'male selector identifies the current ranking');
        check(arrayLen(ids)==(requestedPage==2 ? 22:50),'male pagination applies after gender selection');
        if(requestedPage==2) check(arrayLen(ids)>0 && ids[1]==148,'second male page continues the final ranking, not a mixed-gender offset');
        else check(arrayLen(ids)>1 && ids[1]==4 && ids[2]==3,'male ranking is displayed in post-placement-tiebreak order');
        check(!arrayFind(ids,1) && !arrayFind(ids,2) && !arrayFind(ids,7),'male view excludes female and unspecified athletes');
        check(find('Ranking masculino',html)>0,'table heading identifies the male ranking');
    } else if(requestedGender=='nao_informado') {
        check(arrayLen(ids)==1 && ids[1]==7,'unspecified athletes remain accessible without mixing official rankings');
        check(find('aria-current="page"',unknown)>0,'unspecified view has an active selector');
    } else {
        check(arrayLen(ids)==5,'default or invalid gender opens only the female ranking');
        check(arrayLen(ids)>1 && ids[1]==2 && ids[2]==1,'female ranking is displayed in post-age-tiebreak order');
        check(!arrayFind(ids,3) && !arrayFind(ids,4) && !arrayFind(ids,7),'default view never mixes genders');
        check(find('aria-current="page"',female)>0,'female selector identifies the current ranking');
        check(find('Ranking feminino',html)>0,'table heading identifies the female ranking');
        check(!find('3–4',html),'missing birth no longer creates a provisional interval for the valid-birth peer');
        knownPeerRows=reMatch('<tr[^>]*data-catarinense-athlete="6"[^>]*>[\s\S]*?</tr>',html);
        check(arrayLen(knownPeerRows)==1 && find('01/01/1980',knownPeerRows[1])>0 && !findNoCase('outro atleta',knownPeerRows[1]) && reFind('<td[^>]*>\s*3\s*</td>',knownPeerRows[1])>0,'rendered valid-birth athlete shows its resolved third place without peer-birth warning');
        missingPeerRows=reMatch('<tr[^>]*data-catarinense-athlete="5"[^>]*>[\s\S]*?</tr>',html);
        check(arrayLen(missingPeerRows)==1 && find('Não informado ou inválido',missingPeerRows[1])>0 && findNoCase('após',decodeForHTML(missingPeerRows[1]))>0 && reFind('<td[^>]*>\s*4\s*</td>',missingPeerRows[1])>0,'rendered missing-birth athlete shows fourth place and explains the birth-last rule');
    }
    if(!structKeyExists(URL,'empty')) {
        selectorCounts={feminino=5,masculino=72,nao_informado=1}; selectorCountsMatch=true;
        for(selectorGender in selectorCounts) {
            selectorAnchors=reMatch('<a[^>]*data-catarinense-gender="' & lCase(selectorGender) & '"[^>]*>[\s\S]*?</a>',html);
            if(!arrayLen(selectorAnchors) || !reFind('class="catarinense-gender-count">\s*' & selectorCounts[selectorGender] & '\s*</span>',selectorAnchors[1])) selectorCountsMatch=false;
        }
        check(selectorCountsMatch,'gender selector counts include all circuit participants: female 5, male 72, unspecified 1');
        pendingWarning=find('atleta(s) neste ranking com desempate pendente',html);
        check(!pendingWarning,'birth-last rule does not create a false pending-tie warning');
        check(find('data-catarinense-gender="nao_informado"',html)>0,'unspecified participant records are not hidden');
        check(find('genero=feminino',female)>0 && find('genero=masculino',male)>0,'gender links choose the intended ranking');
        check(find('pagina=1',female)>0 && find('pagina=1',male)>0,'switching gender starts at the first position');
        check(find('estado=SC',male)>0,'switching gender preserves geographic filters');
        exportTags=reMatch('<a[^>]*href="[^"]*exportar_catarinense.cfm[^"]*"[^>]*>',html);
        expectedGender=requestedGender=='masculino' ? 'masculino':(requestedGender=='nao_informado' ? 'nao_informado':'feminino');
        check(arrayLen(exportTags)>0 && find('genero=' & expectedGender,urlDecode(decodeForHTML(exportTags[1])))>0,'export retains the selected gender');
    }
} else if(URL.aba=='medalhas') {
    check(find('id="catarinense-genero"',html)>0,'medal workflow retains the all-genders filter');
    check(!len(female) && !len(male),'ranking-only gender selector does not alter medal management');
    check(arrayFind(ids,1)>0 && arrayFind(ids,3)>0,'unfiltered medal view still contains both genders');
}
cfcontent(type='application/json; charset=utf-8',reset=true); writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
