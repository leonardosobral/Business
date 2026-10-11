<cfparam name="URL.ano" default="2025"/>


<!--- QUERY BASE DE EVENTOS --->

<!--- Only catalogue screens use qEventos; athlete/event/search pages have their own queries. --->
<cfif listFind("/,/estado/", VARIABLES.template)>

<!--- Shared catalogue snapshot: one refresh every 30 minutes, outside warm page requests. --->
<cfif NOT structKeyExists(APPLICATION,"eventCatalogCacheV1")>
 <cflock name="OpenResults.EventCatalog.Init" type="exclusive" timeout="2">
  <cfif NOT structKeyExists(APPLICATION,"eventCatalogCacheV1")>
   <cfset APPLICATION.eventCatalogCacheV1=createObject("component","services.EventCatalogCache").init(source=new services.EventCatalogSource())/>
  </cfif>
 </cflock>
</cfif>
<cfset VARIABLES.eventCatalogSnapshot=APPLICATION.eventCatalogCacheV1.get()/>
<cfif structIsEmpty(VARIABLES.eventCatalogSnapshot)>
 <cfheader statuscode="503" statustext="Service Unavailable"/><cfheader name="Retry-After" value="60"/>
 <cfcontent type="text/html; charset=utf-8" reset="true"/>O catálogo está temporariamente indisponível. Tente novamente em alguns instantes.<cfabort/>
</cfif>
<cfif NOT len(trim(URL.badges))>
 <cfset qEventosBase=VARIABLES.eventCatalogSnapshot.events/>
 <cfset qEventosResult={executionTime=0,cached=true}/>
<cfelse>
<cfquery name="qEventosBase" cachedwithin="#CreateTimeSpan(0, 0, 30, 0)#" result="qEventosResult" timeout="12">
    SELECT
        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
        evt.url_inscricao, evt.url_resultado, evt.obs_resultado,
        DATE_PART('week', evt.data_inicial) AS week,
        DATE_PART('month', evt.data_inicial) AS month,
        translate(lower( cidade ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') as tag_cidade,
        (select json_agg(row_to_json(linha))
            from
                (select
                    distinct
                    bd.badge,
                    tip.ordem
                from tb_badges bd
                inner join tb_badges_tipos tip on tip.badge = bd.badge
                where bd.id_evento = evt.id_evento
                order by tip.ordem
                 ) as linha
        ) as badges,
        (SELECT sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento) as concluintes,
        (SELECT
            json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as lista_percursos,
        (SELECT
            max(percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as max_percurso,
        (SELECT cupom FROM vw_evento_corridas_cupom
            WHERE id_evento_agrega = evt.id_evento
            AND tipo_evento = 1
            OR (id_evento_agrega = evt.id_agrega_evento
            AND tipo_evento = 2)
        ) as cupom,
        (WITH vw as (
                SELECT percurso, sum(concluintes) as concluintes
                from
                tb_resultados_resumo pcr
                where pcr.id_evento = evt.id_evento
                group by percurso)
            SELECT
            json_agg(json_build_object('percurso',percurso,'concluintes',concluintes) order by percurso)
            from vw
        ) as lista_percursos_resultado,
        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
            limit 1
        ) as is_maratona
    FROM tb_evento_corridas evt
    WHERE evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
    AND evt.ativo = true
    AND ( Exists (SELECT distinct id_evento FROM tb_resultados_resumo res WHERE evt.id_evento = res.id_evento )
        OR Exists (SELECT 1 FROM tb_resultados raw_res WHERE raw_res.id_evento = evt.id_evento AND raw_res.origem_resultado <> 'validacao_documental')
        OR (evt.url_resultado is not null AND evt.url_resultado <> '' AND evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>) )
    <cfif len(trim(URL.badges))>
        AND evt.id_evento IN ( select id_evento FROM tb_badges WHERE badge IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="yes" value="#URL.badges#"/>))
    </cfif>
    ORDER BY evt.data_final desc, concluintes desc NULLS LAST;
</cfquery>
</cfif>

<!--- FILTROS DA QUERY BASE DE EVENTOS--->

<cfquery name="qEventos" dbtype="query">
    select * from qEventosBase
    WHERE 1 = 1
    <!---cfif Len(trim(URL.tempo))>
        AND
        (
            data_inicial between <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            and <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+ListLast(URL.tempo)*30, 'yyyy-mm-dd')#"/>
        )
    </cfif--->
    <cfif isDefined("URL.cidade") AND VARIABLES.template NEQ "/estado/">
        AND upper(cidade) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.cidade)#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif URL.cupom>
        AND cupom is not null
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
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
    <cfif VARIABLES.template EQ "/estado/">
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
    </cfif>
</cfquery>


<cfquery name="qPowerUps" cachedwithin="#CreateTimeSpan(0, 0, 15, 0)#">
    SELECT * from tb_powerups
    WHERE ativo = true
    order by liberado desc, id_powerup
</cfquery>

</cfif>

<cfif NOT isDefined("qEventos")>
    <cfset qEventos = queryNew("id_evento")/>
</cfif>


<cfset VARIABLES.statsPercursos = "5,10,15,21,30,42"/>

<cfif VARIABLES.template EQ "/estado/">

<cfquery name="qStatsAll" cachedwithin="#CreateTimeSpan(0, 0, 15, 0)#" result="qStatsAllResult">
    -- cache-state-all-years: #URL.tag#
    with base as (
        SELECT
            res.percurso::int as percurso,
            res.sexo,
            res.id_evento,
            res.tempo_total,
            res.pace,
            res.concluinte,
            res.homologado as res_homologado,
            res.pcd,
            evt.homologado as evt_homologado,
            evt.ranking
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
        WHERE res.percurso::int in (<cfqueryparam cfsqltype="cf_sql_integer" list="yes" value="#VARIABLES.statsPercursos#"/>)
        AND res.sexo in ('M','F')
        AND res.concluinte = true
        AND evt.pais = 'BR'
        <cfif VARIABLES.template EQ "/estado/" AND len(trim(URL.tag))>
            and evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        </cfif>
    ),
    agregado as (
        SELECT
            percurso,
            sexo,
            count(distinct id_evento)::int as eventos,
            count(*)::int as concluintes,
            min(case when evt_homologado = true and res_homologado = true and ranking = 'true' and pcd = false then tempo_total else null end) as rp,
            min(case when evt_homologado = true and res_homologado = true and ranking = 'true' and pcd = false then pace else null end) as rp_pace,
            to_char(avg(case when evt_homologado = true and res_homologado = true and ranking = 'true' and pcd = false then tempo_total else null end),'hh24:mi:ss') as avg_tempo,
            to_char(avg(case when evt_homologado = true and res_homologado = true and ranking = 'true' and pcd = false then pace else null end),'hh24:mi:ss') as avg_pace
        FROM base
        GROUP BY percurso, sexo
    )
    SELECT percurso,
       sexo,
       coalesce(to_char(rp, 'hh24:mi:ss'), '') as rp,
       coalesce(to_char(rp_pace, 'hh24:mi:ss'), '') as rp_pace,
       coalesce(avg_pace, '') as avg_pace,
       coalesce(avg_tempo, '') as avg_tempo,
       concluintes,
       eventos
    FROM agregado
    WHERE concluintes > 0
    ORDER BY percurso, sexo, concluintes, eventos
</cfquery>

</cfif>

<cfif NOT isDefined("qStatsAll")>
    <cfset qStatsAll = queryNew("percurso,sexo,rp,rp_pace,avg_pace,avg_tempo,concluintes,eventos")/>
</cfif>

<cfif NOT isDefined("qStatsTopEstados")>
    <cfset qStatsTopEstados = queryNew("estado,concluintes")/>
</cfif>

<cfif NOT isDefined("qStatsCharts")>
    <cfset qStatsCharts = queryNew("percurso,total,feminino,masculino")/>
</cfif>

<cfquery name="qStats5" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="5"/>
</cfquery>

<cfquery name="qStats10" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="10"/>
</cfquery>

<cfquery name="qStats15" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="15"/>
</cfquery>

<cfquery name="qStats21" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="21"/>
</cfquery>

<cfquery name="qStats30" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="30"/>
</cfquery>

<cfquery name="qStats42" dbtype="query">
    SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
    FROM qStatsAll
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="42"/>
</cfquery>

<cfset qStatsCards = queryNew("percurso,eventos,concluintes,f_rp,f_avg_tempo,f_concluintes,m_rp,m_avg_tempo,m_concluintes")/>
<cfset qStatsCharts = queryNew("percurso,total,feminino,masculino")/>

<cfloop list="#VARIABLES.statsPercursos#" index="statsPercurso">
    <cfquery name="qStatsCardRows" dbtype="query">
        SELECT sexo, rp, rp_pace, avg_pace, avg_tempo, concluintes, eventos
        FROM qStatsAll
        WHERE percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#statsPercurso#"/>
    </cfquery>

    <cfif qStatsCardRows.recordcount>
        <cfset statsEventos = 0/>
        <cfset statsConcluintes = 0/>
        <cfset statsFRp = ""/>
        <cfset statsFAvgTempo = ""/>
        <cfset statsFConcluintes = 0/>
        <cfset statsFEventos = 0/>
        <cfset statsMRp = ""/>
        <cfset statsMAvgTempo = ""/>
        <cfset statsMConcluintes = 0/>
        <cfset statsMEventos = 0/>

        <cfloop query="qStatsCardRows">
            <cfif uCase(qStatsCardRows.sexo) EQ "F">
                <cfset statsFRp = qStatsCardRows.rp/>
                <cfset statsFAvgTempo = qStatsCardRows.avg_tempo/>
                <cfset statsFConcluintes = val(qStatsCardRows.concluintes)/>
                <cfset statsFEventos = val(qStatsCardRows.eventos)/>
            <cfelseif uCase(qStatsCardRows.sexo) EQ "M">
                <cfset statsMRp = qStatsCardRows.rp/>
                <cfset statsMAvgTempo = qStatsCardRows.avg_tempo/>
                <cfset statsMConcluintes = val(qStatsCardRows.concluintes)/>
                <cfset statsMEventos = val(qStatsCardRows.eventos)/>
            </cfif>
        </cfloop>

        <cfset statsEventos = statsFEventos/>
        <cfif statsMEventos GT statsEventos>
            <cfset statsEventos = statsMEventos/>
        </cfif>
        <cfset statsConcluintes = statsFConcluintes + statsMConcluintes/>

        <cfif VARIABLES.template EQ "/estatisticas/">
            <cfset queryAddRow(qStatsCharts, 1)/>
            <cfset querySetCell(qStatsCharts, "percurso", statsPercurso)/>
            <cfset querySetCell(qStatsCharts, "total", statsConcluintes)/>
            <cfset querySetCell(qStatsCharts, "feminino", statsFConcluintes)/>
            <cfset querySetCell(qStatsCharts, "masculino", statsMConcluintes)/>
        </cfif>

        <cfset queryAddRow(qStatsCards, 1)/>
        <cfset querySetCell(qStatsCards, "percurso", statsPercurso)/>
        <cfset querySetCell(qStatsCards, "eventos", statsEventos)/>
        <cfset querySetCell(qStatsCards, "concluintes", statsConcluintes)/>
        <cfset querySetCell(qStatsCards, "f_rp", statsFRp)/>
        <cfset querySetCell(qStatsCards, "f_avg_tempo", statsFAvgTempo)/>
        <cfset querySetCell(qStatsCards, "f_concluintes", statsFConcluintes)/>
        <cfset querySetCell(qStatsCards, "m_rp", statsMRp)/>
        <cfset querySetCell(qStatsCards, "m_avg_tempo", statsMAvgTempo)/>
        <cfset querySetCell(qStatsCards, "m_concluintes", statsMConcluintes)/>
    </cfif>
</cfloop>


<cfquery name="qBadges" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#" result="qBadgesResult">
    SELECT * from tb_badges_tipos
    where ativo = true AND site ilike '%OR%'
    order by ordem
</cfquery>


<cfif isDefined("URL.teste")>
    <cfset statsLog = "#URL.tag#"/>
    <cfif isDefined("qEventosResult")>
        <cfset statsLog = "#statsLog#/ | ev exec: #qEventosResult.ExecutionTime#ms | ev cached: #qEventosResult.Cached#"/>
    </cfif>
    <cfif isDefined("qStatsAllResult")>
        <cfset statsLog = "#statsLog# | stats exec: #qStatsAllResult.ExecutionTime#ms | stats cached: #qStatsAllResult.Cached#"/>
    </cfif>

    <cfquery name="qLogResultadoTeste">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="teste #URL.teste#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#statsLog#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
    </cfquery>
</cfif>
