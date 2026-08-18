<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/ads/canonical/"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>

<cfif NOT isDefined("VARIABLES.businessRealIsAdmin") OR NOT VARIABLES.businessRealIsAdmin>
    <cfcontent reset="true"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <!DOCTYPE html>
    <html lang="pt-br">
    <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Acesso restrito</title>
        <link rel="stylesheet" href="/assets/css/mdb.min.css"/>
    </head>
    <body data-mdb-theme="dark" class="bg-dark-subtle">
        <main class="container py-5">
            <div class="card shadow-0">
                <div class="card-body">
                    <h1 class="h4 mb-2">Acesso restrito</h1>
                    <p class="text-muted mb-4">O piloto Ads V1 esta disponivel somente para administradores.</p>
                    <a class="btn btn-warning" href="/ads/">Voltar para Turbinados</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>

<cfinclude template="includes/backend.cfm"/>
<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>

    <main style="margin-top: -55px;">
        <div class="container-fluid px-4">
            <cfinclude template="includes/home.cfm"/>
        </div>
    </main>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>
</html>
