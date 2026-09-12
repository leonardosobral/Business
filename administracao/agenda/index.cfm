<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/administracao/agenda/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="includes/service.cfm"/>
<cfif NOT structKeyExists(session,"agendaCsrf")><cfset session.agendaCsrf=agendaRandom()/></cfif>
<cfheader name="Cache-Control" value="no-store"/>
<!doctype html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/administracao/agenda/assets/agenda.css?v=1"/>
<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260911-1"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main class="container-fluid px-3 px-lg-4 business-page agenda-page admin-suite-page admin-suite-main" id="googleAgenda" data-csrf="<cfoutput>#encodeForHtmlAttribute(session.agendaCsrf)#</cfoutput>">
    <header class="admin-suite-header">
        <div class="admin-suite-heading">
            <span class="admin-suite-heading-icon" aria-hidden="true"><i class="fa-regular fa-calendar"></i></span>
            <div class="admin-suite-heading-copy">
                <div class="admin-suite-kicker">Ferramentas administrativas</div>
                <h1 class="admin-suite-title">Agenda</h1>
                <p class="admin-suite-subtitle">Compromissos compartilhados · contato@runnerhub.run · Brasília</p>
            </div>
        </div>
        <cfinclude template="../../includes/estrutura/admin_suite_nav.cfm"/>
    </header>
    <section class="admin-suite-commandbar" aria-label="Ações da Agenda">
        <div class="admin-suite-status">
            <i class="fa-solid fa-circle" aria-hidden="true"></i>
            <span id="agendaStatus" role="status" aria-live="polite">Verificando conexão…</span>
        </div>
        <div class="agenda-actions admin-suite-actions">
            <button class="btn btn-outline-light" id="agendaConnect">Conectar Google</button>
            <button class="btn btn-outline-light" id="agendaSettings" disabled>Configurar agendas</button>
            <button class="btn btn-warning" id="agendaNew" disabled>Novo compromisso</button>
        </div>
    </section>
    <cfif structKeyExists(session,"agendaMessage")>
        <p class="alert alert-info"><cfoutput>#encodeForHTML(session.agendaMessage)#</cfoutput></p>
        <cfset structDelete(session,"agendaMessage")/>
    </cfif>
    <section class="agenda-toolbar admin-suite-workbar" aria-label="Filtros da agenda">
        <label>Agenda<select id="agendaCalendar" class="form-select" disabled></select></label>
        <label>Visualização<select id="agendaView" class="form-select"><option value="month">Mês</option><option value="week">Semana</option><option value="list">Lista do mês</option></select></label>
        <label>Data<input id="agendaDate" type="date" class="form-control" required/></label>
        <div class="agenda-actions"><button id="agendaPrevious" class="btn btn-outline-light" aria-label="Período anterior">←</button><button id="agendaToday" class="btn btn-outline-light">Hoje</button><button id="agendaNext" class="btn btn-outline-light" aria-label="Próximo período">→</button><button id="agendaRefresh" class="btn btn-outline-light">Atualizar</button></div>
        <label>Buscar neste período<input id="agendaSearch" type="search" class="form-control" placeholder="Buscar…"/></label>
    </section>
    <h2 id="agendaPeriod" class="h5 mt-4"></h2>
    <div id="agendaEvents" aria-busy="false"></div>
    <dialog id="agendaSettingsDialog" class="agenda-dialog">
        <form id="agendaSettingsForm">
            <h2 class="h5">Agendas disponíveis no Business</h2>
            <p class="text-muted">Selecione as agendas da conta que os administradores poderão consultar e editar.</p>
            <div id="agendaChoices"></div>
            <p id="agendaSettingsError" class="text-danger" role="alert"></p>
            <div class="agenda-actions mt-4"><button class="btn btn-warning" type="submit">Salvar seleção</button><button class="btn btn-outline-light" type="button" data-close>Fechar</button><button class="btn btn-outline-danger" type="button" id="agendaDisconnect">Desconectar conta</button></div>
        </form>
    </dialog>
    <dialog id="agendaEventDialog" class="agenda-dialog">
        <form id="agendaEventForm">
            <h2 id="agendaEventHeading" class="h5">Novo compromisso</h2>
            <p id="agendaRecurrenceNotice" class="text-warning"></p>
            <p id="agendaCardNotice" class="text-muted"></p>
            <label class="agenda-field">Título<input name="summary" class="form-control" maxlength="1024" required/></label>
            <label class="agenda-field">Descrição<textarea name="description" class="form-control" rows="3" maxlength="8000"></textarea></label>
            <label class="agenda-field">Local<input name="location" class="form-control" maxlength="1024"/></label>
            <label class="agenda-field"><span><input name="allDay" type="checkbox"/> Dia inteiro</span></label>
            <div class="agenda-two"><label class="agenda-field">Início<input name="start" class="form-control" type="datetime-local" required/></label><label class="agenda-field"><span id="agendaEndLabel">Término</span><input name="end" class="form-control" type="datetime-local" required/></label></div>
            <p class="text-muted small">Horário de Brasília. Em eventos de dia inteiro, a data final é o primeiro dia fora do compromisso.</p>
            <div class="agenda-two" id="agendaRepeatFields"><label class="agenda-field">Repetir<select name="repeat" class="form-select"><option value="none">Não repetir</option><option value="DAILY">Diariamente</option><option value="WEEKLY">Semanalmente</option><option value="MONTHLY">Mensalmente</option></select></label><label class="agenda-field">Total de ocorrências<input name="count" class="form-control" type="number" min="2" max="52" value="4"/></label></div>
            <label class="agenda-field">Participantes<textarea name="attendees" class="form-control" rows="2" placeholder="E-mails separados por vírgula"></textarea></label>
            <label class="agenda-field">Notificar participantes<select name="send_updates" class="form-select" required><option value="">Escolha antes de salvar ou excluir</option><option value="all">Enviar convites e atualizações para todos</option><option value="none">Não solicitar notificações por e-mail</option></select></label>
            <p class="text-muted small">Sem notificações, a atualização pode não chegar às agendas externas dos participantes.</p>
            <p id="agendaEventError" class="text-danger" role="alert"></p>
            <div class="agenda-actions mt-4"><button class="btn btn-warning" type="submit">Salvar compromisso</button><button class="btn btn-outline-light" type="button" data-close>Cancelar</button><a class="btn btn-outline-light" id="agendaGoogleLink" target="_blank" rel="noopener noreferrer" hidden>Abrir no Google</a><button class="btn btn-outline-light" id="agendaEditSeries" type="button" hidden>Editar série inteira</button><button class="btn btn-outline-danger" id="agendaDelete" type="button" hidden>Excluir</button></div>
        </form>
    </dialog>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
<script src="/administracao/agenda/assets/calendar-model.js?v=1"></script>
<script src="/administracao/agenda/assets/agenda.js?v=1"></script>
</body>
</html>
