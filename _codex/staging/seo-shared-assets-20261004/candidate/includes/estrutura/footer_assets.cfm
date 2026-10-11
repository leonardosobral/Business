<cfif NOT structKeyExists(REQUEST, "rrFooterStylesLoaded")>
    <link rel="stylesheet" href="/assets/css/runnerhub-footer.min.css?v=20261004seo"/>
    <cfset REQUEST.rrFooterStylesLoaded = true/>
</cfif>
