<!--- Synthetic render regression: no Business bootstrap, database or persistent writes. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfinclude template="#VARIABLES.catarinenseTestHelper#"/>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) {
    checks++; if(!arguments.condition) arrayAppend(failures,arguments.label);
}
rows=[];
for(i=1;i<=56;i++) {
    row={id=i,nome='Atleta ' & i & ' <Teste> & "nome"',genero=i==1 ? 'FEMININO':(i==2 ? 'NAO INFORMADO':'MASCULINO'),nodesafio=5,distancia_percorrida=100,data_nascimento='1980-01-01',colocacoes_json='[1,2,3,4,5]',colocacoes_completas=i==3 ? 0:1,ultima_colocacao=1,ultima_completa=1,media_percentual='110',desempenho_completo=1,tag='',cidade='Cidade <Teste>',estado='SC',imagem_usuario='/assets/user.png',medalha_status='imediata',medalha_entregue_em=''};
    for(s=1;s<=6;s++) { row['pontos_' & s]=s<=5 ? 25:0; row['participou_' & s]=s<=5 ? 1:0; }
    arrayAppend(rows,row);
}
columns=structKeyList(rows[1]); types=[];
for(key in listToArray(columns)) arrayAppend(types,listFindNoCase('id,nodesafio,distancia_percorrida,colocacoes_completas,ultima_colocacao,ultima_completa,desempenho_completo',key) || reFindNoCase('^(pontos|participou)_',key) ? 'integer':'varchar');
fixture=catarinenseRank(queryNew(columns,arrayToList(types),rows));
VARIABLES.challengeCircuitTotalEvents=6; VARIABLES.challengeMedalCsrf='fixture-token';
VARIABLES.challengeCircuitMetrics={inscritos=56,comResultado=56,proximaEtapa=0,imediata=56,entregue=0,desempatesPendentes=54};
qStatsEstado=queryNew('estado','varchar',[{estado='SC'}]);
qStatsCidade=queryNew('cidade,estado','varchar,varchar',[{cidade='Cidade <Teste>',estado='SC'}]);
qCatarinenseEvents=queryNew('event_order,percurso,event_tag,nome_evento,data_inicial','integer,integer,varchar,varchar,date',[{event_order=1,percurso=6,event_tag='timbo',nome_evento='Etapa <Teste>',data_inicial=createDate(2026,3,1)}]);
for(circuit in ['catarinensecorridaderua','catarinensetrailrun']) {
    for(view in [{aba='ranking',genero='masculino',pagina=1},{aba='ranking',genero='masculino',pagina=2},{aba='ranking',genero='feminino',pagina=1},{aba='ranking',genero='nao_informado',pagina=1},{aba='medalhas',genero='',pagina=1},{aba='etapas',genero='',pagina=1},{aba='regras',genero='',pagina=1}]) {
        label=circuit & ' ' & view.aba & ' ' & view.genero & ' page ' & view.pagina;
        VARIABLES.challengeTag=circuit; qStatsBase=duplicate(fixture); qBase=duplicate(fixture);
        structAppend(URL,{aba=view.aba,genero=view.genero,pagina=view.pagina,busca='Teste " & < >',medalha='',estado='SC',cidade='',regiao='Regiao " < >',periodo='',preset=''},true);
        try {
            savecontent variable='html' { include VARIABLES.catarinenseTestPanel; }
            check(find('catarinense-dashboard',html)>0,label & ': real panel renders');
            links=reMatch('<a[^>]*href="[^"]*"[^>]*>',html); switchLink='';
            for(link in links) if(find('btn-outline-light',link)) switchLink=link;
            href=reReplace(switchLink,'^.*href="([^"]*)".*$','\1');
            check(urlDecode(decodeForHTML(href))==('/desafios/' & (circuit=='catarinensetrailrun' ? 'catarinensecorridaderua':'catarinensetrailrun') & '/?aba=' & view.aba & (len(view.genero) ? '&genero=' & view.genero:'')),label & ': circuit switch retains tab and gender');
            check(!find('value="Regiao "',html),label & ': quotes cannot break a hidden filter attribute');
            if(listFind('ranking,medalhas',view.aba)) {
                check(!find('<Teste>',html),label & ': athlete and city values are escaped text');
                values=reMatch('<input[^>]*name="busca"[^>]*>',html);
                searchValue=arrayLen(values) ? reReplace(values[1],'^.*value="([^"]*)".*$','\1'):'';
                check(decodeForHTML(searchValue)=='Teste " & < >',label & ': search filter round trips through an attribute');
                if(view.aba=='ranking') check(arrayLen(reMatch('data-catarinense-athlete="[0-9]+"',html))==(view.genero=='masculino' ? (view.pagina==2 ? 4:50):1),label & ': pagination and gender filtering remain intact');
                else check(find('value="entregar_medalha"',html)>0,label & ': medal actions remain available');
            }
        } catch(any error) { check(false,label & ': render failed: ' & error.message); }
    }
}
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
