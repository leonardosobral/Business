<!--- CONTEUDO --->

<cfset VARIABLES.businessHomeIsAdmin = false/>
<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfif IsBoolean(VARIABLES.businessEffectiveIsAdmin)>
        <cfset VARIABLES.businessHomeIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
    <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(VARIABLES.businessEffectiveIsAdmin))>
        <cfset VARIABLES.businessHomeIsAdmin = true/>
    </cfif>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin")>
    <cfif IsBoolean(qPerfil.is_admin)>
        <cfset VARIABLES.businessHomeIsAdmin = qPerfil.is_admin/>
    <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(qPerfil.is_admin))>
        <cfset VARIABLES.businessHomeIsAdmin = true/>
    </cfif>
</cfif>
<cfif isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive>
    <cfset VARIABLES.businessHomeIsAdmin = false/>
</cfif>

<div class="row g-3">

    <cfif VARIABLES.businessHomeIsAdmin>

        <cfinclude template="includes/estrutura/home_admin_dashboard.cfm"/>

    </cfif>

    <cfif NOT VARIABLES.businessHomeIsAdmin
        AND isDefined("VARIABLES.businessEffectiveAccountIds")
        AND len(trim(VARIABLES.businessEffectiveAccountIds))
        AND VARIABLES.businessEffectiveAccountIds NEQ "0">
        <div class="col-12">
            <cfinclude template="includes/estrutura/home_conta_dashboard.cfm"/>
        </div>
    <cfelseif NOT VARIABLES.businessHomeIsAdmin>
        <div class="col-12">
            <div class="alert alert-warning">
                <strong>Acesso Business em analise.</strong>
                Seu usuario ainda nao esta vinculado a uma conta ativa. Se voce ja solicitou acesso, aguarde a aprovacao da equipe.
                <a class="btn btn-sm btn-warning ms-2" href="/cadastro/">Solicitar acesso da empresa</a>
            </div>
        </div>
    </cfif>


    <cfif VARIABLES.businessHomeIsAdmin>
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
                                    <a class="btn btn-dark px-2" href="/bi/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                                </div>
                            <cfelse>
                                <a class="btn btn-dark w-100" href="/bi/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                            </cfif>
                        </div>

                    </div>

                </div>

            </cfoutput>

        </cfif>

    </cfoutput>
    </cfif>

</div>
