<cfset VARIABLES.requireAdminAllowed = false/>

<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfif IsBoolean(VARIABLES.businessEffectiveIsAdmin)>
        <cfset VARIABLES.requireAdminAllowed = VARIABLES.businessEffectiveIsAdmin/>
    <cfelseif ListFindNoCase("true,1,yes,sim", trim(VARIABLES.businessEffectiveIsAdmin))>
        <cfset VARIABLES.requireAdminAllowed = true/>
    </cfif>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND listFindNoCase(qPerfil.columnList, "is_admin")>
    <cfif IsBoolean(qPerfil.is_admin)>
        <cfset VARIABLES.requireAdminAllowed = qPerfil.is_admin/>
    <cfelseif ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin))>
        <cfset VARIABLES.requireAdminAllowed = true/>
    </cfif>
</cfif>

<cfif NOT VARIABLES.requireAdminAllowed>
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
                    <p class="text-muted mb-4">Voce nao tem permissao para acessar esta area.</p>
                    <a class="btn btn-warning" href="/">Voltar para o dashboard</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>
