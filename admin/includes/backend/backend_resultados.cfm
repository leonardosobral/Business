<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 5)#">
    SELECT
    extract(year from evt.data_final) as ano,
    evt.id_evento, evt.estado, evt.cidade, evt.nome_evento, evt.tag, evt.data_final, evt.url_resultado, evt.url_inscricao, evt.obs_resultado,
    agr.nome_evento_agregado, agr.tipo_agregacao, evt.id_agrega_evento, evt.homologado, evt.ranking,
    uf.regiao,
    (select sum(res.concluintes)
        FROM tb_resultados_resumo_2025 res
        WHERE res.id_evento = evt.id_evento and sexo is null) as concluintes
    FROM tb_evento_corridas evt
    inner join tb_uf uf ON evt.estado = uf.uf
    left join tb_agrega_eventos agr ON evt.id_agrega_evento = agr.id_agrega_evento
    where ativo = true and evt.pais = 'BR'
    <cfif len(trim(URL.id_agrega_evento)) >
        AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_agrega_evento#"/>
    </cfif>
    <cfif len(trim(URL.agregador_tag))>
        <cfif URL.agregador_tag EQ 'correria-campinas'>
            AND evt.cidade IN (SELECT cidade FROM tb_agregadores_cidades WHERE agregador_tag = 'correria-campinas')
            AND evt.estado = 'SP'
        <cfelse>
            AND evt.id_evento IN (
                select id_evento from tb_agregadores_eventos where agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.agregador_tag#"/>
            )
        </cfif>
    </cfif>
</cfquery>

<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    WHERE concluintes > 0
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "semana">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "mes">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-30#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2026">
        AND data_final between '2026-01-01' and <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2025">
        AND data_final between '2025-01-01' and <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2024">
        AND data_final between '2024-01-01' and '2024-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2023">
        AND data_final between '2023-01-01' and '2023-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2022">
        AND data_final between '2022-01-01' and '2022-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2021">
        AND data_final between '2021-01-01' and '2021-12-31'
    </cfif>
</cfquery>

<cfquery name="qPeriodoObs" dbtype="query">
    select *
    from qBase
    WHERE concluintes is null
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "semana">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "mes">
        AND data_final >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-30#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2026">
        AND data_final between '2025-01-01' and <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2025">
        AND data_final between '2025-01-01' and <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2024">
        AND data_final between '2024-01-01' and '2024-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2023">
        AND data_final between '2023-01-01' and '2023-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2022">
        AND data_final between '2022-01-01' and '2022-12-31'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "2021">
        AND data_final between '2021-01-01' and '2021-12-31'
    </cfif>
</cfquery>


<cfquery name="qCountInsTotal" dbtype="query">
    select count(*) as total, sum(id_evento) as inscricoes
    from qBase
    where url_inscricao = ''
</cfquery>



<cfquery name="qCount2026" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2026-01-01' and '2026-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCount2025" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2025-01-01' and '2025-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCount2024" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2024-01-01' and '2024-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCount2023" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2023-01-01' and '2023-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCount2022" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where data_final between '2022-01-01' and '2022-12-31' and concluintes > 0
</cfquery>

<cfquery name="qCountTotal" dbtype="query">
    select count(*) as total, sum(concluintes) as concluintes
    from qBase
    where concluintes > 0
</cfquery>

<cfquery name="qCountEv2026" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2026-01-01' and <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
</cfquery>

<cfquery name="qCountLinkEv2026" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2026-01-01' and <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
    AND concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qCountEv2025" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2025-01-01' and <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
</cfquery>

<cfquery name="qCountLinkEv2025" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2025-01-01' and <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
    AND concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qCountEv2024" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2024-01-01' and '2024-12-31'
</cfquery>

<cfquery name="qCountLinkEv2024" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2024-01-01' and '2024-12-31'
    AND concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qCountEv2023" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2023-01-01' and '2023-12-31'
</cfquery>

<cfquery name="qCountLinkEv2023" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2023-01-01' and '2023-12-31'
    AND concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qCountEv2022" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2022-01-01' and '2022-12-31'
</cfquery>

<cfquery name="qCountLinkEv2022" dbtype="query">
    select count(*) as total
    from qBase
    where data_final between '2022-01-01' and '2022-12-31'
    AND concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>

<cfquery name="qCountEvTotal" dbtype="query">
    select count(*) as total
    from qBase
</cfquery>

<cfquery name="qCountLinkEvTotal" dbtype="query">
    select count(*) as total
    from qBase
    WHERE concluintes is null
    AND url_resultado is not null
    AND url_resultado <> ''
</cfquery>


<cfquery name="qStatsRegiao" dbtype="query">
    select regiao, count(id_evento) total
    from qPeriodo
    group by regiao
    order by total desc
</cfquery>

<cfquery name="qStatsEstado" dbtype="query">
    select estado, count(id_evento) total
    from qPeriodo
    where estado is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    group by estado
    order by total desc
</cfquery>

<cfquery name="qStatsCidade" dbtype="query">
    select estado, cidade, count(id_evento) total
    from qPeriodo
    where cidade is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    group by estado, cidade
    order by total desc
</cfquery>


<cfquery name="qStatsEvento" dbtype="query">
    select id_evento, estado, cidade, nome_evento, tag, homologado, ranking, data_final, sum(concluintes) total
    from qPeriodo
    where nome_evento is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif VARIABLES.template EQ "/admin/homologacao.cfm">
        <cfif len(trim(URL.preset)) AND URL.preset EQ "pendentes">
            and homologado is null
        <cfelseif len(trim(URL.preset)) AND URL.preset EQ "homologados">
            and homologado = 1
        <cfelseif len(trim(URL.preset)) AND URL.preset EQ "naohomologados">
            and homologado = 0
        </cfif>
    </cfif>
    group by id_evento, estado, cidade, nome_evento, tag, homologado, ranking, data_final
    order by total desc
</cfquery>

<cfquery name="qStatsMaratonas" dbtype="query">
    select nome_evento_agregado, sum(concluintes) total
    from qPeriodo
    where id_agrega_evento is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    and tipo_agregacao IN ('maratona','corrida')
    group by nome_evento_agregado
    order by total desc
</cfquery>

<cfquery name="qStatsCircuitos" dbtype="query">
    select nome_evento_agregado, sum(concluintes) total
    from qPeriodo
    where id_agrega_evento is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    and tipo_agregacao IN ('circuito')
    group by nome_evento_agregado
    order by total desc
</cfquery>



<cfquery name="qAgrega" cachedwithin="#CreateTimeSpan(0, 0, 3, 0)#">
    SELECT * FROM tb_agrega_eventos
    ORDER by tipo_agregacao, nome_evento_agregado
</cfquery>

<cfquery name="qAgregadores" cachedwithin="#CreateTimeSpan(0, 0, 3, 0)#">
    SELECT * FROM tb_agregadores
    ORDER by agregador_nome
</cfquery>

<cfquery name="qTema" cachedwithin="#CreateTimeSpan(0, 0, 3, 0)#">
    SELECT * FROM tb_temas
    ORDER by logo
</cfquery>



<!--- STATUS DA HOMOLOGACAO --->

<cfquery name="qStatusHomologado" dbtype="query">
    select count(*) as total from qStatsEvento
    where homologado = 1
</cfquery>

<cfquery name="qStatusNaoHomologado" dbtype="query">
    select count(*) as total from qStatsEvento
    where homologado = 0
</cfquery>

<cfset VARIABLES.totalHomologar = qStatsEvento.recordcount/>
<cfset VARIABLES.totalHomologado = len(trim(qStatusHomologado.total)) ? (qStatusHomologado.total*100)/qStatsEvento.recordcount : 0/>
<cfset VARIABLES.totalNaoHomologado = len(trim(qStatusNaoHomologado.total)) ? (qStatusNaoHomologado.total*100)/qStatsEvento.recordcount : 0/>
<cfset VARIABLES.totalFaltaHomologar = 100-VARIABLES.totalHomologado-VARIABLES.totalNaoHomologado/>
