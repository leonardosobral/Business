<!--- SOLICITACOES DE VINCULO ENTRE CONTA E EVENTO --->

<cfparam name="URL.evento_referencia" default=""/>
<cfparam name="URL.id_conta_solicitacao" default=""/>
<cfparam name="URL.solicitacao" default=""/>
<cfparam name="FORM.mensagem" default=""/>
<cfparam name="FORM.observacao_revisor" default=""/>

<cfset VARIABLES.eventoSolicitacaoErrorMessage = ""/>
<cfset VARIABLES.eventoSolicitacaoNoticeMessage = ""/>
<cfset VARIABLES.eventoSolicitacaoTablesReady = false/>
<cfset VARIABLES.eventoSolicitacaoCanRequest = false/>
<cfset VARIABLES.eventoSolicitacaoCanReview = false/>
<cfset VARIABLES.eventoSolicitacaoSelectedAccountId = ""/>
<cfset VARIABLES.eventoSolicitacaoReferencia = trim(URL.evento_referencia)/>
<cfset VARIABLES.eventoSolicitacaoTag = ""/>
<cfset VARIABLES.eventoSolicitacaoSearchTerm = ""/>
<cfset VARIABLES.eventoSolicitacaoEffectiveAccountIds = "0"/>
<cfset VARIABLES.eventoSolicitacaoUsingSimulatedAccount = false/>
<cfset VARIABLES.eventoMinhasSolicitacoesPendentes = 0/>
<cfset VARIABLES.eventoMinhasSolicitacoesHistorico = 0/>

<cfset qEventoSolicitacaoContas = QueryNew("id_conta,nome_conta")/>
<cfset qEventoSolicitacaoBusca = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,status_vinculo,status_solicitacao")/>
<cfset qEventoSolicitacoesPendentes = QueryNew("id_solicitacao,id_conta,id_evento,id_usuario_solicitante,url_informada,tag_informada,mensagem,status,data_criacao,nome_conta,nome_evento,tag,data_inicial,data_final,cidade,estado,usuario_solicitante,email_solicitante")/>
<cfset qEventoMinhasSolicitacoes = QueryNew("id_solicitacao,id_conta,id_evento,status,data_criacao,data_revisao,nome_conta,nome_evento,tag,cidade,estado,observacao_revisor")/>

<cfif isDefined("VARIABLES.businessRealIsAdmin")>
    <cfset VARIABLES.eventoSolicitacaoCanReview = VARIABLES.businessRealIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.eventoSolicitacaoCanReview = true/>
</cfif>

<cfif isDefined("VARIABLES.businessEffectiveAccountIds")
    AND len(trim(VARIABLES.businessEffectiveAccountIds))
    AND VARIABLES.businessEffectiveAccountIds NEQ "0">
    <cfset VARIABLES.eventoSolicitacaoEffectiveAccountIds = VARIABLES.businessEffectiveAccountIds/>
</cfif>

<cfif isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive>
    <cfset VARIABLES.eventoSolicitacaoUsingSimulatedAccount = true/>
</cfif>

<cfif isDefined("SESSION.businessSimulatedAccountId")
    AND len(trim(SESSION.businessSimulatedAccountId))
    AND isNumeric(SESSION.businessSimulatedAccountId)
    AND val(SESSION.businessSimulatedAccountId) GT 0>
    <cfset VARIABLES.eventoSolicitacaoUsingSimulatedAccount = true/>
    <cfif VARIABLES.eventoSolicitacaoEffectiveAccountIds EQ "0">
        <cfset VARIABLES.eventoSolicitacaoEffectiveAccountIds = trim(SESSION.businessSimulatedAccountId)/>
    </cfif>
</cfif>

<cfif VARIABLES.eventoSolicitacaoEffectiveAccountIds NEQ "0"
    AND (
        NOT (isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin)
        OR VARIABLES.eventoSolicitacaoUsingSimulatedAccount
    )>
    <cfset VARIABLES.eventoSolicitacaoCanRequest = true/>
</cfif>

<cfif isDefined("FORM.evento_solicitacao_action")>
    <cfif isDefined("FORM.evento_referencia")>
        <cfset VARIABLES.eventoSolicitacaoReferencia = trim(FORM.evento_referencia)/>
    </cfif>
    <cfif isDefined("FORM.id_conta_solicitacao")>
        <cfset URL.id_conta_solicitacao = trim(FORM.id_conta_solicitacao)/>
    </cfif>
</cfif>

<cfif len(VARIABLES.eventoSolicitacaoReferencia)>
    <cfset VARIABLES.eventoSolicitacaoSearchTerm = VARIABLES.eventoSolicitacaoReferencia/>
    <cfset VARIABLES.eventoSolicitacaoUrlPos = findNoCase("/evento/", VARIABLES.eventoSolicitacaoSearchTerm)/>

    <cfif VARIABLES.eventoSolicitacaoUrlPos GT 0>
        <cfset VARIABLES.eventoSolicitacaoTag = mid(VARIABLES.eventoSolicitacaoSearchTerm, VARIABLES.eventoSolicitacaoUrlPos + len("/evento/"), len(VARIABLES.eventoSolicitacaoSearchTerm))/>
        <cfset VARIABLES.eventoSolicitacaoTag = listFirst(VARIABLES.eventoSolicitacaoTag, "/?##")/>
        <cfset VARIABLES.eventoSolicitacaoTag = trim(VARIABLES.eventoSolicitacaoTag)/>
    <cfelseif NOT find(" ", VARIABLES.eventoSolicitacaoSearchTerm) AND find("-", VARIABLES.eventoSolicitacaoSearchTerm)>
        <cfset VARIABLES.eventoSolicitacaoTag = listFirst(VARIABLES.eventoSolicitacaoSearchTerm, "/?##")/>
        <cfset VARIABLES.eventoSolicitacaoTag = trim(VARIABLES.eventoSolicitacaoTag)/>
    </cfif>
</cfif>

<cftry>
    <cfquery name="qEventoSolicitacaoTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_evento_solicitacoes"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_corridas"/>
          )
    </cfquery>

    <cfset VARIABLES.eventoSolicitacaoTableNames = ValueList(qEventoSolicitacaoTableCheck.table_name)/>
    <cfset VARIABLES.eventoSolicitacaoTablesReady = ListFindNoCase(VARIABLES.eventoSolicitacaoTableNames, "tb_contas")
        AND ListFindNoCase(VARIABLES.eventoSolicitacaoTableNames, "tb_conta_eventos")
        AND ListFindNoCase(VARIABLES.eventoSolicitacaoTableNames, "tb_conta_evento_solicitacoes")
        AND ListFindNoCase(VARIABLES.eventoSolicitacaoTableNames, "tb_evento_corridas")/>

    <cfif VARIABLES.eventoSolicitacaoTablesReady>
        <cfif VARIABLES.eventoSolicitacaoCanRequest>
            <cfquery name="qEventoSolicitacaoContas">
                SELECT id_conta,
                       nome_conta
                FROM tb_contas
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoEffectiveAccountIds#" list="true"/>)
                ORDER BY nome_conta
            </cfquery>

            <cfif len(trim(URL.id_conta_solicitacao))
                AND isNumeric(URL.id_conta_solicitacao)
                AND ListFind(ValueList(qEventoSolicitacaoContas.id_conta), URL.id_conta_solicitacao)>
                <cfset VARIABLES.eventoSolicitacaoSelectedAccountId = trim(URL.id_conta_solicitacao)/>
            <cfelseif qEventoSolicitacaoContas.recordcount>
                <cfset VARIABLES.eventoSolicitacaoSelectedAccountId = qEventoSolicitacaoContas.id_conta/>
            </cfif>
        </cfif>

        <cfif isDefined("FORM.evento_solicitacao_action")
            AND FORM.evento_solicitacao_action EQ "solicitar"
            AND len(trim(VARIABLES.eventoSolicitacaoErrorMessage)) EQ 0>

            <cfif NOT VARIABLES.eventoSolicitacaoCanRequest>
                <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Seu usuario nao possui uma conta ativa para solicitar vinculos de eventos."/>
            <cfelseif NOT len(trim(VARIABLES.eventoSolicitacaoSelectedAccountId))>
                <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Selecione uma conta para solicitar o vinculo."/>
            <cfelseif NOT isDefined("FORM.id_evento") OR NOT isNumeric(FORM.id_evento)>
                <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Evento invalido para solicitacao."/>
            <cfelse>
                <cfquery name="qEventoSolicitacaoEvento">
                    SELECT id_evento,
                           nome_evento,
                           tag
                    FROM tb_evento_corridas
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                      AND ativo = true
                    LIMIT 1
                </cfquery>

                <cfquery name="qEventoSolicitacaoVinculoAtual">
                    SELECT status::text AS status
                    FROM tb_conta_eventos
                    WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>
                      AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qEventoSolicitacaoEvento.recordcount>
                    <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Evento nao encontrado ou inativo."/>
                <cfelseif qEventoSolicitacaoVinculoAtual.recordcount AND qEventoSolicitacaoVinculoAtual.status EQ "ATIVO">
                    <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Este evento ja esta vinculado a conta selecionada."/>
                <cfelse>
                    <cfquery>
                        INSERT INTO tb_conta_eventos
                        (
                            id_conta,
                            id_evento,
                            status,
                            usuario_cadastro
                        )
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                            'PENDENTE'::status_conta_evento,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                        )
                        ON CONFLICT (id_conta, id_evento)
                        DO UPDATE SET
                            status = CASE
                                WHEN tb_conta_eventos.status = 'ATIVO'::status_conta_evento THEN tb_conta_eventos.status
                                ELSE 'PENDENTE'::status_conta_evento
                            END,
                            data_atualizacao = now()
                    </cfquery>

                    <cfquery name="qEventoSolicitacaoPendenteAtual">
                        SELECT id_solicitacao
                        FROM tb_conta_evento_solicitacoes
                        WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>
                          AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                          AND status = <cfqueryparam cfsqltype="cf_sql_varchar" value="PENDENTE"/>
                        ORDER BY data_criacao DESC
                        LIMIT 1
                    </cfquery>

                    <cfif qEventoSolicitacaoPendenteAtual.recordcount>
                        <cfquery>
                            UPDATE tb_conta_evento_solicitacoes
                            SET id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                                url_informada = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventoSolicitacaoReferencia#" null="#NOT len(trim(VARIABLES.eventoSolicitacaoReferencia))#"/>,
                                tag_informada = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventoSolicitacaoTag#" null="#NOT len(trim(VARIABLES.eventoSolicitacaoTag))#"/>,
                                mensagem = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.mensagem#" null="#NOT len(trim(FORM.mensagem))#"/>
                            WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoPendenteAtual.id_solicitacao#"/>
                        </cfquery>
                    <cfelse>
                        <cfquery>
                            INSERT INTO tb_conta_evento_solicitacoes
                            (
                                id_conta,
                                id_evento,
                                id_usuario_solicitante,
                                url_informada,
                                tag_informada,
                                mensagem,
                                status
                            )
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventoSolicitacaoReferencia#" null="#NOT len(trim(VARIABLES.eventoSolicitacaoReferencia))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventoSolicitacaoTag#" null="#NOT len(trim(VARIABLES.eventoSolicitacaoTag))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.mensagem#" null="#NOT len(trim(FORM.mensagem))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="PENDENTE"/>
                            )
                        </cfquery>
                    </cfif>

                    <cfquery>
                        INSERT INTO tb_log
                        (log_item, log_item_id, log_user, site)
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="solicitar_evento_conta"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#,#FORM.id_evento#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="RH"/>
                        )
                    </cfquery>

                    <cflocation addtoken="false" url="/eventos/?solicitacao=pedido"/>
                </cfif>
            </cfif>
        </cfif>

        <cfif isDefined("FORM.evento_solicitacao_action")
            AND ListFindNoCase("aprovar,negar", FORM.evento_solicitacao_action)
            AND len(trim(VARIABLES.eventoSolicitacaoErrorMessage)) EQ 0>

            <cfif NOT VARIABLES.eventoSolicitacaoCanReview>
                <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Apenas administradores podem revisar solicitacoes de vinculo."/>
            <cfelseif NOT isDefined("FORM.id_solicitacao") OR NOT isNumeric(FORM.id_solicitacao)>
                <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Solicitacao invalida."/>
            <cfelse>
                <cfquery name="qEventoSolicitacaoRevisao">
                    SELECT id_solicitacao,
                           id_conta,
                           id_evento,
                           status
                    FROM tb_conta_evento_solicitacoes
                    WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.id_solicitacao#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qEventoSolicitacaoRevisao.recordcount>
                    <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Solicitacao nao encontrada."/>
                <cfelseif qEventoSolicitacaoRevisao.status NEQ "PENDENTE">
                    <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Esta solicitacao ja foi revisada."/>
                <cfelseif FORM.evento_solicitacao_action EQ "aprovar">
                    <cfquery>
                        INSERT INTO tb_conta_eventos
                        (
                            id_conta,
                            id_evento,
                            status,
                            usuario_cadastro
                        )
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoRevisao.id_conta#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qEventoSolicitacaoRevisao.id_evento#"/>,
                            'ATIVO'::status_conta_evento,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                        )
                        ON CONFLICT (id_conta, id_evento)
                        DO UPDATE SET
                            status = 'ATIVO'::status_conta_evento,
                            usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            data_atualizacao = now()
                    </cfquery>

                    <cfquery>
                        UPDATE tb_conta_evento_solicitacoes
                        SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="APROVADA"/>,
                            id_usuario_revisor = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            observacao_revisor = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.observacao_revisor#" null="#NOT len(trim(FORM.observacao_revisor))#"/>,
                            data_revisao = now()
                        WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoRevisao.id_solicitacao#"/>
                    </cfquery>

                    <cflocation addtoken="false" url="/eventos/?solicitacao=aprovada"/>
                <cfelse>
                    <cfquery>
                        INSERT INTO tb_conta_eventos
                        (
                            id_conta,
                            id_evento,
                            status,
                            usuario_cadastro
                        )
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoRevisao.id_conta#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qEventoSolicitacaoRevisao.id_evento#"/>,
                            'INATIVO'::status_conta_evento,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                        )
                        ON CONFLICT (id_conta, id_evento)
                        DO UPDATE SET
                            status = 'INATIVO'::status_conta_evento,
                            usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            data_atualizacao = now()
                    </cfquery>

                    <cfquery>
                        UPDATE tb_conta_evento_solicitacoes
                        SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="NEGADA"/>,
                            id_usuario_revisor = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            observacao_revisor = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.observacao_revisor#" null="#NOT len(trim(FORM.observacao_revisor))#"/>,
                            data_revisao = now()
                        WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoRevisao.id_solicitacao#"/>
                    </cfquery>

                    <cflocation addtoken="false" url="/eventos/?solicitacao=negada"/>
                </cfif>
            </cfif>
        </cfif>

        <cfif URL.solicitacao EQ "pedido">
            <cfset VARIABLES.eventoSolicitacaoNoticeMessage = "Solicitacao enviada. O vinculo ficara pendente ate a aprovacao."/>
        <cfelseif URL.solicitacao EQ "aprovada">
            <cfset VARIABLES.eventoSolicitacaoNoticeMessage = "Solicitacao aprovada e evento liberado para a conta."/>
        <cfelseif URL.solicitacao EQ "negada">
            <cfset VARIABLES.eventoSolicitacaoNoticeMessage = "Solicitacao negada."/>
        <cfelseif URL.solicitacao EQ "evento_admin">
            <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Para incluir um evento na conta, use a busca e envie uma solicitacao para aprovacao."/>
        </cfif>

        <cfif VARIABLES.eventoSolicitacaoCanRequest
            AND len(trim(VARIABLES.eventoSolicitacaoSelectedAccountId))
            AND len(trim(VARIABLES.eventoSolicitacaoReferencia))>

            <cfquery name="qEventoSolicitacaoBusca">
                SELECT evt.id_evento,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado,
                       ce.status::text AS status_vinculo,
                       sol.status AS status_solicitacao
                FROM tb_evento_corridas evt
                LEFT JOIN tb_conta_eventos ce
                    ON ce.id_evento = evt.id_evento
                   AND ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>
                LEFT JOIN LATERAL (
                    SELECT req.status
                    FROM tb_conta_evento_solicitacoes req
                    WHERE req.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoSelectedAccountId#"/>
                      AND req.id_evento = evt.id_evento
                    ORDER BY req.data_criacao DESC
                    LIMIT 1
                ) sol ON true
                WHERE evt.ativo = true
                  AND (
                    <cfif isNumeric(VARIABLES.eventoSolicitacaoReferencia)>
                        evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventoSolicitacaoReferencia#"/>
                        OR
                    </cfif>
                    <cfif len(trim(VARIABLES.eventoSolicitacaoTag))>
                        evt.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(VARIABLES.eventoSolicitacaoTag)#"/>
                        OR
                        evt.tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventoSolicitacaoTag#%"/>
                        OR
                    </cfif>
                    unaccent(upper(coalesce(evt.nome_evento, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventoSolicitacaoReferencia#%"/>))
                    OR unaccent(upper(coalesce(evt.tag, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventoSolicitacaoReferencia#%"/>))
                    OR unaccent(upper(coalesce(evt.cidade, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventoSolicitacaoReferencia#%"/>))
                  )
                ORDER BY
                  <cfif len(trim(VARIABLES.eventoSolicitacaoTag))>
                    CASE WHEN evt.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(VARIABLES.eventoSolicitacaoTag)#"/> THEN 0 ELSE 1 END,
                  </cfif>
                  evt.data_final DESC NULLS LAST,
                  evt.nome_evento
                LIMIT 20
            </cfquery>
        </cfif>

        <cfif VARIABLES.eventoSolicitacaoCanRequest
            AND len(trim(VARIABLES.eventoSolicitacaoEffectiveAccountIds))
            AND VARIABLES.eventoSolicitacaoEffectiveAccountIds NEQ "0">

            <cfquery name="qEventoMinhasSolicitacoes">
                SELECT sol.id_solicitacao,
                       sol.id_conta,
                       sol.id_evento,
                       sol.status,
                       sol.data_criacao,
                       sol.data_revisao,
                       cont.nome_conta,
                       evt.nome_evento,
                       evt.tag,
                       evt.cidade,
                       evt.estado,
                       sol.observacao_revisor
                FROM tb_conta_evento_solicitacoes sol
                INNER JOIN tb_contas cont ON cont.id_conta = sol.id_conta
                INNER JOIN tb_evento_corridas evt ON evt.id_evento = sol.id_evento
                WHERE sol.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventoSolicitacaoEffectiveAccountIds#" list="true"/>)
                ORDER BY CASE WHEN sol.status::text = 'PENDENTE' THEN 0 ELSE 1 END,
                         sol.data_criacao DESC
                LIMIT 20
            </cfquery>

            <cfloop query="qEventoMinhasSolicitacoes">
                <cfif compareNoCase(qEventoMinhasSolicitacoes.status, "PENDENTE") EQ 0>
                    <cfset VARIABLES.eventoMinhasSolicitacoesPendentes = VARIABLES.eventoMinhasSolicitacoesPendentes + 1/>
                <cfelse>
                    <cfset VARIABLES.eventoMinhasSolicitacoesHistorico = VARIABLES.eventoMinhasSolicitacoesHistorico + 1/>
                </cfif>
            </cfloop>
        </cfif>

        <cfif VARIABLES.eventoSolicitacaoCanReview>
            <cfquery name="qEventoSolicitacoesPendentes">
                SELECT sol.id_solicitacao,
                       sol.id_conta,
                       sol.id_evento,
                       sol.id_usuario_solicitante,
                       sol.url_informada,
                       sol.tag_informada,
                       sol.mensagem,
                       sol.status,
                       sol.data_criacao,
                       cont.nome_conta,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado,
                       usr.name AS usuario_solicitante,
                       usr.email AS email_solicitante
                FROM tb_conta_evento_solicitacoes sol
                INNER JOIN tb_contas cont ON cont.id_conta = sol.id_conta
                INNER JOIN tb_evento_corridas evt ON evt.id_evento = sol.id_evento
                LEFT JOIN tb_usuarios usr ON usr.id = sol.id_usuario_solicitante
                WHERE sol.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="PENDENTE"/>
                ORDER BY sol.data_criacao ASC
                LIMIT 100
            </cfquery>
        </cfif>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.eventoSolicitacaoTablesReady = false/>
        <cfset VARIABLES.eventoSolicitacaoErrorMessage = "Nao foi possivel carregar as solicitacoes de eventos. Verifique a DDL de tb_conta_evento_solicitacoes."/>
    </cfcatch>
</cftry>
