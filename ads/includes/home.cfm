<cfinclude template="backend.cfm"/>

<!--- Navbar --->
<nav id="main-navbar" class="navbar navbar-expand-lg shadow-1">

  <!--- Container wrapper --->
  <div class="container-fluid">

    <!--- Toggler --->
    <!---<button data-mdb-toggle="sidenav" data-mdb-target="#main-sidenav"
      class="btn shadow-0 p-0 me-3 d-block d-xxl-none" data-mdb-ripple-init aria-controls="#main-sidenav"
      aria-haspopup="true">
      <i class="fas fa-bars fa-lg"></i>
    </button>--->

    <!--- Search form --->
    <form class="d-none d-md-flex input-group w-auto my-auto">
      <input id="search-focus" autocomplete="off" type="search" class="form-control rounded"
        placeholder='Pesquisa' style="min-width: 225px" />
      <span class="input-group-text border-0"><i class="fas fa-search text-secondary"></i></span>
    </form>

    <!--- Right links --->
    <ul class="navbar-nav ms-auto d-flex flex-row">

      <!--- Notification dropdown --->
      <li class="nav-item dropdown">
        <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdownMenuLink"
          role="button" data-mdb-dropdown-init aria-expanded="false">
          <i class="fas fa-bell link-secondary"></i>
          <span class="badge rounded-pill badge-notification bg-danger">1</span>
        </a>
        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownMenuLink">
          <li><a class="dropdown-item disabled" href="#">Sem notificações</a></li>
        </ul>
      </li>

      <!--- Icon dropdown --->
      <li class="nav-item dropdown">
        <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdown" role="button"
          data-mdb-dropdown-init aria-expanded="false">
          <i class="flag flag-brazil m-0"></i>
        </a>
        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
          <li>
            <a class="dropdown-item" href="#"><i class="flag flag-brazil flag"></i>Português
              <i class="fa fa-check text-success ms-2"></i></a>
          </li>
          <li>
            <hr class="dropdown-divider" />
          </li>
          <!---<li>
            <a class="dropdown-item" href="#"><i class="flag flag-china"></i>中文</a>
          </li>
            <li>
            <a class="dropdown-item" href="#"><i class="flag flag-japan"></i>日本語</a>
          </li>--->
            <li>
            <a class="dropdown-item disabled" href="#"><i class="flag flag-united-states"></i>English</a>
          </li>
            <li>
            <a class="dropdown-item disabled" href="#"><i class="flag flag-germany"></i>Deutsch</a>
          </li>
            <li>
            <a class="dropdown-item disabled" href="#"><i class="flag flag-france"></i>Français</a>
          </li>
            <li>
            <a class="dropdown-item" disabled href="#"><i class="flag flag-spain"></i>Español</a>
          </li>
            <!---<li>
            <a class="dropdown-item" href="#"><i class="flag flag-russia"></i>Русский</a>
          </li>--->
            <!---<li>
                <a class="dropdown-item" href="#"><i class="flag flag-poland"></i>Polski</a>
            </li>--->
        </ul>
      </li>

      <!--- Avatar --->
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle hidden-arrow d-flex align-items-center" href="#"
          id="navbarDropdownMenuLink" role="button" data-mdb-dropdown-init aria-expanded="false">
          <img src="https://mdbootstrap.com/img/new/avatars/2.jpg" class="rounded-circle" height="22" alt="Avatar"
            loading="lazy" />
        </a>
        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownMenuLink">
          <li><a class="dropdown-item " href="#">Cadastro</a></li>
          <li><a class="dropdown-item" href="#">Equipe</a></li>
          <li><a class="dropdown-item" href="#">Assinaturas</a></li>
          <li><a class="dropdown-item" href="#">Sair</a></li>
        </ul>
      </li>
    </ul>
  </div>

</nav>

<!--- WIDGETS --->
<section class="mb-5">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-eye fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
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
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-hand-pointer fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
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
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
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
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
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

            <div class="tab-pane fade" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

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

</section>

