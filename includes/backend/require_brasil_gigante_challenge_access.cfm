<cfinclude template="brasil_gigante_challenge_access.cfm"/>

<cfif NOT VARIABLES.businessCanManageBrasilGiganteChallenge>
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
                    <p class="text-muted mb-4">Este painel está disponível somente para ADMINs, DEVs ou membros operacionais ativos do Circuito Brasil Gigante.</p>
                    <a class="btn btn-warning" href="/">Voltar para o dashboard</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>
