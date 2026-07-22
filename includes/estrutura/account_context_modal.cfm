<cfparam name="VARIABLES.businessAccountModalRequired" default="false"/>

<cfset VARIABLES.businessAccountModalRedirect = "/"/>
<cfif NOT VARIABLES.businessAccountModalRequired>
    <cfset VARIABLES.businessAccountModalRedirect = CGI.SCRIPT_NAME/>
    <cfif len(trim(CGI.QUERY_STRING))>
        <cfset VARIABLES.businessAccountModalRedirect = VARIABLES.businessAccountModalRedirect & "?" & CGI.QUERY_STRING/>
    </cfif>
</cfif>

<style>
  .business-account-modal .modal-content {
    background: linear-gradient(145deg, #292929, #1d1d1d);
    border: 1px solid rgba(255, 255, 255, .1);
    border-radius: 1.15rem;
    box-shadow: 0 1.5rem 4rem rgba(0, 0, 0, .42);
  }

  .business-account-modal .modal-header,
  .business-account-modal .modal-footer {
    border-color: rgba(255, 255, 255, .08);
  }

  .business-account-modal-grid {
    display: grid;
    gap: .8rem;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .business-account-option {
    height: 100%;
    margin: 0;
  }

  .business-account-option-button {
    align-items: center;
    background: rgba(255, 255, 255, .035);
    border: 1px solid rgba(255, 255, 255, .1);
    border-radius: .9rem;
    color: inherit;
    display: flex;
    gap: .85rem;
    min-height: 5.25rem;
    padding: 1rem;
    text-align: left;
    transition: border-color .16s ease, background-color .16s ease, transform .16s ease;
    width: 100%;
  }

  .business-account-option-button:hover,
  .business-account-option-button:focus-visible {
    background: rgba(250, 177, 32, .08);
    border-color: #fab120;
    color: inherit;
    outline: 0;
    transform: translateY(-1px);
  }

  .business-account-option-button.is-active {
    background: rgba(250, 177, 32, .12);
    border-color: rgba(250, 177, 32, .75);
  }

  .business-account-option-button:disabled {
    cursor: not-allowed;
    opacity: .48;
    transform: none;
  }

  .business-account-option-icon {
    align-items: center;
    background: #fab120;
    border-radius: .75rem;
    color: #202020;
    display: inline-flex;
    flex: 0 0 2.75rem;
    font-size: 1rem;
    height: 2.75rem;
    justify-content: center;
  }

  .business-account-option-copy {
    min-width: 0;
  }

  .business-account-option-name {
    display: block;
    font-size: .95rem;
    font-weight: 700;
    line-height: 1.25;
  }

  .business-account-option-meta {
    color: rgba(255, 255, 255, .58);
    display: block;
    font-size: .75rem;
    margin-top: .3rem;
  }

  @media (max-width: 575.98px) {
    .business-account-modal-grid {
      grid-template-columns: 1fr;
    }

    .business-account-modal .modal-dialog {
      margin: .75rem;
    }
  }
</style>

<div class="modal fade business-account-modal" id="businessAccountContextModal" tabindex="-1" aria-labelledby="businessAccountContextModalLabel" aria-hidden="true" <cfif VARIABLES.businessAccountModalRequired>data-mdb-backdrop="static" data-mdb-keyboard="false"</cfif>>
  <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <div>
          <h5 class="modal-title mb-1" id="businessAccountContextModalLabel">Escolha uma conta</h5>
          <p class="text-muted small mb-0">Selecione o ambiente de trabalho que deseja utilizar agora.</p>
        </div>
        <cfif NOT VARIABLES.businessAccountModalRequired>
          <button type="button" class="btn-close" data-mdb-ripple-init data-mdb-dismiss="modal" aria-label="Fechar"></button>
        </cfif>
      </div>
      <div class="modal-body">
        <div class="business-account-modal-grid">
          <cfif isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin AND NOT VARIABLES.businessAccountModalRequired>
            <form class="business-account-option" method="post" action="/selecionar-conta/">
              <input type="hidden" name="business_account_context_action" value="select"/>
              <input type="hidden" name="business_account_context_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.businessAccountContextCsrf)#</cfoutput>"/>
              <input type="hidden" name="business_account_context_id" value="all"/>
              <input type="hidden" name="business_account_context_redirect" value="<cfoutput>#htmlEditFormat(VARIABLES.businessAccountModalRedirect)#</cfoutput>"/>
              <button class="business-account-option-button <cfif NOT VARIABLES.businessAccountSimulationActive>is-active</cfif>" type="submit">
                <span class="business-account-option-icon"><i class="fa-solid fa-layer-group"></i></span>
                <span class="business-account-option-copy">
                  <span class="business-account-option-name">Todas as contas</span>
                  <span class="business-account-option-meta">Visão geral administrativa</span>
                </span>
              </button>
            </form>
          </cfif>

          <cfif isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin AND NOT VARIABLES.businessAccountModalRequired>
            <cfoutput query="qBusinessAccountContextOptions">
              <cfset VARIABLES.businessAccountOptionActive = len(trim(VARIABLES.businessActiveAccountId)) AND VARIABLES.businessActiveAccountId EQ qBusinessAccountContextOptions.id_conta/>
              <cfset VARIABLES.businessAccountOptionEnabled = qBusinessAccountContextOptions.status EQ "ATIVA"/>
              <form class="business-account-option" method="post" action="/selecionar-conta/">
                <input type="hidden" name="business_account_context_action" value="select"/>
                <input type="hidden" name="business_account_context_csrf" value="#htmlEditFormat(VARIABLES.businessAccountContextCsrf)#"/>
                <input type="hidden" name="business_account_context_id" value="#qBusinessAccountContextOptions.id_conta#"/>
                <input type="hidden" name="business_account_context_redirect" value="#htmlEditFormat(VARIABLES.businessAccountModalRedirect)#"/>
                <button class="business-account-option-button <cfif VARIABLES.businessAccountOptionActive>is-active</cfif>" type="submit" <cfif NOT VARIABLES.businessAccountOptionEnabled>disabled</cfif>>
                  <span class="business-account-option-icon"><i class="fa-solid fa-building"></i></span>
                  <span class="business-account-option-copy">
                    <span class="business-account-option-name">#htmlEditFormat(qBusinessAccountContextOptions.nome_conta)#</span>
                    <span class="business-account-option-meta"><cfif VARIABLES.businessAccountOptionActive>Conta em uso<cfelse>#htmlEditFormat(qBusinessAccountContextOptions.status)#</cfif></span>
                  </span>
                </button>
              </form>
            </cfoutput>
          <cfelseif isDefined("qBusinessAccountContextAccounts") AND qBusinessAccountContextAccounts.recordcount>
            <cfoutput query="qBusinessAccountContextAccounts">
              <cfset VARIABLES.businessAccountOptionActive = len(trim(VARIABLES.businessActiveAccountId)) AND VARIABLES.businessActiveAccountId EQ qBusinessAccountContextAccounts.id_conta/>
              <cfset VARIABLES.businessAccountOptionRole = qBusinessAccountContextAccounts.papel/>
              <cfswitch expression="#qBusinessAccountContextAccounts.papel#">
                <cfcase value="OWNER"><cfset VARIABLES.businessAccountOptionRole = "Proprietário"/></cfcase>
                <cfcase value="ADMIN"><cfset VARIABLES.businessAccountOptionRole = "Administrador"/></cfcase>
                <cfcase value="OPERADOR"><cfset VARIABLES.businessAccountOptionRole = "Operador"/></cfcase>
                <cfcase value="VISUALIZADOR"><cfset VARIABLES.businessAccountOptionRole = "Visualizador"/></cfcase>
              </cfswitch>
              <form class="business-account-option" method="post" action="/selecionar-conta/">
                <input type="hidden" name="business_account_context_action" value="select"/>
                <input type="hidden" name="business_account_context_csrf" value="#htmlEditFormat(VARIABLES.businessAccountContextCsrf)#"/>
                <input type="hidden" name="business_account_context_id" value="#qBusinessAccountContextAccounts.id_conta#"/>
                <input type="hidden" name="business_account_context_redirect" value="#htmlEditFormat(VARIABLES.businessAccountModalRedirect)#"/>
                <button class="business-account-option-button <cfif VARIABLES.businessAccountOptionActive>is-active</cfif>" type="submit">
                  <span class="business-account-option-icon"><i class="fa-solid fa-building"></i></span>
                  <span class="business-account-option-copy">
                    <span class="business-account-option-name">#htmlEditFormat(qBusinessAccountContextAccounts.nome_conta)#</span>
                    <span class="business-account-option-meta"><cfif VARIABLES.businessAccountOptionActive>Conta em uso<cfelse>#htmlEditFormat(VARIABLES.businessAccountOptionRole)#</cfif></span>
                  </span>
                </button>
              </form>
            </cfoutput>
          </cfif>
        </div>
      </div>
      <cfif NOT VARIABLES.businessAccountModalRequired>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-light" data-mdb-ripple-init data-mdb-dismiss="modal">Cancelar</button>
        </div>
      </cfif>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    var modalElement = document.getElementById('businessAccountContextModal');
    if (!modalElement || !window.mdb || !mdb.Modal) {
      return;
    }

    var modal = new mdb.Modal(modalElement, {
      backdrop: <cfif VARIABLES.businessAccountModalRequired>'static'<cfelse>true</cfif>,
      keyboard: <cfif VARIABLES.businessAccountModalRequired>false<cfelse>true</cfif>
    });

    document.querySelectorAll('[data-business-account-modal-open]').forEach(function (button) {
      button.addEventListener('click', function () {
        modal.show();
      });
    });

    <cfif VARIABLES.businessAccountModalRequired>
      modal.show();
    </cfif>
  });
</script>
