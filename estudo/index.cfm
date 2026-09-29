<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/estudo/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfif NOT structKeyExists(SESSION,"estudoCsrf")><cfset SESSION.estudoCsrf=lCase(hash(generateSecretKey("AES") & createUUID(),"SHA-256"))/></cfif>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../includes/estrutura/header.cfm"/>
<main style="margin-top:-55px">
  <div class="container-fluid px-4"><cfinclude template="home.cfm"/></div>
</main>
<cfinclude template="../includes/estrutura/footer.cfm"/>
<link rel="stylesheet" href="/estudo/assets/vendor/codemirror.css"/>
<link rel="stylesheet" href="/estudo/assets/notebook.css?v=20260928-3"/>
<script src="/estudo/assets/vendor/codemirror.js"></script>
<script src="/estudo/assets/vendor/sql.js"></script>
<script src="/estudo/assets/vendor/markdown.js"></script>
<script src="/estudo/assets/vendor/xml.js"></script>
<script src="/estudo/assets/vendor/purify.js"></script>
<script src="/estudo/assets/vendor/marked.js"></script>
<script src="/estudo/assets/notebook-data.js?v=20260928-2"></script>
<script src="/estudo/assets/notebook.js?v=20260928-2"></script>
</body></html>