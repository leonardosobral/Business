<!--- INCLUIR CAMPANHA --->

<cfset VARIABLES.adsRestrictByConta = true/>
<cfset VARIABLES.adsEventosContaIds = "0"/>
<cfset VARIABLES.adsEventosOperacaoIds = "0"/>
<cfset VARIABLES.adsEffectiveIsAdmin = false/>
<cfset VARIABLES.adsCanOperate = false/>
<cfset VARIABLES.adsVoucherColumnsReady = false/>
<cfset VARIABLES.adsCreditBalance = 0/>
<cfset VARIABLES.adsCreditTotal = 0/>
<cfset VARIABLES.adsCreditSpent = 0/>
<cfset qAdVoucherCredit = QueryNew("credito_total,consumo_total,saldo_total")/>

<cftry>
    <cfquery name="qAdsVoucherColumnCheck">
        SELECT table_name,
               column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_vouchers"/>
          AND column_name IN (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="id_conta"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="credito_disponivel"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="data_resgate"/>
          )
    </cfquery>

    <cfset VARIABLES.adsVoucherColumnNames = ValueList(qAdsVoucherColumnCheck.column_name)/>
    <cfset VARIABLES.adsVoucherColumnsReady = ListFindNoCase(VARIABLES.adsVoucherColumnNames, "id_conta")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "credito_disponivel")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "data_resgate")/>

    <cfcatch type="any">
        <cfset VARIABLES.adsVoucherColumnsReady = false/>
    </cfcatch>
</cftry>

<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfset VARIABLES.adsEffectiveIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.adsEffectiveIsAdmin = true/>
</cfif>

<cfif VARIABLES.adsEffectiveIsAdmin>
    <cfset VARIABLES.adsRestrictByConta = false/>
    <cfset VARIABLES.adsCanOperate = true/>
</cfif>

<cfif isDefined("qEventosConta") AND qEventosConta.recordcount>
    <cfset VARIABLES.adsEventosContaIds = ValueList(qEventosConta.id_evento)/>
</cfif>

<cfif isDefined("qEventosContaOperacao") AND qEventosContaOperacao.recordcount>
    <cfset VARIABLES.adsEventosOperacaoIds = ValueList(qEventosContaOperacao.id_evento)/>
    <cfset VARIABLES.adsCanOperate = true/>
</cfif>

<cfif VARIABLES.adsVoucherColumnsReady>
    <cfquery name="qAdVoucherCredit">
        WITH voucher_credit AS (
            SELECT coalesce(sum(credito_disponivel), 0) AS credito_total
            FROM tb_ad_vouchers
            WHERE status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>
              AND data_resgate IS NOT NULL
            <cfif VARIABLES.adsRestrictByConta>
              AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
            </cfif>
        ),
        ad_spend AS (
            SELECT coalesce(sum(log.valor_ad), 0) AS consumo_total
            FROM tb_ad_log log
            INNER JOIN tb_ad_eventos ad ON log.id_ad = ad.id_ad_evento
            INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
            WHERE log.status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>
            <cfif VARIABLES.adsRestrictByConta>
              AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
            </cfif>
        )
        SELECT voucher_credit.credito_total,
               ad_spend.consumo_total,
               greatest(voucher_credit.credito_total - ad_spend.consumo_total, 0) AS saldo_total
        FROM voucher_credit, ad_spend
    </cfquery>

    <cfif qAdVoucherCredit.recordcount>
        <cfset VARIABLES.adsCreditTotal = val(qAdVoucherCredit.credito_total)/>
        <cfset VARIABLES.adsCreditSpent = val(qAdVoucherCredit.consumo_total)/>
        <cfset VARIABLES.adsCreditBalance = val(qAdVoucherCredit.saldo_total)/>
    </cfif>
</cfif>

<cfset qAdsEventosPermitidos = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado")/>
<cfif VARIABLES.adsRestrictByConta AND VARIABLES.adsEventosOperacaoIds NEQ "0">
    <cfquery name="qAdsEventosPermitidos">
        SELECT id_evento,
               nome_evento,
               tag,
               data_inicial,
               data_final,
               cidade,
               estado
        FROM tb_evento_corridas
        WHERE ativo = true
          AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
        ORDER BY data_final DESC NULLS LAST, nome_evento
    </cfquery>
</cfif>

<cfif isDefined("form.acao") AND form.acao EQ "incluir_campanha">

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND VARIABLES.adsCreditBalance LTE 0>
        <cflocation addtoken="false" url="/ads/?erro=sem_credito"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND isDefined("FORM.limite_ad")
        AND len(trim(FORM.limite_ad))
        AND val(REReplace(FORM.limite_ad, ",", ".", "all")) GT VARIABLES.adsCreditBalance>
        <cflocation addtoken="false" url="/ads/?erro=credito_insuficiente"/>
    </cfif>

    <cfset qAdCheckEvento = QueryNew("id_evento")/>

    <cfif isDefined("FORM.id_evento") AND len(trim(FORM.id_evento)) AND isNumeric(FORM.id_evento)>
        <cfquery name="qAdCheckEvento">
            SELECT id_evento
            FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
              AND ativo = true
            LIMIT 1
        </cfquery>
    <cfelseif isDefined("FORM.evento") AND len(trim(FORM.evento))>
        <cfset VARIABLES.adsEventoReferencia = trim(FORM.evento)/>
        <cfset VARIABLES.adsEventoReferencia = replaceNoCase(VARIABLES.adsEventoReferencia, "https://roadrunners.run/evento/", "")/>
        <cfset VARIABLES.adsEventoReferencia = replaceNoCase(VARIABLES.adsEventoReferencia, "http://roadrunners.run/evento/", "")/>
        <cfset VARIABLES.adsEventoReferencia = listFirst(VARIABLES.adsEventoReferencia, "/?##")/>

        <cfquery name="qAdCheckEvento">
            SELECT id_evento
            FROM tb_evento_corridas
            WHERE tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsEventoReferencia#"/>
              AND ativo = true
            LIMIT 1
        </cfquery>
    </cfif>

    <cfif NOT qAdCheckEvento.recordcount OR (VARIABLES.adsRestrictByConta AND NOT listFind(VARIABLES.adsEventosOperacaoIds, qAdCheckEvento.id_evento))>
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

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND isDefined("FORM.limite_ad")
        AND len(trim(FORM.limite_ad))
        AND val(REReplace(FORM.limite_ad, ",", ".", "all")) GT VARIABLES.adsCreditBalance>
        <cflocation addtoken="false" url="/ads/?erro=credito_insuficiente"/>
    </cfif>

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
        <cfif VARIABLES.adsRestrictByConta>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_campanha" AND isDefined("URL.campanha") AND isNumeric(URL.campanha) AND isDefined("URL.status") AND isNumeric(URL.status)>

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfquery>
        UPDATE tb_ad_eventos
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.campanha#"/>
        <cfif VARIABLES.adsRestrictByConta>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
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
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdValorMedio">
    SELECT avg(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status <= 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountClicks">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
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
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
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
