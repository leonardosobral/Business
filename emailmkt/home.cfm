<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()><cflocation url="/emailmkt/" addtoken="false"/></cfif>
<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <h1 class="h3">E-mail marketing</h1>
          <div class="d-flex flex-wrap gap-2 mb-4">
            <a class="btn btn-warning" href="/crm-interno/">Públicos e campanhas</a>
            <a class="btn btn-outline-secondary" href="/portal/funil/">Funil de vendas</a>
          </div>
          <section class="mb-4" aria-labelledby="selo-oferta">
            <h2 id="selo-oferta" class="h5">Black Friday · Atleta Verificado</h2>
            <p>R$ 9,90 por 12 meses, com renovação manual.</p>
            <p><a class="btn btn-outline-secondary" href="/emailmkt/?previa=selo-brevo" target="_blank" rel="noopener">Visualizar e-mail da oferta</a></p>
            <cfinclude template="brevo_panel.cfm"/>
            <cftry>
              <cfquery name="qOferta" datasource="runner_dba" timeout="15">
                SELECT count(*) AS pedidos, count(DISTINCT o.user_id) AS compradores, coalesce(sum(o.amount_cents),0) AS centavos
                FROM rr_verified.orders o
                WHERE o.product_code='rr_selo_verificado_anual' AND o.provider_mode='production'
                  AND o.currency='BRL' AND o.state='paid' AND o.paid_at BETWEEN o.created_at AND now()
                  AND EXISTS (
                    SELECT 1 FROM rr_verified.payment_events a WHERE a.order_id=o.id AND a.event_type='offer_attribution_v1'
                      AND a.details->>'environment'='prod' AND a.details->>'is_internal'='false'
                      AND a.details->>'medium'='email'
                      AND (
                        (a.details->>'source'='brevo' AND a.details->>'campaign' IN ('selo-atleta-20261127','seloatleta20261127'))
                        OR (a.details->>'source'='mailchimp' AND a.details->>'campaign'='selo-atleta-20261127')
                      )
                  )
                  AND NOT EXISTS (SELECT 1 FROM rr_verified.payment_events e WHERE e.order_id=o.id AND e.event_type='refunded')
              </cfquery>
              <p><strong>Compras atribuídas ao link do e-mail</strong> · <cfoutput>#qOferta.pedidos# pedidos pagos · #qOferta.compradores# compradores · R$ #lsNumberFormat(qOferta.centavos / 100, "0.00", "pt_BR")#</cfoutput></p>
              <cfcatch><p>Compras atribuídas indisponíveis no momento.</p></cfcatch>
            </cftry>
            <a class="text-decoration-underline" href="/emailmkt/?modelo=selo-brevo" download>Baixar o HTML do e-mail da Brevo</a>
          </section>
          <hr/>
          <h2 class="h5">Fila antiga</h2>
          <cfquery name="qFilaEmail">
            SELECT * FROM tb_mailing
            WHERE data_envio IS NULL AND bounce IS NULL
            ORDER BY data_disparo desc
            LIMIT 10
          </cfquery>
  
          <div class="table-responsive">
          <table class="table table-sm table-striped table-hover">
              <thead>
                <tr>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Assunto</th>
                    <th class="text-end">Enviar em</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qFilaEmail">
                    <tr>
                        <td>#encodeForHTML(qFilaEmail.nome)#</td>
                        <td>#encodeForHTML(qFilaEmail.email)#</td>
                        <td>#encodeForHTML(qFilaEmail.assunto)#</td>
                        <td class="text-end <cfif qFilaEmail.data_disparo LT now()>text-danger</cfif>">#LSDateTimeFormat(qFilaEmail.data_disparo, "dd/mm/yyyy HH:nn:ss")#</td>
                    </tr>
                </cfoutput>
              </tbody>
          </table>
          </div>

          <hr/>

          <h2 class="h5">Histórico de envios</h2>

          <cfquery name="qFilaEmail">
            SELECT * FROM tb_mailing
            WHERE data_envio IS NOT NULL OR bounce IS NOT NULL
            ORDER BY data_envio desc
            LIMIT 20
          </cfquery>

          <div class="table-responsive">
          <table class="table table-sm table-striped table-hover">
              <thead>
                <tr>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Assunto</th>
                    <th class="text-end">Enviado</th>
                    <th class="text-end">Recebido</th>
                    <th class="text-end">Aberto</th>
                    <th class="text-end">Clicks</th>
                    <th class="text-end">Data de Envio</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qFilaEmail">
                    <tr>
                        <td>#encodeForHTML(qFilaEmail.nome)#</td>
                        <td>#encodeForHTML(qFilaEmail.email)#</td>
                        <td>#encodeForHTML(qFilaEmail.assunto)#</td>
                        <td class="text-end">#qFilaEmail.enviado#</td>
                        <td class="text-end">#qFilaEmail.recebido#</td>
                        <td class="text-end">#qFilaEmail.aberto#</td>
                        <td class="text-end">#qFilaEmail.clicks#</td>
                        <cfif len(trim(qFilaEmail.bounce))>
                            <td class="text-end text-danger">#encodeForHTML(qFilaEmail.bounce)#</td>
                        <cfelse>
                            <td class="text-end">#LSDateTimeFormat(qFilaEmail.data_envio, "dd/mm/yyyy HH:nn:ss")#</td>
                        </cfif>
                    </tr>
                </cfoutput>
              </tbody>
          </table>
          </div>

          <!---hr/>

          <h5>Log de Envio</h5>

          <cfquery name="qLogEmail">
            SELECT * FROM tb_webhook
            where referencia = 'mandrill'
            and body like '%roadrunners.run%'
            order by call_date desc
            limit 10
          </cfquery>

          <div class="table-responsive">
          <table class="table table-sm table-striped table-hover">
              <thead>
                <tr>
                    <th>Log</th>
                    <th>Data do log</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qLogEmail">
                    <tr>
                        <td>#encodeForHTML(left(qLogEmail.body, 500))#</td>
                        <td>#LSDateTimeFormat(qLogEmail.call_date, "dd/mm/yyyy HH:nn:ss")#</td>
                    </tr>
                </cfoutput>
              </tbody>
          </table--->

        </div>

      </div>

    </div>

  </div>

</section>
