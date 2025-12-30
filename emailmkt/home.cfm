<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="row">
            <div class="col">
                <h3>Email Marketing</h3>
            </div>
            <div class="col text-end">
                <a href="fila.cfm" target="_blank"><button class="btn btn-outline-danger">Enviar Fila</button></a>
            </div>
          </div>

          <hr/>
  
          <h5>Fila de Envio</h5>
          
          <cfquery name="qFilaEmail">
            SELECT * FROM tb_mailing
            WHERE data_envio IS NULL AND bounce IS NULL
            ORDER BY data_disparo desc
            LIMIT 10
          </cfquery>
  
          <table class="table table-sm table-striped table-hover">
              <thead>
                <tr>
                    <th></th>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Assunto</th>
                    <th class="text-end">Enviar em</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qFilaEmail">
                    <tr>
                        <td>
                            <a href="/emailmkt/?campanha=#qFilaEmail.id_mailing#&acao=status_campanha&status=3"><icon class="fa fa-pause"></icon></a>
                            <a href="/emailmkt/?campanha=#qFilaEmail.id_mailing#&acao=status_campanha&status=4"><icon class="fa fa-archive"></icon></a>
                            <a href="/emailmkt/?campanha=#qFilaEmail.id_mailing#&acao=editar"><icon class="fa fa-edit"></icon></a>
                        </td>
                        <td>#qFilaEmail.nome#</td>
                        <td>#qFilaEmail.email#</td>
                        <td>#qFilaEmail.assunto#</td>
                        <td class="text-end <cfif qFilaEmail.data_disparo LT now()>text-danger</cfif>">#LSDateTimeFormat(qFilaEmail.data_disparo, "dd/mm/yyyy HH:nn:ss")#</td>
                    </tr>
                </cfoutput>
              </tbody>
          </table>

          <hr/>

          <h5>Enviados</h5>

          <cfquery name="qFilaEmail">
            SELECT * FROM tb_mailing
            WHERE data_envio IS NOT NULL OR bounce IS NOT NULL
            ORDER BY data_envio desc
            LIMIT 20
          </cfquery>

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
                        <td>#qFilaEmail.nome#</td>
                        <td>#qFilaEmail.email#</td>
                        <td>#qFilaEmail.assunto#</td>
                        <td class="text-end">#qFilaEmail.enviado#</td>
                        <td class="text-end">#qFilaEmail.recebido#</td>
                        <td class="text-end">#qFilaEmail.aberto#</td>
                        <td class="text-end">#qFilaEmail.clicks#</td>
                        <cfif len(trim(qFilaEmail.bounce))>
                            <td class="text-end text-danger">#qFilaEmail.bounce#</td>
                        <cfelse>
                            <td class="text-end">#LSDateTimeFormat(qFilaEmail.data_envio, "dd/mm/yyyy HH:nn:ss")#</td>
                        </cfif>
                    </tr>
                </cfoutput>
              </tbody>
          </table>

          <!---hr/>

          <h5>Log de Envio</h5>

          <cfquery name="qLogEmail">
            SELECT * FROM tb_webhook
            where referencia = 'mandrill'
            and body like '%roadrunners.run%'
            order by call_date desc
            limit 10
          </cfquery>

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
                        <td><cfdump var="#deserializeJSON(replace(urlDecode(qLogEmail.body), "mandrill_events=", ""))#"></td>
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

