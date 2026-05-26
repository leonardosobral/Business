<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <style>
    .subscription-page .subscription-kicker {
      color: var(--mdb-warning);
      font-size: .78rem;
      font-weight: 700;
      letter-spacing: .04em;
      text-transform: uppercase;
    }

    .subscription-page .subscription-intro {
      color: var(--mdb-secondary-color);
      max-width: 780px;
    }

    .subscription-page .subscription-card {
      border: 1px solid rgba(255, 255, 255, .12);
      border-radius: 8px;
      background: rgba(255, 255, 255, .03);
      display: flex;
      flex-direction: column;
      min-height: 100%;
      transition: border-color .2s ease, transform .2s ease, background .2s ease;
    }

    .subscription-page .subscription-card:hover {
      border-color: rgba(244, 177, 32, .55);
      background: rgba(255, 255, 255, .05);
      transform: translateY(-2px);
    }

    .subscription-page .subscription-card-current {
      border-color: rgba(244, 177, 32, .8);
      background: linear-gradient(180deg, rgba(244, 177, 32, .12), rgba(255, 255, 255, .035));
      box-shadow: 0 0 0 1px rgba(244, 177, 32, .12);
    }

    .subscription-page .subscription-plan-icon {
      align-items: center;
      border: 1px solid rgba(255, 255, 255, .16);
      border-radius: 8px;
      display: inline-flex;
      height: 42px;
      justify-content: center;
      width: 42px;
      background: rgba(255, 255, 255, .04);
    }

    .subscription-page .subscription-price {
      font-size: 2rem;
      font-weight: 700;
      line-height: 1;
    }

    .subscription-page .subscription-price small {
      color: var(--mdb-secondary-color);
      font-size: .9rem;
      font-weight: 500;
    }

    .subscription-page .subscription-list {
      list-style: none;
      margin: 0;
      padding: 0;
    }

    .subscription-page .subscription-list li {
      align-items: flex-start;
      display: flex;
      gap: .55rem;
      margin-bottom: .8rem;
      color: var(--mdb-body-color);
    }

    .subscription-page .subscription-list i {
      color: var(--mdb-warning);
      margin-top: .18rem;
    }

    .subscription-page .subscription-card .btn {
      margin-top: auto;
    }

    .subscription-page .subscription-note {
      border: 1px solid rgba(255, 255, 255, .12);
      border-radius: 8px;
      background: rgba(255, 255, 255, .03);
      color: var(--mdb-secondary-color);
      padding: 1rem;
    }
  </style>

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body subscription-page">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
            <div>
              <div class="subscription-kicker mb-2">Planos</div>
              <h3 class="mb-2">Assinaturas</h3>
              <p class="subscription-intro mb-0">
                Escolha uma base de recursos para operar eventos, acompanhar vendas e ativar ferramentas comerciais no RunnerHub Business.
              </p>
            </div>
            <div class="text-lg-end">
              <span class="badge badge-warning">Run Pro ativo</span>
            </div>
          </div>

          <hr/>

          <div class="row g-4 mb-4">
            <div class="col-lg-4">
              <div class="subscription-card subscription-card-current p-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-4">
                  <div class="subscription-plan-icon">
                    <i class="fa-solid fa-person-running"></i>
                  </div>
                  <span class="badge badge-warning">Plano atual</span>
                </div>

                <h4 class="mb-2">Run Pro</h4>
                <p class="text-muted mb-4">Para empresas que operam eventos e precisam acompanhar inscrições, campanhas e usuários em um só painel.</p>

                <div class="subscription-price mb-4">
                  R$ 249 <small>/mês</small>
                </div>

                <ul class="subscription-list mb-4">
                  <li><i class="fa-solid fa-check"></i><span>Até 8 eventos ativos por ciclo</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Relatórios de inscrições e cupons</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Gestão de usuários da empresa</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Suporte operacional pelo painel</span></li>
                </ul>

                <button type="button" class="btn btn-warning w-100" disabled>Plano ativo</button>
              </div>
            </div>

            <div class="col-lg-4">
              <div class="subscription-card p-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-4">
                  <div class="subscription-plan-icon">
                    <i class="fa-solid fa-chart-line"></i>
                  </div>
                  <span class="badge badge-secondary">Crescimento</span>
                </div>

                <h4 class="mb-2">Run Scale</h4>
                <p class="text-muted mb-4">Para operações em expansão, com mais eventos, campanhas recorrentes e acompanhamento comercial mais próximo.</p>

                <div class="subscription-price mb-4">
                  R$ 499 <small>/mês</small>
                </div>

                <ul class="subscription-list mb-4">
                  <li><i class="fa-solid fa-check"></i><span>Eventos ativos ilimitados</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Ads e cupons com visão consolidada</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Notificações para bases segmentadas</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Prioridade em chamados de suporte</span></li>
                </ul>

                <button type="button" class="btn btn-outline-warning w-100">Solicitar upgrade</button>
              </div>
            </div>

            <div class="col-lg-4">
              <div class="subscription-card p-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-4">
                  <div class="subscription-plan-icon">
                    <i class="fa-solid fa-crown"></i>
                  </div>
                  <span class="badge badge-secondary">Enterprise</span>
                </div>

                <h4 class="mb-2">Run Elite</h4>
                <p class="text-muted mb-4">Para grupos, circuitos e operações com múltiplas marcas que precisam de acompanhamento dedicado.</p>

                <div class="subscription-price mb-4">
                  Sob consulta
                </div>

                <ul class="subscription-list mb-4">
                  <li><i class="fa-solid fa-check"></i><span>Ambiente comercial personalizado</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Integrações e relatórios sob demanda</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Onboarding assistido para equipes</span></li>
                  <li><i class="fa-solid fa-check"></i><span>Gestão dedicada de relacionamento</span></li>
                </ul>

                <button type="button" class="btn btn-outline-light w-100">Falar com atendimento</button>
              </div>
            </div>
          </div>

          <div class="subscription-note">
            Valores e recursos exibidos são fictícios e servem como base inicial para revisão comercial.
          </div>

        </div>

      </div>

    </div>

  </div>

</section>
