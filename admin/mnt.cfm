<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend/backend_mnt.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Admin</title>
    <cfinclude template="includes/seo-web-tools-head.cfm"/>
</head>

<body>

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="includes/header.cfm"/>


            <!--- CONTEUDO --->

            <div class="row">

                <cfinclude template="mnt_listagem_eventos.cfm"/>

            </div>

        </div>

    </cfif>

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
