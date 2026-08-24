<cfif VARIABLES.adsAccessCanAdminVouchers>
  <section id="admin-vouchers" class="mb-3 d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-2">
    <div>
      <div class="ads-v1-eyebrow">Uso interno</div>
      <h2 class="h5 mb-1">Vouchers de publicidade</h2>
      <p class="text-muted mb-0">Crie códigos promocionais para novos clientes ou códigos exclusivos para uma conta.</p>
    </div>
    <cfif VARIABLES.adsV1AdminVoucherApiReady>
      <span class="badge badge-info"><cfoutput>#qAdsV1AdminVouchers.recordcount# recentes</cfoutput></span>
    </cfif>
  </section>

  <cfif NOT VARIABLES.adsV1AdminVoucherApiReady>
    <div class="alert alert-warning mb-4">
      A criação global de vouchers ainda não está disponível. Aplique a migração de vouchers promocionais.
    </div>
  <cfelse>
    <div class="row g-4 mb-4">
      <div class="col-xl-5">
        <section class="card shadow-0 h-100">
          <div class="card-body p-3 p-lg-4">
            <h3 class="h5 mb-1">Criar voucher</h3>
            <p class="text-muted mb-4">O valor sugerido para a ação comercial é R$ 100.</p>

            <form method="post" action="./?view=admin#admin-vouchers" id="ads-admin-voucher-form">
              <input type="hidden" name="ads_v1_action" value="create_admin_voucher"/>
              <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
              <input type="hidden" name="voucher_redemption_role" value="OWNER"/>

              <fieldset class="mb-3">
                <legend class="form-label mb-2">Quem poderá usar?</legend>
                <label class="border rounded p-3 d-flex gap-3 mb-2" for="voucher-scope-promotional">
                  <input class="form-check-input mt-1" id="voucher-scope-promotional" type="radio" name="voucher_scope" value="PROMOTIONAL" checked/>
                  <span><strong class="d-block">Voucher promocional</strong><span class="small text-muted">Sem conta definida. Será vinculado à primeira conta que reservar ou resgatar o código.</span></span>
                </label>
                <label class="border rounded p-3 d-flex gap-3" for="voucher-scope-account">
                  <input class="form-check-input mt-1" id="voucher-scope-account" type="radio" name="voucher_scope" value="ACCOUNT"/>
                  <span><strong class="d-block">Voucher de conta</strong><span class="small text-muted">Exclusivo para uma conta já conhecida e inválido para qualquer outra.</span></span>
                </label>
              </fieldset>

              <div class="mb-3" id="voucher-account-field" hidden>
                <label class="form-label" for="voucher-account-id">Conta autorizada</label>
                <select class="form-select" id="voucher-account-id" name="voucher_account_id" disabled>
                  <option value="">Selecione a conta</option>
                  <cfoutput query="qAdsV1AdminVoucherAccounts">
                    <option value="#id_conta#">#htmlEditFormat(nome_conta)# · #htmlEditFormat(status)#</option>
                  </cfoutput>
                </select>
              </div>

              <div class="row g-3">
                <div class="col-sm-7">
                  <label class="form-label" for="voucher-code">Código</label>
                  <input class="form-control" id="voucher-code" type="text" name="voucher_code" maxlength="80" placeholder="Gerar automaticamente" pattern="[A-Za-z0-9-]+"/>
                </div>
                <div class="col-sm-5">
                  <label class="form-label" for="voucher-amount">Crédito</label>
                  <input class="form-control" id="voucher-amount" type="number" name="voucher_amount" min="0.01" step="0.01" value="100.00" required/>
                </div>
                <div class="col-12">
                  <label class="form-label" for="voucher-expires-on">Validade <span class="text-muted">(opcional)</span></label>
                  <input class="form-control" id="voucher-expires-on" type="date" name="voucher_expires_on"/>
                </div>
                <div class="col-12">
                  <label class="form-label" for="voucher-note">Identificação interna <span class="text-muted">(opcional)</span></label>
                  <input class="form-control" id="voucher-note" type="text" name="voucher_note" maxlength="500" placeholder="Ex.: ação comercial Expo Run 2026"/>
                </div>
                <div class="col-12">
                  <button class="btn btn-info w-100" type="submit">Criar voucher</button>
                </div>
              </div>
            </form>
          </div>
        </section>
      </div>

      <div class="col-xl-7">
        <section class="card shadow-0 h-100">
          <div class="card-body p-3 p-lg-4">
            <h3 class="h5 mb-1">Vouchers recentes</h3>
            <p class="text-muted mb-3">A vinculação promocional acontece uma única vez e fica registrada.</p>

            <cfif qAdsV1AdminVouchers.recordcount>
              <div class="table-responsive">
                <table class="table table-sm align-middle mb-0">
                  <thead><tr><th>Código</th><th>Tipo e conta</th><th>Crédito</th><th>Status</th></tr></thead>
                  <tbody>
                    <cfoutput query="qAdsV1AdminVouchers">
                      <tr>
                        <td>
                          <strong>#htmlEditFormat(codigo)#</strong>
                          <cfif len(trim(observacao & ""))><div class="small text-muted">#htmlEditFormat(observacao)#</div></cfif>
                        </td>
                        <td>
                          <cfif voucher_scope EQ "PROMOTIONAL">
                            <span class="badge badge-info">Promocional</span>
                            <div class="small mt-1"><cfif len(trim(account_name & ""))>#htmlEditFormat(account_name)#<cfelse>Disponível para a primeira conta</cfif></div>
                          <cfelse>
                            <span class="badge badge-secondary">Conta</span>
                            <div class="small mt-1">#htmlEditFormat(account_name)#</div>
                          </cfif>
                        </td>
                        <td>
                          <strong>#lsCurrencyFormat(credito)#</strong>
                          <div class="small text-muted">saldo #lsCurrencyFormat(credito_disponivel)#</div>
                        </td>
                        <td>
                          <cfif reservation_status EQ "RESERVED">
                            <span class="badge badge-warning">Reservado</span>
                            <div class="small mt-1">#htmlEditFormat(reserved_account_name)#</div>
                          <cfelseif status EQ 2>
                            <span class="badge badge-success">Resgatado</span>
                            <cfif len(trim(redeemed_by_name & ""))><div class="small mt-1">#htmlEditFormat(redeemed_by_name)#</div></cfif>
                          <cfelseif status EQ 1>
                            <span class="badge badge-info">Disponível</span>
                          <cfelse>
                            <span class="badge badge-secondary">Inativo</span>
                          </cfif>
                          <cfif isDate(data_expiracao)><div class="small text-muted mt-1">até #lsDateFormat(data_expiracao, "dd/mm/yyyy")#</div></cfif>
                        </td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse>
              <div class="text-muted text-center py-5">Nenhum voucher criado.</div>
            </cfif>
          </div>
        </section>
      </div>
    </div>

    <script>
      (function () {
        var form = document.getElementById("ads-admin-voucher-form");
        var field = document.getElementById("voucher-account-field");
        var select = document.getElementById("voucher-account-id");
        if (!form || !field || !select) return;

        function syncVoucherScope() {
          var selected = form.querySelector('input[name="voucher_scope"]:checked');
          var accountScoped = selected && selected.value === "ACCOUNT";
          field.hidden = !accountScoped;
          select.disabled = !accountScoped;
          select.required = accountScoped;
          if (!accountScoped) select.value = "";
        }

        form.querySelectorAll('input[name="voucher_scope"]').forEach(function (input) {
          input.addEventListener("change", syncVoucherScope);
        });
        syncVoucherScope();
      })();
    </script>
  </cfif>
</cfif>
