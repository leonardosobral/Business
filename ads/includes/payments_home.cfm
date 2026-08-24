<cfif VARIABLES.adsAccessCanViewPayments>
  <cfif VARIABLES.adsAccessIsPendingNewAccount>
    <section class="card shadow-0 mb-4" id="payment-credit">
      <div class="card-body p-3 p-lg-4">
        <div class="ads-v1-eyebrow">Crédito de publicidade</div>
        <h2 class="h5 mb-1">Reservar voucher</h2>
        <p class="text-muted">O crédito será aplicado automaticamente quando a conta for aprovada. Até lá, nenhum saldo será criado ou consumido.</p>

        <cfif qAdsV1VoucherReservation.recordcount>
          <div class="border border-success rounded p-3" id="ads-voucher-form">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3">
              <div><span class="badge badge-success mb-2">Voucher reservado</span><div class="h5 mb-1"><cfoutput>#lsCurrencyFormat(qAdsV1VoucherReservation.credito)#</cfoutput></div><div class="small text-muted">Código <cfoutput>#htmlEditFormat(left(qAdsV1VoucherReservation.codigo, 4))#••••#htmlEditFormat(right(qAdsV1VoucherReservation.codigo, 4))#</cfoutput></div></div>
              <div class="small text-muted align-self-md-center"><cfif isDate(qAdsV1VoucherReservation.expires_at)>Válido até <cfoutput>#lsDateFormat(qAdsV1VoucherReservation.expires_at, "dd/mm/yyyy")#</cfoutput><cfelse>Sem data de expiração</cfif></div>
            </div>
          </div>
        <cfelseif VARIABLES.adsAccessCanReserveVoucher>
          <form method="post" action="./?view=payments#ads-voucher-form" id="ads-voucher-form" class="border rounded p-3">
            <input type="hidden" name="ads_v1_action" value="reserve_voucher"/>
            <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
            <label class="form-label" for="ads-voucher-code">Código do voucher</label>
            <div class="input-group">
              <input class="form-control text-uppercase" id="ads-voucher-code" name="voucher_code" type="text" minlength="3" maxlength="160" autocomplete="off" placeholder="RUNPRO-..." required/>
              <button class="btn btn-warning" type="submit">Reservar voucher</button>
            </div>
          </form>
        </cfif>
      </div>
    </section>
  <cfelse>
  <section class="card shadow-0 mb-4" id="payment-credit">
    <div class="card-body p-3 p-lg-4">
      <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
        <div>
          <div class="ads-v1-eyebrow">Crédito de publicidade</div>
          <h2 class="h5 mb-1">Adicionar saldo</h2>
          <p class="text-muted mb-0">R$ X pagos = R$ X em crédito. As taxas ficam por nossa conta, sem desconto no saldo.</p>
        </div>
        <span class="badge badge-info align-self-lg-start">Checkout Pagar.me</span>
      </div>

      <cfif VARIABLES.adsAccessCanPurchaseCredit>
        <div class="border rounded p-3 mb-4">
          <div class="row g-3 align-items-end">
            <div class="col-lg-5">
              <h3 class="h6 mb-1">Tem um voucher?</h3>
              <p class="small text-muted mb-0">Resgate o código para adicionar o crédito diretamente ao saldo desta conta.</p>
            </div>
            <div class="col-lg-7">
              <form method="post" action="./?view=payments#payment-credit" id="ads-voucher-form">
                <input type="hidden" name="ads_v1_action" value="redeem_voucher"/>
                <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
                <label class="visually-hidden" for="ads-voucher-code">Código do voucher</label>
                <div class="input-group">
                  <input class="form-control text-uppercase" id="ads-voucher-code" name="voucher_code" type="text" minlength="3" maxlength="160" autocomplete="off" placeholder="RUNPRO-..." required/>
                  <button class="btn btn-outline-info" type="submit">Resgatar voucher</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </cfif>

      <cfif len(VARIABLES.adsPaymentError)>
        <div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.adsPaymentError)#</cfoutput></div>
      </cfif>

      <cfif NOT VARIABLES.adsPaymentApiReady>
        <div class="alert alert-warning mb-0">A compra de crédito está em preparação. Campanhas e saldo atual continuam disponíveis.</div>
      <cfelse>
        <cfif structKeyExists(VARIABLES.adsPaymentCurrent, "paymentIntentId")>
          <cfset VARIABLES.adsPaymentBoxId = listFind("CREATED,CHECKOUT_READY,PENDING", VARIABLES.adsPaymentCurrent.status)
            ? "ads-payment-pending" : "ads-payment-result"/>
          <div class="border rounded p-3 mb-4" id="<cfoutput>#VARIABLES.adsPaymentBoxId#</cfoutput>" data-payment-intent="<cfoutput>#htmlEditFormat(VARIABLES.adsPaymentCurrent.paymentIntentId)#</cfoutput>">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3">
              <div>
                <div class="small text-muted">Pagamento <cfoutput>#htmlEditFormat(VARIABLES.adsPaymentCurrent.reference)#</cfoutput></div>
                <div class="h5 mb-1"><cfoutput>#lsCurrencyFormat(VARIABLES.adsPaymentCurrent.amountCents / 100)#</cfoutput></div>
                <div>
                  <cfif VARIABLES.adsPaymentCurrent.status EQ "PAID">
                    <span class="badge badge-success"><cfoutput>#htmlEditFormat(adsV1PaymentStatusLabel(VARIABLES.adsPaymentCurrent.status))#</cfoutput></span>
                  <cfelseif listFind("FAILED,CANCELED,EXPIRED,REFUNDED,CHARGEBACK,REVIEW", VARIABLES.adsPaymentCurrent.status)>
                    <span class="badge badge-warning"><cfoutput>#htmlEditFormat(adsV1PaymentStatusLabel(VARIABLES.adsPaymentCurrent.status))#</cfoutput></span>
                  <cfelse>
                    <span class="badge badge-info">Aguardando / Confirmando</span>
                  </cfif>
                </div>
                <cfif isDate(VARIABLES.adsPaymentCurrent.expiresAt) AND NOT listFind("PAID,REFUNDED,CHARGEBACK", VARIABLES.adsPaymentCurrent.status)>
                  <div class="small text-muted mt-2">Checkout valido ate <cfoutput>#lsDateFormat(VARIABLES.adsPaymentCurrent.expiresAt, "dd/mm/yyyy")# #lsTimeFormat(VARIABLES.adsPaymentCurrent.expiresAt, "HH:nn")#</cfoutput>.</div>
                </cfif>
              </div>
              <div class="d-flex flex-wrap align-items-start gap-2">
                <cfif len(VARIABLES.adsPaymentValidatedCheckoutUrl) AND listFind("CREATED,CHECKOUT_READY,PENDING", VARIABLES.adsPaymentCurrent.status)>
                  <a class="btn btn-info" target="_blank" rel="noopener noreferrer" href="<cfoutput>#htmlEditFormat(VARIABLES.adsPaymentValidatedCheckoutUrl)#</cfoutput>">Ir para o pagamento</a>
                </cfif>
                <a class="btn btn-outline-light" href="<cfoutput>./?view=payments&amp;payment=#urlEncodedFormat(VARIABLES.adsPaymentCurrent.paymentIntentId)###payment-credit</cfoutput>">Atualizar status</a>
              </div>
            </div>
          </div>
        </cfif>

        <cfif NOT VARIABLES.adsPaymentProviderStatus.ready OR NOT VARIABLES.adsPaymentProviderStatus.enabled>
          <div class="alert alert-info mb-0">Novas compras estao temporariamente indisponiveis. Checkouts existentes e o historico permanecem acessiveis.</div>
        <cfelseif VARIABLES.adsAccessCanPurchaseCredit>
          <form method="post" action="./?view=payments#payment-credit" id="ads-payment-form" class="js-payment-checkout-form" data-submitting="false">
            <input type="hidden" name="ads_v1_action" value="create_payment_checkout"/>
            <input type="hidden" name="ads_payment_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsPaymentCsrf)#</cfoutput>"/>
            <input type="hidden" name="ads_payment_idempotency_key" value="<cfoutput>#htmlEditFormat(VARIABLES.adsPaymentIdempotencyKey)#</cfoutput>"/>
            <div class="row g-3 align-items-end">
              <div class="col-lg-6">
                <label class="form-label" for="ads-payment-amount">Valor do crédito</label>
                <div class="input-group"><span class="input-group-text">R$</span><input class="form-control" id="ads-payment-amount" name="ads_payment_amount" type="number" min="50" max="21474836.47" step="0.01" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsPaymentAmountRaw)#</cfoutput>"/></div>
              </div>
              <div class="col-lg-6">
                <div class="d-flex flex-wrap gap-2" aria-label="Valores sugeridos">
                  <button class="btn btn-outline-info ads-payment-amount-shortcut" type="button" data-amount="100.00">R$ 100</button>
                  <button class="btn btn-outline-info ads-payment-amount-shortcut" type="button" data-amount="250.00">R$ 250</button>
                  <button class="btn btn-outline-info ads-payment-amount-shortcut" type="button" data-amount="500.00">R$ 500</button>
                </div>
              </div>
              <div class="col-lg-8">
                <p class="small text-muted mb-0">Pague por PIX ou cartão de crédito em 1x no ambiente seguro do Pagar.me. O Business não recebe os dados do seu cartão.</p>
              </div>
              <div class="col-lg-4 d-grid">
                <button class="btn btn-info" type="submit" data-payment-submit>Continuar para pagamento</button>
              </div>
            </div>
          </form>
        <cfelse>
          <div class="alert alert-secondary mb-0">Somente OWNER ou ADMIN da conta pode adicionar saldo.</div>
        </cfif>
      </cfif>
    </div>
  </section>

  <cfif VARIABLES.adsPaymentApiReady AND VARIABLES.adsPaymentDataReady>
    <section class="card shadow-0 mb-4">
      <div class="card-body p-3 p-lg-4">
        <div class="ads-v1-eyebrow">Pagamentos</div>
        <h2 class="h5">Histórico de pagamentos</h2>
        <div class="table-responsive">
          <table class="table table-sm align-middle mb-0">
            <thead><tr><th>Data</th><th>Referência</th><th>Método</th><th>Status</th><th class="text-end">Valor</th><th>Crédito</th></tr></thead>
            <tbody>
              <cfif qAdsPayments.recordcount>
                <cfoutput query="qAdsPayments">
                  <tr>
                    <td><cfif isDate(created_at)>#lsDateFormat(created_at, "dd/mm/yyyy")# #lsTimeFormat(created_at, "HH:nn")#<cfelse>-</cfif></td>
                    <td><a href="./?view=payments&amp;payment=#urlEncodedFormat(payment_intent_id)###payment-credit">#htmlEditFormat(support_reference)#</a></td>
                    <td><cfif payment_method EQ "pix">PIX<cfelseif payment_method EQ "credit_card">Cartao 1x<cfelse>-</cfif></td>
                    <td><span class="badge <cfif status EQ 'PAID'>badge-success<cfelseif listFind('FAILED,CANCELED,EXPIRED,REFUNDED,CHARGEBACK,REVIEW', status)>badge-warning<cfelse>badge-info</cfif>">#htmlEditFormat(adsV1PaymentStatusLabel(status))#</span></td>
                    <td class="text-end">#lsCurrencyFormat(amount_cents / 100)#</td>
                    <td><cfif len(trim(ledger_entry_id & ""))><span class="text-success">Creditado</span><cfelse><span class="text-muted">Aguardando</span></cfif></td>
                  </tr>
                </cfoutput>
              <cfelse>
                <tr><td colspan="6" class="text-muted text-center py-4">Nenhum pagamento iniciado.</td></tr>
              </cfif>
            </tbody>
          </table>
        </div>
      </div>
    </section>
  </cfif>

  <script>
  (function () {
    var amount = document.getElementById('ads-payment-amount');
    document.querySelectorAll('.ads-payment-amount-shortcut').forEach(function (button) {
      button.addEventListener('click', function () {
        if (amount) amount.value = button.getAttribute('data-amount');
      });
    });

    var form = document.getElementById('ads-payment-form');
    if (form) {
      form.addEventListener('submit', function (event) {
        if (form.dataset.submitting === 'true') {
          event.preventDefault();
          return;
        }
        form.dataset.submitting = 'true';
        var submit = form.querySelector('[data-payment-submit]');
        if (submit) submit.disabled = true;
      });
    }

    var pending = document.getElementById('ads-payment-pending');
    if (!pending) return;
    var paymentId = pending.getAttribute('data-payment-intent');
    var delay = 5000;
    function pollPaymentStatus() {
      fetch('/api/ads/payments/status.cfm?payment=' + encodeURIComponent(paymentId), {
        method: 'GET',
        credentials: 'same-origin',
        headers: { 'Accept': 'application/json' },
        cache: 'no-store'
      }).then(function (response) {
        if (!response.ok) throw new Error('status_unavailable');
        return response.json();
      }).then(function (result) {
        if (result.status === 'paid' || result.status === 'refunded' || result.status === 'chargeback') {
          window.location.reload();
          return;
        }
        delay = Math.min(delay * 1.5, 30000);
        window.setTimeout(pollPaymentStatus, delay);
      }).catch(function () {
        delay = Math.min(delay * 2, 30000);
        window.setTimeout(pollPaymentStatus, delay);
      });
    }
    window.setTimeout(pollPaymentStatus, delay);
  }());
  </script>
  </cfif>
</cfif>
