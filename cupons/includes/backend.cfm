<!--- INCLUIR CAMPANHA --->

<cfif isDefined("form.acao") AND form.acao EQ "incluir_campanha">

    <cfquery name="qAdCheckEvento">
        select id_evento from tb_evento_corridas where tag ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(replace(FORM.evento, 'https://roadrunners.run/evento/',''),'/','','ALL')#"/>
    </cfquery>

    <cfset VARIABLES.locais = {}/>
    <cfif isDefined("FORM.locais") and len(trim(FORM.locais))>
        <cfset arrEstados = listToArray(FORM.locais)/>
        <cfif arraylen(arrEstados) EQ 27>
            <cfset VARIABLES.locais["nacional"] = true/>
        <cfelse>
            <cfset VARIABLES.locais["nacional"] = false/>
        </cfif>
        <cfset VARIABLES.locais["estados"] = arrEstados/>
    </cfif>

    <cfset VARIABLES.escopo = ""/>
    <cfif isDefined("FORM.escopo") and len(trim(FORM.escopo))>
        <cfset VARIABLES.escopo = FORM.escopo/>
    </cfif>

    <cfset VARIABLES.inicio_ad = ""/>
    <cfset VARIABLES.final_ad = ""/>

    <cfif isDefined("FORM.datas") and len(trim(FORM.datas))>
        <cfset FORM.datas = listtoarray(FORM.datas, ' - ')/>
        <cfif arraylen(FORM.datas) GT 0>
            <cfset VARIABLES.inicio_ad = FORM.datas[1]/>
        </cfif>
        <cfif arraylen(FORM.datas) GT 1>
            <cfset VARIABLES.final_ad = FORM.datas[2]/>
        </cfif>
    </cfif>

    <cfquery name="qAdIncluirCampanha">
        insert into tb_ad_eventos
        (id_evento, escopo, cpc_max, limite_diario, limite_ad, inicio_ad, final_ad, locais)
        values
        (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qAdCheckEvento.id_evento#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.escopo#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.cpc_max#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_diario#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_ad#"/>,
            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.inicio_ad#" null="#len(trim(VARIABLES.inicio_ad)) EQ 0#"/>,
            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.final_ad#" null="#len(trim(VARIABLES.final_ad)) EQ 0#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.locais)#"/>::jsonb
        )
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- EDITAR CAMPANHA --->

<cfif isDefined("form.acao") AND form.acao EQ "editar_campanha">

    <cfset VARIABLES.locais = {}/>
    <cfif isDefined("FORM.locais") and len(trim(FORM.locais))>
        <cfset arrEstados = listToArray(FORM.locais)/>
        <cfif arraylen(arrEstados) EQ 27>
            <cfset VARIABLES.locais["nacional"] = true/>
        <cfelse>
            <cfset VARIABLES.locais["nacional"] = false/>
        </cfif>
        <cfset VARIABLES.locais["estados"] = arrEstados/>
    </cfif>

    <cfset VARIABLES.escopo = ""/>
    <cfif isDefined("FORM.escopo") and len(trim(FORM.escopo))>
        <cfset VARIABLES.escopo = FORM.escopo/>
    </cfif>

    <cfset VARIABLES.inicio_ad = ""/>
    <cfset VARIABLES.final_ad = ""/>

    <cfif isDefined("FORM.datas") and len(trim(FORM.datas))>
        <cfset FORM.datas = listtoarray(FORM.datas, ' - ')/>
        <cfif arraylen(FORM.datas) GT 0>
            <cfset VARIABLES.inicio_ad = FORM.datas[1]/>
        </cfif>
        <cfif arraylen(FORM.datas) GT 1>
            <cfset VARIABLES.final_ad = FORM.datas[2]/>
        </cfif>
    </cfif>

    <cfquery name="qAdIncluirCampanha">
        UPDATE tb_ad_eventos
        SET escopo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.escopo#"/>,
            cpc_max = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.cpc_max#"/>,
            limite_diario = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_diario#"/>,
            limite_ad = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_ad#"/>,
            inicio_ad = <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.inicio_ad#" null="#len(trim(VARIABLES.inicio_ad)) EQ 0#"/>,
            final_ad = <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.final_ad#" null="#len(trim(VARIABLES.final_ad)) EQ 0#"/>,
            locais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.locais)#"/>::jsonb
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_ad_evento#"/>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_campanha">

    <cfquery>
        UPDATE tb_ad_eventos
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.campanha#"/>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>



<!--- QUERY BASE --->

<cfquery name="qCuponsBase">
    select case when (trim(tsorders.body ->> 'tituloCupom')) <> '' then (trim(tsorders.body ->> 'tituloCupom')) else 'MIF Orgânico' end as tituloCupom,
    sum(replace(tsorders.body ->> 'valorUnitario', ',', '.')::numeric) as vendas,
    count(*) as pedidos,
    count(DISTINCT tsorders.data_pedido::date) as dias,
    (sum(replace(tsorders.body ->> 'valorUnitario', ',', '.')::numeric)/count(*)) as ticket_medio,
    (sum(replace(tsorders.body ->> 'valorRepasse', ',', '.')::numeric)/count(*)) as ticket_medio_repasse,
    (sum(replace(tsorders.body ->> 'valorRepasse', ',', '.')::numeric))/(select count(DISTINCT internal.data_pedido::date) from tb_ticketsports_participantes internal where (internal.body ->> 'tituloCupom') = '' and internal.data_pedido::date >= '2025-10-08' and internal.cod_evento = '72611') as media_dia,
    sum(replace(tsorders.body ->> 'valorDescontoCupom', ',', '.')::numeric) as desconto_cupom,
    sum(replace(tsorders.body ->> 'valorTaxa', ',', '.')::numeric) as taxas,
    sum(replace(tsorders.body ->> 'valorRepasse', ',', '.')::numeric) as repasse,
    (sum(replace(tsorders.body ->> 'valorRepasse', ',', '.')::numeric)/10) as cashback
    from tb_ticketsports_participantes tsorders
    inner join public.tb_ticketsports_pedidos ttp on tsorders.numero_pedido = ttp.numero_pedido
    where (tsorders.body ->> 'tituloCupom') <> '1' and tsorders.cod_evento = '72611'
    and trim(ttp.body ->> 'status') = 'Pago'
    --and tsorders.data_pedido::date >= '2025-10-08'
    --and tsorders.data_pedido::date < '2025-04-09'
    group by (tsorders.body ->> 'tituloCupom')
    having sum(replace(tsorders.body ->> 'valorRepasse', ',', '.')::double precision) > 0
    order by vendas desc;
</cfquery>

<cfquery name="qCuponsInflu" dbtype="query">
    SELECT *
    FROM qCuponsBase
    WHERE titulocupom like '%Influ%'
    OR titulocupom like '%cashback%'
</cfquery>

<cfquery name="qCuponsAssessoria" dbtype="query">
    SELECT *
    FROM qCuponsBase
    WHERE titulocupom NOT like '%Influ%'
    AND titulocupom NOT like '%cashback%'
    AND titulocupom NOT like '%Orgânico%'
    AND titulocupom NOT like '%Sports Week%'
    AND titulocupom NOT like '%PCD%'
    AND titulocupom NOT like '%Benefício%'
</cfquery>


<!--- WIDGETS --->

<cfquery name="qAdValorTotal" dbtype="query">
    SELECT sum(vendas) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qAdValorMedio" dbtype="query">
    SELECT avg(ticket_medio) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qAdCountViews" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qAdCountClicks" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qAdCountAds" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>


<cfquery name="qEventosAds" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qEventosAdsPausados" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>

<cfquery name="qEventosAdsFinalizados" dbtype="query">
    SELECT sum(pedidos) as total
    FROM qCuponsBase
</cfquery>
