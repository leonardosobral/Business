<!--- Render the real Brasil Gigante table with synthetic athletes only. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
rows=[]; VARIABLES.challengeCircuitEvents=[];
for(s=1;s<=8;s++) arrayAppend(VARIABLES.challengeCircuitEvents,{ordem=s,nome='Etapa ' & s,sigla='E' & s});
VARIABLES.challengeCircuitTotalEvents=8; VARIABLES.challengeMedalCsrf='fixture-token';
for(i=1;i<=2;i++) {
    row={id=i,nome=i==1 ? 'Ana <Atleta> & "Teste"':'Atleta sem contatos',nodesafio=i==1 ? 8:2,tag=i==1 ? 'ana atleta':'',cidade='Florianópolis',estado='SC',equipe='Equipe A',imagem_usuario='/assets/user.png',mandala_status=i==1 ? 'imediata':'progresso',mandala_entregue_em='',email=i==1 ? 'ana+equipe@example.com':'',ddi_usuario='55',ddd_usuario='48',telefone_usuario=i==1 ? '999991234':'',instagram=i==1 ? '@ana.atleta':'',whatsapp=i==1 ? 'https://wa.me/5548999991234':'',strava_code='not-a-contact-field'};
    for(s=1;s<=8;s++) { row['participou_' & s]=s<=row.nodesafio ? 1:0; row['ano_' & s]=s<=row.nodesafio ? 2026:0; }
    arrayAppend(rows,row);
}
for(scenario in ['contacts','missing-columns','empty']) {
    fixture=duplicate(rows);
    if(scenario=='missing-columns') for(row in fixture) for(key in ['email','ddi_usuario','ddd_usuario','telefone_usuario','instagram','whatsapp','equipe']) structDelete(row,key);
    columns=structKeyList(fixture[1]); types=[];
    for(key in listToArray(columns)) arrayAppend(types,listFindNoCase('id,nodesafio',key) || reFindNoCase('^(ano|participou)_',key) ? 'integer':'varchar');
    qBrasilGiganteRanking=queryNew(columns,arrayToList(types),scenario=='empty' ? []:fixture);
    savecontent variable='html' { include VARIABLES.brasilGiganteTestTable; }
    buttons=reMatch('<button[^>]*data-catarinense-contact="[^"]*"[^>]*>',html);
    if(scenario=='empty') {
        check(!arrayLen(buttons),'empty: no contact buttons for absent athletes');
        check(!find('<dialog',html),'empty: no unused dialog');
        check(find('Nenhum atleta encontrado',html)>0,'empty: existing empty state remains available');
        continue;
    }
    check(arrayLen(buttons)==2,scenario & ': one discrete contact button per participant');
    check(arrayLen(reMatch('<dialog[^>]*id="catarinenseContactDialog"',html))==1,scenario & ': a single shared contact dialog');
    check(find('value="entregar_mandala"',html)>0,scenario & ': existing mandala operation remains available');
    check(find('8/8',html)>0 && find('2/8',html)>0,scenario & ': completion counts remain unchanged');
    check(!find('<Atleta>',html),scenario & ': athlete name is safely escaped');
    if(arrayLen(buttons)==2) {
        payload=deserializeJSON(decodeForHTML(reReplace(buttons[1],'^.*data-catarinense-contact="([^"]*)".*$','\1')));
        check(payload.id==1 && payload.nome=='Ana <Atleta> & "Teste"',scenario & ': identity round trips without HTML injection');
        check(!structKeyExists(payload,'strava_code') && !structKeyExists(payload,'mandala_status'),scenario & ': payload contains only contact fields');
        if(scenario=='contacts') check(payload.email=='ana+equipe@example.com' && payload.instagram=='@ana.atleta' && payload.whatsapp=='https://wa.me/5548999991234',scenario & ': contact details reach the dialog');
        else check(!len(payload.email) && !len(payload.telefone_usuario) && !len(payload.whatsapp),scenario & ': missing columns produce empty contact values');
        payload=deserializeJSON(decodeForHTML(reReplace(buttons[2],'^.*data-catarinense-contact="([^"]*)".*$','\1')));
        check(payload.id==2 && !len(payload.email) && !len(payload.instagram),scenario & ': another athlete never inherits contact values');
    }
}
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
