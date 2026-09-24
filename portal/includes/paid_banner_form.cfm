<cfset VARIABLES.paidBannerPageLabels={home='Página inicial',search='Busca de eventos',state='Eventos por estado',event='Páginas de eventos',athlete='Perfil de atleta'}/>
<cfset VARIABLES.paidBannerFormConflict=structKeyExists(VARIABLES,'paidBannerConflict') AND VARIABLES.paidBannerConflict/>
<cfoutput>
<section class="banner-panel" id="paid-banner-form" aria-labelledby="paid-banner-form-title"<cfif VARIABLES.paidBannerFormConflict> data-paid-banner-conflict="true"</cfif>>
    <div class="banner-section-heading">
        <div><div class="banner-eyebrow">Banner por clique</div><h2 class="h5 mb-1" id="paid-banner-form-title"><cfif len(VARIABLES.paidBannerEditId)>Editar banner<cfelse>Criar banner</cfif></h2>
        <p class="text-muted mb-0">Divulgue sua marca ou parceiro. Não é necessário vincular um evento.</p></div>
        <a class="btn btn-outline-light btn-sm" href="/portal/banners/">Fechar formulário</a>
    </div>
    <cfif VARIABLES.paidBannerFormConflict><div class="alert alert-warning" role="alert">Este envio conflita com uma versão mais recente. Os valores abaixo foram preservados somente para conferência e estão desabilitados. Reabra a versão atual antes de editar ou enviar novamente.</div></cfif>
    <form method="post" action="/portal/banners/##paid-banner-form" enctype="multipart/form-data" data-banner-form<cfif VARIABLES.paidBannerFormConflict> aria-disabled="true" onsubmit="return false"</cfif>>
        <input type="hidden" name="paid_banner_action" value="save"/>
        <input type="hidden" name="paid_banner_csrf" value="#htmlEditFormat(VARIABLES.paidBannerCsrf)#"/>
        <input type="hidden" name="campaign_id" value="#htmlEditFormat(VARIABLES.paidBannerEditId)#"/>
        <cfif len(VARIABLES.paidBannerEditId)><input type="hidden" name="expected_version" value="#htmlEditFormat(VARIABLES.paidBannerEditRow.version)#"/></cfif>
        <fieldset class="mb-4"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>><legend class="h6">1. Sua marca e o destino</legend>
            <div class="row g-3">
                <div class="col-md-6"><label class="form-label" for="paid-banner-name">Nome do banner</label><input class="form-control" id="paid-banner-name" name="name" required minlength="3" maxlength="160" value="#htmlEditFormat(VARIABLES.paidBannerFormData.name)#"/></div>
                <div class="col-md-6"><label class="form-label" for="paid-banner-destination">Link de destino</label><input class="form-control" id="paid-banner-destination" name="destination_url" required placeholder="https://sua-marca.com.br/oferta" value="#htmlEditFormat(VARIABLES.paidBannerFormData.destination_url)#"/></div>
                <div class="col-md-8"><label class="form-label" for="paid-banner-alt">Descrição da imagem</label><input class="form-control" id="paid-banner-alt" name="alt_text" required minlength="3" maxlength="300" value="#htmlEditFormat(VARIABLES.paidBannerFormData.alt_text)#"/><div class="form-text">Descreva brevemente a oferta para quem usa leitor de tela.</div></div>
                <div class="col-md-4"><label class="form-label" for="paid-banner-target">Abrir destino</label><select class="form-select" id="paid-banner-target" name="open_new_tab"><option value="1"<cfif VARIABLES.paidBannerFormData.open_new_tab EQ '1'> selected</cfif>>Nova aba</option><option value="0"<cfif VARIABLES.paidBannerFormData.open_new_tab EQ '0'> selected</cfif>>Mesma aba</option></select></div>
            </div>
        </fieldset>
        <fieldset class="mb-4"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>><legend class="h6">2. Imagens do banner</legend>
            <p class="small text-muted">Envie JPG, PNG ou GIF de até 10 MiB. As dimensões são detectadas automaticamente. Na edição, mantenha a imagem atual deixando o campo vazio.</p>
            <div class="row g-3"><cfloop list="desktop,mobile" index="paidBannerImageKind">
                <cfset paidBannerSavedImage=structKeyExists(VARIABLES.paidBannerEditRow,'image_url_' & paidBannerImageKind) ? VARIABLES.paidBannerEditRow['image_url_' & paidBannerImageKind] : ''/>
                <div class="col-md-6"><label class="form-label" for="paid-banner-#paidBannerImageKind#">Imagem #paidBannerImageKind#</label>
                    <input class="form-control" type="file" id="paid-banner-#paidBannerImageKind#" name="banner_arquivo_#paidBannerImageKind#" accept="image/jpeg,image/png,image/gif" data-banner-upload="#paidBannerImageKind#"<cfif NOT len(paidBannerSavedImage)> required</cfif>/>
                    <img class="mt-2 rounded" style="max-width:100%;max-height:200px;object-fit:contain" data-banner-preview="#paidBannerImageKind#" alt="Prévia #paidBannerImageKind#"<cfif len(paidBannerSavedImage)> src="#htmlEditFormat(paidBannerSavedImage)#"<cfelse> hidden</cfif>/>
                    <div class="form-text" data-banner-info="#paidBannerImageKind#"></div>
                </div>
            </cfloop></div>
        </fieldset>
        <fieldset class="mb-4"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>><legend class="h6">3. Investimento</legend>
            <p class="small">O saldo é o mesmo dos anúncios de eventos. CPC é o valor máximo por clique: você só paga por cliques válidos. O lance e a relevância regional participam do leilão; não há garantia de posição ou volume.</p>
            <div class="row g-3">
                <div class="col-md-4"><label class="form-label" for="paid-banner-bid">Lance máximo por clique (R$)</label><input class="form-control" id="paid-banner-bid" name="cpc_bid" inputmode="decimal" required value="#htmlEditFormat(VARIABLES.paidBannerFormData.cpc_bid)#"/></div>
                <div class="col-md-4"><label class="form-label" for="paid-banner-budget">Orçamento total (R$)</label><input class="form-control" id="paid-banner-budget" name="budget_total" inputmode="decimal" required value="#htmlEditFormat(VARIABLES.paidBannerFormData.budget_total)#"/></div>
                <div class="col-md-4"><label class="form-label" for="paid-banner-daily">Limite diário (opcional)</label><input class="form-control" id="paid-banner-daily" name="budget_daily" inputmode="decimal" placeholder="Sem limite adicional" value="#htmlEditFormat(VARIABLES.paidBannerFormData.budget_daily)#"/></div>
            </div>
        </fieldset>
        <fieldset class="mb-4"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>><legend class="h6">4. Período e onde aparecer</legend>
            <p class="small text-muted">Banner responsivo: lateral no desktop e área de banner no celular. As páginas e os estados abaixo definem onde seu banner poderá concorrer.</p>
            <div class="row g-3 mb-3">
                <cfloop list="starts_at,ends_at" index="paidBannerDateKey"><div class="col-md-4"><label class="form-label" for="paid-banner-#paidBannerDateKey#">#paidBannerDateKey EQ 'starts_at' ? 'Início' : 'Fim'# (Brasília)</label><input class="form-control" type="datetime-local" id="paid-banner-#paidBannerDateKey#" name="#paidBannerDateKey#" required value="#htmlEditFormat(VARIABLES.paidBannerFormData[paidBannerDateKey])#"/></div></cfloop>
                <div class="col-md-4"><label class="form-label" for="paid-banner-device">Dispositivo</label><select class="form-select" id="paid-banner-device" name="target_device"><cfloop array="#[{value='ALL',label='Todos'},{value='DESKTOP',label='Desktop'},{value='MOBILE',label='Celular'}]#" index="paidBannerDevice"><option value="#paidBannerDevice.value#"<cfif VARIABLES.paidBannerFormData.target_device EQ paidBannerDevice.value> selected</cfif>>#paidBannerDevice.label#</option></cfloop></select></div>
            </div>
            <div class="row g-3"><cfloop list="pages,regions" index="paidBannerScopeKind">
                <div class="col-md-6"><label class="form-label" for="paid-banner-#paidBannerScopeKind#">#paidBannerScopeKind EQ 'pages' ? 'Páginas' : 'Estados'#</label>
                    <select class="form-select" id="paid-banner-#paidBannerScopeKind#" name="banner_#paidBannerScopeKind#_mode"><option value="ALL"<cfif VARIABLES.paidBannerFormData['banner_' & paidBannerScopeKind & '_mode'] EQ 'ALL'> selected</cfif>>#paidBannerScopeKind EQ 'pages' ? 'Todas as páginas compatíveis' : 'Todo o Brasil'#</option><option value="SELECTED"<cfif VARIABLES.paidBannerFormData['banner_' & paidBannerScopeKind & '_mode'] EQ 'SELECTED'> selected</cfif>>Selecionar #paidBannerScopeKind EQ 'pages' ? 'páginas' : 'estados'#</option></select>
                    <div class="mt-2 d-flex flex-wrap gap-3" data-banner-choices="#paidBannerScopeKind#">
                        <cfloop list="#paidBannerScopeKind EQ 'pages' ? 'home,search,state,event,athlete' : 'AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO'#" index="paidBannerScopeOption"><label class="form-check-label"><input class="form-check-input me-1" type="checkbox" name="banner_#paidBannerScopeKind#" value="#paidBannerScopeOption#"<cfif listFind(VARIABLES.paidBannerFormData['banner_' & paidBannerScopeKind],paidBannerScopeOption)> checked</cfif>/>#paidBannerScopeKind EQ 'pages' ? VARIABLES.paidBannerPageLabels[paidBannerScopeOption] : paidBannerScopeOption#</label></cfloop>
                    </div>
                </div>
            </cfloop></div>
            <p class="form-text mt-3">A região usa o contexto da página ou do visitante, não necessariamente sua localização física. Sem região conhecida, um banner restrito a estados não será exibido.</p>
        </fieldset>
        <div class="alert alert-info">Ao enviar, a equipe RunnerHub analisará as imagens, o destino e a campanha. Nenhum banner entra no ar antes da aprovação. Alterações precisam de uma nova análise.</div>
        <div class="d-flex flex-wrap gap-2 justify-content-between"><button type="submit" class="btn btn-info" name="save_intent" value="submit"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>>Enviar para análise</button><button type="submit" class="btn btn-outline-light" name="save_intent" value="draft"<cfif VARIABLES.paidBannerFormConflict> disabled</cfif>>Salvar como rascunho</button></div>
    </form>
</section>
</cfoutput>
<style>[data-banner-choices][hidden]{display:none!important}</style>
<script src="/assets/js/portal-banners.js" defer></script>
