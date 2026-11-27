<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/emailmkt/"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfinclude template="../includes/backend/require_real_platform_context.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfif structKeyExists(URL,"previa") AND isSimpleValue(URL.previa) AND URL.previa EQ "selo-brevo">
    <cfset previewHtml=fileRead(expandPath('/docs/campanhas/selo-atleta-2026-11-27-brevo.html'),"utf-8")/>
    <cfset previewHtml=reReplace(previewHtml,"\?utm_source=brevo&amp;utm_medium=email&amp;utm_campaign=selo-atleta-20261127(&amp;utm_content=[a-z0-9_-]+)?","","all")/>
    <cfset previewHtml=replace(previewHtml,"{{ unsubscribe }}","https://roadrunners.run/privacidade/","all")/>
    <cfheader name="X-Robots-Tag" value="noindex, nofollow"/>
    <cfcontent reset="true" type="text/html; charset=utf-8"/><cfoutput>#previewHtml#</cfoutput><cfabort/>
</cfif>
<cfif structKeyExists(URL,"modelo") AND listFind("selo-2026-11-27,selo-brevo",URL.modelo)>
    <cfset modelFile=URL.modelo EQ "selo-brevo" ? "selo-atleta-2026-11-27-brevo.html" : "selo-atleta-2026-11-27.html"/>
    <cfheader name="Content-Disposition" value='attachment; filename="#modelFile#"'/>
    <cfcontent reset="true" type="text/html; charset=utf-8" file="#expandPath('/docs/campanhas/' & modelFile)#"/>
    <cfabort/>
</cfif>
<cfinclude template="brevo_controller.cfm"/>

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main class="" style="margin-top: -55px;">

      <div class="container px-4">

        <cfif isdefined("URL.action") and URL.action EQ "compose">

        <cfinclude template="compose.cfm">

        <cfelse>

        <cfinclude template="home.cfm">

        </cfif>

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>
