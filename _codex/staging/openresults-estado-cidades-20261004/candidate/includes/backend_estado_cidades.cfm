<cfif NOT structKeyExists(VARIABLES,"qEventosBase") OR NOT structKeyExists(VARIABLES,"qEventos") OR NOT isQuery(VARIABLES.qEventosBase) OR NOT isQuery(VARIABLES.qEventos)>
    <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfparam name="URL.cidade" default=""/>
<cfscript>
// Resultados históricos usam as mesmas facetas da lista, sem restringir a cidade.
if (!listFindNoCase("maiores,maratonas", URL.filtro)) URL.filtro = "";
VARIABLES.estadoCidadeSlug = lCase(trim(URL.cidade));
VARIABLES.estadoCidadeNome = "Cidade não encontrada";
VARIABLES.estadoCityCounts = {};
REQUEST.estadoCityUrl = function(required string slug, string mode=URL.filtro) {
    var parts = [];
    if (len(arguments.slug)) arrayAppend(parts, "cidade=" & urlEncodedFormat(arguments.slug));
    if (len(arguments.mode)) arrayAppend(parts, "filtro=" & urlEncodedFormat(arguments.mode));
    for (var key in listToArray("distancia,tempo,rua,trail,nacional,internacional,cupom,badges,ano")) {
        if (structKeyExists(URL, key) && len(trim(toString(URL[key])))) arrayAppend(parts, key & "=" & urlEncodedFormat(URL[key]));
    }
    return "/estado/" & lCase(URL.tag) & "/" & (arrayLen(parts) ? "?" & arrayToList(parts,"&") : "");
};
</cfscript>
<!--- Nomes independem dos badges ativos: a seleção válida permanece visível mesmo com zero resultados. --->
<cfquery name="qEstadoCidadesNomes" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
    WITH cidades AS (
        SELECT evt.cidade,
            translate(lower(evt.cidade), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') AS tag_cidade
        FROM tb_evento_corridas evt
        WHERE evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
            AND evt.ativo = true AND nullif(trim(evt.cidade),'') IS NOT NULL
            AND evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(),'yyyy-mm-dd')#"/>
            AND (EXISTS (SELECT 1 FROM tb_resultados_resumo res WHERE res.id_evento=evt.id_evento)
                OR EXISTS (SELECT 1 FROM tb_resultados res WHERE res.id_evento=evt.id_evento AND res.origem_resultado <> 'validacao_documental')
                OR (evt.url_resultado IS NOT NULL AND evt.url_resultado <> ''))
    )
    SELECT tag_cidade, min(cidade) AS cidade FROM cidades
    GROUP BY tag_cidade ORDER BY cidade ASC
</cfquery>
<cfscript>
for (VARIABLES.cityRow in qEstadoCidadesNomes) {
    if (len(VARIABLES.estadoCidadeSlug) && (VARIABLES.estadoCidadeSlug == VARIABLES.cityRow.tag_cidade || compareNoCase(trim(URL.cidade),trim(VARIABLES.cityRow.cidade)) == 0)) {
        VARIABLES.estadoCidadeSlug = VARIABLES.cityRow.tag_cidade;
        break;
    }
}
</cfscript>
<cfquery name="qEstadoEventosSemCidade" dbtype="query">
    SELECT * FROM qEventos WHERE 1=1
    <cfif URL.filtro EQ "maratonas">
        AND is_maratona = 42 AND tipo_corrida = 'rua'
        AND upper(nome_evento) NOT LIKE '%REVEZAMENTO%'
    </cfif>
    ORDER BY data_final DESC, concluintes DESC
</cfquery>
<cfquery name="qEstadoCidadeContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEstadoEventosSemCidade
    WHERE tag_cidade IS NOT NULL
    GROUP BY tag_cidade
</cfquery>
<cfscript>
VARIABLES.estadoCitiesTotal = URL.filtro == "maiores" ? min(20,qEstadoEventosSemCidade.recordCount) : qEstadoEventosSemCidade.recordCount;
for (VARIABLES.cityRow in qEstadoCidadeContagens) {
    VARIABLES.estadoCityCounts[VARIABLES.cityRow.tag_cidade] = URL.filtro == "maiores" ? min(20,VARIABLES.cityRow.total_eventos) : VARIABLES.cityRow.total_eventos;
}
qEstadoCidades = queryNew("cidade,tag_cidade,total_eventos", "varchar,varchar,integer");
for (VARIABLES.cityRow in qEstadoCidadesNomes) {
    if (!len(trim(VARIABLES.cityRow.cidade)) || !len(trim(VARIABLES.cityRow.tag_cidade)) || reFind("[^a-z0-9-]",VARIABLES.cityRow.tag_cidade)) continue;
    VARIABLES.cityWords = listToArray(lCase(trim(VARIABLES.cityRow.cidade)), " ");
    for (VARIABLES.wordIndex=1;VARIABLES.wordIndex<=arrayLen(VARIABLES.cityWords);VARIABLES.wordIndex++) {
        if (VARIABLES.wordIndex==1 || !listFindNoCase("a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob",VARIABLES.cityWords[VARIABLES.wordIndex])) {
            VARIABLES.cityWords[VARIABLES.wordIndex] = uCase(left(VARIABLES.cityWords[VARIABLES.wordIndex],1)) & mid(VARIABLES.cityWords[VARIABLES.wordIndex],2,len(VARIABLES.cityWords[VARIABLES.wordIndex]));
        }
    }
    VARIABLES.cityName = arrayToList(VARIABLES.cityWords," ");
    VARIABLES.cityCount = structKeyExists(VARIABLES.estadoCityCounts,VARIABLES.cityRow.tag_cidade) ? VARIABLES.estadoCityCounts[VARIABLES.cityRow.tag_cidade] : 0;
    queryAddRow(qEstadoCidades, {cidade=VARIABLES.cityName,tag_cidade=VARIABLES.cityRow.tag_cidade,total_eventos=VARIABLES.cityCount});
    if (VARIABLES.estadoCidadeSlug == VARIABLES.cityRow.tag_cidade) VARIABLES.estadoCidadeNome = VARIABLES.cityName;
}
</cfscript>
<cfquery name="qEstadoEventosCidade" dbtype="query">
    SELECT * FROM qEstadoEventosSemCidade WHERE 1=1
    <cfif len(VARIABLES.estadoCidadeSlug)>
        AND tag_cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.estadoCidadeSlug#"/>
    </cfif>
    <cfif URL.filtro EQ "maiores">ORDER BY concluintes DESC<cfelse>ORDER BY data_final DESC, concluintes DESC</cfif>
</cfquery>
<cfif URL.filtro EQ "maiores">
    <cfquery name="qEventos" dbtype="query" maxrows="20">SELECT * FROM qEstadoEventosCidade ORDER BY concluintes DESC</cfquery>
<cfelse>
    <cfset qEventos = qEstadoEventosCidade/>
</cfif>
