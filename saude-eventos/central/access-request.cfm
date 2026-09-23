<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfif NOT isDefined("VARIABLES.saudeAccessRequestAllowed")
    OR NOT VARIABLES.saudeAccessRequestAllowed
    OR NOT isDefined("REQUEST.businessIdentity.id")
    OR NOT isDefined("VARIABLES.saudeRequestedEventId")
    OR VARIABLES.saudeRequestedEventId LTE 0>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfcontent type="text/plain; charset=utf-8" reset="true"/>
    <cfoutput>Página não encontrada.</cfoutput>
    <cfabort/>
</cfif>

<cfset VARIABLES.saudeAccessSchemaReady = false/>
<cfset VARIABLES.saudeAccessError = ""/>
<cfset VARIABLES.saudeAccessCreated = false/>
<cfset qSaudeAccessEventAccounts = queryNew("id_evento,nome_evento,data_inicial,cidade,estado,id_conta,nome_conta")/>
<cfset qSaudeAccessRequester = queryNew("id,name,email")/>
<cfset qSaudeAccessPending = queryNew("id_solicitacao,id_conta,nome_conta,status,data_criacao")/>

<cftry>
    <cfquery name="qSaudeAccessSchema" datasource="runnerhub">
        SELECT to_regclass('public.tb_evento_saude_acesso_solicitacoes') IS NOT NULL AS ready
    </cfquery>
    <cfset VARIABLES.saudeAccessSchemaReady = isBoolean(qSaudeAccessSchema.ready)
        ? qSaudeAccessSchema.ready
        : listFindNoCase("1,true,yes,on", trim(qSaudeAccessSchema.ready & "")) GT 0/>
    <cfcatch type="any">
        <cfset VARIABLES.saudeAccessSchemaReady = false/>
    </cfcatch>
</cftry>

<cfquery name="qSaudeAccessRequester" datasource="runnerhub">
    SELECT id, name, email
    FROM tb_usuarios
    WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
    LIMIT 1
</cfquery>

<cfquery name="qSaudeAccessEventAccounts" datasource="runnerhub">
    SELECT evt.id_evento,
           evt.nome_evento,
           evt.data_inicial,
           evt.cidade,
           evt.estado,
           cont.id_conta,
           cont.nome_conta
    FROM tb_evento_corridas evt
    INNER JOIN tb_conta_eventos ce
        ON ce.id_evento = evt.id_evento
       AND ce.status = 'ATIVO'::status_conta_evento
    INNER JOIN tb_contas cont
        ON cont.id_conta = ce.id_conta
       AND cont.status = 'ATIVA'::status_conta
    INNER JOIN tb_evento_saude_config cfg
        ON cfg.id_evento = evt.id_evento
       AND cfg.ativo = true
    WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeRequestedEventId#"/>
      AND evt.ativo = true
    ORDER BY cont.nome_conta
</cfquery>

<cfif VARIABLES.saudeAccessSchemaReady>
    <cfquery name="qSaudeAccessPending" datasource="runnerhub">
        SELECT req.id_solicitacao,
               req.id_conta,
               cont.nome_conta,
               req.status,
               req.data_criacao
        FROM tb_evento_saude_acesso_solicitacoes req
        INNER JOIN tb_contas cont ON cont.id_conta = req.id_conta
        WHERE req.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeRequestedEventId#"/>
          AND req.id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
          AND req.status = 'PENDENTE'
        ORDER BY req.data_criacao DESC
        LIMIT 1
    </cfquery>
</cfif>

<cfif VARIABLES.saudeAccessSchemaReady
    AND CGI.request_method EQ "POST"
    AND isDefined("FORM.saude_access_action")
    AND FORM.saude_access_action EQ "request"
    AND NOT qSaudeAccessPending.recordcount>

    <cfset VARIABLES.saudeAccessAccountId = isDefined("FORM.id_conta") ? trim(FORM.id_conta & "") : ""/>
    <cfset VARIABLES.saudeAccessMessage = isDefined("FORM.mensagem") ? left(trim(FORM.mensagem & ""), 1000) : ""/>
    <cfset VARIABLES.saudeAccessCsrf = isDefined("FORM.saude_access_csrf") ? trim(FORM.saude_access_csrf & "") : ""/>

    <cfif NOT len(VARIABLES.saudeAccessCsrf) OR compare(VARIABLES.saudeAccessCsrf, VARIABLES.saudeCsrfToken) NEQ 0>
        <cfset VARIABLES.saudeAccessError = "A sessão do formulário expirou. Atualize a página e tente novamente."/>
    <cfelseif NOT isNumeric(VARIABLES.saudeAccessAccountId)
        OR NOT listFind(valueList(qSaudeAccessEventAccounts.id_conta), int(VARIABLES.saudeAccessAccountId))>
        <cfset VARIABLES.saudeAccessError = "Selecione a conta responsável por esta Central."/>
    <cfelse>
        <cftry>
            <cftransaction>
                <cfquery name="qSaudeAccessInsert" datasource="runnerhub">
                    INSERT INTO tb_evento_saude_acesso_solicitacoes
                    (
                        id_evento,
                        id_conta,
                        id_usuario_solicitante,
                        papel_solicitado,
                        status,
                        mensagem
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeRequestedEventId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeAccessAccountId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>,
                        'MEDICO'::papel_usuario_conta,
                        'PENDENTE',
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.saudeAccessMessage#" null="#NOT len(VARIABLES.saudeAccessMessage)#"/>
                    )
                    ON CONFLICT (id_evento, id_conta, id_usuario_solicitante)
                        WHERE status = 'PENDENTE'
                    DO UPDATE SET mensagem = excluded.mensagem,
                                  data_atualizacao = now()
                    RETURNING id_solicitacao
                </cfquery>

                <!--- A fila fica visível aos Donos da conta e aos Admins Globais. --->
                <cfquery datasource="runnerhub">
                    INSERT INTO tb_notifica
                    (
                        id_usuario,
                        data_publicacao,
                        data_expiracao,
                        conteudo_notifica,
                        link,
                        icone
                    )
                    SELECT DISTINCT recipients.id_usuario::integer,
                           now(),
                           now() + interval '30 days',
                           <cfqueryparam cfsqltype="cf_sql_varchar" value="Nova solicitação de acesso médico à Central de Saúde."/>,
                           <cfqueryparam cfsqltype="cf_sql_varchar" value="/administracao/contas/?tab=solicitacoes-saude##solicitacoes-saude"/>,
                           <cfqueryparam cfsqltype="cf_sql_varchar" value="fa-kit-medical"/>
                    FROM (
                        SELECT cu.id_usuario
                        FROM tb_conta_usuarios cu
                        WHERE cu.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeAccessAccountId#"/>
                          AND cu.status = 'ATIVO'::status_usuario_conta
                          AND cu.papel = 'OWNER'::papel_usuario_conta
                        UNION
                        SELECT usr.id AS id_usuario
                        FROM tb_usuarios usr
                        WHERE coalesce(usr.is_admin, false) = true
                    ) recipients
                    WHERE recipients.id_usuario <> <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
                </cfquery>
            </cftransaction>

            <cfset VARIABLES.saudeAccessCreated = true/>
            <cfquery name="qSaudeAccessPending" datasource="runnerhub">
                SELECT req.id_solicitacao,
                       req.id_conta,
                       cont.nome_conta,
                       req.status,
                       req.data_criacao
                FROM tb_evento_saude_acesso_solicitacoes req
                INNER JOIN tb_contas cont ON cont.id_conta = req.id_conta
                WHERE req.id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qSaudeAccessInsert.id_solicitacao#"/>
            </cfquery>
            <cfcatch type="any">
                <cfset VARIABLES.saudeAccessError = "Não foi possível registrar a solicitação agora. Tente novamente em instantes."/>
                <cflog file="business_saude" type="error" text="medical_access_request event=#VARIABLES.saudeRequestedEventId# user=#REQUEST.businessIdentity.id# message=#left(cfcatch.message & '', 1000)# detail=#left(cfcatch.detail & '', 1800)#"/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="robots" content="noindex,nofollow"/>
    <title>Solicitar acesso médico · Road Runners Business</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css"/>
    <link rel="stylesheet" href="/saude-eventos/central/assets/saude-panel.css?v=20260922-3"/>
</head>
<body>
<main class="saude-access-page">
    <section class="saude-access-card">
        <div class="saude-brand-mark"><i class="fa-solid fa-kit-medical"></i></div>
        <span class="saude-eyebrow">Road Runners Business · Saúde</span>

        <cfif qSaudeAccessEventAccounts.recordcount>
            <h1><cfoutput>#htmlEditFormat(qSaudeAccessEventAccounts.nome_evento[1])#</cfoutput></h1>
            <p class="saude-access-event-meta">
                <cfoutput>#dateFormat(qSaudeAccessEventAccounts.data_inicial[1], "dd/mm/yyyy")#</cfoutput>
                <cfif len(trim(qSaudeAccessEventAccounts.cidade[1] & ""))>
                    · <cfoutput>#htmlEditFormat(qSaudeAccessEventAccounts.cidade[1])#<cfif len(trim(qSaudeAccessEventAccounts.estado[1] & ""))>/#htmlEditFormat(qSaudeAccessEventAccounts.estado[1])#</cfif></cfoutput>
                </cfif>
            </p>

            <cfif qSaudeAccessPending.recordcount>
                <div class="saude-access-state is-pending">
                    <i class="fa-regular fa-clock"></i>
                    <div>
                        <strong><cfif VARIABLES.saudeAccessCreated>Solicitação enviada<cfelse>Acesso aguardando aprovação</cfif></strong>
                        <p>O pedido de perfil <strong>Médico</strong> foi encaminhado ao Dono da conta <cfoutput>#htmlEditFormat(qSaudeAccessPending.nome_conta)#</cfoutput> e aos Admins Globais.</p>
                        <small>Solicitação #<cfoutput>#qSaudeAccessPending.id_solicitacao#</cfoutput> · <cfoutput>#dateTimeFormat(qSaudeAccessPending.data_criacao, "dd/mm/yyyy 'às' HH:nn")#</cfoutput></small>
                    </div>
                </div>
                <p class="saude-access-help">Depois da aprovação, acesse novamente este mesmo link. A Central será aberta automaticamente.</p>
            <cfelseif NOT VARIABLES.saudeAccessSchemaReady>
                <div class="saude-access-state is-error">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                    <div><strong>Configuração pendente</strong><p>O fluxo de solicitação médica ainda não foi configurado no servidor.</p></div>
                </div>
            <cfelse>
                <h2>Acesso médico necessário</h2>
                <p>Você entrou com <strong><cfoutput>#htmlEditFormat(qSaudeAccessRequester.email)#</cfoutput></strong>, mas ainda não possui acesso a esta Central. Envie um pedido para ser incluído como Médico na conta responsável pelo evento.</p>

                <cfif len(VARIABLES.saudeAccessError)>
                    <div class="saude-access-alert"><i class="fa-solid fa-circle-exclamation"></i><cfoutput>#htmlEditFormat(VARIABLES.saudeAccessError)#</cfoutput></div>
                </cfif>

                <form method="post" action="<cfoutput>#htmlEditFormat(VARIABLES.saudeReturnUrl)#</cfoutput>" class="saude-access-form">
                    <input type="hidden" name="saude_access_action" value="request"/>
                    <input type="hidden" name="saude_access_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.saudeCsrfToken)#</cfoutput>"/>
                    <input type="hidden" name="id_evento" value="<cfoutput>#VARIABLES.saudeRequestedEventId#</cfoutput>"/>

                    <cfif qSaudeAccessEventAccounts.recordcount EQ 1>
                        <input type="hidden" name="id_conta" value="<cfoutput>#qSaudeAccessEventAccounts.id_conta#</cfoutput>"/>
                        <div class="saude-access-account">
                            <span>Conta responsável</span>
                            <strong><cfoutput>#htmlEditFormat(qSaudeAccessEventAccounts.nome_conta)#</cfoutput></strong>
                        </div>
                    <cfelse>
                        <label for="saude-access-account">Conta responsável</label>
                        <select id="saude-access-account" name="id_conta" required>
                            <option value="">Selecione</option>
                            <cfoutput query="qSaudeAccessEventAccounts">
                                <option value="#id_conta#">#htmlEditFormat(nome_conta)#</option>
                            </cfoutput>
                        </select>
                    </cfif>

                    <label for="saude-access-message">Mensagem <span>(opcional)</span></label>
                    <textarea id="saude-access-message" name="mensagem" rows="3" maxlength="1000" placeholder="Informe sua função na equipe médica ou outro contexto útil."></textarea>

                    <button type="submit"><i class="fa-solid fa-user-doctor"></i>Solicitar acesso como Médico</button>
                </form>
            </cfif>
        <cfelse>
            <h1>Central indisponível</h1>
            <p>Este evento não possui uma operação de saúde ativa vinculada a uma conta Business.</p>
        </cfif>

        <div class="saude-access-actions">
            <a href="/"><i class="fa-solid fa-arrow-left"></i>Voltar ao Business</a>
            <a href="/logout.cfm" class="is-secondary"><i class="fa-solid fa-right-from-bracket"></i>Entrar com outra conta</a>
        </div>
    </section>
</main>
</body>
</html>
