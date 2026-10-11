<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/atendimento/"/>
<cfset VARIABLES.routeKey = "support"/>

<!--- PARAMS --->
<cfparam name="URL.tag" default=""/>
<cfparam name="URL.id_chamado" default=""/>
<cfparam name="URL.debug_notif" default=""/>
<cfparam name="URL.debug_push" default=""/>
<cfparam name="URL.debug_push_message" default=""/>
<cfparam name="URL.debug_pending_id" default=""/>
<cfparam name="URL.debug_pending_text" default=""/>
<cfparam name="URL.origem" default=""/>
<cfparam name="FORM.helpdesk_action" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>
<cfset URL.id_chamado = trim(URL.id_chamado)/>
<cfset URL.debug_notif = trim(URL.debug_notif)/>
<cfset URL.debug_push = trim(URL.debug_push)/>
<cfset URL.debug_push_message = trim(URL.debug_push_message)/>
<cfset URL.debug_pending_id = trim(URL.debug_pending_id)/>
<cfset URL.debug_pending_text = trim(URL.debug_pending_text)/>
<cfset URL.origem = lCase(trim(URL.origem))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfset REQUEST.currentRouteKey = VARIABLES.routeKey/>
<cfset VARIABLES.supportBasePath = REQUEST.i18nBuildPath("support")/>
<cfset VARIABLES.supportCorrectionService = new services.EventCorrectionService()/>
<cfset VARIABLES.supportCorrectionContext = VARIABLES.supportCorrectionService.context(URL.origem, structKeyExists(URL,"evento") ? URL.evento : "", VARIABLES.supportBasePath)/>
<cfset VARIABLES.supportStatusParam = isDefined("URL.status") ? trim(URL.status) : ""/>

<cfif NOT Usuario.logado>
    <cfset VARIABLES.supportLoginRedirect = VARIABLES.supportCorrectionContext.path/>
    <cfif URL.origem EQ "creator-verificacao">
        <cfset VARIABLES.supportLoginRedirect &= "?origem=creator-verificacao" & chr(35) & "novo-chamado"/>
    </cfif>
    <cflocation addtoken="false" url="/login/?redirect=#urlEncodedFormat(VARIABLES.supportLoginRedirect)#"/>
</cfif>

<!--- HELP DESK DATA ---> 
<cfset VARIABLES.helpdeskStatus = "">
<cfset VARIABLES.helpdeskMessage = "">
<cfset VARIABLES.helpdeskTablesReady = false>
<cfset VARIABLES.helpdeskActiveCount = 0>
<cfset VARIABLES.helpdeskWaitingCount = 0>
<cfset VARIABLES.helpdeskResolvedCount = 0>
<cfset VARIABLES.helpdeskShowTechnicalError = VARIABLES.devMode OR (isBoolean(Usuario.is_admin) ? Usuario.is_admin : listFindNoCase("1,true,yes,sim,s", trim(Usuario.is_admin & "")) GT 0)>
<cfset VARIABLES.formSetorId = isDefined("FORM.id_setor") ? trim(FORM.id_setor) : "">
<cfset VARIABLES.formAssunto = isDefined("FORM.assunto") ? trim(FORM.assunto) : "">
<cfset VARIABLES.formMensagem = isDefined("FORM.mensagem") ? trim(FORM.mensagem) : "">
<cfif CGI.REQUEST_METHOD EQ "GET" AND URL.origem EQ "creator-verificacao">
    <cfif REQUEST.lang EQ "en">
        <cfset VARIABLES.formAssunto = "Verified Athlete profile evaluation"/>
        <cfset VARIABLES.formMensagem = "I have completed my Road Runners profile and added my active social channels. I would like to request an evaluation for the Verified Athlete badge."/>
    <cfelseif REQUEST.lang EQ "es">
        <cfset VARIABLES.formAssunto = "Evaluación de perfil para Atleta Verificado"/>
        <cfset VARIABLES.formMensagem = "Completé mi perfil en Road Runners y registré mis canales sociales activos. Me gustaría solicitar una evaluación para obtener el sello Atleta Verificado."/>
    <cfelse>
        <cfset VARIABLES.formAssunto = "Avaliação de perfil para Atleta Verificado"/>
        <cfset VARIABLES.formMensagem = "Completei meu perfil no Road Runners e cadastrei meus canais sociais ativos. Gostaria de solicitar a avaliação para receber o selo Atleta Verificado."/>
    </cfif>
</cfif>
<!--- Prepare an editable draft only; the existing POST flow owns ticket submission. --->
<cfif CGI.REQUEST_METHOD EQ "GET" AND VARIABLES.supportCorrectionContext.eventId GT 0>
    <cfquery name="qSupportCorrectionEvent" timeout="5">
        SELECT nome_evento, tag FROM tb_evento_corridas
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.supportCorrectionContext.eventId#"/>
        LIMIT 1
    </cfquery>
    <cfif qSupportCorrectionEvent.recordcount AND len(trim(qSupportCorrectionEvent.tag[1]))>
        <cfset VARIABLES.supportCorrectionRouteParams = duplicate(REQUEST.currentRouteParams)/>
        <cfset REQUEST.currentRouteParams.tag = qSupportCorrectionEvent.tag[1]/>
        <cfset VARIABLES.supportCorrectionEventUrl = REQUEST.i18nBuildAbsoluteUrl("event")/>
        <cfset REQUEST.currentRouteParams = VARIABLES.supportCorrectionRouteParams/>
        <cfset VARIABLES.supportCorrectionDraft = VARIABLES.supportCorrectionService.draft(qSupportCorrectionEvent.nome_evento[1], VARIABLES.supportCorrectionEventUrl, REQUEST.lang)/>
        <cfset VARIABLES.formAssunto = VARIABLES.supportCorrectionDraft.subject/>
        <cfset VARIABLES.formMensagem = VARIABLES.supportCorrectionDraft.message/>
    </cfif>
</cfif>
<cfset qHelpdeskSetores = queryNew("id_setor,nome_setor,descricao_setor")/>
<cfset qHelpdeskChamados = queryNew("id_chamado,protocolo,id_setor,assunto,status,created_at,updated_at,nome_setor")/>
<cfset qChamadoAtual = queryNew("id_chamado,protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at,nome_setor,descricao_setor")/>
<cfset qChamadoMensagens = queryNew("id_mensagem,id_chamado,id_usuario,mensagem,interno,created_at,name,email,is_admin")/>
<cfset VARIABLES.helpdeskBusinessBaseUrl = "https://business.roadrunners.run"/>

<cfscript>
    function helpdeskDispatchCentralNotification(required struct payload) {
        var requestTimestamp = "";
        var requestBody = "";
        var requestSignature = "";
        var dispatchHttpResult = "";
        var dispatchResponse = {};
        var dispatchBaseUrl = "";
        var pushRequested = false;
        var dispatchStatus = "";
        var pushStatus = "";
        var pushMessage = "";

        if (!structKeyExists(APPLICATION, "handoff") OR !isStruct(APPLICATION.handoff) OR !structKeyExists(APPLICATION.handoff, "secret")) {
            return {
                success = false,
                notificationStatus = "handoff_not_configured",
                pushStatus = "",
                pushMessage = "",
                recipientUserId = 0,
                pendingNotificationId = 0,
                pendingNotificationText = ""
            };
        }

        if (structKeyExists(REQUEST, "currentBaseUrl") AND len(trim(REQUEST.currentBaseUrl & ""))) {
            dispatchBaseUrl = trim(REQUEST.currentBaseUrl & "");
        } else if (structKeyExists(CGI, "HTTP_HOST") AND len(trim(CGI.HTTP_HOST))) {
            dispatchBaseUrl = "https://" & trim(CGI.HTTP_HOST);
        } else {
            dispatchBaseUrl = APPLICATION.baseCanonica;
        }

        requestBody = serializeJSON(arguments.payload);
        requestTimestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
        requestSignature = lCase(hmac(
            requestTimestamp & "." & requestBody,
            APPLICATION.handoff.secret,
            "HmacSHA256"
        ));
        pushRequested = structKeyExists(arguments.payload, "options")
            AND isStruct(arguments.payload.options)
            AND structKeyExists(arguments.payload.options, "sendPush")
            AND (
                isBoolean(arguments.payload.options.sendPush)
                    ? arguments.payload.options.sendPush
                    : listFindNoCase("1,true,yes,sim,s,on", trim(arguments.payload.options.sendPush & "")) GT 0
            );

        try {
            dispatchHttpResult = new http(method="post", url=dispatchBaseUrl & "/api/notifications/integrations/dispatch.cfm", timeout=20, throwOnError=false);
            dispatchHttpResult.addParam(type="header", name="Content-Type", value="application/json; charset=utf-8");
            dispatchHttpResult.addParam(type="header", name="X-RR-Handoff-Timestamp", value=requestTimestamp);
            dispatchHttpResult.addParam(type="header", name="X-RR-Handoff-Signature", value=requestSignature);
            dispatchHttpResult.addParam(type="body", value=requestBody);
            dispatchResponse = dispatchHttpResult.send().getPrefix();

            if (structKeyExists(dispatchResponse, "fileContent")
                AND len(trim(toString(dispatchResponse.fileContent)))
                AND isJSON(toString(dispatchResponse.fileContent))) {
                dispatchResponse = deserializeJSON(toString(dispatchResponse.fileContent));
                if (!isStruct(dispatchResponse)
                    OR !structKeyExists(dispatchResponse, "success")
                    OR !dispatchResponse.success
                    OR !structKeyExists(dispatchResponse, "status")
                    OR trim(dispatchResponse.status & "") NEQ "dispatched") {
                    dispatchStatus = isStruct(dispatchResponse) AND structKeyExists(dispatchResponse, "status") ? trim(dispatchResponse.status & "") : "dispatch_failed";
                    return {
                        success = false,
                        notificationStatus = dispatchStatus,
                        pushStatus = "",
                        pushMessage = "",
                        recipientUserId = 0,
                        pendingNotificationId = 0,
                        pendingNotificationText = ""
                    };
                }

                dispatchStatus = trim(dispatchResponse.status & "");

                if (pushRequested) {
                    pushStatus = structKeyExists(dispatchResponse, "push_result")
                        AND isStruct(dispatchResponse.push_result)
                        AND structKeyExists(dispatchResponse.push_result, "status")
                        ? trim(dispatchResponse.push_result.status & "")
                        : "push_unknown";
                    pushMessage = structKeyExists(dispatchResponse, "push_result")
                        AND isStruct(dispatchResponse.push_result)
                        AND structKeyExists(dispatchResponse.push_result, "message")
                        ? trim(dispatchResponse.push_result.message & "")
                        : "";
                    return {
                        success = structKeyExists(dispatchResponse, "push_result")
                            AND isStruct(dispatchResponse.push_result)
                            AND structKeyExists(dispatchResponse.push_result, "success")
                            AND dispatchResponse.push_result.success,
                        notificationStatus = dispatchStatus,
                        pushStatus = pushStatus,
                        pushMessage = pushMessage,
                        recipientUserId = 0,
                        pendingNotificationId = 0,
                        pendingNotificationText = ""
                    };
                }

                return {
                    success = true,
                    notificationStatus = dispatchStatus,
                    pushStatus = "",
                    pushMessage = "",
                    recipientUserId = 0,
                    pendingNotificationId = 0,
                    pendingNotificationText = ""
                };
            }
        } catch (any pushDispatchError) {
            return {
                success = false,
                notificationStatus = "dispatch_exception",
                pushStatus = "dispatch_exception",
                pushMessage = pushDispatchError.message,
                recipientUserId = 0,
                pendingNotificationId = 0,
                pendingNotificationText = ""
            };
        }

        return {
            success = false,
            notificationStatus = "invalid_dispatch_response",
            pushStatus = "",
            pushMessage = "",
            recipientUserId = 0,
            pendingNotificationId = 0,
            pendingNotificationText = ""
        };
    }

    function helpdeskNotifyResponsibleAdmin(required numeric ticketId, required numeric setorId, required numeric requesterUserId, required string businessBaseUrl) {
        var qHelpdeskNotificationTarget = "";
        var qHelpdeskTicketSummary = "";
        var helpdeskNotificationLink = "";
        var helpdeskNotificationContent = "";
        var notificationPayload = {};
        var notificationResult = {};
        var pendingInbox = "";

        try {
            qHelpdeskNotificationTarget = queryExecute(
                "
                    SELECT setr.id_usuario_responsavel,
                           usr.is_admin
                    FROM tb_helpdesk_setores setr
                    INNER JOIN tb_usuarios usr ON usr.id = setr.id_usuario_responsavel
                    WHERE setr.id_setor = :setor_id
                      AND setr.id_usuario_responsavel IS NOT NULL
                      AND usr.is_admin = true
                    LIMIT 1
                ",
                {
                    setor_id = { value = arguments.setorId, cfsqltype = "cf_sql_integer" }
                },
                { datasource = "runner_dba" }
            );

            if (!qHelpdeskNotificationTarget.recordcount) {
                return false;
            }

            if (val(qHelpdeskNotificationTarget.id_usuario_responsavel) EQ arguments.requesterUserId) {
                return false;
            }

            qHelpdeskTicketSummary = queryExecute(
                "
                    SELECT cham.protocolo,
                           cham.assunto,
                           setr.nome_setor
                    FROM tb_helpdesk_chamados cham
                    INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
                    WHERE cham.id_chamado = :id_chamado
                    LIMIT 1
                ",
                {
                    id_chamado = { value = arguments.ticketId, cfsqltype = "cf_sql_integer" }
                },
                { datasource = "runner_dba" }
            );

            if (!qHelpdeskTicketSummary.recordcount) {
                return false;
            }

            helpdeskNotificationLink = arguments.businessBaseUrl & "/helpdesk/?ticket_id=" & arguments.ticketId;
            helpdeskNotificationContent = REQUEST.t("notifications.support.newTicketForAdmin", {
                "sector" = qHelpdeskTicketSummary.nome_setor,
                "subject" = qHelpdeskTicketSummary.assunto
            });
            notificationPayload = {
                origin = "roadrunners_atendimento",
                category = "atendimento_admin",
                conteudo_notifica = left(helpdeskNotificationContent, 240),
                icone = "fa-solid fa-headset",
                link = helpdeskNotificationLink,
                data_publicacao = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
                data_expiracao = dateTimeFormat(dateAdd("d", 999, now()), "yyyy-mm-dd HH:nn:ss"),
                userIds = [ val(qHelpdeskNotificationTarget.id_usuario_responsavel) ],
                options = {
                    sendPush = true,
                    pushCategory = "atendimento",
                    pushUrgency = "high",
                    pushTtlSeconds = 60
                }
            };

            notificationResult = helpdeskDispatchCentralNotification(notificationPayload);
            if (!isStruct(notificationResult)) {
                notificationResult = {
                    success = false,
                    notificationStatus = "invalid_notification_result",
                    pushStatus = "",
                    pushMessage = "",
                    recipientUserId = 0,
                    pendingNotificationId = 0,
                    pendingNotificationText = ""
                };
            }
            notificationResult.recipientUserId = val(qHelpdeskNotificationTarget.id_usuario_responsavel);
            pendingInbox = rrNotificationsGetInbox(notificationResult.recipientUserId, 1);
            if (isQuery(pendingInbox) AND pendingInbox.recordcount) {
                notificationResult.pendingNotificationId = pendingInbox.id_notifica[1];
                notificationResult.pendingNotificationText = left(trim(pendingInbox.conteudo_notifica[1] & ""), 120);
            } else {
                notificationResult.pendingNotificationId = 0;
                notificationResult.pendingNotificationText = "";
            }
            return notificationResult;
        } catch (any helpdeskNotificationError) {
            return {
                success = false,
                notificationStatus = "notification_exception",
                pushStatus = "notification_exception",
                pushMessage = helpdeskNotificationError.message,
                recipientUserId = 0,
                pendingNotificationId = 0,
                pendingNotificationText = ""
            };
        }
    }
</cfscript>

<cfscript>
    function helpdeskStatusLabel(required string statusCode) {
        return REQUEST.t("support.status." & trim(arguments.statusCode));
    }
</cfscript>

<cfif VARIABLES.helpdeskShowTechnicalError AND len(URL.debug_notif)>
    <cfset VARIABLES.helpdeskStatus = URL.debug_push EQ "sent" ? "success" : "error"/>
    <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.debug.label") & ": dispatch=" & URL.debug_notif/>
    <cfif len(URL.debug_push)>
        <cfset VARIABLES.helpdeskMessage &= " | push=" & URL.debug_push/>
    </cfif>
    <cfif len(URL.debug_push_message)>
        <cfset VARIABLES.helpdeskMessage &= " | detalhe=" & URL.debug_push_message/>
    </cfif>
    <cfif len(URL.debug_pending_id)>
        <cfset VARIABLES.helpdeskMessage &= " | pending_id=" & URL.debug_pending_id/>
    </cfif>
    <cfif len(URL.debug_pending_text)>
        <cfset VARIABLES.helpdeskMessage &= " | pending_text=" & URL.debug_pending_text/>
    </cfif>
</cfif>

<cfif NOT len(trim(VARIABLES.helpdeskMessage)) AND len(VARIABLES.supportStatusParam)>
    <cfif VARIABLES.supportStatusParam EQ "criado">
        <cfset VARIABLES.helpdeskStatus = "success"/>
        <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.created")/>
    <cfelseif VARIABLES.supportStatusParam EQ "respondido">
        <cfset VARIABLES.helpdeskStatus = "success"/>
        <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.replied")/>
    </cfif>
</cfif>

<cfquery datasource="runner_dba" name="qHelpdeskTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tb_helpdesk_setores', 'tb_helpdesk_chamados', 'tb_helpdesk_mensagens')
</cfquery>
<cfset VARIABLES.helpdeskTablesReady = qHelpdeskTables.recordcount EQ 3/>

<cfif VARIABLES.helpdeskTablesReady>
    <cfquery datasource="runner_dba" name="qHelpdeskSetores">
        SELECT id_setor,
               nome_setor,
               coalesce(descricao_setor, '') as descricao_setor
        FROM tb_helpdesk_setores
        WHERE ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        ORDER BY nome_setor
    </cfquery>
</cfif>

<cfif CGI.REQUEST_METHOD EQ "POST" AND VARIABLES.helpdeskTablesReady>
    <cfif FORM.helpdesk_action EQ "abrir_chamado">
        <cfset VARIABLES.helpdeskNotificationDebug = {
            success = false,
            notificationStatus = "",
            pushStatus = "",
            pushMessage = ""
        }/>
        <cfset VARIABLES.novoSetor = isDefined("FORM.id_setor") ? trim(FORM.id_setor) : "">
        <cfset VARIABLES.novoAssunto = isDefined("FORM.assunto") ? trim(FORM.assunto) : "">
        <cfset VARIABLES.novaMensagem = isDefined("FORM.mensagem") ? trim(FORM.mensagem) : "">

        <cfif NOT len(VARIABLES.novoSetor) OR NOT isNumeric(VARIABLES.novoSetor)>
            <cfset VARIABLES.helpdeskStatus = "error">
            <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.selectSector")>
        <cfelseif NOT len(VARIABLES.novoAssunto)>
            <cfset VARIABLES.helpdeskStatus = "error">
            <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.enterSubject")>
        <cfelseif NOT len(VARIABLES.novaMensagem)>
            <cfset VARIABLES.helpdeskStatus = "error">
            <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.enterInitialMessage")>
        <cfelse>
            <cfquery datasource="runner_dba" name="qSetorValido">
                SELECT id_setor
                FROM tb_helpdesk_setores
                WHERE id_setor = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.novoSetor#"/>
                  AND ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
                LIMIT 1
            </cfquery>

            <cfif NOT qSetorValido.recordcount>
                <cfset VARIABLES.helpdeskStatus = "error">
                <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.unavailableSector")>
            <cfelse>
                <cfset VARIABLES.helpdeskProtocol = "HD-" & dateFormat(now(), "yyyymmdd") & "-" & right(replace(createUUID(), "-", "", "all"), 8)/>
                <cftry>
                    <cftransaction>
                        <cfquery datasource="runner_dba" name="qNovoChamado">
                            INSERT INTO tb_helpdesk_chamados
                            (protocolo, id_usuario, id_setor, assunto, status, created_at, updated_at)
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.helpdeskProtocol#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.novoSetor#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.novoAssunto#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="aberto"/>,
                                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>,
                                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                            )
                            RETURNING id_chamado
                        </cfquery>

                        <cfquery datasource="runner_dba">
                            INSERT INTO tb_helpdesk_mensagens
                            (id_chamado, id_usuario, mensagem, interno, created_at)
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qNovoChamado.id_chamado#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.novaMensagem#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                            )
                        </cfquery>
                    </cftransaction>

                    <cftry>
                        <cfset VARIABLES.helpdeskNotificationDebug = helpdeskNotifyResponsibleAdmin(
                            qNovoChamado.id_chamado,
                            VARIABLES.novoSetor,
                            Usuario.id,
                            VARIABLES.helpdeskBusinessBaseUrl
                        )/>
                    <cfcatch></cfcatch>
                    </cftry>

                    <cfset VARIABLES.helpdeskRedirectUrl = "#VARIABLES.supportBasePath#?id_chamado=#qNovoChamado.id_chamado#&status=criado"/>
                    <cfif VARIABLES.helpdeskShowTechnicalError AND isStruct(VARIABLES.helpdeskNotificationDebug)>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_notif=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.notificationStatus & "")/>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_push=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.pushStatus & "")/>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_push_message=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.pushMessage & "")/>
                    </cfif>
                    <cflocation addtoken="false" url="#VARIABLES.helpdeskRedirectUrl#"/>
                <cfcatch>
                    <cfset VARIABLES.helpdeskStatus = "error">
                    <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.createError")>
                    <cfif VARIABLES.helpdeskShowTechnicalError>
                        <cfset VARIABLES.helpdeskMessage &= " " & REQUEST.t("support.feedback.technicalDetail") & ": " & cfcatch.message>
                    </cfif>
                </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    </cfif>

    <cfif FORM.helpdesk_action EQ "responder_chamado">
        <cfset VARIABLES.helpdeskNotificationDebug = {
            success = false,
            notificationStatus = "",
            pushStatus = "",
            pushMessage = ""
        }/>
        <cfset VARIABLES.replyChamadoId = isDefined("FORM.id_chamado") ? trim(FORM.id_chamado) : "">
        <cfset VARIABLES.replyMensagem = isDefined("FORM.mensagem") ? trim(FORM.mensagem) : "">

        <cfif NOT len(VARIABLES.replyChamadoId) OR NOT isNumeric(VARIABLES.replyChamadoId)>
            <cfset VARIABLES.helpdeskStatus = "error">
            <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.invalidTicket")>
        <cfelseif NOT len(VARIABLES.replyMensagem)>
            <cfset VARIABLES.helpdeskStatus = "error">
            <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.enterReply")>
        <cfelse>
            <cfquery datasource="runner_dba" name="qChamadoPermissao">
                SELECT id_chamado,
                       id_setor
                FROM tb_helpdesk_chamados
                WHERE id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.replyChamadoId#"/>
                  AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                LIMIT 1
            </cfquery>

            <cfif NOT qChamadoPermissao.recordcount>
                <cfset VARIABLES.helpdeskStatus = "error">
                <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.ticketOwnership")>
            <cfelse>
                <cftry>
                    <cftransaction>
                        <cfquery datasource="runner_dba">
                            INSERT INTO tb_helpdesk_mensagens
                            (id_chamado, id_usuario, mensagem, interno, created_at)
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.replyChamadoId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.replyMensagem#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                            )
                        </cfquery>

                        <cfquery datasource="runner_dba">
                            UPDATE tb_helpdesk_chamados
                            SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="cliente_respondeu"/>,
                                updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                            WHERE id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.replyChamadoId#"/>
                              AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                        </cfquery>
                    </cftransaction>

                    <cftry>
                        <cfset VARIABLES.helpdeskNotificationDebug = helpdeskNotifyResponsibleAdmin(
                            VARIABLES.replyChamadoId,
                            qChamadoPermissao.id_setor,
                            Usuario.id,
                            VARIABLES.helpdeskBusinessBaseUrl
                        )/>
                    <cfcatch></cfcatch>
                    </cftry>

                    <cfset VARIABLES.helpdeskRedirectUrl = "#VARIABLES.supportBasePath#?id_chamado=#VARIABLES.replyChamadoId#&status=respondido"/>
                    <cfif VARIABLES.helpdeskShowTechnicalError AND isStruct(VARIABLES.helpdeskNotificationDebug)>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_notif=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.notificationStatus & "")/>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_push=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.pushStatus & "")/>
                        <cfset VARIABLES.helpdeskRedirectUrl &= "&debug_push_message=" & urlEncodedFormat(VARIABLES.helpdeskNotificationDebug.pushMessage & "")/>
                    </cfif>
                    <cflocation addtoken="false" url="#VARIABLES.helpdeskRedirectUrl#"/>
                <cfcatch>
                    <cfset VARIABLES.helpdeskStatus = "error">
                    <cfset VARIABLES.helpdeskMessage = REQUEST.t("support.feedback.replyError")>
                    <cfif VARIABLES.helpdeskShowTechnicalError>
                        <cfset VARIABLES.helpdeskMessage &= " " & REQUEST.t("support.feedback.technicalDetail") & ": " & cfcatch.message>
                    </cfif>
                </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    </cfif>
</cfif>

<cfif VARIABLES.helpdeskTablesReady>
    <cfquery datasource="runner_dba" name="qHelpdeskChamados">
        SELECT cham.id_chamado,
               cham.protocolo,
               cham.id_setor,
               cham.assunto,
               cham.status,
               cham.created_at,
               cham.updated_at,
               setr.nome_setor
        FROM tb_helpdesk_chamados cham
        INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
        WHERE cham.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        ORDER BY cham.updated_at DESC, cham.id_chamado DESC
    </cfquery>

    <cfloop query="qHelpdeskChamados">
        <cfif qHelpdeskChamados.status EQ "aberto" OR qHelpdeskChamados.status EQ "em_atendimento" OR qHelpdeskChamados.status EQ "cliente_respondeu">
            <cfset VARIABLES.helpdeskActiveCount = VARIABLES.helpdeskActiveCount + 1/>
        </cfif>
        <cfif qHelpdeskChamados.status EQ "aguardando_cliente">
            <cfset VARIABLES.helpdeskWaitingCount = VARIABLES.helpdeskWaitingCount + 1/>
        </cfif>
        <cfif qHelpdeskChamados.status EQ "resolvido" OR qHelpdeskChamados.status EQ "fechado">
            <cfset VARIABLES.helpdeskResolvedCount = VARIABLES.helpdeskResolvedCount + 1/>
        </cfif>
    </cfloop>

    <cfif NOT len(URL.id_chamado) AND qHelpdeskChamados.recordcount>
        <cfset URL.id_chamado = qHelpdeskChamados.id_chamado[1] & ""/>
    </cfif>

    <cfif len(URL.id_chamado) AND isNumeric(URL.id_chamado)>
        <cfquery datasource="runner_dba" name="qChamadoAtual">
            SELECT cham.id_chamado,
                   cham.protocolo,
                   cham.id_usuario,
                   cham.id_setor,
                   cham.assunto,
                   cham.status,
                   cham.created_at,
                   cham.updated_at,
                   setr.nome_setor,
                   coalesce(setr.descricao_setor, '') as descricao_setor
            FROM tb_helpdesk_chamados cham
            INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
            WHERE cham.id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_chamado#"/>
              AND cham.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            LIMIT 1
        </cfquery>

        <cfif qChamadoAtual.recordcount>
            <cfquery datasource="runner_dba" name="qChamadoMensagens">
                SELECT msg.id_mensagem,
                       msg.id_chamado,
                       msg.id_usuario,
                       msg.mensagem,
                       msg.interno,
                       msg.created_at,
                       usr.name,
                       usr.email,
                       usr.is_admin
                FROM tb_helpdesk_mensagens msg
                INNER JOIN tb_usuarios usr ON usr.id = msg.id_usuario
                WHERE msg.id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#qChamadoAtual.id_chamado#"/>
                ORDER BY msg.created_at ASC, msg.id_mensagem ASC
            </cfquery>
            <cfset REQUEST.normalizeDisplayQuery(qChamadoMensagens, "name")/>
        </cfif>
    </cfif>
</cfif>

<!--- META INFO --->
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl("support")/>
<cfset VARIABLES.title = REQUEST.t("support.meta.title")/>
<cfset VARIABLES.description = REQUEST.t("support.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("support.meta.keywords")/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-institutional.min.css?v=20261008seo"/>

<body>

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .support-shell {
            padding: 1rem 0 2rem;
        }

        .support-hero {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background:
                radial-gradient(circle at top left, rgba(250, 177, 32, 0.18), transparent 34%),
                linear-gradient(135deg, #efefef 0%, #ffffff 100%);
            color: #333333;
        }

        .support-kicker {
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            padding: 0.45rem 0.8rem;
            border-radius: 999px;
            background-color: rgba(255, 255, 255, 0.88);
            color: #333333;
            font-size: 0.78rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }

        .support-title {
            font-size: clamp(2rem, 4vw, 3.1rem);
            line-height: 0.98;
            margin: 1rem 0 0.85rem;
            color: #333333;
        }

        .support-subtitle {
            max-width: 760px;
            color: rgba(51, 51, 51, 0.78);
            font-size: 1.02rem;
            line-height: 1.55;
            margin-bottom: 0;
        }

        .support-stats {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .support-stat {
            border-radius: 12px;
            background-color: rgba(255, 255, 255, 0.86);
            border: 1px solid rgba(51, 51, 51, 0.08);
            padding: 0.95rem 1rem;
        }

        .support-stat-kicker {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.74rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 0.3rem;
        }

        .support-stat-value {
            color: #333333;
            font-size: 1.15rem;
            font-weight: 800;
            line-height: 1.2;
        }

        .support-grid {
            display: grid;
            grid-template-columns: minmax(320px, 0.92fr) minmax(0, 1.3fr);
            gap: 0.85rem;
            align-items: start;
        }

        .support-panel {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background-color: #ffffff;
            color: #333333;
        }

        .support-panel-title {
            color: #333333;
            font-size: 1.05rem;
            font-weight: 800;
            margin-bottom: 0.2rem;
        }

        .support-panel-copy {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.92rem;
            margin-bottom: 0;
        }

        .support-alert {
            border-radius: 12px;
            border: 1px solid rgba(51, 51, 51, 0.08);
            padding: 0.9rem 1rem;
            font-size: 0.92rem;
            line-height: 1.5;
        }

        .support-alert.success {
            background-color: rgba(38, 166, 91, 0.1);
            border-color: rgba(38, 166, 91, 0.22);
            color: #1f6d41;
        }

        .support-alert.error {
            background-color: rgba(208, 58, 58, 0.08);
            border-color: rgba(208, 58, 58, 0.16);
            color: #8a2525;
        }

        .support-form-label {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.74rem;
            font-weight: 800;
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .support-form-control,
        .support-form-select {
            border: 1px solid rgba(51, 51, 51, 0.12);
            border-radius: 12px;
            background-color: #ffffff;
            color: #333333;
            box-shadow: none !important;
        }

        .support-form-control:focus,
        .support-form-select:focus {
            border-color: rgba(250, 177, 32, 0.55);
        }

        .support-ticket-list {
            display: grid;
            gap: 0.75rem;
        }

        .support-ticket-link {
            display: block;
            text-decoration: none;
            color: #333333;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 12px;
            background-color: #efefef;
            padding: 0.95rem 1rem;
        }

        .support-ticket-link.is-active,
        .support-ticket-link:hover {
            border-color: rgba(250, 177, 32, 0.65);
            background-color: #fff8e6;
            color: #333333;
        }

        .support-ticket-protocol {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.75rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }

        .support-ticket-subject {
            color: #333333;
            font-size: 0.98rem;
            font-weight: 800;
            line-height: 1.28;
            margin-top: 0.18rem;
        }

        .support-ticket-meta {
            color: rgba(51, 51, 51, 0.7);
            font-size: 0.84rem;
            line-height: 1.45;
            margin-top: 0.45rem;
        }

        .support-status {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.42rem 0.72rem;
            border-radius: 999px;
            border: 1px solid rgba(51, 51, 51, 0.1);
            background-color: #ffffff;
            color: #333333;
            font-size: 0.78rem;
            font-weight: 700;
            line-height: 1;
        }

        .support-status.aberto,
        .support-status.cliente_respondeu {
            background-color: #fff8e6;
            border-color: rgba(250, 177, 32, 0.45);
        }

        .support-status.em_atendimento {
            background-color: rgba(33, 150, 243, 0.08);
            border-color: rgba(33, 150, 243, 0.2);
            color: #1c5e9e;
        }

        .support-status.aguardando_cliente {
            background-color: rgba(0, 188, 212, 0.08);
            border-color: rgba(0, 188, 212, 0.18);
            color: #0b7180;
        }

        .support-status.resolvido {
            background-color: rgba(38, 166, 91, 0.1);
            border-color: rgba(38, 166, 91, 0.22);
            color: #1f6d41;
        }

        .support-status.fechado {
            background-color: rgba(51, 51, 51, 0.08);
            border-color: rgba(51, 51, 51, 0.15);
            color: #555555;
        }

        .support-thread {
            display: grid;
            gap: 0.75rem;
        }

        .support-message {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            padding: 0.9rem 1rem;
            max-width: min(100%, 760px);
        }

        .support-message.user {
            background-color: #fff8e6;
            border-color: rgba(250, 177, 32, 0.32);
            margin-left: auto;
        }

        .support-message.admin {
            background-color: #efefef;
        }

        .support-message-meta {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.76rem;
            font-weight: 700;
            margin-bottom: 0.3rem;
        }

        .support-message-body {
            color: #333333;
            font-size: 0.94rem;
            line-height: 1.6;
            white-space: pre-wrap;
        }

        .support-empty {
            border: 1px dashed rgba(51, 51, 51, 0.16);
            border-radius: 12px;
            background-color: #efefef;
            color: rgba(51, 51, 51, 0.74);
            padding: 1rem;
        }

        @media (max-width: 991.98px) {
            .support-stats,
            .support-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>

    <div class="container">
        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="support-shell">
            <cfinclude template="../includes/estrutura/institutional_nav.cfm"/>
            <section class="support-hero p-4 p-lg-5">
                <span class="support-kicker">
                    <i class="fa-solid fa-headset"></i>
                    <cfoutput>#REQUEST.t("support.hero.kicker")#</cfoutput>
                </span>
                <h1 class="support-title"><cfoutput>#REQUEST.t("support.hero.title")#</cfoutput></h1>
                <p class="support-subtitle">
                    <cfoutput>#REQUEST.t("support.hero.subtitle")#</cfoutput>
                </p>
            </section>

            <cfif NOT VARIABLES.helpdeskTablesReady>
                <section class="support-panel p-4 p-lg-5 mt-3">
                    <div class="support-panel-title"><cfoutput>#REQUEST.t("support.unavailable.title")#</cfoutput></div>
                    <p class="support-panel-copy">
                        <cfoutput>#REQUEST.t("support.unavailable.text")#</cfoutput>
                    </p>
                </section>
            <cfelse>
                <section class="support-panel p-3 p-lg-4 mt-3">
                    <div class="support-stats">
                        <div class="support-stat">
                            <div class="support-stat-kicker"><cfoutput>#REQUEST.t("support.stats.total.kicker")#</cfoutput></div>
                            <div class="support-stat-value"><cfoutput>#REQUEST.t("support.stats.total.value", { "count" = qHelpdeskChamados.recordcount })#</cfoutput></div>
                        </div>
                        <div class="support-stat">
                            <div class="support-stat-kicker"><cfoutput>#REQUEST.t("support.stats.active.kicker")#</cfoutput></div>
                            <div class="support-stat-value"><cfoutput>#REQUEST.t("support.stats.active.value", { "count" = VARIABLES.helpdeskActiveCount })#</cfoutput></div>
                        </div>
                        <div class="support-stat">
                            <div class="support-stat-kicker"><cfoutput>#REQUEST.t("support.stats.resolved.kicker")#</cfoutput></div>
                            <div class="support-stat-value"><cfoutput>#REQUEST.t("support.stats.resolved.value", { "count" = VARIABLES.helpdeskResolvedCount })#</cfoutput></div>
                        </div>
                    </div>
                </section>

                <cfif len(trim(VARIABLES.helpdeskMessage))>
                    <div class="support-alert #len(trim(VARIABLES.helpdeskStatus)) ? VARIABLES.helpdeskStatus : 'error'# mt-3">
                        <cfoutput>#VARIABLES.helpdeskMessage#</cfoutput>
                    </div>
                </cfif>

                <div class="support-grid mt-3">
                    <div class="d-grid gap-3">
                        <section class="support-panel p-4" id="novo-chamado">
                            <div class="support-panel-title"><cfoutput>#REQUEST.t("support.newTicket.title")#</cfoutput></div>
                            <p class="support-panel-copy mb-3"><cfoutput>#REQUEST.t("support.newTicket.copy")#</cfoutput></p>

                            <cfif qHelpdeskSetores.recordcount>
                                <form action="<cfoutput>#VARIABLES.supportBasePath#</cfoutput>" method="post" class="d-grid gap-3">
                                    <input type="hidden" name="helpdesk_action" value="abrir_chamado">
                                    <div>
                                        <label class="support-form-label mb-2" for="helpdeskSetor"><cfoutput>#REQUEST.t("support.newTicket.fields.sector")#</cfoutput></label>
                                        <select class="form-select support-form-select" id="helpdeskSetor" name="id_setor" required>
                                            <option value=""><cfoutput>#REQUEST.t("support.newTicket.fields.sectorPlaceholder")#</cfoutput></option>
                                            <cfoutput query="qHelpdeskSetores">
                                                <option value="#qHelpdeskSetores.id_setor#"<cfif VARIABLES.formSetorId EQ qHelpdeskSetores.id_setor> selected</cfif>>#qHelpdeskSetores.nome_setor#</option>
                                            </cfoutput>
                                        </select>
                                    </div>
                                    <div>
                                        <label class="support-form-label mb-2" for="helpdeskAssunto"><cfoutput>#REQUEST.t("support.newTicket.fields.subject")#</cfoutput></label>
                                        <input class="form-control support-form-control" id="helpdeskAssunto" type="text" name="assunto" maxlength="180" value="<cfoutput>#encodeForHtmlAttribute(VARIABLES.formAssunto)#</cfoutput>" placeholder="<cfoutput>#REQUEST.t('support.newTicket.fields.subjectPlaceholder')#</cfoutput>" required>
                                    </div>
                                    <div>
                                        <label class="support-form-label mb-2" for="helpdeskMensagem"><cfoutput>#REQUEST.t("support.newTicket.fields.message")#</cfoutput></label>
                                        <textarea class="form-control support-form-control" id="helpdeskMensagem" name="mensagem" rows="6" placeholder="<cfoutput>#REQUEST.t('support.newTicket.fields.messagePlaceholder')#</cfoutput>" required><cfoutput>#encodeForHtml(VARIABLES.formMensagem)#</cfoutput></textarea>
                                    </div>
                                    <button type="submit" class="btn btn-primary btn-lg">
                                        <i class="fa-solid fa-paper-plane me-2"></i><cfoutput>#REQUEST.t("support.newTicket.submit")#</cfoutput>
                                    </button>
                                </form>
                            <cfelse>
                                <div class="support-empty"><cfoutput>#REQUEST.t("support.newTicket.emptySectors")#</cfoutput></div>
                            </cfif>
                        </section>

                        <section class="support-panel p-4">
                            <div class="support-panel-title"><cfoutput>#REQUEST.t("support.ticketList.title")#</cfoutput></div>
                            <p class="support-panel-copy mb-3"><cfoutput>#REQUEST.t("support.ticketList.copy")#</cfoutput></p>

                            <cfif qHelpdeskChamados.recordcount>
                                <div class="support-ticket-list">
                                    <cfoutput query="qHelpdeskChamados">
                                        <a href="#VARIABLES.supportBasePath#?id_chamado=#qHelpdeskChamados.id_chamado#" class="support-ticket-link<cfif len(URL.id_chamado) AND URL.id_chamado EQ qHelpdeskChamados.id_chamado> is-active</cfif>">
                                            <div class="d-flex flex-wrap justify-content-between align-items-start gap-2">
                                                <div class="support-ticket-protocol">#qHelpdeskChamados.protocolo#</div>
                                                <div class="support-status #lCase(qHelpdeskChamados.status)#">#helpdeskStatusLabel(qHelpdeskChamados.status)#</div>
                                            </div>
                                            <div class="support-ticket-subject">#qHelpdeskChamados.assunto#</div>
                                            <div class="support-ticket-meta">
                                                #qHelpdeskChamados.nome_setor#<br>
                                                #REQUEST.t("support.ticketList.updatedAt")# #dateTimeFormat(qHelpdeskChamados.updated_at, "dd/mm/yyyy HH:nn")#
                                            </div>
                                        </a>
                                    </cfoutput>
                                </div>
                            <cfelse>
                                <div class="support-empty"><cfoutput>#REQUEST.t("support.ticketList.empty")#</cfoutput></div>
                            </cfif>
                        </section>
                    </div>

                    <section class="support-panel p-4">
                        <cfif qChamadoAtual.recordcount>
                            <cfoutput>
                                <div class="d-flex flex-wrap justify-content-between align-items-start gap-3 mb-3">
                                    <div>
                                        <div class="support-panel-title mb-1">#qChamadoAtual.assunto#</div>
                                        <p class="support-panel-copy mb-0">#REQUEST.t("support.ticketDetail.protocolLabel")# #qChamadoAtual.protocolo# • #qChamadoAtual.nome_setor#</p>
                                    </div>
                                    <div class="support-status #lCase(qChamadoAtual.status)#">#helpdeskStatusLabel(qChamadoAtual.status)#</div>
                                </div>

                                <div class="d-flex flex-wrap gap-2 mb-3">
                                    <div class="support-status">#REQUEST.t("support.ticketDetail.createdAt")# #dateTimeFormat(qChamadoAtual.created_at, "dd/mm/yyyy HH:nn")#</div>
                                    <div class="support-status">#REQUEST.t("support.ticketDetail.updatedAt")# #dateTimeFormat(qChamadoAtual.updated_at, "dd/mm/yyyy HH:nn")#</div>
                                </div>

                                <cfif len(trim(qChamadoAtual.descricao_setor))>
                                    <div class="support-empty mb-3">#qChamadoAtual.descricao_setor#</div>
                                </cfif>
                            </cfoutput>

                            <div class="support-thread mb-3">
                                <cfif qChamadoMensagens.recordcount>
                                    <cfoutput query="qChamadoMensagens">
                                        <cfset VARIABLES.mensagemEhAdmin = isBoolean(qChamadoMensagens.is_admin) ? qChamadoMensagens.is_admin : listFindNoCase("1,true,yes,sim,s", trim(qChamadoMensagens.is_admin & "")) GT 0/>
                                        <cfset VARIABLES.mensagemClasse = VARIABLES.mensagemEhAdmin ? "admin" : "user"/>
                                        <div class="support-message #VARIABLES.mensagemClasse#">
                                            <div class="support-message-meta">
                                                <cfif VARIABLES.mensagemEhAdmin>
                                                    #REQUEST.t("support.thread.team")#
                                                <cfelse>
                                                    #REQUEST.t("support.thread.you")#
                                                </cfif>
                                                • #dateTimeFormat(qChamadoMensagens.created_at, "dd/mm/yyyy HH:nn")#
                                            </div>
                                            <div class="support-message-body">#encodeForHtml(qChamadoMensagens.mensagem)#</div>
                                        </div>
                                    </cfoutput>
                                <cfelse>
                                    <div class="support-empty"><cfoutput>#REQUEST.t("support.thread.empty")#</cfoutput></div>
                                </cfif>
                            </div>

                            <form action="<cfoutput>#VARIABLES.supportBasePath#</cfoutput>" method="post" class="d-grid gap-3">
                                <input type="hidden" name="helpdesk_action" value="responder_chamado">
                                <input type="hidden" name="id_chamado" value="<cfoutput>#qChamadoAtual.id_chamado#</cfoutput>">
                                <div>
                                    <label class="support-form-label mb-2" for="helpdeskResposta"><cfoutput>#REQUEST.t("support.reply.label")#</cfoutput></label>
                                    <textarea class="form-control support-form-control" id="helpdeskResposta" name="mensagem" rows="6" placeholder="<cfoutput>#REQUEST.t('support.reply.placeholder')#</cfoutput>" required></textarea>
                                </div>
                                <button type="submit" class="btn btn-primary btn-lg">
                                    <i class="fa-solid fa-reply me-2"></i><cfoutput>#REQUEST.t("support.reply.submit")#</cfoutput>
                                </button>
                            </form>
                        <cfelse>
                            <div class="support-panel-title mb-2"><cfoutput>#REQUEST.t("support.ticketDetail.emptyTitle")#</cfoutput></div>
                            <p class="support-panel-copy mb-3"><cfoutput>#REQUEST.t("support.ticketDetail.emptyCopy")#</cfoutput></p>
                            <div class="support-empty"><cfoutput>#REQUEST.t("support.ticketDetail.emptyBody")#</cfoutput></div>
                        </cfif>
                    </section>
                </div>
            </cfif>
        </div>

        </main>

    </div>

    <cfinclude template="../includes/estrutura/footer.cfm"/>

    <cfinclude template="../includes/modal/modal_login.cfm"/>
    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>
</body>
</html>
