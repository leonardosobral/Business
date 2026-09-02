<cfif NOT structKeyExists(REQUEST, "mifReportAuthorized")
    OR NOT REQUEST.mifReportAuthorized>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>Acesso negado.</cfoutput>
    <cfabort/>
</cfif>

<cfset mifReportDataRoot = trim(getSystemSetting(
    "MIF_REPORT_DATA_ROOT",
    "/var/lib/runnerhub/reports/mif-2026"
) & "")/>
<cfif NOT len(mifReportDataRoot)>
    <cfthrow type="MifReport.Configuration" message="Diretório privado do relatório não configurado."/>
</cfif>
<cfset mifReportDataRoot = reReplace(mifReportDataRoot, "[/\\]+$", "")/>
<cfset VARIABLES.mifReportManifestPath = mifReportDataRoot & "/manifest.json"/>
<cfif NOT fileExists(VARIABLES.mifReportManifestPath)>
    <cfthrow type="MifReport.Configuration" message="Manifesto privado do relatório indisponível."/>
</cfif>
<cfset VARIABLES.mifReportManifest = deserializeJson(
    fileRead(VARIABLES.mifReportManifestPath, "utf-8")
)/>
<cfif NOT isStruct(VARIABLES.mifReportManifest)
    OR NOT structKeyExists(VARIABLES.mifReportManifest, "artifacts")
    OR NOT isStruct(VARIABLES.mifReportManifest.artifacts)>
    <cfthrow type="MifReport.Configuration" message="Manifesto privado do relatório inválido."/>
</cfif>

<cffunction name="mifReadDataset" access="public" returntype="any" output="false">
    <cfargument name="relativePath" type="string" required="true"/>
    <cfset var requestedPath = trim(arguments.relativePath & "")/>
    <cfset var datasetPath = ""/>

    <cfif NOT reFind("^[a-z0-9/_-]+\.json$", requestedPath)
        OR find("..", requestedPath)
        OR find("//", requestedPath)
        OR left(requestedPath, 1) EQ "/"
        OR find("\", requestedPath)
        OR NOT structKeyExists(VARIABLES.mifReportManifest.artifacts, requestedPath)>
        <cfthrow type="MifReport.DatasetDenied" message="Dataset de relatório não permitido."/>
    </cfif>

    <cfset datasetPath = mifReportDataRoot & "/" & requestedPath/>
    <cfif NOT fileExists(datasetPath)>
        <cfthrow type="MifReport.DatasetUnavailable" message="Dataset de relatório indisponível."/>
    </cfif>
    <cfreturn deserializeJson(fileRead(datasetPath, "utf-8"))/>
</cffunction>
