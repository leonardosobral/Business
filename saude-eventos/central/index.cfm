<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.template = "/saude-eventos/central/"/>
<cfset VARIABLES.saudeAuthMode = "page"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>

<!DOCTYPE html>
<html lang="pt-br">

<cfparam name="URL.id_evento" type="numeric" default="0"/>
<cfparam name="URL.percurso" type="numeric" default="0"/>

<cfset qSaudeEventos = queryNew("id_evento,nome_evento,data_inicial,data_final,cidade,estado,nome_operacao,percurso_padrao,intervalo_atualizacao,inicio_operacao,fim_operacao,local_atendimento,diretor_medico,whatsapp_equipe,instrucoes")/>
<cfset VARIABLES.saudeSchemaReady = true/>
<cftry>
    <cfquery name="qSaudeEventos" datasource="runner_dba">
        SELECT evt.id_evento, evt.nome_evento, evt.data_inicial, evt.data_final,
               evt.cidade, evt.estado, cfg.nome_operacao, cfg.percurso_padrao,
               cfg.intervalo_atualizacao, cfg.inicio_operacao, cfg.fim_operacao,
               cfg.local_atendimento, cfg.diretor_medico, cfg.whatsapp_equipe, cfg.instrucoes
        FROM tb_evento_saude_config cfg
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = cfg.id_evento
        WHERE cfg.ativo = true
          AND evt.ativo = true
          <cfif NOT VARIABLES.saudeIsGlobalAdmin>
              AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeViewEventIds#" list="true"/>)
          </cfif>
        ORDER BY CASE
                     WHEN now() BETWEEN coalesce(cfg.inicio_operacao, '-infinity'::timestamptz)
                                    AND coalesce(cfg.fim_operacao, 'infinity'::timestamptz) THEN 0
                     WHEN coalesce(cfg.inicio_operacao, evt.data_inicial::timestamp) >= now() THEN 1
                     ELSE 2
                 END,
                 coalesce(cfg.inicio_operacao, evt.data_inicial::timestamp) DESC,
                 evt.nome_evento
    </cfquery>
    <cfcatch type="any">
        <cfset VARIABLES.saudeSchemaReady = false/>
        <cfset qSaudeEventos = queryNew("id_evento,nome_evento,data_inicial,data_final,cidade,estado,nome_operacao,percurso_padrao,intervalo_atualizacao,inicio_operacao,fim_operacao,local_atendimento,diretor_medico,whatsapp_equipe,instrucoes")/>
    </cfcatch>
</cftry>

<cfif URL.id_evento LTE 0 AND qSaudeEventos.recordcount>
    <cfset URL.id_evento = qSaudeEventos.id_evento[1]/>
</cfif>

<cfset qSaudeEvento = queryNew("id_evento,nome_evento,data_inicial,data_final,cidade,estado,nome_operacao,percurso_padrao,intervalo_atualizacao,inicio_operacao,fim_operacao,local_atendimento,diretor_medico,whatsapp_equipe,instrucoes")/>
<cfif URL.id_evento GT 0 AND qSaudeEventos.recordcount>
    <cfquery name="qSaudeEvento" dbtype="query">
        SELECT * FROM qSaudeEventos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(URL.id_evento)#"/>
    </cfquery>
</cfif>

<cfset qSaudePercursos = queryNew("percurso_evento,unidade_de_medida,tipo_corrida")/>
<cfif qSaudeEvento.recordcount>
    <cfquery name="qSaudePercursos" datasource="runner_dba">
        SELECT percurso_evento, unidade_de_medida, tipo_corrida
        FROM tb_evento_corridas_percursos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeEvento.id_evento#"/>
        ORDER BY percurso_evento
    </cfquery>
    <cfset VARIABLES.saudeValidCourse = false/>
    <cfloop query="qSaudePercursos">
        <cfif URL.percurso EQ qSaudePercursos.percurso_evento><cfset VARIABLES.saudeValidCourse = true/></cfif>
    </cfloop>
    <cfif NOT VARIABLES.saudeValidCourse>
        <cfif len(trim(qSaudeEvento.percurso_padrao & ""))>
            <cfset URL.percurso = qSaudeEvento.percurso_padrao/>
        <cfelseif qSaudePercursos.recordcount>
            <cfset URL.percurso = qSaudePercursos.percurso_evento[1]/>
        </cfif>
    </cfif>
</cfif>

<cfset VARIABLES.saudeRefreshSeconds = qSaudeEvento.recordcount ? min(300,max(10,val(qSaudeEvento.intervalo_atualizacao))) : 15/>
<cfset VARIABLES.saudeSelectedCourseLabel = URL.percurso & "km"/>
<cfloop query="qSaudePercursos">
    <cfif URL.percurso EQ qSaudePercursos.percurso_evento>
        <cfset VARIABLES.saudeSelectedCourseLabel = qSaudePercursos.percurso_evento & lCase(qSaudePercursos.unidade_de_medida)/>
    </cfif>
</cfloop>

<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="robots" content="noindex,nofollow"/>
    <title>Central de Saúde · Road Runners Business</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css"/>
    <link rel="stylesheet" href="/saude-eventos/central/assets/saude-panel.css?v=20260922-2"/>
</head>

<body>
<cfif NOT VARIABLES.saudeSchemaReady OR NOT qSaudeEvento.recordcount>
    <main class="saude-unavailable">
        <div class="saude-unavailable__card">
            <div class="saude-brand-mark"><i class="fa-solid fa-kit-medical"></i></div>
            <span class="saude-eyebrow">Road Runners Business · Saúde</span>
            <h1>Nenhuma operação disponível</h1>
            <p><cfif VARIABLES.saudeSchemaReady>Nenhuma operação de saúde ativa está vinculada à conta selecionada. Configure um evento em <strong>Gestão do evento → Operação de saúde</strong>.<cfelse>A configuração da central de saúde ainda não foi concluída no servidor.</cfif></p>
            <div class="saude-unavailable__actions">
                <cfif NOT VARIABLES.saudeIsMedical><a href="/saude-eventos/"><i class="fa-solid fa-sliders"></i>Gerenciar operações</a></cfif>
                <a href="/" class="is-secondary"><i class="fa-solid fa-arrow-left"></i>Voltar ao Business</a>
            </div>
        </div>
    </main>
<cfelse>
<div class="saude-app">
    <header class="saude-topbar">
        <div class="saude-brand">
            <div class="saude-brand-mark"><i class="fa-solid fa-kit-medical"></i></div>
            <div>
                <span>Road Runners Business</span>
                <strong>Central de Saúde</strong>
            </div>
        </div>

        <div class="saude-event-heading">
            <span class="saude-live"><i></i>Operação ativa</span>
            <h1><cfoutput>#htmlEditFormat(qSaudeEvento.nome_evento)#</cfoutput></h1>
            <p>
                <cfoutput>#htmlEditFormat(qSaudeEvento.nome_operacao)#</cfoutput>
                <cfif len(trim(qSaudeEvento.diretor_medico & ""))><span>·</span><i class="fa-solid fa-user-doctor"></i><cfoutput>#htmlEditFormat(qSaudeEvento.diretor_medico)#</cfoutput></cfif>
                <cfif len(trim(qSaudeEvento.local_atendimento & ""))><span>·</span><i class="fa-solid fa-location-dot"></i><cfoutput>#htmlEditFormat(qSaudeEvento.local_atendimento)#</cfoutput></cfif>
            </p>
        </div>

        <div class="saude-topbar-actions">
            <label class="saude-event-select">
                <span>Evento</span>
                <select id="eventSelector" aria-label="Selecionar evento">
                    <cfoutput query="qSaudeEventos">
                        <option value="#qSaudeEventos.id_evento#" <cfif qSaudeEventos.id_evento EQ qSaudeEvento.id_evento>selected</cfif>>#htmlEditFormat(qSaudeEventos.nome_evento)#</option>
                    </cfoutput>
                </select>
            </label>
            <button type="button" class="saude-icon-button" id="refreshButton" title="Atualizar agora"><i class="fa-solid fa-rotate"></i></button>
            <cfif NOT VARIABLES.saudeIsMedical><a class="saude-icon-button" href="/saude-eventos/?id_evento=<cfoutput>#qSaudeEvento.id_evento#</cfoutput>#configuracao" title="Gerenciar operação"><i class="fa-solid fa-sliders"></i></a></cfif>
        </div>
    </header>

    <main class="saude-main">
        <section class="saude-control-strip">
            <div class="saude-courses" aria-label="Percursos do evento">
                <span>Percurso</span>
                <cfoutput query="qSaudePercursos">
                    <a href="./?id_evento=#qSaudeEvento.id_evento#&percurso=#urlEncodedFormat(qSaudePercursos.percurso_evento)#" class="#(URL.percurso EQ qSaudePercursos.percurso_evento ? 'is-active' : '')#">#qSaudePercursos.percurso_evento##lCase(qSaudePercursos.unidade_de_medida)#</a>
                </cfoutput>
            </div>
            <div class="saude-sync-state">
                <span id="syncState"><i class="fa-solid fa-circle-check"></i>Atualizado agora</span>
                <div class="saude-progress"><i id="syncProgress"></i></div>
                <small>nova leitura em <strong id="syncCountdown"><cfoutput>#VARIABLES.saudeRefreshSeconds#</cfoutput></strong>s</small>
            </div>
        </section>

        <cfif len(trim(qSaudeEvento.instrucoes & ""))>
            <details class="saude-instructions">
                <summary><i class="fa-solid fa-circle-info"></i>Orientações da operação</summary>
                <p><cfoutput>#encodeForHTML(qSaudeEvento.instrucoes)#</cfoutput></p>
            </details>
        </cfif>

        <section class="saude-kpis" aria-label="Resumo da operação">
            <article><span class="is-neutral"><i class="fa-solid fa-users"></i></span><div><strong data-stat="total">—</strong><small>Atletas no evento</small></div></article>
            <article><span class="is-blue"><i class="fa-solid fa-wave-square"></i></span><div><strong data-stat="monitorados">—</strong><small>Monitorados</small></div></article>
            <article><span class="is-danger"><i class="fa-solid fa-triangle-exclamation"></i></span><div><strong data-stat="triagem">—</strong><small>Aguardando triagem</small></div></article>
            <article><span class="is-warning"><i class="fa-solid fa-stethoscope"></i></span><div><strong data-stat="atendimento">—</strong><small>Em cuidado</small></div></article>
            <article><span class="is-success"><i class="fa-solid fa-check"></i></span><div><strong data-stat="atendidos">—</strong><small>Atendidos</small></div></article>
        </section>

        <section class="saude-workspace">
            <article class="saude-queue-card is-startlist">
                <header>
                    <div><span class="saude-queue-kicker">Lista da prova</span><h2>Atletas <small id="startlistCount"></small></h2></div>
                    <span class="saude-course-label"><cfoutput>#htmlEditFormat(VARIABLES.saudeSelectedCourseLabel)#</cfoutput></span>
                </header>
                <div class="saude-search">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input id="athleteSearch" type="search" placeholder="Buscar nome ou número de peito" autocomplete="off"/>
                    <kbd>/</kbd>
                </div>
                <div class="saude-table-wrap">
                    <table><thead><tr><th>BIB</th><th>Atleta</th><th><i class="fa-regular fa-address-card" title="Ficha médica"></i></th></tr></thead><tbody id="startlistBody"><tr><td colspan="3" class="saude-loading-row"><i class="fa-solid fa-circle-notch fa-spin"></i>Carregando atletas…</td></tr></tbody></table>
                </div>
            </article>

            <article class="saude-queue-card is-triage">
                <header>
                    <div><span class="saude-queue-kicker">Primeiro cuidado</span><h2>Aguardando triagem</h2></div>
                    <div class="saude-triage-header-actions">
                        <cfif VARIABLES.saudeCanOperate><button type="button" class="saude-triage-clear-button" onclick="prepararLimpezaTriagem()" title="Retornar todos os atletas desta coluna à Lista da Prova"><i class="fa-solid fa-broom"></i><span>Limpar</span></button></cfif>
                        <span class="saude-queue-count" data-stat="triagem">—</span>
                    </div>
                </header>
                <cfif VARIABLES.saudeCanOperate>
                    <div class="saude-triage-confirmation" id="triageClearConfirmation" role="alertdialog" aria-labelledby="triageClearTitle" hidden>
                        <div><strong id="triageClearTitle">Limpar toda a triagem?</strong><p>Atletas com status Scan ou Acionado retornarão à Lista da Prova.</p></div>
                        <div><button type="button" onclick="cancelarLimpezaTriagem()">Cancelar</button><button type="button" class="is-confirm" id="triageClearConfirmButton" onclick="limparTriagem()">Confirmar</button></div>
                    </div>
                </cfif>
                <div class="saude-table-wrap">
                    <table><thead><tr><th>BIB</th><th>Atleta</th><th>Status</th><th>Hora</th><th><i class="fa-regular fa-address-card"></i></th></tr></thead><tbody id="triageBody"><tr><td colspan="5" class="saude-loading-row"><i class="fa-solid fa-circle-notch fa-spin"></i>Atualizando fila…</td></tr></tbody></table>
                </div>
            </article>

            <article class="saude-queue-card is-care">
                <header>
                    <div><span class="saude-queue-kicker">Acompanhamento</span><h2 id="careTitle">Em cuidado</h2></div>
                    <div class="saude-queue-tabs"><button type="button" class="is-active" data-care-view="atendimento">Ativos</button><button type="button" data-care-view="atendidos">Atendidos</button></div>
                </header>
                <div class="saude-table-wrap">
                    <table><thead><tr><th>BIB</th><th>Atleta</th><th>Status</th><th>Hora</th><th><i class="fa-regular fa-address-card"></i></th></tr></thead><tbody id="careBody"><tr><td colspan="5" class="saude-loading-row"><i class="fa-solid fa-circle-notch fa-spin"></i>Atualizando fila…</td></tr></tbody></table>
                </div>
            </article>
        </section>
    </main>

    <div class="saude-drawer-backdrop" id="athleteBackdrop" hidden onclick="fecharAtleta()"></div>
    <aside class="saude-drawer" id="athleteDrawer" aria-hidden="true">
        <div id="athleteDrawerContent" class="saude-drawer-content"></div>
    </aside>

    <div class="saude-toast" id="saudeToast" role="status" aria-live="polite"><i></i><span></span></div>
</div>

<script>
(() => {
    const eventId = <cfoutput>#int(qSaudeEvento.id_evento)#</cfoutput>;
    const course = <cfoutput>#val(URL.percurso)#</cfoutput>;
    const refreshSeconds = <cfoutput>#VARIABLES.saudeRefreshSeconds#</cfoutput>;
    const csrfToken = <cfoutput>#serializeJSON(VARIABLES.saudeCsrfToken)#</cfoutput>;
    let countdown = refreshSeconds;
    let careView = 'atendimento';
    let refreshing = false;

    const byId = id => document.getElementById(id);
    const endpoints = {
        startlist: `/saude-eventos/central/fetch/startlist.cfm?id_evento=${eventId}&percurso=${course}`,
        triage: `/saude-eventos/central/fetch/leaderboard.cfm?id_evento=${eventId}&categoria=scan`,
        care: () => `/saude-eventos/central/fetch/leaderboard.cfm?id_evento=${eventId}&categoria=${careView}`,
        stats: `/saude-eventos/central/fetch/stats.cfm?id_evento=${eventId}`,
        athlete: registrationId => `/saude-eventos/central/fetch/athlete.cfm?id_evento=${eventId}&id_inscricao=${registrationId}`,
        note: '/saude-eventos/central/fetch/note.cfm',
        contact: '/saude-eventos/central/fetch/contact.cfm',
        triageClear: '/saude-eventos/central/fetch/triage-clear.cfm'
    };

    async function fetchHtml(url) {
        const response = await fetch(url, {credentials: 'same-origin', headers: {'X-Requested-With': 'XMLHttpRequest'}});
        if (!response.ok) throw new Error(response.status === 401 ? 'Sua sessão expirou.' : 'Não foi possível atualizar os dados.');
        return response.text();
    }

    function toast(message, type = 'success') {
        const el = byId('saudeToast');
        el.className = `saude-toast is-${type} is-visible`;
        el.querySelector('i').className = type === 'success' ? 'fa-solid fa-circle-check' : 'fa-solid fa-triangle-exclamation';
        el.querySelector('span').textContent = message;
        window.clearTimeout(toast.timer);
        toast.timer = window.setTimeout(() => el.classList.remove('is-visible'), 3600);
    }

    function responseValue(payload, key) {
        return payload?.[key] ?? payload?.[key.toUpperCase()];
    }

    function applySearch() {
        const query = byId('athleteSearch').value.trim().toLocaleLowerCase('pt-BR');
        let visible = 0;
        byId('startlistBody').querySelectorAll('tr[data-search]').forEach(row => {
            const show = !query || row.dataset.search.includes(query);
            row.hidden = !show;
            if (show) visible++;
        });
        byId('startlistCount').textContent = visible ? `(${visible})` : '';
    }

    async function refreshAll(silent = false) {
        if (refreshing) return;
        refreshing = true;
        byId('refreshButton').classList.add('is-spinning');
        try {
            const [startlist, triage, care, statsResponse] = await Promise.all([
                fetchHtml(endpoints.startlist), fetchHtml(endpoints.triage), fetchHtml(endpoints.care()),
                fetch(endpoints.stats, {credentials: 'same-origin'}).then(r => {
                    if (!r.ok) throw new Error('Não foi possível ler os indicadores.');
                    return r.json();
                })
            ]);
            byId('startlistBody').innerHTML = startlist;
            byId('triageBody').innerHTML = triage;
            byId('careBody').innerHTML = care;
            Object.entries(statsResponse).forEach(([key, value]) => {
                document.querySelectorAll(`[data-stat="${key.toLocaleLowerCase('pt-BR')}"]`).forEach(el => el.textContent = value);
            });
            applySearch();
            byId('syncState').innerHTML = '<i class="fa-solid fa-circle-check"></i>Atualizado agora';
            countdown = refreshSeconds;
            if (!silent) toast('Painel atualizado.');
        } catch (error) {
            byId('syncState').innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i>Falha na atualização';
            toast(error.message || 'Não foi possível atualizar o painel.', 'error');
        } finally {
            refreshing = false;
            byId('refreshButton').classList.remove('is-spinning');
        }
    }

    window.carregarAtleta = async registrationId => {
        const drawer = byId('athleteDrawer');
        byId('athleteDrawerContent').innerHTML = '<div class="saude-drawer-loading"><i class="fa-solid fa-circle-notch fa-spin"></i><span>Carregando ficha…</span></div>';
        drawer.classList.add('is-open');
        drawer.setAttribute('aria-hidden', 'false');
        byId('athleteBackdrop').hidden = false;
        document.body.classList.add('saude-drawer-open');
        try {
            byId('athleteDrawerContent').innerHTML = await fetchHtml(endpoints.athlete(registrationId));
        } catch (error) {
            byId('athleteDrawerContent').innerHTML = `<div class="saude-drawer-empty"><i class="fa-solid fa-triangle-exclamation"></i><h2>Ficha indisponível</h2><p>${error.message}</p></div>`;
        }
    };

    window.fecharAtleta = () => {
        byId('athleteDrawer').classList.remove('is-open');
        byId('athleteDrawer').setAttribute('aria-hidden', 'true');
        byId('athleteBackdrop').hidden = true;
        document.body.classList.remove('saude-drawer-open');
    };

    window.atualizarStatus = async (registrationId, status) => {
        const form = new URLSearchParams({id_evento: eventId, id_inscricao: registrationId, status, csrf_token: csrfToken});
        try {
            const response = await fetch('/saude-eventos/central/fetch/status.cfm', {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form
            });
            const result = await response.json();
            const success = responseValue(result, 'success');
            const message = responseValue(result, 'message');
            if (!response.ok || !success) throw new Error(message || 'Não foi possível atualizar o atendimento.');
            toast(message || 'Atendimento atualizado.');
            fecharAtleta();
            await refreshAll(true);
        } catch (error) { toast(error.message, 'error'); }
    };

    window.adicionarAnotacao = async registrationId => {
        const field = byId('saudeNoteText');
        const button = byId('saudeNoteButton');
        const note = field?.value.trim() || '';
        if (!note) {
            field?.focus();
            toast('Escreva a anotação antes de adicionar.', 'error');
            return;
        }

        const form = new URLSearchParams({
            id_evento: eventId,
            id_inscricao: registrationId,
            anotacao: note,
            csrf_token: csrfToken
        });
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Adicionando…';
        }
        try {
            const response = await fetch(endpoints.note, {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form
            });
            const result = await response.json();
            const success = responseValue(result, 'success');
            const message = responseValue(result, 'message');
            if (!response.ok || !success) throw new Error(message || 'Não foi possível adicionar a anotação.');
            toast(message || 'Anotação adicionada à cronologia.');
            await window.carregarAtleta(registrationId);
        } catch (error) {
            toast(error.message || 'Não foi possível adicionar a anotação.', 'error');
            if (button) {
                button.disabled = false;
                button.innerHTML = '<i class="fa-solid fa-plus"></i> Adicionar à cronologia';
            }
        }
    };

    window.acionarContato = async (registrationId, contactType, channel, button) => {
        const externalWindow = channel === 'whatsapp' ? window.open('', '_blank') : null;
        if (externalWindow) {
            externalWindow.opener = null;
            externalWindow.document.title = 'Abrindo WhatsApp…';
        }
        const originalContent = button?.innerHTML || '';
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i>';
        }

        const form = new URLSearchParams({
            id_evento: eventId,
            id_inscricao: registrationId,
            contato: contactType,
            canal: channel,
            csrf_token: csrfToken
        });
        try {
            const response = await fetch(endpoints.contact, {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form
            });
            const result = await response.json();
            const success = responseValue(result, 'success');
            const message = responseValue(result, 'message');
            const target = responseValue(result, 'target');
            const validTarget = channel === 'whatsapp'
                ? /^https:\/\/wa\.me\/[0-9]{12,15}$/.test(target || '')
                : /^tel:\+[0-9]{12,15}$/.test(target || '');
            if (!response.ok || !success || !validTarget) throw new Error(message || 'Não foi possível iniciar o contato.');

            if (channel === 'whatsapp') {
                if (externalWindow) externalWindow.location.replace(target);
                else window.location.href = target;
            } else {
                window.location.href = target;
            }
            toast(message || 'Contato registrado na cronologia.');
            await window.carregarAtleta(registrationId);
        } catch (error) {
            if (externalWindow) externalWindow.close();
            toast(error.message || 'Não foi possível iniciar o contato.', 'error');
            if (button) {
                button.disabled = false;
                button.innerHTML = originalContent;
            }
        }
    };

    window.prepararDesvinculoBib = (registrationId, bib) => {
        const confirmation = byId('bibUnlinkConfirmation');
        if (!confirmation
            || Number(confirmation.dataset.inscricao) !== Number(registrationId)
            || Number(confirmation.dataset.bib) !== Number(bib)) return;
        confirmation.hidden = false;
        byId('bibUnlinkConfirmButton')?.focus();
    };

    window.cancelarDesvinculoBib = () => {
        const confirmation = byId('bibUnlinkConfirmation');
        if (confirmation) confirmation.hidden = true;
    };

    window.desvincularBib = async (registrationId, bib) => {
        const confirmation = byId('bibUnlinkConfirmation');
        const button = byId('bibUnlinkConfirmButton');
        if (!confirmation
            || confirmation.hidden
            || Number(confirmation.dataset.inscricao) !== Number(registrationId)
            || Number(confirmation.dataset.bib) !== Number(bib)) return;

        const form = new URLSearchParams({id_evento: eventId, id_inscricao: registrationId, csrf_token: csrfToken});
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Desvinculando…';
        }
        try {
            const response = await fetch('/saude-eventos/central/fetch/bib.cfm', {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form
            });
            const result = await response.json();
            const success = responseValue(result, 'success');
            const message = responseValue(result, 'message');
            if (!response.ok || !success) throw new Error(message || 'Não foi possível desvincular o BIB.');
            toast(message || `BIB ${bib} desvinculado.`);
            fecharAtleta();
            await refreshAll(true);
        } catch (error) {
            toast(error.message || 'Não foi possível desvincular o BIB.', 'error');
            if (button) {
                button.disabled = false;
                button.innerHTML = '<i class="fa-solid fa-link-slash"></i> Confirmar desvínculo';
            }
        }
    };

    window.prepararLimpezaTriagem = () => {
        const confirmation = byId('triageClearConfirmation');
        if (!confirmation) return;
        confirmation.hidden = false;
        byId('triageClearConfirmButton')?.focus();
    };

    window.cancelarLimpezaTriagem = () => {
        const confirmation = byId('triageClearConfirmation');
        if (confirmation) confirmation.hidden = true;
    };

    window.limparTriagem = async () => {
        const confirmation = byId('triageClearConfirmation');
        const button = byId('triageClearConfirmButton');
        if (!confirmation || confirmation.hidden) return;
        const form = new URLSearchParams({id_evento: eventId, csrf_token: csrfToken});
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Limpando…';
        }
        try {
            const response = await fetch(endpoints.triageClear, {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form
            });
            const result = await response.json();
            const success = responseValue(result, 'success');
            const message = responseValue(result, 'message');
            if (!response.ok || !success) throw new Error(message || 'Não foi possível limpar a triagem.');
            confirmation.hidden = true;
            toast(message || 'Triagem limpa.');
            fecharAtleta();
            await refreshAll(true);
        } catch (error) {
            toast(error.message || 'Não foi possível limpar a triagem.', 'error');
        } finally {
            if (button) {
                button.disabled = false;
                button.textContent = 'Confirmar';
            }
        }
    };

    byId('eventSelector').addEventListener('change', event => {
        window.location.href = `/saude-eventos/central/?id_evento=${encodeURIComponent(event.target.value)}`;
    });
    byId('refreshButton').addEventListener('click', () => refreshAll(false));
    byId('athleteSearch').addEventListener('input', applySearch);
    document.addEventListener('keydown', event => {
        if (event.key === '/' && document.activeElement.tagName !== 'INPUT') { event.preventDefault(); byId('athleteSearch').focus(); }
        if (event.key === 'Escape') fecharAtleta();
    });
    document.querySelectorAll('[data-care-view]').forEach(button => button.addEventListener('click', async () => {
        careView = button.dataset.careView;
        document.querySelectorAll('[data-care-view]').forEach(item => item.classList.toggle('is-active', item === button));
        byId('careTitle').textContent = careView === 'atendidos' ? 'Atendidos' : 'Em cuidado';
        byId('careBody').innerHTML = '<tr><td colspan="5" class="saude-loading-row"><i class="fa-solid fa-circle-notch fa-spin"></i>Atualizando fila…</td></tr>';
        try { byId('careBody').innerHTML = await fetchHtml(endpoints.care()); }
        catch (error) { toast(error.message, 'error'); }
    }));

    window.setInterval(() => {
        countdown--;
        if (countdown <= 0) refreshAll(true);
        byId('syncCountdown').textContent = Math.max(0, countdown);
        byId('syncProgress').style.width = `${Math.max(0, countdown / refreshSeconds * 100)}%`;
    }, 1000);
    refreshAll(true);
})();
</script>
</cfif>
</body>
</html>
