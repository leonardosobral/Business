<cfquery name="qEventos_statsobs" dbtype="query">
    select *
    from qPeriodoObs
    <cfif len(trim(URL.busca))>
        WHERE obs_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.busca#"/>
    <cfelse>
        WHERE obs_resultado is null OR obs_resultado = ''
    </cfif>
    order by obs_resultado, data_final
</cfquery>

<cfquery name="qEventos_obs" dbtype="query">
    select obs_resultado, count(*) total
    from qPeriodoObs
    group by obs_resultado
    order by total desc
</cfquery>

<!--- STATUS DA HOMOLOGACAO --->

<cfquery name="qProvasResultado" dbtype="query">
    select count(*) as total from qPeriodo
</cfquery>

<cfquery name="qProvasLink" dbtype="query">
    select count(*) as total from qPeriodoObs
    WHERE url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qProvasSemResultado" dbtype="query">
    select count(*) as total from qPeriodoObs
    WHERE obs_resultado IN ('Sem Resultado', 'Kids', 'Treino', 'Cancelado', 'Adiado', 'Repetido')
</cfquery>

<cfset VARIABLES.totalProvas = qPeriodo.recordcount + qPeriodoObs.recordcount/>
<cfset VARIABLES.totalProvasResultado = len(trim(qProvasResultado.total)) ? (qProvasResultado.total*100)/VARIABLES.totalProvas : 0/>
<cfset VARIABLES.totalProvasLink = len(trim(qProvasLink.total)) ? (qProvasLink.total*100)/VARIABLES.totalProvas : 0/>
<cfset VARIABLES.totalProvasSemResultado = len(trim(qProvasSemResultado.total)) ? (qProvasSemResultado.total*100)/VARIABLES.totalProvas : 0/>
<cfset VARIABLES.totalProvasPendentes = 100-VARIABLES.totalProvasResultado-VARIABLES.totalProvasLink-VARIABLES.totalProvasSemResultado/>
