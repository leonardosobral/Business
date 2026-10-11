<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/login/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Faça o seu login - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Faça o seu login"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container text-center align-content-center" style="min-height:calc(100vh - 100px)">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- CONTEUDO --->

        <cfif NOT Usuario.logado>

            <!--- LOGIN --->
        <div class="card card-body w-300px mx-auto">
            <cfif isDefined("URL.status") AND URL.status EQ "conta_inativa">
                <div class="alert alert-warning text-start small" role="alert">
                    Esta conta está inativa. Entre em contato com o suporte da plataforma para revisar o acesso.
                </div>
            </cfif>
            <h6>Identifique-se para prosseguir</h6>
            <button data-mdb-ripple-init type="button" alt="Login do usuário" id="btnLogin" class="btn btn-primary py-1 px-2 shadow-0 btn-lg" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
                Efetuar login
            </button>
        </div>

        <cfelse>

            <!--- LOGIN --->
            <cfif structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "beta">
                <meta http-equiv="refresh" content="0; url=/beta/" />
            <cfelse>
                <meta http-equiv="refresh" content="0; url=/atleta/" />
            </cfif>

        </cfif>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

<script>
    window.addEventListener('DOMContentLoaded', function() {
        var btn = document.getElementById('btnLogin');
        var accountInactive = <cfif isDefined("URL.status") AND URL.status EQ "conta_inativa">true<cfelse>false</cfif>;
        if(btn && !accountInactive) btn.click();
    });
</script>

</html>
