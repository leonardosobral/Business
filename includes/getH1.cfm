<cfparam name="url.external" default="">
<cfif len(trim(url.external)) EQ 0>
    <cfset result = { error=true, message="URL não informada" }>
    <cfoutput>#serializeJSON(result)#</cfoutput>
    <cfabort>
</cfif>

<cfhttp url="#url.external#" method="get" result="r" />
<cfset html = r.fileContent />

<!--- Captura o conteúdo da primeira tag <h1> --->
<cfset h1 = rereplacenocase(html, ".*?<h1[^>]*>(.*?)</h1>.*", "\1", "all") />

<cfoutput>
    #serializeJSON({ h1 = trim(h1) })#
</cfoutput>