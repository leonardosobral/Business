<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/administracao/produtos-servicos/"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>

<cfquery name="catalogoInstalado" datasource="runner_dba" timeout="5">
    SELECT to_regclass('public.tb_business_produtos_servicos') IS NOT NULL AS pronto
</cfquery>
<cfif catalogoInstalado.pronto>
    <cfquery name="catalogo" datasource="runner_dba" timeout="5">
        SELECT codigo, grupo, nome, comprador, cobranca, inicio, termino, registro, a_confirmar
        FROM public.tb_business_produtos_servicos
        ORDER BY grupo, ordem, codigo
    </cfquery>
</cfif>

<!doctype html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>
    <main style="margin-top: -55px;">
        <div class="container-fluid business-page px-3 px-md-4 py-4">
            <cfinclude template="home.cfm"/>
        </div>
    </main>
    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>
</html>
