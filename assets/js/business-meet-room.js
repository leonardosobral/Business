(function (global, factory) {
    'use strict';
    const api = factory();
    if (typeof module === 'object' && module.exports) module.exports = api;
    if (global && global.document) {
        const start = () => api.mount(global, global.document);
        if (global.document.readyState === 'loading') {
            global.document.addEventListener('DOMContentLoaded', start, {once: true});
        } else {
            start();
        }
    }
}(typeof window !== 'undefined' ? window : null, function () {
    'use strict';

    function field(value, name) {
        if (!value || typeof value !== 'object') return undefined;
        if (Object.prototype.hasOwnProperty.call(value, name)) return value[name];
        return value[name.toUpperCase()];
    }

    function participantLabel(participant) {
        const displayName = field(participant, 'displayName');
        if (typeof displayName !== 'string') return 'Participante';
        const name = displayName.trim();
        return name || 'Participante';
    }

    function participantInitials(value) {
        const name = typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : '';
        if (!name) return '?';
        const parts = name.split(' ');
        const first = Array.from(parts[0]);
        if (parts.length === 1) return first.slice(0, 2).join('').toLocaleUpperCase('pt-BR');
        return (first[0] + Array.from(parts[parts.length - 1])[0]).toLocaleUpperCase('pt-BR');
    }

    function participantTone(value) {
        return Array.from(typeof value === 'string' ? value : '').reduce((total, character) => {
            return total + character.codePointAt(0);
        }, 0) % 5;
    }

    function viewModel(payload) {
        if (!payload || field(payload, 'success') === false) {
            return {
                badge: 'Indisponível', badgeClass: 'badge-danger',
                summary: field(payload, 'message') || 'Não foi possível atualizar a presença no Google Meet.',
                people: []
            };
        }
        if (!field(payload, 'configured')) {
            return {
                badge: 'Configuração pendente', badgeClass: 'badge-warning',
                summary: field(payload, 'message') || 'Configure a sala virtual no servidor.', people: []
            };
        }
        if (!field(payload, 'connected')) {
            return {
                badge: 'Google desconectado', badgeClass: 'badge-warning',
                summary: field(payload, 'message') || 'Conecte novamente a conta em Agenda Google.', people: []
            };
        }
        const participants = field(payload, 'participants');
        const people = Array.isArray(participants)
            ? participants.map(participantLabel).sort((a, b) => a.localeCompare(b, 'pt-BR'))
            : [];
        if (!field(payload, 'active')) {
            return {
                badge: 'Sala vazia', badgeClass: 'badge-secondary',
                summary: 'Ninguém está conectado à sala neste momento.', people: []
            };
        }
        const participantCount = field(payload, 'participantCount');
        const count = Number.isFinite(Number(participantCount)) ? Number(participantCount) : people.length;
        return {
            badge: 'Sala ativa', badgeClass: 'badge-success',
            summary: count === 1 ? '1 pessoa conectada agora.' : count + ' pessoas conectadas agora.',
            people
        };
    }

    function safeMeetingUri(value) {
        try {
            const url = new URL(value);
            return url.protocol === 'https:' && url.hostname === 'meet.google.com' && /^\/[a-z]+-[a-z]+-[a-z]+\/?$/.test(url.pathname)
                ? 'https://meet.google.com' + url.pathname.replace(/\/$/, '')
                : '';
        } catch (error) {
            return '';
        }
    }

    function mount(window, document) {
        const dashboardRoot = document.getElementById('businessMeetRoom');
        const topbarRoot = document.getElementById('businessMeetTopbar');
        if (!dashboardRoot && !topbarRoot) return;

        const statusRoot = dashboardRoot || topbarRoot;
        const byId = id => document.getElementById(id);
        const dashboard = dashboardRoot ? {
            badge: byId('businessMeetBadge'),
            summary: byId('businessMeetSummary'),
            updated: byId('businessMeetUpdated'),
            people: byId('businessMeetPeople'),
            join: byId('businessMeetJoin'),
            refreshButton: byId('businessMeetRefresh')
        } : null;
        const topbar = topbarRoot ? {
            join: byId('businessMeetTopbarJoin'),
            avatars: byId('businessMeetTopbarAvatars'),
            count: byId('businessMeetTopbarCount')
        } : null;
        const pollMs = Math.max(10000, Number(statusRoot.dataset.pollMs) || 20000);
        let loading = false;
        let meetingUri = '';

        function setMeetingUri(value) {
            meetingUri = safeMeetingUri(value);
            const buttons = [dashboard && dashboard.join, topbar && topbar.join].filter(Boolean);
            buttons.forEach(button => {
                if (meetingUri) {
                    button.disabled = false;
                    button.classList.remove('disabled');
                    button.setAttribute('aria-disabled', 'false');
                } else {
                    button.disabled = true;
                    button.classList.add('disabled');
                    button.setAttribute('aria-disabled', 'true');
                }
            });
        }

        function renderDashboard(state) {
            if (!dashboard) return;
            const {badge, summary, updated, people} = dashboard;
            badge.textContent = state.badge;
            badge.className = 'badge rounded-pill ' + state.badgeClass;
            summary.textContent = state.summary;
            people.replaceChildren();
            state.people.forEach(name => {
                const item = document.createElement('span');
                item.className = 'business-meet-room-person';
                item.setAttribute('role', 'listitem');
                item.textContent = name;
                people.appendChild(item);
            });
            people.hidden = state.people.length === 0;
            updated.textContent = 'Atualizado às ' + new Intl.DateTimeFormat('pt-BR', {
                hour: '2-digit', minute: '2-digit', second: '2-digit'
            }).format(new Date());
        }

        function renderTopbar(state) {
            if (!topbar) return;
            ['is-active', 'is-empty', 'is-warning', 'is-error'].forEach(className => topbarRoot.classList.remove(className));
            const stateClass = state.badgeClass === 'badge-success' ? 'is-active'
                : state.badgeClass === 'badge-warning' ? 'is-warning'
                    : state.badgeClass === 'badge-danger' ? 'is-error' : 'is-empty';
            topbarRoot.classList.add(stateClass);

            topbar.avatars.replaceChildren();
            state.people.slice(0, 3).forEach(name => {
                const avatar = document.createElement('span');
                avatar.className = 'business-meet-topbar-avatar business-meet-topbar-avatar-tone-' + participantTone(name);
                avatar.textContent = participantInitials(name);
                avatar.title = name;
                topbar.avatars.appendChild(avatar);
            });
            if (state.people.length > 3) {
                const overflow = document.createElement('span');
                overflow.className = 'business-meet-topbar-avatar business-meet-topbar-avatar-overflow';
                overflow.textContent = '+' + (state.people.length - 3);
                topbar.avatars.appendChild(overflow);
            }
            topbar.avatars.hidden = state.people.length === 0;

            const active = state.badge === 'Sala ativa';
            topbar.count.textContent = active ? String(state.people.length) : '';
            topbar.count.hidden = !active;
            const names = state.people.length ? ' ' + state.people.join(', ') + '.' : '';
            topbar.join.title = state.summary + names;
            topbar.join.setAttribute('aria-label', state.summary + (meetingUri ? ' Abrir sala virtual.' : ''));
        }

        function render(payload) {
            const state = viewModel(payload);
            setMeetingUri(field(payload, 'meetingUri'));
            renderDashboard(state);
            renderTopbar(state);
        }

        function openMeetingWindow() {
            if (!meetingUri) return;
            const opened = window.open(meetingUri, 'runnerhub-team-room', 'popup=yes,width=1280,height=820,resizable=yes,scrollbars=yes');
            if (opened) return;
            const message = 'O navegador bloqueou a janela. Permita pop-ups para o Business e tente novamente.';
            if (dashboard) dashboard.summary.textContent = message;
            if (topbar) {
                topbar.join.title = message;
                topbar.join.setAttribute('aria-label', message);
            }
        }

        async function refresh() {
            if (loading || document.hidden) return;
            loading = true;
            if (dashboard) dashboard.refreshButton.disabled = true;
            try {
                const response = await window.fetch(statusRoot.dataset.statusUrl, {
                    method: 'GET', credentials: 'same-origin',
                    headers: {'Accept': 'application/json'}, cache: 'no-store'
                });
                let payload;
                try {
                    payload = await response.json();
                } catch (error) {
                    throw new Error('A sessão expirou ou o servidor não retornou uma resposta válida.');
                }
                if (!response.ok || field(payload, 'success') === false) {
                    setMeetingUri(field(payload, 'meetingUri') || meetingUri);
                    throw new Error(field(payload, 'message') || 'Não foi possível consultar o Google Meet.');
                }
                render(payload);
            } catch (error) {
                render({success: false, message: error.message, meetingUri});
            } finally {
                loading = false;
                if (dashboard) dashboard.refreshButton.disabled = false;
            }
        }

        if (dashboard) {
            dashboard.join.addEventListener('click', openMeetingWindow);
            dashboard.refreshButton.addEventListener('click', refresh);
        }
        if (topbar) topbar.join.addEventListener('click', openMeetingWindow);
        document.addEventListener('visibilitychange', function () {
            if (!document.hidden) refresh();
        });
        window.addEventListener('online', refresh);
        window.setInterval(refresh, pollMs);
        refresh();
    }

    return {field, participantInitials, participantLabel, participantTone, safeMeetingUri, viewModel, mount};
}));
