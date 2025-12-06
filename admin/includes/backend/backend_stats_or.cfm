<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#">
    select uf.regiao, cor.id_evento, cor.estado, cor.cidade, cor.nome_evento, cor.tag, cor.data_inicial,
    agr.nome_evento_agregado, agr.tipo_agregacao, cor.id_agrega_evento,
    log.log_timestamp
    from tb_log log
    inner join tb_evento_corridas cor ON cor.id_evento = log.log_item_id::integer
    left join tb_uf uf ON cor.estado = uf.uf
    left join tb_agrega_eventos agr ON cor.id_agrega_evento = agr.id_agrega_evento
    where log.log_item = 'evento'
    <cfif URL.preset EQ "bot">
        and (log_user_agent ilike '%bot%' OR  log_user_agent ilike '%crawler%')
    <cfelse>
        and log_user_agent NOT ilike '%bot%' and log_user_agent NOT ilike '%crawler%'
    </cfif>
    AND log.log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
    and log.site = 'OR'
</cfquery>

<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    <cfif len(trim(URL.preset)) AND URL.preset EQ "hoje">
        where log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#lsDateFormat(now(), 'yyyy-mm-dd')# 03:00:00"/>
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "24horas">
        where log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "7dias">
        where log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "30dias">
        where log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-30#"/>
    </cfif>
</cfquery>

<cfquery name="qCountHoje" dbtype="query">
    select count(*) as total
    from qBase
    where log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
</cfquery>

<cfquery name="qCount7" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
    select count(*) as total
    from tb_log log
    where log.log_item = 'evento'
    and log.site = 'OR'
    AND log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    <cfif URL.preset EQ "bot">
        and (log_user_agent ilike '%bot%' OR  log_user_agent ilike '%crawler%')
    <cfelse>
        and log_user_agent NOT ilike '%bot%' and log_user_agent NOT ilike '%crawler%'
    </cfif>
</cfquery>

<cfquery name="qCount30" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
    select count(*) as total
    from tb_log log
    where log.log_item = 'evento'
    and log.site = 'OR'
    AND log_timestamp >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-30#"/>
    <cfif URL.preset EQ "bot">
        and (log_user_agent ilike '%bot%' OR  log_user_agent ilike '%crawler%')
    <cfelse>
        and log_user_agent NOT ilike '%bot%' and log_user_agent NOT ilike '%crawler%'
    </cfif>
</cfquery>

<cfquery name="qCountTotal" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
    select count(*) as total
    from tb_log log
    where log.log_item = 'evento'
    and log.site = 'OR'
    <cfif URL.preset EQ "bot">
        and (log_user_agent ilike '%bot%' OR  log_user_agent ilike '%crawler%')
    <cfelse>
        and log_user_agent NOT ilike '%bot%' and log_user_agent NOT ilike '%crawler%'
    </cfif>
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
    select id_evento, estado, cidade, nome_evento, tag, data_inicial, count(id_evento) total
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
    group by id_evento, estado, cidade, nome_evento, tag, data_inicial
    order by total desc
</cfquery>

<cfquery name="qStatsMaratonas" dbtype="query">
    select nome_evento_agregado, count(id_evento) total
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
    select nome_evento_agregado, count(id_evento) total
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
