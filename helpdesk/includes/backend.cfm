<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.helpdeskPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.helpdeskBusinessBaseUrl = "https://" & cgi.http_host/>

<cfif NOT isDefined("COOKIE.id") OR NOT len(trim(COOKIE.id)) OR NOT isNumeric(COOKIE.id)>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfquery name="qPerfil">
    SELECT usr.id,
           usr.name,
           usr.email,
           usr.is_admin,
           usr.is_partner,
           usr.is_dev,
           usr.strava_premium,
           coalesce('/assets/paginas/' || pg.path_imagem, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
           pg.tag,
           pg.tag_prefix,
           pg.id_pagina,
           coalesce(pg.nome, usr.name) as nome
    FROM tb_usuarios usr
    LEFT JOIN tb_paginas_usuarios pgusr ON usr.id = pgusr.id_usuario
    LEFT JOIN tb_paginas pg ON pg.id_pagina = pgusr.id_pagina
    WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    ORDER BY pg.id_pagina NULLS LAST
    LIMIT 1
</cfquery>

<cfif NOT qPerfil.recordcount>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfset VARIABLES.helpdeskIsAdmin = IsBoolean(qPerfil.is_admin) ? qPerfil.is_admin : ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin))/>
<cfset VARIABLES.helpdeskIsPartner = IsBoolean(qPerfil.is_partner) ? qPerfil.is_partner : ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_partner))/>
<cfset VARIABLES.helpdeskIsPremium = IsBoolean(qPerfil.strava_premium) ? qPerfil.strava_premium : ListFindNoCase("true,1,yes,sim", trim(qPerfil.strava_premium))/>
<cfset VARIABLES.helpdeskCanAccess = VARIABLES.helpdeskIsAdmin/>

<cfquery name="qHelpdeskTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tb_helpdesk_setores', 'tb_helpdesk_chamados', 'tb_helpdesk_mensagens')
</cfquery>

<cfset VARIABLES.helpdeskTablesReady = qHelpdeskTables.recordcount EQ 3/>

<cfset qHelpdeskAdmins = QueryNew("id,name")/>
<cfset qHelpdeskSetores = QueryNew("id_setor,nome_setor,descricao_setor,id_usuario_responsavel,nome_responsavel,ativo,created_at,updated_at")/>
<cfset qHelpdeskChamados = QueryNew("id_chamado,protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at,nome_setor,nome_usuario,nome_responsavel")/>
<cfset qHelpdeskTicketEdit = QueryNew("id_chamado,protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at,nome_setor,nome_usuario,email_usuario,nome_responsavel")/>
<cfset qHelpdeskMensagens = QueryNew("id_mensagem,id_chamado,id_usuario,mensagem,created_at,is_admin,nome_usuario,email_usuario")/>
<cfset qHelpdeskSetorEdit = QueryNew("id_setor,nome_setor,descricao_setor,id_usuario_responsavel,ativo")/>
<cfset qHelpdeskStats = QueryNew("total_chamados,total_abertos,total_setores", "integer,integer,integer")/>
<cfset QueryAddRow(qHelpdeskStats, 1)/>
<cfset QuerySetCell(qHelpdeskStats, "total_chamados", 0, 1)/>
<cfset QuerySetCell(qHelpdeskStats, "total_abertos", 0, 1)/>
<cfset QuerySetCell(qHelpdeskStats, "total_setores", 0, 1)/>

<cfscript>
    function helpdeskResolveNotificationDispatchUrl(required string configuredUrl) {
        var resolvedUrl = trim(arguments.configuredUrl & "");

        if (!len(resolvedUrl)) {
            return "https://roadrunners.run/api/notifications/integrations/dispatch.cfm";
        }

        if (findNoCase("/api/notifications/integrations/dispatch.cfm", resolvedUrl)) {
            return resolvedUrl;
        }

        if (findNoCase("/api/push/send.cfm", resolvedUrl)) {
            return replaceNoCase(resolvedUrl, "/api/push/send.cfm", "/api/notifications/integrations/dispatch.cfm", "one");
        }

        if (findNoCase("/api/push/send-notifications.cfm", resolvedUrl)) {
            return replaceNoCase(resolvedUrl, "/api/push/send-notifications.cfm", "/api/notifications/integrations/dispatch.cfm", "one");
        }

        return resolvedUrl;
    }
</cfscript>

<cffunction name="helpdeskDispatchCentralNotification" access="private" returntype="boolean" output="false">
    <cfargument name="payload" type="struct" required="true"/>

    <cfset var dispatchUrl = "https://roadrunners.run/api/notifications/integrations/dispatch.cfm"/>
    <cfset var dispatchUrlAttempts = []/>
    <cfset var dispatchSecret = hash("RoadRunners::handoff::roadrunners.run::v1", "SHA-256")/>
    <cfset var dispatchTimeoutSeconds = 20/>
    <cfset var rawBody = ""/>
    <cfset var timestampHeader = ""/>
    <cfset var signatureHeader = ""/>
    <cfset var httpResult = ""/>
    <cfset var responsePayload = {} />
    <cfset var httpStatusCode = ""/>
    <cfset var httpStatusPrefix = ""/>

    <cfif structKeyExists(APPLICATION, "notificationDispatch") AND isStruct(APPLICATION.notificationDispatch)>
        <cfif structKeyExists(APPLICATION.notificationDispatch, "url") AND len(trim(APPLICATION.notificationDispatch.url))>
            <cfset dispatchUrl = helpdeskResolveNotificationDispatchUrl(APPLICATION.notificationDispatch.url)/>
        </cfif>
        <cfif structKeyExists(APPLICATION.notificationDispatch, "secret") AND len(trim(APPLICATION.notificationDispatch.secret))>
            <cfset dispatchSecret = trim(APPLICATION.notificationDispatch.secret)/>
        </cfif>
        <cfif structKeyExists(APPLICATION.notificationDispatch, "timeoutSeconds") AND val(APPLICATION.notificationDispatch.timeoutSeconds) GT 0>
            <cfset dispatchTimeoutSeconds = int(APPLICATION.notificationDispatch.timeoutSeconds)/>
        </cfif>
    </cfif>

    <cfset rawBody = serializeJSON(arguments.payload)/>
    <cfset timestampHeader = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")/>
    <cfset signatureHeader = lCase(hmac(
        timestampHeader & "." & rawBody,
        dispatchSecret,
        "HmacSHA256"
    ))/>

    <cfset dispatchUrlAttempts = [ dispatchUrl ]/>
    <cfif findNoCase("://roadrunners.run/", dispatchUrl)>
        <cfset arrayAppend(
            dispatchUrlAttempts,
            replaceNoCase(
                dispatchUrl,
                "://roadrunners.run/",
                "://dev.roadrunners.run/",
                "one"
            )
        )/>
    <cfelseif findNoCase("://beta.roadrunners.run/", dispatchUrl)>
        <cfset arrayAppend(
            dispatchUrlAttempts,
            replaceNoCase(
                dispatchUrl,
                "://beta.roadrunners.run/",
                "://dev.roadrunners.run/",
                "one"
            )
        )/>
    </cfif>

    <cftry>
        <cfloop array="#dispatchUrlAttempts#" item="dispatchUrlAttempt">
            <cfhttp
                url="#dispatchUrlAttempt#"
                method="post"
                result="httpResult"
                timeout="#dispatchTimeoutSeconds#"
                throwOnError="false">
                <cfhttpparam type="header" name="Content-Type" value="application/json; charset=utf-8"/>
                <cfhttpparam type="header" name="X-RR-Handoff-Timestamp" value="#timestampHeader#"/>
                <cfhttpparam type="header" name="X-RR-Handoff-Signature" value="#signatureHeader#"/>
                <cfhttpparam type="body" value="#rawBody#"/>
            </cfhttp>

            <cfset httpStatusCode = structKeyExists(httpResult, "statusCode") ? trim(httpResult.statusCode) : ""/>
            <cfset httpStatusPrefix = len(httpStatusCode) GTE 3 ? left(httpStatusCode, 3) : ""/>

            <cfif httpStatusPrefix NEQ "404">
                <cfbreak/>
            </cfif>
        </cfloop>

        <cfif structKeyExists(httpResult, "fileContent")
            AND len(trim(toString(httpResult.fileContent)))
            AND isJSON(toString(httpResult.fileContent))>
            <cfset responsePayload = deserializeJSON(toString(httpResult.fileContent))/>
        </cfif>

        <cfif structKeyExists(responsePayload, "success")
            AND responsePayload.success
            AND structKeyExists(responsePayload, "status")
            AND trim(responsePayload.status & "") EQ "dispatched">
            <cfreturn true/>
        </cfif>
    <cfcatch type="any">
    </cfcatch>
    </cftry>

    <cfreturn false/>
</cffunction>

<cffunction name="helpdeskNotifyResponsibleAdmin" access="private" returntype="boolean" output="false">
    <cfargument name="ticketId" type="numeric" required="true"/>
    <cfargument name="setorId" type="numeric" required="true"/>
    <cfargument name="requesterUserId" type="numeric" required="true"/>
    <cfargument name="businessBaseUrl" type="string" required="true"/>

    <cfset var qHelpdeskNotificationTarget = ""/>
    <cfset var notificationPayload = {} />
    <cfset var notificationPublishedAt = now()/>
    <cfset var notificationExpiresAt = dateAdd("d", 999, notificationPublishedAt)/>

    <cfset qHelpdeskNotificationTarget = queryExecute(
        "
            SELECT setr.id_usuario_responsavel,
                   setr.nome_setor,
                   cham.assunto
            FROM tb_helpdesk_chamados cham
            INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
            INNER JOIN tb_usuarios usr ON usr.id = setr.id_usuario_responsavel
            WHERE cham.id_chamado = :id_chamado
              AND setr.id_setor = :setor_id
              AND setr.id_usuario_responsavel IS NOT NULL
              AND usr.is_admin = true
            LIMIT 1
        ",
        {
            id_chamado = { value = arguments.ticketId, cfsqltype = "cf_sql_integer" },
            setor_id = { value = arguments.setorId, cfsqltype = "cf_sql_integer" }
        },
        { datasource = "runner_dba" }
    )/>

    <cfif NOT qHelpdeskNotificationTarget.recordcount>
        <cfreturn false/>
    </cfif>

    <cfif val(qHelpdeskNotificationTarget.id_usuario_responsavel) EQ arguments.requesterUserId>
        <cfreturn false/>
    </cfif>

    <cfset notificationPayload = {
        origin = "business_helpdesk",
        category = "atendimento_admin",
        conteudo_notifica = left("Novo chamado em " & qHelpdeskNotificationTarget.nome_setor & ": " & qHelpdeskNotificationTarget.assunto, 240),
        icone = "fa-solid fa-headset",
        link = arguments.businessBaseUrl & "/helpdesk/?ticket_id=" & arguments.ticketId,
        data_publicacao = dateTimeFormat(notificationPublishedAt, "yyyy-mm-dd HH:nn:ss"),
        data_expiracao = dateTimeFormat(notificationExpiresAt, "yyyy-mm-dd HH:nn:ss"),
        userIds = [ val(qHelpdeskNotificationTarget.id_usuario_responsavel) ],
        options = {
            sendPush = true
        }
    }/>

    <cfreturn helpdeskDispatchCentralNotification(notificationPayload)/>
</cffunction>

<cffunction name="helpdeskNotifyTicketOwner" access="private" returntype="boolean" output="false">
    <cfargument name="ticketId" type="numeric" required="true"/>
    <cfargument name="actorUserId" type="numeric" required="true"/>

    <cfset var qHelpdeskTicketOwner = ""/>
    <cfset var notificationPayload = {} />
    <cfset var notificationPublishedAt = now()/>
    <cfset var notificationExpiresAt = dateAdd("d", 999, notificationPublishedAt)/>

    <cfset qHelpdeskTicketOwner = queryExecute(
        "
            SELECT cham.id_usuario,
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
    )/>

    <cfif NOT qHelpdeskTicketOwner.recordcount>
        <cfreturn false/>
    </cfif>

    <cfif val(qHelpdeskTicketOwner.id_usuario) EQ arguments.actorUserId>
        <cfreturn false/>
    </cfif>

    <cfset notificationPayload = {
        origin = "business_helpdesk",
        category = "atendimento_usuario",
        conteudo_notifica = left("Atualização no seu chamado em " & qHelpdeskTicketOwner.nome_setor & ": " & qHelpdeskTicketOwner.assunto, 240),
        icone = "fa-solid fa-headset",
        link = "/atendimento/?id_chamado=" & arguments.ticketId,
        data_publicacao = dateTimeFormat(notificationPublishedAt, "yyyy-mm-dd HH:nn:ss"),
        data_expiracao = dateTimeFormat(notificationExpiresAt, "yyyy-mm-dd HH:nn:ss"),
        userIds = [ val(qHelpdeskTicketOwner.id_usuario) ],
        options = {
            sendPush = true
        }
    }/>

    <cfreturn helpdeskDispatchCentralNotification(notificationPayload)/>
</cffunction>

<cfif VARIABLES.helpdeskTablesReady>
    <cfquery name="qHelpdeskAdmins">
        SELECT id, name
        FROM tb_usuarios
        WHERE is_admin = true
        ORDER BY name
    </cfquery>

    <cfquery name="qHelpdeskSetores">
        SELECT setr.id_setor,
               setr.nome_setor,
               coalesce(setr.descricao_setor, '') as descricao_setor,
               setr.id_usuario_responsavel,
               setr.ativo,
               setr.created_at,
               setr.updated_at,
               coalesce(resp.name, '') as nome_responsavel
        FROM tb_helpdesk_setores setr
        LEFT JOIN tb_usuarios resp ON resp.id = setr.id_usuario_responsavel
        ORDER BY setr.ativo DESC, setr.nome_setor
    </cfquery>
</cfif>

<cfif isDefined("FORM.helpdesk_action")
    AND VARIABLES.helpdeskTablesReady
    AND VARIABLES.helpdeskCanAccess>

    <cfif FORM.helpdesk_action EQ "salvar_setor" AND VARIABLES.helpdeskIsAdmin>
        <cfset VARIABLES.helpdeskSetorDescricao = isDefined("FORM.setor_descricao") ? trim(FORM.setor_descricao) : ""/>
        <cfset VARIABLES.helpdeskSetorResponsavelId = isDefined("FORM.setor_responsavel_id") ? trim(FORM.setor_responsavel_id) : ""/>
        <cfset VARIABLES.helpdeskSetorAtivo = isDefined("FORM.setor_ativo") AND FORM.setor_ativo EQ "true"/>

        <cfif isDefined("FORM.setor_id") AND len(trim(FORM.setor_id))>
            <cfquery>
                UPDATE tb_helpdesk_setores
                SET nome_setor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.setor_nome)#"/>,
                    descricao_setor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.helpdeskSetorDescricao#"/>,
                    id_usuario_responsavel = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.helpdeskSetorResponsavelId#" null="#NOT len(trim(VARIABLES.helpdeskSetorResponsavelId))#"/>,
                    ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.helpdeskSetorAtivo#"/>,
                    updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                WHERE id_setor = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.setor_id#"/>
            </cfquery>
        <cfelse>
            <cfquery>
                INSERT INTO tb_helpdesk_setores
                (nome_setor, descricao_setor, id_usuario_responsavel, ativo, created_at, updated_at)
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.setor_nome)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.helpdeskSetorDescricao#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.helpdeskSetorResponsavelId#" null="#NOT len(trim(VARIABLES.helpdeskSetorResponsavelId))#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.helpdeskSetorAtivo#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                )
            </cfquery>
        </cfif>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.helpdeskPage#"/>
    </cfif>

    <cfif FORM.helpdesk_action EQ "novo_ticket">
        <cfif isDefined("FORM.ticket_setor_id")
            AND len(trim(FORM.ticket_setor_id))
            AND isDefined("FORM.ticket_assunto")
            AND len(trim(FORM.ticket_assunto))
            AND isDefined("FORM.ticket_mensagem")
            AND len(trim(FORM.ticket_mensagem))>

            <cfset VARIABLES.helpdeskTicketProtocol = "HD-" & dateFormat(now(), "yyyymmdd") & "-" & right(replace(createUUID(), "-", "", "all"), 8)/>

            <cftransaction>
                <cfquery name="qHelpdeskTicketInsert">
                    INSERT INTO tb_helpdesk_chamados
                    (protocolo, id_usuario, id_setor, assunto, status, created_at, updated_at)
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.helpdeskTicketProtocol#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.ticket_setor_id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.ticket_assunto)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="aberto"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                    )
                    RETURNING id_chamado
                </cfquery>

                <cfif qHelpdeskTicketInsert.recordcount>
                    <cfquery>
                        INSERT INTO tb_helpdesk_mensagens
                        (id_chamado, id_usuario, mensagem, interno, created_at)
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qHelpdeskTicketInsert.id_chamado#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.ticket_mensagem)#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                        )
                    </cfquery>
                </cfif>
            </cftransaction>

            <cfif qHelpdeskTicketInsert.recordcount>
                <cftry>
                    <cfset helpdeskNotifyResponsibleAdmin(
                        qHelpdeskTicketInsert.id_chamado,
                        FORM.ticket_setor_id,
                        qPerfil.id,
                        VARIABLES.helpdeskBusinessBaseUrl
                    )/>
                <cfcatch type="any">
                </cfcatch>
                </cftry>
            </cfif>

            <cfif qHelpdeskTicketInsert.recordcount>
                <cflocation addtoken="false" url="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskTicketInsert.id_chamado#"/>
            </cfif>
        </cfif>
    </cfif>

    <cfif FORM.helpdesk_action EQ "responder_ticket"
        AND isDefined("FORM.ticket_id")
        AND len(trim(FORM.ticket_id))
        AND isDefined("FORM.ticket_mensagem")
        AND len(trim(FORM.ticket_mensagem))>

        <cfquery name="qHelpdeskTicketPermission">
            SELECT id_chamado, id_usuario, id_setor
            FROM tb_helpdesk_chamados
            WHERE id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.ticket_id#"/>
            <cfif NOT VARIABLES.helpdeskIsAdmin>
                AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
            </cfif>
            LIMIT 1
        </cfquery>

        <cfif qHelpdeskTicketPermission.recordcount>
            <cfset VARIABLES.helpdeskTicketNextStatus = ""/>
            <cfif VARIABLES.helpdeskIsAdmin AND isDefined("FORM.ticket_status") AND len(trim(FORM.ticket_status))>
                <cfset VARIABLES.helpdeskTicketNextStatus = trim(FORM.ticket_status)/>
            <cfelseif NOT VARIABLES.helpdeskIsAdmin>
                <cfset VARIABLES.helpdeskTicketNextStatus = "cliente_respondeu"/>
            </cfif>

            <cfquery>
                INSERT INTO tb_helpdesk_mensagens
                (id_chamado, id_usuario, mensagem, interno, created_at)
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.ticket_id#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.ticket_mensagem)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                )
            </cfquery>

            <cfquery>
                UPDATE tb_helpdesk_chamados
                SET
                    <cfif len(trim(VARIABLES.helpdeskTicketNextStatus))>
                        status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.helpdeskTicketNextStatus#"/>,
                    </cfif>
                    <cfif VARIABLES.helpdeskIsAdmin AND isDefined("FORM.ticket_setor_id") AND len(trim(FORM.ticket_setor_id))>
                        id_setor = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.ticket_setor_id#"/>,
                    </cfif>
                    updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                WHERE id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.ticket_id#"/>
            </cfquery>

            <cftry>
                <cfif VARIABLES.helpdeskIsAdmin>
                    <cfset helpdeskNotifyTicketOwner(
                        FORM.ticket_id,
                        qPerfil.id
                    )/>
                <cfelse>
                    <cfset helpdeskNotifyResponsibleAdmin(
                        FORM.ticket_id,
                        qHelpdeskTicketPermission.id_setor,
                        qPerfil.id,
                        VARIABLES.helpdeskBusinessBaseUrl
                    )/>
                </cfif>
            <cfcatch type="any">
            </cfcatch>
            </cftry>
        </cfif>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#FORM.ticket_id#"/>
    </cfif>
</cfif>

<cfif VARIABLES.helpdeskTablesReady
    AND VARIABLES.helpdeskIsAdmin
    AND isDefined("URL.setor_acao")
    AND isDefined("URL.setor_id")
    AND URL.setor_acao EQ "status"
    AND isDefined("URL.setor_status")>

    <cfquery>
        UPDATE tb_helpdesk_setores
        SET ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.setor_status#"/>,
            updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
        WHERE id_setor = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.setor_id#"/>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.helpdeskPage#"/>
</cfif>

<cfif VARIABLES.helpdeskTablesReady AND VARIABLES.helpdeskCanAccess>
    <cfquery name="qHelpdeskChamados">
        SELECT cham.id_chamado,
               cham.protocolo,
               cham.id_usuario,
               cham.id_setor,
               cham.assunto,
               cham.status,
               cham.created_at,
               cham.updated_at,
               usr.name as nome_usuario,
               setr.nome_setor,
               coalesce(resp.name, '') as nome_responsavel
        FROM tb_helpdesk_chamados cham
        INNER JOIN tb_usuarios usr ON usr.id = cham.id_usuario
        INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
        LEFT JOIN tb_usuarios resp ON resp.id = setr.id_usuario_responsavel
        <cfif NOT VARIABLES.helpdeskIsAdmin>
            WHERE cham.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
        </cfif>
        ORDER BY cham.updated_at DESC, cham.id_chamado DESC
    </cfquery>

    <cfquery name="qHelpdeskStats">
        SELECT
            (SELECT count(*) FROM tb_helpdesk_chamados
              <cfif NOT VARIABLES.helpdeskIsAdmin>
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
              </cfif>) as total_chamados,
            (SELECT count(*) FROM tb_helpdesk_chamados
              WHERE status NOT IN ('resolvido', 'fechado')
              <cfif NOT VARIABLES.helpdeskIsAdmin>
                AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
              </cfif>) as total_abertos,
            (SELECT count(*) FROM tb_helpdesk_setores WHERE ativo = true) as total_setores
    </cfquery>

    <cfif isDefined("URL.ticket_id") AND len(trim(URL.ticket_id)) AND isNumeric(URL.ticket_id)>
        <cfquery name="qHelpdeskTicketEdit">
            SELECT cham.id_chamado,
                   cham.protocolo,
                   cham.id_usuario,
                   cham.id_setor,
                   cham.assunto,
                   cham.status,
                   cham.created_at,
                   cham.updated_at,
                   usr.name as nome_usuario,
                   usr.email as email_usuario,
                   setr.nome_setor,
                   coalesce(resp.name, '') as nome_responsavel
            FROM tb_helpdesk_chamados cham
            INNER JOIN tb_usuarios usr ON usr.id = cham.id_usuario
            INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
            LEFT JOIN tb_usuarios resp ON resp.id = setr.id_usuario_responsavel
            WHERE cham.id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.ticket_id#"/>
            <cfif NOT VARIABLES.helpdeskIsAdmin>
                AND cham.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
            </cfif>
            LIMIT 1
        </cfquery>

        <cfif qHelpdeskTicketEdit.recordcount>
            <cfquery name="qHelpdeskMensagens">
                SELECT msg.id_mensagem,
                       msg.id_chamado,
                       msg.id_usuario,
                       msg.mensagem,
                       msg.created_at,
                       usr.is_admin,
                       usr.name as nome_usuario,
                       usr.email as email_usuario
                FROM tb_helpdesk_mensagens msg
                INNER JOIN tb_usuarios usr ON usr.id = msg.id_usuario
                WHERE msg.id_chamado = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.ticket_id#"/>
                ORDER BY msg.created_at ASC, msg.id_mensagem ASC
            </cfquery>
        </cfif>
    </cfif>

    <cfif VARIABLES.helpdeskIsAdmin
        AND isDefined("URL.setor_id")
        AND len(trim(URL.setor_id))
        AND isNumeric(URL.setor_id)>
        <cfquery name="qHelpdeskSetorEdit">
            SELECT id_setor,
                   nome_setor,
                   coalesce(descricao_setor, '') as descricao_setor,
                   id_usuario_responsavel,
                   ativo
            FROM tb_helpdesk_setores
            WHERE id_setor = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.setor_id#"/>
            LIMIT 1
        </cfquery>
    </cfif>
</cfif>
