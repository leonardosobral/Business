<cfscript>
VARIABLES.descriptionCanAdmin = isDefined("qPerfil") AND qPerfil.recordCount
    AND !isNull(qPerfil.is_admin) AND (isBoolean(qPerfil.is_admin)
        ? qPerfil.is_admin : listFindNoCase("true,t,1,yes,sim",trim(qPerfil.is_admin & "")) GT 0);
if (!VARIABLES.descriptionCanAdmin) {
    cfheader(statuscode=403,statustext="Forbidden");
    writeOutput("Acesso restrito a administradores.");
    abort;
}
VARIABLES.descriptionStatusReady = false;
VARIABLES.descriptionStatusError = "";
VARIABLES.descriptionStatusRows = [];
VARIABLES.descriptionTotalPending = 0;
VARIABLES.descriptionTotalReview = 0;
VARIABLES.descriptionJob = queryNew("id_cron_job,nome,ativo,interval_minutes,last_run_at,next_run_at,last_status");
try {
    VARIABLES.descriptionSchema = queryExecute("SELECT to_regclass('public.tb_evento_descricao_translations') IS NOT NULL
        AND to_regclass('public.tb_evento_descricao_rewrites') IS NOT NULL
        AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='public'
            AND table_name='tb_evento_corridas' AND column_name IN ('descricao_en','descricao_es','descricao_traducoes_meta'))=3 AS ready",[],{datasource="runner_dba"});
    VARIABLES.descriptionStatusReady = VARIABLES.descriptionSchema.ready[1];
    if (VARIABLES.descriptionStatusReady) {
        include "../../../api/eventos/jobs/queue.cfm";
        VARIABLES.descriptionCounts = queryExecute(eventDescriptionQueueSql() & "
            SELECT language,queue_status,count(*) AS total FROM work GROUP BY language,queue_status", {
                event_id={value=0,cfsqltype="cf_sql_integer"},
                language={value="auto",cfsqltype="cf_sql_varchar"}
            },{datasource="runner_dba"});
        for (VARIABLES.descriptionLocale in [{code="pt-BR",label="Português"},{code="en",label="Inglês"},{code="es",label="Espanhol"}]) {
            VARIABLES.descriptionRow={language=VARIABLES.descriptionLocale.label,ready=0,waiting=0,review=0,running=0};
            for (VARIABLES.descriptionCount in VARIABLES.descriptionCounts) {
                if (VARIABLES.descriptionCount.language NEQ VARIABLES.descriptionLocale.code) continue;
                switch (VARIABLES.descriptionCount.queue_status) {
                    case "ready": VARIABLES.descriptionRow.ready += VARIABLES.descriptionCount.total; break;
                    case "waiting_retry": VARIABLES.descriptionRow.waiting += VARIABLES.descriptionCount.total; break;
                    case "running": VARIABLES.descriptionRow.running += VARIABLES.descriptionCount.total; break;
                    default: VARIABLES.descriptionRow.review += VARIABLES.descriptionCount.total;
                }
            }
            VARIABLES.descriptionTotalPending += VARIABLES.descriptionRow.ready + VARIABLES.descriptionRow.waiting;
            VARIABLES.descriptionTotalReview += VARIABLES.descriptionRow.review;
            arrayAppend(VARIABLES.descriptionStatusRows,VARIABLES.descriptionRow);
        }
        VARIABLES.descriptionJob=queryExecute("SELECT id_cron_job,nome,ativo,interval_minutes,last_run_at,next_run_at,last_status
            FROM public.tb_cron_jobs WHERE endpoint_url=:endpoint ORDER BY id_cron_job LIMIT 1",{
                endpoint={value="https://business.roadrunners.run/api/event-description-rewrite.cfm",cfsqltype="cf_sql_varchar"}
            },{datasource="runner_dba"});
    }
} catch (any unavailableStatus) {
    VARIABLES.descriptionStatusReady=false;
    VARIABLES.descriptionStatusError="Não foi possível consultar a fila agora. Tente atualizar a página.";
}
</cfscript>
