<!--- INCLUIR usuario --->

<cfif isDefined("form.acao") AND form.acao EQ "incluir_usuario">

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

    <cfquery name="qAdIncluirusuario">
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

</cfif>

<!--- EDITAR usuario --->

<cfif isDefined("form.acao") AND form.acao EQ "editar_usuario">

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

    <cfquery name="qAdIncluirUsuario">
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

</cfif>

<!--- ALTERAR STATUS DA usuario --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_usuario">

    <cfquery>
        UPDATE tb_usuarios
        SET is_partner = true
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.usuario#"/>
    </cfquery>

</cfif>


<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qUsuariosBase">
    select usr.*,
    usr.partner_info ->> 'perfil' as perfil,
    usr.partner_info ->> 'celular' as celular,
    usr.partner_info ->> 'documento' as documento,
    usr.partner_info ->> 'nome_comercial' as nome_comercial
    from tb_usuarios usr where partner_info is not null
    or is_partner = true
    <!---
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList(qEventosFornecedor.id_evento)#" list="true"/>)
    --->
</cfquery>

<cfquery name="qUsuariosBaseAprovar" dbtype="query">
    select * from qUsuariosBase
    where is_partner = 0
    order by name
</cfquery>

<cfquery name="qUsuariosBaseCompletar" dbtype="query">
    select * from qUsuariosBase
    where partner_info is null
    order by name
</cfquery>

<cfquery name="qUsuariosBaseAssessoria" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'assessoria'
    order by name
</cfquery>

<cfquery name="qUsuariosBaseTime" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'timer'
    order by name
</cfquery>

<cfquery name="qUsuariosBaseMidia" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'midia'
    order by name
</cfquery>

<cfquery name="qUsuariosBaseAgencia" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'agencia'
    order by name
</cfquery>

<cfquery name="qUsuariosBaseMarca" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'marca'
    order by name
</cfquery>

<cfquery name="qUsuariosBaseOrg" dbtype="query">
    select * from qUsuariosBase
    where perfil = 'org'
    order by name
</cfquery>
