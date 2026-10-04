<cfprocessingdirective pageencoding="utf-8"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="Referrer-Policy" value="no-referrer"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/gestao-clientes/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend.cfm"/>
<!doctype html><html lang="pt-br">
<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<noscript><style>@media(max-width:1199.98px){#main-sidenav{display:none!important}}</style></noscript>
<cfinclude template="../includes/estrutura/header.cfm"/>
<main class="container px-4 business-workspace" id="conteudo"><cfinclude template="home.cfm"/></main>
<cfinclude template="../includes/estrutura/footer.cfm"/>
</body></html>
