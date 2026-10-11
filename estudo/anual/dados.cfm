<cfinclude template="_guard.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cftry><cfset annual=new estudo.includes.StudyEditions().annual()/><cfoutput>#annual.payload_json#</cfoutput><cfcatch><cfheader statuscode="409"/><cfoutput>#serializeJSON({error="Congele uma saída anual válida no notebook antes de abrir o rascunho."})#</cfoutput></cfcatch></cftry>