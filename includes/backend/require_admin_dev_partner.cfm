<cfset VARIABLES.requireAdminDevPartnerAllowed = false/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount>
    <cfif listFindNoCase(qPerfil.columnList, "is_admin")
        AND (
            (IsBoolean(qPerfil.is_admin) AND qPerfil.is_admin)
            OR ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin & ""))
        )>
        <cfset VARIABLES.requireAdminDevPartnerAllowed = true/>
    </cfif>

    <cfif NOT VARIABLES.requireAdminDevPartnerAllowed
        AND listFindNoCase(qPerfil.columnList, "is_dev")
        AND (
            (IsBoolean(qPerfil.is_dev) AND qPerfil.is_dev)
            OR ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_dev & ""))
        )>
        <cfset VARIABLES.requireAdminDevPartnerAllowed = true/>
    </cfif>

    <cfif NOT VARIABLES.requireAdminDevPartnerAllowed
        AND listFindNoCase(qPerfil.columnList, "is_partner")
        AND (
            (IsBoolean(qPerfil.is_partner) AND qPerfil.is_partner)
            OR ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_partner & ""))
        )>
        <cfset VARIABLES.requireAdminDevPartnerAllowed = true/>
    </cfif>
</cfif>

<cfif NOT VARIABLES.requireAdminDevPartnerAllowed>
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
                    <p class="text-muted mb-4">Esta ferramenta esta disponivel somente para Admin, Dev e Partner.</p>
                    <a class="btn btn-warning" href="/">Voltar para o dashboard</a>
                </div>
            </div>
        </main>
    </body>
    </html>
    <cfabort/>
</cfif>
