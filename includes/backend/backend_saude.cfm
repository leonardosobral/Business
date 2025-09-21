<cfquery name="qCountPedidos">
    select count(*) as total
    from tb_ticketsports_pedidos
</cfquery>

<cfquery name="qCountHoje" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_pedido >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()-1#"/>
</cfquery>

<cfquery name="qCountMIF" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where mif > 0
</cfquery>

<cfquery name="qCountCheckin" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_checkin is not null
</cfquery>

<cfquery name="qCountSorteio" dbtype="query">
    select count(flag_sorteio) as total
    from qBaseInscritos
    where data_checkin is not null
    and flag_sorteio = 1
</cfquery>

<cfquery name="qCountSemCheckin" dbtype="query">
    select count(*) as total
    from qBaseInscritos
    where data_checkin is null
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
    <cfif len(trim(URL.assessoria))>
        and assessoria = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.assessoria#"/>
    </cfif>
    <cfif URL.preset EQ "treinos">
        order by presencas desc, total desc, name asc
    <cfelseif NOT len(trim(URL.periodo)) OR URL.periodo NEQ "checkin">
        order by name asc
    </cfif>
</cfquery>
