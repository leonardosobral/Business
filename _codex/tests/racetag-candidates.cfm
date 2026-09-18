<cfscript>
// Execute the actual candidate selection and view against the isolated test DB.
// Only remote HTTP/source discovery and result writes are outside this test.
candidateSource=fileRead(testRoot & 'racetag/form.cfm');
fileWrite(testRoot & 'racetag-functions.cfm',left(candidateSource,find('</cfscript>',candidateSource)+10));
candidateStart=find('<cfif VARIABLES.raceTagAnalyzed>',candidateSource);
candidateEnd=find('<cfif NOT VARIABLES.raceTagStandaloneAllowed',candidateSource,candidateStart);
candidateInitStart=find('<cfset qRaceTagCandidates',candidateSource);
candidateInitEnd=find('<cfif len(trim(FORM.url_resultado))',candidateSource,candidateInitStart);
fileWrite(testRoot & 'racetag-selection.cfm',mid(candidateSource,candidateInitStart,candidateInitEnd-candidateInitStart) & mid(candidateSource,candidateStart,candidateEnd-candidateStart));
viewStart=find('<label for="inputRoadRunnersEvent"',candidateSource);
viewEnd=find('</div>',candidateSource,viewStart)+6;
fileWrite(testRoot & 'racetag-selection-view.cfm',mid(candidateSource,viewStart,viewEnd-viewStart));
include 'racetag-functions.cfm';
transaction {
    queryExecute('CREATE EXTENSION IF NOT EXISTS unaccent');
    queryExecute('ALTER TABLE tb_evento_corridas ADD COLUMN data_final date');
    queryExecute("INSERT INTO tb_evento_corridas(id_evento,nome_evento,cidade,estado,data_inicial,data_final,ativo) VALUES
        (101,'Dia anterior','BANANEIRAS','PB','2026-09-11','2026-09-11',true),
        (102,'Mesmo dia','PATOS','PB','2026-09-12','2026-09-12',true),
        (103,'Dia posterior','BANANEIRAS','PB','2026-09-13','2026-09-13',true),
        (104,'Muito cedo','BANANEIRAS','PB','2026-09-10','2026-09-10',true),
        (105,'Muito tarde','BANANEIRAS','PB','2026-09-14','2026-09-14',true),
        (106,'Outra UF','BANANEIRAS','PE','2026-09-12','2026-09-12',true),
        (107,'Inativo','BANANEIRAS','PB','2026-09-12','2026-09-12',false),
        (108,'Varios dias','BANANEIRAS','PB','2026-09-09','2026-09-11',true),
        (109,'Fora da janela','BANANEIRAS','PB','2026-09-15','2026-09-15',true),
        (110,'Virada de ano','BANANEIRAS','PB','2025-12-31','2025-12-31',true)");
    raceTagAnalyzed=true;
    FORM.id_evento='';
    evento={startDate='2026-09-12',endDate='2026-09-12',place='BANANEIRAS-PB'};
    include 'racetag-selection.cfm';
    check(listSort(valueList(qRaceTagCandidates.id_evento),'numeric') EQ '101,102,103,108',
        'Candidates must include previous/same/next day and overlapping multi-day events, but exclude outside dates, foreign UF and inactive events. Got: ' & valueList(qRaceTagCandidates.id_evento));
    check(qRaceTagCandidates.id_evento[1] EQ 103 AND qRaceTagCandidates.id_evento[4] EQ 102,'Exact city priority is preserved');
    check(!raceTagCanProcess,'More candidate dates do not automatically select or process an event');
    savecontent variable='candidateView' { include 'racetag-selection-view.cfm'; }
    check(find('value="101"',candidateView)>0 AND find('11/09/2026',candidateView)>0,'Previous-day event is visible in the real selector');
    fileWrite(testRoot & 'racetag-candidates.html','<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid p-4">' & candidateView & '</main></body></html>');
    evento.endDate='2026-09-13';
    include 'racetag-selection.cfm';
    check(listSort(valueList(qRaceTagCandidates.id_evento),'numeric') EQ '101,102,103,105,108','Multi-day source keeps its full interval plus one day on either side');
    structDelete(evento,'endDate');
    include 'racetag-selection.cfm';
    check(listSort(valueList(qRaceTagCandidates.id_evento),'numeric') EQ '101,102,103,108','Missing end date uses the start date');
    FORM.id_evento='109';
    include 'racetag-selection.cfm';
    check(listFind(valueList(qRaceTagCandidates.id_evento),'109') AND raceTagCanProcess,'Explicit existing linkage outside the window remains available');
    FORM.id_evento='107';
    include 'racetag-selection.cfm';
    check(!listFind(valueList(qRaceTagCandidates.id_evento),'107') AND !raceTagCanProcess,'Explicit inactive event remains denied');
    FORM.id_evento='';evento={startDate='2026-01-01',place='BANANEIRAS-PB'};
    include 'racetag-selection.cfm';
    check(valueList(qRaceTagCandidates.id_evento) EQ '110','Previous day crosses month and year boundaries');
    evento={startDate='invalid',place='BANANEIRAS-PB'};
    qRaceTagCandidates=queryNew('id_evento');
    include 'racetag-selection.cfm';
    check(qRaceTagCandidates.recordcount EQ 0,'Invalid date without an explicit linkage cannot broaden the search');
    transaction action='rollback';
}
writeOutput('PASS: RaceTag candidate date window, boundaries, multi-day overlap, UF, active status, explicit selection and rendered option. ');
</cfscript>
