<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<!--- Circuit membership is independent of the edition group and visual theme. --->
<cfquery name="qEventCircuitLinks" cachedwithin="#createTimeSpan(0,0,1,0)#" timeout="5">
    SELECT DISTINCT g.agregador_tag, g.agregador_nome,
        coalesce(nullif(a.tag,''),g.agregador_tag) AS route_tag
    FROM tb_agregadores_eventos ge
    JOIN tb_agregadores g ON g.agregador_tag=ge.agregador_tag
    LEFT JOIN tb_agrega_eventos a ON a.id_agrega_evento=g.id_agrega_evento_legado
    WHERE ge.id_evento=<cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento[1]#"/>
        AND g.agregador_tipo='circuito'
        AND g.agregador_tag IN ('live-run-xp','estacoes')
    ORDER BY g.agregador_nome,g.agregador_tag
</cfquery>
<cfscript>
VARIABLES.eventCircuitLinks=[];
for (VARIABLES.eventCircuitRow in qEventCircuitLinks) {
    // The themed header already links its own circuit.
    if (qAgrega.recordCount && qAgrega.tipo_agregacao[1]=="circuito"
        && listFindNoCase(VARIABLES.eventCircuitRow.agregador_tag & "," & VARIABLES.eventCircuitRow.route_tag,qAgrega.tag[1])) continue;
    if (!reFind("^[a-z0-9][a-z0-9-]{1,255}$",VARIABLES.eventCircuitRow.route_tag)) continue;
    arrayAppend(VARIABLES.eventCircuitLinks,{name=VARIABLES.eventCircuitRow.agregador_nome,path="/circuito/" & VARIABLES.eventCircuitRow.route_tag & "/"});
}
VARIABLES.eventCircuitLabel="Etapas do circuito";
if (structKeyExists(REQUEST,"lang") && REQUEST.lang=="en") VARIABLES.eventCircuitLabel="Race series events";
if (structKeyExists(REQUEST,"lang") && REQUEST.lang=="es") VARIABLES.eventCircuitLabel="Etapas del circuito";
</cfscript>
<cfif arrayLen(VARIABLES.eventCircuitLinks)><cfoutput>
<nav class="small mb-2 px-2" aria-label="#encodeForHTMLAttribute(VARIABLES.eventCircuitLabel)#" data-event-circuits>
    <span>#encodeForHTML(VARIABLES.eventCircuitLabel)#: </span>
    <cfloop from="1" to="#arrayLen(VARIABLES.eventCircuitLinks)#" index="eventCircuitIndex"><cfif eventCircuitIndex GT 1> · </cfif><a href="#encodeForHTMLAttribute(VARIABLES.eventCircuitLinks[eventCircuitIndex].path)#" hreflang="pt-BR">#encodeForHTML(VARIABLES.eventCircuitLinks[eventCircuitIndex].name)#</a></cfloop>
</nav>
</cfoutput></cfif>
