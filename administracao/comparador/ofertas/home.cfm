<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
offerWaBlocked=false;
if(ready AND offerId AND structKeyExists(VARIABLES,'detail')) offerWaBlocked=detail.offer.wa_compra_bloqueada;
</cfscript>
<h1 class="h3">Comparador · Promoções e ofertas</h1>
<cfinclude template="../includes/navigation.cfm">
<cfoutput>
<cfif len(error)><div class="alert alert-danger" role="alert">#encodeForHTML(error)#</div></cfif>
<cfif NOT ready><div class="alert alert-warning">Esta área aguarda a atualização do banco de dados.</div>
<cfelseif conflict><p><a href="./?id=#offerId#&#encodeForHTMLAttribute(returnQuery)#">Reabrir oferta atualizada</a></p>
<cfelse>
<cfif service.field(URL,'salvo',1) EQ '1'><div class="alert alert-success" role="status">Oferta salva com histórico.</div></cfif>
<div class="alert alert-info">O site considera a oferta mais recente de cada produto. Ao encerrar essa oferta, passa a mostrar o preço de referência. As ofertas anteriores continuam no histórico. Protótipos permanecem sem opção de compra.</div>
<cfif offerId>
<a class="d-inline-block mb-3" href="./?#encodeForHTMLAttribute(returnQuery)#">← Voltar às ofertas</a>
<div class="card card-body mb-4"><h2 class="h4">Oferta ## #offerId# · #encodeForHTML(value('nome_produto'))#</h2>
<a href="../?id=#service.identifier(value('id_tenis'))#&aba=ofertas" class="mb-3">Ver produto</a>
<cfif offerWaBlocked><div class="alert alert-warning mb-0">Protótipo sem opção de compra. A edição está bloqueada; você pode encerrar a oferta abaixo.</div><cfelse>
<form method="post"><input type="hidden" name="acao" value="salvar"><input type="hidden" name="id_cupom" value="#offerId#"><input type="hidden" name="token" value="#token#"><input type="hidden" name="csrf_token" value="#csrf#">
<div class="row g-3">
<div class="col-md-6"><label class="form-label" for="loja">Loja</label><input class="form-control" id="loja" name="loja" value="#encodeForHTMLAttribute(value('loja'))#" maxlength="256" required></div>
<div class="col-md-3"><label class="form-label" for="preco_promocional">Preço (R$)</label><input class="form-control" id="preco_promocional" name="preco_promocional" value="#encodeForHTMLAttribute(value('preco_promocional'))#" inputmode="decimal" required></div>
<div class="col-md-3"><label class="form-label" for="data_expiracao">Válida até</label><input class="form-control" id="data_expiracao" name="data_expiracao" type="date" value="#encodeForHTMLAttribute(value('data_expiracao'))#"></div>
<div class="col-md-8"><label class="form-label" for="link">Link da oferta</label><input class="form-control" id="link" name="link" type="url" value="#encodeForHTMLAttribute(value('link'))#" maxlength="256" required></div>
<div class="col-md-4"><label class="form-label" for="cupom">Cupom</label><input class="form-control" id="cupom" name="cupom" value="#encodeForHTMLAttribute(value('cupom'))#" maxlength="32"></div>
<div class="col-12"><label class="form-label" for="condicoes">Condições</label><textarea class="form-control" id="condicoes" name="condicoes" maxlength="256" rows="3">#encodeForHTML(value('condicoes'))#</textarea></div>
</div><button class="btn btn-warning mt-3" type="submit">Salvar oferta</button></form></cfif></div>
<form method="post" class="card card-body"><input type="hidden" name="acao" value="encerrar"><input type="hidden" name="id_cupom" value="#offerId#"><input type="hidden" name="token" value="#token#"><input type="hidden" name="csrf_token" value="#csrf#"><h2 class="h5">Encerrar oferta</h2><p>Encerra a validade imediatamente e preserva o registro e seu histórico.</p><div><button class="btn btn-outline-danger" type="submit">Encerrar oferta</button></div></form>
<cfelse>
<div class="d-flex justify-content-end mb-3"><a class="btn btn-warning" href="../">Escolher produto para nova oferta</a></div>
<form method="get" class="card card-body mb-4"><div class="row g-3 align-items-end"><div class="col-md-7"><label class="form-label" for="busca">Produto, loja ou cupom</label><input class="form-control" id="busca" name="busca" value="#encodeForHTMLAttribute(search)#" maxlength="160"></div><div class="col-md-3"><label class="form-label" for="situacao">Situação</label><select class="form-select" id="situacao" name="situacao"><option value="">Todas</option><option value="recentes" <cfif status EQ 'recentes'>selected</cfif>>Mais recentes</option><option value="vencidas" <cfif status EQ 'vencidas'>selected</cfif>>Vencidas</option><option value="anteriores" <cfif status EQ 'anteriores'>selected</cfif>>Anteriores</option></select></div><div class="col-md-2"><button class="btn btn-outline-warning w-100" type="submit">Filtrar</button></div></div></form>
<div class="card card-body"><p>#offers.total# ofertas · página #offers.page# de #offers.pages#</p><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Produto</th><th>Loja / cupom</th><th>Preço</th><th>Validade</th><th>Situação</th><th>Ação</th></tr></thead><tbody><cfloop query="offers.rows"><tr><td>#encodeForHTML(nome_produto)#<br><small>Oferta ## #id_cupom#</small></td><td>#encodeForHTML(loja)#<br>#encodeForHTML(cupom)#</td><td>#isNumeric(preco_promocional)?'R$ ' & numberFormat(preco_promocional,'0.00'):'Não informado'#</td><td>#isDate(data_expiracao)?dateFormat(data_expiracao,'dd/mm/yyyy'):'Não informada'#</td><td>#is_latest?'Mais recente':'Anterior'#<cfif expired><br>Vencida</cfif><cfif wa_compra_bloqueada><br>Protótipo · sem compra</cfif></td><td><a class="btn btn-sm btn-outline-light" href="./?id=#id_cupom#&#encodeForHTMLAttribute(returnQuery)#">#wa_compra_bloqueada?'Encerrar':'Editar'#</a></td></tr></cfloop><cfif NOT offers.rows.recordCount><tr><td colspan="6">Nenhuma oferta encontrada.</td></tr></cfif></tbody></table></div>
<nav class="d-flex justify-content-between" aria-label="Paginação das ofertas"><cfif offers.page GT 1><a href="./?#encodeForHTMLAttribute(reReplace(returnQuery,'pagina=[0-9]+','pagina=' & (offers.page-1)))#">Anterior</a><cfelse><span></span></cfif><cfif offers.page LT offers.pages><a href="./?#encodeForHTMLAttribute(reReplace(returnQuery,'pagina=[0-9]+','pagina=' & (offers.page+1)))#">Próxima</a></cfif></nav></div>
</cfif></cfif>
</cfoutput>
