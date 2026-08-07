<cfparam name="VARIABLES.requiredBusinessPermission" default=""/>
<cfset VARIABLES.requireBusinessPermissionAllowed = false/>
<cfif len(trim(VARIABLES.requiredBusinessPermission))
    AND structKeyExists(VARIABLES, "businessHasPermission")>
    <cfset VARIABLES.requireBusinessPermissionAllowed = businessHasPermission(VARIABLES.requiredBusinessPermission)/>
</cfif>

<cfif NOT VARIABLES.requireBusinessPermissionAllowed>
    <cfcontent reset="true"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <!doctype html>
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
                    <p class="text-muted mb-4">Sua conta ou seu papel não possui permissão para acessar esta área.</p>
                    <a class="btn btn-warning" href="/">Voltar para o dashboard</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>
