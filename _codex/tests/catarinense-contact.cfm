<!--- Render the real athlete table with synthetic data only. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
rows=[];
for(i=1;i<=2;i++) {
    row={id=i,nome=i==1 ? 'Ana <Atleta> & "Teste"':'Atleta sem contatos',genero='FEMININO',nodesafio=5,distancia_percorrida=100,ranking_posicao=i,ranking_fim=i,ranking_criterio='pontos',ranking_motivo='',ranking_nascimento='1980-01-01',colocacoes_json='[1,2,3,4,5]',colocacoes_completas=1,ultima_colocacao=1,ultima_completa=1,media_percentual='110',desempenho_completo=1,tag=i==1 ? 'ana atleta':'',cidade='Florianópolis',estado='SC',equipe='Equipe A',imagem_usuario='/assets/user.png',medalha_status='imediata',medalha_entregue_em='',email=i==1 ? 'ana+equipe@example.com':'',ddi_usuario='55',ddd_usuario='48',telefone_usuario=i==1 ? '999991234':'',instagram=i==1 ? '@ana.atleta':'',whatsapp=i==1 ? 'https://wa.me/5548999991234':''};
    for(s=1;s<=6;s++) { row['pontos_' & s]=s<=5 ? 25:0; row['participou_' & s]=s<=5 ? 1:0; }
    arrayAppend(rows,row);
}
columns=structKeyList(rows[1]); types=[];
for(key in listToArray(columns)) arrayAppend(types,listFindNoCase('id,nodesafio,distancia_percorrida,ranking_posicao,ranking_fim,colocacoes_completas,ultima_colocacao,ultima_completa,desempenho_completo',key) || reFindNoCase('^(pontos|participou)_',key) ? 'integer':'varchar');
qCatarinenseRanking=queryNew(columns,arrayToList(types),rows);
VARIABLES.challengeCircuitTotalEvents=6; VARIABLES.challengeMedalCsrf='fixture-token';
VARIABLES.catarinenseStartRow=1; VARIABLES.catarinensePageSize=50; VARIABLES.catarinenseEndRow=2; VARIABLES.catarinensePageCount=1;
for(circuit in ['catarinensecorridaderua','catarinensetrailrun']) {
    for(tab in ['ranking','medalhas']) {
        VARIABLES.challengeTag=circuit; VARIABLES.catarinenseRankingTitle='Atletas'; VARIABLES.catarinenseRankingIcon='fa-ranking-star';
        structAppend(URL,{aba=tab,genero='feminino',pagina=1,busca='',medalha='',estado='',cidade='',regiao='',periodo='',preset=''},true);
        savecontent variable='html' { include VARIABLES.catarinenseTestTable; }
        label=circuit & ' ' & tab;
        buttons=reMatch('<button[^>]*data-catarinense-contact="[^"]*"[^>]*>',html);
        check(arrayLen(buttons)==2,label & ': one discrete contact button per athlete');
        check(arrayLen(reMatch('<dialog[^>]*id="catarinenseContactDialog"',html))==1,label & ': a single reusable dialog per page');
        if(arrayLen(buttons)==2) {
            payload=deserializeJSON(decodeForHTML(reReplace(buttons[1],'^.*data-catarinense-contact="([^"]*)".*$','\1')));
            check(payload.id==1 && payload.nome=='Ana <Atleta> & "Teste"',label & ': identity safely round trips through the button');
            check(payload.email=='ana+equipe@example.com' && payload.instagram=='@ana.atleta' && payload.whatsapp=='https://wa.me/5548999991234',label & ': real profile contacts reach the dialog');
            check(!structKeyExists(payload,'strava_code') && !structKeyExists(payload,'status_transacao'),label & ': unrelated private fields are not embedded');
            payload=deserializeJSON(decodeForHTML(reReplace(buttons[2],'^.*data-catarinense-contact="([^"]*)".*$','\1')));
            check(!len(payload.email) && !len(payload.telefone_usuario) && !len(payload.instagram),label & ': missing contacts remain empty');
        }
        check(!find('<Atleta>',html),label & ': athlete text is HTML escaped');
        if(tab=='medalhas') check(find('value="entregar_medalha"',html)>0,label & ': contact does not replace medal operations');
    }
}
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
