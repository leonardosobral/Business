<cfscript>
function bannerManagementBuildBaseUrl() {
    var isHttps = false;
    var hostName = "business.roadrunners.run";

    if (structKeyExists(CGI, "https")) {
        isHttps = isBoolean(CGI.https)
            ? CGI.https
            : listFindNoCase("on,1,yes,true", trim(CGI.https)) GT 0;
    }
    if (structKeyExists(CGI, "http_x_forwarded_proto")
        AND listFirst(CGI.http_x_forwarded_proto & "") EQ "https") {
        isHttps = true;
    }
    if (structKeyExists(CGI, "http_host") AND len(trim(CGI.http_host))) {
        hostName = trim(CGI.http_host);
    }
    return (isHttps ? "https://" : "http://") & hostName;
}

function bannerManagementBuildAssetUrl(required string assetPath) {
    var normalizedPath = trim(arguments.assetPath);
    if (reFindNoCase("^https?://", normalizedPath)) return normalizedPath;
    return bannerManagementBuildBaseUrl()
        & (left(normalizedPath, 1) EQ "/" ? "" : "/")
        & normalizedPath;
}

function bannerManagementDestinationUrl(required string destination) {
    var normalizedDestination = trim(arguments.destination);
    if (reFindNoCase("^https://", normalizedDestination)) {
        return normalizedDestination;
    }
    if (left(normalizedDestination, 1) EQ "/") {
        return "https://roadrunners.run" & normalizedDestination;
    }
    return normalizedDestination;
}

function bannerManagementIsUuid(required any value) {
    return reFindNoCase(
        "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
        trim(arguments.value & "")
    ) EQ 1;
}

function bannerManagementStatusLabel(required any statusCode) {
    switch (uCase(trim(arguments.statusCode & ""))) {
        case "DRAFT": return "Rascunho";
        case "ACTIVE": return "Ativo";
        case "PAUSED": return "Pausado";
        case "ENDED": return "Encerrado";
        default: return "Indefinido";
    }
}

function bannerManagementTargetLabel(required any openInNewTab) {
    var normalizedTarget = false;
    if (isBoolean(arguments.openInNewTab)) {
        normalizedTarget = arguments.openInNewTab;
    } else {
        normalizedTarget = listFindNoCase(
            "1,true,yes,on", trim(arguments.openInNewTab & "")
        ) GT 0;
    }
    return normalizedTarget ? "Nova aba" : "Mesma janela";
}

function bannerManagementDirectoryWritable(required string directoryPath) {
    var directoryFile = createObject("java", "java.io.File").init(
        arguments.directoryPath
    );
    return directoryFile.exists() AND directoryFile.canWrite();
}
</cfscript>

<cfparam name="URL.filtro_status" default=""/>
<cfparam name="URL.filtro_canal" default=""/>
<cfparam name="URL.filtro_local" default=""/>
<cfparam name="URL.banner_editar" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.banner_csrf" default=""/>

<cfset VARIABLES.bannerUploadWebRoot = "/portal/banners/assets/"/>
<cfset VARIABLES.bannerUploadDiskPath = expandPath("../banners/assets/")/>
<cfset VARIABLES.bannerPublicBaseUrl = bannerManagementBuildBaseUrl()/>
<cfset VARIABLES.bannerOwnerAccountId = 1/>
<cfset VARIABLES.bannerPlacementKey = "rr-sidebar-banner-300x250"/>
<cfset VARIABLES.bannerManagementAlert = { type = "", message = "" }/>
<cfset VARIABLES.bannerManagementApiReady = false/>
<cfset VARIABLES.bannerManagementTablesReady = false/>
<cfset VARIABLES.bannerManagementResponsiveReady = false/>
<cfset VARIABLES.bannerManagementActorId = 0/>
<cfset VARIABLES.bannerManagementIsAdmin = isDefined("qPerfil")
    AND qPerfil.recordcount AND qPerfil.is_admin/>

<cfif VARIABLES.bannerManagementIsAdmin
    AND isDefined("qPerfil.id") AND isNumeric(qPerfil.id)>
    <cfset VARIABLES.bannerManagementActorId = val(qPerfil.id)/>
</cfif>

<cfif NOT structKeyExists(SESSION, "bannerManagementCanonicalCsrf")
    OR NOT len(trim(SESSION.bannerManagementCanonicalCsrf & ""))>
    <cfset SESSION.bannerManagementCanonicalCsrf = lCase(
        hash(createUUID() & now() & getTickCount(), "SHA-256")
    )/>
</cfif>
<cfset VARIABLES.bannerManagementCsrf = SESSION.bannerManagementCanonicalCsrf/>

<cfset qBannerManagementStats = queryNew(
    "total_banners,total_ativos,total_views,total_clicks",
    "integer,integer,bigint,bigint",
    [{ total_banners = 0, total_ativos = 0, total_views = 0, total_clicks = 0 }]
)/>
<cfset qBannerManagementChannels = queryNew("canal")/>
<cfset qBannerManagementSlots = queryNew("local_layout")/>
<cfset qBannerManagementList = queryNew("id_banner")/>
<cfset qBannerManagementEdit = queryNew("id_banner")/>
<cfset qBannerManagementLegacyRollback = queryNew("legacy_banners,legacy_views,legacy_clicks")/>

<cftry>
    <cfquery name="qBannerManagementReadiness" datasource="runnerhub">
        WITH expected(signature) AS (
            VALUES
                ('ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamp with time zone,timestamp with time zone,integer,integer,integer,bigint)'),
                ('ads.activate_campaign(uuid,integer,text)'),
                ('ads.change_campaign_status(uuid,text,integer,text)')
        ),
        resolved AS (
            SELECT signature,
                   to_regprocedure(signature) AS procedure_oid
            FROM expected
        )
        SELECT count(*)::integer AS expected_count,
               count(procedure_oid)::integer AS resolved_count,
               bool_and(
                   procedure_oid IS NOT NULL
                   AND has_function_privilege(current_user, procedure_oid, 'EXECUTE')
               ) AS ready
        FROM resolved
    </cfquery>
    <cfif qBannerManagementReadiness.recordcount>
        <cfset VARIABLES.bannerManagementReadyFlag = qBannerManagementReadiness.ready & ""/>
        <cfset VARIABLES.bannerManagementApiReady =
            val(qBannerManagementReadiness.expected_count) EQ 3
            AND val(qBannerManagementReadiness.resolved_count) EQ 3
            AND listFindNoCase(
                "1,true,t,yes,on", trim(VARIABLES.bannerManagementReadyFlag)
            ) GT 0/>
    </cfif>
    <cfcatch type="any">
        <cfset VARIABLES.bannerManagementApiReady = false/>
        <cflog file="business_ads_v1" type="error"
            text="banner readiness actor=#VARIABLES.bannerManagementActorId# message=#cfcatch.message#"/>
    </cfcatch>
</cftry>

<cfset VARIABLES.bannerManagementTablesReady = VARIABLES.bannerManagementApiReady/>
<cfset VARIABLES.bannerManagementResponsiveReady = VARIABLES.bannerManagementApiReady/>

<cfif VARIABLES.bannerManagementApiReady AND VARIABLES.bannerManagementIsAdmin
    AND NOT directoryExists(VARIABLES.bannerUploadDiskPath)>
    <cftry>
        <cfdirectory action="create" directory="#VARIABLES.bannerUploadDiskPath#"/>
        <cfcatch type="any">
            <cfif NOT directoryExists(VARIABLES.bannerUploadDiskPath)>
                <cfset VARIABLES.bannerManagementAlert = {
                    type = "danger",
                    message = "Nao foi possivel preparar a pasta de upload dos banners."
                }/>
            </cfif>
        </cfcatch>
    </cftry>
</cfif>

<cfif len(trim(FORM.acao & ""))>
    <cftry>
        <cfif NOT VARIABLES.bannerManagementIsAdmin
            OR VARIABLES.bannerManagementActorId LTE 0>
            <cfthrow type="AdsV1.Validation"
                message="Voce nao tem permissao para gerenciar banners."/>
        </cfif>
        <cfif NOT VARIABLES.bannerManagementApiReady>
            <cfthrow type="AdsV1.Validation"
                message="A API canonica de banners nao esta disponivel."/>
        </cfif>
        <cfif compare(trim(FORM.banner_csrf & ""), VARIABLES.bannerManagementCsrf) NEQ 0>
            <cfthrow type="AdsV1.Validation"
                message="A sessao do formulario expirou. Recarregue a pagina."/>
        </cfif>

        <cfswitch expression="#lCase(trim(FORM.acao & ''))#">
            <cfcase value="salvar_banner">
                <cfset VARIABLES.bannerSaveErrors = []/>
                <cfset VARIABLES.bannerRecordId = structKeyExists(FORM, "banner_id")
                    ? lCase(trim(FORM.banner_id & "")) : ""/>
                <cfset VARIABLES.bannerNome = structKeyExists(FORM, "banner_nome")
                    ? trim(FORM.banner_nome & "") : ""/>
                <cfset VARIABLES.bannerLargura = structKeyExists(FORM, "banner_largura")
                    ? trim(FORM.banner_largura & "") : ""/>
                <cfset VARIABLES.bannerAltura = structKeyExists(FORM, "banner_altura")
                    ? trim(FORM.banner_altura & "") : ""/>
                <cfset VARIABLES.bannerMobileLargura = structKeyExists(FORM, "banner_mobile_largura")
                    ? trim(FORM.banner_mobile_largura & "") : ""/>
                <cfset VARIABLES.bannerMobileAltura = structKeyExists(FORM, "banner_mobile_altura")
                    ? trim(FORM.banner_mobile_altura & "") : ""/>
                <cfset VARIABLES.bannerAltText = structKeyExists(FORM, "banner_alt_text")
                    ? trim(FORM.banner_alt_text & "") : ""/>
                <cfset VARIABLES.bannerLinkDestinoRaw = structKeyExists(FORM, "banner_link_destino")
                    ? trim(FORM.banner_link_destino & "") : ""/>
                <cfset VARIABLES.bannerLinkDestino = bannerManagementDestinationUrl(
                    VARIABLES.bannerLinkDestinoRaw
                )/>
                <cfset VARIABLES.bannerAbrirNovaAba = structKeyExists(FORM, "banner_abrir_nova_aba")
                    AND listFindNoCase(
                        "1,true,yes,on", trim(FORM.banner_abrir_nova_aba & "")
                    ) GT 0/>
                <cfset VARIABLES.bannerPesoExibicao = structKeyExists(FORM, "banner_peso_exibicao")
                    ? trim(FORM.banner_peso_exibicao & "") : "1"/>
                <cfset VARIABLES.bannerPrioridade = structKeyExists(FORM, "banner_prioridade")
                    ? trim(FORM.banner_prioridade & "") : "1"/>
                <cfset VARIABLES.bannerInicioExibicao = structKeyExists(FORM, "banner_inicio_exibicao")
                    ? replace(trim(FORM.banner_inicio_exibicao & ""), "T", " ", "all") : ""/>
                <cfset VARIABLES.bannerFimExibicao = structKeyExists(FORM, "banner_fim_exibicao")
                    ? replace(trim(FORM.banner_fim_exibicao & ""), "T", " ", "all") : ""/>
                <cfset VARIABLES.bannerHasNewDesktopFile = structKeyExists(FORM, "banner_arquivo_desktop")
                    AND len(trim(FORM.banner_arquivo_desktop & ""))/>
                <cfset VARIABLES.bannerHasNewMobileFile = structKeyExists(FORM, "banner_arquivo_mobile")
                    AND len(trim(FORM.banner_arquivo_mobile & ""))/>
                <cfset VARIABLES.bannerDesktopAssetPath = ""/>
                <cfset VARIABLES.bannerMobileAssetPath = ""/>
                <cfset VARIABLES.bannerDesktopUploadedServerFile = ""/>
                <cfset VARIABLES.bannerMobileUploadedServerFile = ""/>

                <cfif len(VARIABLES.bannerRecordId)>
                    <cfif NOT bannerManagementIsUuid(VARIABLES.bannerRecordId)>
                        <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                            "A campanha de banner informada e invalida.")/>
                    <cfelse>
                        <cfquery name="qBannerManagementCurrentAssets" datasource="runnerhub">
                            SELECT creative.image_url AS desktop_image_url,
                                   creative.payload ->> 'mobile_image_url' AS mobile_image_url,
                                   campaign.status
                            FROM ads.campaigns campaign
                            INNER JOIN ads.advertisements advertisement
                              ON advertisement.campaign_id = campaign.campaign_id
                             AND advertisement.account_id = campaign.account_id
                             AND advertisement.billing_model = campaign.billing_model
                             AND advertisement.ad_type = 'BANNER'
                            INNER JOIN ads.creatives creative
                              ON creative.advertisement_id = advertisement.advertisement_id
                             AND creative.campaign_id = campaign.campaign_id
                             AND creative.account_id = campaign.account_id
                             AND creative.billing_model = campaign.billing_model
                             AND creative.ad_type = advertisement.ad_type
                            WHERE campaign.campaign_id = CAST(
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerRecordId#"/> AS uuid
                            )
                              AND campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
                              AND campaign.billing_model = 'HOUSE'
                            LIMIT 1
                        </cfquery>
                        <cfif NOT qBannerManagementCurrentAssets.recordcount>
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "O banner informado para edicao nao foi encontrado.")/>
                        <cfelseif NOT listFind("DRAFT,PAUSED", qBannerManagementCurrentAssets.status)>
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "Pause o banner antes de editar.")/>
                        <cfelse>
                            <cfset VARIABLES.bannerDesktopAssetPath =
                                trim(qBannerManagementCurrentAssets.desktop_image_url & "")/>
                            <cfset VARIABLES.bannerMobileAssetPath =
                                trim(qBannerManagementCurrentAssets.mobile_image_url & "")/>
                        </cfif>
                    </cfif>
                </cfif>

                <cfif len(VARIABLES.bannerNome) LT 3 OR len(VARIABLES.bannerNome) GT 160>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Informe um nome entre 3 e 160 caracteres.")/>
                </cfif>
                <cfif len(VARIABLES.bannerAltText) LT 3 OR len(VARIABLES.bannerAltText) GT 300>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Informe um texto alternativo entre 3 e 300 caracteres.")/>
                </cfif>
                <cfif NOT reFindNoCase("^https://[^[:space:]]+$", VARIABLES.bannerLinkDestino)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Informe um destino HTTPS valido.")/>
                </cfif>
                <cfif NOT isNumeric(VARIABLES.bannerLargura) OR val(VARIABLES.bannerLargura) LTE 0
                    OR NOT isNumeric(VARIABLES.bannerAltura) OR val(VARIABLES.bannerAltura) LTE 0
                    OR NOT isNumeric(VARIABLES.bannerMobileLargura) OR val(VARIABLES.bannerMobileLargura) LTE 0
                    OR NOT isNumeric(VARIABLES.bannerMobileAltura) OR val(VARIABLES.bannerMobileAltura) LTE 0>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Informe dimensoes positivas para desktop e mobile.")/>
                </cfif>
                <cfif NOT isNumeric(VARIABLES.bannerPesoExibicao)
                    OR val(VARIABLES.bannerPesoExibicao) LTE 0
                    OR NOT isNumeric(VARIABLES.bannerPrioridade)
                    OR val(VARIABLES.bannerPrioridade) LTE 0>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Peso e prioridade devem ser positivos.")/>
                </cfif>
                <cfif NOT isDate(VARIABLES.bannerInicioExibicao)
                    OR NOT isDate(VARIABLES.bannerFimExibicao)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Informe o inicio e o fim da exibicao.")/>
                <cfelseif dateCompare(
                    parseDateTime(VARIABLES.bannerFimExibicao),
                    parseDateTime(VARIABLES.bannerInicioExibicao), "s"
                ) LTE 0>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "A data final precisa ser posterior a inicial.")/>
                </cfif>
                <cfif NOT VARIABLES.bannerHasNewDesktopFile
                    AND NOT len(VARIABLES.bannerDesktopAssetPath)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Envie a imagem desktop em JPG, PNG ou GIF.")/>
                </cfif>
                <cfif NOT VARIABLES.bannerHasNewMobileFile
                    AND NOT len(VARIABLES.bannerMobileAssetPath)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "Envie a imagem mobile em JPG, PNG ou GIF.")/>
                </cfif>
                <cfif (VARIABLES.bannerHasNewDesktopFile OR VARIABLES.bannerHasNewMobileFile)
                    AND NOT bannerManagementDirectoryWritable(VARIABLES.bannerUploadDiskPath)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "A pasta de upload dos banners nao esta gravavel.")/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.bannerSaveErrors)
                    AND VARIABLES.bannerHasNewDesktopFile>
                    <cftry>
                        <cffile action="upload" filefield="banner_arquivo_desktop"
                            destination="#VARIABLES.bannerUploadDiskPath#"
                            nameconflict="makeunique" result="bannerDesktopUploadResult"/>
                        <cfset VARIABLES.bannerDesktopUploadedServerFile = bannerDesktopUploadResult.serverFile/>
                        <cfset VARIABLES.bannerDesktopExtension = lCase(bannerDesktopUploadResult.serverFileExt)/>
                        <cfif NOT listFindNoCase("jpg,jpeg,png,gif", VARIABLES.bannerDesktopExtension)>
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "A imagem desktop deve ser JPG, PNG ou GIF.")/>
                        <cfelse>
                            <cfset VARIABLES.bannerDesktopAssetPath = bannerManagementBuildAssetUrl(
                                VARIABLES.bannerUploadWebRoot & bannerDesktopUploadResult.serverFile
                            )/>
                        </cfif>
                        <cfcatch type="any">
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "Nao foi possivel enviar a imagem desktop.")/>
                        </cfcatch>
                    </cftry>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.bannerSaveErrors)
                    AND VARIABLES.bannerHasNewMobileFile>
                    <cftry>
                        <cffile action="upload" filefield="banner_arquivo_mobile"
                            destination="#VARIABLES.bannerUploadDiskPath#"
                            nameconflict="makeunique" result="bannerMobileUploadResult"/>
                        <cfset VARIABLES.bannerMobileUploadedServerFile = bannerMobileUploadResult.serverFile/>
                        <cfset VARIABLES.bannerMobileExtension = lCase(bannerMobileUploadResult.serverFileExt)/>
                        <cfif NOT listFindNoCase("jpg,jpeg,png,gif", VARIABLES.bannerMobileExtension)>
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "A imagem mobile deve ser JPG, PNG ou GIF.")/>
                        <cfelse>
                            <cfset VARIABLES.bannerMobileAssetPath = bannerManagementBuildAssetUrl(
                                VARIABLES.bannerUploadWebRoot & bannerMobileUploadResult.serverFile
                            )/>
                        </cfif>
                        <cfcatch type="any">
                            <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                                "Nao foi possivel enviar a imagem mobile.")/>
                        </cfcatch>
                    </cftry>
                </cfif>

                <cfif NOT reFindNoCase("^https://[^[:space:]]+$", VARIABLES.bannerDesktopAssetPath)
                    OR NOT reFindNoCase("^https://[^[:space:]]+$", VARIABLES.bannerMobileAssetPath)>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors,
                        "As imagens precisam possuir URLs HTTPS publicas.")/>
                </cfif>

                <cfif arrayLen(VARIABLES.bannerSaveErrors)>
                    <cfloop list="#VARIABLES.bannerDesktopUploadedServerFile#,#VARIABLES.bannerMobileUploadedServerFile#"
                        item="bannerUploadedFileToRemove">
                        <cfif len(trim(bannerUploadedFileToRemove))
                            AND fileExists(VARIABLES.bannerUploadDiskPath & bannerUploadedFileToRemove)>
                            <cftry>
                                <cffile action="delete"
                                    file="#VARIABLES.bannerUploadDiskPath##bannerUploadedFileToRemove#"/>
                                <cfcatch type="any"></cfcatch>
                            </cftry>
                        </cfif>
                    </cfloop>
                    <cfthrow type="AdsV1.Validation"
                        message="#arrayToList(VARIABLES.bannerSaveErrors, ' ')#"/>
                </cfif>

                <cfquery name="qBannerManagementSave" datasource="runnerhub">
                    SELECT *
                    FROM ads.save_house_banner_campaign(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerRecordId#" null="#NOT len(VARIABLES.bannerRecordId)#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerPlacementKey#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerNome#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerDesktopAssetPath#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLargura)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerAltura)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerMobileAssetPath#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerMobileLargura)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerMobileAltura)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAltText#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLinkDestino#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.bannerAbrirNovaAba#"/> AS boolean),
                        CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#parseDateTime(VARIABLES.bannerInicioExibicao)#"/> AS timestamp with time zone),
                        CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#parseDateTime(VARIABLES.bannerFimExibicao)#"/> AS timestamp with time zone),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPesoExibicao)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPrioridade)#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.bannerManagementActorId#"/> AS integer),
                        CAST(NULL AS bigint)
                    )
                </cfquery>
                <cflocation addtoken="false" url="/portal/banners/?sucesso=salvo"/>
            </cfcase>

            <cfcase value="alterar_status">
                <cfset VARIABLES.bannerStatusCampaignId = structKeyExists(FORM, "banner_id")
                    ? lCase(trim(FORM.banner_id & "")) : ""/>
                <cfset VARIABLES.bannerTargetStatus = structKeyExists(FORM, "target_status")
                    ? uCase(trim(FORM.target_status & "")) : ""/>
                <cfset VARIABLES.bannerStatusReason = structKeyExists(FORM, "reason")
                    ? trim(FORM.reason & "") : "Alteracao pelo Business"/>
                <cfif NOT bannerManagementIsUuid(VARIABLES.bannerStatusCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Banner invalido."/>
                </cfif>
                <cfif NOT listFind("ACTIVE,PAUSED,ENDED", VARIABLES.bannerTargetStatus)>
                    <cfthrow type="AdsV1.Validation" message="Status invalido."/>
                </cfif>

                <cfquery name="qBannerManagementStatusTarget" datasource="runnerhub">
                    SELECT campaign.campaign_id, campaign.status
                    FROM ads.campaigns campaign
                    WHERE campaign.campaign_id = CAST(
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerStatusCampaignId#"/> AS uuid
                    )
                      AND campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
                      AND campaign.billing_model = 'HOUSE'
                      AND EXISTS (
                          SELECT 1 FROM ads.advertisements advertisement
                          WHERE advertisement.campaign_id = campaign.campaign_id
                            AND advertisement.account_id = campaign.account_id
                            AND advertisement.ad_type = 'BANNER'
                      )
                    LIMIT 1
                </cfquery>
                <cfif NOT qBannerManagementStatusTarget.recordcount>
                    <cfthrow type="AdsV1.Validation"
                        message="Banner nao encontrado para a conta HOUSE."/>
                </cfif>

                <cfif VARIABLES.bannerTargetStatus EQ "ACTIVE">
                    <cfquery name="qBannerManagementActivate" datasource="runnerhub">
                        SELECT (ads.activate_campaign(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerStatusCampaignId#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.bannerManagementActorId#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerStatusReason#"/> AS text)
                        )).status
                    </cfquery>
                <cfelse>
                    <cfquery name="qBannerManagementChangeStatus" datasource="runnerhub">
                        SELECT (ads.change_campaign_status(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerStatusCampaignId#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerTargetStatus#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.bannerManagementActorId#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerStatusReason#"/> AS text)
                        )).status
                    </cfquery>
                </cfif>
                <cflocation addtoken="false" url="/portal/banners/?sucesso=status"/>
            </cfcase>

            <cfdefaultcase>
                <cfthrow type="AdsV1.Validation" message="Acao invalida."/>
            </cfdefaultcase>
        </cfswitch>

        <cfcatch type="AdsV1.Validation">
            <cfset VARIABLES.bannerManagementAlert = {
                type = "danger", message = cfcatch.message
            }/>
        </cfcatch>
        <cfcatch type="any">
            <cfset VARIABLES.bannerManagementAlert = {
                type = "danger",
                message = "Nao foi possivel concluir a operacao do banner."
            }/>
            <cflog file="business_ads_v1" type="error"
                text="banner action=#FORM.acao# actor=#VARIABLES.bannerManagementActorId# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif VARIABLES.bannerManagementApiReady>
    <cftry>
        <cfquery name="qBannerManagementStats" datasource="runnerhub">
            WITH banner_campaigns AS (
                SELECT campaign.campaign_id, campaign.status
                FROM ads.campaigns campaign
                WHERE campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
                  AND campaign.billing_model = 'HOUSE'
                  AND EXISTS (
                      SELECT 1 FROM ads.advertisements advertisement
                      WHERE advertisement.campaign_id = campaign.campaign_id
                        AND advertisement.account_id = campaign.account_id
                        AND advertisement.ad_type = 'BANNER'
                  )
            ),
            banner_metrics AS (
                SELECT metric.campaign_id,
                       sum(metric.viewable_impression_count)::bigint AS views,
                       sum(metric.valid_click_count)::bigint AS clicks
                FROM ads.daily_metrics metric
                JOIN banner_campaigns campaign ON campaign.campaign_id = metric.campaign_id
                GROUP BY metric.campaign_id
            )
            SELECT count(*)::integer AS total_banners,
                   count(*) FILTER (WHERE campaign.status = 'ACTIVE')::integer AS total_ativos,
                   coalesce(sum(metric.views), 0)::bigint AS total_views,
                   coalesce(sum(metric.clicks), 0)::bigint AS total_clicks
            FROM banner_campaigns campaign
            LEFT JOIN banner_metrics metric ON metric.campaign_id = campaign.campaign_id
        </cfquery>

        <cfquery name="qBannerManagementList" datasource="runnerhub">
            SELECT campaign.campaign_id::text AS id_banner,
                   campaign.name AS nome,
                   'roadrunners'::text AS canal,
                   placement.placement_key AS local_layout,
                   'responsive'::text AS tamanho_nome,
                   creative.width AS largura,
                   creative.height AS altura,
                   NULL::text AS formato,
                   creative.alt_text,
                   creative.image_url AS arquivo_path,
                   NULL::text AS arquivo_original,
                   creative.payload ->> 'mobile_image_url' AS arquivo_mobile_path,
                   NULL::text AS arquivo_mobile_original,
                   NULL::text AS formato_mobile,
                   (creative.payload ->> 'mobile_width')::integer AS largura_mobile,
                   (creative.payload ->> 'mobile_height')::integer AS altura_mobile,
                   advertisement.destination_url AS link_destino,
                   CASE WHEN advertisement.destination_url LIKE 'https://roadrunners.run/%'
                       THEN 'interno' ELSE 'externo' END AS link_tipo,
                   coalesce((creative.payload ->> 'open_in_new_tab')::boolean, false) AS abrir_nova_aba,
                   link.weight AS peso_exibicao,
                   link.priority AS prioridade,
                   NULL::integer AS limite_impressoes,
                   NULL::integer AS limite_cliques,
                   NULL::integer AS limite_diario,
                   campaign.starts_at AS inicio_exibicao,
                   campaign.ends_at AS fim_exibicao,
                   campaign.status,
                   NULL::text AS observacoes,
                   coalesce(metrics.views, 0)::bigint AS views,
                   coalesce(metrics.clicks, 0)::bigint AS clicks
            FROM ads.campaigns campaign
            INNER JOIN ads.advertisements advertisement
              ON advertisement.campaign_id = campaign.campaign_id
             AND advertisement.account_id = campaign.account_id
             AND advertisement.billing_model = campaign.billing_model
             AND advertisement.ad_type = 'BANNER'
             AND advertisement.status <> 'ARCHIVED'
            INNER JOIN ads.creatives creative
              ON creative.advertisement_id = advertisement.advertisement_id
             AND creative.campaign_id = campaign.campaign_id
             AND creative.account_id = campaign.account_id
             AND creative.billing_model = campaign.billing_model
             AND creative.ad_type = advertisement.ad_type
             AND creative.status <> 'ARCHIVED'
            INNER JOIN ads.campaign_placements link
              ON link.campaign_id = campaign.campaign_id
             AND link.account_id = campaign.account_id
            INNER JOIN ads.placements placement
              ON placement.placement_id = link.placement_id
             AND placement.placement_key = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerPlacementKey#"/>
            LEFT JOIN LATERAL (
                SELECT sum(metric.viewable_impression_count)::bigint AS views,
                       sum(metric.valid_click_count)::bigint AS clicks
                FROM ads.daily_metrics metric
                WHERE metric.campaign_id = campaign.campaign_id
            ) metrics ON true
            WHERE campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
              AND campaign.billing_model = 'HOUSE'
            <cfif listFindNoCase("DRAFT,ACTIVE,PAUSED,ENDED", trim(URL.filtro_status & ""))>
              AND campaign.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(URL.filtro_status))#"/>
            </cfif>
            ORDER BY CASE campaign.status
                WHEN 'ACTIVE' THEN 0 WHEN 'PAUSED' THEN 1
                WHEN 'DRAFT' THEN 2 ELSE 3 END,
                link.priority DESC, campaign.updated_at DESC
        </cfquery>

        <cfquery name="qBannerManagementEdit" dbtype="query">
            SELECT * FROM qBannerManagementList
            WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_varchar" value="#bannerManagementIsUuid(URL.banner_editar) ? lCase(trim(URL.banner_editar)) : ''#"/>
        </cfquery>

        <cfquery name="qBannerManagementLegacyRollback" datasource="runnerhub">
            SELECT count(DISTINCT banner.id_banner)::integer AS legacy_banners,
                   count(*) FILTER (WHERE log.tipo_evento = 'view')::bigint AS legacy_views,
                   count(*) FILTER (WHERE log.tipo_evento = 'click')::bigint AS legacy_clicks
            FROM ads.tb_portal_banners banner
            LEFT JOIN ads.tb_portal_banners_log log ON log.id_banner = banner.id_banner
            WHERE banner.status <> 4
        </cfquery>

        <cfset qBannerManagementChannels = queryNew(
            "canal", "varchar", [{ canal = "roadrunners" }]
        )/>
        <cfset qBannerManagementSlots = queryNew(
            "local_layout", "varchar", [{ local_layout = VARIABLES.bannerPlacementKey }]
        )/>

        <cfcatch type="any">
            <cfset VARIABLES.bannerManagementTablesReady = false/>
            <cfset VARIABLES.bannerManagementResponsiveReady = false/>
            <cfset VARIABLES.bannerManagementAlert = {
                type = "danger",
                message = "Nao foi possivel carregar os banners canonicos."
            }/>
            <cflog file="business_ads_v1" type="error"
                text="banner read actor=#VARIABLES.bannerManagementActorId# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif structKeyExists(URL, "sucesso") AND len(trim(URL.sucesso & ""))>
    <cfif URL.sucesso EQ "salvo">
        <cfset VARIABLES.bannerManagementAlert = {
            type = "success",
            message = "Banner HOUSE salvo com sucesso. Ative-o quando estiver pronto."
        }/>
    <cfelseif URL.sucesso EQ "status">
        <cfset VARIABLES.bannerManagementAlert = {
            type = "success", message = "Status do banner HOUSE atualizado."
        }/>
    </cfif>
</cfif>
