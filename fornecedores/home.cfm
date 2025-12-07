<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO--->

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
                 aria-controls="ex1-pills-2" aria-selected="false">Timers (<cfoutput>#qFornecedoresOrg.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Fornecedores (<cfoutput>#qFornecedoresOrg.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-4" data-mdb-pill-init href="#ex1-pills-4" role="tab"
                 aria-controls="ex1-pills-4" aria-selected="false">Creators (<cfoutput>#qFornecedoresOrg.recordcount#</cfoutput>)</a>
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

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

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

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

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

          </div>

        </div>

      </div>

    </div>

  </div>

</section>

