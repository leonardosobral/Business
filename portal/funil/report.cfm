<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="90"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../includes/backend/require_real_platform_context.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cftry>
    <cfif structKeyExists(URL,"visao") AND isSimpleValue(URL.visao) AND URL.visao EQ "geral">
        <cfinclude template="includes/geral_backend.cfm"/>
    <cfelseif structKeyExists(URL,"publico") AND isSimpleValue(URL.publico) AND URL.publico EQ "organizers">
        <cfinclude template="includes/organizer_backend.cfm"/>
    <cfelseif structKeyExists(URL,"produto") AND isSimpleValue(URL.produto) AND URL.produto EQ "selo">
        <cfinclude template="includes/selo_backend.cfm"/>
    <cfelse>
        <cfinclude template="includes/report_backend.cfm"/>
    </cfif>
    <cfcontent type="application/json; charset=utf-8" reset="true"/>
    <cfoutput>#serializeJSON(VARIABLES.funnelReport)#</cfoutput>
    <cfcatch type="FunnelInput">
        <cfheader statuscode="400"/>
        <cfcontent type="application/json; charset=utf-8" reset="true"/>
        <cfoutput>#serializeJSON({error="Confira as datas e os filtros. A data final deve ser igual ou posterior à inicial e não pode estar no futuro."})#</cfoutput>
    </cfcatch>
    <cfcatch type="any">
        <cflog file="application" type="error" text="Business funnel report unavailable: #cfcatch.type# / #left(listFirst(cfcatch.message, ':'), 120)#"/>
        <cfheader statuscode="503"/>
        <cfcontent type="application/json; charset=utf-8" reset="true"/>
        <cfscript>
        VARIABLES.funnelFailure={error="Não foi possível consultar o funil. Os dados não foram substituídos por números de demonstração."};
        if (structKeyExists(URL,"visao") AND isSimpleValue(URL.visao) AND URL.visao EQ "geral") {
            // Dados técnicos limitados para o administrador: sem SQL, parâmetros ou dados pessoais.
            VARIABLES.generalErrorText=(structKeyExists(cfcatch,"detail") ? cfcatch.detail & " " : "") & cfcatch.message;
            VARIABLES.generalErrorState=structKeyExists(cfcatch,"sqlState") AND reFind("^[A-Z0-9]{5}$",cfcatch.sqlState & "") ? cfcatch.sqlState : "";
            VARIABLES.generalErrorInfo={tipo=reReplace(cfcatch.type & "","[^A-Za-z0-9_.-]","","all"),sqlstate=VARIABLES.generalErrorState,sintaxe=reFindNoCase("syntax error|invalid cfml|invalid construct",VARIABLES.generalErrorText) GT 0,coluna=reFindNoCase("column.*does not exist|column.*ambiguous",VARIABLES.generalErrorText) GT 0,permissao=reFindNoCase("permission denied",VARIABLES.generalErrorText) GT 0,tempo=reFindNoCase("timeout|timed out|canceling statement",VARIABLES.generalErrorText) GT 0,arquivo="",linha=0};
            if (structKeyExists(cfcatch,"tagContext") AND isArray(cfcatch.tagContext)) for (VARIABLES.generalTrace in cfcatch.tagContext) {
                if (!len(VARIABLES.generalErrorInfo.arquivo) AND structKeyExists(VARIABLES.generalTrace,"template") AND reFindNoCase("(geral_backend|legacy_payments)\.cfm$",VARIABLES.generalTrace.template & "")) {
                    VARIABLES.generalErrorInfo.arquivo=reFindNoCase("geral_backend\.cfm$",VARIABLES.generalTrace.template & "") ? "geral_backend.cfm" : "legacy_payments.cfm";
                    if (structKeyExists(VARIABLES.generalTrace,"line")) VARIABLES.generalErrorInfo.linha=val(VARIABLES.generalTrace.line);
                }
            }
            VARIABLES.funnelFailure.diagnostico=VARIABLES.generalErrorInfo;
        }
        </cfscript>
        <cfoutput>#serializeJSON(VARIABLES.funnelFailure)#</cfoutput>
    </cfcatch>
</cftry>
