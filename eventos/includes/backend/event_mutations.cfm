<cfscript>
function adminEventoResolveUniqueTag(required string requestedTag, numeric eventId=0, string datasource="runner_dba") {
    var baseTag = trim(arguments.requestedTag);
    var candidateTag = baseTag;
    var suffix = "";
    var attempt = 1;
    var qTagConflict = "";

    if (!len(baseTag)) {
        baseTag = arguments.eventId GT 0
            ? "evento-" & int(arguments.eventId)
            : "evento-" & lCase(replace(createUUID(), "-", "", "all"));
        candidateTag = baseTag;
    }

    while (attempt LTE 100) {
        qTagConflict = queryExecute(
            "SELECT id_evento
             FROM tb_evento_corridas
             WHERE tag = :tag
               AND id_evento <> :eventId
             LIMIT 1",
            {
                tag = {value=candidateTag, cfsqltype="cf_sql_varchar"},
                eventId = {value=val(arguments.eventId), cfsqltype="cf_sql_integer"}
            }, {datasource=arguments.datasource}
        );

        if (!qTagConflict.recordcount) {
            return candidateTag;
        }

        suffix = arguments.eventId GT 0
            ? "-" & int(arguments.eventId) & (attempt GT 1 ? "-" & attempt : "")
            : "-" & (attempt + 1);
        candidateTag = left(baseTag, max(1, 512 - len(suffix))) & suffix;
        attempt++;
    }

    throw(
        type="EventoTagConflict",
        message="Não foi possível gerar uma tag única para o evento."
    );
}
</cfscript>
<cffunction name="eventMutationEdit" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfset eventMutationScope(arguments.fresh,FORM,arguments.state)/>
<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_basico" AND isDefined("FORM.nome_evento") AND Len(trim(FORM.nome_evento))>



    <cfset arguments.state.inscricaoBasicSchemaReady = new services.EventRegistrationAvailabilityService().isSchemaReady()/>

    <cfquery name="qCidade" datasource="#arguments.fresh.datasource#">
        SELECT cod_cidade, nome_cidade, uf
        FROM tb_cidades
        WHERE cod_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.cidade#"/>
          AND uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.estado))#"/>
    </cfquery>
    <cfif qCidade.recordcount NEQ 1>
        <cfthrow type="BusinessDelegation.Validation" message="Selecione uma cidade do estado informado."/>
    </cfif>

    <cfset arguments.state.adminEventoRequestedTag = trim(FORM.tag & "")/>
    <cfset arguments.state.adminEventoResolvedTag = adminEventoResolveUniqueTag(
        arguments.state.adminEventoRequestedTag,
        isNumeric(FORM.id_evento) ? val(FORM.id_evento) : 0, arguments.fresh.datasource
    )/>
    <cfset arguments.state.adminEventoTagAdjusted = compare(
        arguments.state.adminEventoRequestedTag,
        arguments.state.adminEventoResolvedTag
    ) NEQ 0/>

    <cfif FORM.id_evento EQ 0>

        <cfquery name="arguments.state.qInsert" datasource="#arguments.fresh.datasource#">
            INSERT INTO tb_evento_corridas
            (nome_evento, cidade, cod_cidade, estado, data_inicial, data_final, tag,
                tipo_corrida, endereco, coordenadas, url_inscricao, url_hotsite)
            VALUES
            (
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome_evento#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.nome_cidade#"/>,
             <cfqueryparam cfsqltype="cf_sql_integer" value="#qCidade.cod_cidade#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.uf#"/>,
             <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_inicial#"/>,
             <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_final#"/>,
	             <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adminEventoResolvedTag#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.endereco#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.coordenadas#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_inscricao#"/>,
             <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_hotsite#"/>
            ) RETURNING id_evento
        </cfquery>

        <cfquery datasource="#arguments.fresh.datasource#">
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.nome_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
        </cfquery>

    <cfelse>

        <cfquery datasource="#arguments.fresh.datasource#">
            UPDATE tb_evento_corridas
            SET
            nome_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.nome_evento#"/>,
            cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.nome_cidade#"/>,
            cod_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCidade.cod_cidade#"/>,
            estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qCidade.uf#"/>,
            data_inicial = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_inicial#"/>,
            data_final = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_final#"/>,
            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adminEventoResolvedTag#"/>,
            tipo_corrida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
            endereco = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.endereco#"/>,
            coordenadas = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.coordenadas#"/>,
            <cfif arguments.state.inscricaoBasicSchemaReady>
                inscricao_disponibilidade = CASE WHEN trim(coalesce(url_inscricao, '')) IS DISTINCT FROM <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.url_inscricao)#"/>
                    THEN NULL ELSE inscricao_disponibilidade END,
            </cfif>
            url_inscricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_inscricao#"/>,
            url_hotsite = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_hotsite#"/>
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery datasource="#arguments.fresh.datasource#">
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.nome_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
        </cfquery>

    </cfif>

</cfif>

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_fornecedores" >

    <cfquery datasource="#arguments.fresh.datasource#">
        DELETE FROM tb_evento_corridas_fornecedores
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfloop array="#arguments.state.eventSupplierRows#" index="local.supplier">
        <cfquery datasource="#arguments.fresh.datasource#">
            INSERT INTO tb_evento_corridas_fornecedores(id_fornecedor,id_fornecedor_tipo,id_evento)
            VALUES (<cfqueryparam cfsqltype="cf_sql_integer" value="#local.supplier.id#"/>,
              <cfqueryparam cfsqltype="cf_sql_integer" value="#local.supplier.type#"/>,
              <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>)
        </cfquery>
    </cfloop>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_competition_id" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento))>

    <cfquery datasource="#arguments.fresh.datasource#">
        DELETE FROM tb_evento_corridas_relaciona
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        AND id_parceiro = 1
        AND nome_variavel = 'competition_id'
    </cfquery>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_evento_corridas_relaciona
        (id_evento_parceiro, id_parceiro, nome_variavel, id_evento)
        VALUES
        (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento_parceiro#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="competition_id"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        )
    </cfquery>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento_parceiro#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_descricao" AND isDefined("FORM.descricao")>

    <cfquery datasource="#arguments.fresh.datasource#">
        UPDATE tb_evento_corridas
        SET descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.descricao#"/>,
        url_imagem = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_imagem#"/>,
        resumo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.resumo#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.resumo#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_percursos" AND isDefined("FORM.categorias")>

    <cfquery datasource="#arguments.fresh.datasource#">
        UPDATE tb_evento_corridas
        SET categorias = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.categorias#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.categorias#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>

<cfif isDefined("FORM.action") AND FORM.action EQ "salvar_evento_percurso" AND isDefined("FORM.id_evento_percurso") AND Len(trim(FORM.id_evento_percurso))>

    <cfquery datasource="#arguments.fresh.datasource#">
        UPDATE tb_evento_corridas_percursos
        SET percurso_evento = <cfqueryparam cfsqltype="cf_sql_numeric" value="#FORM.percurso_evento#"/>,
        unidade_de_medida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.unidade_de_medida#"/>,
        data_percurso = <cfqueryparam cfsqltype="cf_sql_date" value="#FORM.data_percurso#"/>,
        hora_largada = <cfqueryparam cfsqltype="cf_sql_time" value="#FORM.hora_largada#" null="#NOT len(trim(FORM.hora_largada))#"/>,
        tipo_corrida = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.tipo_corrida#"/>,
        percurso_bloqueado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        WHERE id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento_percurso#"/>
        AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery name="qBadges" datasource="#arguments.fresh.datasource#">
        SELECT tip.image_path, tip.badge, bg.valor_badge, bg.percurso, bg.complemento_badge from tb_badges_tipos tip
        left join tb_badges bg on bg.badge = tip.badge
            and bg.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
            and bg.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>
        where tip.tipo_badge = 'percurso'
        and tip.min_km <= <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>
        order by ordem
    </cfquery>

    <cfloop query="qBadges">

        <cfif isDefined("FORM.#qBadges.badge#")>
            <cfquery datasource="#arguments.fresh.datasource#">
                INSERT INTO tb_badges
                (id_evento, percurso, badge, valor_badge, complemento_badge, flag_badge)
                values
                (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.percurso_evento#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBadges.badge#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM[qBadges.badge&'_valor_badge']#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM[qBadges.badge&'_complemento_badge']#"/>,
                true
                )
                ON CONFLICT (id_evento, percurso, badge)
                    DO UPDATE SET
                    valor_badge  = excluded.valor_badge,
                    complemento_badge  = excluded.complemento_badge
                    RETURNING *;
            </cfquery>
        </cfif>

    </cfloop>

    <cfquery datasource="#arguments.fresh.datasource#">
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento_percurso#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>
<cfreturn true/></cffunction>
<cffunction name="eventMutationRequest" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfif structKeyExists(arguments.fresh,"accessMode") AND arguments.fresh.accessMode EQ "DELEGATED">
    <cfif NOT structKeyExists(FORM,"id_conta_solicitacao") OR compare(FORM.id_conta_solicitacao & "",arguments.fresh.accountId & "") NEQ 0 OR compare(arguments.state.eventoSolicitacaoSelectedAccountId & "",arguments.fresh.accountId & "") NEQ 0>
        <cfthrow type="BusinessDelegation.Forbidden" message="Request account unavailable"/>
    </cfif>
    <cfset arguments.state.eventoSolicitacaoUsingPendingAccount=false/>
</cfif>
                <cfquery name="qEventoSolicitacaoEvento" datasource="#arguments.fresh.datasource#">
                    SELECT id_evento,
                           nome_evento,
                           tag
                    FROM tb_evento_corridas
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                      AND ativo = true
                    LIMIT 1 FOR UPDATE
                </cfquery>

                <cfquery name="qEventoSolicitacaoVinculoAtual" datasource="#arguments.fresh.datasource#">
                    SELECT status::text AS status
                    FROM tb_conta_eventos
                    WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.eventoSolicitacaoSelectedAccountId#"/>
                      AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                      <cfif arguments.state.eventoSolicitacaoUsingPendingAccount>
                        AND usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
                      </cfif>
                    LIMIT 1 FOR UPDATE
                </cfquery>

                <cfif NOT qEventoSolicitacaoEvento.recordcount>
                    <cfthrow type="BusinessDelegation.NotFound" message="Evento não encontrado ou inativo."/>
                <cfelseif qEventoSolicitacaoVinculoAtual.recordcount AND qEventoSolicitacaoVinculoAtual.status EQ "ATIVO">
                    <cfthrow type="BusinessDelegation.Validation" message="Este evento já está vinculado à conta selecionada."/>
                <cfelse>
                    <cfquery datasource="#arguments.fresh.datasource#">
                        INSERT INTO tb_conta_eventos
                        (
                            id_conta,
                            id_evento,
                            status,
                            usuario_cadastro
                        )
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.eventoSolicitacaoSelectedAccountId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                            'PENDENTE'::status_conta_evento,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
                        )
                        ON CONFLICT (id_conta, id_evento)
                        DO UPDATE SET
                            status = CASE
                                WHEN tb_conta_eventos.status = 'ATIVO'::status_conta_evento THEN tb_conta_eventos.status
                                ELSE 'PENDENTE'::status_conta_evento
                            END,
                            data_atualizacao = now()
                    </cfquery>

                    <cfquery name="qEventoSolicitacaoPendenteAtual" datasource="#arguments.fresh.datasource#">
                        SELECT id_solicitacao
                        FROM tb_conta_evento_solicitacoes
                        WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.eventoSolicitacaoSelectedAccountId#"/>
                          AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                          AND status = <cfqueryparam cfsqltype="cf_sql_varchar" value="PENDENTE"/>
                          <cfif arguments.state.eventoSolicitacaoUsingPendingAccount>
                            AND id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
                          </cfif>
                        ORDER BY data_criacao DESC
                        LIMIT 1
                    </cfquery>

                    <cfif qEventoSolicitacaoPendenteAtual.recordcount>
                        <cfquery datasource="#arguments.fresh.datasource#">
                            UPDATE tb_conta_evento_solicitacoes
                            SET id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>,
                                url_informada = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.eventoSolicitacaoReferencia#" null="#NOT len(trim(arguments.state.eventoSolicitacaoReferencia))#"/>,
                                tag_informada = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.eventoSolicitacaoTag#" null="#NOT len(trim(arguments.state.eventoSolicitacaoTag))#"/>,
                                mensagem = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.mensagem#" null="#NOT len(trim(FORM.mensagem))#"/>
                            WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qEventoSolicitacaoPendenteAtual.id_solicitacao#"/>
                        </cfquery>
                    <cfelse>
                        <cfquery datasource="#arguments.fresh.datasource#">
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
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.eventoSolicitacaoSelectedAccountId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.eventoSolicitacaoReferencia#" null="#NOT len(trim(arguments.state.eventoSolicitacaoReferencia))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.eventoSolicitacaoTag#" null="#NOT len(trim(arguments.state.eventoSolicitacaoTag))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FORM.mensagem#" null="#NOT len(trim(FORM.mensagem))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="PENDENTE"/>
                            )
                        </cfquery>
                    </cfif>

                    <cfquery datasource="#arguments.fresh.datasource#">
                        INSERT INTO tb_log
                        (log_item, log_item_id, log_user, site)
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="solicitar_evento_conta"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.eventoSolicitacaoSelectedAccountId#,#FORM.id_evento#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="RH"/>
                        )
                    </cfquery>


                </cfif>
<cfreturn true/></cffunction>
