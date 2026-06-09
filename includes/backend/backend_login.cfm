<!--- DADOS DO USUARIO LOGADO --->

<cfset VARIABLES.roadRunnersBaseUrl = "https://roadrunners.run"/>
<cfset VARIABLES.businessSkipCookieLogin = false/>
<cfset VARIABLES.businessAccountPendingAccess = false/>
<cfset qBusinessPendingRegistration = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,status,data_criacao,nome_responsavel,email_responsavel")/>

<cfif isDefined("URL.logout") AND URL.logout EQ "1">
    <cfset VARIABLES.businessSkipCookieLogin = true/>
</cfif>

<cfif isDefined("URL.action")
    AND URL.action EQ "abrir_notificacao"
    AND isDefined("COOKIE.id")
    AND len(trim(COOKIE.id))
    AND isDefined("URL.id_notifica")
    AND isNumeric(URL.id_notifica)>

    <cfset VARIABLES.businessNotificationRedirectUrl = isDefined("URL.destino") ? trim(URL.destino) : ""/>

    <cfif len(VARIABLES.businessNotificationRedirectUrl)>
        <cfif NOT reFindNoCase("^https?://", VARIABLES.businessNotificationRedirectUrl)>
            <cfif left(VARIABLES.businessNotificationRedirectUrl, 1) EQ "/">
                <cfset VARIABLES.businessNotificationRedirectUrl = VARIABLES.roadRunnersBaseUrl & VARIABLES.businessNotificationRedirectUrl/>
            <cfelse>
                <cfset VARIABLES.businessNotificationRedirectUrl = VARIABLES.roadRunnersBaseUrl & "/" & VARIABLES.businessNotificationRedirectUrl/>
            </cfif>
        </cfif>
    <cfelse>
        <cfset VARIABLES.businessNotificationRedirectUrl = VARIABLES.roadRunnersBaseUrl & "/"/>
    </cfif>

    <cfquery>
        UPDATE tb_notifica
        SET data_leitura = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
        WHERE id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_notifica#"/>
          AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
          AND data_leitura IS NULL
    </cfquery>

    <cflocation addtoken="false" url="#VARIABLES.businessNotificationRedirectUrl#"/>
</cfif>

<cfif NOT VARIABLES.businessSkipCookieLogin AND isDefined("COOKIE.id")>
    <cfquery name="qPerfil">
        SELECT usr.id, usr.name, usr.email, usr.is_admin, usr.is_partner, usr.is_dev, usr.strava_id, usr.aka, usr.fonte_lead,
        coalesce('/assets/paginas/' || pg.path_imagem, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
        pg.tag, pg.tag_prefix, pg.id_pagina, coalesce(pg.nome, usr.name) as nome, pg.verificado, pg.cidade, pg.uf,
        pg.instagram, pg.youtube, pg.tiktok, pg.website, pg.loja, pg.whatsapp, pg.whatsapp_publico, pg.descricao,
        usr.partner_info
        FROM tb_usuarios usr
        LEFT JOIN tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
        LEFT JOIN tb_paginas pg on pg.id_pagina = pgusr.id_pagina
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND (
            is_admin = true
            OR is_partner = true
            OR EXISTS (
                SELECT 1
                FROM tb_conta_usuarios cu
                INNER JOIN tb_contas cont ON cont.id_conta = cu.id_conta
                WHERE cu.id_usuario = usr.id
                  AND cu.status = 'ATIVO'::status_usuario_conta
                  AND cont.status = 'ATIVA'::status_conta
            )
        )
    </cfquery>
    <cfinclude template="business_account_context.cfm"/>
    <cftry>
        <cfquery name="qBusinessPendingRegistration">
            SELECT sol.id_solicitacao,
                   sol.nome_empresa,
                   sol.tipo_prestador,
                   sol.status::text AS status,
                   sol.data_criacao,
                   sol.nome_responsavel,
                   sol.email_responsavel
            FROM tb_usuarios usr
            INNER JOIN tb_conta_cadastro_solicitacoes sol
                ON lower(sol.email_responsavel) = lower(usr.email)
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
              AND coalesce(usr.is_admin, false) = false
              AND NOT EXISTS (
                SELECT 1
                FROM tb_conta_usuarios cu
                INNER JOIN tb_contas cont ON cont.id_conta = cu.id_conta
                WHERE cu.id_usuario = usr.id
                  AND cu.status = 'ATIVO'::status_usuario_conta
                  AND cont.status = 'ATIVA'::status_conta
              )
            ORDER BY sol.data_criacao DESC
            LIMIT 1
        </cfquery>

        <cfif qBusinessPendingRegistration.recordcount>
            <cfset VARIABLES.businessAccountPendingAccess = true/>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.businessAccountPendingAccess = false/>
            <cfset qBusinessPendingRegistration = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,status,data_criacao,nome_responsavel,email_responsavel")/>
        </cfcatch>
    </cftry>

    <cfif VARIABLES.businessAccountPendingAccess AND isDefined("VARIABLES.template")>
        <cflocation addtoken="false" url="/"/>
    </cfif>

    <cfif qPerfil.recordcount>
        <cfif qPerfil.is_admin>
            <cftry>
                <cfquery>
                    INSERT INTO tb_notifica
                    (
                        id_usuario,
                        id_notifica_template,
                        data_publicacao,
                        data_expiracao,
                        link
                    )
                    SELECT setr.id_usuario_responsavel,
                           10,
                           cham.updated_at,
                           cham.updated_at + interval '999 days',
                           <cfqueryparam cfsqltype="cf_sql_varchar" value="https://#cgi.http_host#/helpdesk/?ticket_id="/> || cham.id_chamado
                    FROM tb_helpdesk_chamados cham
                    INNER JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
                    WHERE setr.id_usuario_responsavel = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
                      AND cham.id_usuario <> setr.id_usuario_responsavel
                      AND cham.status IN (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="aberto"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="cliente_respondeu"/>
                      )
                      AND COALESCE(
                        (
                            SELECT MAX(ntf.data_publicacao)
                            FROM tb_notifica ntf
                            WHERE ntf.id_usuario = setr.id_usuario_responsavel
                              AND ntf.id_notifica_template = 10
                              AND ntf.link = <cfqueryparam cfsqltype="cf_sql_varchar" value="https://#cgi.http_host#/helpdesk/?ticket_id="/> || cham.id_chamado
                        ),
                        timestamp '1900-01-01 00:00:00'
                      ) < cham.updated_at
                </cfquery>
            <cfcatch type="any"></cfcatch>
            </cftry>
        </cfif>

        <cfquery name="qNotificacoes">
            SELECT ntf.id_notifica,
                   ntf.id_usuario,
                   ntf.data_publicacao,
                   ntf.data_expiracao,
                   ntf.data_leitura,
                   ntf.id_notifica_template,
                   COALESCE(ntf.link, tpl.link) AS link,
                   COALESCE(ntf.icone, tpl.icone) AS icone,
                   COALESCE(ntf.conteudo_notifica, tpl.conteudo_template) AS conteudo_notifica
            FROM tb_notifica ntf
            LEFT JOIN tb_notifica_template tpl ON ntf.id_notifica_template = tpl.id_notifica_template
            WHERE ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            AND (ntf.data_expiracao IS NULL OR ntf.data_expiracao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>)
            AND ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            ORDER BY ntf.data_publicacao DESC, ntf.id_notifica DESC
        </cfquery>

        <cfquery name="qNotificacoesNaoLidas">
            SELECT ntf.id_notifica
            FROM tb_notifica ntf
            WHERE ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            AND (ntf.data_expiracao IS NULL OR ntf.data_expiracao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>)
            AND ntf.data_leitura IS NULL
            AND ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            LIMIT 1
        </cfquery>

        <cfif isDefined("URL.notificacao")>
            <cfquery>
                UPDATE tb_notifica
                SET data_leitura = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
                AND data_leitura IS NULL
            </cfquery>
        </cfif>
    <cfelse>
        <cfset qNotificacoes = queryNew("id_notifica,id_usuario,data_publicacao,data_expiracao,data_leitura,id_notifica_template,link,icone,conteudo_notifica")/>
        <cfset qNotificacoesNaoLidas = queryNew("id_notifica")/>
    </cfif>
    <cfset qEventosConta = queryNew("id_evento")/>
    <cfset qEventosContaOperacao = queryNew("id_evento")/>
    <cfif NOT (isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin)
        AND isDefined("VARIABLES.businessEffectiveAccountIds")
        AND len(trim(VARIABLES.businessEffectiveAccountIds))
        AND VARIABLES.businessEffectiveAccountIds NEQ "0">
        <cfquery name="qEventosConta">
            SELECT DISTINCT id_evento
            FROM tb_conta_eventos
            WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
              AND status = 'ATIVO'::status_conta_evento
        </cfquery>
    </cfif>
    <cfif NOT (isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin)
        AND isDefined("VARIABLES.businessEffectiveAccountOperatorIds")
        AND len(trim(VARIABLES.businessEffectiveAccountOperatorIds))
        AND VARIABLES.businessEffectiveAccountOperatorIds NEQ "0">
        <cfquery name="qEventosContaOperacao">
            SELECT DISTINCT id_evento
            FROM tb_conta_eventos
            WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountOperatorIds#" list="true"/>)
              AND status = 'ATIVO'::status_conta_evento
        </cfquery>
    </cfif>
    <cfif isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin>
        <cfquery name="qPermissoes">
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.bi_nome, 'Todas as Provas - Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_bi agr on agr.bi_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            UNION
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.agregador_nome, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agregadores agr on agr.agregador_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            UNION
            SELECT perm.*, agr.tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.nome_evento_agregado, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agrega_eventos agr on agr.tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario = 0
            ORDER BY tipo, ordem
        </cfquery>
    <cfelse>
        <cfquery name="qPermissoes">
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.bi_nome, 'Todas as Provas - Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_bi agr on agr.bi_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.businessEffectiveUserIds#" list="true"/>)
            UNION
            SELECT perm.*, '' as tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.agregador_nome, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agregadores agr on agr.agregador_tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.businessEffectiveUserIds#" list="true"/>)
            UNION
            SELECT perm.*, agr.tipo_agregacao, tema.*, agr.ordem,
            COALESCE(agr.nome_evento_agregado, 'Brasil') as titulo
            FROM public.tb_permissoes perm
            inner join tb_agrega_eventos agr on agr.tag = perm.tag
            inner join tb_temas tema on tema.id_tema = agr.id_tema
            WHERE perm.id_usuario IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.businessEffectiveUserIds#" list="true"/>)
            ORDER BY tipo, ordem
        </cfquery>
    </cfif>
<cfelse>
    <cfif isDefined("VARIABLES.template")>
        <cflocation addtoken="false" url="/"/>
    </cfif>
</cfif>


<!--- GOOGLE SIGN OUT --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>


<!--- GOOGLE SIGN IN --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignin" AND isDefined("URL.credential")>

    <cfset id_token = listToArray(URL.credential, ".")/>
    <cfset fb_str = replacelist(id_token[2], "-,_", "+,/")>
    <cfset paddingLength = (4 - (len(fb_str) mod 4)) mod 4>
    <cfset padding = repeatstring("=", paddingLength)>
    <cfset user_data = deserializeJSON(toString(BinaryDecode(fb_str & padding,"base64")))>

    <cfquery>
        INSERT INTO tb_usuarios
        (name, email, imagem_usuario, password,
        verification_key, is_email_verified, optin_usuario)
        VALUES
        (
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(user_data.name)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>,
        <cfif isDefined("user_data.picture")>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.picture#"/>,
        <cfelse>
           null,
        </cfif>
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        )
        ON CONFLICT (email)
        DO UPDATE SET
        data_alteracao  = now(),
        imagem_usuario  = excluded.imagem_usuario,
        verification_key = excluded.verification_key
        RETURNING *;
    </cfquery>

    <cfquery name="qPerfil">
        select * from tb_usuarios
        where email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>
    </cfquery>

    <cfcookie name="id" secure="yes" encodevalue="yes" value="#qPerfil.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="name" secure="yes" encodevalue="yes" value="#qPerfil.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="email" secure="yes" encodevalue="yes" value="#qPerfil.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="imagem_usuario" secure="yes" encodevalue="yes" value="#qPerfil.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfheader name="Set-Cookie" value="rr_logged_out=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=/; Secure; SameSite=Lax"/>
    <cfset VARIABLES.googleSignInRedirect = "/"/>
    <cfif isDefined("URL.redirect") AND len(trim(URL.redirect))>
        <cfset VARIABLES.googleSignInRedirect = URL.redirect/>
    </cfif>
    <cfif findNoCase("logout=1", VARIABLES.googleSignInRedirect)>
        <cfset VARIABLES.googleSignInRedirect = "/"/>
    </cfif>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        ('googlesignin',<cfqueryparam cfsqltype="cf_sql_varchar" value="#qPerfil.id#,#qPerfil.name#,#qPerfil.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
    </cfquery>

    <cflocation addtoken="false" url="#VARIABLES.googleSignInRedirect#"/>

</cfif>


<!--- ATUALIZAR CADASTRO POCKET --->

<cfif isDefined("FORM.action") AND FORM.action EQ "atualizar_cadastro_pocket">
    <cfquery name="qCheckTagPagina">
        SELECT tag FROM tb_paginas
        WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(FORM.tag))#"/>
        AND id_pagina <> <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_pagina#"/>
    </cfquery>
    <cfquery datasource="runner_dba" name="qUpdatePagina">
        UPDATE tb_paginas
        SET
        nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome#"/>,
        tag_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tag_prefix#"/>,
        <cfif NOT qCheckTagPagina.recordcount>
            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(FORM.tag))#"/>,
        </cfif>
        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.cidade#"/>,
        uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.uf#"/>,
        <!---pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.pais#"/>,--->
        descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.descricao#"/>,
        id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_pagina#"/>
    </cfquery>
    <cfquery datasource="runner_dba" name="qUpdateUsuario">
        UPDATE tb_usuarios
        SET
        name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome#"/>,
        <cfif isDefined("FORM.assessoria")>
            assessoria = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.assessoria#"/>,
        </cfif>
        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.cidade#"/>,
        estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.uf#"/>,
        pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.pais#"/>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>
    <cfif qCheckTagPagina.recordcount>
        <cflocation addtoken="false" url="#FORM.template#inscricao/?info=tag&tag=#FORM.tag#"/>
    </cfif>
</cfif>


<!--- CONFIRMAR INSCRICAO BUSINESS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "confirmar_business">
    <cfset VARIABLES.postback = {}/>
    <cfif isDefined("FORM.documento")>
        <cfset VARIABLES.postback["documento"] = FORM.documento/>
    </cfif>
    <cfif isDefined("FORM.celular")>
        <cfset VARIABLES.postback["celular"] = FORM.celular/>
    </cfif>
    <cfif isDefined("FORM.nome_comercial")>
        <cfset VARIABLES.postback["nome_comercial"] = FORM.nome_comercial/>
    </cfif>
    <cfif isDefined("FORM.perfil")>
        <cfset VARIABLES.postback["perfil"] = FORM.perfil/>
    </cfif>
    <cfquery datasource="runner_dba" name="qInsertIncricaoTreino">
        UPDATE tb_usuarios
        set partner_info = <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.postback)#"/>::jsonb
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>
    <cfmail from="Road Runners <contato@roadrunners.run>" to="leonardo.sobral@gmail.com" bcc="contato@roadrunners.run"
            subject="[ROADRUNNERS] Cadastro concluído no Road Runners Business" usetls="true"
            server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
            charset="utf-8" type="html" port="587">
        <cfdump var="#VARIABLES.postback#"/>
    </cfmail>
    <!---cfmail from="Road Runners <contato@roadrunners.run>" to="#FORM.email#" bcc="contato@roadrunners.run"
            subject="[ROADRUNNERS] Cadastro concluído no Road Runners Business" usetls="true"
            server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
            charset="utf-8" type="html" port="587">
        <!---cfinclude template="../../mif/treinao/email_template.cfm"/--->
    </cfmail---->
</cfif>
