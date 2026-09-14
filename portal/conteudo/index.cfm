<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/conteudo/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<!--- Preserva favoritos anteriores sem manter SEO como uma aba de conteúdo. --->
<cfif structKeyExists(URL,"visao") AND isSimpleValue(URL.visao) AND URL.visao EQ "seo">
    <cfheader name="Cache-Control" value="private, no-store"/>
    <cfset VARIABLES.seoLegacyFilters = []/>
    <cfloop array="#[{name='site',allowed='all,roadrunners,openresults'},{name='prioridade',allowed='all,p1,p2,p3,review'},{name='verificacao',allowed='all,pass,warning,error,unknown'}]#" index="seoLegacyFilter">
        <cfif structKeyExists(URL,seoLegacyFilter.name) AND isSimpleValue(URL[seoLegacyFilter.name])>
            <cfset VARIABLES.seoLegacyValue = lCase(trim(URL[seoLegacyFilter.name]))/>
            <cfif listFind(seoLegacyFilter.allowed,VARIABLES.seoLegacyValue)>
                <cfset arrayAppend(VARIABLES.seoLegacyFilters,seoLegacyFilter.name & "=" & encodeForURL(VARIABLES.seoLegacyValue))/>
            </cfif>
        </cfif>
    </cfloop>
    <cflocation url="#'/portal/seo/' & (arrayLen(VARIABLES.seoLegacyFilters) ? '?' & arrayToList(VARIABLES.seoLegacyFilters,'&') : '')#" addtoken="false" statuscode="302"/>
</cfif>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>

    <main class="" style="margin-top: -55px;">
      <div class="container-fluid px-4">
        <cfinclude template="home.cfm"/>
      </div>
    </main>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>

</html>
