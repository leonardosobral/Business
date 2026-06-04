<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfscript>
function runnerAppsApiBuildBaseUrl() {
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

function runnerAppsApiNormalizeBoolean(required any value) {
    if (isBoolean(arguments.value)) {
        return arguments.value;
    }

    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function runnerAppsApiAssetUrl(required string imagePath) {
    var normalizedPath = trim(arguments.imagePath);

    if (!len(normalizedPath)) {
        return "";
    }

    if (reFindNoCase("^(https?:)?//", normalizedPath) OR left(normalizedPath, 5) EQ "data:") {
        return normalizedPath;
    }

    return runnerAppsApiBuildBaseUrl() & (left(normalizedPath, 1) EQ "/" ? normalizedPath : "/" & normalizedPath);
}

function runnerAppsApiWrite(required any payload) {
    cfcontent(type="application/json; charset=utf-8", reset="true");
    writeOutput(serializeJSON(arguments.payload));
    abort;
}
</cfscript>

<cfheader name="Access-Control-Allow-Origin" value="*"/>
<cfheader name="Access-Control-Allow-Methods" value="GET, OPTIONS"/>
<cfheader name="Access-Control-Allow-Headers" value="Content-Type"/>

<cfif CGI.request_method EQ "OPTIONS">
    <cfcontent type="application/json; charset=utf-8" reset="true"/>
    <cfoutput>{}</cfoutput>
    <cfabort/>
</cfif>

<cfparam name="URL.incluir_ocultos" default="0"/>

<cfset VARIABLES.runnerAppsIncludeHidden = runnerAppsApiNormalizeBoolean(URL.incluir_ocultos)/>

<cfquery name="qRunnerAppsApiTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = current_schema()
      AND table_name IN ('tb_portal_runner_app_groups', 'tb_portal_runner_apps')
</cfquery>

<cfset VARIABLES.runnerAppsApiTablesList = valueList(qRunnerAppsApiTables.table_name)/>

<cfif NOT listFindNoCase(VARIABLES.runnerAppsApiTablesList, "tb_portal_runner_app_groups") OR NOT listFindNoCase(VARIABLES.runnerAppsApiTablesList, "tb_portal_runner_apps")>
    <cfset runnerAppsApiWrite({
        success = false,
        status = "tables_missing",
        message = "As tabelas do Runner Apps ainda nao foram criadas no Business."
    })/>
</cfif>

<cfquery name="qRunnerAppsApiRows">
    SELECT grp.id_group,
           grp.nome AS grupo_nome,
           grp.descricao AS grupo_descricao,
           grp.ordem AS grupo_ordem,
           grp.ativo AS grupo_ativo,
           app.id_app,
           app.nome,
           app.url,
           app.imagem_url,
           app.alt_text,
           app.abrir_nova_aba,
           app.rel,
           app.ordem,
           app.ativo
    FROM tb_portal_runner_app_groups grp
    LEFT JOIN tb_portal_runner_apps app ON app.id_group = grp.id_group
        <cfif NOT VARIABLES.runnerAppsIncludeHidden>
            AND app.ativo = true
        </cfif>
    WHERE 1 = 1
      <cfif NOT VARIABLES.runnerAppsIncludeHidden>
        AND grp.ativo = true
      </cfif>
    ORDER BY grp.ordem ASC,
             grp.id_group ASC,
             app.ordem ASC NULLS LAST,
             app.id_app ASC NULLS LAST
</cfquery>

<cfscript>
runnerAppsGroups = [];
runnerAppsFlatItems = [];
runnerAppsGroupIndex = {};

for (rowIndex = 1; rowIndex <= qRunnerAppsApiRows.recordcount; rowIndex++) {
    groupId = qRunnerAppsApiRows.id_group[rowIndex] & "";

    if (!structKeyExists(runnerAppsGroupIndex, groupId)) {
        arrayAppend(runnerAppsGroups, {
            id = qRunnerAppsApiRows.id_group[rowIndex],
            name = qRunnerAppsApiRows.grupo_nome[rowIndex],
            description = qRunnerAppsApiRows.grupo_descricao[rowIndex],
            order = qRunnerAppsApiRows.grupo_ordem[rowIndex],
            active = runnerAppsApiNormalizeBoolean(qRunnerAppsApiRows.grupo_ativo[rowIndex]),
            items = []
        });
        runnerAppsGroupIndex[groupId] = arrayLen(runnerAppsGroups);
    }

    if (len(trim(qRunnerAppsApiRows.id_app[rowIndex] & ""))) {
        itemPayload = {
            id = qRunnerAppsApiRows.id_app[rowIndex],
            groupId = qRunnerAppsApiRows.id_group[rowIndex],
            groupName = qRunnerAppsApiRows.grupo_nome[rowIndex],
            name = qRunnerAppsApiRows.nome[rowIndex],
            href = qRunnerAppsApiRows.url[rowIndex],
            target = runnerAppsApiNormalizeBoolean(qRunnerAppsApiRows.abrir_nova_aba[rowIndex]) ? "_blank" : "",
            rel = trim(qRunnerAppsApiRows.rel[rowIndex] & ""),
            imgSrc = runnerAppsApiAssetUrl(qRunnerAppsApiRows.imagem_url[rowIndex]),
            imgAlt = len(trim(qRunnerAppsApiRows.alt_text[rowIndex] & "")) ? qRunnerAppsApiRows.alt_text[rowIndex] : qRunnerAppsApiRows.nome[rowIndex],
            label = qRunnerAppsApiRows.nome[rowIndex],
            labelHtml = qRunnerAppsApiRows.nome[rowIndex],
            order = qRunnerAppsApiRows.ordem[rowIndex],
            active = runnerAppsApiNormalizeBoolean(qRunnerAppsApiRows.ativo[rowIndex])
        };

        arrayAppend(runnerAppsGroups[runnerAppsGroupIndex[groupId]].items, itemPayload);
        arrayAppend(runnerAppsFlatItems, itemPayload);
    }
}

runnerAppsApiWrite({
    success = true,
    status = "ok",
    groups = runnerAppsGroups,
    items = runnerAppsFlatItems,
    poweredBy = {
        label = "powered by",
        href = "https://runnerhub.run/",
        name = "RunnerHub"
    }
});
</cfscript>
