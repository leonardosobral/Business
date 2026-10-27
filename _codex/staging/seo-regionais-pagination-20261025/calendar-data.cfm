<cfset VARIABLES.template="/estado/"/>
<cfinclude template="/includes/estrutura/variaveis.cfm"/>
<cfinclude template="includes/backend/backend_regional_calendar.cfm"/>
<cfscript>
result={rows=qEventos.recordCount,total=VARIABLES.regionalTotal,ids=[],periodValid=true};
for (row in qEventos) {
 arrayAppend(result.ids,row.id_evento);
 if(VARIABLES.regionalExactPeriod && (row.data_final LT VARIABLES.regionalFrom || row.data_inicial GTE dateAdd("d",1,VARIABLES.regionalTo)))result.periodValid=false;
}
</cfscript>
<cfcontent reset="true" type="application/json"/><cfoutput>#serializeJSON(result)#</cfoutput>
