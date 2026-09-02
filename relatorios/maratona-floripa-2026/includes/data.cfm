<cfif NOT structKeyExists(REQUEST, "mifReportAuthorized")
    OR NOT REQUEST.mifReportAuthorized>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>Acesso negado.</cfoutput>
    <cfabort/>
</cfif>

<cffunction name="mifAbortDatasetUnavailable" access="public" returntype="void" output="true">
    <cfheader statuscode="503" statustext="Service Unavailable"/>
    <cfcontent type="text/html; charset=utf-8" reset="true"/>
    <cfoutput><!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Dados indisponíveis</title></head>
<body><main><h1>Dados autenticados temporariamente indisponíveis</h1><p>A integridade do artefato privado não pôde ser confirmada.</p><p>Nenhuma conclusão foi exibida.</p></main></body></html></cfoutput>
    <cfabort/>
</cffunction>

<cfset mifReportDataRoot = "/var/lib/runnerhub/reports/mif-2026"/>
<cfset VARIABLES.mifReportEnvironment = createObject(
    "java",
    "java.lang.System"
).getenv()/>
<cfif VARIABLES.mifReportEnvironment.containsKey("MIF_REPORT_DATA_ROOT")>
    <cfset mifReportDataRoot = trim(
        VARIABLES.mifReportEnvironment.get("MIF_REPORT_DATA_ROOT") & ""
    )/>
</cfif>
<cfif NOT len(mifReportDataRoot)>
    <cfset mifAbortDatasetUnavailable()/>
</cfif>
<cfset mifReportDataRoot = reReplace(mifReportDataRoot, "[/\\]+$", "")/>
<cfset VARIABLES.mifReportManifestPath = mifReportDataRoot & "/manifest.json"/>
<cftry>
    <cfif NOT fileExists(VARIABLES.mifReportManifestPath)>
        <cfset mifAbortDatasetUnavailable()/>
    </cfif>
    <cfset VARIABLES.mifReportManifest = deserializeJson(
        fileRead(VARIABLES.mifReportManifestPath, "utf-8")
    )/>
    <cfif NOT isStruct(VARIABLES.mifReportManifest)
        OR NOT structKeyExists(VARIABLES.mifReportManifest, "source_sha256")
        OR NOT reFind("^[0-9a-f]{64}$", VARIABLES.mifReportManifest.source_sha256 & "")
        OR NOT structKeyExists(VARIABLES.mifReportManifest, "artifacts")
        OR NOT isStruct(VARIABLES.mifReportManifest.artifacts)>
        <cfset mifAbortDatasetUnavailable()/>
    </cfif>
    <cfcatch type="any">
        <cfset mifAbortDatasetUnavailable()/>
    </cfcatch>
</cftry>

<cffunction name="mifReadDataset" access="public" returntype="any" output="false">
    <cfargument name="relativePath" type="string" required="true"/>
    <cfset var requestedPath = trim(arguments.relativePath & "")/>
    <cfset var datasetPath = ""/>
    <cfset var receipt = {}/>
    <cfset var datasetBytes = ""/>
    <cfset var dataset = {}/>

    <cftry>
        <cfif NOT reFind("^[a-z0-9/_-]+\.json$", requestedPath)
            OR find("..", requestedPath)
            OR find("//", requestedPath)
            OR left(requestedPath, 1) EQ "/"
            OR find("\", requestedPath)
            OR NOT structKeyExists(VARIABLES.mifReportManifest.artifacts, requestedPath)>
            <cfset mifAbortDatasetUnavailable()/>
        </cfif>

        <cfset receipt = VARIABLES.mifReportManifest.artifacts[requestedPath]/>
        <cfif NOT isStruct(receipt)
            OR NOT structKeyExists(receipt, "path")
            OR receipt.path NEQ requestedPath
            OR NOT structKeyExists(receipt, "bytes")
            OR NOT isNumeric(receipt.bytes)
            OR receipt.bytes LT 1
            OR NOT structKeyExists(receipt, "sha256")
            OR NOT reFind("^[0-9a-f]{64}$", receipt.sha256 & "")
            OR NOT structKeyExists(receipt, "source_sha256")
            OR receipt.source_sha256 NEQ VARIABLES.mifReportManifest.source_sha256
            OR NOT structKeyExists(receipt, "transform_version")
            OR NOT len(trim(receipt.transform_version & ""))>
            <cfset mifAbortDatasetUnavailable()/>
        </cfif>

        <cfset datasetPath = mifReportDataRoot & "/" & requestedPath/>
        <cfif NOT fileExists(datasetPath)>
            <cfset mifAbortDatasetUnavailable()/>
        </cfif>
        <cfset datasetBytes = fileReadBinary(datasetPath)/>
        <cfif arrayLen(datasetBytes) NEQ receipt.bytes
            OR lCase(hash(datasetBytes, "SHA-256")) NEQ lCase(receipt.sha256 & "")>
            <cfset mifAbortDatasetUnavailable()/>
        </cfif>

        <cfset dataset = deserializeJson(toString(datasetBytes, "utf-8"))/>
        <cfif NOT isStruct(dataset)
            OR NOT structKeyExists(dataset, "meta")
            OR NOT isStruct(dataset.meta)
            OR NOT structKeyExists(dataset.meta, "transform_version")
            OR dataset.meta.transform_version NEQ receipt.transform_version>
            <cfset mifAbortDatasetUnavailable()/>
        </cfif>
        <cfreturn dataset/>
        <cfcatch type="any">
            <cfset mifAbortDatasetUnavailable()/>
        </cfcatch>
    </cftry>
</cffunction>
