<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<!--- Historical discovery is independent from the calendar filters and only on page one. --->
<cfif VARIABLES.regionalPage EQ 0>
<cfquery name="qRegionalRaces" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="8">
    SELECT a.tag, a.nome_evento_agregado, count(DISTINCT e.id_evento) AS editions,
        min(e.data_inicial) FILTER (WHERE coalesce(e.data_final,e.data_inicial) >= current_date) AS next_date
    FROM tb_agrega_eventos a
    JOIN tb_evento_corridas e ON e.id_agrega_evento=a.id_agrega_evento
    WHERE e.ativo=true AND a.tipo_agregacao='maratona' AND a.tag ~ '^[a-z0-9-]+$'
        AND upper(trim(e.estado))=<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
        AND upper(trim(e.pais))='BR'
        <cfif len(VARIABLES.estadoCidadeSlug)>
        AND translate(lower(trim(e.cidade)), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc')=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.estadoCidadeSlug#"/>
        </cfif>
    GROUP BY a.tag,a.nome_evento_agregado
    HAVING count(DISTINCT e.id_evento) >= 2
    ORDER BY next_date ASC NULLS LAST, editions DESC, a.nome_evento_agregado, a.tag
    LIMIT 6
</cfquery>
<cfif qRegionalRaces.recordCount>
<cfoutput>
<details class="rr-race-guide rr-regional-races" data-regional-races>
    <summary>Histórico de maratonas #encodeForHTML(VARIABLES.estadoLocalidade)#</summary>
    <p>Explore provas com edições cadastradas nesta região. Esta seleção inclui o histórico, independentemente dos filtros do calendário.</p>
    <ul class="rr-race-links"><cfloop query="qRegionalRaces">
        <li><a href="/maratona/#encodeForHTMLAttribute(tag)#/">#encodeForHTML(nome_evento_agregado)#</a><span class="rr-race-note">#editions# edições cadastradas na região</span></li>
    </cfloop></ul>
</details>
</cfoutput>
</cfif>
</cfif>
