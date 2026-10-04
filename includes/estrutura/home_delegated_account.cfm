<cfprocessingdirective pageencoding="utf-8"/><cfheader name="Cache-Control" value="private, no-store"/>
<cfset VARIABLES.delegatedHomeContext=REQUEST.businessAccessContext/>
<cfset VARIABLES.delegatedHomeService=REQUEST.businessDelegationService/>
<cfquery name="qDelegatedHomeNames" datasource="runnerhub">
  SELECT client.nome_conta AS client_name,manager.nome_conta AS manager_name
  FROM tb_contas client JOIN tb_contas manager ON manager.id_conta=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.delegatedHomeContext.managerAccountId#"/>
  WHERE client.id_conta=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.delegatedHomeContext.accountId#"/>
</cfquery>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Conta do cliente</title><link rel="stylesheet" href="/assets/css/account-delegation.css"/></head>
<body class="business-delegated-home">
<main class="container business-workspace">
  <nav aria-label="Contexto da conta"><a href="/gestao-clientes/">Voltar à carteira</a> · <a href="/selecionar-conta/">Trocar conta</a></nav>
  <cfif qDelegatedHomeNames.recordCount><cfoutput><p class="business-workspace-warning">Via #encodeForHTML(qDelegatedHomeNames.manager_name)#</p><h1>#encodeForHTML(qDelegatedHomeNames.client_name)#</h1></cfoutput><cfelse><h1>Conta do cliente</h1></cfif>
  <p>Escolha um serviço concedido para este cliente.</p>
  <ul class="business-delegated-shortcuts">
    <cfif VARIABLES.delegatedHomeService.has(VARIABLES.delegatedHomeContext,'ads.campaigns.view')><li><a href="/ads/?view=campaigns">Campanhas</a></li></cfif>
    <cfif VARIABLES.delegatedHomeService.has(VARIABLES.delegatedHomeContext,'ads.payments.view')><li><a href="/ads/?view=payments">Saldo e pagamentos</a></li></cfif>
    <cfif VARIABLES.delegatedHomeService.has(VARIABLES.delegatedHomeContext,'events.view')><li><a href="/eventos/">Eventos</a></li></cfif>
  </ul>
  <cfif NOT VARIABLES.delegatedHomeService.has(VARIABLES.delegatedHomeContext,'ads.campaigns.view') AND NOT VARIABLES.delegatedHomeService.has(VARIABLES.delegatedHomeContext,'events.view')><p>Nenhum módulo concedido nesta atribuição.</p></cfif>
</main>
</body></html>
