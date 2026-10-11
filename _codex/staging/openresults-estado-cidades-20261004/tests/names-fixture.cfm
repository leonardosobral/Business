<cfquery name="qEstadoCidadesNomes" dbtype="query">
    SELECT tag_cidade, min(cidade) AS cidade
    FROM qEstadoCidadesFixtureBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    GROUP BY tag_cidade
    ORDER BY cidade ASC
</cfquery>