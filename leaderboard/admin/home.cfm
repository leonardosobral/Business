<style>
  .leaderboard-admin-card,
  .leaderboard-admin-result-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.025);
  }

  .leaderboard-admin-help {
    font-size: 0.92rem;
    color: rgba(255,255,255,0.72);
  }

  .leaderboard-admin-result-grid {
    display: grid;
    gap: 0.85rem;
  }

  .leaderboard-admin-result-item {
    padding: 0.9rem 1rem;
    border-radius: 0.9rem;
    border: 1px solid rgba(255,255,255,0.08);
    background: rgba(255,255,255,0.03);
  }

  .leaderboard-admin-result-item small {
    display: block;
    color: rgba(255,255,255,0.6);
    text-transform: uppercase;
    letter-spacing: 0.04em;
    margin-bottom: 0.2rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Leaderboard - Cadastro Manual de Atleta</h3>
              <p class="text-muted mb-0">Crie manualmente um usuário funcional com página pública de atleta, reaproveitando o mesmo contrato base usado no fluxo Google do Road Runners.</p>
            </div>
          </div>

          <hr/>

          <cfif VARIABLES.leaderboardAdminStatus EQ "criado">
            <div class="alert alert-success mb-4">
              O usuário e a página de perfil foram criados com sucesso.
            </div>

            <div class="leaderboard-admin-result-card p-4 mb-4">
              <h5 class="mb-3">Dados criados</h5>
              <div class="leaderboard-admin-result-grid">
                <div class="leaderboard-admin-result-item">
                  <small>ID do usuário</small>
                  <cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminCreatedUserId)#</cfoutput>
                </div>
                <div class="leaderboard-admin-result-item">
                  <small>ID da página</small>
                  <cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminCreatedPageId)#</cfoutput>
                </div>
                <div class="leaderboard-admin-result-item">
                  <small>Perfil público</small>
                  <cfoutput><a class="link-warning" href="https://roadrunners.run/atleta/#urlEncodedFormat(VARIABLES.leaderboardAdminCreatedTag)#/" target="_blank">/atleta/#htmlEditFormat(VARIABLES.leaderboardAdminCreatedTag)#/</a></cfoutput>
                </div>
              </div>
            </div>
          <cfelseif VARIABLES.leaderboardAdminStatus EQ "erro">
            <div class="alert alert-danger mb-4">
              <cfif VARIABLES.leaderboardAdminError EQ "email_duplicado">
                Já existe um usuário com este e-mail.
              <cfelseif VARIABLES.leaderboardAdminError EQ "nome_obrigatorio">
                Informe o nome do atleta.
              <cfelseif VARIABLES.leaderboardAdminError EQ "sexo_invalido">
                Informe um sexo válido.
              <cfelseif VARIABLES.leaderboardAdminError EQ "pais_obrigatorio">
                Informe o país.
              <cfelseif VARIABLES.leaderboardAdminError EQ "email_invalido">
                O e-mail informado é inválido.
              <cfelse>
                Não foi possível concluir o cadastro manual. <cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminError)#</cfoutput>
              </cfif>
            </div>
          </cfif>

          <div class="leaderboard-admin-card p-4">
            <div class="mb-4">
              <h5 class="mb-2">Novo atleta</h5>
              <p class="leaderboard-admin-help mb-0">O e-mail pode ser provisório e gerado pelo sistema, para depois ser substituído pelo e-mail real do atleta antes de ele assumir a conta.</p>
            </div>

            <form method="post" action="./">
              <input type="hidden" name="manual_user_action" value="create_manual_user"/>

              <div class="row g-3">
                <div class="col-12 col-lg-6">
                  <label class="form-label">E-mail provisório</label>
                  <input class="form-control" type="email" name="manual_user_email" value="<cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminFormEmail)#</cfoutput>" required/>
                  <div class="form-text">Você pode manter o valor gerado automaticamente ou ajustar manualmente.</div>
                </div>

                <div class="col-12 col-lg-6">
                  <label class="form-label">Nome</label>
                  <input class="form-control" type="text" name="manual_user_name" value="<cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminFormName)#</cfoutput>" maxlength="255" required/>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label">Sexo</label>
                  <select class="form-select" name="manual_user_gender" required>
                    <option value="">Selecione</option>
                    <option value="M" <cfif VARIABLES.leaderboardAdminFormGender EQ "M">selected</cfif>>Masculino</option>
                    <option value="F" <cfif VARIABLES.leaderboardAdminFormGender EQ "F">selected</cfif>>Feminino</option>
                  </select>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label">País</label>
                  <select class="form-select" name="manual_user_country" required>
                    <option value="">Selecione</option>
                    <cfoutput query="qLeaderboardAdminCountries">
                      <option value="#qLeaderboardAdminCountries.cod_alpha2#" <cfif VARIABLES.leaderboardAdminFormCountry EQ qLeaderboardAdminCountries.cod_alpha2>selected</cfif>>#htmlEditFormat(qLeaderboardAdminCountries.nome_pais)#</option>
                    </cfoutput>
                  </select>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label">CBAT</label>
                  <input class="form-control" type="text" name="manual_user_cbat" value="<cfoutput>#htmlEditFormat(VARIABLES.leaderboardAdminFormCBAT)#</cfoutput>" maxlength="50"/>
                </div>
              </div>

              <div class="d-flex flex-wrap gap-2 mt-4">
                <button type="submit" class="btn btn-warning">Criar atleta manualmente</button>
                <a class="btn btn-outline-secondary" href="./">Gerar novo e-mail provisório</a>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
