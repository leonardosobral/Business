<!--- Facetas do calendário: os mesmos filtros da lista, sem restringir a cidade. --->
<cfquery name="qEstadoCidadesContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEventosBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    <cfif len(trim(URL.tempo))>
        AND data_final BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListLast(URL.tempo)*30), 'yyyy-mm-dd')#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.cupom>
        AND cupom IS NOT NULL
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    GROUP BY tag_cidade
</cfquery>

<cfquery name="qEstadoCidadesNomes" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    WITH cidades_normalizadas AS (
        SELECT initcap(lower(trim(cidade))) AS cidade,
            translate(lower(trim(cidade)), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') AS tag_cidade
        FROM tb_evento_corridas
        WHERE upper(trim(estado)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
            AND nullif(trim(cidade), '') IS NOT NULL
    )
    SELECT min(cidade) AS cidade, tag_cidade
    FROM cidades_normalizadas
    WHERE tag_cidade ~ '^[a-z0-9-]+$'
    GROUP BY tag_cidade
    ORDER BY cidade ASC
</cfquery>

<cfscript>
if (!structKeyExists(REQUEST, "formatEstadoCidadeNome")) {
    REQUEST.formatEstadoCidadeNome = function(required string cityName) {
        var words = listToArray(trim(arguments.cityName), " ");
        for (var i = 2; i <= arrayLen(words); i++) {
            if (listFindNoCase("a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob", words[i])) words[i] = lCase(words[i]);
        }
        return arrayToList(words, " ");
    };
}
VARIABLES.estadoCityCounts = {};
VARIABLES.estadoCitiesData = {uf=lCase(URL.tag), cities=[], total=0};
VARIABLES.estadoCitiesData["filters"] = {"distancia"=URL.distancia,"tempo"=URL.tempo,"rua"=URL.rua,"trail"=URL.trail,"nacional"=URL.nacional,"internacional"=URL.internacional,"cupom"=URL.cupom,"badges"=URL.badges};
for (VARIABLES.estadoCityRow in qEstadoCidadesContagens) {
    VARIABLES.estadoCityCounts[VARIABLES.estadoCityRow.tag_cidade] = VARIABLES.estadoCityRow.total_eventos;
    VARIABLES.estadoCitiesData.total += VARIABLES.estadoCityRow.total_eventos;
}
qEstadoCidades = queryNew("cidade,tag_cidade,total_eventos", "varchar,varchar,integer");
for (VARIABLES.estadoCityRow in qEstadoCidadesNomes) {
    VARIABLES.estadoCityCount = structKeyExists(VARIABLES.estadoCityCounts, VARIABLES.estadoCityRow.tag_cidade) ? VARIABLES.estadoCityCounts[VARIABLES.estadoCityRow.tag_cidade] : 0;
    VARIABLES.estadoCityName = REQUEST.formatEstadoCidadeNome(VARIABLES.estadoCityRow.cidade);
    queryAddRow(qEstadoCidades, {cidade=VARIABLES.estadoCityName,tag_cidade=VARIABLES.estadoCityRow.tag_cidade,total_eventos=VARIABLES.estadoCityCount});
    arrayAppend(VARIABLES.estadoCitiesData.cities, {slug=VARIABLES.estadoCityRow.tag_cidade,name=VARIABLES.estadoCityName,total=VARIABLES.estadoCityCount});
}
</cfscript>

<cfquery name="qEstadoCidadesSidebar" dbtype="query" maxrows="10">
    SELECT * FROM qEstadoCidades WHERE total_eventos > 0 ORDER BY total_eventos DESC, cidade ASC
</cfquery>
