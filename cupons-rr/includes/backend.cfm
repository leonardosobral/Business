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



<!--- WIDGETS

<cfquery name="qAdValorTotal">
    SELECT sum(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
</cfquery>

<cfquery name="qAdValorMedio">
    SELECT avg(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status <= 2
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
</cfquery>

<cfquery name="qAdCountClicks">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
</cfquery>

 --->


<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qCupons">
    SELECT cup.*
    FROM tb_cupom cup
    WHERE cup.ativo = true
    <!---cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
    </cfif--->
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qEventosCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_evento_corridas_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_evento_corridas evt ON evtcup.id_evento = evt.id_evento
    WHERE cup.ativo = true
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qCircuitosCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_evento_circuitos_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_agrega_eventos evt ON evtcup.id_agrega_evento = evt.id_agrega_evento
    WHERE cup.ativo = true
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qPaginasCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_paginas_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_paginas evt ON evtcup.id_pagina = evt.id_pagina
    WHERE cup.ativo = true
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>
