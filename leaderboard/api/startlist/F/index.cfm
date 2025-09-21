<cfobject name="transmissao" component="leaderboard.api.transmissao"/>
<cfinvoke component="#transmissao#" method="startlist" genero="F" returnVariable="res">
<cfheader name="Content-Type" value="text/xml; charset=utf-8">
<cfoutput>#res#</cfoutput>
