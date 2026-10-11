(function (window) {
    'use strict';
    var validStates = 'AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO'.split(' ');
    var filterKeys = ['filtro', 'ano', 'distancia', 'tempo', 'rua', 'trail', 'nacional', 'internacional', 'cupom', 'badges'];

    function buildUrl(href, uf, slug) {
        uf = String(uf || '').toUpperCase();
        slug = String(slug || '').toLowerCase();
        if (validStates.indexOf(uf) < 0 || (slug && !/^[a-z0-9-]+$/.test(slug))) return '';
        var source = new URL(href);
        var target = new URL('/estado/' + uf.toLowerCase() + '/', source.origin);
        filterKeys.forEach(function (key) {
            var value = source.searchParams.get(key);
            if (value !== null && value !== '') target.searchParams.set(key, value);
        });
        if (slug) target.searchParams.set('cidade', slug);
        return target.pathname + target.search;
    }
    function buildTabUrl(href, mode, selected) {
        var source = new URL(href);
        var state = source.pathname.split('/')[2];
        var slug = selected === undefined ? source.searchParams.get('cidade') : selected;
        var targetPath = buildUrl(href,state,slug);
        if (!targetPath || ['','maiores','maratonas'].indexOf(mode) < 0) return '';
        var target = new URL(targetPath,source.origin);
        if (mode) target.searchParams.set('filtro',mode);
        else target.searchParams.delete('filtro');
        return target.pathname + target.search;
    }
    function buildApiUrl(href, uf, page, monthKey, selected) {
        var source = new URL(href);
        var slug = selected === undefined ? source.searchParams.get('cidade') : selected;
        var targetPath = buildUrl(href,uf,slug);
        if (!targetPath) return '';
        var target = new URL(targetPath,source.origin);
        target.pathname = '/api/eventos_por_estado.cfm';
        target.searchParams.set('tag',String(uf).toUpperCase());
        target.searchParams.set('page',String(page));
        target.searchParams.set('lastMonthKey',String(monthKey || ''));
        return target.pathname + target.search;
    }

    function normalize(value) {
        return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim().replace(/\s+/g, ' ');
    }

    function matches(name, term) { return normalize(name).indexOf(normalize(term)) >= 0; }

    function init(document, uf, selected) {
        var picker = document.querySelector('[data-estado-city-picker]');
        if (!picker) return;
        var input = picker.querySelector('input');
        var summary = picker.querySelector('summary');
        var items = picker.querySelectorAll('[data-estado-city-slug]');
        var status = picker.querySelector('[data-estado-city-status]');

        function search() {
            var visible = 0;
            items.forEach(function (item) {
                var found = matches(item.dataset.estadoCityName, input.value);
                item.hidden = !found;
                if (found) visible++;
            });
            status.textContent = visible ? '' : 'Nenhuma cidade encontrada.';
        }

        function syncLinks() {
            document.querySelectorAll('[data-estado-city-slug]').forEach(function (item) {
                if (item.getAttribute('aria-disabled') !== 'true') item.href = buildUrl(window.location.href, uf, item.dataset.estadoCitySlug);
            });
        }

        picker.addEventListener('toggle', function () {
            if (picker.open) { syncLinks(); input.focus(); }
            else { input.value = ''; search(); }
        });
        input.addEventListener('input', search);
        picker.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') { picker.open = false; summary.focus(); }
        });
        document.addEventListener('click', function (event) {
            if (!picker.contains(event.target)) picker.open = false;
            var link = event.target.closest('[data-estado-city-slug]');
            if (link && link.getAttribute('aria-disabled') !== 'true') link.href = buildUrl(window.location.href, uf, link.dataset.estadoCitySlug);
        });
        var stateSelect = document.querySelector('[data-estado-state-select]');
        if (stateSelect) stateSelect.addEventListener('change', function () {
            var target = buildUrl(window.location.href, stateSelect.value, '');
            if (target) window.location.assign(target);
        });

        document.querySelectorAll('[data-estado-tab]').forEach(function (link) {
            var target = buildTabUrl(window.location.href,link.dataset.estadoTab,selected);
            if (target) link.href = target;
        });
        syncLinks();
    }
    window.OpenResultsEstadoCities = {buildUrl:buildUrl, buildTabUrl:buildTabUrl, buildApiUrl:buildApiUrl, matches:matches, init:init};
})(window);
