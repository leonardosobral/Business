<cfsetting requesttimeout="600" showdebugoutput="false"/>

<cfset VARIABLES.stravaMigrationConfig = {}/>
<cfset VARIABLES.stravaMigrationConfigPath = expandPath("/config/percursos.local.cfm")/>
<cfif fileExists(VARIABLES.stravaMigrationConfigPath)>
    <cfinclude template="../../config/percursos.local.cfm"/>
    <cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig)>
        <cfset VARIABLES.stravaMigrationConfig = duplicate(percursoLocalConfig)/>
    </cfif>
</cfif>

<cfscript>
function stravaMigrationBoolean(required any value) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,t,yes,sim,on", trim(arguments.value & "")) GT 0;
}

function stravaMigrationStorageRoot() {
    var configured = "";
    try {
        configured = trim(createObject("java", "java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "");
    } catch (any ignored) {}
    if (len(configured)) return configured;
    if (structKeyExists(VARIABLES.stravaMigrationConfig, "storagePath")
        AND len(trim(VARIABLES.stravaMigrationConfig.storagePath & ""))) {
        return trim(VARIABLES.stravaMigrationConfig.storagePath & "");
    }
    return getTempDirectory() & "business-percursos-storage";
}

function stravaMigrationDistanceMeters(required any distance, required string unit) {
    var normalizedUnit = lCase(trim(arguments.unit));
    var numericDistance = val(arguments.distance);
    if (numericDistance LTE 0) return 0;
    if (listFindNoCase("km,quilometro,quilometros,quilômetro,quilômetros", normalizedUnit)) {
        return round(numericDistance * 1000);
    }
    if (listFindNoCase("m,metro,metros", normalizedUnit)) return round(numericDistance);
    return 0;
}

function stravaMigrationRouteType(required any value) {
    var normalizedType = lCase(trim(arguments.value & ""));
    if (listFindNoCase("rua,trail,misto", normalizedType)) return normalizedType;
    return "rua";
}

function stravaMigrationUpdate(
    required numeric sourceId,
    required string status,
    required string message,
    numeric httpStatus=0,
    string sha256="",
    numeric distanceM=0,
    numeric routeId=0,
    numeric fileId=0,
    struct data={},
    boolean completed=false
) {
    queryExecute(
        "UPDATE tb_percurso_migracoes_strava
         SET status = :status,
             mensagem = :message,
             ultimo_http_status = :httpStatus,
             sha256 = coalesce(:sha256, sha256),
             distancia_gpx_m = coalesce(:distanceM, distancia_gpx_m),
             id_percurso = coalesce(:routeId, id_percurso),
             id_percurso_arquivo = coalesce(:fileId, id_percurso_arquivo),
             dados = dados || CAST(:data AS jsonb),
             id_usuario_ultima_acao = :actorId,
             data_atualizacao = now(),
             data_conclusao = CASE WHEN :completed = 1 THEN now() ELSE NULL END
         WHERE id_evento_percurso = :sourceId",
        {
            status={value=arguments.status,cfsqltype="cf_sql_varchar"},
            message={value=left(arguments.message,4000),cfsqltype="cf_sql_longvarchar",null=!len(trim(arguments.message))},
            httpStatus={value=arguments.httpStatus,cfsqltype="cf_sql_integer",null=arguments.httpStatus LTE 0},
            sha256={value=arguments.sha256,cfsqltype="cf_sql_char",null=!len(trim(arguments.sha256))},
            distanceM={value=arguments.distanceM,cfsqltype="cf_sql_decimal",scale=2,null=arguments.distanceM LTE 0},
            routeId={value=arguments.routeId,cfsqltype="cf_sql_bigint",null=arguments.routeId LTE 0},
            fileId={value=arguments.fileId,cfsqltype="cf_sql_bigint",null=arguments.fileId LTE 0},
            data={value=serializeJSON(arguments.data),cfsqltype="cf_sql_longvarchar"},
            actorId={value=VARIABLES.stravaMigrationActorId,cfsqltype="cf_sql_bigint"},
            completed={value=(arguments.completed ? 1 : 0),cfsqltype="cf_sql_integer"},
            sourceId={value=arguments.sourceId,cfsqltype="cf_sql_integer"}
        }
    );
}
</cfscript>

<cfparam name="URL.status" default="todos"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.pagina" default="1"/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>
<cfparam name="FORM.modalidade_ids" default=""/>
<cfparam name="FORM.modo" default="simular"/>
<cfparam name="FORM.limite" default="5"/>

<cfset VARIABLES.stravaMigrationActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.stravaMigrationIsAdmin = isDefined("qPerfil")
    AND qPerfil.recordcount
    AND listFindNoCase(qPerfil.columnList, "is_admin")
    AND stravaMigrationBoolean(qPerfil.is_admin)/>

<cfif NOT VARIABLES.stravaMigrationIsAdmin>
    <cfcontent reset="true" type="text/plain; charset=utf-8"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>Acesso restrito a ADMINs do sistema.</cfoutput>
    <cfabort/>
</cfif>

<cfquery name="qStravaMigrationSchema">
    SELECT to_regclass('public.tb_percurso_migracoes_strava') IS NOT NULL
           AND to_regclass('public.tb_evento_percursos_gpx') IS NOT NULL
           AND EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_schema = 'public'
                 AND table_name = 'tb_evento_percursos_gpx'
                 AND column_name = 'id_evento_percurso'
           ) AS ready
</cfquery>
<cfset VARIABLES.stravaMigrationSchemaReady = qStravaMigrationSchema.recordcount
    AND stravaMigrationBoolean(qStravaMigrationSchema.ready)/>
<cfset VARIABLES.stravaMigrationStoragePath = stravaMigrationStorageRoot()/>
<cfset VARIABLES.stravaMigrationStorageConfigured = false/>
<cftry>
    <cfset VARIABLES.stravaMigrationStorageConfigured = len(trim(createObject("java","java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")) GT 0/>
    <cfcatch type="any"></cfcatch>
</cftry>
<cfif NOT VARIABLES.stravaMigrationStorageConfigured
    AND structKeyExists(VARIABLES.stravaMigrationConfig,"storagePath")
    AND len(trim(VARIABLES.stravaMigrationConfig.storagePath & ""))>
    <cfset VARIABLES.stravaMigrationStorageConfigured = true/>
</cfif>
<cfset VARIABLES.stravaMigrationStorageReady = false/>
<cfset VARIABLES.stravaMigrationStorageError = ""/>
<cfif NOT VARIABLES.stravaMigrationStorageConfigured>
    <cfset VARIABLES.stravaMigrationStorageError = "Configure um storage persistente em config/percursos.local.cfm ou BUSINESS_PERCURSOS_STORAGE_PATH antes de migrar."/>
<cfelse>
    <cftry>
        <cfif NOT directoryExists(VARIABLES.stravaMigrationStoragePath)>
            <cfdirectory action="create" directory="#VARIABLES.stravaMigrationStoragePath#" recurse="true"/>
        </cfif>
        <cfset VARIABLES.stravaMigrationStorageReady = createObject("java","java.io.File").init(VARIABLES.stravaMigrationStoragePath).canWrite()/>
        <cfif NOT VARIABLES.stravaMigrationStorageReady>
            <cfset VARIABLES.stravaMigrationStorageError = "O ColdFusion nao possui permissao de escrita no repositorio de percursos."/>
        </cfif>
        <cfcatch type="any">
            <cfset VARIABLES.stravaMigrationStorageError = cfcatch.message/>
        </cfcatch>
    </cftry>
</cfif>

<cfif NOT structKeyExists(SESSION, "stravaMigrationCsrfToken") OR NOT len(trim(SESSION.stravaMigrationCsrfToken & ""))>
    <cfset SESSION.stravaMigrationCsrfToken = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.stravaMigrationCsrfToken = SESSION.stravaMigrationCsrfToken/>
<cfset VARIABLES.stravaMigrationAlert = {type="", message=""}/>
<cfif structKeyExists(SESSION, "stravaMigrationFlash") AND isStruct(SESSION.stravaMigrationFlash)>
    <cfset VARIABLES.stravaMigrationAlert = duplicate(SESSION.stravaMigrationFlash)/>
    <cfset structDelete(SESSION, "stravaMigrationFlash")/>
</cfif>

<cfif VARIABLES.stravaMigrationSchemaReady>
    <cfquery>
        WITH fontes AS (
            SELECT modalidade.id_evento_percurso,
                   modalidade.id_evento,
                   trim(modalidade.mapa) AS mapa_original,
                   CASE
                       WHEN trim(modalidade.mapa) ~ '^[0-9]+$'
                           THEN left(trim(modalidade.mapa), 128)
                       WHEN trim(modalidade.mapa) ~* 'strava\.com/routes/[0-9]+'
                           THEN substring(trim(modalidade.mapa) FROM '(?i)strava\.com/routes/([0-9]+)')
                       ELSE left(trim(modalidade.mapa), 128)
                   END AS strava_route_id
            FROM tb_evento_corridas_percursos modalidade
            WHERE nullif(trim(modalidade.mapa), '') IS NOT NULL
        )
        INSERT INTO tb_percurso_migracoes_strava
            (id_evento_percurso, id_evento, strava_route_id, strava_url, status, mensagem, dados)
        SELECT fontes.id_evento_percurso,
               fontes.id_evento,
               fontes.strava_route_id,
               'https://www.strava.com/routes/' || fontes.strava_route_id || '/export_gpx',
               CASE WHEN fontes.strava_route_id ~ '^[0-9]{1,32}$' THEN 'pendente' ELSE 'revisao' END,
               CASE
                   WHEN fontes.strava_route_id ~ '^[0-9]{1,32}$' THEN 'Aguardando processamento.'
                   ELSE 'O valor original de mapa precisa de revisao antes do processamento.'
               END,
               jsonb_build_object('mapaOriginal', fontes.mapa_original)
        FROM fontes
        ON CONFLICT (id_evento_percurso) DO UPDATE
        SET id_evento = EXCLUDED.id_evento,
            strava_url = EXCLUDED.strava_url,
            status = CASE
                WHEN tb_percurso_migracoes_strava.strava_route_id IS DISTINCT FROM EXCLUDED.strava_route_id
                    THEN 'revisao'
                WHEN EXCLUDED.status = 'revisao'
                     AND tb_percurso_migracoes_strava.status IN ('pendente','validado','erro','revisao')
                    THEN 'revisao'
                ELSE tb_percurso_migracoes_strava.status
            END,
            mensagem = CASE
                WHEN tb_percurso_migracoes_strava.strava_route_id IS DISTINCT FROM EXCLUDED.strava_route_id
                    THEN 'O identificador da rota Strava mudou depois do inventario. Revise antes de reprocessar.'
                WHEN EXCLUDED.status = 'revisao'
                     AND tb_percurso_migracoes_strava.status IN ('pendente','validado','erro','revisao')
                    THEN EXCLUDED.mensagem
                ELSE tb_percurso_migracoes_strava.mensagem
            END,
            strava_route_id = EXCLUDED.strava_route_id,
            dados = tb_percurso_migracoes_strava.dados || EXCLUDED.dados,
            data_atualizacao = CASE
                WHEN tb_percurso_migracoes_strava.strava_route_id IS DISTINCT FROM EXCLUDED.strava_route_id
                    THEN now()
                ELSE tb_percurso_migracoes_strava.data_atualizacao
            END
    </cfquery>
</cfif>

<cfif VARIABLES.stravaMigrationSchemaReady AND len(trim(FORM.acao))>
    <cfif compareNoCase(trim(FORM.csrf_token), VARIABLES.stravaMigrationCsrfToken) NEQ 0>
        <cfset VARIABLES.stravaMigrationAlert = {type="danger", message="A sessao do formulario expirou. Recarregue a pagina."}/>
    <cfelseif listFindNoCase("ignorar,reabrir",FORM.acao)>
        <cfset VARIABLES.stravaMigrationStatusIds = []/>
        <cfloop list="#FORM.modalidade_ids#" item="migrationStatusId">
            <cfif isNumeric(migrationStatusId)
                AND val(migrationStatusId) GT 0
                AND NOT arrayFind(VARIABLES.stravaMigrationStatusIds,val(migrationStatusId))>
                <cfset arrayAppend(VARIABLES.stravaMigrationStatusIds,val(migrationStatusId))/>
            </cfif>
        </cfloop>
        <cfif NOT arrayLen(VARIABLES.stravaMigrationStatusIds)>
            <cfset VARIABLES.stravaMigrationAlert = {type="warning", message="Selecione ao menos uma modalidade para alterar o status."}/>
        <cfelse>
            <cfquery>
                UPDATE tb_percurso_migracoes_strava
                SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.acao EQ 'ignorar' ? 'ignorado' : 'pendente'#"/>,
                    mensagem = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.acao EQ 'ignorar' ? 'Item ignorado manualmente.' : 'Item reaberto para processamento.'#"/>,
                    id_usuario_ultima_acao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>,
                    data_atualizacao = now(),
                    data_conclusao = NULL
                WHERE id_evento_percurso IN (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayToList(VARIABLES.stravaMigrationStatusIds)#" list="true"/>
                )
                  AND status NOT IN ('migrado','reutilizado','processando')
            </cfquery>
            <cfset SESSION.stravaMigrationFlash = {
                type="success",
                message=(FORM.acao EQ "ignorar" ? "Itens marcados como ignorados." : "Itens reabertos para processamento.")
            }/>
            <cflocation addtoken="false" url="./migracao-strava.cfm"/>
        </cfif>
    <cfelseif NOT VARIABLES.stravaMigrationStorageReady>
        <cfset VARIABLES.stravaMigrationAlert = {type="danger", message=VARIABLES.stravaMigrationStorageError}/>
    <cfelseif FORM.acao EQ "processar">
        <cfset VARIABLES.stravaMigrationDryRun = FORM.modo NEQ "migrar"/>
        <cfset VARIABLES.stravaMigrationLimit = isNumeric(FORM.limite) ? min(10,max(1,val(FORM.limite))) : 5/>
        <cfset VARIABLES.stravaMigrationSelectedIds = []/>
        <cfloop list="#FORM.modalidade_ids#" item="migrationSelectedId">
            <cfif isNumeric(migrationSelectedId)
                AND val(migrationSelectedId) GT 0
                AND NOT arrayFind(VARIABLES.stravaMigrationSelectedIds,val(migrationSelectedId))>
                <cfset arrayAppend(VARIABLES.stravaMigrationSelectedIds,val(migrationSelectedId))/>
            </cfif>
        </cfloop>

        <cfquery name="qStravaMigrationBatch">
            SELECT id_evento_percurso
            FROM tb_percurso_migracoes_strava
            WHERE 1 = 1
            AND (
                status IN ('pendente', 'erro', 'revisao'<cfif NOT VARIABLES.stravaMigrationDryRun>, 'validado'</cfif>)
                OR (status = 'processando' AND data_atualizacao < now() - interval '15 minutes')
            )
            <cfif arrayLen(VARIABLES.stravaMigrationSelectedIds)>
                AND id_evento_percurso IN (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayToList(VARIABLES.stravaMigrationSelectedIds)#" list="true"/>
                )
            </cfif>
            ORDER BY CASE status
                         WHEN 'pendente' THEN 1
                         WHEN 'validado' THEN 2
                         WHEN 'erro' THEN 3
                         WHEN 'revisao' THEN 4
                         ELSE 5
                     END,
                     id_evento_percurso
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.stravaMigrationLimit#"/>
        </cfquery>

        <cfif NOT qStravaMigrationBatch.recordcount>
            <cfset VARIABLES.stravaMigrationAlert = {type="warning", message="Nenhuma modalidade elegivel foi encontrada para este lote."}/>
        <cfelse>
                <cfset VARIABLES.stravaMigrationProcessed = 0/>
                <cfset VARIABLES.stravaMigrationSucceeded = 0/>
                <cfset VARIABLES.stravaMigrationReused = 0/>
                <cfset VARIABLES.stravaMigrationErrors = 0/>
                <cfset VARIABLES.stravaMigrationReviews = 0/>
                    <cfloop query="qStravaMigrationBatch">
                        <cfquery name="qStravaMigrationClaim">
                            UPDATE tb_percurso_migracoes_strava
                            SET status = 'processando',
                                tentativas = tentativas + 1,
                                mensagem = 'Processando rota Strava.',
                                id_usuario_ultima_acao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>,
                                data_ultima_tentativa = now(),
                                data_atualizacao = now()
                            WHERE id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationBatch.id_evento_percurso#"/>
                              AND (
                                  status IN ('pendente','erro','revisao'<cfif NOT VARIABLES.stravaMigrationDryRun>,'validado'</cfif>)
                                  OR (status = 'processando' AND data_atualizacao < now() - interval '15 minutes')
                              )
                            RETURNING id_evento_percurso
                        </cfquery>
                        <cfif qStravaMigrationClaim.recordcount>
                        <cfset VARIABLES.stravaMigrationProcessed++/>
                        <cfset VARIABLES.stravaMigrationTempDir = ""/>
                        <cfset VARIABLES.stravaMigrationRouteDiskDir = ""/>
                        <cfset VARIABLES.stravaMigrationHttpStatus = 0/>
                        <cftry>
                            <cfquery name="qStravaMigrationSource">
                                SELECT migracao.id_evento_percurso,
                                       migracao.id_evento,
                                       migracao.strava_route_id,
                                       modalidade.percurso_evento,
                                       modalidade.unidade_de_medida,
                                       modalidade.tipo_corrida,
                                       evento.nome_evento,
                                       evento.cidade,
                                       evento.estado,
                                       evento.pais,
                                       coalesce(contas.total, 0) AS total_contas,
                                       contas.id_conta
                                FROM tb_percurso_migracoes_strava migracao
                                INNER JOIN tb_evento_corridas_percursos modalidade
                                    ON modalidade.id_evento_percurso = migracao.id_evento_percurso
                                INNER JOIN tb_evento_corridas evento
                                    ON evento.id_evento = modalidade.id_evento
                                LEFT JOIN LATERAL (
                                    SELECT count(*) AS total,
                                           min(conta_evento.id_conta) AS id_conta
                                    FROM tb_conta_eventos conta_evento
                                    INNER JOIN tb_contas conta
                                        ON conta.id_conta = conta_evento.id_conta
                                       AND conta.status = 'ATIVA'::status_conta
                                    WHERE conta_evento.id_evento = modalidade.id_evento
                                      AND conta_evento.status = 'ATIVO'::status_conta_evento
                                ) contas ON true
                                WHERE migracao.id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationBatch.id_evento_percurso#"/>
                                LIMIT 1
                            </cfquery>

                            <cfif NOT qStravaMigrationSource.recordcount>
                                <cfthrow message="A modalidade original nao foi encontrada."/>
                            </cfif>

                            <cfset VARIABLES.stravaMigrationRouteId = trim(qStravaMigrationSource.strava_route_id & "")/>
                            <cfset VARIABLES.stravaMigrationNominalM = stravaMigrationDistanceMeters(
                                qStravaMigrationSource.percurso_evento,
                                qStravaMigrationSource.unidade_de_medida
                            )/>
                            <cfset VARIABLES.stravaMigrationItemFinalized = false/>

                            <cfif NOT reFind("^[0-9]{1,32}$", VARIABLES.stravaMigrationRouteId)>
                                <cfset stravaMigrationUpdate(
                                    qStravaMigrationSource.id_evento_percurso,
                                    "revisao",
                                    "O campo mapa nao contem um identificador numerico de rota do Strava.",
                                    0, "", 0, 0, 0,
                                    {stravaRouteId=VARIABLES.stravaMigrationRouteId},
                                    false
                                )/>
                                <cfset VARIABLES.stravaMigrationReviews++/>
                                <cfset VARIABLES.stravaMigrationItemFinalized = true/>
                            <cfelseif VARIABLES.stravaMigrationNominalM LTE 0>
                                <cfset stravaMigrationUpdate(
                                    qStravaMigrationSource.id_evento_percurso,
                                    "revisao",
                                    "A unidade de medida da modalidade nao permite calcular a distancia nominal em metros.",
                                    0, "", 0, 0, 0,
                                    {distance=qStravaMigrationSource.percurso_evento,unit=qStravaMigrationSource.unidade_de_medida},
                                    false
                                )/>
                                <cfset VARIABLES.stravaMigrationReviews++/>
                                <cfset VARIABLES.stravaMigrationItemFinalized = true/>
                            </cfif>

                            <cfif NOT VARIABLES.stravaMigrationItemFinalized>
                                <cfset VARIABLES.stravaMigrationTempDir = getTempDirectory() & "strava-route-migration-" & createUUID()/>
                                <cfdirectory action="create" directory="#VARIABLES.stravaMigrationTempDir#"/>
                                <cfset VARIABLES.stravaMigrationTempGpx = VARIABLES.stravaMigrationTempDir & "/strava-route-" & VARIABLES.stravaMigrationRouteId & ".gpx"/>
                                <cfset VARIABLES.stravaMigrationTempGeo = VARIABLES.stravaMigrationTempDir & "/route.geojson"/>
                                <cfset VARIABLES.stravaMigrationDownloadUrl = "https://www.strava.com/routes/" & VARIABLES.stravaMigrationRouteId & "/export_gpx"/>

                                <cfhttp method="get"
                                    url="#VARIABLES.stravaMigrationDownloadUrl#"
                                    result="stravaMigrationDownload"
                                    timeout="45"
                                    redirect="true"
                                    throwonerror="false"
                                    getasbinary="yes"
                                    useragent="RoadRunners-Business-Strava-Migration/1.0"/>

                                <cfif structKeyExists(stravaMigrationDownload,"statusCode")>
                                    <cfset VARIABLES.stravaMigrationHttpStatus = val(listFirst(stravaMigrationDownload.statusCode," "))/>
                                </cfif>
                                <cfif VARIABLES.stravaMigrationHttpStatus NEQ 200>
                                    <cfthrow message="O Strava retornou HTTP #VARIABLES.stravaMigrationHttpStatus# ao exportar a rota."/>
                                </cfif>
                                <cfif NOT structKeyExists(stravaMigrationDownload,"fileContent")>
                                    <cfthrow message="O Strava nao retornou conteudo para o arquivo GPX."/>
                                </cfif>

                                <cfset fileWrite(VARIABLES.stravaMigrationTempGpx,stravaMigrationDownload.fileContent)/>
                                <cfset VARIABLES.stravaMigrationDownloadedInfo = getFileInfo(VARIABLES.stravaMigrationTempGpx)/>
                                <cfif VARIABLES.stravaMigrationDownloadedInfo.size LTE 0 OR VARIABLES.stravaMigrationDownloadedInfo.size GT 20971520>
                                    <cfthrow message="O arquivo retornado pelo Strava esta vazio ou excede o limite de 20 MB."/>
                                </cfif>

                                <cfset VARIABLES.stravaMigrationGpxService = createObject("component","percursos.includes.PercursoGpxService")/>
                                <cfset VARIABLES.stravaMigrationAnalysis = VARIABLES.stravaMigrationGpxService.analyze(VARIABLES.stravaMigrationTempGpx)/>
                                <cfif NOT VARIABLES.stravaMigrationAnalysis.valid>
                                    <cfthrow message="#arrayToList(VARIABLES.stravaMigrationAnalysis.errors,' ')#"/>
                                </cfif>

                                <cfset VARIABLES.stravaMigrationData = {
                                    stravaRouteId=VARIABLES.stravaMigrationRouteId,
                                    sourceUrl=VARIABLES.stravaMigrationDownloadUrl,
                                    nominalDistanceM=VARIABLES.stravaMigrationNominalM,
                                    gpxDistanceM=VARIABLES.stravaMigrationAnalysis.distanceM,
                                    distanceDifferenceM=abs(VARIABLES.stravaMigrationAnalysis.distanceM-VARIABLES.stravaMigrationNominalM),
                                    pointCount=VARIABLES.stravaMigrationAnalysis.pointCount,
                                    eventId=qStravaMigrationSource.id_evento,
                                    eventRouteId=qStravaMigrationSource.id_evento_percurso
                                }/>

                                <cfif VARIABLES.stravaMigrationDryRun>
                                    <cfset stravaMigrationUpdate(
                                        qStravaMigrationSource.id_evento_percurso,
                                        "validado",
                                        "GPX validado. Nenhum percurso foi criado porque a execucao estava em modo de simulacao.",
                                        VARIABLES.stravaMigrationHttpStatus,
                                        VARIABLES.stravaMigrationAnalysis.sha256,
                                        VARIABLES.stravaMigrationAnalysis.distanceM,
                                        0, 0,
                                        VARIABLES.stravaMigrationData,
                                        false
                                    )/>
                                    <cfset VARIABLES.stravaMigrationSucceeded++/>
                                <cfelse>
                                    <cfquery name="qStravaMigrationExactLink">
                                        SELECT vinculo.id_percurso,
                                               arquivo.id_percurso_arquivo,
                                               arquivo.sha256
                                        FROM tb_evento_percursos_gpx vinculo
                                        LEFT JOIN LATERAL (
                                            SELECT id_percurso_arquivo, sha256
                                            FROM tb_percurso_arquivos
                                            WHERE id_percurso = vinculo.id_percurso
                                              AND ativo = true
                                            ORDER BY versao DESC
                                            LIMIT 1
                                        ) arquivo ON true
                                        WHERE vinculo.id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento_percurso#"/>
                                        LIMIT 1
                                    </cfquery>

                                    <cfif qStravaMigrationExactLink.recordcount>
                                        <cfif compareNoCase(trim(qStravaMigrationExactLink.sha256 & ""), VARIABLES.stravaMigrationAnalysis.sha256) EQ 0>
                                            <cfset stravaMigrationUpdate(
                                                qStravaMigrationSource.id_evento_percurso,
                                                "migrado",
                                                "A modalidade ja estava vinculada a este mesmo GPX.",
                                                VARIABLES.stravaMigrationHttpStatus,
                                                VARIABLES.stravaMigrationAnalysis.sha256,
                                                VARIABLES.stravaMigrationAnalysis.distanceM,
                                                qStravaMigrationExactLink.id_percurso,
                                                qStravaMigrationExactLink.id_percurso_arquivo,
                                                VARIABLES.stravaMigrationData,
                                                true
                                            )/>
                                            <cfset VARIABLES.stravaMigrationSucceeded++/>
                                        <cfelse>
                                            <cfset VARIABLES.stravaMigrationData.existingRouteId = qStravaMigrationExactLink.id_percurso/>
                                            <cfset stravaMigrationUpdate(
                                                qStravaMigrationSource.id_evento_percurso,
                                                "revisao",
                                                "A modalidade ja esta vinculada a outro GPX. O vinculo nao foi substituido automaticamente.",
                                                VARIABLES.stravaMigrationHttpStatus,
                                                VARIABLES.stravaMigrationAnalysis.sha256,
                                                VARIABLES.stravaMigrationAnalysis.distanceM,
                                                qStravaMigrationExactLink.id_percurso,
                                                qStravaMigrationExactLink.id_percurso_arquivo,
                                                VARIABLES.stravaMigrationData,
                                                false
                                            )/>
                                            <cfset VARIABLES.stravaMigrationReviews++/>
                                        </cfif>
                                    <cfelse>
                                        <cfquery name="qStravaMigrationDuplicate">
                                            SELECT percurso.id_percurso,
                                                   arquivo.id_percurso_arquivo
                                            FROM tb_percursos percurso
                                            INNER JOIN LATERAL (
                                                SELECT versao,
                                                       id_percurso_arquivo,
                                                       sha256,
                                                       criado_em
                                                FROM tb_percurso_arquivos
                                                WHERE id_percurso = percurso.id_percurso
                                                  AND ativo = true
                                                ORDER BY versao DESC
                                                LIMIT 1
                                            ) arquivo ON true
                                            WHERE arquivo.sha256 = <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.stravaMigrationAnalysis.sha256#"/>
                                            ORDER BY arquivo.criado_em, arquivo.id_percurso_arquivo
                                            LIMIT 1
                                        </cfquery>

                                        <cfif qStravaMigrationDuplicate.recordcount>
                                            <cftransaction>
                                                <cfquery name="qStravaMigrationManualLink">
                                                    SELECT id_evento_percurso_gpx
                                                    FROM tb_evento_percursos_gpx
                                                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento#"/>
                                                      AND id_percurso = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationDuplicate.id_percurso#"/>
                                                      AND id_evento_percurso IS NULL
                                                    LIMIT 1
                                                </cfquery>
                                                <cfif qStravaMigrationManualLink.recordcount>
                                                    <cfquery>
                                                        UPDATE tb_evento_percursos_gpx
                                                        SET id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento_percurso#"/>
                                                        WHERE id_evento_percurso_gpx = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationManualLink.id_evento_percurso_gpx#"/>
                                                    </cfquery>
                                                <cfelse>
                                                    <cfquery>
                                                        INSERT INTO tb_evento_percursos_gpx
                                                            (id_evento, id_evento_percurso, id_percurso, id_usuario_criador)
                                                        VALUES (
                                                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento#"/>,
                                                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento_percurso#"/>,
                                                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationDuplicate.id_percurso#"/>,
                                                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>
                                                        )
                                                    </cfquery>
                                                </cfif>
                                                <cfquery>
                                                    INSERT INTO tb_percurso_historico
                                                        (id_percurso,id_percurso_arquivo,id_usuario,acao,dados,endereco_ip)
                                                    VALUES (
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationDuplicate.id_percurso#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationDuplicate.id_percurso_arquivo#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>,
                                                        'reutilizar_strava',
                                                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.stravaMigrationData)#"/> AS jsonb),
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>
                                                    )
                                                </cfquery>
                                                <cfset stravaMigrationUpdate(
                                                    qStravaMigrationSource.id_evento_percurso,
                                                    "reutilizado",
                                                    "GPX identico encontrado no repositorio. O percurso existente foi reutilizado.",
                                                    VARIABLES.stravaMigrationHttpStatus,
                                                    VARIABLES.stravaMigrationAnalysis.sha256,
                                                    VARIABLES.stravaMigrationAnalysis.distanceM,
                                                    qStravaMigrationDuplicate.id_percurso,
                                                    qStravaMigrationDuplicate.id_percurso_arquivo,
                                                    VARIABLES.stravaMigrationData,
                                                    true
                                                )/>
                                            </cftransaction>
                                            <cfset VARIABLES.stravaMigrationReused++/>
                                            <cfset VARIABLES.stravaMigrationSucceeded++/>
                                        <cfelse>
                                            <cfset VARIABLES.stravaMigrationGpxService.writeGeoJson(VARIABLES.stravaMigrationAnalysis,VARIABLES.stravaMigrationTempGeo)/>
                                            <cfset VARIABLES.stravaMigrationRouteName = trim(qStravaMigrationSource.nome_evento)
                                                & " - " & qStravaMigrationSource.percurso_evento
                                                & " " & qStravaMigrationSource.unidade_de_medida/>
                                            <cfset VARIABLES.stravaMigrationResolvedRouteType = stravaMigrationRouteType(qStravaMigrationSource.tipo_corrida)/>
                                            <cfset VARIABLES.stravaMigrationAccountId = val(qStravaMigrationSource.total_contas) EQ 1
                                                ? val(qStravaMigrationSource.id_conta)
                                                : 0/>
                                            <cftransaction>
                                                <cfquery name="qStravaMigrationNewRoute">
                                                    INSERT INTO tb_percursos
                                                        (codigo_publico,nome,cidade,estado,pais,distancia_nominal_m,tipo_percurso,descricao,visibilidade,status,id_usuario_criador,id_conta_responsavel)
                                                    VALUES (
                                                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#createUUID()#"/> AS uuid),
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(VARIABLES.stravaMigrationRouteName,180)#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(qStravaMigrationSource.cidade & '')#" null="#!len(trim(qStravaMigrationSource.cidade & ''))#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(qStravaMigrationSource.estado & ''))#" null="#!len(trim(qStravaMigrationSource.estado & ''))#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(qStravaMigrationSource.pais & ''))#" null="#!len(trim(qStravaMigrationSource.pais & ''))#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.stravaMigrationNominalM#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.stravaMigrationResolvedRouteType#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#'Migrado da rota Strava ' & VARIABLES.stravaMigrationRouteId & ' vinculada a modalidade ' & qStravaMigrationSource.id_evento_percurso & '.'#"/>,
                                                        'privado',
                                                        'rascunho',
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationAccountId#" null="#VARIABLES.stravaMigrationAccountId LTE 0#"/>
                                                    )
                                                    RETURNING id_percurso
                                                </cfquery>
                                                <cfset VARIABLES.stravaMigrationNewRouteId = val(qStravaMigrationNewRoute.id_percurso)/>
                                                <cfset VARIABLES.stravaMigrationRelativeDir = VARIABLES.stravaMigrationNewRouteId & "/1"/>
                                                <cfset VARIABLES.stravaMigrationRouteDiskDir = VARIABLES.stravaMigrationStoragePath & "/" & VARIABLES.stravaMigrationRelativeDir/>
                                                <cfif NOT directoryExists(VARIABLES.stravaMigrationRouteDiskDir)>
                                                    <cfdirectory action="create" directory="#VARIABLES.stravaMigrationRouteDiskDir#" recurse="true"/>
                                                </cfif>
                                                <cffile action="move" source="#VARIABLES.stravaMigrationTempGpx#" destination="#VARIABLES.stravaMigrationRouteDiskDir#/original.gpx"/>
                                                <cffile action="move" source="#VARIABLES.stravaMigrationTempGeo#" destination="#VARIABLES.stravaMigrationRouteDiskDir#/route.geojson"/>

                                                <cfquery name="qStravaMigrationNewFile">
                                                    INSERT INTO tb_percurso_arquivos
                                                        (id_percurso,versao,storage_key,geojson_storage_key,nome_original,mime_type,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,id_usuario_criador)
                                                    VALUES (
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationNewRouteId#"/>,
                                                        1,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.stravaMigrationRelativeDir & '/original.gpx'#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.stravaMigrationRelativeDir & '/route.geojson'#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#'strava-route-' & VARIABLES.stravaMigrationRouteId & '.gpx'#"/>,
                                                        'application/gpx+xml',
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationDownloadedInfo.size#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.stravaMigrationAnalysis.sha256#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.stravaMigrationAnalysis.pointCount#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.distanceM#" scale="2"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.elevationMin#" null="#!len(VARIABLES.stravaMigrationAnalysis.elevationMin & '')#" scale="2"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.elevationMax#" null="#!len(VARIABLES.stravaMigrationAnalysis.elevationMax & '')#" scale="2"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.elevationGainM#" scale="2"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.minLat#" scale="7"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.minLng#" scale="7"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.maxLat#" scale="7"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.stravaMigrationAnalysis.maxLng#" scale="7"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>
                                                    )
                                                    RETURNING id_percurso_arquivo
                                                </cfquery>
                                                <cfquery>
                                                    INSERT INTO tb_evento_percursos_gpx
                                                        (id_evento,id_evento_percurso,id_percurso,id_usuario_criador)
                                                    VALUES (
                                                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qStravaMigrationSource.id_evento_percurso#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationNewRouteId#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>
                                                    )
                                                </cfquery>
                                                <cfquery>
                                                    INSERT INTO tb_percurso_historico
                                                        (id_percurso,id_percurso_arquivo,id_usuario,acao,dados,endereco_ip)
                                                    VALUES (
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationNewRouteId#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qStravaMigrationNewFile.id_percurso_arquivo#"/>,
                                                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.stravaMigrationActorId#"/>,
                                                        'migrar_strava',
                                                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.stravaMigrationData)#"/> AS jsonb),
                                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>
                                                    )
                                                </cfquery>
                                                <cfset stravaMigrationUpdate(
                                                    qStravaMigrationSource.id_evento_percurso,
                                                    "migrado",
                                                    "GPX migrado e associado a modalidade original.",
                                                    VARIABLES.stravaMigrationHttpStatus,
                                                    VARIABLES.stravaMigrationAnalysis.sha256,
                                                    VARIABLES.stravaMigrationAnalysis.distanceM,
                                                    VARIABLES.stravaMigrationNewRouteId,
                                                    qStravaMigrationNewFile.id_percurso_arquivo,
                                                    VARIABLES.stravaMigrationData,
                                                    true
                                                )/>
                                            </cftransaction>
                                            <cfset VARIABLES.stravaMigrationSucceeded++/>
                                        </cfif>
                                    </cfif>
                                </cfif>
                            </cfif>
                            <cfcatch type="any">
                                <cfif len(VARIABLES.stravaMigrationRouteDiskDir) AND directoryExists(VARIABLES.stravaMigrationRouteDiskDir)>
                                    <cftry>
                                        <cfdirectory action="delete" directory="#VARIABLES.stravaMigrationRouteDiskDir#" recurse="true"/>
                                        <cfcatch type="any"></cfcatch>
                                    </cftry>
                                </cfif>
                                <cfset stravaMigrationUpdate(
                                    qStravaMigrationBatch.id_evento_percurso,
                                    "erro",
                                    cfcatch.message,
                                    VARIABLES.stravaMigrationHttpStatus,
                                    "", 0, 0, 0,
                                    {detail=left(cfcatch.detail & "",2000)},
                                    false
                                )/>
                                <cflog file="business-percursos" type="error" text="Falha na migracao Strava da modalidade #qStravaMigrationBatch.id_evento_percurso#: #cfcatch.message# #cfcatch.detail#"/>
                                <cfset VARIABLES.stravaMigrationErrors++/>
                            </cfcatch>
                            <cffinally>
                                <cfif len(VARIABLES.stravaMigrationTempDir) AND directoryExists(VARIABLES.stravaMigrationTempDir)>
                                    <cftry>
                                        <cfdirectory action="delete" directory="#VARIABLES.stravaMigrationTempDir#" recurse="true"/>
                                        <cfcatch type="any"></cfcatch>
                                    </cftry>
                                </cfif>
                            </cffinally>
                        </cftry>
                        </cfif>
                    </cfloop>
                <cfset SESSION.stravaMigrationFlash = {
                    type=(VARIABLES.stravaMigrationErrors GT 0 ? "warning" : "success"),
                    message=(VARIABLES.stravaMigrationDryRun ? "Simulacao" : "Migracao")
                        & " concluida: " & VARIABLES.stravaMigrationProcessed & " processado(s), "
                        & VARIABLES.stravaMigrationSucceeded & " validado(s)/migrado(s), "
                        & VARIABLES.stravaMigrationReused & " reutilizado(s), "
                        & VARIABLES.stravaMigrationReviews & " para revisao e "
                        & VARIABLES.stravaMigrationErrors & " erro(s)."
                }/>
                <cflocation addtoken="false" url="./migracao-strava.cfm"/>
        </cfif>
    </cfif>
</cfif>

<cfset VARIABLES.stravaMigrationAllowedStatuses = "todos,pendente,processando,validado,migrado,reutilizado,revisao,erro,ignorado"/>
<cfif NOT listFindNoCase(VARIABLES.stravaMigrationAllowedStatuses,URL.status)>
    <cfset URL.status = "todos"/>
</cfif>
<cfset VARIABLES.stravaMigrationPage = isNumeric(URL.pagina) ? max(1,val(URL.pagina)) : 1/>
<cfset VARIABLES.stravaMigrationPerPage = 100/>
<cfset VARIABLES.stravaMigrationOffset = (VARIABLES.stravaMigrationPage-1)*VARIABLES.stravaMigrationPerPage/>
<cfset qStravaMigrationStats = queryNew("total,pendente,processando,validado,migrado,reutilizado,revisao,erro,ignorado")/>
<cfset qStravaMigrationItems = queryNew("id_evento_percurso,id_evento,strava_route_id,strava_url,status,id_percurso,id_percurso_arquivo,sha256,distancia_gpx_m,tentativas,ultimo_http_status,mensagem,data_atualizacao,data_conclusao,nome_evento,cidade,estado,percurso_evento,unidade_de_medida,tipo_corrida")/>
<cfset VARIABLES.stravaMigrationTotal = 0/>

<cfif VARIABLES.stravaMigrationSchemaReady>
    <cfquery name="qStravaMigrationStats">
        SELECT count(*) AS total,
               count(*) FILTER (WHERE status = 'pendente') AS pendente,
               count(*) FILTER (WHERE status = 'processando') AS processando,
               count(*) FILTER (WHERE status = 'validado') AS validado,
               count(*) FILTER (WHERE status = 'migrado') AS migrado,
               count(*) FILTER (WHERE status = 'reutilizado') AS reutilizado,
               count(*) FILTER (WHERE status = 'revisao') AS revisao,
               count(*) FILTER (WHERE status = 'erro') AS erro,
               count(*) FILTER (WHERE status = 'ignorado') AS ignorado
        FROM tb_percurso_migracoes_strava
    </cfquery>

    <cfquery name="qStravaMigrationCount">
        SELECT count(*) AS total
        FROM tb_percurso_migracoes_strava migracao
        INNER JOIN tb_evento_corridas_percursos modalidade
            ON modalidade.id_evento_percurso = migracao.id_evento_percurso
        INNER JOIN tb_evento_corridas evento
            ON evento.id_evento = modalidade.id_evento
        WHERE 1 = 1
        <cfif URL.status NEQ "todos">
            AND migracao.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.status#"/>
        </cfif>
        <cfif len(trim(URL.busca))>
            AND (
                evento.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
                OR migracao.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
                OR migracao.id_evento_percurso::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
                OR migracao.strava_route_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
            )
        </cfif>
    </cfquery>
    <cfset VARIABLES.stravaMigrationTotal = val(qStravaMigrationCount.total)/>

    <cfquery name="qStravaMigrationItems">
        SELECT migracao.id_evento_percurso,
               migracao.id_evento,
               migracao.strava_route_id,
               migracao.strava_url,
               migracao.status,
               migracao.id_percurso,
               migracao.id_percurso_arquivo,
               migracao.sha256,
               migracao.distancia_gpx_m,
               migracao.tentativas,
               migracao.ultimo_http_status,
               migracao.mensagem,
               migracao.data_atualizacao,
               migracao.data_conclusao,
               evento.nome_evento,
               evento.cidade,
               evento.estado,
               modalidade.percurso_evento,
               modalidade.unidade_de_medida,
               modalidade.tipo_corrida
        FROM tb_percurso_migracoes_strava migracao
        INNER JOIN tb_evento_corridas_percursos modalidade
            ON modalidade.id_evento_percurso = migracao.id_evento_percurso
        INNER JOIN tb_evento_corridas evento
            ON evento.id_evento = modalidade.id_evento
        WHERE 1 = 1
        <cfif URL.status NEQ "todos">
            AND migracao.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.status#"/>
        </cfif>
        <cfif len(trim(URL.busca))>
            AND (
                evento.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
                OR migracao.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
                OR migracao.id_evento_percurso::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
                OR migracao.strava_route_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>
            )
        </cfif>
        ORDER BY CASE migracao.status
                     WHEN 'revisao' THEN 1
                     WHEN 'erro' THEN 2
                     WHEN 'pendente' THEN 3
                     WHEN 'validado' THEN 4
                     WHEN 'processando' THEN 5
                     ELSE 6
                 END,
                 evento.nome_evento,
                 modalidade.percurso_evento,
                 migracao.id_evento_percurso
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.stravaMigrationPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.stravaMigrationOffset#"/>
    </cfquery>
</cfif>

<cfset VARIABLES.stravaMigrationTotalPages = max(1,ceiling(VARIABLES.stravaMigrationTotal/VARIABLES.stravaMigrationPerPage))/>
