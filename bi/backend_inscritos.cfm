<cfquery name="qBaseInscritos" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
    SELECT COALESCE(uf.regiao, 'Exterior') as regiao, pag.tag as tag_usuario,
        tkt.data_pedido,
        COALESCE(tkt.nome, usr.name) as name,
        COALESCE(tkt.email, usr.email) as email,
        COALESCE(tkt.cidade, usr.cidade) as cidade,
        COALESCE(tkt.estado, usr.estado) as estado,
        usr.id, usr.is_email_verified, usr.strava_code, usr.strava_id, usr.assessoria,
        usr.strava_premium, usr.strava_weight, usr.strava_full_follower_count, usr.strava_full_friend_count,
        usr.strava_full_shoes, usr.strava_full_clubs,
    (select count(*) from tb_resultados where id_usuario = usr.id) as resultados,
    (select count(*) from tb_evento_corridas_checkin where id_usuario = usr.id) as checkin
    from tb_ticketsports_participantes tkt
    left join tb_usuarios usr on usr.email = (tkt.body ->> 'email')::varchar
    left join tb_uf uf ON coalesce(tkt.estado, usr.estado) = uf.uf
    left join tb_paginas pag ON usr.id = pag.id_usuario_cadastro
    WHERE cod_evento = '70020'
</cfquery>

<cfquery name="qCountPedidos">
    select count(*) as total
    from tb_ticketsports_pedidos
</cfquery>

<cfquery name="qCountHoje" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
</cfquery>

<cfquery name="qCount7" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
</cfquery>

<cfquery name="qCount28" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-28#"/>
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
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "24horas">
        where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "7dias">
        where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-7#"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "28dias">
        where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-28#"/>
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
    order by data_pedido desc
</cfquery>


<cfif len(trim(URL.periodo)) AND URL.periodo EQ "novosite">
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
