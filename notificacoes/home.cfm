<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- WIDGETS --->

<section class="mb-4">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-bell fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Notificações</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qNotificaCount.total, "9,999,999")#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-hand-pointer fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Clicks</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qNotificaCountClicks.total, "9,999,999")# (#LSNumberFormat((qNotificaCountClicks.total*100)/qNotificaCount.total, "9.99")#%)</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Conversão</p>
              <h4 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qNotificaCountConversoes.valor_total)# (#qNotificaCountConversoes.total#)</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

</section>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="row">
            <div class="col">
                <h3>Notificações</h3>
            </div>
            <div class="col text-end">
                <!---a href="fila.cfm" target="_blank"><button class="btn btn-outline-danger">Enviar Fila</button></a--->
            </div>
          </div>

          <hr/>
  
          <cfquery name="qFilaEmail">
            SELECT t.id_usuario, t.link,
              (select data_inscricao from desafios where id_usuario = t.id_usuario and desafio = 'todosantodia' order by status limit 1) as data_inscricao_todosantodia,
              (select data_inscricao from desafios where id_usuario = t.id_usuario and desafio = 'desafio365' order by status limit 1) as data_inscricao_365 ,
              (select status from desafios where id_usuario = t.id_usuario and desafio = 'todosantodia' order by status limit 1) as status
            FROM public.tb_notifica t
            WHERE data_leitura is not null
            ORDER BY data_inscricao_todosantodia DESC NULLS LAST
            --LIMIT 10
          </cfquery>
  
          <table class="table table-sm table-striped table-hover">
              <thead>
                <tr>
                    <th>id_usuario</th>
                    <th>Link</th>
                    <th class="text-end">Inscrição TSD</th>
                    <th class="text-end">Inscrição 365</th>
                    <th class="text-end">Status TSD</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qFilaEmail">
                    <tr>
                        <td>#qFilaEmail.id_usuario#</td>
                        <td>#qFilaEmail.link#</td>
                        <td class="text-end <cfif qFilaEmail.data_inscricao_todosantodia GT '2025-12-29 15:10:00'>text-success</cfif>">#LSDateTimeFormat(qFilaEmail.data_inscricao_todosantodia, "dd/mm/yyyy HH:nn:ss")#</td>
                        <td class="text-end">#LSDateTimeFormat(qFilaEmail.data_inscricao_365, "dd/mm/yyyy HH:nn:ss")#</td>
                        <td class="text-end <cfif qFilaEmail.status EQ 'C'>text-success</cfif>">#qFilaEmail.status#</td>
                </tr>
                </cfoutput>
              </tbody>
          </table>

        </div>

      </div>

    </div>

  </div>

</section>

