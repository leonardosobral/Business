<cfscript>
businessLocalConfig = {
    "uptimeRobotApiKey" = "COLOQUE_AQUI_A_READ_ONLY_API_KEY",
    "uptimeRobotApiUrl" = "https://api.uptimerobot.com/v2/getMonitors",
    "uptimeRobotTimeoutSeconds" = 15,
    "uptimeRobotCacheSeconds" = 120,
    "cronRunnerToken" = "COLOQUE_AQUI_UM_TOKEN_FORTE_PARA_O_RUNNER",
    "cronDefaultTimeoutSeconds" = 30,
    "cronSecrets" = {
        "road_runners_handoff" = "SEGREDO_COMPARTILHADO_COM_ROAD_RUNNERS",
        "business_internal" = "SEGREDO_INTERNO_DO_BUSINESS",
        "runnerhub_update_feed" = "MESMO_VALOR_DE_RUNNERHUB_UPDATE_FEED_JOB_TOKEN",
        "runnerhub_youtube" = "MESMO_VALOR_DE_RUNNERHUB_YOUTUBE_JOB_TOKEN",
        "runnerhub_ticketsports" = "MESMO_VALOR_DE_RUNNERHUB_TICKETSPORTS_JOB_TOKEN",
        "runnerhub_foco_eventos" = "MESMO_VALOR_DO_JOBTOKEN_EM_FOCO.LOCAL.CFM"
    }
};
</cfscript>
