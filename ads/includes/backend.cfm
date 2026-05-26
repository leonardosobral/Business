<!--- INCLUIR CAMPANHA --->

<cfset VARIABLES.adsRestrictByFornecedor = true/>
<cfset VARIABLES.adsEventosFornecedorIds = "0"/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.adsRestrictByFornecedor = false/>
</cfif>

<cfif isDefined("qEventosFornecedor") AND qEventosFornecedor.recordcount>
    <cfset VARIABLES.adsEventosFornecedorIds = ValueList(qEventosFornecedor.id_evento)/>
</cfif>

<cfif isDefined("form.acao") AND form.acao EQ "incluir_campanha">

    <cfquery name="qAdCheckEvento">
        select id_evento from tb_evento_corridas where tag ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(replace(FORM.evento, 'https://roadrunners.run/evento/',''),'/','','ALL')#"/>
    </cfquery>

    <cfif NOT qAdCheckEvento.recordcount OR (VARIABLES.adsRestrictByFornecedor AND NOT listFind(VARIABLES.adsEventosFornecedorIds, qAdCheckEvento.id_evento))>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

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

    <cfif NOT isDefined("FORM.id_ad_evento") OR NOT isNumeric(FORM.id_ad_evento)>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

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
        <cfif VARIABLES.adsRestrictByFornecedor>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_campanha" AND isDefined("URL.campanha") AND isNumeric(URL.campanha) AND isDefined("URL.status") AND isNumeric(URL.status)>

    <cfquery>
        UPDATE tb_ad_eventos
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.campanha#"/>
        <cfif VARIABLES.adsRestrictByFornecedor>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>



<!--- WIDGETS --->

<cfquery name="qAdValorTotal">
    SELECT sum(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdValorMedio">
    SELECT avg(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status <= 2
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountClicks">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>


<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAdsBase">
    WITH
    ad_views AS (
        SELECT
            id_ad as id_evento,
            count(*) as views
        FROM tb_ad_log
        WHERE tb_ad_log.status <= 2
        GROUP BY id_ad
    ),
    ad_views_usuarios AS (
        SELECT
            id_ad as id_evento,
            count(*) as views
        FROM tb_ad_log
        WHERE tb_ad_log.status <= 2
        AND id_usuario is not null
        GROUP BY id_ad
    ),
    ad_clicks AS (
        select
        id_ad as id_evento,
        count(*) as clicks,
        avg(valor_ad) as cpc_medio,
        sum(valor_ad) as custo_total
        FROM tb_ad_log
        WHERE status = 2
        group by id_ad
    ),
    ad_clicks_usuarios AS (
        select
        id_ad as id_evento,
        count(*) as clicks,
        avg(valor_ad) as cpc_medio,
        sum(valor_ad) as custo_total
        FROM tb_ad_log
        WHERE status = 2
        AND id_usuario is not null
        group by id_ad
    )
    SELECT evt.*,
           ad.id_ad_evento,
           ad.status,
           ad.cpc_max,
           ad.qualidade,
           ad.limite_diario,
           ad.limite_ad,
           ad.escopo,
           ad.locais,
           ad.inicio_ad,
           ad.final_ad,
           ad_views.views,
           ad_views_usuarios.views as views_usuarios,
           ad_clicks.clicks,
           ad_clicks.cpc_medio,
           ad_clicks.custo_total,
           ad_clicks_usuarios.clicks as clicks_usuarios,
           ad_clicks_usuarios.cpc_medio as cpc_medio_usuarios,
           ad_clicks_usuarios.custo_total as custo_total_usuarios,
           (ad.qualidade * ad.cpc_max) as ad_rank
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    LEFT JOIN ad_views on ad_views.id_evento = ad.id_ad_evento
    LEFT JOIN ad_views_usuarios on ad_views_usuarios.id_evento = ad.id_ad_evento
    LEFT JOIN ad_clicks on ad_clicks.id_evento = ad.id_ad_evento
    LEFT JOIN ad_clicks_usuarios on ad_clicks_usuarios.id_evento = ad.id_ad_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif VARIABLES.adsRestrictByFornecedor>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosFornecedorIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qEventosAds" dbtype="query">
    select * from qEventosAdsBase
    where status < 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsPausados" dbtype="query">
    select * from qEventosAdsBase
    where status = 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsFinalizados" dbtype="query">
    select * from qEventosAdsBase
    where status = 4
    order by clicks desc, views desc
</cfquery>
