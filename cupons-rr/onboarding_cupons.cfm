<style>
  .coupons-onboarding-card {
    border: 1px solid rgba(244, 177, 32, .24);
    background: rgba(255, 255, 255, .03);
    border-radius: .5rem;
  }

  .coupons-onboarding-kicker {
    color: var(--mdb-warning);
    font-size: .78rem;
    font-weight: 700;
    text-transform: uppercase;
  }

  .coupons-onboarding-steps {
    display: grid;
    gap: .85rem;
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .coupons-onboarding-step {
    background: rgba(255,255,255,.04);
    border: 1px solid rgba(255,255,255,.09);
    border-radius: .5rem;
    display: flex;
    flex-direction: column;
    min-height: 220px;
    padding: 1rem;
  }

  .coupons-onboarding-number {
    align-items: center;
    background: var(--mdb-warning);
    border-radius: 999px;
    color: #111;
    display: inline-flex;
    font-weight: 800;
    height: 30px;
    justify-content: center;
    margin-bottom: .75rem;
    width: 30px;
  }

  .coupons-onboarding-action {
    margin-top: auto;
    padding-top: 1rem;
  }

  @media (max-width: 991.98px) {
    .coupons-onboarding-steps {
      grid-template-columns: 1fr;
    }
  }
</style>

<section class="mb-4" id="primeiro-cupom">
  <div class="coupons-onboarding-card p-3 p-lg-4">
    <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
      <div>
        <div class="coupons-onboarding-kicker mb-1">Primeiro cupom</div>
        <h4 class="mb-1">Libere cupons para os eventos da sua conta</h4>
        <p class="text-muted mb-0">Cupons aparecem aqui quando estão associados aos seus eventos, circuitos ou páginas. Use este fluxo para preparar o primeiro vínculo.</p>
      </div>
      <cfif VARIABLES.cuponsRrHasLinkedEvents>
        <a class="btn btn-warning align-self-lg-start" href="/suporte/?ticket_novo=1">Solicitar cupom</a>
      <cfelse>
        <a class="btn btn-outline-warning align-self-lg-start" href="/eventos/">Vincular evento</a>
      </cfif>
    </div>

    <div class="coupons-onboarding-steps">
      <div class="coupons-onboarding-step">
        <span class="coupons-onboarding-number">1</span>
        <h5 class="mb-2">Tenha um evento vinculado</h5>
        <p class="text-muted mb-0">Os cupons da conta dependem dos eventos vinculados. Se a prova ainda não aparece no Business, solicite o vínculo primeiro.</p>
        <div class="coupons-onboarding-action">
          <cfif VARIABLES.cuponsRrHasLinkedEvents>
            <span class="btn btn-outline-success disabled w-100">Evento vinculado</span>
          <cfelse>
            <a class="btn btn-outline-warning w-100" href="/eventos/">Ir para Eventos</a>
          </cfif>
        </div>
      </div>

      <div class="coupons-onboarding-step">
        <span class="coupons-onboarding-number">2</span>
        <h5 class="mb-2">Solicite o cupom</h5>
        <p class="text-muted mb-0">Informe a prova, o código desejado, regra de desconto e período de validade para a equipe RunnerHub liberar o uso.</p>
        <div class="coupons-onboarding-action">
          <cfif VARIABLES.cuponsRrHasLinkedEvents>
            <a class="btn btn-warning w-100" href="/suporte/?ticket_novo=1">Abrir solicitação</a>
          <cfelse>
            <span class="btn btn-outline-light disabled w-100">Aguardando evento</span>
          </cfif>
        </div>
      </div>

      <div class="coupons-onboarding-step">
        <span class="coupons-onboarding-number">3</span>
        <h5 class="mb-2">Acompanhe os vínculos</h5>
        <p class="text-muted mb-0">Depois de liberado, o cupom aparece nesta tela para consulta por prova, circuito ou página.</p>
        <div class="coupons-onboarding-action">
          <span class="btn btn-outline-light disabled w-100">Nenhum cupom ainda</span>
        </div>
      </div>
    </div>
  </div>
</section>
