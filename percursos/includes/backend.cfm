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
<cfparam name="URL.owner_busca" default=""/>
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
<cfset VARIABLES.percursoWriteAccountIds = isDefined("VARIABLES.businessEffectiveAccountOperatorIds") ? VARIABLES.businessEffectiveAccountOperatorIds : "0"/>
<cfset VARIABLES.percursoCanWrite = VARIABLES.percursoIsAdmin OR (len(trim(VARIABLES.percursoWriteAccountIds)) AND VARIABLES.percursoWriteAccountIds NEQ "0")/>
<cfset VARIABLES.percursoSelectedId = isNumeric(URL.id) ? val(URL.id) : 0/>
<cfset VARIABLES.percursoIsOwner = false/>
<cfset VARIABLES.percursoCanManageEventLinks = false/>
<cfset VARIABLES.percursoCanLinkEvents = false/>
<cfset VARIABLES.percursoStoragePath = percursoStorageRoot()/>
<cfset VARIABLES.percursoStorageConfigured = false/>
<cftry><cfset VARIABLES.percursoStorageConfigured = len(trim(createObject("java", "java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")) GT 0/><cfcatch type="any"></cfcatch></cftry>
<cfif NOT VARIABLES.percursoStorageConfigured AND structKeyExists(VARIABLES.percursoLocalConfig,"storagePath") AND len(trim(VARIABLES.percursoLocalConfig.storagePath & ""))><cfset VARIABLES.percursoStorageConfigured=true/></cfif>
<cfset VARIABLES.percursoStorageReady=false/>
<cfset VARIABLES.percursoStorageError=""/>
<cftry>
    <cfif NOT directoryExists(VARIABLES.percursoStoragePath)><cfdirectory action="create" directory="#VARIABLES.percursoStoragePath#" recurse="true"/></cfif>
    <cfset VARIABLES.percursoStorageReady=createObject("java","java.io.File").init(VARIABLES.percursoStoragePath).canWrite()/>
    <cfif NOT VARIABLES.percursoStorageReady><cfset VARIABLES.percursoStorageError="O ColdFusion nao possui permissao de escrita no diretorio configurado."/></cfif>
    <cfcatch type="any"><cfset VARIABLES.percursoStorageReady=false/><cfset VARIABLES.percursoStorageError=cfcatch.message/></cfcatch>
</cftry>
<cfset VARIABLES.percursoCanWrite = VARIABLES.percursoCanWrite AND VARIABLES.percursoStorageReady/>
<cfset qPercursos = queryNew("id_percurso,codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,visibilidade,status,id_usuario_criador,id_conta_responsavel,criado_em,atualizado_em,versao,distancia_gpx_m,quantidade_pontos")/>
<cfset qPercurso = queryNew("id_percurso,codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,descricao,visibilidade,status,id_usuario_criador,id_conta_responsavel,criado_em,atualizado_em")/>
<cfset qPercursoArquivos = queryNew("id_percurso_arquivo,versao,nome_original,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,criado_em")/>
<cfset qPercursoHistorico = queryNew("acao,dados,endereco_ip,criado_em,usuario_nome")/>
<cfset qPercursoOwner = queryNew("id,name,email")/>
<cfset qPercursoOwnerSearch = queryNew("id,name,email")/>
<cfset qPercursoEventos = queryNew("id_evento_percurso_gpx,id_evento,id_evento_percurso,percurso_evento,unidade_de_medida,nome_evento,tag,data_inicial,data_final,cidade,estado,contas")/>
<cfset qPercursoEventSearch = queryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,contas")/>

<cfif NOT structKeyExists(SESSION, "percursoCsrfToken") OR NOT len(trim(SESSION.percursoCsrfToken & ""))>
    <cfset SESSION.percursoCsrfToken = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.percursoCsrfToken = SESSION.percursoCsrfToken/>

<cfif URL.sucesso EQ "criado"><cfset VARIABLES.percursoAlert={type="success",message="Percurso criado e GPX processado com sucesso."}/></cfif>
<cfif URL.sucesso EQ "salvo"><cfset VARIABLES.percursoAlert={type="success",message="Dados do percurso atualizados."}/></cfif>
<cfif URL.sucesso EQ "versao"><cfset VARIABLES.percursoAlert={type="success",message="Nova versao do GPX adicionada."}/></cfif>
<cfif URL.sucesso EQ "status"><cfset VARIABLES.percursoAlert={type="success",message="Status do percurso atualizado."}/></cfif>
<cfif URL.sucesso EQ "proprietario"><cfset VARIABLES.percursoAlert={type="success",message="Proprietario do percurso atualizado."}/></cfif>
<cfif URL.sucesso EQ "evento_vinculado"><cfset VARIABLES.percursoAlert={type="success",message="Evento vinculado ao percurso. Os membros das contas associadas ja podem visualiza-lo."}/></cfif>
<cfif URL.sucesso EQ "evento_desvinculado"><cfset VARIABLES.percursoAlert={type="success",message="Vinculo do evento removido do percurso."}/></cfif>

<cfif VARIABLES.percursoSchemaReady AND len(trim(FORM.acao))>
    <cfif compareNoCase(trim(FORM.csrf_token), VARIABLES.percursoCsrfToken) NEQ 0>
        <cfset VARIABLES.percursoAlert={type="danger",message="A sessao do formulario expirou. Recarregue a pagina."}/>
    <cfelseif FORM.acao EQ "alterar_proprietario">
        <cfif NOT VARIABLES.percursoIsSystemAdmin>
            <cfset VARIABLES.percursoAlert={type="danger",message="Somente ADMINs do sistema podem alterar o proprietario de um percurso."}/>
        <cfelse>
            <cfset VARIABLES.ownerRouteId = isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
            <cfset VARIABLES.ownerUserId = isDefined("FORM.id_usuario_criador") AND isNumeric(FORM.id_usuario_criador) ? val(FORM.id_usuario_criador) : 0/>
            <cfquery name="qPercursoOwnerChangeCheck">
                SELECT percurso.id_percurso,
                       percurso.id_usuario_criador AS id_usuario_anterior,
                       usuario.id AS id_usuario_novo
                FROM tb_percursos percurso
                LEFT JOIN tb_usuarios usuario
                    ON usuario.id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerUserId#"/>
                WHERE percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerRouteId#"/>
                LIMIT 1
            </cfquery>

            <cfif VARIABLES.ownerRouteId LTE 0
                OR VARIABLES.ownerUserId LTE 0
                OR NOT qPercursoOwnerChangeCheck.recordcount
                OR NOT len(qPercursoOwnerChangeCheck.id_usuario_novo & "")>
                <cfset VARIABLES.percursoAlert={type="danger",message="Selecione um usuario valido para receber o percurso."}/>
            <cfelseif val(qPercursoOwnerChangeCheck.id_usuario_anterior) EQ VARIABLES.ownerUserId>
                <cfset VARIABLES.percursoAlert={type="warning",message="O usuario selecionado ja e o proprietario deste percurso."}/>
            <cfelse>
                <cftransaction>
                    <cfquery>
                        UPDATE tb_percursos
                        SET id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerUserId#"/>,
                            atualizado_em = now()
                        WHERE id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.ownerRouteId#"/>
                    </cfquery>
                    <cfset percursoAudit(VARIABLES.ownerRouteId, 0, "alterar_proprietario", {
                        id_usuario_anterior = val(qPercursoOwnerChangeCheck.id_usuario_anterior),
                        id_usuario_novo = VARIABLES.ownerUserId
                    })/>
                </cftransaction>
                <cflocation addtoken="false" url="./?id=#VARIABLES.ownerRouteId#&sucesso=proprietario"/>
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
        <cfelse>
            <cfquery name="qPercursoEventLinkRouteCheck">
                SELECT percurso.id_percurso,
                       percurso.id_usuario_criador
                FROM tb_percursos percurso
                WHERE percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>
                <cfif NOT VARIABLES.percursoIsSystemAdmin>
                    AND (
                        percurso.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                        OR percurso.id_conta_responsavel IN (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>
                        )
                    )
                </cfif>
                LIMIT 1
            </cfquery>

            <cfif NOT qPercursoEventLinkRouteCheck.recordcount>
                <cfset VARIABLES.percursoAlert={type="danger",message="Percurso nao encontrado ou sem permissao para gerenciar seus eventos."}/>
            <cfelseif FORM.acao EQ "vincular_evento">
                <cfquery name="qPercursoEventLinkEventCheck">
                    SELECT evento.id_evento
                    FROM tb_evento_corridas evento
                    WHERE evento.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>
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
                </cfquery>

                <cfif NOT qPercursoEventLinkEventCheck.recordcount>
                    <cfset VARIABLES.percursoAlert={type="danger",message="Evento nao encontrado ou indisponivel para operacao nesta conta."}/>
                <cfelse>
                    <cfquery name="qPercursoEventLinkExists">
                        SELECT id_evento_percurso_gpx
                        FROM tb_evento_percursos_gpx
                        WHERE id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>
                          AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>
                        LIMIT 1
                    </cfquery>
                    <cfif qPercursoEventLinkExists.recordcount>
                        <cfset VARIABLES.percursoAlert={type="warning",message="Este evento ja esta vinculado ao percurso."}/>
                    <cfelse>
                        <cftransaction>
                            <cfquery>
                                INSERT INTO tb_evento_percursos_gpx
                                    (id_evento, id_percurso, id_usuario_criador)
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventLinkEventId#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.eventLinkRouteId#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
                                )
                            </cfquery>
                            <cfset percursoAudit(VARIABLES.eventLinkRouteId, 0, "vincular_evento", {
                                id_evento = VARIABLES.eventLinkEventId
                            })/>
                        </cftransaction>
                        <cflocation addtoken="false" url="./?id=#VARIABLES.eventLinkRouteId#&sucesso=evento_vinculado"/>
                    </cfif>
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
    <cfelseif NOT VARIABLES.percursoCanWrite>
        <cfset VARIABLES.percursoAlert={type="danger",message="Sua conta nao possui permissao para alterar percursos."}/>
    <cfelseif listFindNoCase("criar,adicionar_versao", FORM.acao)>
        <cfset VARIABLES.uploadErrors=[]/>
        <cfset VARIABLES.uploadRouteId = FORM.acao EQ "adicionar_versao" AND isDefined("FORM.id_percurso") AND isNumeric(FORM.id_percurso) ? val(FORM.id_percurso) : 0/>
        <cfset VARIABLES.uploadName = isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
        <cfset VARIABLES.uploadDistance = isDefined("FORM.distancia_km") AND isNumeric(replace(FORM.distancia_km, ",", ".", "all")) ? round(val(replace(FORM.distancia_km, ",", ".", "all"))*1000) : 0/>
        <cfset VARIABLES.uploadType = isDefined("FORM.tipo_percurso") AND listFindNoCase("rua,trail,misto",FORM.tipo_percurso) ? lCase(FORM.tipo_percurso) : "rua"/>
        <cfset VARIABLES.uploadAccountId = 0/>
        <cfif NOT VARIABLES.percursoIsAdmin AND VARIABLES.percursoWriteAccountIds NEQ "0"><cfset VARIABLES.uploadAccountId=val(listFirst(VARIABLES.percursoWriteAccountIds))/></cfif>
        <cfif VARIABLES.percursoIsAdmin AND isDefined("FORM.id_conta_responsavel") AND isNumeric(FORM.id_conta_responsavel)><cfset VARIABLES.uploadAccountId=val(FORM.id_conta_responsavel)/></cfif>
        <cfif FORM.acao EQ "criar" AND NOT len(VARIABLES.uploadName)><cfset arrayAppend(VARIABLES.uploadErrors,"Informe o nome do percurso.")/></cfif>
        <cfif FORM.acao EQ "criar" AND VARIABLES.uploadDistance LTE 0><cfset arrayAppend(VARIABLES.uploadErrors,"Informe uma distancia nominal valida.")/></cfif>
        <cfif NOT isDefined("FORM.arquivo_gpx") OR NOT len(trim(FORM.arquivo_gpx & ""))><cfset arrayAppend(VARIABLES.uploadErrors,"Selecione um arquivo GPX.")/></cfif>

        <cfif VARIABLES.uploadRouteId GT 0>
            <cfquery name="qPercursoUploadAllowed">
                SELECT id_percurso FROM tb_percursos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/>
                <cfif NOT VARIABLES.percursoIsAdmin>AND (id_usuario_criador=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/> OR id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>))</cfif>
            </cfquery>
            <cfif NOT qPercursoUploadAllowed.recordcount><cfset arrayAppend(VARIABLES.uploadErrors,"Percurso nao encontrado ou sem permissao de alteracao.")/></cfif>
        </cfif>

        <cfif NOT arrayLen(VARIABLES.uploadErrors)>
            <cfset VARIABLES.uploadTempDir = getTempDirectory() & "business-percurso-" & createUUID()/>
            <cfdirectory action="create" directory="#VARIABLES.uploadTempDir#"/>
            <cftry>
                <cffile action="upload" filefield="arquivo_gpx" destination="#VARIABLES.uploadTempDir#" nameconflict="makeunique" result="percursoUpload"/>
                <cfset VARIABLES.uploadTempFile = VARIABLES.uploadTempDir & "/" & percursoUpload.serverFile/>
                <cfif lCase(percursoUpload.serverFileExt) NEQ "gpx"><cfset arrayAppend(VARIABLES.uploadErrors,"O arquivo precisa ter extensao .gpx.")/></cfif>
                <cfif percursoUpload.fileSize GT 20971520><cfset arrayAppend(VARIABLES.uploadErrors,"O GPX excede o limite de 20 MB.")/></cfif>
                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
                    <cfset VARIABLES.gpxService = createObject("component","percursos.includes.PercursoGpxService")/>
                    <cfset VARIABLES.gpxAnalysis = VARIABLES.gpxService.analyze(VARIABLES.uploadTempFile)/>
                    <cfif NOT VARIABLES.gpxAnalysis.valid><cfset VARIABLES.uploadErrors=VARIABLES.gpxAnalysis.errors/></cfif>
                </cfif>
                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
                    <cfquery name="qDuplicateGpx">SELECT id_percurso,versao FROM tb_percurso_arquivos WHERE sha256=<cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.gpxAnalysis.sha256#"/> LIMIT 1</cfquery>
                    <cfif qDuplicateGpx.recordcount><cfset arrayAppend(VARIABLES.uploadErrors,"Este GPX ja foi cadastrado no percurso " & qDuplicateGpx.id_percurso & ", versao " & qDuplicateGpx.versao & ".")/></cfif>
                </cfif>
                <cfif NOT arrayLen(VARIABLES.uploadErrors)>
                    <cftransaction>
                        <cfif FORM.acao EQ "criar">
                            <cfquery name="qNewPercurso">
                                INSERT INTO tb_percursos (codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,descricao,visibilidade,status,id_usuario_criador,id_conta_responsavel)
                                VALUES (CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#createUUID()#"/> AS uuid),<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uploadName#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.cidade)#" null="#!len(trim(FORM.cidade))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.estado))#" null="#!len(trim(FORM.estado))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(FORM.pais))#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.uploadDistance#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.uploadType#"/>,<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#trim(FORM.descricao)#" null="#!len(trim(FORM.descricao))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="privado"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="rascunho"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadAccountId#" null="#VARIABLES.uploadAccountId LTE 0#"/>) RETURNING id_percurso
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
                        <cfset VARIABLES.routeGpxKey=VARIABLES.routeRelativeDir & "/original.gpx"/>
                        <cfset VARIABLES.routeGeoKey=VARIABLES.routeRelativeDir & "/route.geojson"/>
                        <cffile action="move" source="#VARIABLES.uploadTempFile#" destination="#VARIABLES.percursoStoragePath#/#VARIABLES.routeGpxKey#"/>
                        <cfset VARIABLES.gpxService.writeGeoJson(VARIABLES.gpxAnalysis, VARIABLES.percursoStoragePath & "/" & VARIABLES.routeGeoKey)/>
                        <cfquery name="qNewFile">
                            INSERT INTO tb_percurso_arquivos (id_percurso,versao,storage_key,geojson_storage_key,nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,id_usuario_criador)
                            VALUES (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.uploadRouteId#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.uploadVersion#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.routeGpxKey#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.routeGeoKey#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#percursoUpload.clientFile#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#percursoUpload.contentType#/#percursoUpload.contentSubType#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#percursoUpload.fileSize#"/>,<cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.gpxAnalysis.sha256#"/>,<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.gpxAnalysis.pointCount#"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.distanceM#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationMin#" null="#!len(VARIABLES.gpxAnalysis.elevationMin & '')#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationMax#" null="#!len(VARIABLES.gpxAnalysis.elevationMax & '')#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.elevationGainM#" scale="2"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.minLat#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.minLng#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.maxLat#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.gpxAnalysis.maxLng#" scale="7"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>) RETURNING id_percurso_arquivo
                        </cfquery>
                        <cfset percursoAudit(VARIABLES.uploadRouteId,qNewFile.id_percurso_arquivo,FORM.acao,{versao=VARIABLES.uploadVersion,sha256=VARIABLES.gpxAnalysis.sha256})/>
                    </cftransaction>
                    <cflocation addtoken="false" url="./?id=#VARIABLES.uploadRouteId#&sucesso=#(FORM.acao EQ 'criar' ? 'criado' : 'versao')#"/>
                </cfif>
                <cfcatch type="any">
                    <cflog file="business-percursos" type="error" text="Falha ao processar GPX para o usuario #VARIABLES.percursoActorId#: #cfcatch.message# #cfcatch.detail#"/>
                    <cfset arrayAppend(VARIABLES.uploadErrors,"Nao foi possivel processar o GPX. Consulte o log do modulo se o problema persistir.")/>
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
        <cfquery name="qSaveAllowed">SELECT id_percurso FROM tb_percursos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saveId#"/><cfif NOT VARIABLES.percursoIsAdmin> AND (id_usuario_criador=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/> OR id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoWriteAccountIds#" list="true"/>))</cfif></cfquery>
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
                    id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
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
            <cfset VARIABLES.percursoIsOwner = val(qPercurso.id_usuario_criador) EQ VARIABLES.percursoActorId/>
            <cfset VARIABLES.percursoRouteUsesWritableAccount = len(qPercurso.id_conta_responsavel & "")
                AND VARIABLES.percursoWriteAccountIds NEQ "0"
                AND listFind(VARIABLES.percursoWriteAccountIds, qPercurso.id_conta_responsavel)/>
            <cfset VARIABLES.percursoCanManageEventLinks = VARIABLES.percursoIsSystemAdmin
                OR VARIABLES.percursoIsOwner
                OR VARIABLES.percursoRouteUsesWritableAccount/>
            <cfset VARIABLES.percursoCanLinkEvents = VARIABLES.percursoIsSystemAdmin
                OR (VARIABLES.percursoCanManageEventLinks
                    AND VARIABLES.percursoWriteAccountIds NEQ "0")/>
            <cfquery name="qPercursoOwner">
                SELECT id, name, email
                FROM tb_usuarios
                WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPercurso.id_usuario_criador#"/>
                LIMIT 1
            </cfquery>
            <cfif VARIABLES.percursoIsSystemAdmin>
                <cfif len(trim(URL.owner_busca)) GTE 2 OR (isNumeric(trim(URL.owner_busca)) AND val(URL.owner_busca) GT 0)>
                    <cfset VARIABLES.ownerSearchTerm = trim(URL.owner_busca)/>
                    <cfquery name="qPercursoOwnerSearch">
                        SELECT usr.id, usr.name, usr.email
                        FROM tb_usuarios usr
                        WHERE usr.id::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.ownerSearchTerm#"/>
                           OR unaccent(coalesce(usr.name, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.ownerSearchTerm#%"/>)
                           OR coalesce(usr.email, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.ownerSearchTerm#%"/>
                        ORDER BY CASE WHEN usr.id::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.ownerSearchTerm#"/> THEN 0 ELSE 1 END,
                                 usr.name,
                                 usr.id
                        LIMIT 20
                    </cfquery>
                </cfif>
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
                           ), '') AS contas
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
                             evento.id_evento
                </cfquery>

                <cfif VARIABLES.percursoCanLinkEvents
                    AND (len(trim(URL.evento_busca)) GTE 2 OR (isNumeric(trim(URL.evento_busca)) AND val(URL.evento_busca) GT 0))>
                    <cfset VARIABLES.eventSearchTerm = trim(URL.evento_busca)/>
                    <cfquery name="qPercursoEventSearch">
                        SELECT evento.id_evento,
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
                               ), '') AS contas
                        FROM tb_evento_corridas evento
                        WHERE NOT EXISTS (
                              SELECT 1
                              FROM tb_evento_percursos_gpx evento_percurso
                              WHERE evento_percurso.id_evento = evento.id_evento
                                AND evento_percurso.id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/>
                          )
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
                              OR unaccent(coalesce(evento.nome_evento, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR unaccent(coalesce(evento.tag, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                              OR unaccent(coalesce(evento.cidade, '')) ILIKE unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventSearchTerm#%"/>)
                          )
                        ORDER BY CASE
                                     WHEN evento.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventSearchTerm#"/> THEN 0
                                     ELSE 1
                                 END,
                                 evento.data_inicial DESC NULLS LAST,
                                 evento.nome_evento,
                                 evento.id_evento
                        LIMIT 20
                    </cfquery>
                </cfif>
            </cfif>
            <cfquery name="qPercursoArquivos">SELECT id_percurso_arquivo,versao,nome_original,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,criado_em FROM tb_percurso_arquivos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> ORDER BY versao DESC</cfquery>
            <cfif VARIABLES.percursoIsOwner OR VARIABLES.percursoIsSystemAdmin>
                <cfquery name="qPercursoHistorico">SELECT hist.acao,hist.dados,hist.endereco_ip,hist.criado_em,usr.name AS usuario_nome FROM tb_percurso_historico hist LEFT JOIN tb_usuarios usr ON usr.id=hist.id_usuario WHERE hist.id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> ORDER BY hist.criado_em DESC LIMIT 30</cfquery>
            </cfif>
        </cfif>
    </cfif>
    <cfif VARIABLES.percursoSelectedId LTE 0>
        <cfquery name="qPercursos">
            SELECT p.*, latest.versao,latest.distancia_gpx_m,latest.quantidade_pontos FROM tb_percursos p LEFT JOIN LATERAL (SELECT versao,distancia_gpx_m,quantidade_pontos FROM tb_percurso_arquivos a WHERE a.id_percurso=p.id_percurso ORDER BY versao DESC LIMIT 1) latest ON true WHERE 1=1
            <cfif NOT VARIABLES.percursoCanViewAll>
                AND (
                    p.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/>
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
    </cfif>
</cfif>
