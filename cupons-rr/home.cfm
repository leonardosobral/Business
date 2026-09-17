<cfif NOT structKeyExists(VARIABLES,'cpData')><cfheader statuscode="403"/><cfabort/></cfif>
<link rel="stylesheet" href="/cupons-rr/assets/manager.css?v=20260916-1"/>
<section class="cp-manager">
<cfoutput>
<header class="cp-header"><div><span class="cp-kicker">Benefícios e inscrições</span><h1>Cupons de desconto</h1><p>Organize os códigos, as condições e os eventos que recebem cada benefício.</p></div><cfif cuponsRrCanOperate><a class="btn btn-warning" href="./?novo=1##cp-editor">Novo cupom</a></cfif></header>
<div class="cp-stats" aria-label="Resumo do catálogo"><div><span>Total de cupons</span><strong>#cpData.stats.total#</strong></div><div><span>Ativos</span><strong>#cpData.stats.ativos#</strong></div><div><span>Expirados</span><strong>#cpData.stats.expirados#</strong></div><div><span>Inativos</span><strong>#cpData.stats.inativos#</strong></div></div>
<p class="cp-help">Resumo de todos os cupons acessíveis à sua conta. A validade em cada evento é definida nos vínculos.</p>
<cfif len(cpError)><div class="alert alert-warning" role="alert">#encodeForHTML(cpError)#<cfif cpConflict> <a href="./?cupom_id=#cpSelected#">Recarregar cadastro</a></cfif></div></cfif>
<cfif (URL.salvo ?: '') EQ '1'><div class="alert alert-success" role="status">Cupom atualizado com sucesso.</div></cfif>
<cfif NOT cuponsRrCanOperate><div class="alert alert-info">Você pode consultar os cupons disponíveis para sua conta. Para cadastrar ou alterar, é necessário acesso de operação ao evento.</div></cfif>
<div class="cp-layout">
<section class="cp-panel" aria-label="Catálogo de cupons">
<form class="cp-filters" action="./" method="get" role="search">
<div><label for="cp-search">Buscar cupom</label><input class="form-control" id="cp-search" type="search" name="busca" maxlength="120" placeholder="Código, parceiro ou evento" value="#encodeForHTMLAttribute(cpData.filters.search)#"/></div>
<div><label for="cp-status">Situação</label><select class="form-select" id="cp-status" name="status"><option value="">Todas</option><cfloop array="#[{value='ativos',label='Ativos'},{value='expirados',label='Expirados'},{value='inativos',label='Inativos'}]#" item="cpOption"><option value="#cpOption.value#" <cfif cpData.filters.status EQ cpOption.value>selected</cfif>>#cpOption.label#</option></cfloop></select></div><button class="btn btn-outline-warning" type="submit">Filtrar</button><a href="./">Limpar</a>
</form>
<div class="cp-list-heading"><h2>Catálogo</h2><span>#cpData.total# resultado(s)</span></div>
<div class="cp-list">
<cfloop query="cpData.coupons"><cfset cpItem=queryGetRow(cpData.coupons,cpData.coupons.currentRow)/>
<a class="cp-item <cfif cpSelected EQ cpItem.id_cupom>is-selected</cfif>" href="#encodeForHTMLAttribute(cpListUrl(cpData.page))#&amp;cupom_id=#cpItem.id_cupom###cp-editor"><div class="cp-row"><strong class="cp-code">#encodeForHTML(cpItem.cupom)#</strong><span class="cp-badge" data-status="#cpItem.situacao#">#cpItem.situacao#</span></div><div>#encodeForHTML(cpItem.parceiro)#</div><p>#encodeForHTML(cpItem.condicoes)#</p><small>Expiração: #cpDate(cpItem.data_expiracao)#</small></a>
</cfloop>
<cfif NOT cpData.total><div class="cp-empty"><h3>Nenhum cupom encontrado</h3><p>Altere a busca ou cadastre o primeiro cupom para um evento autorizado.</p></div></cfif>
</div>
<nav class="cp-pagination" aria-label="Paginação"><cfif cpData.page GT 1><a href="#encodeForHTMLAttribute(cpListUrl(cpData.page-1))#">Anterior</a><cfelse><span></span></cfif><span>#cpData.page# / #cpData.pages#</span><cfif cpData.page LT cpData.pages><a href="#encodeForHTMLAttribute(cpListUrl(cpData.page+1))#">Próxima</a><cfelse><span></span></cfif></nav>
</section>
<section class="cp-panel cp-detail" id="cp-editor" aria-label="Cadastro do cupom">
<cfif (cpNew AND cuponsRrCanOperate) OR cpCoupon.recordcount>
<header class="cp-detail-heading"><div><span class="cp-kicker"><cfif cpNew>Novo benefício<cfelse>Código ## #cpSelected#</cfif></span><h2><cfif cpNew>Cadastrar cupom<cfelse>#encodeForHTML(cpValues.cupom)#</cfif></h2></div><a href="./" aria-label="Fechar cadastro">Fechar</a></header>
<cfif cpNew OR cpCanEdit>
<cfinclude template="includes/form_cupom.cfm"/>
<cfelse>
<div class="alert alert-info">Consulta disponível. Cupons compartilhados entre contas, páginas ou circuitos só podem ser alterados por um administrador global.</div>
<dl><dt>Parceiro</dt><dd>#encodeForHTML(cpValues.parceiro)#</dd><dt>Desconto / condições</dt><dd>#encodeForHTML(cpValues.condicoes)#</dd><dt>Descrição</dt><dd>#encodeForHTML(cpValues.descricao)#</dd><dt>Expiração</dt><dd>#cpDate(cpValues.data_expiracao)#</dd></dl>
</cfif>
<cfif cpCoupon.recordcount><cfinclude template="includes/links.cfm"/></cfif>
<cfelse><div class="cp-empty"><i class="fa-solid fa-ticket" aria-hidden="true"></i><h2><cfif cpSelected>Cupom indisponível<cfelse>Um código, vários eventos</cfif></h2><p>Selecione um cupom para consultar seus dados, editar as condições ou gerenciar os vínculos com eventos.</p><small>Os códigos e as regras de desconto devem existir também na plataforma que vende as inscrições. Este cadastro organiza a divulgação no Road Runners.</small></div></cfif>
</section>
</div>
</cfoutput>
</section>
<script src="/cupons-rr/assets/manager.js?v=20260916-1" defer></script>
