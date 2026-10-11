<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfparam name="url.tid" default="">
<cfif structKeyExists(REQUEST, "Usuario")>
    <cfset Usuario = REQUEST.Usuario/>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario").init({})/>
</cfif>

<!--- Aqui você consulta sua tabela de transações --->
<cfif Usuario.logado AND len(trim(url.tid))>
    <cfquery name="qCheckTransacoes" result="qCheckTransacoesMeta">
        SELECT status_atual
        FROM tb_transacoes
        WHERE id_usuario = <cfqueryparam value="#Usuario.id#" cfsqltype="cf_sql_integer">
        AND codigo_transacao = <cfqueryparam value="#url.tid#" cfsqltype="cf_sql_varchar">
    </cfquery>
    <cfset logQueryDebug("qCheckTransacoes", qCheckTransacoesMeta, "carteira/check_transacao/base", "sem cache", qCheckTransacoes)/>
<cfelse>
    <cfset qCheckTransacoes = queryNew("status_atual", "varchar")/>
</cfif>

<cfset resultado = structNew("ordered")>
<cfset resultado.status = "CHECK">

<cfif qCheckTransacoes.recordCount>

    <cfquery name="qCheckTransacaoStatus" dbtype="query" result="qCheckTransacaoStatusMeta">
        SELECT status_atual
        FROM qCheckTransacoes
        WHERE status_atual = 'charge.pending'
    </cfquery>
    <cfset logQueryDebug("qCheckTransacaoStatus", qCheckTransacaoStatusMeta, "carteira/check_transacao/pending", "dbtype=query", qCheckTransacaoStatus)/>
    <cfif qCheckTransacaoStatus.recordcount>
        <cfset resultado.status = "PENDING">
    </cfif>

    <cfquery name="qCheckTransacaoStatus" dbtype="query" result="qCheckTransacaoStatusMeta">
        SELECT status_atual
        FROM qCheckTransacoes
        WHERE status_atual = 'charge.payment_failed'
    </cfquery>
    <cfset logQueryDebug("qCheckTransacaoStatus", qCheckTransacaoStatusMeta, "carteira/check_transacao/declined", "dbtype=query", qCheckTransacaoStatus)/>
    <cfif qCheckTransacaoStatus.recordcount>
        <cfset resultado.status = "DECLINED">
    </cfif>

    <cfquery name="qCheckTransacaoStatus" dbtype="query" result="qCheckTransacaoStatusMeta">
        SELECT status_atual
        FROM qCheckTransacoes
        WHERE status_atual = 'order.paid'
    </cfquery>
    <cfset logQueryDebug("qCheckTransacaoStatus", qCheckTransacaoStatusMeta, "carteira/check_transacao/approved", "dbtype=query", qCheckTransacaoStatus)/>
    <cfif qCheckTransacaoStatus.recordcount>
        <cfset resultado.status = "APPROVED">
    </cfif>

<cfelse>
    <cfset resultado.status = "CHECK">
</cfif>

<cfoutput>#serializeJSON(resultado)#</cfoutput>
