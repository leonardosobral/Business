<cfinclude template="backend.cfm"/>

<!--- WIDGETS --->
<section class="mb-4">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-eye fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Views</p>
              <h3 class="mb-0">
                <cfoutput>#qAdCountViews.total#</cfoutput>
              </h3>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 d-none d-xl-block mb-lg-0">
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
              <h3 class="mb-0">
                <cfoutput>#qAdCountClicks.total#</cfoutput>
              </h3>
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
              <p class="text-muted mb-1">CPC Médio</p>
              <h3 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorMedio.total)#</cfoutput>
              </h3>
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
              <p class="text-muted mb-1">Investimento</p>
              <h3 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorTotal.total)#</cfoutput>
              </h3>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
    
</section>

<!--- CONTEUDO--->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Ativos</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Pausados</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Finalizados</a>
            </li>
          </ul>


          <!--- CONTEUDO ABAS --->
          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAds">
                            <tr>
                                <td>#qEventosAds.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAds.qualidade#</td--->
                                <td class="text-end">#qEventosAds.ad_rank#</td>
                                <td class="text-end">#qEventosAds.views#</td>
                                <td class="text-end">#qEventosAds.clicks#</td>
                                <td class="text-end">#lsNumberFormat(qEventosAds.clicks NEQ 0 ? qEventosAds.clicks*100/qEventosAds.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsPausados">
                            <tr>
                                <td>#qEventosAdsPausados.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsPausados.qualidade#</td--->
                                <td class="text-end">#qEventosAdsPausados.ad_rank#</td>
                                <td class="text-end">#qEventosAdsPausados.views#</td>
                                <td class="text-end">#qEventosAdsPausados.clicks#</td>
                                <td class="text-end">#lsNumberFormat(qEventosAdsPausados.clicks NEQ 0 ? qEventosAdsPausados.clicks*100/qEventosAdsPausados.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsFinalizados">
                            <tr>
                                <td>#qEventosAdsFinalizados.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsFinalizados.qualidade#</td--->
                                <td class="text-end">#qEventosAdsFinalizados.ad_rank#</td>
                                <td class="text-end">#qEventosAdsFinalizados.views#</td>
                                <td class="text-end">#qEventosAdsFinalizados.clicks#</td>
                                <td class="text-end">#lsNumberFormat(qEventosAdsFinalizados.clicks NEQ 0 ? qEventosAdsFinalizados.clicks*100/qEventosAdsFinalizados.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

          </div>


          <hr/>

            <div class="bg-light bg-opacity-10 rounded p-2">
              <!--- INCLUIR CAMPANHA --->
              <form method="post">

                <h3>Incluir Campanha</h3>

                <div data-mdb-input-init class="form-outline mb-4">
                  <input type="text" name="evento" id="form1Example1" class="form-control"
                  placeholder="https://roadrunners.run/evento/seu-evento/"
                  required/>
                  <label class="form-label" for="form1Example1">URL do Evento</label>
                </div>

                <div class="row mb-4">
                  <div class="col">
                    <div data-mdb-input-init class="form-outline">
                      <input type="number" name="cpc_max" id="form3Example1" class="form-control"
                      value="1.00"
                      required/>
                      <label class="form-label" for="form3Example1">CPC max</label>
                    </div>
                  </div>
                  <div class="col">
                    <div data-mdb-input-init class="form-outline">
                      <input type="number" name="limite_diario" id="form3Example2" class="form-control"
                      placeholder="20.00"/>
                      <label class="form-label" for="form3Example2">Valor max diário</label>
                    </div>
                  </div>
                  <div class="col">
                    <div data-mdb-input-init class="form-outline">
                      <input type="number" name="limite_ad" id="form3Example2" class="form-control"
                      placeholder="100.00"/>
                      <label class="form-label" for="form3Example2">Valor max da Campanha</label>
                    </div>
                  </div>
                </div>

                <div class="row mb-4">
                  <div class="col">
                    <select name="escopo" data-mdb-select-init data-mdb-placeholder="Locais" multiple required>
                      <option value="hom">Home</option>
                      <option value="busca">Busca</option>
                      <option value="feed">Feed de Usuários</option>
                    </select>
                  </div>
                  <div class="col">
                    <select name="locais" data-mdb-select-init data-mdb-placeholder="Público" multiple required>
                      <cfoutput query="qAdUFs">
                        <option value="#qAdUFs.uf#">#qAdUFs.uf# - #qAdUFs.nome_uf#</option>
                      </cfoutput>
                    </select>
                  </div>
                  <div class="col">
                    <div class="form-outline" data-mdb-datepicker-init data-mdb-input-init data-mdb-date-range="true" data-mdb-inline="true">
                      <input type="text" name="datas" class="form-control" id="date-range-inline" />
                      <label for="date-range-inline" class="form-label">Data da Campanha</label>
                    </div>
                  </div>
                </div>

                <!-- Submit button -->
                <button data-mdb-ripple-init type="submit" class="btn btn-primary btn-block">Incluir Campanha</button>

              </form>

            </div>

        </div>

      </div>

    </div>

  </div>

</section>

