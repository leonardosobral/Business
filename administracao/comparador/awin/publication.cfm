<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfif structKeyExists(publicationData,'plan')>
<cfscript>
publicationQueues=[{key='revisao',label='Precisam de revisão',count=publicationData.plan.pending},{key='fora_catalogo',label='Fora do catálogo',count=publicationData.plan.outsideCatalog},{key='vinculadas',label='Vinculadas',count=publicationData.plan.published},{key='bloqueadas',label='Bloqueadas',count=publicationData.plan.blocked},{key='todas',label='Todas',count=arrayLen(publicationData.plan.decisions)}];
publicationBase='?aba=publicacao&busca=' & encodeForURL(search) & '&anunciante=' & encodeForURL(advertiserFilter);
selectedDecision={};for(decision in publicationData.plan.decisions)if(decision.campaignId==campaignEdit)selectedDecision=decision;
</cfscript>
<cfoutput>
<cfif guard.field(URL,'salvo',1) EQ '1'><div class="alert alert-success" role="status">Decisão salva e publicação atualizada.</div></cfif>
<div class="card card-body mb-4">
 <h2 class="h5">Publicação das ofertas</h2>
 <p>#publicationData.plan.published# vinculadas · #publicationData.plan.pending# precisam de revisão · #publicationData.plan.outsideCatalog# fora do catálogo · #publicationData.plan.blocked# bloqueadas</p>
 <p class="mb-1"><cfif len(publicationData.publishedAt)>Última publicação: #encodeForHTML(awin.localTime(publicationData.publishedAt))# (Brasília).<cfelse>Clique em Sincronizar e publicar para aplicar a primeira vinculação.</cfif></p>
 <p class="small mb-0">Campanhas fora do catálogo têm um motivo de revisão registrado e podem ser reabertas. Mudanças nas condições da campanha voltam para revisão. <a href="/administracao/cron-jobs/">Gerenciar a rotina de atualização</a>.</p>
</div>
<nav class="nav nav-pills mb-3" aria-label="Situação das campanhas">
 <cfloop array="#publicationQueues#" index="queue"><a class="nav-link #publicationQueue EQ queue.key ? 'active' : ''#" href="#encodeForHTMLAttribute(publicationBase & '&fila=' & queue.key)#" <cfif publicationQueue EQ queue.key>aria-current="page"</cfif>>#queue.label# <span class="badge bg-secondary ms-1">#queue.count#</span></a></cfloop>
</nav>
<form method="get" class="card card-body mb-4">
 <input type="hidden" name="aba" value="publicacao"><input type="hidden" name="fila" value="#publicationQueue#">
 <div class="row g-3 align-items-end">
  <div class="col-md-6"><label for="publicacao-busca" class="form-label">Buscar campanha ou motivo</label><input id="publicacao-busca" class="form-control" name="busca" maxlength="160" value="#encodeForHTMLAttribute(search)#"></div>
  <div class="col-md-4"><label for="publicacao-anunciante" class="form-label">Programa</label><select class="form-select" name="anunciante" id="publicacao-anunciante"><option value="">Todos</option><cfloop array="#data.programmes#" index="programme"><option value="#encodeForHTMLAttribute(programme.id)#" <cfif programme.id EQ advertiserFilter>selected</cfif>>#encodeForHTML(programme.name)#</option></cfloop></select></div>
  <div class="col-md-2"><button class="btn btn-outline-warning" type="submit">Filtrar</button></div>
 </div>
</form>
<cfif NOT structIsEmpty(selectedDecision)>
<div class="card card-body mb-4" id="campanha-em-revisao">
 <h2 class="h5">#encodeForHTML(selectedDecision.title)#</h2><p>#encodeForHTML(selectedDecision.advertiser)# · #encodeForHTML(selectedDecision.reason)#</p>
 <cfloop array="#data.promotions#" index="campaign"><cfif campaign.id EQ campaignEdit><details class="mb-3"><summary>Conferir condições e elegibilidade</summary><p class="awin-terms">#encodeForHTML(campaign.description)#</p><p class="awin-terms">#encodeForHTML(campaign.terms)#</p><cfif len(campaign.trackingUrl)><a href="#encodeForHTMLAttribute(campaign.trackingUrl)#" target="_blank" rel="noopener noreferrer sponsored">Conferir campanha na loja</a></cfif></details></cfif></cfloop>
 <details <cfif selectedDecision.classification EQ 'revisao' OR selectedDecision.classification EQ 'vinculadas'>open</cfif>>
  <summary>Vincular produtos e publicar</summary>
  <form method="get" class="row g-2 my-3"><input type="hidden" name="aba" value="publicacao"><input type="hidden" name="fila" value="#publicationQueue#"><input type="hidden" name="campanha" value="#campaignEdit#"><div class="col-md-9"><label class="form-label" for="produto-busca">Buscar produtos do catálogo</label><input id="produto-busca" name="produto_busca" class="form-control" value="#encodeForHTMLAttribute(productSearch)#" placeholder="Marca, modelo ou versão"></div><div class="col-md-3 align-self-end"><button class="btn btn-outline-warning" type="submit">Buscar produtos</button></div></form>
  <form method="post"><input type="hidden" name="acao" value="regra"><input type="hidden" name="modo" value="manual"><input type="hidden" name="campanha" value="#campaignEdit#"><input type="hidden" name="csrf_token" value="#csrf#"><input type="hidden" name="publicacao_token" value="#publicationData.token#"><input type="hidden" name="campanha_hash" value="#selectedDecision.fingerprint#">
   <fieldset><legend class="h6">Produtos elegíveis para esta campanha</legend><p class="small">Selecione até 20 produtos após conferir as condições. Salvar substitui a seleção anterior. As demais campanhas do produto são preservadas.</p>
    <cfset productOptions=0/>
    <cfloop array="#publicationData.products#" index="product"><cfset isSelected=arrayFind(selectedDecision.products,product.id) GT 0/>
     <cfif isSelected OR (len(productSearch) AND findNoCase(productSearch,product.label) AND productOptions LT 30)><cfset productOptions++/>
      <div class="form-check mb-2"><input class="form-check-input" type="checkbox" name="produtos" value="#product.id#" id="vinculo-#product.id#" <cfif isSelected>checked</cfif>><label class="form-check-label" for="vinculo-#product.id#">#encodeForHTML(product.label)#</label> <a class="small" href="/administracao/comparador/?id=#product.id#" target="_blank" rel="noopener">Ver produto</a></div>
     </cfif>
    </cfloop>
    <cfif NOT productOptions><p>Busque pelo nome do produto para selecionar.</p></cfif>
   </fieldset>
   <button class="btn btn-warning mt-3" type="submit" <cfif NOT productOptions>disabled</cfif>>Confirmar produtos e publicar</button>
  </form>
 </details>
 <details class="mt-3" <cfif selectedDecision.classification EQ 'fora_catalogo'>open</cfif>>
  <summary>Classificar fora do catálogo</summary>
  <p class="small mt-2">Use quando a campanha não tiver produto correspondente no catálogo. Registre o motivo para a próxima conferência.</p>
  <form method="post"><input type="hidden" name="acao" value="regra"><input type="hidden" name="modo" value="fora_catalogo"><input type="hidden" name="campanha" value="#campaignEdit#"><input type="hidden" name="csrf_token" value="#csrf#"><input type="hidden" name="publicacao_token" value="#publicationData.token#"><input type="hidden" name="campanha_hash" value="#selectedDecision.fingerprint#">
   <label class="form-label" for="motivo-catalogo">Motivo</label><textarea class="form-control" id="motivo-catalogo" name="motivo_catalogo" required minlength="8" maxlength="1000" rows="3">#selectedDecision.classification EQ 'fora_catalogo' ? encodeForHTML(selectedDecision.reason) : ''#</textarea>
   <button class="btn btn-outline-warning mt-3" type="submit">Salvar fora do catálogo</button>
  </form>
 </details>
 <div class="d-flex flex-wrap gap-2 mt-3">
  <cfloop list="revisar,bloqueado,automatico" index="ruleMode"><form method="post"><input type="hidden" name="acao" value="regra"><input type="hidden" name="modo" value="#ruleMode#"><input type="hidden" name="campanha" value="#campaignEdit#"><input type="hidden" name="csrf_token" value="#csrf#"><input type="hidden" name="publicacao_token" value="#publicationData.token#"><input type="hidden" name="campanha_hash" value="#selectedDecision.fingerprint#"><button class="btn btn-outline-warning" type="submit">#ruleMode EQ 'revisar' ? 'Mover para revisão' : (ruleMode EQ 'bloqueado' ? 'Bloquear publicação desta campanha' : 'Restaurar vinculação automática')#</button></form></cfloop>
 </div>
</div>
</cfif>
<p>#arrayLen(publicationDecisions)# #arrayLen(publicationDecisions) EQ 1 ? 'campanha encontrada' : 'campanhas encontradas'# nesta lista.</p>
<div class="row g-3">
 <cfloop array="#publicationDecisions#" index="decision"><div class="col-12 col-xl-6"><article class="card card-body h-100" data-campanha="#decision.campaignId#" data-classificacao="#decision.classification#">
  <p class="small text-muted mb-1">#encodeForHTML(decision.advertiser)# · campanha #decision.campaignId#</p><h2 class="h6">#encodeForHTML(decision.title)#</h2>
  <p><strong>#decision.classification EQ 'fora_catalogo' ? 'Fora do catálogo' : (decision.classification EQ 'bloqueadas' ? 'Bloqueada' : (decision.classification EQ 'vinculadas' ? (decision.state EQ 'upcoming' ? 'Agendada para o início da campanha' : 'Vinculada') : 'Precisa de revisão'))#</strong></p>
  <p class="small awin-terms">#encodeForHTML(decision.reason)#</p>
  <cfif arrayLen(decision.labels)><ul><cfloop array="#decision.labels#" index="productLabel"><li>#encodeForHTML(productLabel)#</li></cfloop></ul></cfif>
  <a class="btn btn-outline-warning mt-auto align-self-start" href="#encodeForHTMLAttribute(publicationBase & '&fila=' & publicationQueue & '&campanha=' & decision.campaignId)#">Gerenciar campanha</a>
 </article></div></cfloop>
 <cfif NOT arrayLen(publicationDecisions)><div class="col-12"><div class="card card-body" role="status"><cfif len(search) OR len(advertiserFilter)>Nenhuma campanha corresponde aos filtros nesta lista.<cfelseif publicationQueue EQ 'revisao'>Nenhuma campanha precisa de revisão neste momento.<cfelse>Nenhuma campanha nesta lista.</cfif></div></div></cfif>
</div>
<details class="mt-4"><summary>Histórico de publicação</summary><div class="table-responsive"><table class="table"><thead><tr><th>Quando (Brasília)</th><th>Ação</th><th>Responsável</th><th>Vínculos</th><th>Revisão</th><th>Fora do catálogo</th></tr></thead><tbody><cfloop array="#publicationData.history#" index="entry"><tr><td>#encodeForHTML(awin.localTime(entry.at))#</td><td>#encodeForHTML(entry.action)#</td><td>#entry.actorId EQ 0 ? (entry.action EQ 'classificacao_catalogo_operacional' ? 'Operação do servidor' : 'Rotina automática') : 'Admin ' & entry.actorId#</td><td>#entry.offers#</td><td>#entry.pending#</td><td>#structKeyExists(entry,'outsideCatalog') ? entry.outsideCatalog : '—'#</td></tr></cfloop></tbody></table></div></details>
</cfoutput>
</cfif>
