<section>
    <div class="card shadow-0">
        <div class="card-body">
            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                <div>
                    <div class="text-warning text-uppercase small fw-bold">Resultados</div>
                    <h1 class="h3 mb-1">Importador RaceTag Pro</h1>
                    <p class="text-muted mb-0">Descubra o evento externo, confira o vínculo e execute manualmente a importação.</p>
                </div>
                <a class="btn btn-outline-warning btn-sm align-self-start" href="/administracao/importacoes-resultados/">
                    <i class="fa-solid fa-list-check me-1"></i>Fila de resultados
                </a>
            </div>

            <cfif len(VARIABLES.raceTagNotice)>
                <div class="alert alert-info"><cfoutput>#htmlEditFormat(VARIABLES.raceTagNotice)#</cfoutput></div>
            </cfif>

            <cfif VARIABLES.raceTagSubmissionReady>
                <div class="alert alert-info py-2">
                    <div class="small text-uppercase fw-bold">Submissão da fila</div>
                    <cfoutput>
                        <code>#htmlEditFormat(qRaceTagSubmission.submission_id)#</code>
                        · #htmlEditFormat(qRaceTagSubmission.status_processamento)#
                        · #htmlEditFormat(qRaceTagSubmission.status_publicacao)#
                    </cfoutput>
                </div>
            </cfif>

            <cfinclude template="form.cfm"/>
        </div>
    </div>
</section>
