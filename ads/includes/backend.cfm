<!--- WIDGETS --->

<cfquery name="qAdValorTotal">
    SELECT sum(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
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
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    <cfif NOT qPerfil.is_admin>
        WHERE evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
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
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
</cfquery>

<!--- QUERY UFs --->

<cfquery name="qAdUFs">
    SELECT * from tb_uf
    ORDER BY uf
</cfquery>

<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAds">
    SELECT evt.*, ad.id_ad_evento,
    ad.cpc_max, ad.qualidade,
    (SELECT count(*) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento) as views,
    (SELECT count(*) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as clicks,
    (SELECT avg(valor_ad) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as cpc_medio,
    (SELECT sum(valor_ad) FROM tb_ad_log log WHERE log.id_ad = ad.id_ad_evento AND status = 2) as custo_total,
    (ad.qualidade * ad.cpc_max) as ad_rank
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif NOT qPerfil.is_admin>
        AND evt.tag IN (select perm.tag from tb_permissoes perm WHERE perm.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>)
    </cfif>
    ORDER BY ad_rank DESC
</cfquery>


<!--- INCLUIR CAMPANHA --->
<cfif isDefined("form.evento")>

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

</cfif>
