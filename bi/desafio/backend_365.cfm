<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
     WITH atv as (
        SELECT
        athlete_id,
        sum(distance) as distancia_percorrida,
        max(start_date)::date as ultimo_dia,
        min(start_date)::date as primeiro_dia,
        sum(total_elevation_gain) as altimetria,
        count(activity_id) as atividades,
        count(distinct activity_date::date) as dias_correndo,
        (select count(distinct activity_date) from tb_strava_activities act where act.athlete_id = atv.athlete_id and activity_date between '2025-01-01'::date and '2025-01-01'::date + interval '0 days') as primeiros_1_dias,
        (select count(distinct activity_date) from tb_strava_activities act where act.athlete_id = atv.athlete_id and activity_date between '2025-01-01'::date and '2025-01-01'::date + interval '6 days') as primeiros_7_dias,
        (select count(distinct activity_date) from tb_strava_activities act where act.athlete_id = atv.athlete_id and activity_date between '2025-01-01'::date and '2025-01-01'::date + interval '14 days') as primeiros_15_dias,
        (select count(distinct activity_date) from tb_strava_activities act where act.athlete_id = atv.athlete_id and activity_date between '2025-01-01'::date and '2025-01-01'::date + interval '10 days') as nodesafio,
        (select start_date from tb_strava_activities act where act.athlete_id = atv.athlete_id order by start_date desc limit 1) as ultima_atividade,
        EXTRACT('doy' FROM current_date) as dias_do_ano
        FROM tb_strava_activities atv
        WHERE (type = 'Run' OR type = 'VirtualRun' OR type = 'TrailRun')
        AND distance >= 990
        AND activity_date >= '2025-01-01'
        AND extract(year from start_date) = extract(year from current_date)
        GROUP BY athlete_id
    )
    SELECT COALESCE(uf.nome_regiao, 'Exterior') as regiao,
    des.status,
    des.produto,
    des.num_pedido,
    usr.is_email_verified,
    usr.id,
    atv.ultima_atividade,
    usr.strava_code,
    to_timestamp(usr.strava_expires_at) as strava_expires_at,
    usr.strava_premium,
    usr.strava_weight,
    usr.strava_full_follower_count,
    usr.strava_full_friend_count,
    usr.strava_full_shoes,
    usr.strava_full_clubs,
    usr.strava_id,
    usr.email,
    usr.ddi_usuario,
    usr.ddd_usuario,
    usr.telefone_usuario,
    COALESCE(upper(trim(pag.cidade)), upper(trim(usr.cidade))) as cidade,
    COALESCE(pag.uf, usr.estado) as estado,
    COALESCE(usr.data_criacao, '2024-01-01') as data_criacao,
    COALESCE(pag.nome, usr.name) as nome,
    COALESCE(usr.genero, usr.strava_sex) as genero,
    usr.tag_usuario,
    (select count(*) from tb_resultados where id_usuario = usr.id) as resultados,
    (select count(*) from tb_evento_corridas_checkin where id_usuario = usr.id) as checkin,
    (select status from tb_crm where id_usuario = usr.id order by id_interacao desc limit 1) as status_crm,
    <!---(select tb2.body::jsonb ->'data'->>'status'
        from  tb_webhook tb2
        where referencia = 'pagarme'
        and body::jsonb ->'data'->'customer'->>'email' = usr.email
        order by call_date desc limit 1) as status_pagamento,--->
    usr.pais,
    atv.distancia_percorrida,
    atv.primeiro_dia,
    atv.ultimo_dia,
    atv.dias_correndo,
    atv.atividades,
    atv.altimetria,
    atv.primeiros_1_dias,
    atv.primeiros_7_dias,
    0 as primeiros_15_dias,
    0 as primeiros_30_dias,
    0 as primeiros_90_dias,
    0 as primeiros_180_dias,
    0 as primeiros_270_dias,
    0 as primeiros_365_dias,
    atv.nodesafio,
    atv.dias_do_ano,
    pag.tag,
    current_date::date - ultimo_dia::date as correu_hoje,
    pag.verificado,
    coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario
    FROM desafios des
    INNER JOIN tb_usuarios usr ON (des.id_usuario = usr.id)
    LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id and pag.tag_prefix = 'atleta'
    LEFT JOIN atv on atv.athlete_id = usr.strava_id
    LEFT JOIN tb_uf uf ON usr.estado = uf.uf
    WHERE des.desafio = 'desafio365'
</cfquery>

<cfquery name="qCountHoje" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'I'
</cfquery>

<cfquery name="qNoDesafio" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'C'
    and dias_correndo is not null
    AND (dias_do_ano-dias_correndo < 2)
</cfquery>

<cfquery name="qCountvip" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'C'
    and produto = 'inscricao365vip'
    and strava_id is not null
</cfquery>

<cfquery name="qCountNovoSite" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'C'
</cfquery>

<cfquery name="qCountTotal">
    select count(*) as total
    from desafios
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
        where status = 'C'
        and dias_correndo is not null AND (dias_do_ano-dias_correndo < 2)
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "vip">
        where status = 'C' and produto = 'inscricao365vip' and strava_id is not null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "novosite">
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
    <cfif len(trim(URL.preset)) AND URL.preset EQ "30dias">
        where primeiros_30_dias >= 30
    </cfif>
</cfquery>

<cfquery name="qCountStrava" dbtype="query">
    select *
    from qPeriodo
    where strava_code <> '' and strava_code is not null
</cfquery>

<cfquery name="qCount30Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_30_dias >= 30
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
    order by ultima_atividade desc
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
