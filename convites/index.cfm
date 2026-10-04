<cfprocessingdirective pageencoding="utf-8"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="Referrer-Policy" value="no-referrer"/>
<cfheader name="Content-Security-Policy" value="default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'"/>
<cfinclude template="includes/backend.cfm"/>
<cfif VARIABLES.inviteHttpStatus NEQ 200><cfheader statuscode="#VARIABLES.inviteHttpStatus#" statustext="Invitation unavailable"/></cfif>
<cfcontent type="text/html; charset=utf-8"/>
<cfinclude template="home.cfm"/>
