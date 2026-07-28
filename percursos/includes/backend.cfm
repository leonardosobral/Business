<cfset VARIABLES.percursoLocalConfig={}/>
<cfset VARIABLES.percursoLocalConfigPath=expandPath("/config/percursos.local.cfm")/>
<cfif fileExists(VARIABLES.percursoLocalConfigPath)>
    <cfinclude template="../../config/percursos.local.cfm"/>
    <cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig)>
        <cfset VARIABLES.percursoLocalConfig=duplicate(percursoLocalConfig)/>
    </cfif>
</cfif>

<cfscript>
function percursoBoolean(required any value) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,t,yes,sim,on", trim(arguments.value & "")) GT 0;
}
function percursoTablesReady() {
    try {
        var check = queryExecute("SELECT to_regclass('public.tb_percursos') IS NOT NULL AND to_regclass('public.tb_percurso_arquivos') IS NOT NULL AND to_regclass('public.tb_percurso_historico') IS NOT NULL AS ready");
        return check.recordCount AND percursoBoolean(check.ready[1]);
    } catch (any ignored) { return false; }
}
function percursoEventLinksTableReady() {
    try {
        var check = queryExecute("SELECT to_regclass('public.tb_evento_percursos_gpx') IS NOT NULL AS ready");
        return check.recordCount AND percursoBoolean(check.ready[1]);
    } catch (any ignored) { return false; }
}
function percursoHasEventRouteColumn() {
    try {
        var check = queryExecute("SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_percursos_gpx' AND column_name='id_evento_percurso') AS ready");
        return check.recordCount AND percursoBoolean(check.ready[1]);
    } catch (any ignored) { return false; }
}
function percursoStravaMigrationTableReady() {
    try {
        var check = queryExecute("SELECT to_regclass('public.tb_percurso_migracoes_strava') IS NOT NULL AS ready");
        return check.recordCount AND percursoBoolean(check.ready[1]);
    } catch (any ignored) { return false; }
}
function percursoStorageRoot() {
    var configured = "";
    try { configured = trim(createObject("java", "java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & ""); } catch (any ignored) {}
    if (len(configured)) return configured;
    if (structKeyExists(VARIABLES.percursoLocalConfig, "storagePath") AND len(trim(VARIABLES.percursoLocalConfig.storagePath & ""))) {
        return trim(VARIABLES.percursoLocalConfig.storagePath & "");
    }
    return getTempDirectory() & "business-percursos-storage";
}
function percursoAudit(required numeric routeId, numeric fileId=0, required string action, struct data={}) {
    queryExecute(
        "INSERT INTO tb_percurso_historico (id_percurso,id_percurso_arquivo,id_usuario,acao,dados,endereco_ip) VALUES (:routeId,:fileId,:actor,:action,CAST(:data AS jsonb),:ip)",
        {routeId={value=arguments.routeId,cfsqltype="cf_sql_bigint"}, fileId={value=arguments.fileId,cfsqltype="cf_sql_bigint",null=arguments.fileId LTE 0}, actor={value=VARIABLES.percursoActorId,cfsqltype="cf_sql_bigint"}, action={value=arguments.action,cfsqltype="cf_sql_varchar"}, data={value=serializeJSON(arguments.data),cfsqltype="cf_sql_varchar"}, ip={value=cgi.remote_addr,cfsqltype="cf_sql_varchar"}}
    );
}
</cfscript>

<cfparam name="URL.id" default=""/>
<cfparam name="URL.novo" default=""/>
<cfparam name="URL.q" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.evento_busca" default=""/>
<cfparam name="URL.sucesso" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.percursoSchemaReady = percursoTablesReady()/>
<cfset VARIABLES.percursoEventLinksReady = percursoEventLinksTableReady()/>
<cfset VARIABLES.percursoEventRouteColumnReady = VARIABLES.percursoEventLinksReady AND percursoHasEventRouteColumn()/>
<cfset VARIABLES.percursoStravaMigrationReady = percursoStravaMigrationTableReady()/>
<cfset VARIABLES.percursoAlert = {type="", message=""}/>
<cfset VARIABLES.percursoActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.percursoIsAdmin = isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.percursoIsSystemAdmin = isDefined("qPerfil")
    AND qPerfil.recordcount
    AND listFindNoCase(qPerfil.columnList, "is_admin")
    AND percursoBoolean(qPerfil.is_admin)/>
<cfset VARIABLES.percursoIsDev = isDefined("qPerfil")
    AND qPerfil.recordcount
    AND listFindNoCase(qPerfil.columnList, "is_dev")
    AND percursoBoolean(qPerfil.is_dev)/>
<cfset VARIABLES.percursoCanViewAll = VARIABLES.percursoIsSystemAdmin OR VARIABLES.percursoIsDev/>
<cfset VARIABLES.percursoAccountIds = isDefined("VARIABLES.businessEffectiveAccountIds") ? VARIABLES.businessEffectiveAccountIds : "0"/>
<cfset VARIABLES.percursoManagerAccountIds = isDefined("VARIABLES.businessEffectiveAccountManagerIds") ? VARIABLES.businessEffectiveAccountManagerIds : "0"/>
<cfset VARIABLES.percursoWriteAccountIds = isDefined("VARIABLES.businessEffectiveAccountOperatorIds") ? VARIABLES.businessEffectiveAccountOperatorIds : "0"/>
<cfset VARIABLES.percursoActiveAccountId = isDefined("VARIABLES.businessActiveAccountId") AND isNumeric(VARIABLES.businessActiveAccountId) ? val(VARIABLES.businessActiveAccountId) : 0/>
<cfset VARIABLES.percursoCanWrite = VARIABLES.percursoIsAdmin OR (len(trim(VARIABLES.percursoWriteAccountIds)) AND VARIABLES.percursoWriteAccountIds NEQ "0")/>
<cfset VARIABLES.percursoCanCreate = VARIABLES.percursoActiveAccountId GT 0
    AND VARIABLES.percursoWriteAccountIds NEQ "0"
    AND listFind(VARIABLES.percursoWriteAccountIds, VARIABLES.percursoActiveAccountId)/>
<cfset VARIABLES.percursoSelectedId = isNumeric(URL.id) ? val(URL.id) : 0/>
<cfset VARIABLES.percursoIsLegacyCreator = false/>
<cfset VARIABLES.percursoCanViewAudit = false/>
<cfset VARIABLES.percursoCanManageRouteEventLinks = false/>
<cfset VARIABLES.percursoCanManageEventLinks = false/>
<cfset VARIABLES.percursoCanLinkEvents = false/>
<cfset VARIABLES.percursoStoragePath = percursoStorageRoot()/>
<cfset VARIABLES.percursoStorageConfigured = false/>
<cftry><cfset VARIABLES.percursoStorageConfigured = len(trim(createObject("java", "java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")) GT 0/><cfcatch type="any"></cfcatch></cftry>
<cfif NOT VARIABLES.percursoStorageConfigured AND structKeyExists(VARIABLES.percursoLocalConfig,"storagePath") AND len(trim(VARIABLES.percursoLocalConfig.storagePath & ""))><cfset VARIABLES.percursoStorageConfigured=true/></cfif>
<cfset VARIABLES.percursoStorageReady=false/>
<cfset VARIABLES.percursoStorageError=""/>
<cfset VARIABLES.percursoMapboxPublicToken=""/>
<cfset VARIABLES.percursoMapboxServerToken=""/>
<cfset VARIABLES.percursoElevationMaxSamples=2000/>
<cftry>
    <cfset VARIABLES.percursoMapboxPublicToken=trim(createObject("java","java.lang.System").getenv("BUSINESS_MAPBOX_PUBLIC_TOKEN") & "")/>
    <cfset VARIABLES.percursoMapboxServerToken=trim(createObject("java","java.lang.System").getenv("BUSINESS_MAPBOX_SERVER_TOKEN") & "")/>
    <cfcatch type="any"></cfcatch>
</cftry>
<cfif NOT len(VARIABLES.percursoMapboxPublicToken)>
    <cftry><cfset VARIABLES.percursoMapboxPublicToken=trim(createObject("java","java.lang.System").getenv("MAPBOX_ACCESS_TOKEN") & "")/><cfcatch type="any"></cfcatch></cftry>
</cfif>
<cfif NOT len(VARIABLES.percursoMapboxPublicToken)
    AND structKeyExists(VARIABLES.percursoLocalConfig,"mapboxPublicAccessToken")>
    <cfset VARIABLES.percursoMapboxPublicToken=trim(VARIABLES.percursoLocalConfig.mapboxPublicAccessToken & "")/>
</cfif>
<cfif NOT len(VARIABLES.percursoMapboxServerToken)
    AND structKeyExists(VARIABLES.percursoLocalConfig,"mapboxServerAccessToken")>
    <cfset VARIABLES.percursoMapboxServerToken=trim(VARIABLES.percursoLocalConfig.mapboxServerAccessToken & "")/>
</cfif>
<cfif structKeyExists(VARIABLES.percursoLocalConfig,"elevationMaxSamples")
    AND isNumeric(VARIABLES.percursoLocalConfig.elevationMaxSamples)>
    <cfset VARIABLES.percursoElevationMaxSamples=min(5000,max(2,int(VARIABLES.percursoLocalConfig.elevationMaxSamples)))/>
</cfif>
<cfset VARIABLES.percursoMapboxPreviewConfigured=len(VARIABLES.percursoMapboxPublicToken) GT 0/>
<cfset VARIABLES.percursoElevationConfigured=len(VARIABLES.percursoMapboxServerToken) GT 0
    AND left(VARIABLES.percursoMapboxServerToken,3) EQ "sk."/>
<cftry>
    <cfif NOT directoryExists(VARIABLES.percursoStoragePath)><cfdirectory action="create" directory="#VARIABLES.percursoStoragePath#" recurse="true"/></cfif>
    <cfset VARIABLES.percursoStorageReady=createObject("java","java.io.File").init(VARIABLES.percursoStoragePath).canWrite()/>
    <cfif NOT VARIABLES.percursoStorageReady><cfset VARIABLES.percursoStorageError="O ColdFusion nao possui permissao de escrita no diretorio configurado."/></cfif>
    <cfcatch type="any"><cfset VARIABLES.percursoStorageReady=false/><cfset VARIABLES.percursoStorageError=cfcatch.message/></cfcatch>
</cftry>
<cfset VARIABLES.percursoCanWrite = VARIABLES.percursoCanWrite AND VARIABLES.percursoStorageReady/>
<cfset VARIABLES.percursoCanCreate = VARIABLES.percursoCanCreate AND VARIABLES.percursoStorageReady/>
<cfset qPercursos = queryNew("id_percurso,codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,visibilidade,status,id_usuario_criador,id_conta_responsavel,conta_proprietaria,criado_em,atualizado_em,versao,distancia_gpx_m,quantidade_pontos")/>
<cfset qPercurso = queryNew("id_percurso,codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,descricao,visibilidade,status,id_usuario_criador,id_conta_responsavel,criado_em,atualizado_em")/>
<cfset qPercursoArquivos = queryNew("id_percurso_arquivo,versao,nome_original,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,criado_em")/>
<cfset qPercursoHistorico = queryNew("acao,dados,endereco_ip,criado_em,usuario_nome")/>
<cfset qPercursoOwner = queryNew("id,name,email")/>
<cfset qPercursoConta = queryNew("id_conta,nome_conta,status")/>
<cfset qPercursoContasTransferencia = queryNew("id_conta,nome_conta,status")/>
<cfset qPercursoEventos = queryNew("id_evento_percurso_gpx,id_evento,id_evento_percurso,percurso_evento,unidade_de_medida,nome_evento,tag,data_inicial,data_final,cidade,estado,contas,conta_pode_gerenciar")/>
<cfset qPercursoEventSearch = queryNew("id_evento_percurso,id_evento,percurso_evento,unidade_de_medida,tipo_corrida,nome_evento,tag,data_inicial,data_final,cidade,estado,contas,id_percurso_vinculado,nome_percurso_vinculado")/>
<cfset qPercursosVinculos = queryNew("id_percurso,id_evento,id_evento_percurso,nome_evento,percurso_evento,unidade_de_medida")/>
<cfset VARIABLES.percursoListEventLinks = {}/>

<cfif NOT structKeyExists(SESSION, "percursoCsrfToken") OR NOT len(trim(SESSION.percursoCsrfToken & ""))>
    <cfset SESSION.percursoCsrfToken = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.percursoCsrfToken = SESSION.percursoCsrfToken/>

<cfif URL.sucesso EQ "criado"><cfset VARIABLES.percursoAlert={type="success",message="Percurso criado e arquivo processado com sucesso."}/></cfif>
<cfif URL.sucesso EQ "salvo"><cfset VARIABLES.percursoAlert={type="success",message="Dados do percurso atualizados."}/></cfif>
<cfif URL.sucesso EQ "versao"><cfset VARIABLES.percursoAlert={type="success",message="Nova versao do percurso adicionada."}/></cfif>
<cfif URL.sucesso EQ "versao_restaurada"><cfset VARIABLES.percursoAlert={type="success",message="A versao selecionada foi restaurada como uma nova versao atual."}/></cfif>
<cfif URL.sucesso EQ "versao_excluida"><cfset VARIABLES.percursoAlert={type="success",message="A versao foi excluida do percurso. Os arquivos permanecem preservados no storage e na auditoria."}/></cfif>
<cfif URL.sucesso EQ "altimetria"><cfset VARIABLES.percursoAlert={type="success",message="Altimetria gerada com o Mapbox Terrain-RGB. Uma nova versao do percurso foi criada e o arquivo anterior permanece preservado."}/></cfif>
<cfif URL.sucesso EQ "status"><cfset VARIABLES.percursoAlert={type="success",message="Status do percurso atualizado."}/></cfif>
<cfif URL.sucesso EQ "conta_proprietaria"><cfset VARIABLES.percursoAlert={type="success",message="Conta proprietaria do percurso atualizada."}/></cfif>
<cfif URL.sucesso EQ "evento_vinculado"><cfset VARIABLES.percursoAlert={type="success",message="Arquivo vinculado ao percurso do evento. Os membros das contas associadas ja podem visualiza-lo."}/></cfif>
<cfif URL.sucesso EQ "evento_substituido"><cfset VARIABLES.percursoAlert={type="success",message="O arquivo anteriormente vinculado ao percurso do evento foi substituido com sucesso."}/></cfif>
<cfif URL.sucesso EQ "evento_desvinculado"><cfset VARIABLES.percursoAlert={type="success",message="Vinculo com o percurso do evento removido."}/></cfif>

<cfif VARIABLES.percursoSchemaReady AND len(trim(FORM.acao))>
    <cfif compareNoCase(trim(FORM.csrf_token), VARIABLES.percursoCsrfToken) NEQ 0>
        <cfset VARIABLES.percursoAlert={type="danger",message="A sessao do formulario expirou. Recarregue a pagina."}/>
    <cfelseif FORM.acao EQ "alterar_conta_proprietaria">
        <cfif NOT VARIABLES.percursoIsSystemAdmin>
            <cfset VARIABLES.percursoAlert={type="danger",message="Somente ADMINs do sistema podem alterar a conta proprietaria de um percurso."}/>
        <cfelse>
            <cfset VARIABLES.ownerRouteId = isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
            <cfset VARIABLES.ownerAccountId = isDefined("FORM.id_conta_responsavel") AND isNumeric(FORM.id_conta_responsavel) ? val(FORM.id_conta_responsavel) : 0/>
            <cfquery name="qPercursoOwnerChangeCheck">
                SELECT percurso.id_percurso,
                       percurso.id_conta_responsavel AS id_conta_anterior,
                       conta.id_conta AS id_conta_nova
                FROM tb_percursos percurso
                LEFT JOIN tb_contas conta
                    ON conta.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerAccountId#"/>
                   AND conta.status = 'ATIVA'::status_conta
                WHERE percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerRouteId#"/>
                LIMIT 1
            </cfquery>

            <cfif VARIABLES.ownerRouteId LTE 0
                OR VARIABLES.ownerAccountId LTE 0
                OR NOT qPercursoOwnerChangeCheck.recordcount
                OR NOT len(qPercursoOwnerChangeCheck.id_conta_nova & "")>
                <cfset VARIABLES.percursoAlert={type="danger",message="Selecione uma conta ativa valida para receber o percurso."}/>
            <cfelseif len(qPercursoOwnerChangeCheck.id_conta_anterior & "")
                AND val(qPercursoOwnerChangeCheck.id_conta_anterior) EQ VARIABLES.ownerAccountId>
                <cfset VARIABLES.percursoAlert={type="warning",message="A conta selecionada ja e proprietaria deste percurso."}/>
            <cfelse>
                <cftransaction>
                    <cfquery>
                        UPDATE tb_percursos
                        SET id_conta_responsavel = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerAccountId#"/>,
                            atualizado_em = now()
                        WHERE id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerRouteId#"/>
                    </cfquery>
                    <cfset percursoAudit(VARIABLES.ownerRouteId, 0, "alterar_conta_proprietaria", {
                        id_conta_anterior = len(qPercursoOwnerChangeCheck.id_conta_anterior & "") ? val(qPercursoOwnerChangeCheck.id_conta_anterior) : 0,
                        id_conta_nova = VARIABLES.ownerAccountId
                    })/>
                </cftransaction>
                <cflocation addtoken="false" url="./?id=#VARIABLES.ownerRouteId#&sucesso=conta_proprietaria"/>
            </cfif>
        </cfif>
    <cfelseif listFindNoCase("vincular_evento,desvincular_evento", FORM.acao)>
        <cfset VARIABLES.eventLinkRouteId = isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.eventLinkEventId = isDefined("FORM.id_evento") AND isNumeric(FORM.id_evento) ? val(FORM.id_evento) : 0/>
        <cfset VARIABLES.eventLinkEventRouteId = isDefined("FORM.id_evento_percurso") AND isNumeric(FORM.id_evento_percurso) ? val(FORM.id_evento_percurso) : 0/>

        <cfif NOT VARIABLES.percursoEventLinksReady>
            <cfset VARIABLES.percursoAlert={type="danger",message="A estrutura de vinculos entre eventos e percursos ainda nao foi aplicada no banco."}/>
        <cfelseif VARIABLES.eventLinkRouteId LTE 0 OR VARIABLES.eventLinkEventId LTE 0>
            <cfset VARIABLES.percursoAlert={type="danger",message="Percurso ou evento invalido para o vinculo."}/>
        <cfelseif FORM.acao EQ "vincular_evento" AND (NOT VARIABLES.percursoEventRouteColumnReady OR VARIABLES.eventLinkEventRouteId LTE 0)>
            <cfset VARIABLES.percursoAlert={type="danger",message="Selecione um percurso pre-existente do evento para realizar o vinculo."}/>
        <cfelse>
            <cfquery name="qPercursoEventLinkRouteCheck">
                SELECT percurso.id_percurso,
                       percurso.id_usuario_criador
                FROM tb_percursos percurso
                WHERE percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>
                  AND percurso.id_conta_responsavel IS NOT NULL
                <cfif NOT VARIABLES.percursoIsSystemAdmin>
                    AND (
                        percurso.id_conta_responsavel IN (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                        )
                        <cfif VARIABLES.percursoManagerAccountIds NEQ "0">
                            OR EXISTS (
                                SELECT 1
                                FROM tb_conta_eventos conta_evento
                                INNER JOIN tb_contas conta
                                    ON conta.id_conta = conta_evento.id_conta
                                   AND conta.status = 'ATIVA'::status_conta
                                WHERE conta_evento.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>
                                  AND conta_evento.id_conta IN (
                                      <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoManagerAccountIds#" list="true"/>
                                  )
                                  AND conta_evento.status = 'ATIVO'::status_conta_evento
                            )
                        </cfif>
                    )
                </cfif>
                LIMIT 1
            </cfquery>

            <cfif NOT qPercursoEventLinkRouteCheck.recordcount>
                <cfset VARIABLES.percursoAlert={type="danger",message="Percurso nao encontrado ou sem permissao para gerenciar seus eventos."}/>
            <cfelseif FORM.acao EQ "vincular_evento">
                <cfset VARIABLES.eventLinkConfirmedReplacement = isDefined("FORM.confirmar_substituicao") AND percursoBoolean(FORM.confirmar_substituicao)/>
                <cfset VARIABLES.eventLinkSuccess = ""/>
                <cftransaction>
                    <cfquery name="qPercursoEventLinkEventCheck">
                        SELECT modalidade.id_evento_percurso,
                               modalidade.id_evento,
                               modalidade.percurso_evento,
                               modalidade.unidade_de_medida,
                               vinculo.id_evento_percurso_gpx,
                               vinculo.id_percurso AS id_percurso_vinculado
                        FROM tb_evento_corridas_percursos modalidade
                        INNER JOIN tb_evento_corridas evento
                            ON evento.id_evento = modalidade.id_evento
                        LEFT JOIN tb_evento_percursos_gpx vinculo
                            ON vinculo.id_evento_percurso = modalidade.id_evento_percurso
                        WHERE modalidade.id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventRouteId#"/>
                          AND modalidade.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>
                        <cfif NOT VARIABLES.percursoIsSystemAdmin>
                            AND EXISTS (
                                SELECT 1
                                FROM tb_conta_eventos conta_evento
                                INNER JOIN tb_contas conta
                                    ON conta.id_conta = conta_evento.id_conta
                                   AND conta.status = 'ATIVA'::status_conta
                                WHERE conta_evento.id_evento = evento.id_evento
                                  AND conta_evento.id_conta IN (
                                      <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                                  )
                                  AND conta_evento.status = 'ATIVO'::status_conta_evento
                            )
                        </cfif>
                        LIMIT 1
                        FOR UPDATE OF modalidade
                    </cfquery>

                    <cfif NOT qPercursoEventLinkEventCheck.recordcount>
                        <cfset VARIABLES.percursoAlert={type="danger",message="Percurso do evento nao encontrado ou indisponivel para operacao nesta conta."}/>
                    <cfelseif len(qPercursoEventLinkEventCheck.id_percurso_vinculado & "")
                        AND val(qPercursoEventLinkEventCheck.id_percurso_vinculado) EQ VARIABLES.eventLinkRouteId>
                        <cfset VARIABLES.percursoAlert={type="warning",message="Este arquivo ja esta vinculado ao percurso selecionado do evento."}/>
                    <cfelseif len(qPercursoEventLinkEventCheck.id_percurso_vinculado & "")
                        AND NOT VARIABLES.eventLinkConfirmedReplacement>
                        <cfset VARIABLES.percursoAlert={type="danger",message="Este percurso do evento ja possui outro arquivo vinculado. Confirme explicitamente a substituicao para continuar."}/>
                    <cfelseif len(qPercursoEventLinkEventCheck.id_percurso_vinculado & "")>
                        <cfset VARIABLES.eventLinkPreviousRouteId = val(qPercursoEventLinkEventCheck.id_percurso_vinculado)/>
                        <cfquery>
                            UPDATE tb_evento_percursos_gpx
                            SET id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>,
                                id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>,
                                criado_em = now()
                            WHERE id_evento_percurso_gpx = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPercursoEventLinkEventCheck.id_evento_percurso_gpx#"/>
                        </cfquery>
                        <cfset percursoAudit(VARIABLES.eventLinkRouteId, 0, "substituir_vinculo_evento", {
                            id_evento = val(qPercursoEventLinkEventCheck.id_evento),
                            id_evento_percurso = val(qPercursoEventLinkEventCheck.id_evento_percurso),
                            id_percurso_anterior = VARIABLES.eventLinkPreviousRouteId
                        })/>
                        <cfset percursoAudit(VARIABLES.eventLinkPreviousRouteId, 0, "vinculo_evento_substituido", {
                            id_evento = val(qPercursoEventLinkEventCheck.id_evento),
                            id_evento_percurso = val(qPercursoEventLinkEventCheck.id_evento_percurso),
                            id_percurso_novo = VARIABLES.eventLinkRouteId
                        })/>
                        <cfif VARIABLES.percursoStravaMigrationReady>
                            <cfquery>
                                UPDATE tb_percurso_migracoes_strava
                                SET status = 'revisao',
                                    mensagem = 'O arquivo vinculado ao percurso do evento foi substituido manualmente no repositorio.',
                                    id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>,
                                    id_percurso_arquivo = NULL,
                                    id_usuario_ultima_acao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>,
                                    data_atualizacao = now(),
                                    data_conclusao = NULL
                                WHERE id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventRouteId#"/>
                            </cfquery>
                        </cfif>
                        <cfset VARIABLES.eventLinkSuccess = "evento_substituido"/>
                    <cfelse>
                        <cfquery>
                            INSERT INTO tb_evento_percursos_gpx
                                (id_evento, id_evento_percurso, id_percurso, id_usuario_criador)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qPercursoEventLinkEventCheck.id_evento#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qPercursoEventLinkEventCheck.id_evento_percurso#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                            )
                        </cfquery>
                        <cfset percursoAudit(VARIABLES.eventLinkRouteId, 0, "vincular_evento", {
                            id_evento = val(qPercursoEventLinkEventCheck.id_evento),
                            id_evento_percurso = val(qPercursoEventLinkEventCheck.id_evento_percurso)
                        })/>
                        <cfset VARIABLES.eventLinkSuccess = "evento_vinculado"/>
                    </cfif>
                </cftransaction>
                <cfif len(VARIABLES.eventLinkSuccess)>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.eventLinkRouteId#&sucesso=#VARIABLES.eventLinkSuccess#"/>
                </cfif>
            <cfelse>
                <cfquery name="qPercursoEventLinkExists">
                    SELECT id_evento_percurso_gpx
                    FROM tb_evento_percursos_gpx
                    WHERE id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>
                      AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>
                      <cfif VARIABLES.percursoEventRouteColumnReady>
                          <cfif VARIABLES.eventLinkEventRouteId GT 0>
                              AND id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventRouteId#"/>
                          <cfelse>
                              AND id_evento_percurso IS NULL
                          </cfif>
                      </cfif>
                    LIMIT 1
                </cfquery>
                <cfif NOT qPercursoEventLinkExists.recordcount>
                    <cfset VARIABLES.percursoAlert={type="warning",message="O evento informado nao esta vinculado a este percurso."}/>
                <cfelse>
                    <cftransaction>
                        <cfquery>
                            DELETE FROM tb_evento_percursos_gpx
                            WHERE id_evento_percurso_gpx = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPercursoEventLinkExists.id_evento_percurso_gpx#"/>
                        </cfquery>
                        <cfif VARIABLES.percursoStravaMigrationReady AND VARIABLES.eventLinkEventRouteId GT 0>
                            <cfquery>
                                UPDATE tb_percurso_migracoes_strava
                                SET status = 'revisao',
                                    mensagem = 'O vinculo com a modalidade foi removido manualmente no repositorio de percursos.',
                                    id_usuario_ultima_acao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>,
                                    data_atualizacao = now(),
                                    data_conclusao = NULL
                                WHERE id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventRouteId#"/>
                            </cfquery>
                        </cfif>
                        <cfset percursoAudit(VARIABLES.eventLinkRouteId, 0, "desvincular_evento", {
                            id_evento = VARIABLES.eventLinkEventId,
                            id_evento_percurso = VARIABLES.eventLinkEventRouteId
                        })/>
                    </cftransaction>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.eventLinkRouteId#&sucesso=evento_desvinculado"/>
                </cfif>
            </cfif>
        </cfif>
    <cfelseif NOT VARIABLES.percursoCanWrite AND FORM.acao NEQ "gerar_altimetria_mapbox">
        <cfset VARIABLES.percursoAlert={type="danger",message="Sua conta nao possui permissao para alterar percursos."}/>
    <cfelseif FORM.acao EQ "gerar_altimetria_mapbox">
        <cfset VARIABLES.elevationRouteId=isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.elevationFileId=isDefined("FORM.id_percurso_arquivo") AND isNumeric(FORM.id_percurso_arquivo) ? val(FORM.id_percurso_arquivo) : 0/>
        <cfset VARIABLES.elevationDiskDir=""/>
        <cfif NOT VARIABLES.percursoElevationConfigured>
            <cfset VARIABLES.percursoAlert={type="danger",message="Configure no servidor um token secreto Mapbox sk.* com escopo map:read e sem restricao de URL."}/>
        <cfelseif VARIABLES.elevationRouteId LTE 0 OR VARIABLES.elevationFileId LTE 0>
            <cfset VARIABLES.percursoAlert={type="danger",message="Percurso ou versao invalida para gerar altimetria."}/>
        <cfelse>
            <cfquery name="qElevationSource">
                SELECT percurso.id_percurso,
                       percurso.nome,
                       arquivo.id_percurso_arquivo,
                       arquivo.versao,
                       arquivo.storage_key,
                       arquivo.nome_original,
                       arquivo.ganho_elevacao_m,
                       arquivo.elevacao_min_m,
                       arquivo.elevacao_max_m
                FROM tb_percursos percurso
                INNER JOIN tb_percurso_arquivos arquivo
                    ON arquivo.id_percurso = percurso.id_percurso
                WHERE percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationRouteId#"/>
                  AND arquivo.id_percurso_arquivo = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationFileId#"/>
                  AND arquivo.ativo=true
                  AND arquivo.versao = (
                      SELECT max(atual.versao)
                      FROM tb_percurso_arquivos atual
                      WHERE atual.id_percurso = percurso.id_percurso
                        AND atual.ativo=true
                  )
                  <cfif NOT VARIABLES.percursoIsAdmin AND NOT VARIABLES.percursoIsSystemAdmin>
                      AND (
                          percurso.id_conta_responsavel IN (
                              <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                          )
                          OR (
                              percurso.id_conta_responsavel IS NULL
                              AND percurso.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                          )
                      )
                  </cfif>
                LIMIT 1
            </cfquery>
            <cfif NOT qElevationSource.recordcount>
                <cfset VARIABLES.percursoAlert={type="danger",message="A versao atual do percurso nao foi encontrada ou sua conta nao possui permissao para altera-la."}/>
            <cfelseif NOT reFind("^[0-9]+/[0-9]+/[A-Za-z0-9._-]+$", qElevationSource.storage_key & "")>
                <cfset VARIABLES.percursoAlert={type="danger",message="O arquivo desta versao possui uma referencia de armazenamento invalida."}/>
            <cfelse>
                <cfset VARIABLES.elevationSourcePath=VARIABLES.percursoStoragePath & "/" & qElevationSource.storage_key/>
                <cfset VARIABLES.elevationSourceFormat=lCase(listLast(qElevationSource.storage_key & "", "."))/>
                <cfset VARIABLES.elevationStage="validacao_arquivo"/>
                <cfif VARIABLES.elevationSourceFormat EQ "json"><cfset VARIABLES.elevationSourceFormat="geojson"/></cfif>
                <cftry>
                    <cfsetting requesttimeout="240"/>
                    <cfif NOT fileExists(VARIABLES.elevationSourcePath)>
                        <cfthrow message="O arquivo original da versao nao foi encontrado no storage privado."/>
                    </cfif>
                    <cfset VARIABLES.gpxService=createObject("component","percursos.includes.PercursoGpxService")/>
                    <cfset VARIABLES.elevationAnalysis=VARIABLES.gpxService.analyze(VARIABLES.elevationSourcePath,VARIABLES.elevationSourceFormat)/>
                    <cfif NOT VARIABLES.elevationAnalysis.valid>
                        <cfthrow message="#arrayToList(VARIABLES.elevationAnalysis.errors,' ')#"/>
                    </cfif>
                    <cfset VARIABLES.elevationStage="mapbox_terrain_rgb"/>
                    <cfset VARIABLES.elevationEnrichment=VARIABLES.gpxService.enrichElevationFromMapbox(
                        VARIABLES.elevationAnalysis,
                        VARIABLES.percursoMapboxServerToken,
                        VARIABLES.percursoElevationMaxSamples,
                        true
                    )/>
                    <cfif NOT VARIABLES.elevationEnrichment.success>
                        <cfthrow message="#VARIABLES.elevationEnrichment.error#"/>
                    </cfif>
                    <cfset VARIABLES.elevationStage="persistencia"/>
                    <cftransaction>
                        <cfquery name="qElevationRouteLock">
                            SELECT id_percurso
                            FROM tb_percursos
                            WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationRouteId#"/>
                            FOR UPDATE
                        </cfquery>
                        <cfquery name="qElevationNextVersion">
                            SELECT coalesce(max(versao),0)+1 AS versao
                            FROM tb_percurso_arquivos
                            WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationRouteId#"/>
                        </cfquery>
                        <cfif val(qElevationNextVersion.versao) NEQ val(qElevationSource.versao)+1>
                            <cfthrow message="Uma nova versao foi adicionada enquanto a altimetria era processada. Recarregue o percurso e tente novamente."/>
                        </cfif>
                        <cfset VARIABLES.elevationVersion=val(qElevationNextVersion.versao)/>
                        <cfset VARIABLES.elevationRelativeDir=VARIABLES.elevationRouteId & "/" & VARIABLES.elevationVersion/>
                        <cfset VARIABLES.elevationDiskDir=VARIABLES.percursoStoragePath & "/" & VARIABLES.elevationRelativeDir/>
                        <cfdirectory action="create" directory="#VARIABLES.elevationDiskDir#" recurse="true"/>
                        <cfset VARIABLES.elevationGpxKey=VARIABLES.elevationRelativeDir & "/original.gpx"/>
                        <cfset VARIABLES.elevationGeoKey=VARIABLES.elevationRelativeDir & "/route.geojson"/>
                        <cfset VARIABLES.elevationOptimizedKey=VARIABLES.elevationRelativeDir & "/optimized.gpx"/>
                        <cfset VARIABLES.gpxService.writeGpx(VARIABLES.elevationEnrichment.analysis,VARIABLES.percursoStoragePath & "/" & VARIABLES.elevationGpxKey,qElevationSource.nome)/>
                        <cfset VARIABLES.gpxService.writeGeoJson(VARIABLES.elevationEnrichment.analysis,VARIABLES.percursoStoragePath & "/" & VARIABLES.elevationGeoKey)/>
                        <cffile action="copy" source="#VARIABLES.percursoStoragePath#/#VARIABLES.elevationGpxKey#" destination="#VARIABLES.percursoStoragePath#/#VARIABLES.elevationOptimizedKey#"/>
                        <cfset VARIABLES.elevationFinalAnalysis=VARIABLES.gpxService.analyze(VARIABLES.percursoStoragePath & "/" & VARIABLES.elevationGpxKey,"gpx")/>
                        <cfif NOT VARIABLES.elevationFinalAnalysis.valid OR VARIABLES.elevationFinalAnalysis.elevationPointCount LTE 0>
                            <cfthrow message="O GPX enriquecido nao passou na validacao final."/>
                        </cfif>
                        <cfset VARIABLES.elevationFileInfo=getFileInfo(VARIABLES.percursoStoragePath & "/" & VARIABLES.elevationGpxKey)/>
                        <cfquery name="qElevationNewFile">
                            INSERT INTO tb_percurso_arquivos
                                (id_percurso,versao,storage_key,geojson_storage_key,nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,id_usuario_criador)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationRouteId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.elevationVersion#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.elevationGpxKey#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.elevationGeoKey#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#reReplace(reReplace(qElevationSource.nome_original,'\.[^.]+$','','one'),'-altimetria-(google|mapbox)$','','one')#-altimetria-mapbox.gpx"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="application/gpx+xml"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationFileInfo.size#"/>,
                                <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.elevationFinalAnalysis.sha256#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.elevationFinalAnalysis.pointCount#"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.distanceM#" scale="2"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.elevationMin#" scale="2"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.elevationMax#" scale="2"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.elevationGainM#" scale="2"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.minLat#" scale="7"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.minLng#" scale="7"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.maxLat#" scale="7"/>,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.elevationFinalAnalysis.maxLng#" scale="7"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                            )
                            RETURNING id_percurso_arquivo
                        </cfquery>
                        <cfquery>
                            UPDATE tb_percursos
                            SET atualizado_em=now()
                            WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.elevationRouteId#"/>
                        </cfquery>
                        <cfset percursoAudit(
                            VARIABLES.elevationRouteId,
                            qElevationNewFile.id_percurso_arquivo,
                            VARIABLES.elevationAnalysis.elevationPointCount GT 0
                                ? "regerar_altimetria_mapbox"
                                : "gerar_altimetria_mapbox",
                        {
                            versao_origem=val(qElevationSource.versao),
                            id_arquivo_origem=val(qElevationSource.id_percurso_arquivo),
                            versao=VARIABLES.elevationVersion,
                            pontos=VARIABLES.elevationFinalAnalysis.pointCount,
                            pontos_consultados=VARIABLES.elevationEnrichment.sampledPoints,
                            fonte_altimetria="mapbox_terrain_rgb",
                            metodo_altimetria="terrain_rgb_z15_tile_dinamico_suavizacao_5"
                        })/>
                    </cftransaction>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.elevationRouteId#&sucesso=altimetria"/>
                    <cfcatch type="any">
                        <cfset VARIABLES.elevationErrorId=lCase(left(replace(createUUID(),"-","","all"),12))/>
                        <cflog file="business-percursos" type="error" text="Falha #VARIABLES.elevationErrorId# na etapa #VARIABLES.elevationStage# ao gerar altimetria para percurso #VARIABLES.elevationRouteId#, arquivo #VARIABLES.elevationFileId#, usuario #VARIABLES.percursoActorId#: #cfcatch.message# #cfcatch.detail#"/>
                        <cfif len(VARIABLES.elevationDiskDir) AND directoryExists(VARIABLES.elevationDiskDir)>
                            <cfdirectory action="delete" directory="#VARIABLES.elevationDiskDir#" recurse="true"/>
                        </cfif>
                        <cfif VARIABLES.elevationStage EQ "mapbox_terrain_rgb">
                            <cfset VARIABLES.percursoAlert={
                                type="danger",
                                message="A Mapbox Terrain-RGB API recusou ou nao concluiu a consulta: "
                                    & cfcatch.message
                                    & " Referencia: "
                                    & VARIABLES.elevationErrorId
                            }/>
                        <cfelseif VARIABLES.elevationStage EQ "validacao_arquivo">
                            <cfset VARIABLES.percursoAlert={
                                type="danger",
                                message="Nao foi possivel ler a geometria da versao atual: "
                                    & cfcatch.message
                                    & " Referencia: "
                                    & VARIABLES.elevationErrorId
                            }/>
                        <cfelse>
                            <cfset VARIABLES.percursoAlert={
                                type="danger",
                                message="A altimetria foi consultada, mas nao foi possivel criar a nova versao. Referencia: "
                                    & VARIABLES.elevationErrorId
                            }/>
                        </cfif>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    <cfelseif listFindNoCase("restaurar_versao,excluir_versao",FORM.acao)>
        <cfset VARIABLES.versionRouteId=isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.versionFileId=isDefined("FORM.id_percurso_arquivo") AND isNumeric(FORM.id_percurso_arquivo) ? val(FORM.id_percurso_arquivo) : 0/>
        <cfset VARIABLES.versionDiskDir=""/>
        <cfquery name="qVersionActionSource">
            SELECT percurso.id_percurso,
                   arquivo.id_percurso_arquivo,
                   arquivo.versao,
                   arquivo.storage_key,
                   arquivo.geojson_storage_key,
                   arquivo.ativo
            FROM tb_percursos percurso
            INNER JOIN tb_percurso_arquivos arquivo
                ON arquivo.id_percurso=percurso.id_percurso
            WHERE percurso.id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
              AND arquivo.id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionFileId#"/>
              AND percurso.id_conta_responsavel IS NOT NULL
              <cfif NOT VARIABLES.percursoIsAdmin>
                  AND percurso.id_conta_responsavel IN (
                      <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                  )
              </cfif>
            LIMIT 1
        </cfquery>
        <cfif NOT qVersionActionSource.recordcount>
            <cfset VARIABLES.percursoAlert={type="danger",message="Versao nao encontrada ou sem permissao para gerencia-la."}/>
        <cfelseif FORM.acao EQ "excluir_versao">
            <cfif NOT percursoBoolean(qVersionActionSource.ativo)>
                <cfset VARIABLES.percursoAlert={type="warning",message="Esta versao ja esta excluida."}/>
            <cfelse>
                <cfset VARIABLES.versionDeleted=false/>
                <cftransaction>
                    <cfquery name="qVersionDeleteRouteLock">
                        SELECT id_percurso FROM tb_percursos
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                        FOR UPDATE
                    </cfquery>
                    <cfquery name="qVersionActiveCount">
                        SELECT count(*) AS total
                        FROM tb_percurso_arquivos
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                          AND ativo=true
                    </cfquery>
                    <cfif val(qVersionActiveCount.total) LTE 1>
                        <cfset VARIABLES.percursoAlert={type="danger",message="Nao e possivel excluir a unica versao ativa do percurso."}/>
                    <cfelse>
                    <cfquery>
                        UPDATE tb_percurso_arquivos
                        SET ativo=false
                        WHERE id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionFileId#"/>
                          AND id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                          AND ativo=true
                    </cfquery>
                    <cfquery>
                        UPDATE tb_percursos SET atualizado_em=now()
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                    </cfquery>
                    <cfset percursoAudit(VARIABLES.versionRouteId,VARIABLES.versionFileId,"excluir_versao",{
                        versao=val(qVersionActionSource.versao),
                        exclusao_logica=true
                    })/>
                    <cfset VARIABLES.versionDeleted=true/>
                    </cfif>
                </cftransaction>
                <cfif VARIABLES.versionDeleted>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.versionRouteId#&sucesso=versao_excluida"/>
                </cfif>
            </cfif>
        <cfelse>
            <cftry>
                <cftransaction>
                    <cfquery name="qVersionRouteLock">
                        SELECT id_percurso FROM tb_percursos
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                        FOR UPDATE
                    </cfquery>
                    <cfquery name="qVersionNext">
                        SELECT coalesce(max(versao),0)+1 AS versao
                        FROM tb_percurso_arquivos
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                    </cfquery>
                    <cfset VARIABLES.versionNewNumber=val(qVersionNext.versao)/>
                    <cfset VARIABLES.versionRelativeDir=VARIABLES.versionRouteId & "/" & VARIABLES.versionNewNumber/>
                    <cfset VARIABLES.versionDiskDir=VARIABLES.percursoStoragePath & "/" & VARIABLES.versionRelativeDir/>
                    <cfset VARIABLES.versionSourceOriginal=VARIABLES.percursoStoragePath & "/" & qVersionActionSource.storage_key/>
                    <cfset VARIABLES.versionSourceGeo=VARIABLES.percursoStoragePath & "/" & qVersionActionSource.geojson_storage_key/>
                    <cfset VARIABLES.versionSourceOptimized=VARIABLES.percursoStoragePath & "/" & reReplace(qVersionActionSource.geojson_storage_key,"[^/]+$","optimized.gpx")/>
                    <cfif NOT fileExists(VARIABLES.versionSourceOriginal) OR NOT fileExists(VARIABLES.versionSourceGeo)>
                        <cfthrow message="Os arquivos da versao selecionada nao existem no storage privado."/>
                    </cfif>
                    <cfdirectory action="create" directory="#VARIABLES.versionDiskDir#" recurse="true"/>
                    <cfset VARIABLES.versionOriginalName=listLast(qVersionActionSource.storage_key,"/")/>
                    <cfset VARIABLES.versionNewOriginalKey=VARIABLES.versionRelativeDir & "/" & VARIABLES.versionOriginalName/>
                    <cfset VARIABLES.versionNewGeoKey=VARIABLES.versionRelativeDir & "/route.geojson"/>
                    <cffile action="copy" source="#VARIABLES.versionSourceOriginal#" destination="#VARIABLES.percursoStoragePath#/#VARIABLES.versionNewOriginalKey#"/>
                    <cffile action="copy" source="#VARIABLES.versionSourceGeo#" destination="#VARIABLES.percursoStoragePath#/#VARIABLES.versionNewGeoKey#"/>
                    <cfif fileExists(VARIABLES.versionSourceOptimized)>
                        <cffile action="copy" source="#VARIABLES.versionSourceOptimized#" destination="#VARIABLES.versionDiskDir#/optimized.gpx"/>
                    </cfif>
                    <cfquery name="qVersionRestored">
                        INSERT INTO tb_percurso_arquivos
                            (id_percurso,versao,storage_key,geojson_storage_key,nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,id_usuario_criador)
                        SELECT id_percurso,
                               <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.versionNewNumber#"/>,
                               <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.versionNewOriginalKey#"/>,
                               <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.versionNewGeoKey#"/>,
                               nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,true,
                               <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                        FROM tb_percurso_arquivos
                        WHERE id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionFileId#"/>
                          AND id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                        RETURNING id_percurso_arquivo
                    </cfquery>
                    <cfquery>
                        UPDATE tb_percursos SET atualizado_em=now()
                        WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.versionRouteId#"/>
                    </cfquery>
                    <cfset percursoAudit(VARIABLES.versionRouteId,qVersionRestored.id_percurso_arquivo,"restaurar_versao",{
                        id_arquivo_origem=VARIABLES.versionFileId,
                        versao_origem=val(qVersionActionSource.versao),
                        nova_versao=VARIABLES.versionNewNumber
                    })/>
                </cftransaction>
                <cflocation addtoken="false" url="./?id=#VARIABLES.versionRouteId#&sucesso=versao_restaurada"/>
                <cfcatch type="any">
                    <cflog file="business-percursos" type="error" text="Falha ao restaurar versao #VARIABLES.versionFileId# do percurso #VARIABLES.versionRouteId#: #cfcatch.message# #cfcatch.detail#"/>
                    <cfif len(VARIABLES.versionDiskDir) AND directoryExists(VARIABLES.versionDiskDir)>
                        <cfdirectory action="delete" directory="#VARIABLES.versionDiskDir#" recurse="true"/>
                    </cfif>
                    <cfset VARIABLES.percursoAlert={type="danger",message="Nao foi possivel restaurar a versao selecionada. Consulte o log do modulo."}/>
                </cfcatch>
            </cftry>
        </cfif>
    <cfelseif listFindNoCase("criar,adicionar_versao", FORM.acao)>
        <cfset VARIABLES.uploadErrors=[]/>
        <cfset VARIABLES.uploadRouteId = FORM.acao EQ "adicionar_versao" AND isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.uploadName = isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
        <cfset VARIABLES.uploadDistance = isDefined("FORM.distancia_km") AND isNumeric(replace(FORM.distancia_km, ",", ".", "all")) ? round(val(replace(FORM.distancia_km, ",", ".", "all"))*1000) : 0/>
        <cfset VARIABLES.uploadType = isDefined("FORM.tipo_percurso") AND listFindNoCase("rua,trail,misto",FORM.tipo_percurso) ? lCase(FORM.tipo_percurso) : "rua"/>
        <cfset VARIABLES.uploadAccountId = VARIABLES.percursoActiveAccountId/>
        <cfset qPercursoUploadAllowed = queryNew("id_percurso,nome")/>
        <cfif FORM.acao EQ "criar" AND NOT len(VARIABLES.uploadName)><cfset arrayAppend(VARIABLES.uploadErrors,"Informe o nome do percurso.")/></cfif>
        <cfif FORM.acao EQ "criar" AND VARIABLES.uploadDistance LTE 0><cfset arrayAppend(VARIABLES.uploadErrors,"Informe uma distancia nominal valida.")/></cfif>
        <cfif FORM.acao EQ "criar" AND NOT VARIABLES.percursoCanCreate><cfset arrayAppend(VARIABLES.uploadErrors,"Selecione uma conta ativa na qual voce tenha permissao operacional antes de cadastrar o percurso.")/></cfif>
        <cfif NOT isDefined("FORM.arquivo_percurso") OR NOT len(trim(FORM.arquivo_percurso & ""))><cfset arrayAppend(VARIABLES.uploadErrors,"Selecione um arquivo GPX, KML, KMZ, GeoJSON ou FIT.")/></cfif>

        <cfif VARIABLES.uploadRouteId GT 0>
            <cfquery name="qPercursoUploadAllowed">
                SELECT id_percurso,nome FROM tb_percursos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/> AND id_conta_responsavel IS NOT NULL
                <cfif NOT VARIABLES.percursoIsAdmin>AND id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>)</cfif>
            </cfquery>
            <cfif NOT qPercursoUploadAllowed.recordcount><cfset arrayAppend(VARIABLES.uploadErrors,"Percurso nao encontrado ou sem permissao de alteracao.")/></cfif>
        </cfif>

        <cfif NOT arrayLen(VARIABLES.uploadErrors)>
            <cfset VARIABLES.uploadTempDir = getTempDirectory() & "business-percurso-" & createUUID()/>
            <cfdirectory action="create" directory="#VARIABLES.uploadTempDir#"/>
            <cftry>
                <cffile action="upload" filefield="arquivo_percurso" destination="#VARIABLES.uploadTempDir#" nameconflict="makeunique" result="percursoUpload"/>
                <cfset VARIABLES.uploadTempFile = VARIABLES.uploadTempDir & "/" & percursoUpload.serverFile/>
                <cfset VARIABLES.uploadFormat = lCase(trim(percursoUpload.serverFileExt & ""))/>
                <cfif VARIABLES.uploadFormat EQ "json"><cfset VARIABLES.uploadFormat = "geojson"/></cfif>
                <cfset VARIABLES.uploadMimeType = "application/octet-stream"/>
                <cfswitch expression="#VARIABLES.uploadFormat#">
                    <cfcase value="gpx"><cfset VARIABLES.uploadMimeType = "application/gpx+xml"/></cfcase>
                    <cfcase value="kml"><cfset VARIABLES.uploadMimeType = "application/vnd.google-earth.kml+xml"/></cfcase>
                    <cfcase value="kmz"><cfset VARIABLES.uploadMimeType = "application/vnd.google-earth.kmz"/></cfcase>
                    <cfcase value="geojson"><cfset VARIABLES.uploadMimeType = "application/geo+json"/></cfcase>
                    <cfcase value="fit"><cfset VARIABLES.uploadMimeType = "application/vnd.ant.fit"/></cfcase>
                </cfswitch>
                <cfif NOT listFindNoCase("gpx,kml,kmz,geojson,fit", VARIABLES.uploadFormat)><cfset arrayAppend(VARIABLES.uploadErrors,"O arquivo precisa ser GPX, KML, KMZ, GeoJSON ou FIT.")/></cfif>
                <cfif percursoUpload.fileSize GT 20971520><cfset arrayAppend(VARIABLES.uploadErrors,"O arquivo excede o limite de 20 MB.")/></cfif>
	                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
	                    <cfset VARIABLES.gpxService = createObject("component","percursos.includes.PercursoGpxService")/>
	                    <cfset VARIABLES.gpxAnalysis = VARIABLES.gpxService.analyze(VARIABLES.uploadTempFile, VARIABLES.uploadFormat)/>
	                    <cfif NOT VARIABLES.gpxAnalysis.valid><cfset VARIABLES.uploadErrors=VARIABLES.gpxAnalysis.errors/></cfif>
	                    <cfif VARIABLES.gpxAnalysis.valid AND VARIABLES.gpxAnalysis.elevationPointCount EQ 0>
	                        <cfsetting requesttimeout="180"/>
	                        <cfset VARIABLES.elevationEnrichment = VARIABLES.gpxService.enrichElevationFromMapbox(
	                            VARIABLES.gpxAnalysis,
	                            VARIABLES.percursoMapboxServerToken,
	                            VARIABLES.percursoElevationMaxSamples
	                        )/>
	                        <cfif VARIABLES.elevationEnrichment.success>
	                            <cfset VARIABLES.gpxAnalysis = VARIABLES.elevationEnrichment.analysis/>
	                        <cfelse>
	                            <cfset arrayAppend(
	                                VARIABLES.uploadErrors,
	                                "O arquivo não possui altimetria e a consulta externa falhou: "
	                                    & VARIABLES.elevationEnrichment.error
	                            )/>
	                        </cfif>
	                    </cfif>
	                </cfif>
                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
                    <cfquery name="qDuplicateGpx">
                        SELECT arquivo.id_percurso, arquivo.versao
                        FROM tb_percurso_arquivos arquivo
                        INNER JOIN tb_percursos percurso ON percurso.id_percurso = arquivo.id_percurso
                        WHERE arquivo.sha256 = <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.gpxAnalysis.sha256#"/>
                        <cfif FORM.acao EQ "criar">
                            AND percurso.id_conta_responsavel = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadAccountId#"/>
                        <cfelse>
                            AND arquivo.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/>
                        </cfif>
                        LIMIT 1
                    </cfquery>
                    <cfif qDuplicateGpx.recordcount><cfset arrayAppend(VARIABLES.uploadErrors,"Este arquivo ja foi cadastrado no percurso " & qDuplicateGpx.id_percurso & ", versao " & qDuplicateGpx.versao & ".")/></cfif>
                </cfif>
                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
                    <cftransaction>
                        <cfif FORM.acao EQ "criar">
                            <cfquery name="qNewPercurso">
                                INSERT INTO tb_percursos (codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,descricao,visibilidade,status,id_usuario_criador,id_conta_responsavel)
                                VALUES (CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#createUUID()#"/> AS uuid),<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uploadName#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.cidade)#" null="#!len(trim(FORM.cidade))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.estado))#" null="#!len(trim(FORM.estado))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.pais))#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.uploadDistance#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uploadType#"/>,<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#trim(FORM.descricao)#" null="#!len(trim(FORM.descricao))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="privado"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="rascunho"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadAccountId#"/>) RETURNING id_percurso
                            </cfquery>
                            <cfset VARIABLES.uploadRouteId=qNewPercurso.id_percurso/>
                            <cfset VARIABLES.uploadVersion=1/>
                        <cfelse>
                            <cfquery name="qNextVersion">SELECT coalesce(max(versao),0)+1 AS versao FROM tb_percurso_arquivos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/></cfquery>
                            <cfset VARIABLES.uploadVersion=qNextVersion.versao/>
                        </cfif>
                        <cfset VARIABLES.routeRelativeDir = VARIABLES.uploadRouteId & "/" & VARIABLES.uploadVersion/>
                        <cfset VARIABLES.routeDiskDir = VARIABLES.percursoStoragePath & "/" & VARIABLES.routeRelativeDir/>
                        <cfif NOT directoryExists(VARIABLES.routeDiskDir)><cfdirectory action="create" directory="#VARIABLES.routeDiskDir#" recurse="true"/></cfif>
                        <cfset VARIABLES.routeGpxKey=VARIABLES.routeRelativeDir & "/original." & VARIABLES.uploadFormat/>
                        <cfset VARIABLES.routeGeoKey=VARIABLES.routeRelativeDir & "/route.geojson"/>
                        <cfset VARIABLES.routeOptimizedGpxKey=VARIABLES.routeRelativeDir & "/optimized.gpx"/>
                        <cfset VARIABLES.routeOptimizedGpxName=len(VARIABLES.uploadName) ? VARIABLES.uploadName : (qPercursoUploadAllowed.recordcount ? qPercursoUploadAllowed.nome : "Percurso")/>
                        <cffile action="move" source="#VARIABLES.uploadTempFile#" destination="#VARIABLES.percursoStoragePath#/#VARIABLES.routeGpxKey#"/>
                        <cfset VARIABLES.gpxService.writeGeoJson(VARIABLES.gpxAnalysis, VARIABLES.percursoStoragePath & "/" & VARIABLES.routeGeoKey)/>
                        <cfset VARIABLES.gpxService.writeGpx(VARIABLES.gpxAnalysis, VARIABLES.percursoStoragePath & "/" & VARIABLES.routeOptimizedGpxKey, VARIABLES.routeOptimizedGpxName)/>
                        <cfquery name="qNewFile">
                            INSERT INTO tb_percurso_arquivos (id_percurso,versao,storage_key,geojson_storage_key,nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,id_usuario_criador)
                            VALUES (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.uploadVersion#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.routeGpxKey#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.routeGeoKey#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#percursoUpload.clientFile#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uploadMimeType#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#percursoUpload.fileSize#"/>,<cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.gpxAnalysis.sha256#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.gpxAnalysis.pointCount#"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.distanceM#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationMin#" null="#!len(VARIABLES.gpxAnalysis.elevationMin & '')#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationMax#" null="#!len(VARIABLES.gpxAnalysis.elevationMax & '')#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationGainM#" null="#VARIABLES.gpxAnalysis.elevationPointCount LTE 0#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.minLat#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.minLng#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.maxLat#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.maxLng#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>) RETURNING id_percurso_arquivo
                        </cfquery>
	                        <cfset percursoAudit(VARIABLES.uploadRouteId,qNewFile.id_percurso_arquivo,FORM.acao,{
	                            versao=VARIABLES.uploadVersion,
	                            sha256=VARIABLES.gpxAnalysis.sha256,
	                            formato=VARIABLES.gpxAnalysis.format,
	                            pontos=VARIABLES.gpxAnalysis.pointCount,
	                            segmentos=VARIABLES.gpxAnalysis.segmentCount,
	                            fonte_altimetria=VARIABLES.gpxAnalysis.elevationPointCount GT 0
	                                ? (isDefined("VARIABLES.elevationEnrichment") AND VARIABLES.elevationEnrichment.success ? VARIABLES.elevationEnrichment.source : "original")
	                                : "indisponivel"
	                        })/>
                    </cftransaction>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.uploadRouteId#&sucesso=#(FORM.acao EQ 'criar' ? 'criado' : 'versao')#"/>
                </cfif>
                <cfcatch type="any">
                    <cflog file="business-percursos" type="error" text="Falha ao processar arquivo de percurso para o usuario #VARIABLES.percursoActorId#: #cfcatch.message# #cfcatch.detail#"/>
                    <cfset arrayAppend(VARIABLES.uploadErrors,"Nao foi possivel processar o arquivo do percurso. Consulte o log do modulo se o problema persistir.")/>
                </cfcatch>
            </cftry>
            <cfif directoryExists(VARIABLES.uploadTempDir)><cfdirectory action="delete" directory="#VARIABLES.uploadTempDir#" recurse="true"/></cfif>
        </cfif>
        <cfif arrayLen(VARIABLES.uploadErrors)><cfset VARIABLES.percursoAlert={type="danger",message=arrayToList(VARIABLES.uploadErrors," ")}/></cfif>
    <cfelseif FORM.acao EQ "salvar">
        <cfset VARIABLES.saveId=isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.saveName=isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
        <cfset VARIABLES.saveDistance=isDefined("FORM.distancia_km") AND isNumeric(replace(FORM.distancia_km,",",".","all")) ? round(val(replace(FORM.distancia_km,",",".","all"))*1000) : 0/>
        <cfset VARIABLES.saveType=isDefined("FORM.tipo_percurso") AND listFindNoCase("rua,trail,misto",FORM.tipo_percurso) ? lCase(FORM.tipo_percurso) : ""/>
        <cfset VARIABLES.saveVisibility=isDefined("FORM.visibilidade") AND listFindNoCase("privado,compartilhado,publico",FORM.visibilidade) ? lCase(FORM.visibilidade) : ""/>
        <cfset VARIABLES.saveStatus=isDefined("FORM.status") AND listFindNoCase("rascunho,publicado,arquivado",FORM.status) ? lCase(FORM.status) : ""/>
        <cfquery name="qSaveAllowed">SELECT id_percurso FROM tb_percursos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saveId#"/> AND id_conta_responsavel IS NOT NULL<cfif NOT VARIABLES.percursoIsAdmin> AND id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>)</cfif></cfquery>
        <cfif NOT len(VARIABLES.saveName) OR VARIABLES.saveDistance LTE 0 OR NOT len(VARIABLES.saveType) OR NOT len(VARIABLES.saveVisibility) OR NOT len(VARIABLES.saveStatus)>
            <cfset VARIABLES.percursoAlert={type="danger",message="Os dados enviados para o percurso sao invalidos."}/>
        <cfelseif qSaveAllowed.recordcount>
            <cfquery>UPDATE tb_percursos SET nome=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveName#"/>,cidade=<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.cidade)#" null="#!len(trim(FORM.cidade))#"/>,estado=<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.estado))#" null="#!len(trim(FORM.estado))#"/>,pais=<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.pais))#"/>,distancia_nominal_m=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveDistance#"/>,tipo_percurso=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveType#"/>,descricao=<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#trim(FORM.descricao)#" null="#!len(trim(FORM.descricao))#"/>,visibilidade=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveVisibility#"/>,status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveStatus#"/>,atualizado_em=now() WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saveId#"/></cfquery>
            <cfset percursoAudit(VARIABLES.saveId,0,"atualizar_metadados",{nome=VARIABLES.saveName,status=VARIABLES.saveStatus,visibilidade=VARIABLES.saveVisibility})/>
            <cflocation addtoken="false" url="./?id=#VARIABLES.saveId#&sucesso=salvo"/>
        <cfelse><cfset VARIABLES.percursoAlert={type="danger",message="Percurso nao encontrado ou sem permissao de alteracao."}/></cfif>
    </cfif>
</cfif>

<cfif VARIABLES.percursoSchemaReady>
    <cfif VARIABLES.percursoSelectedId GT 0>
        <cfquery name="qPercurso">
            SELECT * FROM tb_percursos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/>
            <cfif NOT VARIABLES.percursoCanViewAll>
                AND (
                    (id_conta_responsavel IS NULL
                     AND id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>)
                    OR id_conta_responsavel IN (
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>
                    )
                    <cfif VARIABLES.percursoEventLinksReady>
                        OR EXISTS (
                            SELECT 1
                            FROM tb_evento_percursos_gpx evento_percurso
                            INNER JOIN tb_conta_eventos conta_evento
                                ON conta_evento.id_evento = evento_percurso.id_evento
                               AND conta_evento.status = 'ATIVO'::status_conta_evento
                            INNER JOIN tb_contas conta
                                ON conta.id_conta = conta_evento.id_conta
                               AND conta.status = 'ATIVA'::status_conta
                            WHERE evento_percurso.id_percurso = tb_percursos.id_percurso
                              AND conta_evento.id_conta IN (
                                  <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>
                              )
                        )
                    </cfif>
                )
            </cfif>
        </cfquery>
        <cfif qPercurso.recordcount>
            <cfset VARIABLES.percursoIsLegacyCreator = NOT len(qPercurso.id_conta_responsavel & "")
                AND val(qPercurso.id_usuario_criador) EQ VARIABLES.percursoActorId/>
            <cfset VARIABLES.percursoRouteUsesWritableAccount = len(qPercurso.id_conta_responsavel & "")
                AND VARIABLES.percursoWriteAccountIds NEQ "0"
                AND listFind(VARIABLES.percursoWriteAccountIds, qPercurso.id_conta_responsavel)/>
            <cfset VARIABLES.percursoRouteUsesManagerAccount = len(qPercurso.id_conta_responsavel & "")
                AND VARIABLES.percursoManagerAccountIds NEQ "0"
                AND listFind(VARIABLES.percursoManagerAccountIds, qPercurso.id_conta_responsavel)/>
            <cfset VARIABLES.percursoHasOwnerAccount = len(qPercurso.id_conta_responsavel & "") GT 0/>
            <cfset VARIABLES.percursoCanViewAudit = VARIABLES.percursoIsSystemAdmin
                OR VARIABLES.percursoIsLegacyCreator
                OR VARIABLES.percursoRouteUsesManagerAccount/>
            <cfset VARIABLES.percursoCanManageRouteEventLinks = VARIABLES.percursoIsSystemAdmin
                OR VARIABLES.percursoRouteUsesWritableAccount/>
            <cfset VARIABLES.percursoHasManagerAccount = VARIABLES.percursoManagerAccountIds NEQ "0"/>
            <cfset VARIABLES.percursoCanManageEventLinks = VARIABLES.percursoHasOwnerAccount
                AND (VARIABLES.percursoCanManageRouteEventLinks OR VARIABLES.percursoHasManagerAccount)/>
            <cfset VARIABLES.percursoCanLinkEvents = VARIABLES.percursoHasOwnerAccount
                AND (VARIABLES.percursoIsSystemAdmin
                    OR (VARIABLES.percursoCanManageEventLinks
                        AND VARIABLES.percursoWriteAccountIds NEQ "0"))/>
            <cfquery name="qPercursoOwner">
                SELECT id, name, email
                FROM tb_usuarios
                WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPercurso.id_usuario_criador#"/>
                LIMIT 1
            </cfquery>
            <cfquery name="qPercursoConta">
                SELECT id_conta, nome_conta, status::text AS status
                FROM tb_contas
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPercurso.id_conta_responsavel#" null="#!len(qPercurso.id_conta_responsavel & '')#"/>
                LIMIT 1
            </cfquery>
            <cfif VARIABLES.percursoIsSystemAdmin>
                <cfquery name="qPercursoContasTransferencia">
                    SELECT id_conta, nome_conta, status::text AS status
                    FROM tb_contas
                    WHERE status = 'ATIVA'::status_conta
                    ORDER BY nome_conta, id_conta
                </cfquery>
            </cfif>
            <cfif VARIABLES.percursoEventLinksReady>
                <cfquery name="qPercursoEventos">
                    SELECT evento_percurso.id_evento_percurso_gpx,
                           evento.id_evento,
                           <cfif VARIABLES.percursoEventRouteColumnReady>
                               evento_percurso.id_evento_percurso,
                               modalidade.percurso_evento,
                               modalidade.unidade_de_medida,
                           <cfelse>
                               NULL::integer AS id_evento_percurso,
                               NULL::numeric AS percurso_evento,
                               NULL::varchar AS unidade_de_medida,
                           </cfif>
                           evento.nome_evento,
                           evento.tag,
                           evento.data_inicial,
                           evento.data_final,
                           evento.cidade,
                           evento.estado,
                           coalesce((
                               SELECT string_agg(DISTINCT conta.nome_conta, ', ' ORDER BY conta.nome_conta)
                               FROM tb_conta_eventos conta_evento
                               INNER JOIN tb_contas conta
                                   ON conta.id_conta = conta_evento.id_conta
                                  AND conta.status = 'ATIVA'::status_conta
                               WHERE conta_evento.id_evento = evento.id_evento
                                 AND conta_evento.status = 'ATIVO'::status_conta_evento
                           ), '') AS contas,
                           <cfif VARIABLES.percursoManagerAccountIds NEQ "0">
                               EXISTS (
                                   SELECT 1
                                   FROM tb_conta_eventos conta_evento_gerencia
                                   INNER JOIN tb_contas conta_gerencia
                                       ON conta_gerencia.id_conta = conta_evento_gerencia.id_conta
                                      AND conta_gerencia.status = 'ATIVA'::status_conta
                                   WHERE conta_evento_gerencia.id_evento = evento.id_evento
                                     AND conta_evento_gerencia.id_conta IN (
                                         <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoManagerAccountIds#" list="true"/>
                                     )
                                     AND conta_evento_gerencia.status = 'ATIVO'::status_conta_evento
                               ) AS conta_pode_gerenciar
                           <cfelse>
                               false AS conta_pode_gerenciar
                           </cfif>
                    FROM tb_evento_percursos_gpx evento_percurso
                    INNER JOIN tb_evento_corridas evento
                        ON evento.id_evento = evento_percurso.id_evento
                    <cfif VARIABLES.percursoEventRouteColumnReady>
                        LEFT JOIN tb_evento_corridas_percursos modalidade
                            ON modalidade.id_evento_percurso = evento_percurso.id_evento_percurso
                    </cfif>
                    WHERE evento_percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/>
                    ORDER BY evento.data_inicial DESC NULLS LAST,
                             evento.nome_evento,
                             evento.id_evento,
                             <cfif VARIABLES.percursoEventRouteColumnReady>
                                 modalidade.percurso_evento NULLS LAST,
                             </cfif>
                             evento_percurso.id_evento_percurso_gpx
                </cfquery>

                <cfif VARIABLES.percursoCanLinkEvents
                    AND (len(trim(URL.evento_busca)) GTE 2 OR (isNumeric(trim(URL.evento_busca)) AND val(URL.evento_busca) GT 0))>
                    <cfset VARIABLES.eventSearchTerm = trim(URL.evento_busca)/>
                    <cfquery name="qPercursoEventSearch">
                        SELECT modalidade.id_evento_percurso,
                               evento.id_evento,
                               modalidade.percurso_evento,
                               modalidade.unidade_de_medida,
                               modalidade.tipo_corrida,
                               evento.nome_evento,
                               evento.tag,
                               evento.data_inicial,
                               evento.data_final,
                               evento.cidade,
                               evento.estado,
                               coalesce((
                                   SELECT string_agg(DISTINCT conta.nome_conta, ', ' ORDER BY conta.nome_conta)
                                   FROM tb_conta_eventos conta_evento
                                   INNER JOIN tb_contas conta
                                       ON conta.id_conta = conta_evento.id_conta
                                      AND conta.status = 'ATIVA'::status_conta
                                   WHERE conta_evento.id_evento = evento.id_evento
                                     AND conta_evento.status = 'ATIVO'::status_conta_evento
                               ), '') AS contas,
                               vinculo.id_percurso AS id_percurso_vinculado,
                               percurso_vinculado.nome AS nome_percurso_vinculado
                        FROM tb_evento_corridas_percursos modalidade
                        INNER JOIN tb_evento_corridas evento
                            ON evento.id_evento = modalidade.id_evento
                        LEFT JOIN tb_evento_percursos_gpx vinculo
                            ON vinculo.id_evento_percurso = modalidade.id_evento_percurso
                        LEFT JOIN tb_percursos percurso_vinculado
                            ON percurso_vinculado.id_percurso = vinculo.id_percurso
                        WHERE 1 = 1
                        <cfif NOT VARIABLES.percursoIsSystemAdmin>
                          AND EXISTS (
                              SELECT 1
                              FROM tb_conta_eventos conta_evento
                              INNER JOIN tb_contas conta
                                  ON conta.id_conta = conta_evento.id_conta
                                 AND conta.status = 'ATIVA'::status_conta
                              WHERE conta_evento.id_evento = evento.id_evento
                                AND conta_evento.id_conta IN (
                                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                                )
                                AND conta_evento.status = 'ATIVO'::status_conta_evento
                          )
                        </cfif>
                          AND (
                              evento.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventSearchTerm#"/>
                              OR modalidade.id_evento_percurso::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventSearchTerm#"/>
                              OR unaccent(coalesce(evento.nome_evento, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR unaccent(coalesce(evento.tag, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR unaccent(coalesce(evento.cidade, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR unaccent(coalesce(modalidade.tipo_corrida, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR concat(coalesce(modalidade.percurso_evento::text, ''), ' ', coalesce(modalidade.unidade_de_medida, '')) ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>
                          )
                        ORDER BY CASE
                                     WHEN evento.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventSearchTerm#"/> THEN 0
                                     WHEN modalidade.id_evento_percurso::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventSearchTerm#"/> THEN 0
                                     ELSE 1
                                 END,
                                 evento.data_inicial DESC NULLS LAST,
                                 evento.nome_evento,
                                 evento.id_evento,
                                 modalidade.percurso_evento,
                                 modalidade.id_evento_percurso
                        LIMIT 40
                    </cfquery>
                </cfif>
            </cfif>
            <cfquery name="qPercursoArquivos">SELECT id_percurso_arquivo,versao,nome_original,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,criado_em FROM tb_percurso_arquivos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> AND ativo=true ORDER BY versao DESC</cfquery>
            <cfif VARIABLES.percursoCanViewAudit>
                <cfquery name="qPercursoHistorico">SELECT hist.acao,hist.dados,hist.endereco_ip,hist.criado_em,usr.name AS usuario_nome FROM tb_percurso_historico hist LEFT JOIN tb_usuarios usr ON usr.id=hist.id_usuario WHERE hist.id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> ORDER BY hist.criado_em DESC LIMIT 30</cfquery>
            </cfif>
        </cfif>
    </cfif>
    <cfif VARIABLES.percursoSelectedId LTE 0>
        <cfquery name="qPercursos">
            SELECT p.*, conta.nome_conta AS conta_proprietaria, latest.versao,latest.distancia_gpx_m,latest.quantidade_pontos
            FROM tb_percursos p
            LEFT JOIN tb_contas conta ON conta.id_conta = p.id_conta_responsavel
            LEFT JOIN LATERAL (SELECT versao,distancia_gpx_m,quantidade_pontos FROM tb_percurso_arquivos a WHERE a.id_percurso=p.id_percurso AND a.ativo=true ORDER BY versao DESC LIMIT 1) latest ON true
            WHERE 1=1
            <cfif NOT VARIABLES.percursoCanViewAll>
                AND (
                    (p.id_conta_responsavel IS NULL
                     AND p.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>)
                    OR p.id_conta_responsavel IN (
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>
                    )
                    <cfif VARIABLES.percursoEventLinksReady>
                        OR EXISTS (
                            SELECT 1
                            FROM tb_evento_percursos_gpx evento_percurso
                            INNER JOIN tb_conta_eventos conta_evento
                                ON conta_evento.id_evento = evento_percurso.id_evento
                               AND conta_evento.status = 'ATIVO'::status_conta_evento
                            INNER JOIN tb_contas conta
                                ON conta.id_conta = conta_evento.id_conta
                               AND conta.status = 'ATIVA'::status_conta
                            WHERE evento_percurso.id_percurso = p.id_percurso
                              AND conta_evento.id_conta IN (
                                  <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>
                              )
                        )
                    </cfif>
                )
            </cfif>
            <cfif len(trim(URL.q))>AND (p.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.q)#%"/> OR p.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.q)#%"/>)</cfif>
            <cfif len(trim(URL.estado))>AND p.estado=<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(URL.estado))#"/></cfif>
            <cfif listFindNoCase("rascunho,publicado,arquivado",URL.status)>AND p.status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(URL.status)#"/></cfif>
            ORDER BY p.atualizado_em DESC LIMIT 500
        </cfquery>
        <cfif VARIABLES.percursoEventLinksReady AND qPercursos.recordcount>
            <cfquery name="qPercursosVinculos">
                SELECT vinculo.id_percurso,
                       evento.id_evento,
                       evento.nome_evento,
                       <cfif VARIABLES.percursoEventRouteColumnReady>
                           vinculo.id_evento_percurso,
                           modalidade.percurso_evento,
                           modalidade.unidade_de_medida
                       <cfelse>
                           NULL::integer AS id_evento_percurso,
                           NULL::numeric AS percurso_evento,
                           NULL::varchar AS unidade_de_medida
                       </cfif>
                FROM tb_evento_percursos_gpx vinculo
                INNER JOIN tb_evento_corridas evento
                    ON evento.id_evento = vinculo.id_evento
                <cfif VARIABLES.percursoEventRouteColumnReady>
                    LEFT JOIN tb_evento_corridas_percursos modalidade
                        ON modalidade.id_evento_percurso = vinculo.id_evento_percurso
                </cfif>
                WHERE vinculo.id_percurso IN (
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#valueList(qPercursos.id_percurso)#" list="true"/>
                )
                ORDER BY vinculo.id_percurso,
                         evento.data_inicial DESC NULLS LAST,
                         evento.nome_evento,
                         evento.id_evento,
                         <cfif VARIABLES.percursoEventRouteColumnReady>
                             modalidade.percurso_evento NULLS LAST,
                         </cfif>
                         vinculo.id_evento_percurso_gpx
            </cfquery>
            <cfloop query="qPercursosVinculos">
                <cfset VARIABLES.percursoListLinkKey = qPercursosVinculos.id_percurso & ""/>
                <cfif NOT structKeyExists(VARIABLES.percursoListEventLinks, VARIABLES.percursoListLinkKey)>
                    <cfset VARIABLES.percursoListEventLinks[VARIABLES.percursoListLinkKey] = []/>
                </cfif>
                <cfset arrayAppend(VARIABLES.percursoListEventLinks[VARIABLES.percursoListLinkKey], {
                    id_evento = val(qPercursosVinculos.id_evento),
                    id_evento_percurso = len(qPercursosVinculos.id_evento_percurso & "") ? val(qPercursosVinculos.id_evento_percurso) : 0,
                    nome_evento = qPercursosVinculos.nome_evento & "",
                    percurso_evento = qPercursosVinculos.percurso_evento & "",
                    unidade_de_medida = qPercursosVinculos.unidade_de_medida & ""
                })/>
            </cfloop>
        </cfif>
    </cfif>
</cfif>
