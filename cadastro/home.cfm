<cfinclude template="includes/backend.cfm"/>

<section class="cadastro-public-page">
  <div class="cadastro-grid" aria-hidden="true"></div>
  <div class="cadastro-glow cadastro-glow-top" aria-hidden="true"></div>
  <div class="cadastro-glow cadastro-glow-bottom" aria-hidden="true"></div>

  <header class="cadastro-header">
    <div class="container cadastro-header-inner">
      <a href="/" class="cadastro-brand" aria-label="Run Pro — página inicial">
        <img src="/lib/images/runpro.svg" alt="Run Pro"/>
        <span aria-hidden="true">Road Runners <strong>Business</strong></span>
      </a>

      <div class="cadastro-header-actions">
        <a class="cadastro-link-back" href="/">
          <i class="fa-solid fa-arrow-left" aria-hidden="true"></i>
          Voltar ao site
        </a>
        <a class="btn cadastro-login-button" href="/?login=1">
          Já tenho acesso
          <i class="fa-solid fa-arrow-right" aria-hidden="true"></i>
        </a>
      </div>
    </div>
  </header>

  <main class="container cadastro-shell">
    <div class="cadastro-layout">
      <aside class="cadastro-story">
        <div class="cadastro-story-content">
          <span class="cadastro-kicker">
            <i></i>
            Acesso Run Pro Business
          </span>

          <h1>Sua empresa na linha de frente da corrida.</h1>

          <p class="cadastro-lead">
            Entre no ecossistema que conecta quem organiza, promove, comunica e movimenta o mercado de corridas de rua.
          </p>

          <div class="cadastro-audiences" aria-label="Perfis atendidos pelo Run Pro">
            <span>Organizadores</span>
            <span>Marcas</span>
            <span>Canais</span>
            <span>Fornecedores</span>
          </div>

          <div class="cadastro-journey">
            <div class="cadastro-step<cfif NOT VARIABLES.cadastroGoogleAuthenticated AND NOT len(trim(VARIABLES.cadastroSucesso))> is-current</cfif>">
              <span class="cadastro-step-number">01</span>
              <div>
                <strong>Confirme sua identidade</strong>
                <p>Entre com a conta Google que será usada para acessar o Run Pro.</p>
              </div>
            </div>

            <div class="cadastro-step<cfif VARIABLES.cadastroGoogleAuthenticated AND NOT len(trim(VARIABLES.cadastroSucesso))> is-current</cfif>">
              <span class="cadastro-step-number">02</span>
              <div>
                <strong>Conte sobre sua empresa</strong>
                <p>Informe os dados do negócio e como você atua no setor.</p>
              </div>
            </div>

            <div class="cadastro-step<cfif len(trim(VARIABLES.cadastroSucesso))> is-current</cfif>">
              <span class="cadastro-step-number">03</span>
              <div>
                <strong>Análise e liberação</strong>
                <p>Nossa equipe valida a solicitação e associa a empresa à sua conta.</p>
              </div>
            </div>
          </div>
        </div>

        <div class="cadastro-story-footer">
          <div class="cadastro-story-mark" aria-hidden="true">
            <img src="/lib/images/runpro.svg" alt=""/>
          </div>
          <p>Operação, audiência e inteligência em um só ecossistema.</p>
        </div>
      </aside>

      <section class="cadastro-panel" aria-labelledby="cadastro-form-title">
        <div class="cadastro-panel-topline">
          <span>Solicitação de acesso</span>
          <span class="cadastro-panel-status<cfif VARIABLES.cadastroGoogleAuthenticated OR len(trim(VARIABLES.cadastroSucesso))> is-confirmed</cfif>">
            <i></i>
            <cfif len(trim(VARIABLES.cadastroSucesso))>Solicitação recebida<cfelseif VARIABLES.cadastroGoogleAuthenticated>Identidade confirmada<cfelse>Conta Google necessária</cfif>
          </span>
        </div>

        <div class="cadastro-panel-header">
          <span class="cadastro-panel-index">
            <cfif len(trim(VARIABLES.cadastroSucesso))>03<cfelseif VARIABLES.cadastroGoogleAuthenticated>02<cfelse>01</cfif>
          </span>
          <div>
            <cfif len(trim(VARIABLES.cadastroSucesso))>
              <h2 id="cadastro-form-title">Solicitação enviada.</h2>
              <p>Seu pedido de acesso já está com a equipe RunnerHub.</p>
            <cfelseif VARIABLES.cadastroGoogleAuthenticated>
              <h2 id="cadastro-form-title">Agora, conte sobre seu negócio.</h2>
              <p>Sua identidade está confirmada. Complete os dados da empresa.</p>
            <cfelse>
              <h2 id="cadastro-form-title">Comece com sua conta Google.</h2>
              <p>Confirme quem será o responsável pelo acesso antes de preencher o formulário.</p>
            </cfif>
          </div>
        </div>

        <cfif len(trim(VARIABLES.cadastroSucesso))>
          <div class="alert alert-success cadastro-alert" role="status">
            <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
            <cfoutput>#htmlEditFormat(VARIABLES.cadastroSucesso)#</cfoutput>
          </div>
        </cfif>

        <cfif len(trim(VARIABLES.cadastroErro))>
          <div class="alert alert-danger cadastro-alert" role="alert">
            <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
            <cfoutput>#htmlEditFormat(VARIABLES.cadastroErro)#</cfoutput>
          </div>
        </cfif>

        <cfif len(trim(VARIABLES.cadastroSucesso))>
          <div class="cadastro-success">
            <span class="cadastro-success-icon">
              <i class="fa-solid fa-check" aria-hidden="true"></i>
            </span>
            <span class="cadastro-kicker">Solicitação recebida</span>
            <h3>Agora é com a nossa equipe.</h3>
            <p>
              Vamos revisar os dados enviados. Quando a conta for aprovada, o responsável poderá entrar usando a conta Google já confirmada.
            </p>

            <div class="cadastro-success-actions">
              <a class="btn cadastro-submit-button" href="/">
                Ir para o login
                <i class="fa-solid fa-arrow-right" aria-hidden="true"></i>
              </a>
              <a class="btn cadastro-secondary-button" href="/cadastro/">Enviar outra solicitação</a>
            </div>
          </div>
        <cfelseif NOT VARIABLES.cadastroGoogleAuthenticated>
          <div class="cadastro-auth-gate" data-cadastro-auth-gate>
            <span class="cadastro-auth-icon" aria-hidden="true">
              <i class="fa-solid fa-user"></i>
            </span>
            <span class="cadastro-kicker">Identidade do responsável</span>
            <h3>Entre para liberar o formulário.</h3>
            <p>
              Usaremos o nome e o e-mail confirmados pelo Google para identificar o responsável pela conta Business.
              Esses dados não poderão ser alterados no formulário.
            </p>

            <div class="cadastro-google-signin">
              <div id="g_id_onload"
                   data-client_id="<cfoutput>#htmlEditFormat(VARIABLES.cadastroGoogleClientId)#</cfoutput>"
                   data-callback="handleCadastroCredentialResponse"
                   data-auto_select="false"
                   data-auto_prompt="false">
              </div>
              <div class="g_id_signin"
                   data-type="standard"
                   data-size="large"
                   data-theme="outline"
                   data-text="signin_with"
                   data-shape="rectangular"
                   data-logo_alignment="left"
                   data-width="320">
              </div>
            </div>

            <p class="cadastro-auth-privacy">
              <i class="fa-solid fa-lock" aria-hidden="true"></i>
              A autenticação apenas confirma sua identidade. Nenhuma senha é compartilhada com o Run Pro.
            </p>

            <noscript>
              <div class="alert alert-warning cadastro-alert">
                Ative o JavaScript para continuar com sua conta Google.
              </div>
            </noscript>
          </div>
        <cfelse>
          <div class="cadastro-google-identity">
            <span class="cadastro-google-identity-avatar" aria-hidden="true">
              <cfoutput>#htmlEditFormat(uCase(left(SESSION.cadastroGoogleIdentity.name, 1)))#</cfoutput>
            </span>
            <span class="cadastro-google-identity-copy">
              <small>Conta Google confirmada</small>
              <strong><cfoutput>#htmlEditFormat(SESSION.cadastroGoogleIdentity.name)#</cfoutput></strong>
              <span><cfoutput>#htmlEditFormat(SESSION.cadastroGoogleIdentity.email)#</cfoutput></span>
            </span>
            <span class="cadastro-google-identity-check" aria-label="Identidade confirmada">
              <i class="fa-solid fa-circle-check" aria-hidden="true"></i>
            </span>
            <form method="post" action="/cadastro/" class="cadastro-google-change-form">
              <input type="hidden" name="acao" value="trocar_conta_google"/>
              <input type="hidden" name="cadastro_csrf" value="<cfoutput>#htmlEditFormat(SESSION.cadastroGoogleCsrf)#</cfoutput>"/>
              <button class="cadastro-google-change" type="submit">Trocar conta</button>
            </form>
          </div>
          <cfinclude template="includes/form.cfm"/>
        </cfif>

        <div class="cadastro-panel-footer">
          <i class="fa-solid fa-lock" aria-hidden="true"></i>
          <span>Seus dados serão usados apenas para analisar e administrar o acesso Business.</span>
        </div>
      </section>
    </div>
  </main>

  <footer class="container cadastro-footer">
    <p>© <cfoutput>#year(now())#</cfoutput> RunnerHub</p>
    <div>
      <a href="/faq/">FAQ</a>
      <a href="/suporte/">Suporte</a>
      <a href="https://wa.me/5548991534589" target="_blank" rel="noopener noreferrer">Falar com a equipe</a>
    </div>
  </footer>
</section>

<script>
  function handleCadastroCredentialResponse(response) {
    var authGate = document.querySelector("[data-cadastro-auth-gate]");

    if (!response || !response.credential) {
      if (authGate) authGate.classList.add("has-auth-error");
      return;
    }

    if (authGate) {
      authGate.classList.remove("has-auth-error");
      authGate.classList.add("is-authenticating");
      authGate.setAttribute("aria-busy", "true");
    }

    document.cookie = "rr_logged_out=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=/; SameSite=Lax; Secure";

    var baseUrl = window.location.origin;
    var cadastroUrl = encodeURIComponent(baseUrl + "/cadastro/");
    window.location.href = baseUrl
      + "/?action=googlesignin&redirect="
      + cadastroUrl
      + "&credential="
      + encodeURIComponent(response.credential);
  }
</script>
