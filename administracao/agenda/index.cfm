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
<link rel="stylesheet" href="/administracao/agenda/assets/agenda.css?v=20261010-editor2"/>
<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260917-aimails"/>
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
        <label>Buscar neste período<input id="agendaSearch" type="search" class="form-control" placeholder="Título, local ou participante…"/></label>
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
    <dialog id="agendaEventDialog" class="agenda-dialog agenda-event-dialog" aria-labelledby="agendaEventHeading">
        <form id="agendaEventForm" novalidate>
            <header class="agenda-dialog-header">
                <div><div class="agenda-eyebrow">Compromisso · horário de Brasília</div><h2 id="agendaEventHeading" class="h5">Novo compromisso</h2><p id="agendaEventMeta" class="agenda-muted"></p></div>
                <button type="button" class="agenda-icon-button" data-close aria-label="Fechar compromisso">×</button>
            </header>
            <div class="agenda-tabs" role="tablist" aria-label="Dados do compromisso">
                <button type="button" id="agendaTabDetails" role="tab" data-panel="details" aria-controls="agendaPanelDetails" aria-selected="true">Detalhes</button>
                <button type="button" id="agendaTabParticipants" role="tab" data-panel="participants" aria-controls="agendaPanelParticipants" aria-selected="false" tabindex="-1">Participantes <span id="agendaGuestCount">0</span></button>
                <button type="button" id="agendaTabOptions" role="tab" data-panel="options" aria-controls="agendaPanelOptions" aria-selected="false" tabindex="-1">Opções</button>
            </div>
            <div class="agenda-dialog-body">
            <p id="agendaRecurrenceNotice" class="agenda-notice text-warning" hidden></p>
            <p id="agendaCardNotice" class="agenda-notice agenda-muted" hidden></p>
            <section id="agendaPanelDetails" role="tabpanel" aria-labelledby="agendaTabDetails">
            <label class="agenda-field">Título<input name="summary" class="form-control" maxlength="1024" required/></label>
            <label class="agenda-field"><span><input name="allDay" type="checkbox"/> Dia inteiro</span></label>
            <div class="agenda-two"><label class="agenda-field">Início<input name="start" class="form-control" type="datetime-local" required/></label><label class="agenda-field"><span id="agendaEndLabel">Término</span><input name="end" class="form-control" type="datetime-local" required/></label></div>
            <p class="agenda-muted small" id="agendaDateHint">Em eventos de dia inteiro, a data final é o primeiro dia fora do compromisso.</p>
            <label class="agenda-field">Local<input name="location" class="form-control" maxlength="1024" placeholder="Endereço, sala ou local do encontro"/></label>
            <a id="agendaMapLink" class="agenda-inline-link" target="_blank" rel="noopener noreferrer" hidden>Ver no Google Maps ↗</a>
            <div class="agenda-meeting-card">
                <div><strong>Reunião on-line</strong><p id="agendaMeetingInfo" class="agenda-muted"></p></div>
            </div>
            <label class="agenda-field">Descrição / pauta<textarea name="description" class="form-control" rows="5" maxlength="8000" placeholder="Objetivo, pauta e orientações para os participantes"></textarea></label>
            </section>
            <section id="agendaPanelParticipants" role="tabpanel" aria-labelledby="agendaTabParticipants" hidden>
                <h3 class="h6">Convidados e confirmações</h3><p class="agenda-muted small">Respostas sincronizadas com o Google. Só o próprio convidado pode confirmar sua presença. Trocar o e-mail cria um novo convite.</p>
                <div id="agendaGuestSummary" class="agenda-rsvp-summary"></div>
                <div class="agenda-guest-add"><label class="agenda-field" for="agendaGuestInput">Adicionar participantes<textarea id="agendaGuestInput" class="form-control" rows="1" placeholder="Digite ou cole e-mails separados por vírgula, ponto e vírgula ou quebra de linha"></textarea></label><button id="agendaAddGuests" type="button" class="btn btn-outline-light btn-sm">Adicionar convidados</button></div>
                <p id="agendaGuestError" class="text-danger small" role="alert"></p>
                <div id="agendaGuestList"></div>
            </section>
            <section id="agendaPanelOptions" role="tabpanel" aria-labelledby="agendaTabOptions" hidden>
            <div class="agenda-two" id="agendaRepeatFields"><label class="agenda-field">Repetir<select name="repeat" class="form-select"><option value="none">Não repetir</option><option value="DAILY">Diariamente</option><option value="WEEKLY">Semanalmente</option><option value="MONTHLY">Mensalmente</option></select></label><label class="agenda-field">Total de ocorrências<input name="count" class="form-control" type="number" min="2" max="52" value="4"/></label></div>
            <h3 class="h6">Lembretes da agenda compartilhada</h3><p class="agenda-muted small">Esses lembretes pertencem à conta da agenda; não substituem as preferências pessoais dos convidados.</p>
            <label class="agenda-field">Lembretes<select id="agendaReminderMode" class="form-select"><option value="default">Usar padrão da agenda</option><option value="custom">Personalizar</option><option value="none">Sem lembretes</option></select></label>
            <div id="agendaReminderCustom" hidden><div id="agendaReminderList"></div><button id="agendaAddReminder" type="button" class="btn btn-outline-light btn-sm">Adicionar lembrete</button><p class="agenda-muted small">Até 5 lembretes, de 0 a 40.320 minutos antes do início.</p></div>
            <dl id="agendaOrganizer" class="agenda-organizer"></dl>
            <div class="agenda-actions"><a class="btn btn-outline-light btn-sm" id="agendaGoogleLink" target="_blank" rel="noopener noreferrer" hidden>Abrir no Google ↗</a><button class="btn btn-outline-light btn-sm" id="agendaEditSeries" type="button" hidden>Editar série inteira</button><button class="btn btn-outline-danger btn-sm" id="agendaDelete" type="button" hidden>Excluir compromisso</button></div>
            </section>
            </div>
            <footer class="agenda-dialog-footer">
            <label class="agenda-field">Notificar participantes<select name="send_updates" class="form-select form-select-sm" required><option value="">Escolha antes de salvar ou excluir</option><option value="all">Enviar convites e atualizações para todos</option><option value="none">Não solicitar notificações por e-mail</option></select></label>
            <p class="agenda-muted small">Sem notificações, a atualização pode não chegar às agendas externas.</p>
            <p id="agendaEventError" class="text-danger" role="alert"></p>
            <div class="agenda-actions"><button class="btn btn-warning" id="agendaSave" type="submit">Salvar compromisso</button><button class="btn btn-outline-light" type="button" data-close>Fechar</button><a id="agendaMeetingLink" class="btn btn-outline-light btn-sm" target="_blank" rel="noopener noreferrer" hidden>Entrar na reunião ↗</a><button id="agendaCopyMeeting" class="btn btn-outline-light btn-sm" type="button" hidden>Copiar link</button><span id="agendaDirtyStatus" class="agenda-muted small" role="status"></span><span id="agendaCopyStatus" role="status" class="small"></span></div>
            </footer>
        </form>
    </dialog>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
<script src="/administracao/agenda/assets/calendar-model.js?v=20261010-editor2"></script>
<script src="/administracao/agenda/assets/agenda.js?v=20261010-editor2"></script>
</body>
</html>
