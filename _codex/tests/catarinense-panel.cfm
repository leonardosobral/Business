<!--- Render the real panel with synthetic athletes, without SQL/auth mutations. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfinclude template="#VARIABLES.catarinenseTestHelper#"/>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
VARIABLES.challengeTag='catarinensetrailrun'; VARIABLES.challengeCircuitTotalEvents=6; VARIABLES.challengeMedalCsrf='fixture-token';
VARIABLES.challengeCircuitMetrics={inscritos=120,comResultado=120,proximaEtapa=0,imediata=60,entregue=60,desempatesPendentes=0};
for(key in ['busca','genero','medalha','estado','cidade','regiao','periodo','preset']) if(!structKeyExists(URL,key)) URL[key]='';
rows=[];
for(i=1;i<=120;i++) {
    r={id=i,nome='Atleta ' & i & ' <Teste>',genero='FEMININO',nodesafio=5,distancia_percorrida=201-i,data_nascimento='1980-01-01',colocacoes_json='[1,2,3,4,5]',colocacoes_completas=1,ultima_colocacao=0,ultima_completa=1,media_percentual=i==1 ? '110.1234567890123456':(i==2 ? '110.1234567890123457':'110'),desempenho_completo=1,tag='',cidade='Cidade',estado='SC',imagem_usuario='/assets/user.png',medalha_status=i MOD 2 ? 'entregue':'imediata',medalha_entregue_em='',email='',ddi_usuario='',ddd_usuario='',telefone_usuario='',equipe=''};
    for(s=1;s<=6;s++) { r['pontos_' & s]=s<=5 ? 10:0; r['participou_' & s]=s<=5 ? 1:0; }
    arrayAppend(rows,r);
}
if(structKeyExists(URL,'birth_policy')) {
    rows=[rows[1],rows[2],rows[3]];
    rows[1].data_nascimento=''; rows[2].data_nascimento='1970-01-01'; rows[3].data_nascimento='1980-01-01';
    for(r in rows) { r.distancia_percorrida=100; for(s=1;s<=5;s++) r['pontos_' & s]=25; }
}
fixtureColumns=structKeyList(rows[1]); fixtureTypes=[];
for(key in listToArray(fixtureColumns)) arrayAppend(fixtureTypes,listFindNoCase('id,nodesafio,distancia_percorrida,colocacoes_completas,ultima_colocacao,ultima_completa,desempenho_completo',key) || reFindNoCase('^(pontos|participou)_',key) ? 'integer':'varchar');
qStatsBase=queryNew(fixtureColumns,arrayToList(fixtureTypes),rows); qStatsBase=catarinenseRank(qStatsBase);
qStatsBase=queryExecute('SELECT * FROM qStatsBase ORDER BY genero, ranking_ordem',{}, {dbtype='query'});
qBase=duplicate(qStatsBase);
qCatarinenseFemale=qStatsBase; qCatarinenseMale=queryNew(qStatsBase.columnList); qCatarinenseUninformed=queryNew(qStatsBase.columnList);
qStatsEstado=queryNew('estado','varchar',[{estado='SC'}]); qStatsCidade=queryNew('cidade,estado','varchar,varchar',[{cidade='Cidade',estado='SC'},{cidade='',estado='SC'}]);
qCatarinenseEvents=queryNew('event_order,percurso,event_tag,nome_evento,data_inicial','integer,integer,varchar,varchar,date');
for(i=1;i<=6;i++) queryAddRow(qCatarinenseEvents,{event_order=i,percurso=6,event_tag='fixture-' & i,nome_evento='Etapa ' & i,data_inicial=createDate(2026,i,1)});
if(structKeyExists(URL,'export')) {
    URL.desafio=VARIABLES.challengeTag;
    exportSource=fileRead(expandPath(VARIABLES.catarinenseTestExport));
    exportStart=find('<cfset VARIABLES.challengeExportSheet',exportSource);
    exportFinish=find('<cfheader name="Content-Disposition"',exportSource);
    exportScratch=getTempDirectory() & 'catarinense-export-' & lCase(replace(createUUID(),'-','','all'));
    directoryCreate(exportScratch);
    try {
        fileWrite(exportScratch & '/export.cfm',mid(exportSource,exportStart,exportFinish-exportStart));
        relativeExport=repeatString('../',listLen(getDirectoryFromPath(getCurrentTemplatePath()),'/')) & mid(exportScratch,2,len(exportScratch));
        savecontent variable='ignoredExport' { include relativeExport & '/export.cfm'; }
        if(structKeyExists(URL,'birth_policy')) {
            check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,1)==2 && spreadsheetGetCellValue(VARIABLES.challengeExportSheet,3,1)==3 && spreadsheetGetCellValue(VARIABLES.challengeExportSheet,4,1)==1,'export puts missing birth after valid births within a point tie');
            check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,19) & ''=='1' && spreadsheetGetCellValue(VARIABLES.challengeExportSheet,3,19) & ''=='2' && spreadsheetGetCellValue(VARIABLES.challengeExportSheet,4,19) & ''=='3','export contains resolved positions instead of a shared birth-pending interval');
            check(!len(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,21)) && !len(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,3,21)),'export does not claim birth-data dependency for valid peers');
            check(findNoCase('após',spreadsheetGetCellValue(VARIABLES.challengeExportSheet,4,21))>0 && !len(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,4,22)),'export explains birth-last without inventing a missing birth date');
            check(isBinary(VARIABLES.challengeExportBinary),'birth-last export is a real XLSX payload');
        } else {
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,1)==1 && spreadsheetGetCellValue(VARIABLES.challengeExportSheet,121,1)==120,'export includes every filtered athlete, not only the current page');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,1,19)=='Posição geral','export explains the global position column');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,52,19)=='51','export preserves global position from the displayed ranking');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,20)=='Pontuação','export includes the deciding criterion');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,22)=='1980-01-01','export includes normalized birth date');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,2,25) & ''=='110.1234567890123456','export preserves exact mean, without display rounding');
        check(spreadsheetGetCellValue(VARIABLES.challengeExportSheet,3,25) & ''=='110.1234567890123457','export preserves the distinction between close decimal means');
        check(VARIABLES.challengeExportSheet.getWorkbook().getSheetAt(0).getRow(1).getCell(24).getCellType() & ''=='STRING','precise performance mean is an Excel text cell, not a rounded numeric double');
        check(isBinary(VARIABLES.challengeExportBinary),'real spreadsheet engine produces an XLSX payload');
        }
    } finally { directoryDelete(exportScratch,true); }
    cfcontent(type='application/json; charset=utf-8',reset=true); writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
    abort;
}
savecontent variable='panelHtml' { include VARIABLES.catarinenseTestPanel; }
if(structKeyExists(URL,'preview')) { cfcontent(type='text/html; charset=utf-8',reset=true); writeOutput('<!doctype html><html lang="pt-BR"><head><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="https://business.roadrunners.run/assets/css/mdb.min.css"></head><body data-mdb-theme="dark" style="background:##222;padding:16px">' & panelHtml & '</body></html>'); }
else {
    if(!structKeyExists(URL,'aba') || URL.aba=='ranking') {
        check(arrayLen(reMatch('data-catarinense-athlete="[0-9]+"',panelHtml))==50,'ranking loads only fifty rows per page');
        if(structKeyExists(URL,'pagina') && URL.pagina==2) {
            check(find('data-catarinense-athlete="51"',panelHtml)>0 && !find('data-catarinense-athlete="1"',panelHtml),'second page starts at athlete 51 without duplicating page one');
            check(find('51–100 de 120',panelHtml)>0,'pagination communicates the filtered range');
        }
        check(!find('Atleta 51 <Teste>',panelHtml),'athlete text is HTML escaped');
    } else if(URL.aba=='medalhas') {
        check(find('name="challenge_action"',panelHtml)>0 && find('value="entregar_medalha"',panelHtml)>0,'medal view retains guarded delivery workflow');
        check(!find('class="stage-score"',panelHtml),'medal workflow avoids wide score columns');
    } else if(URL.aba=='regras') check(!find('data-catarinense-athlete=',panelHtml),'rules view does not render the athlete table');
    else if(URL.aba=='etapas') check(!find('data-catarinense-athlete=',panelHtml),'stages view does not render the athlete table');
    check(find('aria-current="page"',panelHtml)>0,'active tab has a keyboard-accessible current-page indication');
    check(!find('>/SC</option>',panelHtml),'blank athlete city cannot override the default all-cities filter');
    check(find('busca=',decodeForHTML(panelHtml))>0 && find('estado=SC',decodeForHTML(panelHtml))>0,'tab and pagination links keep current filters');
    cfcontent(type='application/json; charset=utf-8',reset=true); writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
}
</cfscript>
