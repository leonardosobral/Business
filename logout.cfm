<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfset VARIABLES.logoutCodSite = "RH"/>
<cfif isDefined("APPLICATION.codSite") AND len(trim(APPLICATION.codSite))>
    <cfset VARIABLES.logoutCodSite = APPLICATION.codSite/>
</cfif>

<cftry>
    <cfif isDefined("COOKIE.id")>
        <cfset VARIABLES.logoutName = ""/>
        <cfset VARIABLES.logoutEmail = ""/>
        <cfif isDefined("COOKIE.name")>
            <cfset VARIABLES.logoutName = COOKIE.name/>
        </cfif>
        <cfif isDefined("COOKIE.email")>
            <cfset VARIABLES.logoutEmail = COOKIE.email/>
        </cfif>

        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            (
                'googlesignout',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#VARIABLES.logoutName#,#VARIABLES.logoutEmail#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.logoutCodSite#"/>
            )
        </cfquery>
    </cfif>
<cfcatch type="any"></cfcatch>
</cftry>

<cftry>
    <cfset StructDelete(SESSION, "businessSimulatedAccountId", false)/>
    <cfset StructDelete(SESSION, "businessActiveAccountId", false)/>
    <cfset StructDelete(SESSION, "businessAccountSelectionConfirmed", false)/>
    <cfset StructDelete(SESSION, "businessAccountContextCsrf", false)/>
<cfcatch type="any"></cfcatch>
</cftry>

<cfset VARIABLES.logoutCookieNames = "id,name,email,imagem_usuario"/>
<cfset VARIABLES.logoutCookiePaths = "/,/admin,/bi,/cadastro,/portal,/inscricoes"/>

<cfloop list="#VARIABLES.logoutCookieNames#" index="logoutCookieName">
    <cfcookie name="#logoutCookieName#" value="" expires="now" secure="yes"/>

    <cfloop list="#VARIABLES.logoutCookiePaths#" index="logoutCookiePath">
        <cfheader name="Set-Cookie" value="#logoutCookieName#=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=#logoutCookiePath#; Secure; SameSite=Lax"/>
    </cfloop>
</cfloop>

<cfheader name="Set-Cookie" value="rr_logged_out=1; Max-Age=86400; Path=/; Secure; SameSite=Lax"/>
<cfheader name="Cache-Control" value="private, max-age=0, no-store, no-cache, must-revalidate"/>
<cfheader name="Pragma" value="no-cache"/>

<!doctype html>
<html lang="pt-br">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title>Saindo...</title>
</head>
<body style="margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center; font-family:Arial,sans-serif; background:rgb(18,18,18); color:white;">
    <div style="text-align:center;">
        <strong>Saindo...</strong>
        <div style="font-size:13px; opacity:.75; margin-top:8px;">Limpando sua sessão local.</div>
    </div>

    <script>
        (function () {
            var names = ['id', 'ID', 'name', 'NAME', 'email', 'EMAIL', 'imagem_usuario', 'IMAGEM_USUARIO'];
            var paths = ['/', '/admin', '/bi', '/cadastro', '/portal', '/inscricoes', '/ads', '/usuarios', '/cupons-rr'];
            var host = window.location.hostname;
            var domains = ['', host, '.' + host, '.roadrunners.run'];

            function expireCookie(name, path, domain) {
                var cookie = name + '=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=' + path + '; SameSite=Lax; Secure';

                if (domain) {
                    cookie += '; Domain=' + domain;
                }

                document.cookie = cookie;
            }

            try {
                if (window.google && google.accounts && google.accounts.id) {
                    google.accounts.id.disableAutoSelect();
                }
            } catch (error) {
                console.warn('Google disableAutoSelect indisponivel.', error);
            }

            names.forEach(function (name) {
                paths.forEach(function (path) {
                    domains.forEach(function (domain) {
                        expireCookie(name, path, domain);
                    });
                });
            });

            document.cookie = 'rr_logged_out=1; Max-Age=86400; Path=/; SameSite=Lax; Secure';
            window.setTimeout(function () {
                window.location.replace('/?logout=1');
            }, 250);
        }());
    </script>

    <noscript>
        <meta http-equiv="refresh" content="1;url=/?logout=1"/>
        <p><a href="/?logout=1" style="color:white;">Continuar</a></p>
    </noscript>
</body>
</html>
