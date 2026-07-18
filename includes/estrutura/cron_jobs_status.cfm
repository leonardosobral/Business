<cfset VARIABLES.businessCronStatusHasErrors = VARIABLES.businessAdminHomeCronErrors GT 0/>
<cfset VARIABLES.businessCronStatusHasOverdue = VARIABLES.businessAdminHomeCronDue GT 0/>
<cfset VARIABLES.businessCronStatusClass = NOT VARIABLES.businessAdminHomeCronLoaded ? "secondary" : (VARIABLES.businessCronStatusHasErrors ? "danger" : (VARIABLES.businessCronStatusHasOverdue ? "warning" : "success"))/>
<cfset VARIABLES.businessCronStatusLabel = NOT VARIABLES.businessAdminHomeCronLoaded ? "Status indisponível" : (VARIABLES.businessCronStatusHasErrors ? "Ação necessária" : (VARIABLES.businessCronStatusHasOverdue ? "Execuções pendentes" : "Operação em dia"))/>

<section class="col-12 col-xl-6">
    <div class="card shadow-0 overflow-hidden h-100">
        <div class="card-header bg-black bg-opacity-25 d-flex flex-wrap gap-2 justify-content-between align-items-center">
            <div>
                <h5 class="mb-0">Cron Jobs Status</h5>
                <small class="text-muted">Agendamentos e estado das últimas execuções</small>
            </div>
            <div class="d-flex flex-wrap gap-2 align-items-center">
                <a class="btn btn-sm btn-outline-warning" href="/administracao/cron-jobs/">Gerenciar</a>
                <cfoutput>
                    <span class="badge badge-#VARIABLES.businessCronStatusClass#">#VARIABLES.businessCronStatusLabel#</span>
                </cfoutput>
            </div>
        </div>

        <div class="card-body">
            <cfif VARIABLES.businessAdminHomeCronLoaded>
                <div class="row g-2 business-admin-status-metrics">
                    <div class="col-3">
                        <a class="border rounded-4 h-100 d-block text-reset text-decoration-none business-admin-status-metric" href="/administracao/cron-jobs/">
                            <small class="text-muted d-block">Total</small>
                            <strong class="fs-3"><cfoutput>#numberFormat(VARIABLES.businessAdminHomeCronTotal, "9")#</cfoutput></strong>
                        </a>
                    </div>
                    <div class="col-3">
                        <a class="border border-success rounded-4 h-100 d-block text-reset text-decoration-none business-admin-status-metric" href="/administracao/cron-jobs/?status=true">
                            <small class="text-muted d-block">Ativos</small>
                            <strong class="fs-3 text-success"><cfoutput>#numberFormat(VARIABLES.businessAdminHomeCronActive, "9")#</cfoutput></strong>
                        </a>
                    </div>
                    <div class="col-3">
                        <a class="border border-warning rounded-4 h-100 d-block text-reset text-decoration-none business-admin-status-metric" href="/administracao/cron-jobs/?status=vencidos">
                            <small class="text-muted d-block">Vencidos</small>
                            <strong class="fs-3 text-warning"><cfoutput>#numberFormat(VARIABLES.businessAdminHomeCronDue, "9")#</cfoutput></strong>
                        </a>
                    </div>
                    <div class="col-3">
                        <a class="border border-danger rounded-4 h-100 d-block text-reset text-decoration-none business-admin-status-metric" href="/administracao/cron-jobs/?status=erro">
                            <small class="text-muted d-block">Com erro</small>
                            <strong class="fs-3 text-danger"><cfoutput>#numberFormat(VARIABLES.businessAdminHomeCronErrors, "9")#</cfoutput></strong>
                        </a>
                    </div>
                </div>
            <cfelse>
                <div class="alert alert-info mb-0">
                    <cfif VARIABLES.businessAdminHomeHasCronTables>
                        Não foi possível carregar o status dos Cron Jobs agora.
                    <cfelse>
                        A estrutura do Gerenciador de Cron Jobs ainda não está disponível.
                    </cfif>
                </div>
            </cfif>
        </div>
    </div>
</section>
