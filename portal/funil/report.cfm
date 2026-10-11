<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="90"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../includes/backend/require_real_platform_context.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cftry>
    <cfinclude template="includes/report_backend.cfm"/>
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
        <cfoutput>#serializeJSON({error="Não foi possível consultar o funil. Os dados não foram substituídos por números de demonstração."})#</cfoutput>
    </cfcatch>
</cftry>
