<style>
  .events-onboarding-card {
    border: 1px solid rgba(244, 177, 32, .24);
    background: rgba(255, 255, 255, .03);
    border-radius: .5rem;
  }

  .events-onboarding-kicker {
    color: var(--mdb-warning);
    font-size: .78rem;
    font-weight: 700;
    text-transform: uppercase;
  }

  .events-onboarding-steps {
    display: grid;
    gap: .85rem;
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .events-onboarding-step {
    background: rgba(255,255,255,.04);
    border: 1px solid rgba(255,255,255,.09);
    border-radius: .5rem;
    display: flex;
    flex-direction: column;
    min-height: 190px;
    padding: 1rem;
  }

  .events-onboarding-number {
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

  .events-onboarding-action {
    margin-top: auto;
    padding-top: 1rem;
  }

  @media (max-width: 991.98px) {
    .events-onboarding-steps {
      grid-template-columns: 1fr;
    }
  }
</style>

<section class="mb-4" id="primeiro-evento">
  <div class="events-onboarding-card p-3 p-lg-4">
    <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
      <div>
        <div class="events-onboarding-kicker mb-1">Primeiro evento</div>
        <h4 class="mb-1">Vincule uma prova à sua conta</h4>
        <p class="text-muted mb-0">Busque o evento no RoadRunners e envie a solicitação. Depois da aprovação, ele aparece para edição, conteúdo, Turbinados e cupons.</p>
      </div>
      <cfif isDefined("VARIABLES.eventosShowRequestPanel") AND VARIABLES.eventosShowRequestPanel>
        <a class="btn btn-outline-warning align-self-lg-start" href="#event-request-panel">Ver solicitações</a>
      </cfif>
    </div>

    <div class="events-onboarding-steps">
      <div class="events-onboarding-step">
        <span class="events-onboarding-number">1</span>
        <h5 class="mb-2">Encontre a prova</h5>
        <p class="text-muted mb-3">Cole a URL do RoadRunners, a tag, o ID ou parte do nome da prova.</p>
        <form method="get" action="/eventos/" class="events-onboarding-action">
          <cfif isDefined("qEventoSolicitacaoContas") AND qEventoSolicitacaoContas.recordcount GT 1>
            <select class="form-select mb-2" name="id_conta_solicitacao" aria-label="Conta">
              <cfoutput query="qEventoSolicitacaoContas">
                <option value="#qEventoSolicitacaoContas.id_conta#" <cfif VARIABLES.eventoSolicitacaoSelectedAccountId EQ qEventoSolicitacaoContas.id_conta>selected</cfif>>#htmlEditFormat(qEventoSolicitacaoContas.nome_conta)#</option>
              </cfoutput>
            </select>
          <cfelseif len(trim(VARIABLES.eventoSolicitacaoSelectedAccountId))>
            <cfoutput><input type="hidden" name="id_conta_solicitacao" value="#htmlEditFormat(VARIABLES.eventoSolicitacaoSelectedAccountId)#"/></cfoutput>
          </cfif>
          <div class="input-group">
            <input class="form-control" type="text" name="evento_referencia" placeholder="https://roadrunners.run/evento/..."/>
            <button class="btn btn-outline-warning" type="submit">Buscar</button>
          </div>
        </form>
      </div>

      <div class="events-onboarding-step">
        <span class="events-onboarding-number">2</span>
        <h5 class="mb-2">Solicite o vínculo</h5>
        <p class="text-muted mb-0">Ao encontrar a prova, clique em Solicitar. O evento fica pendente até a validação da equipe RunnerHub.</p>
        <div class="events-onboarding-action">
          <cfif isDefined("VARIABLES.eventosShowRequestPanel") AND VARIABLES.eventosShowRequestPanel>
            <a class="btn btn-warning w-100" href="#event-request-panel">Acompanhar busca</a>
          <cfelse>
            <span class="btn btn-outline-light disabled w-100">Busque acima</span>
          </cfif>
        </div>
      </div>

      <div class="events-onboarding-step">
        <span class="events-onboarding-number">3</span>
        <h5 class="mb-2">Comece a operar</h5>
        <p class="text-muted mb-0">Quando o vínculo for aprovado, a prova entra na sua lista e libera as ações da conta.</p>
        <div class="events-onboarding-action">
          <cfif VARIABLES.eventoMinhasSolicitacoesPendentes GT 0>
            <span class="btn btn-outline-warning disabled w-100"><cfoutput>#VARIABLES.eventoMinhasSolicitacoesPendentes#</cfoutput> em análise</span>
          <cfelse>
            <span class="btn btn-outline-light disabled w-100">Aguardando vínculo</span>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
