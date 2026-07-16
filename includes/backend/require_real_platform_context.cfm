<cfset VARIABLES.requireRealPlatformContextSimulationActive = false/>

<cfif isDefined("VARIABLES.businessAccountSimulationActive")>
    <cfif isBoolean(VARIABLES.businessAccountSimulationActive)>
        <cfset VARIABLES.requireRealPlatformContextSimulationActive = VARIABLES.businessAccountSimulationActive/>
    <cfelseif listFindNoCase("true,t,1,yes,sim", trim(VARIABLES.businessAccountSimulationActive & ""))>
        <cfset VARIABLES.requireRealPlatformContextSimulationActive = true/>
    </cfif>
</cfif>

<cfif VARIABLES.requireRealPlatformContextSimulationActive>
    <cfcontent reset="true"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <!doctype html>
    <html lang="pt-br">
    <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Contexto de conta ativo</title>
        <link rel="stylesheet" href="/assets/css/mdb.min.css"/>
    </head>
    <body data-mdb-theme="dark" class="bg-dark-subtle">
        <main class="container py-5">
            <div class="card shadow-0">
                <div class="card-body">
                    <h1 class="h4 mb-2">Gestão global indisponível</h1>
                    <p class="text-muted mb-4">Encerre a simulação da conta para acessar a gestão global de usuários.</p>
                    <a class="btn btn-warning" href="/administracao/contas/">Voltar para a gestão da conta</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>
