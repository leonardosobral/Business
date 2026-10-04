(function (window) {
    'use strict';
    var validStates = 'AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO'.split(' ');
    var filterKeys = ['distancia', 'tempo', 'rua', 'trail', 'nacional', 'internacional', 'cupom', 'badges'];
    var defaults = {distancia:'1,42', tempo:'0,12', rua:'true', trail:'true', nacional:'true', internacional:'false', cupom:'false', badges:''};

    function normalizeFilter(key, value) {
        if (value === null || value === undefined || value === '') value = defaults[key];
        value = String(value).trim();
        if (['rua','trail','nacional','internacional','cupom'].indexOf(key) >= 0) {
            return /^(true|yes|1)$/i.test(value) ? 'true' : 'false';
        }
        if (key === 'distancia' || key === 'tempo') {
            var parts = value.split(',').filter(function(part) { return part.trim() !== ''; });
            return Number(parts[0]) + ',' + Number(parts[parts.length - 1]);
        }
        return value;
    }

    function acceptsFilters(href, filters) {
        if (!filters) return false;
        var source = new URL(href);
        return filterKeys.every(function(key) { return normalizeFilter(key, source.searchParams.get(key)) === normalizeFilter(key, filters[key]); });
    }

    function buildUrl(href, uf, slug) {
        uf = String(uf || '').toUpperCase();
        slug = String(slug || '');
        if (validStates.indexOf(uf) < 0 || (slug && !/^[a-z0-9-]+$/.test(slug))) return '';
        var source = new URL(href);
        var target = new URL('/estado/' + uf.toLowerCase() + '/' + (slug ? slug + '/' : ''), source.origin);
        filterKeys.forEach(function (key) {
            var value = source.searchParams.get(key);
            if (value !== null && value !== '') target.searchParams.set(key, value);
        });
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
        var sidebar = document.querySelector('[data-estado-city-sidebar]');

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

        window.RunnerHubEstadoCities.update = function (data) {
            if (!data || String(data.uf).toLowerCase() !== String(uf).toLowerCase() || !Array.isArray(data.cities) || !acceptsFilters(window.location.href, data.filters)) return;
            var counts = {};
            data.cities.forEach(function (city) { counts[city.slug] = city; });
            items.forEach(function (item) {
                var slug = item.dataset.estadoCitySlug;
                var total = slug ? (counts[slug] ? counts[slug].total : 0) : data.total;
                var enabled = total > 0 || slug === '' || slug === selected;
                item.querySelector('[data-city-count]').textContent = total + (total === 1 ? ' prova' : ' provas');
                item.setAttribute('aria-disabled', enabled ? 'false' : 'true');
                if (enabled) { item.href = buildUrl(window.location.href, uf, slug); item.removeAttribute('tabindex'); }
                else { item.removeAttribute('href'); item.setAttribute('tabindex', '-1'); }
            });
            if (sidebar) {
                sidebar.textContent = '';
                data.cities.filter(function (city) { return city.total > 0; }).sort(function (a,b) { return b.total - a.total || a.name.localeCompare(b.name, 'pt-BR'); }).slice(0,10).forEach(function (city) {
                    var link = document.createElement('a');
                    link.className = 'estado-city-list-item';
                    link.dataset.estadoCitySlug = city.slug;
                    link.href = buildUrl(window.location.href, uf, city.slug);
                    var name = document.createElement('span'); name.className = 'estado-city-list-name'; name.textContent = city.name;
                    var count = document.createElement('span'); count.className = 'estado-city-list-count'; count.textContent = city.total + (city.total === 1 ? ' prova' : ' provas');
                    link.append(name,count); sidebar.appendChild(link);
                });
                sidebar.parentElement.hidden = !sidebar.children.length;
            }
            search();
        };
        syncLinks();
    }
    window.RunnerHubEstadoCities = {buildUrl:buildUrl, matches:matches, acceptsFilters:acceptsFilters, init:init};
})(window);
