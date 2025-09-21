<cfobject name="transmissao" component="leaderboard.api.transmissao"/>
<cfinvoke component="#transmissao#" method="widget" returnVariable="res">
<cfheader name="Content-Type" value="text/xml; charset=utf-8">
<cfoutput>#res#</cfoutput>
