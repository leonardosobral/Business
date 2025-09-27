<cfinclude template="backend.cfm"/>

<!--- WIDGETS --->
<section class="mb-5">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-thermometer-half fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Views</p>
              <h2 class="mb-0">
                <cfoutput>#qAdCountViews.total#</cfoutput>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 d-none d-xl-block mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-wind fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Clicks</p>
              <h2 class="mb-0">
                <cfoutput>#qAdCountClicks.total#</cfoutput>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-tint fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">CPC Médio</p>
              <h2 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorMedio.total)#</cfoutput>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-tint fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Investimento</p>
              <h2 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorTotal.total)#</cfoutput>
              </h2>
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

            <div class="tab-pane fade show active" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-hover">
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

            <div class="tab-pane fade" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">
              <div class="bg-image rounded-4">
                <img src="https://mdbootstrap.com/img/Photos/dashboard/home/bedroom.jpg" class="w-100"
                     alt="Louvre Museum" />
                <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                  <div class="d-flex justify-content-between align-items-start h-100 p-4">
                    <small class="text-white">
                      23.05.2022 18:45
                    </small>

                    <span class="badge badge-light">
                      <i class="fas fa-video me-1 text-danger"></i>
                      <span>Recording</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div class="tab-pane fade" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">
              <div class="bg-image rounded-4">
                <img src="https://mdbootstrap.com/img/Photos/dashboard/home/living-room.jpg" class="w-100"
                     alt="Louvre Museum" />
                <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                  <div class="d-flex justify-content-between align-items-start h-100 p-4">
                    <small class="text-white">
                      23.05.2022 18:45
                    </small>

                    <span class="badge badge-light">
                      <i class="fas fa-video me-1 text-danger"></i>
                      <span>Recording</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>

          </div>


          <hr/>

          <!--- INCLUIR CAMPANHA --->
          <form method="post">

            <h3>Incluir Campanha</h3>

            <div data-mdb-input-init class="form-outline mb-4">
              <input type="text" name="evento" id="form1Example1" class="form-control"
              value="https://roadrunners.run/evento/2026-maratona-internacional-de-floripa-2026/"/>
              <label class="form-label" for="form1Example1">Evento</label>
            </div>

            <div class="row mb-4">
              <div class="col">
                <div data-mdb-input-init class="form-outline">
                  <input type="text" name="cpc_max" id="form3Example1" class="form-control"
                  value="1.00"/>
                  <label class="form-label" for="form3Example1">CPC max</label>
                </div>
              </div>
              <div class="col">
                <div data-mdb-input-init class="form-outline">
                  <input type="text" name="limite_diario" id="form3Example2" class="form-control"
                  value="20.00"/>
                  <label class="form-label" for="form3Example2">Valor diário</label>
                </div>
              </div>
              <div class="col">
                <div data-mdb-input-init class="form-outline">
                  <input type="text" name="limite_ad" id="form3Example2" class="form-control"
                  value="100.00"/>
                  <label class="form-label" for="form3Example2">Valor da Campanha</label>
                </div>
              </div>
            </div>

            <div class="row mb-4">
              <div class="col">
                <select name="escopo" data-mdb-select-init data-mdb-placeholder="Locais" multiple>
                  <option value="hom">Home</option>
                  <option value="busca">Busca</option>
                  <option value="feed">Feed de Usuários</option>
                </select>
              </div>
              <div class="col">
                <select name="locais" data-mdb-select-init data-mdb-placeholder="Público" multiple>
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

            <!-- 2 column grid layout for inline styling -->
            <div class="row mb-4">
              <div class="col d-flex">
                <!-- Checkbox -->
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" value="" id="form1Example3" checked />
                  <label class="form-check-label" for="form1Example3"> aprovar anúncio e começar </label>
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

</section>

