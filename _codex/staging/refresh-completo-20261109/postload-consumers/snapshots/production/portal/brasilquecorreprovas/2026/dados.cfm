<!--- Allowlisted public projection from the Q3 product's pinned notebook publication. --->
<cfsetting showdebugoutput="false"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cftry>
    <cfset publicStudy=queryExecute('SELECT payload FROM estudo.lancamento_publico',{}, {datasource='runnerhub',timeout=5})/>
    <cfif publicStudy.recordCount NEQ 1><cfthrow message="Public release unavailable"/></cfif>
    <cfoutput>#publicStudy.payload[1]#</cfoutput>
    <cfcatch><cfheader statuscode="503"/><cfoutput>{"ok":false,"message":"Os destaques estão temporariamente indisponíveis."}</cfoutput></cfcatch>
</cftry>
