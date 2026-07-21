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
<cfparam name="URL.sucesso" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.percursoSchemaReady = percursoTablesReady()/>
<cfset VARIABLES.percursoAlert = {type="", message=""}/>
<cfset VARIABLES.percursoActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.percursoIsAdmin = isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.percursoAccountIds = isDefined("VARIABLES.businessEffectiveAccountIds") ? VARIABLES.businessEffectiveAccountIds : "0"/>
<cfset VARIABLES.percursoWriteAccountIds = isDefined("VARIABLES.businessEffectiveAccountOperatorIds") ? VARIABLES.businessEffectiveAccountOperatorIds : "0"/>
<cfset VARIABLES.percursoCanWrite = VARIABLES.percursoIsAdmin OR (len(trim(VARIABLES.percursoWriteAccountIds)) AND VARIABLES.percursoWriteAccountIds NEQ "0")/>
<cfset VARIABLES.percursoSelectedId = isNumeric(URL.id) ? val(URL.id) : 0/>
<cfset VARIABLES.percursoIsOwner = false/>
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

<cfif NOT structKeyExists(SESSION, "percursoCsrfToken") OR NOT len(trim(SESSION.percursoCsrfToken & ""))>
    <cfset SESSION.percursoCsrfToken = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.percursoCsrfToken = SESSION.percursoCsrfToken/>

<cfif URL.sucesso EQ "criado"><cfset VARIABLES.percursoAlert={type="success",message="Percurso criado e GPX processado com sucesso."}/></cfif>
<cfif URL.sucesso EQ "salvo"><cfset VARIABLES.percursoAlert={type="success",message="Dados do percurso atualizados."}/></cfif>
<cfif URL.sucesso EQ "versao"><cfset VARIABLES.percursoAlert={type="success",message="Nova versao do GPX adicionada."}/></cfif>
<cfif URL.sucesso EQ "status"><cfset VARIABLES.percursoAlert={type="success",message="Status do percurso atualizado."}/></cfif>

<cfif VARIABLES.percursoSchemaReady AND len(trim(FORM.acao))>
    <cfif compareNoCase(trim(FORM.csrf_token), VARIABLES.percursoCsrfToken) NEQ 0>
        <cfset VARIABLES.percursoAlert={type="danger",message="A sessao do formulario expirou. Recarregue a pagina."}/>
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
            <cfif NOT VARIABLES.percursoIsAdmin>AND (id_usuario_criador=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/> OR id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>) OR visibilidade IN ('compartilhado','publico'))</cfif>
        </cfquery>
        <cfif qPercurso.recordcount>
            <cfset VARIABLES.percursoIsOwner = val(qPercurso.id_usuario_criador) EQ VARIABLES.percursoActorId/>
            <cfquery name="qPercursoArquivos">SELECT id_percurso_arquivo,versao,nome_original,tamanho_bytes,sha256,quantidade_pontos,distancia_gpx_m,elevacao_min_m,elevacao_max_m,ganho_elevacao_m,bbox_min_lat,bbox_min_lng,bbox_max_lat,bbox_max_lng,ativo,criado_em FROM tb_percurso_arquivos WHERE id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> ORDER BY versao DESC</cfquery>
            <cfif VARIABLES.percursoIsOwner>
                <cfquery name="qPercursoHistorico">SELECT hist.acao,hist.dados,hist.endereco_ip,hist.criado_em,usr.name AS usuario_nome FROM tb_percurso_historico hist LEFT JOIN tb_usuarios usr ON usr.id=hist.id_usuario WHERE hist.id_percurso=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoSelectedId#"/> ORDER BY hist.criado_em DESC LIMIT 30</cfquery>
            </cfif>
        </cfif>
    </cfif>
    <cfquery name="qPercursos">
        SELECT p.*, latest.versao,latest.distancia_gpx_m,latest.quantidade_pontos FROM tb_percursos p LEFT JOIN LATERAL (SELECT versao,distancia_gpx_m,quantidade_pontos FROM tb_percurso_arquivos a WHERE a.id_percurso=p.id_percurso ORDER BY versao DESC LIMIT 1) latest ON true WHERE 1=1
        <cfif NOT VARIABLES.percursoIsAdmin>AND (p.id_usuario_criador=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoActorId#"/> OR p.id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.percursoAccountIds#" list="true"/>) OR p.visibilidade IN ('compartilhado','publico'))</cfif>
        <cfif len(trim(URL.q))>AND (p.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.q)#%"/> OR p.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.q)#%"/>)</cfif>
        <cfif len(trim(URL.estado))>AND p.estado=<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(URL.estado))#"/></cfif>
        <cfif listFindNoCase("rascunho,publicado,arquivado",URL.status)>AND p.status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(URL.status)#"/></cfif>
        ORDER BY p.atualizado_em DESC LIMIT 500
    </cfquery>
</cfif>
