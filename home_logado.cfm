<!--- CONTEUDO --->

<div class="row g-2">


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
                    Plataforma Ads disponível a partir de <b>01 de janeiro</b>.
                </div>
            </div>
        </div>
    </div>

    <cfoutput query="qPermissoes" group="tipo">

        <!---<hr/>--->

        <div>
            <h4 class="bg-black bg-opacity-25 px-2 py-1 rounded">#uCase(qPermissoes.tipo)#</h4>
        </div>

        <cfif NOT #qPermissoes.recordcount#>Seu cadastro está em análise, você receberá um email ou mensagem no momento da ativação.</cfif>

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

    </cfoutput>

</div>
