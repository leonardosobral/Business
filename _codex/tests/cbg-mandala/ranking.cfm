<cfscript>
URL.desafio='circuitobrasilgigante';URL.periodo='';URL.preset='';URL.busca='';URL.regiao='';URL.estado='';URL.cidade='';URL.genero='';URL.medalha='';URL.mandala='';URL.challenge_refresh='';
include '../desafios/includes/backend.cfm';
if(!listFindNoCase(qBrasilGiganteRanking.columnList,'mandala_numero'))throw(message='Ranking sem coluna número');
writeOutput('CBG_MANDALA_RANKING_PASSED rows='&qBrasilGiganteRanking.recordCount);
</cfscript>
