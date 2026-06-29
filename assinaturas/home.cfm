<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<cfset VARIABLES.subscriptionHasBusinessAccount = false/>
<cfif isDefined("VARIABLES.businessEffectiveAccountIds")
    AND len(trim(VARIABLES.businessEffectiveAccountIds))
    AND VARIABLES.businessEffectiveAccountIds NEQ "0">
    <cfset VARIABLES.subscriptionHasBusinessAccount = true/>
</cfif>
<cfset VARIABLES.subscriptionRole = isDefined("VARIABLES.businessCurrentAccountRole") ? uCase(trim(VARIABLES.businessCurrentAccountRole)) : ""/>
<cfset VARIABLES.subscriptionRoleLabel = "Acesso Business"/>
<cfif VARIABLES.subscriptionRole EQ "OWNER">
    <cfset VARIABLES.subscriptionRoleLabel = "Proprietário"/>
<cfelseif VARIABLES.subscriptionRole EQ "ADMIN">
    <cfset VARIABLES.subscriptionRoleLabel = "Administrador"/>
<cfelseif VARIABLES.subscriptionRole EQ "OPERADOR">
    <cfset VARIABLES.subscriptionRoleLabel = "Operador"/>
<cfelseif VARIABLES.subscriptionRole EQ "VISUALIZADOR">
    <cfset VARIABLES.subscriptionRoleLabel = "Visualizador"/>
</cfif>

<!--- CONTEUDO --->

<section class="subscription-page business-page">
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0 business-page-card">
        <div class="card-body business-page-body">

          <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
            <div>
              <div class="business-label mb-2">Plano e acesso</div>
              <h3 class="business-page-title mb-2">Assinaturas</h3>
              <p class="text-muted mb-0">
                Acompanhe o plano liberado para sua empresa e use os atalhos certos quando precisar revisar limites, recursos ou atendimento comercial.
              </p>
            </div>
            <div class="business-page-actions">
              <a class="btn btn-sm btn-outline-warning" href="/suporte/?ticket_novo=1">Falar com suporte</a>
              <a class="btn btn-sm btn-outline-secondary" href="/administracao/contas/">Gestão da conta</a>
            </div>
          </div>

          <div class="business-panel p-3 mb-4">
            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
              <div>
                <div class="business-label mb-1">Plano atual</div>
                <h4 class="mb-1">Run Pro</h4>
                <p class="text-muted mb-0">
                  Base operacional para gerenciar eventos, inscrições, campanhas, cupons e usuários da empresa.
                </p>
              </div>
              <div class="text-lg-end">
                <span class="badge badge-warning">Ativo</span>
              </div>
            </div>

            <div class="business-metric-strip">
              <div class="business-mini-metric">
                <span class="business-label">Status</span>
                <strong><cfif VARIABLES.subscriptionHasBusinessAccount>Disponível<cfelse>Conta pendente</cfif></strong>
              </div>
              <div class="business-mini-metric">
                <span class="business-label">Seu papel</span>
                <strong><cfoutput>#htmlEditFormat(VARIABLES.subscriptionRoleLabel)#</cfoutput></strong>
              </div>
              <div class="business-mini-metric">
                <span class="business-label">Cobrança</span>
                <strong>Atendimento</strong>
              </div>
            </div>
          </div>

          <div class="business-step-grid mb-4">
            <div class="business-step <cfif VARIABLES.subscriptionHasBusinessAccount>is-complete<cfelse>is-current</cfif>">
              <div class="business-step-top">
                <span class="business-step-marker">1</span>
                <span class="business-step-status"><cfif VARIABLES.subscriptionHasBusinessAccount>Conta vinculada<cfelse>Primeiro passo</cfif></span>
              </div>
              <h5 class="mb-2">Empresa no Business</h5>
              <p class="text-muted small mb-0">
                A conta da empresa organiza usuários, permissões e eventos sob o mesmo acesso.
              </p>
              <div class="business-step-action">
                <a class="btn btn-sm btn-outline-warning" href="/administracao/contas/">Ver conta</a>
              </div>
            </div>

            <div class="business-step <cfif VARIABLES.subscriptionHasBusinessAccount>is-current<cfelse>is-muted</cfif>">
              <div class="business-step-top">
                <span class="business-step-marker">2</span>
                <span class="business-step-status">Recursos</span>
              </div>
              <h5 class="mb-2">Use os módulos liberados</h5>
              <p class="text-muted small mb-0">
                Eventos, inscrições, turbinados e cupons aparecem conforme os vínculos da sua empresa avançam.
              </p>
              <div class="business-step-action d-flex flex-wrap gap-2">
                <a class="btn btn-sm btn-outline-warning" href="/eventos/">Eventos</a>
                <a class="btn btn-sm btn-outline-secondary" href="/ads/">Marketing</a>
              </div>
            </div>

            <div class="business-step">
              <div class="business-step-top">
                <span class="business-step-marker">3</span>
                <span class="business-step-status">Comercial</span>
              </div>
              <h5 class="mb-2">Revise limites ou upgrade</h5>
              <p class="text-muted small mb-0">
                Para condições comerciais, mais eventos ou atendimento dedicado, abra um chamado e a equipe revisa o cenário.
              </p>
              <div class="business-step-action">
                <a class="btn btn-sm btn-outline-warning" href="/suporte/?ticket_novo=1">Solicitar revisão</a>
              </div>
            </div>
          </div>

          <div class="row g-4">
            <div class="col-12 col-lg-7">
              <div class="business-panel p-3 h-100">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1">Incluído no Run Pro</h5>
                    <p class="text-muted small mb-0">Recursos operacionais já considerados no fluxo principal do Business.</p>
                  </div>
                </div>

                <div class="row g-3">
                  <div class="col-12 col-md-6">
                    <div class="business-mini-metric h-100">
                      <span class="business-label">Eventos</span>
                      <strong>Gestão</strong>
                      <div class="small text-muted mt-2">Solicitação de vínculo, publicação e acompanhamento.</div>
                    </div>
                  </div>
                  <div class="col-12 col-md-6">
                    <div class="business-mini-metric h-100">
                      <span class="business-label">Vendas</span>
                      <strong>Inscrições</strong>
                      <div class="small text-muted mt-2">Consulta de pedidos, receita, influenciadores e assessorias.</div>
                    </div>
                  </div>
                  <div class="col-12 col-md-6">
                    <div class="business-mini-metric h-100">
                      <span class="business-label">Marketing</span>
                      <strong>Turbinados</strong>
                      <div class="small text-muted mt-2">Criação e acompanhamento de campanhas para eventos vinculados.</div>
                    </div>
                  </div>
                  <div class="col-12 col-md-6">
                    <div class="business-mini-metric h-100">
                      <span class="business-label">Promoções</span>
                      <strong>Cupons</strong>
                      <div class="small text-muted mt-2">Controle de descontos e leitura comercial por evento.</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="col-12 col-lg-5">
              <div class="business-empty-state h-100">
                <h5 class="mb-2">Precisa de algo fora do plano?</h5>
                <p class="text-muted mb-3">
                  Alterações de contrato, limites, cobrança e recursos especiais devem ser confirmados pelo atendimento. Assim evitamos mostrar valores ou promessas fora do combinado comercial.
                </p>
                <div class="business-empty-actions">
                  <a class="btn btn-sm btn-warning" href="/suporte/?ticket_novo=1">Abrir solicitação</a>
                  <a class="btn btn-sm btn-outline-secondary" href="/faq/">Ver FAQ</a>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
</section>
