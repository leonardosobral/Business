<cfscript>
function runnerAppsBuildBaseUrl() {
    var isHttps = false;
    var hostName = "business.roadrunners.run";

    if (structKeyExists(CGI, "https")) {
        isHttps = isBoolean(CGI.https) ? CGI.https : listFindNoCase("on,1,yes,true", trim(CGI.https));
    }

    if (structKeyExists(CGI, "http_host") AND len(trim(CGI.http_host))) {
        hostName = trim(CGI.http_host);
    }

    return (isHttps ? "https://" : "http://") & hostName;
}

function runnerAppsDirectoryWritable(required string directoryPath) {
    var directoryFile = createObject("java", "java.io.File").init(arguments.directoryPath);
    return directoryFile.exists() AND directoryFile.canWrite();
}

function runnerAppsNormalizeBoolean(required any value) {
    if (isBoolean(arguments.value)) {
        return arguments.value;
    }

    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function runnerAppsAssetUrl(required string imagePath) {
    var normalizedPath = trim(arguments.imagePath);

    if (!len(normalizedPath)) {
        return "";
    }

    if (reFindNoCase("^(https?:)?//", normalizedPath) OR left(normalizedPath, 5) EQ "data:") {
        return normalizedPath;
    }

    return runnerAppsBuildBaseUrl() & (left(normalizedPath, 1) EQ "/" ? normalizedPath : "/" & normalizedPath);
}
</cfscript>

<cfparam name="URL.grupo_editar" default=""/>
<cfparam name="URL.app_editar" default=""/>
<cfparam name="URL.acao" default=""/>
<cfparam name="URL.id_group" default=""/>
<cfparam name="URL.id_app" default=""/>
<cfparam name="URL.ativo" default=""/>
<cfparam name="FORM.acao" default=""/>

<cfset VARIABLES.runnerAppsUploadWebRoot = "/portal/runner-apps/assets/"/>
<cfset VARIABLES.runnerAppsUploadDiskPath = expandPath("../runner-apps/assets/")/>
<cfset VARIABLES.runnerAppsAlert = { type = "", message = "" }/>

<cfquery name="qRunnerAppsTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = current_schema()
      AND table_name IN ('tb_portal_runner_app_groups', 'tb_portal_runner_apps')
</cfquery>

<cfset VARIABLES.runnerAppsTablesList = valueList(qRunnerAppsTables.table_name)/>
<cfset VARIABLES.runnerAppsTablesReady = listFindNoCase(VARIABLES.runnerAppsTablesList, "tb_portal_runner_app_groups") AND listFindNoCase(VARIABLES.runnerAppsTablesList, "tb_portal_runner_apps")/>

<cfif VARIABLES.runnerAppsTablesReady>
    <cfif NOT directoryExists(VARIABLES.runnerAppsUploadDiskPath)>
        <cftry>
            <cfdirectory action="create" directory="#VARIABLES.runnerAppsUploadDiskPath#"/>
        <cfcatch type="any">
            <cfset VARIABLES.runnerAppsAlert = {
                type = "danger",
                message = "Nao foi possivel preparar a pasta de upload dos icones em /portal/runner-apps/assets/."
            }/>
        </cfcatch>
        </cftry>
    </cfif>

    <cfif isDefined("qPerfil") AND qPerfil.recordcount AND qPerfil.is_admin>
        <cfif FORM.acao EQ "salvar_grupo">
            <cfset VARIABLES.runnerAppsGroupId = isDefined("FORM.id_group") ? trim(FORM.id_group) : ""/>
            <cfset VARIABLES.runnerAppsGroupName = isDefined("FORM.grupo_nome") ? trim(FORM.grupo_nome) : ""/>
            <cfset VARIABLES.runnerAppsGroupDescription = isDefined("FORM.grupo_descricao") ? trim(FORM.grupo_descricao) : ""/>
            <cfset VARIABLES.runnerAppsGroupOrder = isDefined("FORM.grupo_ordem") AND isNumeric(FORM.grupo_ordem) ? val(FORM.grupo_ordem) : 1/>
            <cfset VARIABLES.runnerAppsGroupActive = isDefined("FORM.grupo_ativo") AND runnerAppsNormalizeBoolean(FORM.grupo_ativo)/>

            <cfif NOT len(VARIABLES.runnerAppsGroupName)>
                <cfset VARIABLES.runnerAppsAlert = { type = "warning", message = "Informe o nome da linha/categoria." }/>
            <cfelseif len(VARIABLES.runnerAppsGroupId) AND isNumeric(VARIABLES.runnerAppsGroupId)>
                <cfquery>
                    UPDATE tb_portal_runner_app_groups
                    SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsGroupName#"/>,
                        descricao = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsGroupDescription#" null="#NOT len(VARIABLES.runnerAppsGroupDescription)#"/>,
                        ordem = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsGroupOrder#"/>,
                        ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsGroupActive#"/>,
                        atualizado_em = now()
                    WHERE id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsGroupId#"/>
                </cfquery>
                <cflocation addtoken="false" url="./?sucesso=grupo"/>
            <cfelse>
                <cfquery>
                    INSERT INTO tb_portal_runner_app_groups (nome, descricao, ordem, ativo)
                    VALUES (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsGroupName#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsGroupDescription#" null="#NOT len(VARIABLES.runnerAppsGroupDescription)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsGroupOrder#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsGroupActive#"/>
                    )
                </cfquery>
                <cflocation addtoken="false" url="./?sucesso=grupo"/>
            </cfif>
        </cfif>

        <cfif FORM.acao EQ "salvar_app">
            <cfset VARIABLES.runnerAppsSaveErrors = []/>
            <cfset VARIABLES.runnerAppsAppId = isDefined("FORM.id_app") ? trim(FORM.id_app) : ""/>
            <cfset VARIABLES.runnerAppsAppGroupId = isDefined("FORM.id_group") ? trim(FORM.id_group) : ""/>
            <cfset VARIABLES.runnerAppsAppName = isDefined("FORM.app_nome") ? trim(FORM.app_nome) : ""/>
            <cfset VARIABLES.runnerAppsAppUrl = isDefined("FORM.app_url") ? trim(FORM.app_url) : ""/>
            <cfset VARIABLES.runnerAppsAppImageUrl = isDefined("FORM.app_imagem_url") ? trim(FORM.app_imagem_url) : ""/>
            <cfset VARIABLES.runnerAppsAppCurrentImage = isDefined("FORM.app_imagem_atual") ? trim(FORM.app_imagem_atual) : ""/>
            <cfset VARIABLES.runnerAppsAppCurrentOriginal = isDefined("FORM.app_imagem_original_atual") ? trim(FORM.app_imagem_original_atual) : ""/>
            <cfset VARIABLES.runnerAppsAppAlt = isDefined("FORM.app_alt_text") ? trim(FORM.app_alt_text) : ""/>
            <cfset VARIABLES.runnerAppsAppNewTab = isDefined("FORM.app_abrir_nova_aba") AND runnerAppsNormalizeBoolean(FORM.app_abrir_nova_aba)/>
            <cfset VARIABLES.runnerAppsAppRel = isDefined("FORM.app_rel") ? trim(FORM.app_rel) : ""/>
            <cfset VARIABLES.runnerAppsAppOrder = isDefined("FORM.app_ordem") AND isNumeric(FORM.app_ordem) ? val(FORM.app_ordem) : 1/>
            <cfset VARIABLES.runnerAppsAppActive = isDefined("FORM.app_ativo") AND runnerAppsNormalizeBoolean(FORM.app_ativo)/>
            <cfset VARIABLES.runnerAppsAppHasFile = isDefined("FORM.app_icone") AND len(trim(FORM.app_icone & ""))/>

            <cfif NOT isNumeric(VARIABLES.runnerAppsAppGroupId)>
                <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Escolha a linha/categoria do app.")/>
            </cfif>
            <cfif NOT len(VARIABLES.runnerAppsAppName)>
                <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Informe o nome do app.")/>
            </cfif>
            <cfif NOT len(VARIABLES.runnerAppsAppUrl)>
                <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Informe a URL do app.")/>
            </cfif>
            <cfif NOT len(VARIABLES.runnerAppsAppImageUrl) AND NOT len(VARIABLES.runnerAppsAppCurrentImage) AND NOT VARIABLES.runnerAppsAppHasFile>
                <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Informe a URL do icone ou envie uma imagem.")/>
            </cfif>
            <cfif VARIABLES.runnerAppsAppHasFile AND NOT runnerAppsDirectoryWritable(VARIABLES.runnerAppsUploadDiskPath)>
                <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "A pasta de upload nao esta gravavel pelo servidor: " & VARIABLES.runnerAppsUploadDiskPath)/>
            </cfif>

            <cfif NOT arrayLen(VARIABLES.runnerAppsSaveErrors) AND VARIABLES.runnerAppsAppHasFile>
                <cftry>
                    <cffile action="upload"
                            filefield="app_icone"
                            destination="#VARIABLES.runnerAppsUploadDiskPath#"
                            nameconflict="makeunique"
                            result="runnerAppsUploadResult"/>

                    <cfset VARIABLES.runnerAppsUploadedExtension = lCase(runnerAppsUploadResult.serverFileExt)/>
                    <cfif NOT listFindNoCase("jpg,jpeg,png,gif,webp,svg", VARIABLES.runnerAppsUploadedExtension)>
                        <cfif fileExists(VARIABLES.runnerAppsUploadDiskPath & runnerAppsUploadResult.serverFile)>
                            <cffile action="delete" file="#VARIABLES.runnerAppsUploadDiskPath##runnerAppsUploadResult.serverFile#"/>
                        </cfif>
                        <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Use JPG, PNG, GIF, WEBP ou SVG para o icone.")/>
                    <cfelse>
                        <cfset VARIABLES.runnerAppsAppImageUrl = VARIABLES.runnerAppsUploadWebRoot & runnerAppsUploadResult.serverFile/>
                        <cfset VARIABLES.runnerAppsAppCurrentOriginal = runnerAppsUploadResult.clientFile/>
                    </cfif>
                <cfcatch type="any">
                    <cfset arrayAppend(VARIABLES.runnerAppsSaveErrors, "Nao foi possivel enviar o icone: " & cfcatch.message)/>
                </cfcatch>
                </cftry>
            </cfif>

            <cfif NOT len(VARIABLES.runnerAppsAppImageUrl)>
                <cfset VARIABLES.runnerAppsAppImageUrl = VARIABLES.runnerAppsAppCurrentImage/>
            </cfif>

            <cfif NOT len(VARIABLES.runnerAppsAppAlt)>
                <cfset VARIABLES.runnerAppsAppAlt = VARIABLES.runnerAppsAppName/>
            </cfif>

            <cfif arrayLen(VARIABLES.runnerAppsSaveErrors)>
                <cfset VARIABLES.runnerAppsAlert = { type = "warning", message = arrayToList(VARIABLES.runnerAppsSaveErrors, " ") }/>
            <cfelseif len(VARIABLES.runnerAppsAppId) AND isNumeric(VARIABLES.runnerAppsAppId)>
                <cfquery>
                    UPDATE tb_portal_runner_apps
                    SET id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsAppGroupId#"/>,
                        nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppName#"/>,
                        url = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsAppUrl#"/>,
                        imagem_url = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsAppImageUrl#"/>,
                        imagem_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppCurrentOriginal#" null="#NOT len(VARIABLES.runnerAppsAppCurrentOriginal)#"/>,
                        alt_text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppAlt#" null="#NOT len(VARIABLES.runnerAppsAppAlt)#"/>,
                        abrir_nova_aba = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsAppNewTab#"/>,
                        rel = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppRel#" null="#NOT len(VARIABLES.runnerAppsAppRel)#"/>,
                        ordem = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsAppOrder#"/>,
                        ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsAppActive#"/>,
                        atualizado_em = now()
                    WHERE id_app = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsAppId#"/>
                </cfquery>
                <cflocation addtoken="false" url="./?sucesso=app"/>
            <cfelse>
                <cfquery>
                    INSERT INTO tb_portal_runner_apps
                        (id_group, nome, url, imagem_url, imagem_original, alt_text, abrir_nova_aba, rel, ordem, ativo)
                    VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsAppGroupId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppName#"/>,
                            <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsAppUrl#"/>,
                            <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.runnerAppsAppImageUrl#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppCurrentOriginal#" null="#NOT len(VARIABLES.runnerAppsAppCurrentOriginal)#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppAlt#" null="#NOT len(VARIABLES.runnerAppsAppAlt)#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsAppNewTab#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.runnerAppsAppRel#" null="#NOT len(VARIABLES.runnerAppsAppRel)#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.runnerAppsAppOrder#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.runnerAppsAppActive#"/>
                        )
                </cfquery>
                <cflocation addtoken="false" url="./?sucesso=app"/>
            </cfif>
        </cfif>

        <cfif URL.acao EQ "toggle_app" AND isNumeric(URL.id_app) AND len(URL.ativo)>
            <cfquery>
                UPDATE tb_portal_runner_apps
                SET ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#runnerAppsNormalizeBoolean(URL.ativo)#"/>,
                    atualizado_em = now()
                WHERE id_app = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_app#"/>
            </cfquery>
            <cflocation addtoken="false" url="./?sucesso=status"/>
        </cfif>

        <cfif URL.acao EQ "delete_app" AND isNumeric(URL.id_app)>
            <cfquery>
                DELETE FROM tb_portal_runner_apps
                WHERE id_app = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_app#"/>
            </cfquery>
            <cflocation addtoken="false" url="./?sucesso=removido"/>
        </cfif>

        <cfif URL.acao EQ "toggle_group" AND isNumeric(URL.id_group) AND len(URL.ativo)>
            <cfquery>
                UPDATE tb_portal_runner_app_groups
                SET ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#runnerAppsNormalizeBoolean(URL.ativo)#"/>,
                    atualizado_em = now()
                WHERE id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_group#"/>
            </cfquery>
            <cflocation addtoken="false" url="./?sucesso=status"/>
        </cfif>

        <cfif URL.acao EQ "delete_group" AND isNumeric(URL.id_group)>
            <cfquery name="qRunnerAppsGroupUsage">
                SELECT count(*) AS total
                FROM tb_portal_runner_apps
                WHERE id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_group#"/>
            </cfquery>

            <cfif qRunnerAppsGroupUsage.total EQ 0>
                <cfquery>
                    DELETE FROM tb_portal_runner_app_groups
                    WHERE id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_group#"/>
                </cfquery>
                <cflocation addtoken="false" url="./?sucesso=grupo_removido"/>
            <cfelse>
                <cfset VARIABLES.runnerAppsAlert = { type = "warning", message = "Remova ou mova os apps desta linha antes de excluir a categoria." }/>
            </cfif>
        </cfif>
    </cfif>
</cfif>

<cfif isDefined("URL.sucesso") AND len(trim(URL.sucesso)) AND NOT len(VARIABLES.runnerAppsAlert.message)>
    <cfset VARIABLES.runnerAppsAlert = { type = "success", message = "Alteracao salva com sucesso." }/>
</cfif>

<cfif VARIABLES.runnerAppsTablesReady>
    <cfquery name="qRunnerAppGroups">
        SELECT grp.*,
               coalesce(app_counts.total_apps, 0) AS total_apps,
               coalesce(app_counts.active_apps, 0) AS active_apps
        FROM tb_portal_runner_app_groups grp
        LEFT JOIN (
            SELECT id_group,
                   count(*) AS total_apps,
                   count(*) FILTER (WHERE ativo = true) AS active_apps
            FROM tb_portal_runner_apps
            GROUP BY id_group
        ) app_counts ON app_counts.id_group = grp.id_group
        ORDER BY grp.ordem ASC, grp.id_group ASC
    </cfquery>

    <cfquery name="qRunnerApps">
        SELECT app.*,
               grp.nome AS grupo_nome,
               grp.ordem AS grupo_ordem
        FROM tb_portal_runner_apps app
        INNER JOIN tb_portal_runner_app_groups grp ON grp.id_group = app.id_group
        ORDER BY grp.ordem ASC, app.ordem ASC, app.id_app ASC
    </cfquery>

    <cfquery name="qRunnerAppGroupEdit">
        SELECT *
        FROM tb_portal_runner_app_groups
        WHERE id_group = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.grupo_editar) ? val(URL.grupo_editar) : 0#"/>
    </cfquery>

    <cfquery name="qRunnerAppEdit">
        SELECT *
        FROM tb_portal_runner_apps
        WHERE id_app = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.app_editar) ? val(URL.app_editar) : 0#"/>
    </cfquery>
<cfelse>
    <cfset qRunnerAppGroups = queryNew("id_group,nome,descricao,ordem,ativo,total_apps,active_apps")/>
    <cfset qRunnerApps = queryNew("id_app,id_group,nome,url,imagem_url,imagem_original,alt_text,abrir_nova_aba,rel,ordem,ativo,grupo_nome,grupo_ordem")/>
    <cfset qRunnerAppGroupEdit = queryNew("id_group,nome,descricao,ordem,ativo")/>
    <cfset qRunnerAppEdit = queryNew("id_app,id_group,nome,url,imagem_url,imagem_original,alt_text,abrir_nova_aba,rel,ordem,ativo")/>
</cfif>
