<cfscript>
    businessLocalConfig = {
        "eventoApiToken" = "COLOQUE_AQUI_O_TOKEN_DA_API_DE_EVENTOS",
        "mandrillUsername" = "COLOQUE_AQUI_O_USUARIO_MANDRILL",
        "mandrillPassword" = "COLOQUE_AQUI_A_SENHA_MANDRILL",
        "pushPublicKey" = "COLOQUE_AQUI_A_CHAVE_PUBLICA_PUSH",
        "pushPrivateKey" = "COLOQUE_AQUI_A_CHAVE_PRIVADA_PUSH",
        "pushSubject" = "mailto:contato@runnerhub.run",
        "notificationDispatchUrl" = "https://roadrunners.run/api/notifications/integrations/dispatch.cfm",
        "notificationDispatchSecret" = "SEGREDO_COMPARTILHADO_COM_ROAD_RUNNERS",
        "notificationDispatchTimeoutSeconds" = 20,
        "uptimeRobotApiKey" = "COLOQUE_AQUI_A_READ_ONLY_API_KEY",
        "uptimeRobotApiUrl" = "https://api.uptimerobot.com/v2/getMonitors",
        "uptimeRobotTimeoutSeconds" = 15,
        "uptimeRobotCacheSeconds" = 120,
        "focoApiToken" = "TOKEN_DA_COMPETITION_API_DA_FOCO",
        "youtubeApiKey" = "CHAVE_DA_YOUTUBE_DATA_API_V3",
        "apiMonitorLogPath" = "/var/log/apache2/api.roadrunners.run-telemetry.log",
        "apiMonitorMaxBytes" = 16777216,
        "apiMonitorCacheSeconds" = 60,
        "cronRunnerToken" = "COLOQUE_AQUI_UM_TOKEN_FORTE_PARA_O_RUNNER",
        "cronDefaultTimeoutSeconds" = 30,
        "cronSecrets" = {
            "road_runners_handoff" = "SEGREDO_COMPARTILHADO_COM_ROAD_RUNNERS",
            "business_internal" = "SEGREDO_INTERNO_DO_BUSINESS",
            "conteudo_internal" = "SEGREDO_INTERNO_DO_BUSINESS",
            "runnerhub_update_feed" = "MESMO_VALOR_DE_RUNNERHUB_UPDATE_FEED_JOB_TOKEN",
            "runnerhub_youtube" = "MESMO_VALOR_DE_RUNNERHUB_YOUTUBE_JOB_TOKEN",
            "business_youtube" = "TOKEN_FORTE_EXCLUSIVO_DO_ENDPOINT_YOUTUBE_NO_BUSINESS",
            "runnerhub_ticketsports" = "MESMO_VALOR_DE_RUNNERHUB_TICKETSPORTS_JOB_TOKEN",
            "runnerhub_foco_eventos" = "TOKEN_DO_ENDPOINT_ORIGINAL_MANTIDO_NO_RUNNERHUB",
            "business_foco_eventos" = "TOKEN_FORTE_EXCLUSIVO_DO_ENDPOINT_FOCO_NO_BUSINESS"
        }
    };
</cfscript>
