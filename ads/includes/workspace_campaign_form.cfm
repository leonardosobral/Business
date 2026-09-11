<cfset VARIABLES.adsV1PreviewEventName = "Selecione um evento vinculado"/>
<cfset VARIABLES.adsV1PreviewEventCity = ""/>
<cfset VARIABLES.adsV1PreviewEventState = ""/>
<cfset VARIABLES.adsV1PreviewEventDate = ""/>
<cfset VARIABLES.adsV1PreviewEventTag = ""/>
<cfset VARIABLES.adsV1PreviewEventImage = ""/>
<cfset VARIABLES.adsV1PreviewEventStatus = ""/>
<cfloop query="qAdsV1Events">
  <cfif val(qAdsV1Events.id_evento) EQ VARIABLES.adsV1FormEventId>
    <cfset VARIABLES.adsV1PreviewEventName = qAdsV1Events.nome_evento & ""/>
    <cfset VARIABLES.adsV1PreviewEventCity = qAdsV1Events.cidade & ""/>
    <cfset VARIABLES.adsV1PreviewEventState = qAdsV1Events.estado & ""/>
    <cfset VARIABLES.adsV1PreviewEventDate = isDate(qAdsV1Events.data_final) ? dateFormat(qAdsV1Events.data_final, "dd/mm/yyyy") : ""/>
    <cfset VARIABLES.adsV1PreviewEventTag = qAdsV1Events.tag & ""/>
    <cfset VARIABLES.adsV1PreviewEventStatus = qAdsV1Events.event_link_status & ""/>
    <cfset VARIABLES.adsV1PreviewEventImage = adsV1EventImageUrl(len(trim(qAdsV1Events.url_imagem_listagem & "")) ? qAdsV1Events.url_imagem_listagem : (len(trim(qAdsV1Events.url_imagem & "")) ? qAdsV1Events.url_imagem : qAdsV1Events.imagem))/>
    <cfbreak/>
  </cfif>
</cfloop>

<style>
  .ads-wizard-shell { background: rgba(255,255,255,.025); border: 1px solid rgba(98,199,216,.18); }
  .ads-wizard-header { border-bottom: 1px solid rgba(255,255,255,.08); }
  .ads-wizard-steps { display: grid; gap: .5rem; grid-template-columns: repeat(4,minmax(0,1fr)); }
  .ads-wizard-step-button { align-items: center; background: transparent; border: 0; color: var(--mdb-secondary-color); display: flex; font-size: .78rem; font-weight: 700; gap: .55rem; min-width: 0; padding: .7rem .25rem; text-align: left; }
  .ads-wizard-step-button:not(:disabled) { cursor: pointer; }
  .ads-wizard-step-number { align-items: center; border: 1px solid rgba(255,255,255,.28); border-radius: 50%; display: inline-flex; flex: 0 0 30px; height: 30px; justify-content: center; }
  .ads-wizard-step-button.is-active { color: #78d3e1; }
  .ads-wizard-step-button.is-active .ads-wizard-step-number { background: #62c7d8; border-color: #62c7d8; color: #10252a; }
  .ads-wizard-step-button.is-complete { color: #76d4a6; }
  .ads-wizard-step-button.is-complete .ads-wizard-step-number { background: rgba(25,167,106,.18); border-color: #25a76a; }
  .ads-wizard-panel[hidden] { display: none !important; }
  .ads-wizard-panel-title { font-size: 1.25rem; font-weight: 750; }
  .ads-wizard-help { color: var(--mdb-secondary-color); font-size: .88rem; line-height: 1.55; }
  .ads-event-choice { border: 1px solid rgba(255,255,255,.13); border-radius: .45rem; padding: 1rem; }
  .ads-cpc-grid { display: grid; gap: .75rem; grid-template-columns: repeat(3,minmax(0,1fr)); }
  .ads-cpc-option { display: block; height: 100%; position: relative; }
  .ads-cpc-option input { opacity: 0; position: absolute; }
  .ads-cpc-card { border: 1px solid rgba(255,255,255,.16); border-radius: .45rem; cursor: pointer; display: block; height: 100%; padding: 1rem; transition: border-color .15s ease, background .15s ease; }
  .ads-cpc-option input:checked + .ads-cpc-card { background: rgba(250,177,32,.07); border-color: #fab120; box-shadow: inset 0 0 0 1px rgba(250,177,32,.2); }
  .ads-cpc-option input:focus-visible + .ads-cpc-card { outline: 2px solid #78d3e1; outline-offset: 2px; }
  .ads-cpc-value { display: block; font-size: 1.4rem; font-weight: 800; margin: .35rem 0; }
  .ads-estimate-box { background: rgba(10,91,108,.28); border: 1px solid rgba(98,199,216,.32); border-radius: .5rem; min-height: 100%; padding: 1rem; }
  .ads-estimate-value { color: #8ee4f2; font-size: 1.55rem; font-weight: 800; line-height: 1.2; }
  .ads-placement-grid { display: grid; gap: .65rem; grid-template-columns: 1fr; }
  .ads-placement-card { align-items: flex-start; border: 1px solid rgba(255,255,255,.14); border-radius: .45rem; display: flex; gap: .75rem; padding: .9rem 1rem; }
  .ads-placement-card:has(input:checked) { background: rgba(98,199,216,.07); border-color: #62c7d8; }
  .ads-placement-copy { min-width: 0; }
  .ads-preview-panel { background: #181a1d; border: 1px solid rgba(255,255,255,.12); border-radius: .5rem; min-height: 100%; overflow: hidden; position: sticky; top: 90px; }
  .ads-preview-toolbar { border-bottom: 1px solid rgba(255,255,255,.09); padding: 1rem; }
  .ads-preview-tabs { display: flex; flex-wrap: wrap; gap: .4rem; }
  .ads-preview-tab { background: transparent; border: 1px solid rgba(255,255,255,.13); border-radius: .3rem; color: var(--mdb-secondary-color); font-size: .72rem; font-weight: 700; padding: .45rem .6rem; }
  .ads-preview-tab.is-active { border-color: #62c7d8; color: #78d3e1; }
  .ads-preview-site { padding: 1rem; }
  .ads-preview-site-header { align-items: center; border-bottom: 1px solid rgba(255,255,255,.08); display: flex; justify-content: space-between; margin-bottom: 1rem; padding-bottom: .75rem; }
  .ads-preview-brand { font-size: .95rem; font-style: italic; font-weight: 900; letter-spacing: -.04em; }
  .ads-native-event { border: 1px solid #fab120; border-radius: .35rem; overflow: hidden; }
  .ads-native-sponsored { color: #fab120; font-size: .68rem; font-weight: 800; letter-spacing: .05em; padding: .55rem .75rem 0; text-transform: uppercase; }
  .ads-native-body { display: grid; gap: .9rem; grid-template-columns: 135px minmax(0,1fr); padding: .65rem .75rem .85rem; }
  .ads-native-image { background: rgba(255,255,255,.05); border-radius: .25rem; height: 132px; object-fit: cover; width: 100%; }
  .ads-native-image-placeholder { align-items: center; background: rgba(255,255,255,.05); border-radius: .25rem; color: #fab120; display: flex; font-size: 2rem; height: 132px; justify-content: center; }
  .ads-native-title { font-size: 1rem; font-weight: 800; line-height: 1.25; margin-bottom: .55rem; }
  .ads-native-meta { color: var(--mdb-secondary-color); font-size: .75rem; line-height: 1.55; }
  .ads-preview-note { background: rgba(10,91,108,.22); border-top: 1px solid rgba(98,199,216,.22); color: #8ee4f2; font-size: .78rem; padding: .8rem 1rem; }
  .ads-wizard-actions { border-top: 1px solid rgba(255,255,255,.08); }
  .ads-wizard-error { color: #ff9f9f; display: none; font-size: .82rem; }
  .ads-wizard-error.is-visible { display: block; }
  @media (max-width: 991.98px) { .ads-preview-panel { position: static; } }
  @media (max-width: 767.98px) {
    .ads-wizard-steps { grid-template-columns: repeat(2,minmax(0,1fr)); }
    .ads-cpc-grid, .ads-placement-grid { grid-template-columns: 1fr; }
    .ads-native-body { grid-template-columns: 95px minmax(0,1fr); }
    .ads-native-image, .ads-native-image-placeholder { height: 104px; }
  }
</style>

<section class="card shadow-0 mb-4 ads-wizard-shell<cfif VARIABLES.adsV1IsFirstCampaign> ads-first-campaign</cfif>" id="campaign-form">
  <div class="card-body p-0">
    <header class="ads-wizard-header p-3 p-lg-4">
      <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
        <div>
          <div class="ads-v1-eyebrow"><cfif VARIABLES.adsV1IsFirstCampaign>Primeira campanha<cfelse>Campanha de evento</cfif></div>
          <h2 class="h4 mb-1"><cfif len(VARIABLES.adsV1FormCampaignId)>Editar campanha<cfelse>Criar campanha de evento</cfif></h2>
          <p class="text-muted mb-0">O anúncio usa automaticamente os dados e a imagem do evento vinculado.</p>
        </div>
        <cfif NOT VARIABLES.adsV1IsFirstCampaign><a class="btn btn-sm btn-outline-light" href="./?view=campaigns">Fechar formulário</a></cfif>
      </div>

      <nav class="ads-wizard-steps" aria-label="Etapas da campanha">
        <button class="ads-wizard-step-button is-active" type="button" data-wizard-step-button="1" aria-current="step"><span class="ads-wizard-step-number">1</span><span>Evento</span></button>
        <button class="ads-wizard-step-button" type="button" data-wizard-step-button="2" disabled><span class="ads-wizard-step-number">2</span><span>Investimento</span></button>
        <button class="ads-wizard-step-button" type="button" data-wizard-step-button="3" disabled><span class="ads-wizard-step-number">3</span><span>Período e público</span></button>
        <button class="ads-wizard-step-button" type="button" data-wizard-step-button="4" disabled><span class="ads-wizard-step-number">4</span><span>Onde aparecerá</span></button>
      </nav>
    </header>

    <cfif VARIABLES.adsV1IsCampaignCreationFocus AND VARIABLES.adsAccessIsPendingNewAccount>
      <div class="alert alert-info rounded-0 border-start-0 border-end-0 d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2 mb-0">
        <span><strong>Prepare agora.</strong> A campanha ficará em rascunho ou espera e não entrará no ar antes das aprovações.</span>
        <cfif qAdsV1VoucherReservation.recordcount AND uCase(trim(qAdsV1VoucherReservation.status & "")) EQ "RESERVED"><span class="badge badge-warning flex-shrink-0">Voucher reservado: <cfoutput>#lsCurrencyFormat(qAdsV1VoucherReservation.credito)#</cfoutput></span></cfif>
      </div>
    </cfif>

    <cfif NOT VARIABLES.adsV1CampaignEditable>
      <div class="p-3 p-lg-4"><div class="alert alert-warning mb-0">Somente rascunhos ou campanhas pausadas podem ser editados.</div></div>
    <cfelseif NOT qAdsV1Events.recordcount>
      <div class="p-3 p-lg-4"><div class="alert alert-warning mb-0">Esta conta não possui eventos ativos ou pendentes autorizados para preparar a campanha.</div></div>
    <cfelseif NOT qAdsV1Placements.recordcount>
      <div class="p-3 p-lg-4"><div class="alert alert-warning mb-0">Nenhum local de exibição está disponível.</div></div>
    <cfelse>
      <form method="post" action="./?view=campaigns#campaign-form" id="ads-campaign-wizard" data-initial-step="<cfif FORM.ads_v1_action EQ 'save_campaign' AND len(VARIABLES.adsV1Error)>4<cfelse>1</cfif>" data-is-new="<cfif len(VARIABLES.adsV1FormCampaignId)>false<cfelse>true</cfif>" novalidate>
        <input type="hidden" name="ads_v1_action" value="save_campaign"/>
        <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
        <input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCampaignId)#</cfoutput>"/>

        <div class="row g-0">
          <div class="col-lg-7 p-3 p-lg-4">
            <section class="ads-wizard-panel" data-wizard-panel="1">
              <div class="ads-v1-eyebrow mb-2">Passo 1 de 4</div>
              <h3 class="ads-wizard-panel-title mb-2">Qual evento você quer divulgar?</h3>
              <p class="ads-wizard-help mb-4">Você só pode anunciar eventos já vinculados ou com vínculo solicitado pela sua conta. Não é necessário criar arte ou escrever outro anúncio.</p>

              <div class="mb-3">
                <label class="form-label" for="ads-v1-event">Evento vinculado</label>
                <select class="form-select" id="ads-v1-event" name="core_event_id" required>
                  <option value="">Selecione um evento</option>
                  <cfoutput query="qAdsV1Events">
                    <cfset VARIABLES.adsV1EventImageRaw = len(trim(qAdsV1Events.url_imagem_listagem & "")) ? qAdsV1Events.url_imagem_listagem : (len(trim(qAdsV1Events.url_imagem & "")) ? qAdsV1Events.url_imagem : qAdsV1Events.imagem)/>
                    <cfset VARIABLES.adsV1EventImageResolved = adsV1EventImageUrl(VARIABLES.adsV1EventImageRaw)/>
                    <option value="#id_evento#" data-event-name="#htmlEditFormat(nome_evento)#" data-event-city="#htmlEditFormat(cidade)#" data-event-state="#htmlEditFormat(estado)#" data-event-tag="#htmlEditFormat(tag)#" data-event-start="#isDate(data_inicial) ? dateFormat(data_inicial, 'yyyy-mm-dd') : ''#" data-event-end="#isDate(data_final) ? dateFormat(data_final, 'yyyy-mm-dd') : ''#" data-event-date="#isDate(data_final) ? dateFormat(data_final, 'dd/mm/yyyy') : ''#" data-event-image="#htmlEditFormat(VARIABLES.adsV1EventImageResolved)#" data-event-status="#htmlEditFormat(event_link_status)#" <cfif val(id_evento) EQ VARIABLES.adsV1FormEventId>selected</cfif>>#htmlEditFormat(nome_evento)# — #htmlEditFormat(cidade)#/#htmlEditFormat(estado)#<cfif isDate(data_final)> — #dateFormat(data_final, 'dd/mm/yyyy')#</cfif> <cfif uCase(event_link_status & '') EQ 'PENDENTE'>(vínculo em análise)</cfif></option>
                  </cfoutput>
                </select>
                <div class="invalid-feedback">Selecione um evento vinculado.</div>
              </div>

              <div>
                <label class="form-label" for="ads-v1-name">Nome interno da campanha</label>
                <input class="form-control" id="ads-v1-name" name="name" minlength="3" maxlength="160" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormName)#</cfoutput>" placeholder="Ex.: Divulgação — nome do evento"/>
                <div class="form-text">Esse nome serve apenas para você encontrar a campanha no Business.</div>
                <div class="invalid-feedback">Informe um nome com pelo menos 3 caracteres.</div>
              </div>
            </section>

            <section class="ads-wizard-panel" data-wizard-panel="2" hidden>
              <div class="ads-v1-eyebrow mb-2">Passo 2 de 4</div>
              <h3 class="ads-wizard-panel-title mb-2">Defina seu investimento</h3>
              <p class="ads-wizard-help mb-4"><strong>CPC</strong> é seu lance máximo por clique. O leilão combina aderência regional e lance: entre anúncios com relevância parecida, um lance maior aumenta a chance de aparecer primeiro. Nenhuma posição é garantida.</p>

              <fieldset class="mb-4">
                <legend class="form-label mb-2">Escolha seu lance por clique</legend>
                <div class="ads-cpc-grid">
                  <label class="ads-cpc-option"><input type="radio" name="ads_cpc_option" value="0.56"/><span class="ads-cpc-card"><strong>Econômico</strong><span class="ads-cpc-value">R$ 0,56</span><span class="small text-muted">Menor custo por clique e alcance mais limitado.</span></span></label>
                  <label class="ads-cpc-option"><input type="radio" name="ads_cpc_option" value="0.94"/><span class="ads-cpc-card"><strong>Recomendado</strong><span class="ads-cpc-value">R$ 0,94</span><span class="small text-muted">Equilíbrio entre alcance e custo por clique.</span></span></label>
                  <label class="ads-cpc-option"><input type="radio" name="ads_cpc_option" value="1.32"/><span class="ads-cpc-card"><strong>Mais alcance</strong><span class="ads-cpc-value">R$ 1,32</span><span class="small text-muted">Maior alcance potencial em disputas concorridas.</span></span></label>
                </div>
              </fieldset>

              <div class="row g-3 align-items-stretch">
                <div class="col-md-6">
                  <label class="form-label" for="ads-v1-cpc">Seu lance (CPC)</label>
                  <div class="input-group"><span class="input-group-text">R$</span><input class="form-control" id="ads-v1-cpc" type="number" name="cpc_bid" min="0.51" step="0.01" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCpcRaw)#</cfoutput>"/></div>
                  <div class="form-text">Lance mínimo de R$ 0,51. Você paga no máximo esse valor e pode pagar menos: somente o necessário para superar o próximo anúncio.</div>
                </div>
                <div class="col-md-6">
                  <label class="form-label" for="ads-v1-total">Orçamento total</label>
                  <div class="input-group"><span class="input-group-text">R$</span><input class="form-control" id="ads-v1-total" type="number" name="budget_total" min="0.01" step="0.01" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormBudgetTotalRaw)#</cfoutput>"/></div>
                  <div class="form-text">Valor máximo reservado para a campanha.</div>
                </div>
                <div class="col-md-6">
                  <label class="form-label" for="ads-v1-daily">Limite diário <span class="text-muted">(opcional)</span></label>
                  <div class="input-group"><span class="input-group-text">R$</span><input class="form-control" id="ads-v1-daily" type="number" name="budget_daily" min="0.01" step="0.01" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormBudgetDailyRaw)#</cfoutput>" placeholder="Ex.: 20,00"/></div>
                  <div class="form-text">Controla quanto pode ser gasto em um dia.</div>
                </div>
                <div class="col-md-6">
                  <div class="ads-estimate-box" aria-live="polite">
                    <div class="ads-v1-eyebrow mb-2">Estimativa</div>
                    <div class="ads-estimate-value"><span id="ads-estimate-min">0</span> a <span id="ads-estimate-max">0</span> cliques</div>
                    <p class="small text-muted mb-0 mt-2">O valor real pode variar conforme concorrência, período e público. Esta estimativa não é garantia.</p>
                  </div>
                </div>
              </div>
              <div class="ads-wizard-error mt-3" data-step-error="2">Revise o CPC, o orçamento e o limite diário.</div>
            </section>

            <section class="ads-wizard-panel" data-wizard-panel="3" hidden>
              <div class="ads-v1-eyebrow mb-2">Passo 3 de 4</div>
              <h3 class="ads-wizard-panel-title mb-2">Escolha o período e o público</h3>
              <p class="ads-wizard-help mb-4">Para campanhas de evento, sugerimos terminar poucos dias antes da prova. Assim você concentra o investimento enquanto ainda há tempo para o atleta agir.</p>

              <div class="row g-3">
                <div class="col-md-6"><label class="form-label" for="ads-v1-start">Início</label><input class="form-control" id="ads-v1-start" type="datetime-local" name="starts_at" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormStartsDisplay)#</cfoutput>"/></div>
                <div class="col-md-6"><label class="form-label" for="ads-v1-end">Fim</label><input class="form-control" id="ads-v1-end" type="datetime-local" name="ends_at" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormEndsDisplay)#</cfoutput>"/><div class="form-text" id="ads-end-suggestion">Sugerimos encerrar 3 dias antes do evento.</div></div>
                <div class="col-md-4"><label class="form-label" for="ads-v1-device">Dispositivo</label><select class="form-select" id="ads-v1-device" name="target_device_class"><option value="ALL" <cfif VARIABLES.adsV1FormDevice EQ "ALL">selected</cfif>>Todos</option><option value="DESKTOP" <cfif VARIABLES.adsV1FormDevice EQ "DESKTOP">selected</cfif>>Desktop</option><option value="MOBILE" <cfif VARIABLES.adsV1FormDevice EQ "MOBILE">selected</cfif>>Celular</option></select></div>
                <div class="col-md-4"><label class="form-label" for="ads-v1-country">País</label><input class="form-control text-uppercase" id="ads-v1-country" name="target_country_code" maxlength="2" pattern="[A-Za-z]{2}" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCountry)#</cfoutput>"/></div>
                <div class="col-md-4"><label class="form-label" for="ads-v1-region">Estado ou região</label><input class="form-control text-uppercase" id="ads-v1-region" name="target_region_code" maxlength="40" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormRegion)#</cfoutput>" placeholder="Opcional, ex.: BA"/></div>
              </div>
              <div class="ads-wizard-error mt-3" data-step-error="3">O fim precisa ser posterior ao início. Revise também o país informado.</div>
            </section>

            <section class="ads-wizard-panel" data-wizard-panel="4" hidden>
              <div class="ads-v1-eyebrow mb-2">Passo 4 de 4</div>
              <h3 class="ads-wizard-panel-title mb-2">Em quais áreas seu evento poderá concorrer?</h3>
              <p class="ads-wizard-help mb-3">Escolha as áreas do RoadRunners. Você não compra uma posição fixa: em cada área, a ordem é calculada pela aderência regional e pelo lance.</p>
              <div class="alert alert-info py-2 px-3 mb-3"><strong>Página inicial:</strong> uma única seleção habilita os dois destaques. O anúncio com melhor ranking aparece primeiro e o seguinte aparece depois.</div>

              <fieldset>
                <legend class="visually-hidden">Locais de exibição</legend>
                <div class="ads-placement-grid">
                  <cfoutput query="qAdsV1Placements">
                    <label class="ads-placement-card" for="ads-v1-placement-#currentRow#">
                      <input class="form-check-input flex-shrink-0 mt-1" id="ads-v1-placement-#currentRow#" type="checkbox" name="placement_keys" value="#htmlEditFormat(placement_key)#" data-placement-label="#htmlEditFormat(adsV1PlacementLabel(placement_key))#" <cfif arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, placement_key)>checked</cfif>/>
                      <span class="ads-placement-copy"><strong class="d-block">#htmlEditFormat(adsV1PlacementLabel(placement_key))#</strong><span class="d-block small text-muted mt-1">#htmlEditFormat(adsV1PlacementDescription(placement_key))#</span></span>
                    </label>
                  </cfoutput>
                </div>
              </fieldset>
              <div class="ads-wizard-error mt-3" data-step-error="4">Selecione pelo menos um local de exibição.</div>
              <div class="alert alert-info mt-4 mb-0"><strong>Antes de entrar no ar:</strong> a campanha ficará em rascunho e precisará da aprovação da conta, do evento e da equipe RunnerHub.</div>
            </section>
          </div>

          <aside class="col-lg-5 p-3 p-lg-4 ps-lg-0">
            <div class="ads-preview-panel">
              <div class="ads-preview-toolbar">
                <div class="ads-v1-eyebrow mb-1">Prévia no site</div>
                <p class="small text-muted mb-3">Veja como seu evento poderá aparecer para os atletas.</p>
                <div class="ads-preview-tabs" aria-label="Local da prévia">
                  <button type="button" class="ads-preview-tab is-active" data-preview-placement="Página inicial">Página inicial</button>
                  <button type="button" class="ads-preview-tab" data-preview-placement="Busca de eventos">Busca de eventos</button>
                  <button type="button" class="ads-preview-tab" data-preview-placement="Eventos por estado">Por estado</button>
                  <button type="button" class="ads-preview-tab" data-preview-placement="Página do evento">Página do evento</button>
                </div>
              </div>
              <div class="ads-preview-site">
                <div class="ads-preview-site-header"><span class="ads-preview-brand">RUN// ROADRUNNERS</span><span class="small text-muted" id="ads-preview-location">Página inicial</span></div>
                <div class="small fw-bold mb-2 text-uppercase">Próximos eventos</div>
                <article class="ads-native-event">
                  <div class="ads-native-sponsored">Patrocinado</div>
                  <div class="ads-native-body">
                    <cfif len(VARIABLES.adsV1PreviewEventImage)><img class="ads-native-image" id="ads-preview-image" src="<cfoutput>#htmlEditFormat(VARIABLES.adsV1PreviewEventImage)#</cfoutput>" alt=""/><div class="ads-native-image-placeholder" id="ads-preview-image-placeholder" hidden><i class="fa-solid fa-flag-checkered" aria-hidden="true"></i></div><cfelse><img class="ads-native-image" id="ads-preview-image" src="" alt="" hidden/><div class="ads-native-image-placeholder" id="ads-preview-image-placeholder"><i class="fa-solid fa-flag-checkered" aria-hidden="true"></i></div></cfif>
                    <div>
                      <div class="ads-native-title" id="ads-preview-name"><cfoutput>#htmlEditFormat(VARIABLES.adsV1PreviewEventName)#</cfoutput></div>
                      <div class="ads-native-meta"><span id="ads-preview-date"><cfoutput>#htmlEditFormat(VARIABLES.adsV1PreviewEventDate)#</cfoutput></span><br/><span id="ads-preview-city"><cfoutput>#htmlEditFormat(VARIABLES.adsV1PreviewEventCity)#<cfif len(VARIABLES.adsV1PreviewEventState)>/#htmlEditFormat(VARIABLES.adsV1PreviewEventState)#</cfif></cfoutput></span></div>
                      <a class="btn btn-sm btn-outline-light mt-3<cfif NOT len(VARIABLES.adsV1PreviewEventTag)> disabled</cfif>" id="ads-preview-link" href="<cfif len(VARIABLES.adsV1PreviewEventTag)><cfoutput>https://roadrunners.run/evento/#urlEncodedFormat(VARIABLES.adsV1PreviewEventTag)#/</cfoutput><cfelse>#</cfif>" target="_blank" rel="noopener">Ver evento</a>
                    </div>
                  </div>
                </article>
              </div>
              <div class="ads-preview-note"><i class="fa-solid fa-circle-info me-1" aria-hidden="true"></i> O anúncio usa os dados e a imagem do evento vinculado. Não há envio de arte ou anúncio de outro produto.</div>
            </div>
          </aside>
        </div>

        <footer class="ads-wizard-actions d-flex flex-column flex-sm-row justify-content-between gap-2 p-3 p-lg-4">
          <button class="btn btn-outline-light" id="ads-wizard-back" type="button" hidden><i class="fa-solid fa-arrow-left me-2" aria-hidden="true"></i>Voltar</button>
          <span class="d-none d-sm-block"></span>
          <button class="btn btn-info" id="ads-wizard-next" type="button">Continuar<i class="fa-solid fa-arrow-right ms-2" aria-hidden="true"></i></button>
          <button class="btn btn-info" id="ads-wizard-submit" type="submit" hidden>Salvar rascunho<i class="fa-solid fa-check ms-2" aria-hidden="true"></i></button>
        </footer>
      </form>
      <script src="/assets/js/ads-campaign-wizard.js?v=20260902-2"></script>
    </cfif>
  </div>
</section>
