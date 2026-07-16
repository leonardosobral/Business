<cfinclude template="../../includes/backend/agenda_service.cfm"/>

<cfparam name="URL.agenda_id" default=""/>
<cfparam name="URL.nova" default=""/>
<cfparam name="URL.sucesso" default=""/>
<cfparam name="URL.owner_search" default=""/>
<cfparam name="URL.buscar_eventos" default=""/>
<cfparam name="URL.evento_busca" default=""/>
<cfparam name="URL.evento_agregador" default=""/>
<cfparam name="URL.evento_distancia" default=""/>
<cfparam name="URL.evento_estado" default=""/>
<cfparam name="URL.evento_cidade" default=""/>
<cfparam name="URL.evento_tipo" default=""/>
<cfparam name="URL.evento_visao" default="todos"/>
<cfparam name="URL.preview_visao" default=""/>
<cfparam name="URL.agregador_filtro_busca" default=""/>
<cfparam name="URL.codigo_visao" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.agendaManagementTablesReady = agendaServiceTablesReady()/>
<cfset VARIABLES.agendaManagementAlert = { type = "", message = "" }/>
<cfset VARIABLES.agendaManagementNewFeedToken = ""/>
<cfset VARIABLES.agendaManagementSelectedId = isNumeric(URL.agenda_id) ? val(URL.agenda_id) : 0/>
<cfset VARIABLES.agendaManagementActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(agendaServiceQueryValue(qPerfil, "id", 1)) : 0/>
<cfset VARIABLES.agendaManagementIsAdmin = isDefined("qPerfil") AND qPerfil.recordcount AND agendaServiceNormalizeBoolean(agendaServiceQueryValue(qPerfil, "is_admin", 1))/>
<cfset VARIABLES.agendaManagementIsDev = isDefined("qPerfil") AND qPerfil.recordcount AND agendaServiceNormalizeBoolean(agendaServiceQueryValue(qPerfil, "is_dev", 1))/>
<cfset VARIABLES.agendaManagementIsPartner = isDefined("qPerfil") AND qPerfil.recordcount AND agendaServiceNormalizeBoolean(agendaServiceQueryValue(qPerfil, "is_partner", 1))/>
<cfset VARIABLES.agendaManagementCanManageAll = VARIABLES.agendaManagementIsAdmin OR VARIABLES.agendaManagementIsDev/>
<cfset VARIABLES.agendaManagementCanWrite = VARIABLES.agendaManagementCanManageAll OR VARIABLES.agendaManagementIsPartner/>
<cfset VARIABLES.agendaManagementPostedAgendaAllowed = true/>

<cfset qAgendaManagementStats = queryNew("total,ativas,manuais,dinamicas,acessos_30d")/>
<cfset queryAddRow(qAgendaManagementStats, {total=0, ativas=0, manuais=0, dinamicas=0, acessos_30d=0})/>
<cfset qAgendaManagementList = queryNew("id_agenda,chave_publica,nome,id_usuario,usuario_nome,usuario_email,modo,visao_padrao,dominio_permitido,permitir_subdominios,limite_eventos,ordenacao,tema_embed,cor_card_data,fonte_cards,raio_cards,status,versao,data_criacao,data_atualizacao,total_eventos,total_filtros,total_acessos,ultimo_acesso")/>
<cfset qAgendaManagementEdit = queryNew("id_agenda,chave_publica,nome,descricao,id_usuario,usuario_nome,usuario_email,modo,visao_padrao,dominio_permitido,permitir_subdominios,limite_eventos,ordenacao,tema_embed,cor_card_data,fonte_cards,raio_cards,status,versao,data_criacao,data_atualizacao")/>
<cfset qAgendaManagementOwnerSearch = queryNew("id,name,email")/>
<cfset qAgendaManagementSelectedEvents = queryNew("id_agenda_evento,id_evento,ordem,nome_evento,tag,cidade,estado,data_inicial,data_final,tipo_corrida,url_resultado")/>
<cfset qAgendaManagementFilters = queryNew("id_agenda_filtro,campo,valor_texto,valor_numero,valor_id,valor_exibicao")/>
<cfset qAgendaManagementEventSearch = queryNew("id_evento,nome_evento,tag,cidade,estado,pais,data_inicial,data_final,tipo_corrida,url_resultado,agregador_nome,distancias,ja_adicionado")/>
<cfset qAgendaManagementStates = queryNew("estado")/>
<cfset qAgendaManagementTypes = queryNew("tipo_corrida")/>
<cfset qAgendaManagementAggregatorSearch = queryNew("id_agrega_evento,nome_evento_agregado,tipo_agregacao")/>
<cfset qAgendaManagementPreview = queryNew("id_evento,nome_evento,tag,cidade,estado,pais,data_inicial,data_final,tipo_corrida,status_evento,url_resultado,url_imagem,url_imagem_listagem,imagem,destaque,id_agrega_evento,agregador_nome,distancias_json,total_concluintes,ordem_agenda")/>
<cfset qAgendaManagementAccessStats = queryNew("total,permitidos,negados,ultimo_acesso")/>
<cfset queryAddRow(qAgendaManagementAccessStats, {total=0, permitidos=0, negados=0, ultimo_acesso=""})/>
<cfset qAgendaManagementRecentAccess = queryNew("formato,visao,dominio_requisitante,endereco_ip,status_http,eventos_retornados,duracao_ms,data_acesso")/>

<cfif NOT structKeyExists(SESSION, "agendaManagementCsrfToken") OR NOT len(trim(SESSION.agendaManagementCsrfToken & ""))>
    <cfset SESSION.agendaManagementCsrfToken = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.agendaManagementCsrfToken = SESSION.agendaManagementCsrfToken/>

<cfif structKeyExists(SESSION, "agendaManagementFeedToken")
    AND isStruct(SESSION.agendaManagementFeedToken)
    AND structKeyExists(SESSION.agendaManagementFeedToken, "agendaId")
    AND val(SESSION.agendaManagementFeedToken.agendaId) EQ VARIABLES.agendaManagementSelectedId
    AND structKeyExists(SESSION.agendaManagementFeedToken, "token")>
    <cfset VARIABLES.agendaManagementNewFeedToken = trim(SESSION.agendaManagementFeedToken.token & "")/>
    <cfset structDelete(SESSION, "agendaManagementFeedToken")/>
</cfif>

<cfif len(trim(URL.sucesso))>
    <cfswitch expression="#lCase(trim(URL.sucesso))#">
        <cfcase value="criada"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Agenda criada. A credencial XML abaixo sera exibida somente agora."}/></cfcase>
        <cfcase value="salva"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Agenda atualizada com sucesso."}/></cfcase>
        <cfcase value="status"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Status da agenda atualizado."}/></cfcase>
        <cfcase value="eventos"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Eventos adicionados a agenda."}/></cfcase>
        <cfcase value="evento_removido"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Evento removido da agenda."}/></cfcase>
        <cfcase value="evento_movido"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Ordem dos eventos atualizada."}/></cfcase>
        <cfcase value="filtro"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Regra dinamica adicionada."}/></cfcase>
        <cfcase value="filtro_removido"><cfset VARIABLES.agendaManagementAlert = {type="success", message="Regra dinamica removida."}/></cfcase>
        <cfcase value="credencial"><cfset VARIABLES.agendaManagementAlert = {type="success", message="A credencial XML foi rotacionada e sera exibida somente agora."}/></cfcase>
    </cfswitch>
</cfif>

<cfif VARIABLES.agendaManagementTablesReady AND VARIABLES.agendaManagementCanWrite>
    <cfif len(trim(FORM.acao))
        AND NOT VARIABLES.agendaManagementCanManageAll
        AND isDefined("FORM.agenda_id")
        AND isNumeric(FORM.agenda_id)
        AND val(FORM.agenda_id) GT 0>
        <cfquery name="qAgendaManagementPostedAgendaOwner">
            SELECT id_agenda
            FROM tb_agendas
            WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
              AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaManagementActorId#"/>
        </cfquery>
        <cfset VARIABLES.agendaManagementPostedAgendaAllowed = qAgendaManagementPostedAgendaOwner.recordcount GT 0/>
    </cfif>

    <cfif len(trim(FORM.acao)) AND compareNoCase(trim(FORM.csrf_token), VARIABLES.agendaManagementCsrfToken) NEQ 0>
        <cfset VARIABLES.agendaManagementAlert = {type="danger", message="A sessao do formulario expirou. Recarregue a pagina e tente novamente."}/>
    <cfelseif len(trim(FORM.acao)) AND NOT VARIABLES.agendaManagementPostedAgendaAllowed>
        <cfset VARIABLES.agendaManagementAlert = {type="danger", message="Voce nao tem permissao para alterar esta agenda."}/>
    <cfelseif FORM.acao EQ "salvar_agenda">
        <cfset VARIABLES.agendaSaveId = isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id) ? val(FORM.agenda_id) : 0/>
        <cfset VARIABLES.agendaSaveName = isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
        <cfset VARIABLES.agendaSaveDescription = isDefined("FORM.descricao") ? trim(FORM.descricao) : ""/>
        <cfset VARIABLES.agendaSaveOwnerId = VARIABLES.agendaManagementCanManageAll
            AND isDefined("FORM.id_usuario")
            AND isNumeric(FORM.id_usuario)
            ? val(FORM.id_usuario)
            : VARIABLES.agendaManagementActorId/>
        <cfset VARIABLES.agendaSaveMode = isDefined("FORM.modo") AND listFindNoCase("manual,dinamica", FORM.modo) ? lCase(FORM.modo) : "manual"/>
        <cfset VARIABLES.agendaSaveView = "futuros"/>
        <cfset VARIABLES.agendaSaveHost = isDefined("FORM.dominio_permitido") ? agendaServiceNormalizeHost(FORM.dominio_permitido) : ""/>
        <cfset VARIABLES.agendaSaveSubdomains = isDefined("FORM.permitir_subdominios") AND agendaServiceNormalizeBoolean(FORM.permitir_subdominios)/>
        <cfset VARIABLES.agendaSaveLimit = isDefined("FORM.limite_eventos") AND isNumeric(FORM.limite_eventos) ? min(100, max(1, int(FORM.limite_eventos))) : 20/>
        <cfset VARIABLES.agendaSaveOrder = isDefined("FORM.ordenacao") AND listFindNoCase("data,manual", FORM.ordenacao) ? lCase(FORM.ordenacao) : "data"/>
        <cfset VARIABLES.agendaSaveTheme = agendaServiceNormalizeTheme(isDefined("FORM.tema_embed") ? FORM.tema_embed : "escuro")/>
        <cfset VARIABLES.agendaSaveDateColor = agendaServiceNormalizeHexColor(isDefined("FORM.cor_card_data") ? FORM.cor_card_data : "fab120")/>
        <cfset VARIABLES.agendaSaveCardFont = agendaServiceNormalizeCardFont(isDefined("FORM.fonte_cards") ? FORM.fonte_cards : "trebuchet")/>
        <cfset VARIABLES.agendaSaveCardRadius = agendaServiceNormalizeCardRadius(isDefined("FORM.raio_cards") ? FORM.raio_cards : "atual")/>
        <cfset VARIABLES.agendaSaveStatus = isDefined("FORM.status") AND listFindNoCase("rascunho,ativa,pausada,arquivada", FORM.status) ? lCase(FORM.status) : "rascunho"/>
        <cfset VARIABLES.agendaSaveErrors = []/>

        <cfif NOT len(VARIABLES.agendaSaveName)><cfset arrayAppend(VARIABLES.agendaSaveErrors, "Informe o nome da agenda.")/></cfif>
        <cfif VARIABLES.agendaSaveOwnerId LTE 0><cfset arrayAppend(VARIABLES.agendaSaveErrors, "Selecione o usuario proprietario.")/></cfif>
        <cfif NOT agendaServiceValidHost(VARIABLES.agendaSaveHost)><cfset arrayAppend(VARIABLES.agendaSaveErrors, "Informe um dominio valido, sem caminhos ou curingas.")/></cfif>
        <cfif VARIABLES.agendaSaveMode EQ "dinamica"><cfset VARIABLES.agendaSaveOrder = "data"/></cfif>

        <cfif NOT arrayLen(VARIABLES.agendaSaveErrors)>
            <cfquery name="qAgendaSaveOwner">
                SELECT id FROM tb_usuarios WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaSaveOwnerId#"/>
            </cfquery>
            <cfif NOT qAgendaSaveOwner.recordcount><cfset arrayAppend(VARIABLES.agendaSaveErrors, "O usuario proprietario nao foi encontrado.")/></cfif>
        </cfif>

        <cfif arrayLen(VARIABLES.agendaSaveErrors)>
            <cfset VARIABLES.agendaManagementAlert = {type="warning", message=arrayToList(VARIABLES.agendaSaveErrors, " ")}/>
        <cfelseif VARIABLES.agendaSaveId GT 0>
            <cfquery name="qAgendaSaveExisting">
                SELECT id_agenda FROM tb_agendas WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agendaSaveId#"/>
            </cfquery>
            <cfif NOT qAgendaSaveExisting.recordcount>
                <cfset VARIABLES.agendaManagementAlert = {type="danger", message="A agenda informada nao foi encontrada."}/>
            <cfelse>
                <cfquery>
                    UPDATE tb_agendas
                    SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveName#"/>,
                        descricao = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agendaSaveDescription#" null="#NOT len(VARIABLES.agendaSaveDescription)#"/>,
                        id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaSaveOwnerId#"/>,
                        modo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveMode#"/>,
                        visao_padrao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveView#"/>,
                        dominio_permitido = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveHost#"/>,
                        permitir_subdominios = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.agendaSaveSubdomains#"/>,
                        limite_eventos = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaSaveLimit#"/>,
                        ordenacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveOrder#"/>,
                        tema_embed = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveTheme#"/>,
                        cor_card_data = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveDateColor#"/>,
                        fonte_cards = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveCardFont#"/>,
                        raio_cards = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveCardRadius#"/>,
                        status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveStatus#"/>,
                        versao = versao + 1,
                        atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,
                        data_atualizacao = now()
                    WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agendaSaveId#"/>
                </cfquery>
                <cflocation addtoken="false" url="./?agenda_id=#VARIABLES.agendaSaveId#&sucesso=salva"/>
            </cfif>
        <cfelse>
            <cfset VARIABLES.agendaSavePublicKey = agendaServiceCreatePublicKey()/>
            <cfset VARIABLES.agendaSaveRawToken = agendaServiceCreateToken()/>
            <cftransaction>
                <cfquery name="qAgendaSaveInsert">
                    INSERT INTO tb_agendas
                        (chave_publica, nome, descricao, id_usuario, modo, visao_padrao, dominio_permitido,
                         permitir_subdominios, limite_eventos, ordenacao, tema_embed, cor_card_data, fonte_cards, raio_cards,
                         status, criado_por, atualizado_por)
                    VALUES (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSavePublicKey#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveName#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agendaSaveDescription#" null="#NOT len(VARIABLES.agendaSaveDescription)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaSaveOwnerId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveMode#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveView#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveHost#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.agendaSaveSubdomains#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaSaveLimit#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveOrder#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveTheme#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveDateColor#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveCardFont#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveCardRadius#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaSaveStatus#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                    )
                    RETURNING id_agenda
                </cfquery>
                <cfquery>
                    INSERT INTO tb_agenda_credenciais (id_agenda, token_prefixo, token_hash, criado_por)
                    VALUES (
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaSaveInsert.id_agenda#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(VARIABLES.agendaSaveRawToken, 12)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_char" value="#lCase(hash(VARIABLES.agendaSaveRawToken, 'SHA-256'))#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                    )
                </cfquery>
            </cftransaction>
            <cfset SESSION.agendaManagementFeedToken = {agendaId=qAgendaSaveInsert.id_agenda, token=VARIABLES.agendaSaveRawToken}/>
            <cflocation addtoken="false" url="./?agenda_id=#qAgendaSaveInsert.id_agenda#&sucesso=criada"/>
        </cfif>
    <cfelseif FORM.acao EQ "alterar_status" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id)>
        <cfset VARIABLES.agendaStatusValue = isDefined("FORM.status") AND listFindNoCase("rascunho,ativa,pausada,arquivada", FORM.status) ? lCase(FORM.status) : "pausada"/>
        <cfquery>
            UPDATE tb_agendas SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaStatusValue#"/>, versao = versao + 1,
                atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>, data_atualizacao = now()
            WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=status"/>
    <cfelseif FORM.acao EQ "adicionar_eventos" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id) AND isDefined("FORM.evento_ids")>
        <cfset VARIABLES.agendaAddEventIds = reReplace(FORM.evento_ids, "[^0-9,]", "", "all")/>
        <cfif len(VARIABLES.agendaAddEventIds)>
            <cfquery>
                INSERT INTO tb_agenda_eventos (id_agenda, id_evento, ordem, adicionado_por)
                SELECT <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>, evt.id_evento,
                       coalesce((SELECT max(ordem) FROM tb_agenda_eventos WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>), 0)
                           + (row_number() OVER (ORDER BY evt.data_inicial, evt.id_evento) * 10)::integer,
                       <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                FROM tb_evento_corridas evt
                WHERE evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaAddEventIds#" list="true"/>)
                  AND evt.ativo = true
                ON CONFLICT (id_agenda, id_evento) DO NOTHING
            </cfquery>
            <cfquery>
                UPDATE tb_agendas SET versao = versao + 1, atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>, data_atualizacao = now()
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
            </cfquery>
        </cfif>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=eventos"/>
    <cfelseif FORM.acao EQ "remover_evento" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id) AND isDefined("FORM.id_evento") AND isNumeric(FORM.id_evento)>
        <cfquery>
            DELETE FROM tb_agenda_eventos
            WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
              AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>
        <cfquery>
            UPDATE tb_agendas SET versao = versao + 1, atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>, data_atualizacao = now()
            WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=evento_removido"/>
    <cfelseif FORM.acao EQ "mover_evento" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id) AND isDefined("FORM.id_evento") AND isNumeric(FORM.id_evento)>
        <cfset VARIABLES.agendaMoveDirection = isDefined("FORM.direcao") AND FORM.direcao EQ "baixo" ? "baixo" : "cima"/>
        <cftransaction>
            <cfquery name="qAgendaMoveCurrent">
                SELECT id_agenda_evento, ordem FROM tb_agenda_eventos
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/> AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                FOR UPDATE
            </cfquery>
            <cfif qAgendaMoveCurrent.recordcount>
                <cfquery name="qAgendaMoveNeighbor">
                    SELECT id_agenda_evento, ordem FROM tb_agenda_eventos
                    WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
                      AND ordem <cfif VARIABLES.agendaMoveDirection EQ "baixo">&gt;<cfelse>&lt;</cfif> <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgendaMoveCurrent.ordem#"/>
                    ORDER BY ordem <cfif VARIABLES.agendaMoveDirection EQ "baixo">ASC<cfelse>DESC</cfif>, id_agenda_evento <cfif VARIABLES.agendaMoveDirection EQ "baixo">ASC<cfelse>DESC</cfif>
                    LIMIT 1 FOR UPDATE
                </cfquery>
                <cfif qAgendaMoveNeighbor.recordcount>
                    <cfquery>
                        UPDATE tb_agenda_eventos
                        SET ordem = CASE
                            WHEN id_agenda_evento = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaMoveCurrent.id_agenda_evento#"/> THEN <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgendaMoveNeighbor.ordem#"/>
                            WHEN id_agenda_evento = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaMoveNeighbor.id_agenda_evento#"/> THEN <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgendaMoveCurrent.ordem#"/>
                        END
                        WHERE id_agenda_evento IN (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaMoveCurrent.id_agenda_evento#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaMoveNeighbor.id_agenda_evento#"/>
                        )
                    </cfquery>
                </cfif>
            </cfif>
        </cftransaction>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=evento_movido"/>
    <cfelseif FORM.acao EQ "adicionar_filtro" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id)>
        <cfset VARIABLES.agendaFilterField = isDefined("FORM.campo") AND listFindNoCase("estado,cidade,distancia,tipo,agregador", FORM.campo) ? lCase(FORM.campo) : ""/>
        <cfset VARIABLES.agendaFilterText = isDefined("FORM.valor_texto") ? trim(FORM.valor_texto) : ""/>
        <cfset VARIABLES.agendaFilterNumber = isDefined("FORM.valor_numero") AND isNumeric(replace(FORM.valor_numero, ",", ".")) ? val(replace(FORM.valor_numero, ",", ".")) : 0/>
        <cfset VARIABLES.agendaFilterId = isDefined("FORM.valor_id") AND isNumeric(FORM.valor_id) ? val(FORM.valor_id) : 0/>
        <cfset VARIABLES.agendaFilterValid = len(VARIABLES.agendaFilterField)/>
        <cfif VARIABLES.agendaFilterField EQ "estado"><cfset VARIABLES.agendaFilterText = uCase(left(VARIABLES.agendaFilterText, 2))/><cfset VARIABLES.agendaFilterValid = len(VARIABLES.agendaFilterText) EQ 2/></cfif>
        <cfif listFindNoCase("cidade,tipo", VARIABLES.agendaFilterField)><cfset VARIABLES.agendaFilterValid = len(VARIABLES.agendaFilterText) GT 0/></cfif>
        <cfif VARIABLES.agendaFilterField EQ "distancia"><cfset VARIABLES.agendaFilterValid = VARIABLES.agendaFilterNumber GT 0/></cfif>
        <cfif VARIABLES.agendaFilterField EQ "agregador">
            <cfset VARIABLES.agendaFilterValid = VARIABLES.agendaFilterId GT 0/>
            <cfif VARIABLES.agendaFilterValid>
                <cfquery name="qAgendaFilterAggregatorExists">
                    SELECT id_agrega_evento FROM tb_agrega_eventos
                    WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaFilterId#"/>
                </cfquery>
                <cfset VARIABLES.agendaFilterValid = qAgendaFilterAggregatorExists.recordcount GT 0/>
            </cfif>
        </cfif>
        <cfif VARIABLES.agendaFilterValid>
            <cfquery>
                INSERT INTO tb_agenda_filtros (id_agenda, campo, valor_texto, valor_numero, valor_id, criado_por)
                VALUES (
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaFilterField#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agendaFilterText#" null="#NOT listFindNoCase('estado,cidade,tipo', VARIABLES.agendaFilterField)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_decimal" scale="3" value="#VARIABLES.agendaFilterNumber#" null="#VARIABLES.agendaFilterField NEQ 'distancia'#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaFilterId#" null="#VARIABLES.agendaFilterField NEQ 'agregador'#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                )
                ON CONFLICT DO NOTHING
            </cfquery>
            <cfquery>
                UPDATE tb_agendas SET versao = versao + 1, atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>, data_atualizacao = now()
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
            </cfquery>
            <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=filtro"/>
        <cfelse>
            <cfset VARIABLES.agendaManagementAlert = {type="warning", message="Informe um valor valido para a regra dinamica."}/>
        </cfif>
    <cfelseif FORM.acao EQ "remover_filtro" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id) AND isDefined("FORM.id_agenda_filtro") AND isNumeric(FORM.id_agenda_filtro)>
        <cfquery>
            DELETE FROM tb_agenda_filtros WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/> AND id_agenda_filtro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.id_agenda_filtro#"/>
        </cfquery>
        <cfquery>
            UPDATE tb_agendas SET versao = versao + 1, atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>, data_atualizacao = now()
            WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=filtro_removido"/>
    <cfelseif FORM.acao EQ "rotacionar_credencial" AND isDefined("FORM.agenda_id") AND isNumeric(FORM.agenda_id)>
        <cfset VARIABLES.agendaRotateToken = agendaServiceCreateToken()/>
        <cftransaction>
            <cfquery>
                UPDATE tb_agenda_credenciais SET ativa = false, data_revogacao = now()
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/> AND ativa = true
            </cfquery>
            <cfquery>
                INSERT INTO tb_agenda_credenciais (id_agenda, token_prefixo, token_hash, criado_por)
                VALUES (
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.agenda_id#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(VARIABLES.agendaRotateToken, 12)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_char" value="#lCase(hash(VARIABLES.agendaRotateToken, 'SHA-256'))#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                )
            </cfquery>
        </cftransaction>
        <cfset SESSION.agendaManagementFeedToken = {agendaId=FORM.agenda_id, token=VARIABLES.agendaRotateToken}/>
        <cflocation addtoken="false" url="./?agenda_id=#FORM.agenda_id#&sucesso=credencial"/>
    </cfif>

    <cfquery name="qAgendaManagementStats">
        SELECT count(*) AS total,
               count(*) FILTER (WHERE status = 'ativa') AS ativas,
               count(*) FILTER (WHERE modo = 'manual') AS manuais,
               count(*) FILTER (WHERE modo = 'dinamica') AS dinamicas,
               (
                   SELECT count(*)
                   FROM tb_agenda_acessos ace
                   WHERE ace.data_acesso >= now() - interval '30 days'
                   <cfif NOT VARIABLES.agendaManagementCanManageAll>
                       AND EXISTS (
                           SELECT 1
                           FROM tb_agendas access_agenda
                           WHERE access_agenda.id_agenda = ace.id_agenda
                             AND access_agenda.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaManagementActorId#"/>
                       )
                   </cfif>
               ) AS acessos_30d
        FROM tb_agendas agd
        WHERE 1 = 1
        <cfif NOT VARIABLES.agendaManagementCanManageAll>
            AND agd.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaManagementActorId#"/>
        </cfif>
    </cfquery>

    <cfquery name="qAgendaManagementList">
        SELECT agd.id_agenda, agd.chave_publica, agd.nome, agd.id_usuario, usr.name AS usuario_nome, usr.email AS usuario_email,
               agd.modo, agd.visao_padrao, agd.dominio_permitido, agd.permitir_subdominios, agd.limite_eventos,
               agd.ordenacao, agd.tema_embed, agd.cor_card_data, agd.fonte_cards, agd.raio_cards,
               agd.status, agd.versao, agd.data_criacao, agd.data_atualizacao,
               (SELECT count(*) FROM tb_agenda_eventos aev WHERE aev.id_agenda = agd.id_agenda) AS total_eventos,
               (SELECT count(*) FROM tb_agenda_filtros fil WHERE fil.id_agenda = agd.id_agenda) AS total_filtros,
               (SELECT count(*) FROM tb_agenda_acessos ace WHERE ace.id_agenda = agd.id_agenda) AS total_acessos,
               (SELECT max(ace.data_acesso) FROM tb_agenda_acessos ace WHERE ace.id_agenda = agd.id_agenda) AS ultimo_acesso
        FROM tb_agendas agd
        INNER JOIN tb_usuarios usr ON usr.id = agd.id_usuario
        WHERE 1 = 1
        <cfif NOT VARIABLES.agendaManagementCanManageAll>
            AND agd.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaManagementActorId#"/>
        </cfif>
        ORDER BY agd.data_atualizacao DESC, agd.id_agenda DESC
        LIMIT 200
    </cfquery>

    <cfif VARIABLES.agendaManagementCanManageAll AND len(trim(URL.owner_search))>
        <cfset VARIABLES.agendaOwnerSearchTerm = trim(URL.owner_search)/>
        <cfquery name="qAgendaManagementOwnerSearch">
            SELECT usr.id, usr.name, usr.email
            FROM tb_usuarios usr
            WHERE
                <cfif isNumeric(VARIABLES.agendaOwnerSearchTerm)>usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agendaOwnerSearchTerm#"/> OR</cfif>
                unaccent(lower(coalesce(usr.name, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agendaOwnerSearchTerm#%"/>))
                OR unaccent(lower(coalesce(usr.email, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agendaOwnerSearchTerm#%"/>))
            ORDER BY usr.name, usr.email
            LIMIT 30
        </cfquery>
    <cfelseif VARIABLES.agendaManagementCanManageAll AND FORM.acao EQ "salvar_agenda" AND isDefined("FORM.id_usuario") AND isNumeric(FORM.id_usuario)>
        <cfquery name="qAgendaManagementOwnerSearch">
            SELECT usr.id, usr.name, usr.email
            FROM tb_usuarios usr
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_usuario#"/>
        </cfquery>
    </cfif>

    <cfquery name="qAgendaManagementStates">
        SELECT DISTINCT upper(estado) AS estado FROM tb_evento_corridas WHERE nullif(trim(estado), '') IS NOT NULL ORDER BY upper(estado)
    </cfquery>
    <cfquery name="qAgendaManagementTypes">
        SELECT DISTINCT lower(tipo_corrida) AS tipo_corrida FROM tb_evento_corridas WHERE nullif(trim(tipo_corrida), '') IS NOT NULL ORDER BY lower(tipo_corrida)
    </cfquery>

    <cfif VARIABLES.agendaManagementSelectedId GT 0>
        <cfset qAgendaManagementEdit = agendaServiceGetAgendaById(VARIABLES.agendaManagementSelectedId)/>
        <cfif qAgendaManagementEdit.recordcount
            AND NOT VARIABLES.agendaManagementCanManageAll
            AND val(agendaServiceQueryValue(qAgendaManagementEdit, "id_usuario", 1)) NEQ VARIABLES.agendaManagementActorId>
            <cfset qAgendaManagementEdit = queryNew("id_agenda,chave_publica,nome,descricao,id_usuario,usuario_nome,usuario_email,modo,visao_padrao,dominio_permitido,permitir_subdominios,limite_eventos,ordenacao,tema_embed,cor_card_data,fonte_cards,raio_cards,status,versao,data_criacao,data_atualizacao")/>
        </cfif>
        <cfif qAgendaManagementEdit.recordcount>
            <cfset VARIABLES.agendaManagementPreviewView = agendaServiceNormalizeView(URL.preview_visao, "futuros")/>
            <cfset qAgendaManagementPreview = agendaServiceResolveEvents(qAgendaManagementEdit.id_agenda, VARIABLES.agendaManagementPreviewView, qAgendaManagementEdit.limite_eventos)/>

            <cfquery name="qAgendaManagementSelectedEvents">
                SELECT aev.id_agenda_evento, aev.id_evento, aev.ordem, evt.nome_evento, evt.tag, evt.cidade, evt.estado,
                       evt.data_inicial, evt.data_final, evt.tipo_corrida, evt.url_resultado
                FROM tb_agenda_eventos aev INNER JOIN tb_evento_corridas evt ON evt.id_evento = aev.id_evento
                WHERE aev.id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaManagementEdit.id_agenda#"/>
                ORDER BY aev.ordem, aev.id_agenda_evento
            </cfquery>

            <cfquery name="qAgendaManagementFilters">
                SELECT fil.id_agenda_filtro, fil.campo, fil.valor_texto, fil.valor_numero, fil.valor_id,
                       CASE fil.campo
                           WHEN 'agregador' THEN coalesce(agr.nome_evento_agregado, 'Agregador ' || fil.valor_id::text)
                           WHEN 'distancia' THEN trim(trailing '.' FROM to_char(fil.valor_numero, 'FM999999990.999')) || ' km'
                           ELSE fil.valor_texto
                       END AS valor_exibicao
                FROM tb_agenda_filtros fil
                LEFT JOIN tb_agrega_eventos agr ON fil.campo = 'agregador' AND agr.id_agrega_evento = fil.valor_id
                WHERE fil.id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaManagementEdit.id_agenda#"/>
                ORDER BY fil.campo, valor_exibicao
            </cfquery>

            <cfquery name="qAgendaManagementAccessStats">
                SELECT count(*) AS total,
                       count(*) FILTER (WHERE status_http BETWEEN 200 AND 399) AS permitidos,
                       count(*) FILTER (WHERE status_http >= 400) AS negados,
                       max(data_acesso) AS ultimo_acesso
                FROM tb_agenda_acessos
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaManagementEdit.id_agenda#"/>
            </cfquery>

            <cfquery name="qAgendaManagementRecentAccess">
                SELECT formato, visao, dominio_requisitante, endereco_ip, status_http, eventos_retornados, duracao_ms, data_acesso
                FROM tb_agenda_acessos
                WHERE id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaManagementEdit.id_agenda#"/>
                ORDER BY data_acesso DESC, id_agenda_acesso DESC
                LIMIT 25
            </cfquery>

            <cfif len(trim(URL.agregador_filtro_busca))>
                <cfquery name="qAgendaManagementAggregatorSearch">
                    SELECT id_agrega_evento, nome_evento_agregado, tipo_agregacao
                    FROM tb_agrega_eventos
                    WHERE
                        <cfif isNumeric(URL.agregador_filtro_busca)>id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.agregador_filtro_busca#"/> OR</cfif>
                        unaccent(lower(nome_evento_agregado)) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.agregador_filtro_busca)#%"/>))
                    ORDER BY nome_evento_agregado
                    LIMIT 40
                </cfquery>
            </cfif>

            <cfif len(trim(URL.buscar_eventos))>
                <cfquery name="qAgendaManagementEventSearch">
                    SELECT evt.id_evento, evt.nome_evento, evt.tag, evt.cidade, evt.estado, evt.pais, evt.data_inicial, evt.data_final,
                           evt.tipo_corrida, evt.url_resultado, agr.nome_evento_agregado AS agregador_nome,
                           coalesce((SELECT string_agg(trim(trailing '.' FROM to_char(pcr.percurso_evento, 'FM999999990.999')) || pcr.unidade_de_medida, ', ' ORDER BY pcr.percurso_evento) FROM tb_evento_corridas_percursos pcr WHERE pcr.id_evento = evt.id_evento), '') AS distancias,
                           EXISTS (SELECT 1 FROM tb_agenda_eventos aev WHERE aev.id_agenda = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgendaManagementEdit.id_agenda#"/> AND aev.id_evento = evt.id_evento) AS ja_adicionado
                    FROM tb_evento_corridas evt
                    LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
                    WHERE evt.ativo = true AND nullif(trim(evt.tag), '') IS NOT NULL
                      AND lower(trim(coalesce(evt.status_evento, ''))) <> 'cancelado'
                    <cfif len(trim(URL.evento_busca))>
                        AND (<cfif isNumeric(URL.evento_busca)>evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.evento_busca#"/> OR</cfif>
                            unaccent(lower(evt.nome_evento)) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.evento_busca)#%"/>))
                            OR unaccent(lower(coalesce(evt.tag, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.evento_busca)#%"/>)))
                    </cfif>
                    <cfif len(trim(URL.evento_agregador))>
                        AND (<cfif isNumeric(URL.evento_agregador)>evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.evento_agregador#"/> OR</cfif>
                            unaccent(lower(coalesce(agr.nome_evento_agregado, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.evento_agregador)#%"/>)))
                    </cfif>
                    <cfif len(trim(URL.evento_estado))>AND upper(evt.estado) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.evento_estado)#"/></cfif>
                    <cfif len(trim(URL.evento_cidade))>AND unaccent(lower(coalesce(evt.cidade, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.evento_cidade)#%"/>))</cfif>
                    <cfif len(trim(URL.evento_tipo))>AND lower(evt.tipo_corrida) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(URL.evento_tipo)#"/></cfif>
                    <cfif isNumeric(replace(URL.evento_distancia, ',', '.')) AND val(replace(URL.evento_distancia, ',', '.')) GT 0>
                        AND EXISTS (SELECT 1 FROM tb_evento_corridas_percursos pcr WHERE pcr.id_evento = evt.id_evento AND round((CASE WHEN lower(pcr.unidade_de_medida) IN ('m','metro','metros') THEN pcr.percurso_evento / 1000.0 WHEN lower(pcr.unidade_de_medida) IN ('mi','milha','milhas') THEN pcr.percurso_evento * 1.609344 ELSE pcr.percurso_evento END)::numeric, 3) = <cfqueryparam cfsqltype="cf_sql_decimal" scale="3" value="#val(replace(URL.evento_distancia, ',', '.'))#"/>)
                    </cfif>
                    <cfif URL.evento_visao EQ "futuros">AND evt.data_final >= current_date
                    <cfelseif URL.evento_visao EQ "resultados">AND evt.data_final < current_date AND (nullif(trim(evt.url_resultado), '') IS NOT NULL OR EXISTS (SELECT 1 FROM tb_resultados_resumo res WHERE res.id_evento = evt.id_evento))</cfif>
                    ORDER BY CASE WHEN evt.data_final >= current_date THEN 0 ELSE 1 END,
                             CASE WHEN evt.data_final >= current_date THEN evt.data_final END ASC,
                             CASE WHEN evt.data_final < current_date THEN evt.data_final END DESC,
                             evt.nome_evento
                    LIMIT 60
                </cfquery>
            </cfif>
        </cfif>
    </cfif>
</cfif>
