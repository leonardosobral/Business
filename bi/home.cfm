<div class="row g-3">

    <cfoutput query="qPermissoes" group="tipo">

        <!---<hr/>--->

        <div>
            <h4 class="bg-black bg-opacity-25 px-2 py-1 rounded">#uCase(qPermissoes.tipo)#</h4>
        </div>

        <cfif NOT #qPermissoes.recordcount#>Sem permissão</cfif>

        <cfoutput>

            <div class="mb-1 col-sm-12 col-md-6 col-lg-4">

                <div class="card" data-mdb-theme="light">

                    <div class="card-header h6" style="background-color: #qPermissoes.cor_fundo#;">#qPermissoes.titulo#</div>

                    <div class="card-body text-center p-2 d-flex align-items-center justify-content-center" style="height: 100px">
                        <div>
                            <a href="/bi/#qPermissoes.tag#/"><img src="/assets/logos/#qPermissoes.logo#.png?2" style="max-height:75px; max-width: 200px;" onerror="this.src='/assets/logos/runnerhub.png';"></a>
                        </div>
                    </div>

                    <div class="card-footer p-3" style="background-color: #qPermissoes.cor_fundo#;">
                        <cfif qPermissoes.tipo EQ "eventos">
                            <div class="btn-group w-100" role="group" aria-label="menuEvento">
                                <a class="btn btn-light px-2" target="_blank" href="https://roadrunners.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Calendário</a>
                                <a class="btn btn-light px-2" target="_blank" href="https://openresults.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Resultados</a>
                                <a class="btn btn-dark px-2" href="/bi/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                            </div>
                        <cfelse>
                            <a class="btn btn-dark w-100" href="/bi/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                        </cfif>
                    </div>

                </div>

            </div>

        </cfoutput>

    </cfoutput>

</div>
