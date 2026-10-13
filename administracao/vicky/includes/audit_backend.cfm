<!--- This include is not a public endpoint. The authenticated page sets this guard. --->
<cfif NOT structKeyExists(VARIABLES,"requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfinclude template="audit_helpers.cfm"/>
<cfset VARIABLES.vickyErrorStep="auditoria de conversas"/>
<cfset VARIABLES.vickyAudit=vickyAuditLoad(vickyAuditState(URL),val(qPerfil.id))/>
