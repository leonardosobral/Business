(function (window, document) {
    'use strict';

    function noop() {}

    function toOptionalNumber(value) {
        if (value === null || value === undefined || value === '') {
            return null;
        }

        var parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    }

    function normalizeRangePair(minValue, maxValue, fallbackMin, fallbackMax) {
        var parsedMin = toOptionalNumber(minValue);
        var parsedMax = toOptionalNumber(maxValue);
        var normalizedMin = parsedMin === null ? fallbackMin : parsedMin;
        var normalizedMax = parsedMax === null ? fallbackMax : parsedMax;
        var lowerBound = Math.min(normalizedMin, normalizedMax);
        var upperBound = Math.max(normalizedMin, normalizedMax);

        return [Math.round(lowerBound), Math.round(upperBound)];
    }

    function monthsUntil(dateValue) {
        if (!dateValue) {
            return null;
        }

        var targetDate = new Date(dateValue + 'T00:00:00');

        if (Number.isNaN(targetDate.getTime())) {
            return null;
        }

        var today = new Date();
        var baseDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        var diffMonths = (targetDate.getFullYear() - baseDate.getFullYear()) * 12;
        diffMonths += targetDate.getMonth() - baseDate.getMonth();

        if (targetDate.getDate() > baseDate.getDate()) {
            diffMonths += 1;
        }

        return Math.max(0, diffMonths);
    }

    function formatDateForUrl(dateValue) {
        var yearValue = dateValue.getFullYear();
        var monthValue = String(dateValue.getMonth() + 1).padStart(2, '0');
        var dayValue = String(dateValue.getDate()).padStart(2, '0');
        return yearValue + '-' + monthValue + '-' + dayValue;
    }

    function buildPeriodFromMonthsRange(monthRange) {
        var today = new Date();
        var normalizedStart = Number(monthRange[0] || 0);
        var normalizedEnd = Number(monthRange[1] || 12);
        var startDate = new Date(today.getFullYear(), today.getMonth() + normalizedStart, today.getDate());
        var endDate = new Date(today.getFullYear(), today.getMonth() + normalizedEnd, today.getDate());

        return {
            inicio: formatDateForUrl(startDate),
            fim: formatDateForUrl(endDate)
        };
    }

    function buildTempoRangeFromFilters(filters) {
        var defaultTempo = [0, 12];
        var startMonth = monthsUntil(filters.periodo_inicio);
        var endMonth = monthsUntil(filters.periodo_fim);

        if (startMonth === null && endMonth === null) {
            return defaultTempo;
        }

        var minMonth = startMonth === null ? 0 : startMonth;
        var maxMonth = endMonth === null ? 12 : endMonth;
        return normalizeRangePair(minMonth, Math.min(12, maxMonth), 0, 12);
    }

    function replaceMultiRangeSlider(element, instance, values) {
        if (!element || !instance) {
            return instance;
        }

        instance.dispose();
        element.innerHTML = '';

        return new window.mdb.MultiRangeSlider(element, {
            startValues: values
        });
    }

    function init(config) {
        // CENTRALIZA O ESTADO DOS FILTROS USADO PELA PAGINA DE BUSCA

        var options = {
            eventosEndpoint: config.eventosEndpoint || '/api/eventos_busca.cfm',
            useLegacyRangeParams: Boolean(config.useLegacyRangeParams),
            extraParams: config.extraParams || {}
        };
        var callbacks = {
            setResultsLoading: noop,
            updateEventQueryDebug: noop
        };

        var state = {
            distanciaSelecionada: config.distanciaSelecionada || [1, 42],
            periodoMesesSelecionado: config.periodoMesesSelecionado || [0, 12],
            badges: config.badges || '',
            rua: Boolean(config.rua),
            trail: Boolean(config.trail),
            nacional: Boolean(config.nacional),
            internacional: Boolean(config.internacional),
            tag: config.tag || '',
            cupom: Boolean(config.cupom),
            buscaTermo: config.buscaTermo || '',
            buscaApiTermo: config.buscaApiTermo || '',
            buscaDistanciaInicio: config.buscaDistanciaInicio,
            buscaDistanciaFim: config.buscaDistanciaFim,
            buscaDistanciaAtiva: Boolean(config.buscaDistanciaAtiva),
            buscaEstado: config.buscaEstado || '',
            buscaCidade: config.buscaCidade || '',
            buscaEstados: config.buscaEstados || '',
            buscaPeriodoInicio: config.buscaPeriodoInicio || '',
            buscaPeriodoFim: config.buscaPeriodoFim || '',
            buscaModo: config.buscaModo || 'ai',
            buscaTipoTermo: config.buscaTipoTermo || 'indefinido',
            pagesize: Number(config.pagesize || 50),
            page: 0,
            lastWeek: config.lastWeek || '',
            lastMonth: config.lastMonth || '',
            loading: false,
            totalEventos: Number(config.totalEventos || 0),
            suppressSliderFetch: false,
            updateDataTimer: 0
        };

        var refs = {
            rangeDistancia: document.querySelector(config.selectors.rangeDistancia),
            rangeTempo: document.querySelector(config.selectors.rangeTempo),
            filtroFull: document.querySelector(config.selectors.filtroFull),
            spinner: document.querySelector(config.selectors.spinner),
            scrollContainer: document.querySelector(config.selectors.scrollContainer),
            stateFilterSelect: document.querySelector(config.selectors.stateFilterSelect),
            stateFilterChips: document.querySelectorAll(config.selectors.stateFilterChips)
        };

        var rangeDistanciaInit = null;
        var rangeTempoInit = null;

        // ATUALIZA UM PARAMETRO NA URL SEM RECARREGAR A PAGINA

        function updateUrl(param, value) {
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, param, value));
        }

        function appendUrlParam(url, key, value) {
            if (value === null || value === undefined || value === '') {
                return url;
            }

            return url + '&' + encodeURIComponent(key) + '=' + encodeURIComponent(value);
        }

        // APLICA O ESTADO VISUAL DOS BADGES SELECIONADOS

        function processaBadge(value) {
            var badgeNodes = document.querySelectorAll('.badges');
            badgeNodes.forEach(function (node) {
                node.classList.add('opacity-50');
            });

            if (state.badges === value) {
                return '';
            }

            var target = document.getElementById('badge_' + value);
            var targetAlt = document.getElementById('badgeav_' + value);

            if (target) {
                target.classList.remove('opacity-50');
            }

            if (targetAlt) {
                targetAlt.classList.remove('opacity-50');
            }

            return value;
        }

        // SINCRONIZA SELECT E CHIPS DE UF COM O ESTADO INTERPRETADO

        function syncStateFilterVisuals(activeState) {
            var normalizedState = (activeState || '').toUpperCase();

            if (refs.stateFilterSelect) {
                refs.stateFilterSelect.value = normalizedState;
            }

            refs.stateFilterChips.forEach(function (chip) {
                chip.classList.toggle('is-active', normalizedState.length && chip.dataset.stateChip === normalizedState);
            });
        }

        // CONVERTE O SLIDER DE MESES EM DATAS ABSOLUTAS PARA O BACKEND

        function applyPeriodoMesesToUrl(monthRange) {
            var periodRange = buildPeriodFromMonthsRange(monthRange);
            state.buscaPeriodoInicio = periodRange.inicio;
            state.buscaPeriodoFim = periodRange.fim;

            if (options.useLegacyRangeParams) {
                updateUrl('tempo', String(monthRange[0]) + ',' + String(monthRange[1]));
                updateUrl('periodo_inicio', '');
                updateUrl('periodo_fim', '');
                return;
            }

            updateUrl('periodo_inicio', state.buscaPeriodoInicio);
            updateUrl('periodo_fim', state.buscaPeriodoFim);
        }

        // RECRIA OS SLIDERS QUANDO A IA DEVOLVE NOVOS FILTROS

        function syncSliderVisuals() {
            if (!refs.rangeDistancia || !refs.rangeTempo || !rangeDistanciaInit || !rangeTempoInit) {
                return;
            }

            if (!refs.rangeDistancia.offsetWidth || !refs.rangeTempo.offsetWidth) {
                return;
            }

            state.suppressSliderFetch = true;
            rangeDistanciaInit = replaceMultiRangeSlider(refs.rangeDistancia, rangeDistanciaInit, state.distanciaSelecionada);
            rangeTempoInit = replaceMultiRangeSlider(refs.rangeTempo, rangeTempoInit, state.periodoMesesSelecionado);
            window.setTimeout(function () {
                state.suppressSliderFetch = false;
            }, 0);
        }

        // MONTA A URL DO ENDPOINT DE EVENTOS COM TODOS OS FILTROS ATUAIS

        function buildEventosBuscaUrl(targetPage) {
            var periodoInicioRequest = state.buscaPeriodoInicio;
            var periodoFimRequest = state.buscaPeriodoFim;
            var key = '';
            var url = options.eventosEndpoint + '?page=' + targetPage +
                '&badges=' + encodeURIComponent(state.badges) +
                '&rua=' + encodeURIComponent(state.rua) +
                '&trail=' + encodeURIComponent(state.trail) +
                '&nacional=' + encodeURIComponent(state.nacional) +
                '&internacional=' + encodeURIComponent(state.internacional) +
                '&tag=' + encodeURIComponent(state.tag) +
                '&cupom=' + encodeURIComponent(state.cupom) +
                '&busca_mode=' + encodeURIComponent(state.buscaModo);

            if (options.useLegacyRangeParams) {
                if (state.buscaDistanciaAtiva && toOptionalNumber(state.buscaDistanciaInicio) !== null && toOptionalNumber(state.buscaDistanciaFim) !== null) {
                    url += '&distancia=' + encodeURIComponent(String(state.buscaDistanciaInicio) + ',' + String(state.buscaDistanciaFim));
                }
            } else {
                if (state.buscaDistanciaAtiva && toOptionalNumber(state.buscaDistanciaInicio) !== null) {
                    url += '&distancia_inicio=' + encodeURIComponent(state.buscaDistanciaInicio);
                }

                if (state.buscaDistanciaAtiva && toOptionalNumber(state.buscaDistanciaFim) !== null) {
                    url += '&distancia_fim=' + encodeURIComponent(state.buscaDistanciaFim);
                }
            }

            if (state.buscaApiTermo.length) {
                url += '&busca=' + encodeURIComponent(state.buscaApiTermo);
            }

            if (state.buscaModo === 'ai' && state.buscaTermo.length) {
                url += '&busca_original=' + encodeURIComponent(state.buscaTermo);
            }

            if (state.buscaEstado.length) {
                url += '&estado=' + encodeURIComponent(state.buscaEstado);
            }

            if (state.buscaCidade.length) {
                url += '&cidade=' + encodeURIComponent(state.buscaCidade);
            }

            if (state.buscaEstados.length) {
                url += '&estados=' + encodeURIComponent(state.buscaEstados);
            }

            if (!periodoInicioRequest.length && !periodoFimRequest.length && (state.periodoMesesSelecionado[0] > 0 || state.periodoMesesSelecionado[1] < 12)) {
                var periodRange = buildPeriodFromMonthsRange(state.periodoMesesSelecionado);
                periodoInicioRequest = periodRange.inicio;
                periodoFimRequest = periodRange.fim;
            }

            if (options.useLegacyRangeParams) {
                if (state.periodoMesesSelecionado[0] > 0 || state.periodoMesesSelecionado[1] < 12) {
                    url += '&tempo=' + encodeURIComponent(String(state.periodoMesesSelecionado[0]) + ',' + String(state.periodoMesesSelecionado[1]));
                }
            } else {
                if (periodoInicioRequest.length) {
                    url += '&periodo_inicio=' + encodeURIComponent(periodoInicioRequest);
                }

                if (periodoFimRequest.length) {
                    url += '&periodo_fim=' + encodeURIComponent(periodoFimRequest);
                }
            }

            for (key in options.extraParams) {
                if (Object.prototype.hasOwnProperty.call(options.extraParams, key)) {
                    url = appendUrlParam(url, key, options.extraParams[key]);
                }
            }

            return url;
        }

        // REINICIA PAGINACAO QUANDO UMA BUSCA NOVA SUBSTITUI A LISTA

        function resetInfiniteScrollState() {
            state.page = 0;
            state.lastWeek = '';
            state.lastMonth = '';
        }

        // LÊ DO HTML RETORNADO O SQL DE DEBUG GERADO PELO BACKEND

        function updateEventSearchDebugFromWindow() {
            if (window.__buscaEventDebug) {
                callbacks.updateEventQueryDebug(window.__buscaEventDebug);
                window.__buscaEventDebug = null;
            }
        }

        // MANTEM PAGINACAO LOCAL ALINHADA COM O ULTIMO HTML CARREGADO

        function syncPagingStateFromWindow() {
            if (typeof window.totalEventos !== 'undefined' && Number.isFinite(Number(window.totalEventos))) {
                state.totalEventos = Number(window.totalEventos);
            }

            if (typeof window.lastMonth !== 'undefined') {
                state.lastMonth = window.lastMonth || '';
            }

            if (typeof window.lastWeek !== 'undefined') {
                state.lastWeek = window.lastWeek || '';
            }
        }

        // TROCA O HTML DA LISTA DE EVENTOS E REATIVA SCRIPTS DOS CARDS

        function audienceRequestOptions(url) {
            var headers = {};
            var audience = window.RoadRunnersAudienceConfig;
            if (window.RoadRunnersAudience && audience) {
                try {
                    var target = new window.URL(url, window.location.href);
                    if (target.origin === window.location.origin && target.pathname === '/api/eventos_busca.cfm') {
                        headers['X-RR-Audience-Context'] = audience.contextToken;
                        headers['X-RR-Audience-Signature'] = audience.signature;
                    }
                } catch (ignoredAudienceUrl) {}
            }
            return { headers: headers };
        }

        function prepareAudienceHtml(html) {
            if (!window.RoadRunnersAudience || typeof window.RoadRunnersAudience.adoptContext !== 'function') {
                return html;
            }
            // Bind only the incoming nodes, so pagination preserves prior regions.
            var holder = document.createElement('div');
            holder.innerHTML = html;
            window.RoadRunnersAudience.adoptContext(holder);
            return holder.innerHTML;
        }

        function renderFetchedHtml(html, resetState) {
            if (resetState) {
                resetInfiniteScrollState();
            }

            refs.scrollContainer.innerHTML = prepareAudienceHtml(html);
            var scripts = refs.scrollContainer.getElementsByTagName('script');

            for (var index = 0; index < scripts.length; index += 1) {
                window.eval(scripts[index].innerHTML);
            }

            syncPagingStateFromWindow();
            updateEventSearchDebugFromWindow();
            window.colorirDistancias();
        }

        // RECARREGA A LISTA PRINCIPAL DE EVENTOS

        function callAPI() {
            callbacks.setResultsLoading(true, state.buscaModo === 'plain');

            var requestUrl = buildEventosBuscaUrl(0);
            return window.fetch(requestUrl, audienceRequestOptions(requestUrl))
                .then(function (response) {
                    return response.text();
                })
                .then(function (html) {
                    callbacks.setResultsLoading(false);
                    renderFetchedHtml(html, true);
                })
                .catch(function (err) {
                    callbacks.setResultsLoading(false);
                    window.console.warn('Something went wrong.', err);
                });
        }

        // CARREGA A PROXIMA PAGINA NO SCROLL INFINITO

        function loadImages() {
            if (!state.totalEventos || state.totalEventos <= ((state.page + 1) * state.pagesize)) {
                return;
            }

            if (refs.spinner) {
                refs.spinner.style.display = 'block';
            }

            if (state.loading) {
                return;
            }

            state.page += 1;
            state.loading = true;

            var requestUrl = buildEventosBuscaUrl(state.page) + '&lastWeek=' + encodeURIComponent(state.lastWeek) + '&lastMonth=' + encodeURIComponent(state.lastMonth);
            window.fetch(requestUrl, audienceRequestOptions(requestUrl))
                .then(function (response) {
                    return response.text();
                })
                .then(function (html) {
                    state.loading = false;

                    if (refs.spinner) {
                        refs.spinner.style.display = 'none';
                    }

                    refs.scrollContainer.insertAdjacentHTML('beforeend', prepareAudienceHtml(html));

                    var scripts = refs.scrollContainer.getElementsByTagName('script');
                    for (var index = 0; index < scripts.length; index += 1) {
                        window.eval(scripts[index].innerHTML);
                    }

                    syncPagingStateFromWindow();
                    updateEventSearchDebugFromWindow();
                    window.colorirDistancias();
                })
                .catch(function (err) {
                    state.loading = false;
                    window.console.warn('Something went wrong.', err);
                });
        }

        // RECEBE FILTROS DA IA E ATUALIZA ESTADO, SLIDERS E URL

        function syncBuscaFilters(filters) {
            state.distanciaSelecionada = normalizeRangePair(filters.distancia_inicio, filters.distancia_fim, 1, 42);
            state.periodoMesesSelecionado = buildTempoRangeFromFilters(filters);
            // O RANGE VISUAL NAO DEVE FECHAR LIMITES ABERTOS DA CONSULTA.
            state.buscaDistanciaInicio = toOptionalNumber(filters.distancia_inicio);
            state.buscaDistanciaFim = toOptionalNumber(filters.distancia_fim);
            state.buscaDistanciaAtiva = state.buscaDistanciaInicio !== null || state.buscaDistanciaFim !== null;
            state.buscaApiTermo = filters.termo_livre || '';
            state.buscaEstado = filters.estado || '';
            state.buscaCidade = filters.cidade || '';
            state.buscaEstados = Array.isArray(filters.estados) ? filters.estados.join(',') : '';
            state.buscaPeriodoInicio = filters.periodo_inicio || '';
            state.buscaPeriodoFim = filters.periodo_fim || '';
            state.buscaTipoTermo = filters.tipo_termo || 'indefinido';

            syncSliderVisuals();
            syncStateFilterVisuals(state.buscaEstado);

            if (options.useLegacyRangeParams) {
                updateUrl('distancia', state.buscaDistanciaAtiva && state.buscaDistanciaInicio !== null && state.buscaDistanciaFim !== null
                    ? String(state.buscaDistanciaInicio) + ',' + String(state.buscaDistanciaFim) : '');
                updateUrl('tempo', (state.periodoMesesSelecionado[0] > 0 || state.periodoMesesSelecionado[1] < 12) ? String(state.periodoMesesSelecionado[0]) + ',' + String(state.periodoMesesSelecionado[1]) : '');
            } else {
                updateUrl('distancia_inicio', state.buscaDistanciaAtiva && state.buscaDistanciaInicio !== null ? state.buscaDistanciaInicio : '');
                updateUrl('distancia_fim', state.buscaDistanciaAtiva && state.buscaDistanciaFim !== null ? state.buscaDistanciaFim : '');
                updateUrl('distancia', '');
                updateUrl('tempo', '');
                updateUrl('estado', filters.estado || '');
                updateUrl('cidade', filters.cidade || '');
                updateUrl('estados', Array.isArray(filters.estados) ? filters.estados.join(',') : '');
                updateUrl('periodo_inicio', filters.periodo_inicio || '');
                updateUrl('periodo_fim', filters.periodo_fim || '');
            }
        }

        function initSliders() {
            if (!refs.rangeDistancia || !refs.rangeTempo || !window.mdb || !window.mdb.MultiRangeSlider) {
                return;
            }

            rangeDistanciaInit = new window.mdb.MultiRangeSlider(refs.rangeDistancia, {
                startValues: state.distanciaSelecionada
            });
            rangeTempoInit = new window.mdb.MultiRangeSlider(refs.rangeTempo, {
                startValues: state.periodoMesesSelecionado
            });

            refs.rangeDistancia.addEventListener('valueChanged.mdb.multiRangeSlider', function (event) {
                if (state.suppressSliderFetch) {
                    return;
                }

                window.clearTimeout(state.updateDataTimer);
                state.updateDataTimer = window.setTimeout(function () {
                    state.distanciaSelecionada = event.values.rounded;
                    state.buscaDistanciaInicio = state.distanciaSelecionada[0];
                    state.buscaDistanciaFim = state.distanciaSelecionada[1];
                    state.buscaDistanciaAtiva = !(state.buscaDistanciaInicio === 1 && state.buscaDistanciaFim === 42);
                    if (options.useLegacyRangeParams) {
                        updateUrl('distancia', state.buscaDistanciaAtiva ? String(state.buscaDistanciaInicio) + ',' + String(state.buscaDistanciaFim) : '');
                    } else {
                        updateUrl('distancia_inicio', state.buscaDistanciaAtiva ? state.buscaDistanciaInicio : '');
                        updateUrl('distancia_fim', state.buscaDistanciaAtiva ? state.buscaDistanciaFim : '');
                        updateUrl('distancia', '');
                    }
                    callAPI();
                }, 300);
            });

            refs.rangeTempo.addEventListener('valueChanged.mdb.multiRangeSlider', function (event) {
                if (state.suppressSliderFetch) {
                    return;
                }

                window.clearTimeout(state.updateDataTimer);
                state.updateDataTimer = window.setTimeout(function () {
                    state.periodoMesesSelecionado = event.values.rounded;
                    applyPeriodoMesesToUrl(state.periodoMesesSelecionado);
                    if (!options.useLegacyRangeParams) {
                        updateUrl('tempo', '');
                    }
                    callAPI();
                }, 300);
            });

            if (refs.filtroFull) {
                refs.filtroFull.addEventListener('shown.bs.collapse', function () {
                    syncSliderVisuals();
                });
            }
        }

        function initInfiniteScroll() {
            if (!window.mdb || !window.mdb.InfiniteScroll) {
                return;
            }

            window.addEventListener('completed.mdb.infiniteScroll', loadImages);
            new window.mdb.InfiniteScroll(window);
        }

        function setBadge(value) {
            state.badges = processaBadge(value);
            updateUrl('badges', value);
            callAPI();
        }

        function setCupom(value) {
            state.cupom = value;
            updateUrl('cupom', value);
            callAPI();
        }

        function setRua(value) {
            state.rua = value;
            updateUrl('rua', value);
            callAPI();
        }

        function setTrail(value) {
            state.trail = value;
            updateUrl('trail', value);
            callAPI();
        }

        function setNacional(value) {
            state.nacional = value;
            updateUrl('nacional', value);
            callAPI();
        }

        function setInternacional(value) {
            var escopoNode = document.getElementById('escopo');
            state.internacional = value;
            updateUrl('internacional', value);
            callAPI();

            if (escopoNode) {
                escopoNode.textContent = value ? 'do Mundo' : 'do Brasil';
            }
        }

        function setBuscaContext(nextContext) {
            state.buscaTermo = nextContext.buscaTermo !== undefined ? nextContext.buscaTermo : state.buscaTermo;
            state.buscaApiTermo = nextContext.buscaApiTermo !== undefined ? nextContext.buscaApiTermo : state.buscaApiTermo;
            state.buscaModo = nextContext.buscaModo !== undefined ? nextContext.buscaModo : state.buscaModo;
        }

        function clearResults() {
            if (refs.scrollContainer) {
                refs.scrollContainer.innerHTML = '';
            }
        }

        function setCallbacks(nextCallbacks) {
            callbacks = {
                setResultsLoading: nextCallbacks.setResultsLoading || callbacks.setResultsLoading || noop,
                updateEventQueryDebug: nextCallbacks.updateEventQueryDebug || callbacks.updateEventQueryDebug || noop
            };
        }

        window.setBadge = setBadge;
        window.setCupom = setCupom;
        window.setRua = setRua;
        window.setTrail = setTrail;
        window.setNacional = setNacional;
        window.setInternacional = setInternacional;

        initSliders();
        initInfiniteScroll();
        syncStateFilterVisuals(state.buscaEstado);

        return {
            callAPI: callAPI,
            clearResults: clearResults,
            getState: function () { return state; },
            setCallbacks: setCallbacks,
            setBuscaContext: setBuscaContext,
            setBuscaMode: function (mode) { state.buscaModo = mode === 'plain' ? 'plain' : 'ai'; },
            syncBuscaFilters: syncBuscaFilters,
            syncPagingStateFromWindow: syncPagingStateFromWindow,
            syncStateFilterVisuals: syncStateFilterVisuals,
            updateEventQueryDebug: updateEventSearchDebugFromWindow
        };
    }

    window.RunnerHubEventFilters = {
        init: init
    };
})(window, document);
