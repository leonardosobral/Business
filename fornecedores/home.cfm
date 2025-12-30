<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <h3>Fornecedores</h3>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Organizadores (<cfoutput>#qFornecedoresOrg.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Timers (<cfoutput>#qFornecedoresTimer.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Assessorias (<cfoutput>#qFornecedoresAssessorias.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-4" data-mdb-pill-init href="#ex1-pills-4" role="tab"
                 aria-controls="ex1-pills-4" aria-selected="false">Fornecedores (<cfoutput>#qFornecedoresOutros.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-5" data-mdb-pill-init href="#ex1-pills-5" role="tab"
                 aria-controls="ex1-pills-5" aria-selected="false">Creators (<cfoutput>#qFornecedoresCreator.recordcount#</cfoutput>)</a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->
          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Nome</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qFornecedoresOrg">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qFornecedoresOrg.id_fornecedor#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qFornecedoresOrg.nome_fornecedor# <cfif qFornecedoresOrg.status EQ 1><span class="badge badge-success">em verificação</span></cfif></td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Nome</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qFornecedoresTimer">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qFornecedoresTimer.id_fornecedor#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qFornecedoresTimer.nome_fornecedor# <cfif qFornecedoresTimer.status EQ 1><span class="badge badge-success">em verificação</span></cfif></td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Nome</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qFornecedoresAssessorias">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qFornecedoresAssessorias.id_fornecedor#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qFornecedoresAssessorias.nome_fornecedor# <cfif qFornecedoresAssessorias.status EQ 1><span class="badge badge-success">em verificação</span></cfif></td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Nome</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qFornecedoresOutros">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qFornecedoresOutros.id_fornecedor#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qFornecedoresOutros.nome_fornecedor# <cfif qFornecedoresOutros.status EQ 1><span class="badge badge-success">em verificação</span></cfif></td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-5" role="tabpanel" aria-labelledby="ex1-tab-5">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Nome</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qFornecedoresCreator">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qFornecedoresCreator.id_fornecedor#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qFornecedoresCreator.nome_fornecedor# <cfif qFornecedoresCreator.status EQ 1><span class="badge badge-success">em verificação</span></cfif></td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

          </div>

        </div>

      </div>

    </div>

  </div>

</section>

