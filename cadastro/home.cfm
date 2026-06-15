<cfinclude template="includes/backend.cfm"/>

<style>
  .cadastro-public-page {
    min-height: 100vh;
    background:
      linear-gradient(180deg, rgba(7, 9, 13, .94), rgba(12, 15, 22, .98)),
      url('/assets/meta_imagem.jpg') center/cover no-repeat;
  }

  .cadastro-public-page .cadastro-shell {
    max-width: 1080px;
  }

  .cadastro-public-page .cadastro-panel {
    border: 1px solid rgba(255,255,255,.12);
    border-radius: 8px;
    background: rgba(18, 22, 31, .9);
    backdrop-filter: blur(12px);
  }

  .cadastro-public-page .cadastro-side {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: 8px;
    background: rgba(255,255,255,.035);
  }

  .cadastro-public-page .cadastro-step {
    display: grid;
    grid-template-columns: 32px minmax(0, 1fr);
    gap: .75rem;
    align-items: start;
  }

  .cadastro-public-page .cadastro-step-number {
    width: 32px;
    height: 32px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    background: var(--mdb-warning);
    color: #111;
    font-weight: 700;
  }
</style>

<section class="cadastro-public-page text-light py-4 py-lg-5">
  <div class="container cadastro-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
      <a href="/" class="d-inline-flex align-items-center text-decoration-none">
        <img src="/lib/images/runpro.svg" alt="Run Pro" style="height: 42px; max-width: 170px;"/>
      </a>
      <div class="d-flex gap-2">
        <a class="btn btn-outline-light btn-sm" href="/">Inicio</a>
        <a class="btn btn-warning btn-sm" href="/">Entrar</a>
      </div>
    </div>

    <div class="row g-4 align-items-start">
      <div class="col-12 col-lg-5">
        <div class="cadastro-side p-4 h-100">
          <span class="badge badge-warning mb-3">Acesso Business</span>
          <h1 class="h2 mb-3">Solicite o acesso da sua empresa</h1>
          <p class="text-muted mb-4">
            O acesso ao Run Pro e liberado apos revisao. Envie os dados da empresa e do responsavel para que o time aprove ou associe sua empresa a uma conta existente.
          </p>

          <div class="d-grid gap-3">
            <div class="cadastro-step">
              <span class="cadastro-step-number">1</span>
              <div>
                <div class="fw-bold">Envio da solicitacao</div>
                <div class="small text-muted">Voce informa empresa, responsavel e tipo de atuacao.</div>
              </div>
            </div>
            <div class="cadastro-step">
              <span class="cadastro-step-number">2</span>
              <div>
                <div class="fw-bold">Analise interna</div>
                <div class="small text-muted">O admin valida os dados e cria ou associa uma conta Business.</div>
              </div>
            </div>
            <div class="cadastro-step">
              <span class="cadastro-step-number">3</span>
              <div>
                <div class="fw-bold">Acesso liberado</div>
                <div class="small text-muted">O responsavel entra com Google e opera apenas os dados da conta.</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-12 col-lg-7">
        <div class="cadastro-panel p-4">
          <div class="mb-4">
            <h2 class="h4 mb-2">Dados para analise</h2>
            <p class="text-muted mb-0">Use um e-mail Google que sera utilizado para acessar a conta depois da aprovacao.</p>
          </div>

          <cfif len(trim(VARIABLES.cadastroSucesso))>
            <div class="alert alert-success">
              <cfoutput>#htmlEditFormat(VARIABLES.cadastroSucesso)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.cadastroErro))>
            <div class="alert alert-danger">
              <cfoutput>#htmlEditFormat(VARIABLES.cadastroErro)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.cadastroSucesso))>
            <div class="cadastro-side p-4">
              <h3 class="h5 mb-3">Solicitacao enviada</h3>
              <p class="text-muted mb-4">
                Agora a equipe interna vai revisar os dados enviados. Quando a conta for aprovada, o responsavel podera entrar usando o e-mail Google informado no cadastro.
              </p>

              <div class="d-flex flex-column flex-sm-row gap-2">
                <a class="btn btn-warning" href="/">Ir para o login</a>
                <a class="btn btn-outline-light" href="/cadastro/">Enviar outra solicitacao</a>
              </div>
            </div>
          <cfelse>
            <cfif isDefined("COOKIE.id") AND len(trim(COOKIE.id))>
              <form method="post" action="/cadastro/" class="cadastro-side p-3 mb-4">
                <input type="hidden" name="acao" value="resgatar_voucher"/>
                <h3 class="h5 mb-2">Tenho um voucher</h3>
                <p class="text-muted mb-3">Use o codigo recebido para vincular seu usuario a conta da empresa e liberar o credito de ads.</p>
                <div class="row g-2 align-items-end">
                  <div class="col-12 col-lg-8">
                    <label class="form-label" for="txtVoucherResgate">Codigo do voucher</label>
                    <input class="form-control" type="text" id="txtVoucherResgate" name="voucher_codigo" maxlength="80" value="<cfoutput>#htmlEditFormat(FORM.voucher_codigo)#</cfoutput>" required/>
                  </div>
                  <div class="col-12 col-lg-4">
                    <button class="btn btn-warning w-100" type="submit">Resgatar</button>
                  </div>
                </div>
              </form>
            </cfif>

            <cfinclude template="includes/form.cfm"/>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
