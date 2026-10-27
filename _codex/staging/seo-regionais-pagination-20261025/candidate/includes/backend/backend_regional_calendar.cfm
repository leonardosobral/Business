<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
// Regional-only pagination. Home/search retain their existing data contracts.
VARIABLES.regionalBadRequest = function(required string message) {
    cfheader(statuscode=400);cfheader(name="X-Robots-Tag",value="noindex");
    cfcontent(type="text/html; charset=utf-8",reset=true);
    writeOutput('<h1>Confira os filtros do calendário</h1><p>' & encodeForHTML(arguments.message) & '</p><a href="/estado/">Voltar ao calendário</a>');abort;
};
if (!listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",URL.tag)) VARIABLES.regionalBadRequest("Estado inválido.");
param name="URL.cidade" default="";
param name="URL.page" default="0";
param name="URL.periodo_inicio" default="";
param name="URL.periodo_fim" default="";
if (len(URL.cidade) && !reFind("^[a-z0-9-]+$",URL.cidade)) VARIABLES.regionalBadRequest("Cidade inválida.");
if (!reFind("^\d{1,6}$",URL.page)) VARIABLES.regionalBadRequest("Página inválida.");
VARIABLES.regionalPage = val(URL.page);
VARIABLES.regionalToday = parseDateTime(dateTimeFormat(now(),"yyyy-mm-dd","America/Sao_Paulo"));
for (VARIABLES.regionalFlag in listToArray("rua,trail,nacional,internacional,cupom")) {
    if (!isBoolean(URL[VARIABLES.regionalFlag])) VARIABLES.regionalBadRequest("Filtro inválido.");
}
for (VARIABLES.regionalRangeKey in ["distancia","tempo"]) {
    if (!reFind("^\d{1,3},\d{1,3}$",URL[VARIABLES.regionalRangeKey]) || val(listFirst(URL[VARIABLES.regionalRangeKey])) GT val(listLast(URL[VARIABLES.regionalRangeKey]))) VARIABLES.regionalBadRequest("Intervalo inválido.");
}
if (val(listLast(URL.tempo)) GT 12 || val(listLast(URL.distancia)) GT 100) VARIABLES.regionalBadRequest("Intervalo fora dos limites do calendário.");
if (len(URL.badges) GT 500) VARIABLES.regionalBadRequest("Seleção de filtros muito longa.");
VARIABLES.regionalExactPeriod = len(URL.periodo_inicio) || len(URL.periodo_fim);
VARIABLES.regionalFrom = dateAdd("d",val(listFirst(URL.tempo))*30,VARIABLES.regionalToday);
VARIABLES.regionalTo = dateAdd("d",val(listLast(URL.tempo))*30,VARIABLES.regionalToday);
if (VARIABLES.regionalExactPeriod) {
    for (VARIABLES.regionalDateKey in ["periodo_inicio","periodo_fim"]) {
        if (!reFind("^\d{4}-\d{2}-\d{2}$",URL[VARIABLES.regionalDateKey])) VARIABLES.regionalBadRequest("Preencha a data inicial e a final no formato ano-mês-dia.");
        try {
            VARIABLES.regionalDate = createDate(val(listGetAt(URL[VARIABLES.regionalDateKey],1,"-")),val(listGetAt(URL[VARIABLES.regionalDateKey],2,"-")),val(listGetAt(URL[VARIABLES.regionalDateKey],3,"-")));
            if (dateFormat(VARIABLES.regionalDate,"yyyy-mm-dd") NEQ URL[VARIABLES.regionalDateKey]) VARIABLES.regionalBadRequest("Data inválida.");
        } catch(any invalidDate) { VARIABLES.regionalBadRequest("Data inválida."); }
        if (VARIABLES.regionalDateKey EQ "periodo_inicio") VARIABLES.regionalFrom=VARIABLES.regionalDate;else VARIABLES.regionalTo=VARIABLES.regionalDate;
    }
    if (VARIABLES.regionalFrom LT VARIABLES.regionalToday || VARIABLES.regionalTo LT VARIABLES.regionalFrom || dateDiff("d",VARIABLES.regionalFrom,VARIABLES.regionalTo) GT 732) VARIABLES.regionalBadRequest("Selecione datas a partir de hoje, com a data final após a inicial e um intervalo de até dois anos.");
}
VARIABLES.regionalWhere = "evt.estado=:uf AND evt.data_final>=:today";
VARIABLES.regionalParams = {uf={value=uCase(URL.tag),cfsqltype="cf_sql_varchar"},today={value=VARIABLES.regionalToday,cfsqltype="cf_sql_date"},startDate={value=VARIABLES.regionalFrom,cfsqltype="cf_sql_date"},endDate={value=dateAdd("d",1,VARIABLES.regionalTo),cfsqltype="cf_sql_date"}};
if (VARIABLES.regionalExactPeriod) VARIABLES.regionalWhere &= " AND evt.data_final>=:startDate AND coalesce(evt.data_inicial,evt.data_final)<:endDate";
else VARIABLES.regionalWhere &= " AND evt.data_final>=:startDate AND evt.data_final<:endDate";
if (URL.distancia NEQ "1,42") {
    VARIABLES.regionalWhere &= " AND EXISTS (SELECT 1 FROM tb_evento_corridas_percursos p WHERE p.id_evento=evt.id_evento AND p.percurso_evento BETWEEN :dmin AND :dmax)";
    VARIABLES.regionalParams.dmin={value=val(listFirst(URL.distancia)),cfsqltype="cf_sql_integer"};VARIABLES.regionalParams.dmax={value=val(listLast(URL.distancia)),cfsqltype="cf_sql_integer"};
}
if (len(URL.badges)) {VARIABLES.regionalWhere &= " AND evt.id_evento IN (SELECT id_evento FROM tb_badges WHERE badge IN (:badges))";VARIABLES.regionalParams.badges={value=URL.badges,cfsqltype="cf_sql_varchar",list=true};}
if (URL.rua && !URL.trail) VARIABLES.regionalWhere &= " AND evt.tipo_corrida='rua'";
if (!URL.rua && URL.trail) VARIABLES.regionalWhere &= " AND evt.tipo_corrida='trail'";
if (!URL.rua && !URL.trail) VARIABLES.regionalWhere &= " AND evt.tipo_corrida<>'rua' AND evt.tipo_corrida<>'trail'";
if (URL.cupom) VARIABLES.regionalWhere &= " AND evt.cupom IS NOT NULL";
if (URL.nacional && !URL.internacional) VARIABLES.regionalWhere &= " AND evt.pais='BR'";
if (!URL.nacional && URL.internacional) VARIABLES.regionalWhere &= " AND evt.pais<>'BR'";
if (!URL.nacional && !URL.internacional) VARIABLES.regionalWhere &= " AND evt.pais=''";
// Only aggregated counts/available distances cross the DB boundary for the full region.
VARIABLES.regionalFacetsSql = "SELECT evt.tag_cidade,count(*) AS total_eventos,min(evt.data_final) AS next_date";
for (VARIABLES.regionalKm in [5,10,21,42]) VARIABLES.regionalFacetsSql &= ",bool_or(EXISTS(SELECT 1 FROM tb_evento_corridas_percursos p WHERE p.id_evento=evt.id_evento AND p.percurso_evento=" & VARIABLES.regionalKm & " AND lower(trim(p.unidade_de_medida))='km')) AS km" & VARIABLES.regionalKm;
qEstadoCidadesContagens=queryExecute(VARIABLES.regionalFacetsSql & " FROM vw_evento_corridas evt WHERE " & VARIABLES.regionalWhere & " GROUP BY evt.tag_cidade",VARIABLES.regionalParams,{cachedWithin=createTimeSpan(0,0,5,0),timeout=20});
VARIABLES.regionalTotal=0;VARIABLES.regionalDistances={};VARIABLES.regionalNextDate="";
for (VARIABLES.regionalFacet in qEstadoCidadesContagens) {
    if (!len(URL.cidade) || compareNoCase(VARIABLES.regionalFacet.tag_cidade & "",URL.cidade) EQ 0) {
        VARIABLES.regionalTotal+=VARIABLES.regionalFacet.total_eventos;
        if (!len(VARIABLES.regionalNextDate) || VARIABLES.regionalFacet.next_date LT VARIABLES.regionalNextDate) VARIABLES.regionalNextDate=VARIABLES.regionalFacet.next_date;
        for (VARIABLES.regionalKm in [5,10,21,42]) if (VARIABLES.regionalFacet["km" & VARIABLES.regionalKm]) VARIABLES.regionalDistances[toString(VARIABLES.regionalKm)]=true;
    }
}
VARIABLES.regionalPages=max(1,ceiling(VARIABLES.regionalTotal/VARIABLES.pageSize));
if (len(URL.cidade)) {VARIABLES.regionalWhere &= " AND evt.tag_cidade=:city";VARIABLES.regionalParams.city={value=URL.cidade,cfsqltype="cf_sql_varchar"};}
VARIABLES.regionalParams.offsetRows={value=VARIABLES.regionalPage*VARIABLES.pageSize,cfsqltype="cf_sql_integer"};
VARIABLES.regionalParams.limitRows={value=VARIABLES.pageSize,cfsqltype="cf_sql_integer"};
if (VARIABLES.regionalPage GTE VARIABLES.regionalPages) qEventos=queryNew("id_evento","integer");
else qEventos=queryExecute("SELECT evt.* FROM vw_evento_corridas evt WHERE " & VARIABLES.regionalWhere & " ORDER BY evt.data_final,evt.destaque NULLS LAST,evt.id_tema DESC,evt.id_agrega_evento NULLS LAST,cupom NULLS LAST,is_maratona NULLS LAST,max_percurso DESC NULLS LAST,id_foco_radical NULLS LAST,evt.tipo_corrida,evt.id_evento LIMIT :limitRows OFFSET :offsetRows",VARIABLES.regionalParams,{cachedWithin=createTimeSpan(0,0,5,0),timeout=20});
VARIABLES.eventListRenderAllRows=true;
VARIABLES.eventListTotal=VARIABLES.regionalTotal;
VARIABLES.regionalPath="/estado/" & lCase(URL.tag) & "/" & (len(URL.cidade) ? URL.cidade & "/" : "");
VARIABLES.regionalFilterDefaults={distancia="1,42",tempo="0,12",rua="true",trail="true",nacional="true",internacional="false",cupom="false",badges="",periodo_inicio="",periodo_fim=""};
VARIABLES.regionalFilterParts=[];
for (VARIABLES.regionalKey in listToArray("distancia,tempo,rua,trail,nacional,internacional,cupom,badges,periodo_inicio,periodo_fim")) {
    if (VARIABLES.regionalExactPeriod && VARIABLES.regionalKey EQ "tempo") continue;
    if (toString(URL[VARIABLES.regionalKey]) NEQ VARIABLES.regionalFilterDefaults[VARIABLES.regionalKey]) arrayAppend(VARIABLES.regionalFilterParts,VARIABLES.regionalKey & "=" & urlEncodedFormat(URL[VARIABLES.regionalKey]));
}
VARIABLES.regionalPageUrl=function(required numeric pageNumber){
    var parts=duplicate(VARIABLES.regionalFilterParts);if(arguments.pageNumber GT 1)arrayAppend(parts,"pagina=" & arguments.pageNumber);
    return VARIABLES.regionalPath & (arrayLen(parts) ? "?" & arrayToList(parts,"&") : "");
};
</cfscript>
