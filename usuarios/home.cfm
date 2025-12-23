<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO--->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="bg-light bg-opacity-10 rounded p-3">

            <!--- INCLUIR usuario --->

            <h3>Usuários</h3>

            <cfif NOT isDefined("URL.acao") AND NOT isDefined("URL.usuario")>
                <cfinclude template="includes/form_usuario.cfm"/>
            </cfif>

            </div>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Aprovar (<cfoutput>#qUsuariosBaseAprovar.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Completar (<cfoutput>#qUsuariosBaseCompletar.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Ativos (<cfoutput>#qUsuariosBase.recordcount#</cfoutput>)</a>
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
                            <th>Email</th>
                            <th>Perfil</th>
                            <th>Nome comercial</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qUsuariosBaseAprovar">
                            <tr>
                                <td>
                                    <a href="./?usuario=#qUsuariosBaseAprovar.id#&acao=status_usuario&status=1"><icon class="fa fa-check"></icon></a>
                                    <a href="./?usuario=#qUsuariosBaseAprovar.id#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qUsuariosBaseAprovar.name# <cfif NOT qUsuariosBaseAprovar.is_partner><span class="badge badge-success">em aprovação</span></cfif></td>
                                <td>#qUsuariosBaseAprovar.email#</td>
                                <td>#qUsuariosBaseAprovar.perfil#</td>
                                <td>#qUsuariosBaseAprovar.nome_comercial#</td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.usuario") and URL.usuario EQ qUsuariosBaseAprovar.id>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR USUARIO --->
                                        <cfset VARIABLES.usuario = QueryGetRow(qUsuariosBaseAprovar, qUsuariosBaseAprovar.currentRow)>
                                        <h5 class="mb-3">Editar Usuário</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_usuario.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
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
                            <th>Email</th>
                            <th>Perfil</th>
                            <th>Nome comercial</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qUsuariosBaseCompletar">
                            <tr>
                                <td>
                                    <a href="./?usuario=#qUsuariosBaseCompletar.id#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qUsuariosBaseCompletar.name# <cfif NOT qUsuariosBaseCompletar.is_partner><span class="badge badge-success">em aprovação</span></cfif></td>
                                <td>#qUsuariosBaseCompletar.email#</td>
                                <td>#qUsuariosBaseCompletar.perfil#</td>
                                <td>#qUsuariosBaseCompletar.nome_comercial#</td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.usuario") and URL.usuario EQ qUsuariosBaseCompletar.id>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR USUARIO --->
                                        <cfset VARIABLES.usuario = QueryGetRow(qUsuariosBaseCompletar, qUsuariosBaseCompletar.currentRow)>
                                        <h5 class="mb-3">Editar Usuário</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_usuario.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
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
                            <th>Email</th>
                            <th>Perfil</th>
                            <th>Nome comercial</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qUsuariosBase">
                            <tr>
                                <td>
                                    <a href="./?usuario=#qUsuariosBase.id#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qUsuariosBase.name# <cfif NOT qUsuariosBase.is_partner><span class="badge badge-success">em aprovação</span></cfif></td>
                                <td>#qUsuariosBase.email#</td>
                                <td>#qUsuariosBase.perfil#</td>
                                <td>#qUsuariosBase.nome_comercial#</td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.usuario") and URL.usuario EQ qUsuariosBase.id>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR USUARIO --->
                                        <cfset VARIABLES.usuario = QueryGetRow(qUsuariosBase, qUsuariosBase.currentRow)>
                                        <h5 class="mb-3">Editar Usuário</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_usuario.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
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

