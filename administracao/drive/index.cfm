<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/administracao/drive/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfif NOT structKeyExists(session,"driveCsrf")><cfset session.driveCsrf=agendaRandom()/></cfif>
<cfset VARIABLES.drivePickerClientId=structKeyExists(APPLICATION,"googleCalendar") AND structKeyExists(APPLICATION.googleCalendar,"CLIENT_ID") ? APPLICATION.googleCalendar.CLIENT_ID & "" : ""/>
<cfset VARIABLES.drivePickerApiKey=structKeyExists(APPLICATION,"googleDrive") AND structKeyExists(APPLICATION.googleDrive,"pickerApiKey") ? APPLICATION.googleDrive.pickerApiKey & "" : ""/>
<cfset VARIABLES.drivePickerAppId=structKeyExists(APPLICATION,"googleDrive") AND structKeyExists(APPLICATION.googleDrive,"appId") ? APPLICATION.googleDrive.appId & "" : ""/>
<cfheader name="Cache-Control" value="no-store"/>
<!doctype html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/administracao/drive/assets/drive.css?v=1"/>
<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260911-1"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main class="container-fluid px-3 px-lg-4 business-page drive-page admin-suite-page admin-suite-main" id="googleDrive"
      data-csrf="<cfoutput>#encodeForHtmlAttribute(session.driveCsrf)#</cfoutput>"
      data-picker-client-id="<cfoutput>#encodeForHtmlAttribute(VARIABLES.drivePickerClientId)#</cfoutput>"
      data-picker-api-key="<cfoutput>#encodeForHtmlAttribute(VARIABLES.drivePickerApiKey)#</cfoutput>"
      data-picker-app-id="<cfoutput>#encodeForHtmlAttribute(VARIABLES.drivePickerAppId)#</cfoutput>"
      data-picker-email="contato@runnerhub.run">
    <header class="admin-suite-header">
        <div class="admin-suite-heading">
            <span class="admin-suite-heading-icon" aria-hidden="true"><i class="fa-brands fa-google-drive"></i></span>
            <div class="admin-suite-heading-copy">
                <div class="admin-suite-kicker">Ferramentas administrativas</div>
                <h1 class="admin-suite-title">Documentos</h1>
                <p class="admin-suite-subtitle">Arquivos compartilhados · Google Drive · contato@runnerhub.run</p>
            </div>
        </div>
        <cfinclude template="../../includes/estrutura/admin_suite_nav.cfm"/>
    </header>
    <section class="admin-suite-commandbar" aria-label="Ações de Documentos">
        <div class="admin-suite-status">
            <i class="fa-solid fa-circle" aria-hidden="true"></i>
            <span id="driveStatus" class="drive-status" role="status" aria-live="polite">Verificando conexão…</span>
        </div>
        <div class="drive-actions admin-suite-actions">
            <button class="btn btn-outline-light" type="button" id="driveOpenRoot" hidden>Abrir no Drive</button>
            <button class="btn btn-outline-light" type="button" id="drivePicker" disabled><i class="fa-brands fa-google-drive me-2"></i>Adicionar do Drive</button>
            <button class="btn btn-outline-light" type="button" id="driveUpload" disabled><i class="fa-solid fa-arrow-up-from-bracket me-2"></i>Enviar</button>
            <button class="btn btn-warning" type="button" id="driveNew" disabled><i class="fa-solid fa-plus me-2"></i>Novo</button>
        </div>
    </section>

    <p id="drivePickerNotice" class="small text-warning mb-3" hidden>Configure o Google Picker no servidor para autorizar arquivos já existentes no Drive.</p>

    <section id="driveSetup" class="drive-setup" hidden>
        <div class="drive-setup-icon"><i class="fa-brands fa-google-drive"></i></div>
        <div><h2 class="h5 mb-1">Configuração pendente</h2><p class="text-muted mb-0" id="driveSetupMessage"></p></div>
        <button class="btn btn-warning" type="button" id="driveCreateRoot" hidden>Criar pasta RunnerHub Business</button>
        <a class="btn btn-outline-light" href="/administracao/agenda/" id="driveReconnect" hidden>Reconectar Google</a>
    </section>

    <section id="driveWorkspace" hidden>
        <div class="drive-toolbar admin-suite-workbar">
            <nav id="driveBreadcrumbs" class="drive-breadcrumbs" aria-label="Caminho da pasta"></nav>
            <label class="drive-search"><span class="visually-hidden">Buscar nesta pasta</span><i class="fa-solid fa-magnifying-glass"></i><input class="form-control" id="driveSearch" type="search" maxlength="100" placeholder="Buscar nesta pasta"/></label>
            <button class="btn btn-outline-light" type="button" id="driveRefresh" aria-label="Atualizar"><i class="fa-solid fa-rotate"></i></button>
        </div>
        <div class="drive-list-heading" aria-hidden="true"><span>Nome</span><span>Modificado</span><span>Tamanho</span><span></span></div>
        <div id="driveItems" class="drive-items" aria-busy="false"></div>
        <button class="btn btn-outline-light mt-3" id="driveMore" type="button" hidden>Carregar mais</button>
    </section>

    <dialog class="drive-dialog" id="driveNewDialog" aria-labelledby="driveNewTitle">
        <form id="driveNewForm">
            <h2 class="h5" id="driveNewTitle">Novo item</h2>
            <label class="drive-field">Tipo<select class="form-select" name="type" required><option value="folder">Pasta</option><option value="document">Documento Google</option><option value="spreadsheet">Planilha Google</option></select></label>
            <label class="drive-field">Nome<input class="form-control" name="name" maxlength="255" required/></label>
            <p class="text-danger" data-dialog-error role="alert"></p>
            <div class="drive-actions mt-4"><button class="btn btn-warning" type="submit">Criar</button><button class="btn btn-outline-light" type="button" data-close>Cancelar</button></div>
        </form>
    </dialog>

    <dialog class="drive-dialog" id="driveUploadDialog" aria-labelledby="driveUploadTitle">
        <form id="driveUploadForm">
            <h2 class="h5" id="driveUploadTitle">Enviar arquivo</h2>
            <label class="drive-field">Arquivo<input class="form-control" name="upload_file" type="file" required/></label>
            <p class="text-muted small" id="driveUploadHint">O limite será informado após conectar.</p>
            <p class="text-danger" data-dialog-error role="alert"></p>
            <div class="drive-actions mt-4"><button class="btn btn-warning" type="submit">Enviar</button><button class="btn btn-outline-light" type="button" data-close>Cancelar</button></div>
        </form>
    </dialog>

    <dialog class="drive-dialog" id="driveRenameDialog" aria-labelledby="driveRenameTitle">
        <form id="driveRenameForm">
            <h2 class="h5" id="driveRenameTitle">Renomear item</h2>
            <input name="file_id" type="hidden"/>
            <label class="drive-field">Novo nome<input class="form-control" name="name" maxlength="255" required/></label>
            <p class="text-danger" data-dialog-error role="alert"></p>
            <div class="drive-actions mt-4"><button class="btn btn-warning" type="submit">Salvar</button><button class="btn btn-outline-light" type="button" data-close>Cancelar</button></div>
        </form>
    </dialog>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
<script src="/administracao/drive/assets/drive.js?v=3"></script>
</body>
</html>
