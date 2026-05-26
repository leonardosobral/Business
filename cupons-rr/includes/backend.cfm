<!--- INCLUIR CAMPANHA --->

<cfset VARIABLES.cuponsRrRestrictByFornecedor = true/>
<cfset VARIABLES.cuponsRrEventosFornecedorIds = "0"/>
<cfset VARIABLES.cuponsRrPaginaIds = "0"/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.cuponsRrRestrictByFornecedor = false/>
</cfif>

<cfif isDefined("qEventosFornecedor") AND qEventosFornecedor.recordcount AND len(trim(ValueList(qEventosFornecedor.id_evento)))>
    <cfset VARIABLES.cuponsRrEventosFornecedorIds = ValueList(qEventosFornecedor.id_evento)/>
</cfif>

<cfif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.id_pagina") AND len(trim(ValueList(qPerfil.id_pagina)))>
    <cfset VARIABLES.cuponsRrPaginaIds = ValueList(qPerfil.id_pagina)/>
</cfif>

<cfif isDefined("form.acao") AND form.acao EQ "incluir_campanha">

    <cfquery name="qAdCheckEvento">
        select id_evento from tb_evento_corridas where tag ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(replace(FORM.evento, 'https://roadrunners.run/evento/',''),'/','','ALL')#"/>
    </cfquery>

    <cfif NOT qAdCheckEvento.recordcount OR (VARIABLES.cuponsRrRestrictByFornecedor AND NOT listFind(VARIABLES.cuponsRrEventosFornecedorIds, qAdCheckEvento.id_evento))>
        <cflocation addtoken="false" url="/cupons-rr/"/>
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

    <cflocation addtoken="false" url="/cupons-rr/"/>

</cfif>

<!--- EDITAR CAMPANHA --->

<cfif isDefined("form.acao") AND form.acao EQ "editar_campanha">

    <cfif NOT isDefined("FORM.id_ad_evento") OR NOT isNumeric(FORM.id_ad_evento)>
        <cflocation addtoken="false" url="/cupons-rr/"/>
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
        <cfif VARIABLES.cuponsRrRestrictByFornecedor>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/cupons-rr/"/>

</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_campanha" AND isDefined("URL.campanha") AND isNumeric(URL.campanha) AND isDefined("URL.status") AND isNumeric(URL.status)>

    <cfquery>
        UPDATE tb_ad_eventos
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.campanha#"/>
        <cfif VARIABLES.cuponsRrRestrictByFornecedor>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/cupons-rr/"/>

</cfif>



<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qCupons">
    SELECT cup.*
    FROM tb_cupom cup
    WHERE cup.ativo = true
    <cfif VARIABLES.cuponsRrRestrictByFornecedor>
        AND (
            cup.id_cupom IN (
                SELECT id_cupom
                FROM tb_evento_corridas_cupom
                WHERE id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
            )
            OR cup.id_cupom IN (
                SELECT circup.id_cupom
                FROM tb_evento_circuitos_cupom circup
                WHERE circup.id_agrega_evento IN (
                    SELECT DISTINCT id_agrega_evento
                    FROM tb_evento_corridas
                    WHERE id_agrega_evento IS NOT NULL
                      AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
                )
            )
            OR cup.id_cupom IN (
                SELECT id_cupom
                FROM tb_paginas_cupom
                WHERE id_pagina IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrPaginaIds#" list="true"/>)
            )
        )
    </cfif>
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qEventosCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_evento_corridas_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_evento_corridas evt ON evtcup.id_evento = evt.id_evento
    WHERE cup.ativo = true
    <cfif VARIABLES.cuponsRrRestrictByFornecedor>
        AND evtcup.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
    </cfif>
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qCircuitosCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_evento_circuitos_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_agrega_eventos evt ON evtcup.id_agrega_evento = evt.id_agrega_evento
    WHERE cup.ativo = true
    <cfif VARIABLES.cuponsRrRestrictByFornecedor>
        AND evtcup.id_agrega_evento IN (
            SELECT DISTINCT id_agrega_evento
            FROM tb_evento_corridas
            WHERE id_agrega_evento IS NOT NULL
              AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrEventosFornecedorIds#" list="true"/>)
        )
    </cfif>
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>

<cfquery name="qPaginasCupons">
    SELECT cup.*, evtcup.*, evt.*
    FROM tb_paginas_cupom evtcup
    INNER JOIN tb_cupom cup ON evtcup.id_cupom = cup.id_cupom
    INNER JOIN tb_paginas evt ON evtcup.id_pagina = evt.id_pagina
    WHERE cup.ativo = true
    <cfif VARIABLES.cuponsRrRestrictByFornecedor>
        AND evtcup.id_pagina IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cuponsRrPaginaIds#" list="true"/>)
    </cfif>
    ORDER BY cup.data_expiracao DESC NULLS FIRST
</cfquery>
