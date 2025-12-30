<!--- CONTEUDO --->

<div class="row g-3">


    <cfif NOT qPermissoes.recordcount>
        <div class="col-12">
            <div data-mdb-alert-init class="alert text-center" role="alert" data-mdb-color="light">
                <b>Cadastro inicial realizado com sucesso.</b><br>Seu perfil está sob análise.
            </div>
        </div>
    </cfif>

    <div class="col-12">
        <div class="card bg-warning bg-opacity-50">
            <div class="row p-3">
                <div class="col-md-6 text-center align-content-center"><img src="/lib/images/runpro.svg" class="w-50"></div>
                <div class="col-md-6 align-content-center">
                    Plataforma Ads disponível a partir de <b>05 de janeiro</b>.
                </div>
            </div>
        </div>
    </div>


    <cfif NOT #qPermissoes.recordcount#>Seu cadastro está em análise, você receberá um email ou mensagem no momento da ativação.</cfif>


    <!--- VERIFICA TAGS COM CARACTERES ESPECIAIS --->

    <cfquery name="qManutencaoItem">
        select id_usuario_cadastro, nome, tag from tb_paginas where tag ilike '% %' OR tag = '' OR tag is null or tag ilike '%/%' or tag ilike '%|%' or tag ilike '%\%';
    </cfquery>

    <cfif qManutencaoItem.recordcount>

        <div class="col-md-6">

            <div class="card">

                <div class="card-header">Tags com caracteres especiais</div>

                <div class="card-body">

                    <table class="table table-sm table-striped table-hover">
                  <thead>
                    <tr>
                        <th></th>
                        <th>ID</th>
                        <th>Nome</th>
                        <th>Tag</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfoutput query="qManutencaoItem">
                        <tr>
                            <td>
                                <a href="/emailmkt/?campanha=#qManutencaoItem.id_pagina#&acao=editar"><icon class="fa fa-edit"></icon></a>
                            </td>
                            <td>#qManutencaoItem.id_pagina#</td>
                            <td>#qManutencaoItem.nome#</td>
                            <td>#qManutencaoItem.tag#</td>
                        </tr>
                    </cfoutput>
                  </tbody>
              </table>

                    <div class="font-monospace">--update tb_paginas set tag = replace(lower(tag), ' ', '-') where tag ilike '% %';</div>

                </div>

            </div>

        </div>

    </cfif>


    <!--- AD LOGS DE BOTS --->

    <cfquery name="qManutencaoItem">
        select data_insercao::date as data,
        contexto ->> 'HTTP_USER_AGENT' as agente,
        count(*) as total
        from tb_ad_log
        where (contexto ->> 'HTTP_USER_AGENT' ilike '%bot%' OR contexto ->> 'HTTP_USER_AGENT' ilike '%crawl%' OR contexto ->> 'HTTP_USER_AGENT' ilike '%spider%')
        group by contexto ->> 'HTTP_USER_AGENT', data_insercao::date
        order by total desc;
    </cfquery>

    <cfif qManutencaoItem.recordcount>

        <div class="col-md-6">

            <div class="card">

                <div class="card-header">AD Logs de Bots</div>

                <div class="card-body">

                    <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Data</th>
                            <th>Agente</th>
                            <th>Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qManutencaoItem">
                            <tr>
                                <td>#qManutencaoItem.data#</td>
                                <td>#qManutencaoItem.agente#</td>
                                <td>#qManutencaoItem.total#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

                    <div class="font-monospace">
                        update tb_ad_log set status = 4 where (contexto ->> 'HTTP_USER_AGENT' ilike '%bot%' OR contexto ->> 'HTTP_USER_AGENT' ilike '%crawl%' OR contexto ->> 'HTTP_USER_AGENT' ilike '%spider%');
                        update tb_ad_log set status = 4 where id_usuario IN (select id from tb_usuarios where is_admin = true OR  is_dev = true);
                        delete from tb_ad_log where status = 4 and data_insercao < '2025-12-02';
                    </div>

                </div>

            </div>

        </div>

    </cfif>


    <!--- VERIFICA USUARIO PARA AUTORIZAR NO BUSINESS --->

    <cfquery name="qManutencaoItem">
        select usr.*,
        usr.partner_info ->> 'perfil' as perfil,
        usr.partner_info ->> 'celular' as celular,
        usr.partner_info ->> 'documento' as documento,
        usr.partner_info ->> 'nome_comercial' as nome_comercial
        from tb_usuarios usr where partner_info is not null;
    </cfquery>

    <cfif qManutencaoItem.recordcount>

        <div class="col-md-12">

            <div class="card">

                <div class="card-header">Verifica usuario para autorizar no business</div>

                <div class="card-body">

                    <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>perfil</th>
                            <th>nome_comercial</th>
                            <th>celular</th>
                            <th>documento</th>
                            <th>Partner</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qManutencaoItem">
                            <tr>
                                <td>
                                    <a href="/emailmkt/?campanha=#qManutencaoItem.email#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qManutencaoItem.name#</td>
                                <td>#qManutencaoItem.email#</td>
                                <td>#qManutencaoItem.perfil#</td>
                                <td>#qManutencaoItem.nome_comercial#</td>
                                <td>#qManutencaoItem.celular#</td>
                                <td>#qManutencaoItem.documento#</td>
                                <td>#qManutencaoItem.is_partner#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

                </div>

            </div>

        </div>

    </cfif>


    <cfoutput query="qPermissoes" group="tipo">

        <cfif qPermissoes.tipo EQ "bi">

            <div>
                <h4 class="bg-black bg-opacity-25 px-2 py-1 rounded">#uCase(qPermissoes.tipo)#</h4>
            </div>

            <cfoutput>

                <div class="col-sm-12 col-md-6 col-lg-4 col-xl-4">

                    <div class="card" data-mdb-theme="light">

                        <div class="card-header h6" style="background-color: #qPermissoes.cor_fundo#;">#qPermissoes.titulo#</div>

                        <div class="card-body text-center p-2 d-flex align-items-center justify-content-center" style="height: 100px">
                            <div>
                                <img src="/assets/logos/#qPermissoes.logo#.png?2" style="max-height:75px; max-width: 200px;" onerror="this.src='/assets/logos/runnerhub.png';">
                            </div>
                        </div>

                        <div class="card-footer p-3" style="background-color: #qPermissoes.cor_fundo#;">
                            <cfif qPermissoes.tipo EQ "eventos">
                                <div class="btn-group w-100" role="group" aria-label="menuEvento">
                                    <a class="btn btn-light px-2" target="_blank" href="https://roadrunners.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Calendário</a>
                                    <a class="btn btn-light px-2" target="_blank" href="https://openresults.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Resultados</a>
                                    <a class="btn btn-dark px-2" href="/evento/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                                </div>
                            <cfelse>
                                <a class="btn btn-dark w-100" href="/evento/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                            </cfif>
                        </div>

                    </div>

                </div>

            </cfoutput>

        </cfif>

    </cfoutput>

</div>
