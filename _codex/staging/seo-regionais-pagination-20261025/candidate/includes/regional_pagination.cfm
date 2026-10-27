<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<nav class="rr-regional-pagination" aria-label="Páginas do calendário" data-regional-pagination data-page="#VARIABLES.regionalPage+1#" data-pages="#VARIABLES.regionalPages#">
    <p>Página #VARIABLES.regionalPage+1# de #VARIABLES.regionalPages# · #lsNumberFormat(VARIABLES.regionalTotal)# provas</p>
    <div>
    <cfif VARIABLES.regionalPage GT 0><a href="#encodeForHTMLAttribute(VARIABLES.regionalPageUrl(1))#">Primeira página</a><a rel="prev" href="#encodeForHTMLAttribute(VARIABLES.regionalPageUrl(VARIABLES.regionalPage))#">Anterior</a></cfif>
    <cfif VARIABLES.regionalPage+1 LT VARIABLES.regionalPages><a rel="next" href="#encodeForHTMLAttribute(VARIABLES.regionalPageUrl(VARIABLES.regionalPage+2))#">Próxima</a></cfif>
    </div>
</nav>
</cfoutput>
