<cfif NOT structKeyExists(REQUEST, "rrFooterStylesLoaded")>
    <link rel="stylesheet" href="/assets/css/runnerhub-footer.css?v=20260913a"/>
    <cfset REQUEST.rrFooterStylesLoaded = true/>
</cfif>
