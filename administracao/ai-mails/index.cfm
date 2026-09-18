<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/administracao/ai-mails/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfif NOT structKeyExists(session,"aiMailCsrf")><cfset session.aiMailCsrf=agendaRandom()/></cfif>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="Referrer-Policy" value="same-origin"/>
<!doctype html><html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260917-aimails"/>
<link rel="stylesheet" href="/administracao/ai-mails/assets/ai-mails.css?v=1"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main class="container-fluid px-3 px-lg-4 business-page admin-suite-page admin-suite-main ai-mails" id="aiMails" data-csrf="<cfoutput>#encodeForHtmlAttribute(session.aiMailCsrf)#</cfoutput>">
    <header class="admin-suite-header">
        <div class="admin-suite-heading"><span class="admin-suite-heading-icon" aria-hidden="true"><i class="fa-solid fa-envelope-open-text"></i></span><div class="admin-suite-heading-copy"><div class="admin-suite-kicker">Ferramentas administrativas</div><h1 class="admin-suite-title">AI-mails</h1><p class="admin-suite-subtitle">Menos ruído. Mais atenção ao que importa. · contato@runnerhub.run</p></div></div>
        <cfinclude template="../../includes/estrutura/admin_suite_nav.cfm"/>
    </header>
    <section class="admin-suite-commandbar" aria-label="Monitoramento da caixa">
        <div class="admin-suite-status"><i class="fa-solid fa-circle" aria-hidden="true"></i><span id="mailStatus" role="status">Verificando monitor…</span></div>
        <div class="admin-suite-actions"><button class="btn btn-outline-light" id="mailRefresh" type="button"><i class="fa-solid fa-rotate me-2" aria-hidden="true"></i>Atualizar agora</button><button class="btn btn-warning" id="mailSettings" type="button"><i class="fa-solid fa-sliders me-2" aria-hidden="true"></i>Configurações</button></div>
    </section>
    <cfif structKeyExists(session,"aiMailMessage")><p class="mail-notice" role="status"><cfoutput>#encodeForHTML(session.aiMailMessage)#</cfoutput></p><cfset structDelete(session,"aiMailMessage")/></cfif>
    <div id="mailMessage" class="mail-notice" role="status" aria-live="polite" hidden></div>
    <section id="mailSetup" class="mail-setup" hidden><span class="mail-setup-icon" aria-hidden="true"><i class="fa-brands fa-google"></i></span><div><h2 class="h5">Uma caixa. Uma central de atenção.</h2><p id="mailSetupText"></p><small>Acesso exclusivo dos admins globais. Nenhum e-mail será enviado ou alterado.</small></div><button class="btn btn-warning" id="mailConnect" type="button">Autorizar leitura do Gmail</button></section>
    <section class="mail-metrics" aria-label="Indicadores de atenção">
        <button class="mail-metric" type="button" data-metric=""><span>Pendências abertas</span><strong id="metricPending">—</strong><small>Conversas que merecem atenção</small></button>
        <button class="mail-metric mail-metric-urgent" type="button" data-metric="urgent"><span>Críticas e altas</span><strong id="metricUrgent">—</strong><small>Priorize estas conversas</small></button>
        <button class="mail-metric" type="button" data-metric="response"><span>Aguardando resposta</span><strong id="metricResponse">—</strong><small>Retorno solicitado à equipe</small></button>
        <button class="mail-metric" type="button" data-metric="overdue"><span>Prazos vencidos</span><strong id="metricOverdue">—</strong><small>Somente prazos explícitos</small></button>
    </section>
    <div class="mail-monitor"><span id="mailProgress">Consultando fila de análise…</span><small>Os indicadores podem se sobrepor. Resolver aqui não altera o Gmail.</small></div>
    <section class="mail-workspace" aria-label="Conversas analisadas">
        <nav class="mail-views" aria-label="Visões de atendimento"><button type="button" data-view="pending" aria-pressed="true">Pendentes</button><button type="button" data-view="in_progress" aria-pressed="false">Em andamento</button><button type="button" data-view="resolved" aria-pressed="false">Resolvidos</button><button type="button" data-view="review" aria-pressed="false">Revisão da triagem</button></nav>
        <form id="mailFilters" class="mail-filters">
            <label class="mail-search">Buscar<input name="search" class="form-control" type="search" maxlength="100" placeholder="Assunto, remetente ou resumo"/></label>
            <label>Prioridade<select name="priority" class="form-select"><option value="">Todas</option><option value="critical">Crítica</option><option value="high">Alta</option><option value="normal">Normal</option><option value="informational">Para ciência</option><option value="low">Baixa relevância</option></select></label>
            <label>Categoria<select name="category" class="form-select"><option value="">Todas</option><option value="operacao">Operação</option><option value="financeiro">Financeiro</option><option value="comercial">Comercial</option><option value="suporte">Suporte</option><option value="seguranca">Segurança</option><option value="juridico">Jurídico</option><option value="outros">Outros</option></select></label>
            <label>Responsável<select name="assignee" class="form-select" id="mailAssignee"><option value="">Todos</option><option value="none">Não atribuído</option></select></label>
            <label>Atenção<select name="attention" class="form-select"><option value="">Todas</option><option value="urgent">Críticas e altas</option><option value="response">Requer resposta</option><option value="action">Requer ação</option><option value="overdue">Prazo vencido</option></select></label>
            <label>Recebimento<select name="days" class="form-select"><option value="">Todo o período</option><option value="1">Últimas 24 h</option><option value="7">Últimos 7 dias</option><option value="30">Últimos 30 dias</option></select></label>
            <button class="btn btn-outline-light" type="reset">Limpar</button>
        </form>
        <div class="mail-list-top"><span id="mailCount" role="status">Carregando conversas…</span><span>Prioridade → prazo → antiguidade</span></div>
        <div id="mailItems" class="mail-items" aria-busy="true"></div>
        <div class="mail-pagination"><button id="mailPrev" type="button" class="btn btn-outline-light" disabled>Anterior</button><span id="mailPage"></span><button id="mailNext" type="button" class="btn btn-outline-light" disabled>Próxima</button></div>
    </section>
    <dialog id="mailDetail" class="mail-dialog mail-detail" aria-labelledby="mailDetailTitle"><div class="mail-dialog-top"><span class="admin-suite-kicker">Análise da conversa</span><button type="button" class="btn btn-outline-light" data-close aria-label="Fechar detalhe">Fechar</button></div><div id="mailDetailBody"></div></dialog>
    <dialog id="mailConfig" class="mail-dialog" aria-labelledby="mailConfigTitle"><form id="mailConfigForm"><div class="mail-dialog-top"><h2 class="h4" id="mailConfigTitle">Configurações do AI-mails</h2><button type="button" class="btn btn-outline-light" data-close>Fechar</button></div>
        <p>Caixa <strong>contato@runnerhub.run</strong> · execução a cada 5 minutos, mesmo com o painel fechado.</p>
        <label class="mail-check"><input type="checkbox" name="enabled"/> Monitoramento ativo</label>
        <div class="mail-config-grid"><label>Modelo OpenAI<input class="form-control" name="model" value="gpt-4.1-mini" maxlength="100" required/></label><label>Limite de análises por dia<input class="form-control" name="daily_limit" type="number" min="1" max="2000" value="100" required/></label><label>Carga inicial: últimos dias<input class="form-control" name="initial_days" type="number" min="1" max="365" value="30" required/></label><label>Retenção de resolvidos (dias)<input class="form-control" name="retention_days" type="number" min="7" max="365" value="90" required/></label></div>
        <p class="mail-muted">A carga inclui também mensagens antigas não lidas ou importantes na caixa de entrada. Alterar o período inicia uma reconciliação sem apagar decisões. Anexos não são analisados.</p>
        <label class="mail-check"><input type="checkbox" name="consent"/> Autorizo o processamento do conteúdo das mensagens pela OpenAI para triagem interna. Os corpos não serão armazenados permanentemente no Business nem adicionados ao RAG. Resumos e observações ficam restritos aos admins globais.</label>
        <p class="mail-muted">O processamento usa <code>store=false</code>; isso não elimina os registros de segurança do provedor. <a href="https://developers.openai.com/api/docs/guides/your-data" target="_blank" rel="noopener noreferrer">Política de dados da OpenAI</a>. A retenção preserva pendências abertas; textos de itens resolvidos expiram no período configurado.</p>
        <div id="mailUsage" class="mail-notice"></div><p id="mailConfigError" role="alert" class="text-warning"></p><div class="mail-actions"><button type="submit" class="btn btn-warning">Salvar configurações</button><button type="button" id="mailReconnect" class="btn btn-outline-light">Reautorizar Google</button><a href="/administracao/cron-jobs/" class="btn btn-outline-light">Histórico do monitor</a></div>
    </form></dialog>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
<script src="/administracao/ai-mails/assets/ai-mails.js?v=2"></script>
</body></html>
