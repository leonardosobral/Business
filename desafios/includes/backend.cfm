<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "alterar_status">

    <cfquery>
        UPDATE desafios
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
        AND desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(trim(URL.desafio))#"/>
    </cfquery>

    <cflocation addtoken="false" url="/ads/#lcase(trim(URL.desafio))#"/>

</cfif>


<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    WITH atv as (
    with atividades as
    (
        select
        athlete_id,
        count(distinct frequencia_fechamento) as frequencia_fechamento
        from
            (
                select
                athlete_id,
                activity_date as frequencia_fechamento
                from tb_strava_activities act
                <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                    where activity_date between '2025-01-01'::date and '2025-12-31'::date
                <cfelse>
                    where activity_date between '2020-01-01'::date and current_date::date
                </cfif>
                AND type in ('Run','VirtualRun','TrailRun')
                AND distance >= 990
                UNION
                select
                id_athlete_donation as athlete_id,
                activity_date as frequencia_fechamento
                from tb_strava_activities act
                <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                    where activity_date between '2025-01-01'::date and '2025-12-31'::date
                <cfelse>
                    where activity_date between '2020-01-01'::date and current_date::date
                </cfif>
                and id_athlete_donation > 0
                AND type in ('Run','VirtualRun','TrailRun')
                AND distance >= 990
            ) as atv
        group by
        athlete_id
    )
    SELECT
    athlete_id,
    sum(distance) as distancia_percorrida,
    sum(total_elevation_gain) as altimetria,
    count(activity_id) as atividades,
    count(distinct activity_date::date) as dias_correndo,
    max(frequencia_fechamento) as frequencia_fechamento,
    max(activity_date::date) as data_final,
    min(activity_date::date) as data_inicial,
    max(dias_do_ano) as dias_do_ano
    FROM
    (
        SELECT
        at1.athlete_id,
        distance,
        total_elevation_gain,
        activity_id,
        activity_date::date,
        frequencia_fechamento,
        <cfif lcase(trim(URL.desafio)) EQ "desafio365">
            365 as dias_do_ano
        <cfelse>
            EXTRACT('doy' FROM current_date) as dias_do_ano
        </cfif>
        FROM tb_strava_activities at1
        inner join atividades on atividades.athlete_id = at1.athlete_id
        WHERE type in ('Run','VirtualRun','TrailRun')
        AND distance >= 990
        <cfif lcase(trim(URL.desafio)) EQ "desafio365">
            AND activity_date >= '2025-01-01'
            AND activity_date <= '2025-12-31'
            AND extract(year from start_date) = 2025
        <cfelse>
            AND activity_date >= '2020-01-01'
            --AND extract(year from start_date) = extract(year from current_date)
        </cfif>
        UNION
        SELECT
        id_athlete_donation as athlete_id,
        distance,
        total_elevation_gain,
        activity_id,
        activity_date::date,
        frequencia_fechamento,
        <cfif lcase(trim(URL.desafio)) EQ "desafio365">
            365 as dias_do_ano
        <cfelse>
            EXTRACT('doy' FROM current_date) as dias_do_ano
        </cfif>
        FROM tb_strava_activities at2
        inner join atividades on atividades.athlete_id = at2.id_athlete_donation
        WHERE type in ('Run','VirtualRun','TrailRun')
        AND distance >= 990
        <cfif lcase(trim(URL.desafio)) EQ "desafio365">
            AND activity_date >= '2025-01-01'
            AND activity_date <= '2025-12-31'
            AND extract(year from start_date) = 2025
        <cfelse>
            AND activity_date >= '2020-01-01'
            --AND extract(year from start_date) = extract(year from current_date)
        </cfif>
        AND id_athlete_donation > 0

    ) as qry1
     GROUP BY athlete_id
    )
    SELECT COALESCE(uf.nome_regiao, 'Exterior') as regiao,
    to_timestamp(usr.strava_expires_at) as strava_expires_at,
    des.status,
    des.produto,
    des.data_inscricao,
    usr.id,
    usr.ddi_usuario,
    usr.ddd_usuario,
    usr.telefone_usuario,
    usr.email,
    usr.strava_id,
    usr.strava_code,
    usr.ddi_usuario,
    usr.ddd_usuario,
    COALESCE(upper(trim(unaccent(usr.cidade))), upper(trim(unaccent(pag.cidade)))) as cidade,
    COALESCE(usr.estado, pag.uf) as estado,
    upper(COALESCE(pag.nome, usr.name)) as nome,
    COALESCE(usr.genero, usr.strava_sex) as genero,
    usr.tag_usuario,
    usr.pais,
    usr.data_statisticas,
    (select status from tb_crm where id_usuario = usr.id order by id_interacao desc limit 1) as status_crm,
    CASE
        WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') > 1 THEN 'duplicado'
        WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') = 1 THEN 'pago'
        WHEN (select count(*) from tb_transacoes where id_usuario = usr.id) > 0 THEN 'pendente'
        ELSE null
    END as status_transacao,
    atv.distancia_percorrida,
    atv.dias_correndo,
    atv.atividades,
    atv.altimetria,
    atv.frequencia_fechamento as frequencia_fechamento,
    atv.frequencia_fechamento as nodesafio,
    atv.data_final,
    atv.data_inicial,
    CASE WHEN atv.frequencia_fechamento > 1 THEN 1 ELSE 0 END as ativo,
    atv.dias_do_ano,
    pag.tag,
    pag.verificado,
    coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario
    FROM desafios des
    INNER JOIN tb_usuarios usr ON (des.id_usuario = usr.id)
    LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id and pag.tag_prefix = 'atleta'
    LEFT JOIN atv on atv.athlete_id = usr.strava_id
    LEFT JOIN tb_uf uf ON usr.estado = uf.uf
    where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(trim(URL.desafio))#"/>
</cfquery>

<cfquery name="qCountPendentes" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'I'
</cfquery>

<cfquery name="qNoDesafio" dbtype="query">
    select count(*) as total
    from qBase
    <cfif lcase(trim(URL.desafio)) EQ "desafio365">
        where frequencia_fechamento = 365
    <cfelse>
        where frequencia_fechamento = dias_do_ano
    </cfif>
    and status = 'C'
    and frequencia_fechamento is not null
</cfquery>

<cfquery name="qPendenteDesafio" dbtype="query">
    select count(*) as total
    from qBase
    where frequencia_fechamento <> dias_do_ano and status = 'C' and frequencia_fechamento is not null
</cfquery>

<cfquery name="qCountVip" dbtype="query">
    select count(*) as total
    from qBase
    where produto like '%vip%' and status = 'C'
</cfquery>

<cfquery name="qCountConfirmados" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'C'
</cfquery>

<cfquery name="qCountTotal">
    select count(*) as total
    from desafios
    where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(trim(URL.desafio))#"/>
</cfquery>

<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    <cfif len(trim(URL.busca))>
        where nome like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#ucase(URL.busca)#%"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentes">
        where status = 'I'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "nodesafio">
        where frequencia_fechamento = dias_do_ano and status = 'C' and frequencia_fechamento is not null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentedesafio">
        where frequencia_fechamento <> dias_do_ano and status = 'C' and frequencia_fechamento is not null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "vip">
        where produto like '%vip%' and status = 'C'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "confirmados">
        where status = 'C'
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
</cfquery>

<cfquery name="qCountStrava" dbtype="query">
    select *
    from qPeriodo
    where strava_code <> '' and strava_code is not null
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

<cfquery name="qStatsBase" dbtype="query">
    select *
    from qPreset
    where nome is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
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
