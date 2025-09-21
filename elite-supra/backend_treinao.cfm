<cfif isDefined("URL.id_usuario") AND isDefined("URL.status")>
    <cfquery>
        UPDATE desafios
        SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.status#"/>
        WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
    </cfquery>
    <cflocation addtoken="false" url="/bi/elite-supra"/>
</cfif>

<cfif isDefined("FORM.id_usuario") AND isDefined("FORM.obs")>
    <cfquery>
        INSERT INTO desafios_obs
        (id_usuario, id_atendente, produto, obs)
        VALUES
        (
        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_usuario#"/>,
        <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="/desafiosupra/inscricao/"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs#"/>
        )
    </cfquery>
    <cflocation addtoken="false" url="/bi/elite-supra"/>
</cfif>

<cfquery name="qBaseInscritos">
    SELECT COALESCE(uf.regiao, 'Exterior') as regiao, pag.tag as tag_usuario,
        insc.data_inscricao, insc.num_pedido, insc.status,
        COALESCE(pag.nome, usr.name) as name, usr.email,
        trim(upper(unaccent(COALESCE(pag.cidade, usr.cidade)))) as cidade,
        insc.body,
        COALESCE(pag.uf, usr.estado) as estado,
        usr.id, usr.is_email_verified, usr.strava_code, usr.strava_id, usr.assessoria,
        usr.strava_premium, usr.strava_weight, usr.strava_full_follower_count, usr.strava_full_friend_count,
        usr.strava_full_shoes, usr.strava_full_clubs,
    (select count(*) from tb_resultados where id_usuario = usr.id) as resultados,
    (select count(*) from tb_ticketsports_participantes where documento = insc.body ->>'documento') as mif,
    (select count(*) from tb_evento_corridas_checkin where id_usuario = usr.id) as checkin,
    (select count(*) from desafios_obs where id_usuario = usr.id) as obs,
    (select tempo_total from tb_resultados_obs obs
        inner join public.tb_resultados tr on obs.num_peito = tr.num_peito
            and obs.id_evento = tr.id_evento
        inner join tb_evento_corridas evt on obs.id_evento = evt.id_evento
        where obs.obs = 'Olympikus Supra'
        and evt.data_inicial >= '2025-01-01'
        and usr.id = tr.id_usuario
        order by tempo_total
        LIMIT 1) as tempo
    from desafios insc
    left join tb_usuarios usr on usr.id = insc.id_usuario
    left join tb_paginas pag ON usr.id = pag.id_usuario_cadastro
    left join tb_uf uf ON coalesce(pag.uf, usr.estado) = uf.uf
    WHERE insc.produto = '/desafiosupra/inscricao/'
    <cfif len(trim(URL.prova))>
        and body ->>'provas' like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#URL.prova#%"/>
    </cfif>
    ORDER BY usr.id
</cfquery>

<cfquery name="qCountInscritosTreino">
    select count(*) as total
    from desafios
</cfquery>

<cfquery name="qTreinoAssessorias" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#">
    select trim(unaccent(upper(tsparticipantes.body ->> 'assessoria'))) as assossoria, count(*) as total
    FROM desafios tsparticipantes
    WHERE produto = '/desafiosupra/inscricao/' and trim(unaccent(upper(tsparticipantes.body ->> 'assessoria'))) NOT IN ('NÃO POSSUO','INDIVIDUAL','NA','SEM ASSESORIA','AULSO','N/A','N/A','NAO TENHO','NÃO','SIM','NAO','-','.',' ','','NÃO TEM','NENHUMA','SEM','NAO TEM','NENHUM','AVULSO','NÃO TENHO')
    group by trim(unaccent(upper(tsparticipantes.body ->> 'assessoria')))
    order by total desc;
</cfquery>

<cfquery name="qCountPedidos">
    select count(*) as total
    from tb_ticketsports_pedidos
</cfquery>

<cfquery name="qCountHoje" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_inscricao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
</cfquery>

<cfquery name="qCount7" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_inscricao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
</cfquery>

<cfquery name="qCount28" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_inscricao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-28#"/>
</cfquery>

<cfquery name="qCountNovoSite" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where is_email_verified = 1
</cfquery>

<cfquery name="qCountTotal" dbtype="query">
    select count(*) as total
    from qBaseInscritos
</cfquery>

<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBaseInscritos
    <cfif len(trim(URL.busca))>
        where name like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#ucase(URL.busca)#%"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "checkin">
        where data_checkin is not null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "sorteados">
        where data_checkin is not null and flag_sorteio = 1
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "mif">
        where mif > 0
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "semcheckin">
        where data_checkin is null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "novosite">
        where is_email_verified = 1
    </cfif>
</cfquery>

<cfquery name="qPreset" dbtype="query">
    select *
    from qPeriodo
    <cfif len(trim(URL.preset)) AND URL.preset EQ "calendario">
        where checkin > 0
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "resultados">
        where resultados > 0
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "strava">
        where strava_code <> '' and strava_code is not null
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "assessoria">
        where assessoria <> '' and assessoria is not null
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "cidade">
        where cidade <> '' and cidade is not null
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "estado">
        where estado <> '' and estado is not null
    </cfif>
</cfquery>


<cfquery name="qCountCalendario" dbtype="query">
    select id
    from qPeriodo
    where checkin > 0
</cfquery>

<cfquery name="qCountResultados" dbtype="query">
    select id
    from qPeriodo
    where resultados > 0
</cfquery>

<cfquery name="qCountStrava" dbtype="query">
    select *
    from qPeriodo
    where strava_code <> '' and strava_code is not null
</cfquery>

<cfquery name="qCountAssessoria" dbtype="query">
    select id
    from qPeriodo
    where assessoria <> '' and assessoria is not null
</cfquery>

<cfquery name="qCountCidade" dbtype="query">
    select id
    from qPeriodo
    where cidade <> '' and cidade is not null
</cfquery>

<cfquery name="qCountEstado" dbtype="query">
    select id
    from qPeriodo
    where estado <> '' and estado is not null
</cfquery>



<cfquery name="qStatsRegiao" dbtype="query">
    select regiao, count(id) total
    from qPreset
    group by regiao
    order by total desc
</cfquery>

<cfquery name="qStatsEstado" dbtype="query">
    select estado, count(id) total
    from qPreset
    where estado is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    group by estado
    order by total desc
</cfquery>

<cfquery name="qStatsCidade" dbtype="query">
    select estado, cidade, count(id) total
    from qPreset
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
    select *
    from qPreset
    where name is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif NOT len(trim(URL.periodo)) OR URL.periodo NEQ "checkin">
        order by name asc
    </cfif>
</cfquery>


<cfif len(trim(URL.preset)) AND URL.preset EQ "strava">
    <cfquery name="qStravaPremium" dbtype="query">
        select strava_premium
        from qCountStrava
        where strava_premium = 1
    </cfquery>
    <cfquery name="qStravaWeight" dbtype="query">
        select AVG(strava_weight) as strava_weight
        from qCountStrava
        where strava_weight is not null
    </cfquery>
    <cfquery name="qStravaFollowers" dbtype="query">
        select AVG(strava_full_follower_count) as strava_full_follower_count
        from qCountStrava
        where strava_full_follower_count is not null
    </cfquery>
    <cfquery name="qStravaFriends" dbtype="query">
        select AVG(strava_full_friend_count) as strava_full_friend_count
        from qCountStrava
        where strava_full_friend_count is not null
    </cfquery>
    <cfquery name="qStravaShoes" dbtype="query">
        select strava_full_shoes
        from qCountStrava
        where strava_full_shoes is not null
    </cfquery>
    <cfset VARIABLES.shoeCount = 0/>
    <cfset VARIABLES.shoeKm = 0/>
    <cfloop query="qStravaShoes">
        <cfset VARIABLES.shoeCount = VARIABLES.shoeCount + arraylen(deserializeJSON(qStravaShoes.strava_full_shoes))/>
        <cfloop array="#deserializeJSON(qStravaShoes.strava_full_shoes)#" index="item">
            <cfset VARIABLES.shoeKm = VARIABLES.shoeKm + item.converted_distance/>
        </cfloop>
    </cfloop>
    <cfquery name="qStravaClubs" dbtype="query">
        select strava_full_clubs
        from qCountStrava
        where strava_full_clubs is not null
    </cfquery>
    <cfset VARIABLES.clubCount = 0/>
    <cfloop query="qStravaClubs">
        <cfset VARIABLES.clubCount = VARIABLES.clubCount + arraylen(deserializeJSON(qStravaClubs.strava_full_clubs))/>
    </cfloop>

</cfif>
