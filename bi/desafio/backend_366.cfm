<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
    with atv as ( select
    num_inscricao,
    sum(distancia) as distancia_percorrida,
    max(data_comprovante)::date as ultimo_dia,
    min(data_comprovante)::date as primeiro_dia,
    count(distinct data_comprovante::date) as dias_correndo,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '0 days') as primeiros_1_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '6 days') as primeiros_7_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '14 days') as primeiros_15_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '29 days') as primeiros_30_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '89 days') as primeiros_90_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '179 days') as primeiros_180_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '269 days') as primeiros_270_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '365 days') as primeiros_366_dias,
    (select count(distinct data_comprovante::date) from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao and data_comprovante::date between '2024-01-01'::date and '2024-01-01'::date + interval '355 days') as nodesafio,
    (select data_comprovante from desafio_366_atividades act where act.num_inscricao = atv.num_inscricao order by data_comprovante desc limit 1) as ultima_atividade,
    EXTRACT('doy' FROM '2024-12-31'::date) as dias_do_ano
    from desafio_366_atividades atv
    where  extract(year from data_comprovante) = extract(year from '2024-12-31'::date)
    group by
        num_inscricao
    )
    SELECT COALESCE(uf.nome_regiao, 'Não Informada') as regiao,
    usr.is_email_verified,
    usr.id,
    des.num_inscricao,
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
    usr.email,
    COALESCE(des.cidade, usr.cidade) as cidade,
    COALESCE(des.uf, usr.estado) as estado,
    COALESCE(usr.data_criacao, '2024-01-01') as data_criacao,
    COALESCE(des.nome, usr.name) as name,
    usr.tag_usuario,
    (select count(*) from tb_resultados where id_usuario = usr.id) as resultados,
    (select count(*) from tb_evento_corridas_checkin where id_usuario = usr.id) as checkin,
    atv.distancia_percorrida,
    atv.primeiro_dia,
    atv.ultimo_dia,
    atv.dias_correndo,
    atv.primeiros_1_dias,
    atv.primeiros_7_dias,
    atv.primeiros_15_dias,
    atv.primeiros_30_dias,
    atv.primeiros_90_dias,
    atv.primeiros_180_dias,
    atv.primeiros_270_dias,
    atv.nodesafio,
    atv.primeiros_366_dias,
    atv.dias_do_ano,
    pag.tag,
    '2024-12-31'::date - ultimo_dia::date as correu_hoje
    FROM desafio_366_inscritos des
    LEFT JOIN tb_usuarios usr ON des.id_usuario = usr.id
    LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id
    LEFT JOIN atv ON atv.num_inscricao = des.num_inscricao
    LEFT JOIN tb_uf uf ON des.uf = uf.uf
</cfquery>

<cfquery name="qCountAptos" dbtype="query">
    select count(*) as total
    from qBase
    where is_email_verified = 1 and strava_id is not null
</cfquery>

<cfquery name="qCountNovoSite" dbtype="query">
    select count(*) as total
    from qBase
    where dias_correndo is not null AND dias_correndo > 0
</cfquery>

<cfquery name="qCountTotal" dbtype="query">
    select count(*) as total
    from qBase
</cfquery>

<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    <cfif len(trim(URL.busca))>
        where name like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#ucase(URL.busca)#%"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "aptos">
        where is_email_verified = 1 and strava_id is not null
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "novosite">
        where dias_correndo is not null AND dias_correndo > 0
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
    <cfif len(trim(URL.preset)) AND URL.preset EQ "1dia">
        where primeiros_1_dias >= 1
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "7dias">
        where primeiros_7_dias >= 7
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "15dias">
        where primeiros_30_dias >= 15
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "30dias">
        where primeiros_30_dias >= 30
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "90dias">
        where primeiros_90_dias >= 90
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "180dias">
        where primeiros_180_dias >= 180
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "270dias">
        where primeiros_270_dias >= 270
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "366dias">
        where primeiros_366_dias >= 366
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "nodesafio">
        where nodesafio >= 360
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

<cfquery name="qCount1Dia" dbtype="query">
    select id
    from qPeriodo
    where primeiros_1_dias >= 1
</cfquery>

<cfquery name="qCount7Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_7_dias >= 7
</cfquery>

<cfquery name="qCount15Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_15_dias >= 15
</cfquery>

<cfquery name="qCount30Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_30_dias >= 30
</cfquery>

<cfquery name="qCount90Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_90_dias >= 90
</cfquery>

<cfquery name="qCount180Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_180_dias >= 180
</cfquery>

<cfquery name="qCount270Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_270_dias >= 270
</cfquery>

<cfquery name="qCount366Dias" dbtype="query">
    select id
    from qPeriodo
    where primeiros_366_dias >= 366
</cfquery>

<cfquery name="qCountNoDesafio" dbtype="query">
    select id
    from qPeriodo
    where nodesafio >= 356
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
    <cfif len(trim(URL.preset)) AND URL.preset EQ "nodesafio">
        order by distancia_percorrida DESC
    <cfelse>
        order by dias_correndo DESC, ultima_atividade DESC
    </cfif>
</cfquery>


<!---cfif len(trim(URL.preset)) AND URL.preset EQ "strava"--->
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

<!---/cfif--->
