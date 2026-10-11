<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>
<cfheader statuscode="404" statusText="not found"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/404/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/variaveis.cfm"/>
<cfinclude template="../includes/backend.cfm"/>

<cfquery>
    INSERT INTO tb_log
    (log_item, log_item_id, log_user, site)
    VALUES
    ('404',<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "404 Página não encontrada - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Página não encontrada"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-start.cfm"/>


    <div class="container text-center">


        <!--- HEADER --->

        <cfinclude template="../includes/header.cfm"/>


        <!--- CONTEUDO --->
        <!---
        <h3 class="mb-3">PÁGINA NÃO ENCONTRADA</h3>
        <p>
            Navegue pelo menu principal como alternativa.
        </p>
        --->

        <img src="/assets/rr_404.png" class="my-5 w-100">


    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/footer.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal_cadastro_evento.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
