(function (window, document) {
    'use strict';

    function init(config) {
        // MAPEIA ELEMENTOS DA UI E ESTADO COMPARTILHADO DA BUSCA

        var shouldInterceptSubmit = config.interceptSubmit !== false;
        var i18n = config.i18n || {};
        var languageCode = config.language || 'pt-BR';
        var filtersController = config.filtersController;
        var searchEndpoint = config.searchEndpoint || '/api/search.cfm';
        var buscaForm = document.querySelector(config.selectors.form);
        var buscaHiddenInput = buscaForm ? buscaForm.querySelector('input[name="busca"]') : null;
        var buscaModeHiddenInput = buscaForm ? buscaForm.querySelector('input[name="busca_mode"]') : null;
        var buscaTipoHiddenInput = buscaForm ? buscaForm.querySelector('input[name="busca_tipo"]') : null;
        var isSingleBuscaField = buscaForm ? buscaForm.dataset.buscaSingleField === 'true' : false;
        var buscaPlainInput = document.getElementById(config.selectors.buscaPlainInputId);
        var buscaAiInput = document.getElementById(config.selectors.buscaAiInputId);
        var buscaPlainWrapper = document.getElementById(config.selectors.buscaPlainWrapperId);
        var buscaAiWrapper = document.getElementById(config.selectors.buscaAiWrapperId);
        var buscaModeButtons = document.querySelectorAll(config.selectors.buscaModeButtons);
        var buscaDebugCard = document.getElementById(config.selectors.buscaDebugCardId);
        var buscaDebugDetails = document.getElementById(config.selectors.buscaDebugDetailsId);
        var buscaFeedbackMessage = document.getElementById(config.selectors.buscaFeedbackMessageId);
        var buscaHeroCopy = document.getElementById(config.selectors.buscaHeroCopyId);
        var buscaDebugJson = document.getElementById(config.selectors.buscaDebugJsonId);
        var buscaDebugModelo = document.getElementById(config.selectors.buscaDebugModeloId);
        var buscaDebugStatus = document.getElementById(config.selectors.buscaDebugStatusId);
        var buscaDebugIgnored = document.getElementById(config.selectors.buscaDebugIgnoredId);
        var buscaDebugError = document.getElementById(config.selectors.buscaDebugErrorId);
        var buscaDebugHttpStatus = document.getElementById(config.selectors.buscaDebugHttpStatusId);
        var buscaDebugEndpoint = document.getElementById(config.selectors.buscaDebugEndpointId);
        var buscaDebugEventQuery = document.getElementById(config.selectors.buscaDebugEventQueryId);
        var buscaDebugEventParams = document.getElementById(config.selectors.buscaDebugEventParamsId);
        var buscaDebugRaw = document.getElementById(config.selectors.buscaDebugRawId);
        var buscaAiLoadingCard = document.getElementById(config.selectors.buscaAiLoadingCardId);
        var buscaAiLoadingTitle = document.getElementById(config.selectors.buscaAiLoadingTitleId);
        var buscaAiLoadingCopy = document.getElementById(config.selectors.buscaAiLoadingCopyId);
        var buscaResultsLoadingCard = document.getElementById(config.selectors.buscaResultsLoadingCardId);
        var buscaResultsLoadingTitle = document.getElementById(config.selectors.buscaResultsLoadingTitleId);
        var buscaResultsLoadingCopy = document.getElementById(config.selectors.buscaResultsLoadingCopyId);
        var buscaResultsSkeleton = document.getElementById(config.selectors.buscaResultsSkeletonId);
        var buscaAiLoadingInterval = 0;
        var buscaResultsLoadingInterval = 0;
        var aggregateSearchRequestId = 0;
        var loadedSearchTypes = {};
        var aiFilterBaseline = null;
        var aiAppliedFilters = null;
        var buscaLogId = '';
        var state = filtersController.getState();

        if (buscaModeHiddenInput && buscaModeHiddenInput.value) {
            state.buscaModo = buscaModeHiddenInput.value === 'ai' ? 'ai' : 'plain';
        }

        // LINKS LEGADOS AINDA PODEM ENTREGAR APENAS O RANGE DO SLIDER.
        if (!state.buscaDistanciaAtiva && state.distanciaSelecionada &&
            (Number(state.distanciaSelecionada[0]) !== 1 || Number(state.distanciaSelecionada[1]) !== 42)) {
            state.buscaDistanciaAtiva = true;
            state.buscaDistanciaInicio = state.distanciaSelecionada[0];
            state.buscaDistanciaFim = state.distanciaSelecionada[1];
        }

        // LE TEXTOS LOCALIZADOS COM FALLBACK PARA EVITAR QUEBRAR A UI

        function readI18n(path, fallback) {
            var parts = path.split('.');
            var current = i18n;
            var index;

            for (index = 0; index < parts.length; index += 1) {
                if (!current || typeof current !== 'object' || !(parts[index] in current)) {
                    return fallback;
                }

                current = current[parts[index]];
            }

            return current === undefined || current === null ? fallback : current;
        }

        function interpolate(text, replacements) {
            var result = String(text || '');

            Object.keys(replacements || {}).forEach(function (key) {
                result = result.replace(new RegExp('\\{' + key + '\\}', 'g'), replacements[key]);
            });

            return result;
        }

        function getFallbackReasonLabel(reason) {
            return readI18n('debug.fallbackReasons.' + reason, readI18n('debug.fallbackReasons.unknown', reason || ''));
        }

        function getActiveBuscaInput() {
            if (isSingleBuscaField) {
                return buscaPlainInput || buscaAiInput;
            }
            return state.buscaModo === 'plain' ? buscaPlainInput : buscaAiInput;
        }

        // ANIMA OS CARDS DE CARREGAMENTO DA IA E DOS RESULTADOS

        function startLoadingAnimation(titleElement, copyElement, titleBase, steps) {
            var stepIndex = 0;

            if (titleElement) {
                titleElement.textContent = titleBase + '.';
            }

            if (copyElement && steps.length) {
                copyElement.textContent = steps[0];
            }

            return window.setInterval(function () {
                stepIndex += 1;

                if (titleElement) {
                    titleElement.textContent = titleBase + '.'.repeat((stepIndex % 3) + 1);
                }

                if (copyElement && steps.length) {
                    copyElement.textContent = steps[stepIndex % steps.length];
                }
            }, 1800);
        }

        // MOSTRA APENAS A ETAPA DE INTERPRETACAO DA IA

        function setAiLoading(isLoading) {
            if (!buscaAiLoadingCard) {
                return;
            }

            if (buscaAiLoadingInterval) {
                window.clearInterval(buscaAiLoadingInterval);
                buscaAiLoadingInterval = 0;
            }

            buscaAiLoadingCard.style.display = isLoading ? '' : 'none';

            if (isLoading) {
                buscaAiLoadingInterval = startLoadingAnimation(
                    buscaAiLoadingTitle,
                    buscaAiLoadingCopy,
                    readI18n('loading.aiTitle', 'Pensando'),
                    readI18n('loading.aiSteps', [])
                );
            }
        }

        // MOSTRA A ETAPA DE BUSCA NOS ENDPOINTS DE RESULTADOS

        function setResultsLoading(isLoading, isPlainMode) {
            if (!buscaResultsLoadingCard) {
                return;
            }

            if (buscaResultsLoadingInterval) {
                window.clearInterval(buscaResultsLoadingInterval);
                buscaResultsLoadingInterval = 0;
            }

            buscaResultsLoadingCard.style.display = isLoading ? '' : 'none';

            if (buscaResultsSkeleton) {
                buscaResultsSkeleton.style.display = isLoading ? '' : 'none';
            }

            if (config.scrollContainer) {
                config.scrollContainer.style.display = isLoading ? 'none' : '';
            }

            if (config.spinner) {
                config.spinner.style.display = isLoading ? 'none' : config.spinner.style.display;
            }

            if (isLoading) {
                buscaResultsLoadingInterval = startLoadingAnimation(
                    buscaResultsLoadingTitle,
                    buscaResultsLoadingCopy,
                    isPlainMode ? readI18n('loading.resultsTitlePlain', 'Buscando') : readI18n('loading.resultsTitleAi', 'Procurando corridas pra você'),
                    isPlainMode ? readI18n('loading.resultsStepsPlain', []) : readI18n('loading.resultsStepsAi', [])
                );
            }
        }

        // ESCONDE ABAS E RESULTADOS ENQUANTO A IA AINDA ESTA INTERPRETANDO

        function setResultsSurfaceVisible(isVisible) {
            document.querySelectorAll('.busca-tabs-shell').forEach(function (tabsShell) {
                tabsShell.style.display = isVisible ? '' : 'none';
            });

            var resultsContainer = document.getElementById('container-proximas');
            if (resultsContainer) {
                resultsContainer.style.display = isVisible ? '' : 'none';
            }
        }

        // EXIBE SQL E PARAMETROS NO PAINEL DE DEBUG TECNICO

        function getDebugValue(debugData, key) {
            if (!debugData) {
                return undefined;
            }

            if (debugData[key] !== undefined) {
                return debugData[key];
            }

            var upperKey = key.toUpperCase();
            if (debugData[upperKey] !== undefined) {
                return debugData[upperKey];
            }

            var lowerKey = key.toLowerCase();
            if (debugData[lowerKey] !== undefined) {
                return debugData[lowerKey];
            }

            return undefined;
        }

        function updateEventQueryDebug(eventSearchDebug) {
            var eventSql = getDebugValue(eventSearchDebug, 'sql');
            var eventParams = getDebugValue(eventSearchDebug, 'params');
            var eventQueryDebug = getDebugValue(eventSearchDebug, 'queryDebug');
            var paramsText = eventParams
                ? JSON.stringify(eventParams, null, 2)
                : '';
            var sqlText = eventSql ? eventSql : '';
            var searchMeta = {
                exists: Boolean(eventSearchDebug),
                eventSql: sqlText,
                eventParams: eventParams || '',
                queryDebug: eventQueryDebug || [],
                debug: eventSearchDebug || {}
            };
            var debugPanelMeta = document.getElementById('runnerhub-debug-search-meta');
            var debugPanelSql = document.getElementById('runnerhub-debug-search-sql');
            var debugPanelParams = document.getElementById('runnerhub-debug-search-params');
            var debugPanelQuerySql = document.getElementById('runnerhub-debug-query-search-sql');
            var debugPanelQueryParams = document.getElementById('runnerhub-debug-query-search-params');
            var debugPanelRaw = document.getElementById('runnerhub-debug-search-raw');
            var debugPanelExecutions = document.getElementById('runnerhub-debug-search-query-executions');
            var debugPanelQueryExecutions = document.getElementById('runnerhub-debug-query-search-executions');
            var debugPanel = window.RunnerHubDebugPanel || null;

            function setRawNode(node, value) {
                if (!node) {
                    return;
                }

                if (debugPanel && typeof debugPanel.renderRawNode === 'function') {
                    debugPanel.renderRawNode(node, value);
                } else {
                    node.textContent = value;
                }
            }

            function setJsonNode(node, value) {
                if (!node) {
                    return;
                }

                if (debugPanel && typeof debugPanel.renderJsonNode === 'function') {
                    debugPanel.renderJsonNode(node, value);
                } else {
                    node.textContent = value ? JSON.stringify(value, null, 2) : '';
                }
            }

            if (buscaDebugEventQuery) {
                buscaDebugEventQuery.textContent = sqlText;
                buscaDebugEventQuery.style.display = buscaDebugEventQuery.textContent.length ? '' : 'none';
            }

            if (buscaDebugEventParams) {
                buscaDebugEventParams.textContent = paramsText;
                buscaDebugEventParams.style.display = buscaDebugEventParams.textContent.length ? '' : 'none';
            }

            if (debugPanelMeta) {
                if (eventSearchDebug) {
                    setJsonNode(debugPanelMeta, searchMeta);
                } else {
                    setRawNode(debugPanelMeta, '');
                }
            }

            [debugPanelSql, debugPanelQuerySql].forEach(function (node) {
                setRawNode(node, sqlText);
            });

            [debugPanelParams, debugPanelQueryParams].forEach(function (node) {
                if (eventParams) {
                    setJsonNode(node, eventParams);
                } else {
                    setRawNode(node, '');
                }
            });

            if (debugPanelRaw) {
                if (eventSearchDebug) {
                    setJsonNode(debugPanelRaw, eventSearchDebug);
                } else {
                    setRawNode(debugPanelRaw, '');
                }
            }

            [debugPanelExecutions, debugPanelQueryExecutions].forEach(function (node) {
                if (eventQueryDebug) {
                    setJsonNode(node, eventQueryDebug);
                } else {
                    setRawNode(node, '');
                }
            });
        }

        function updateEventQueryDebugFromWindow() {
            if (window.__buscaEventDebug) {
                updateEventQueryDebug(window.__buscaEventDebug);
                window.__buscaEventDebug = null;
            }
        }

        function updateEventQueryDebugFromContainer(container) {
            var debugNode;
            var debugText;

            if (!container) {
                return false;
            }

            debugNode = container.querySelector('[data-busca-event-debug]');
            if (!debugNode) {
                return false;
            }

            debugText = (debugNode.textContent || '').trim();
            if (!debugText.length) {
                return false;
            }

            try {
                updateEventQueryDebug(JSON.parse(debugText));
                return true;
            } catch (error) {
                window.console.warn('Busca event debug parse failed.', error);
                return false;
            }
        }

        // MANTEM OS CAMPOS VISIVEIS E HIDDEN COM O MESMO TEXTO

        function syncBuscaInputs(value) {
            if (buscaPlainInput) {
                buscaPlainInput.value = value;
            }
            if (buscaAiInput) {
                buscaAiInput.value = value;
            }
            if (buscaHiddenInput) {
                buscaHiddenInput.value = value;
            }
        }

        // LIMPA O CARD "COMO ENTENDI SUA BUSCA"

        function clearBuscaDebug() {
            if (buscaDebugCard) {
                buscaDebugCard.style.display = 'none';
            }
            if (buscaDebugDetails) {
                buscaDebugDetails.open = false;
            }
            if (buscaFeedbackMessage) {
                buscaFeedbackMessage.textContent = '';
            }
            if (buscaDebugJson) {
                buscaDebugJson.textContent = '';
            }
            if (buscaDebugModelo) {
                buscaDebugModelo.textContent = '';
            }
            if (buscaDebugStatus) {
                buscaDebugStatus.textContent = '';
            }
            if (buscaDebugIgnored) {
                buscaDebugIgnored.style.display = 'none';
            }
            if (buscaDebugError) {
                buscaDebugError.textContent = '';
            }
            if (buscaDebugHttpStatus) {
                buscaDebugHttpStatus.textContent = '';
            }
            if (buscaDebugEndpoint) {
                buscaDebugEndpoint.textContent = '';
            }
            if (buscaDebugRaw) {
                buscaDebugRaw.textContent = '';
                buscaDebugRaw.style.display = 'none';
            }
            updateEventQueryDebug(null);
        }

        function resetBuscaFeedbackForPlainMode() {
            clearBuscaDebug();

            if (buscaDebugCard) {
                buscaDebugCard.style.display = '';
            }
            if (buscaFeedbackMessage) {
                buscaFeedbackMessage.textContent = readI18n('debug.plainFeedback', '');
            }
            if (buscaDebugStatus) {
                buscaDebugStatus.textContent = readI18n('debug.plainStatus', '');
            }
        }

        function getBuscaTipo() {
            var value = buscaTipoHiddenInput && buscaTipoHiddenInput.value ? buscaTipoHiddenInput.value : 'todos';
            return ['todos', 'eventos', 'resultados', 'atletas', 'noticias', 'videos'].indexOf(value) >= 0 ? value : 'todos';
        }

        // VERIFICA SE EXISTE FILTRO ATIVO MESMO SEM TEXTO DIGITADO

        function hasActiveFilterCriteria() {
            var currentState = filtersController.getState();

            return Boolean(
                (currentState.badges && currentState.badges.length) ||
                currentState.rua ||
                currentState.trail ||
                currentState.nacional ||
                currentState.internacional ||
                currentState.cupom ||
                (currentState.tag && currentState.tag.length) ||
                currentState.buscaDistanciaAtiva ||
                (currentState.buscaEstado && currentState.buscaEstado.length) ||
                (currentState.buscaCidade && currentState.buscaCidade.length) ||
                (currentState.buscaEstados && currentState.buscaEstados.length) ||
                (currentState.buscaPeriodoInicio && currentState.buscaPeriodoInicio.length) ||
                (currentState.buscaPeriodoFim && currentState.buscaPeriodoFim.length) ||
                (currentState.periodoMesesSelecionado &&
                    (currentState.periodoMesesSelecionado[0] > 0 || currentState.periodoMesesSelecionado[1] < 12))
            );
        }

        function captureBuscaFilters() {
            return {
                distancia_inicio: state.buscaDistanciaAtiva ? state.buscaDistanciaInicio : null,
                distancia_fim: state.buscaDistanciaAtiva ? state.buscaDistanciaFim : null,
                estado: state.buscaEstado || '',
                cidade: state.buscaCidade || '',
                estados: state.buscaEstados ? state.buscaEstados.split(',') : [],
                periodo_inicio: state.buscaPeriodoInicio || '',
                periodo_fim: state.buscaPeriodoFim || ''
            };
        }

        // RETIRA FILTROS DA INTERPRETACAO ANTERIOR SEM APAGAR AJUSTES MANUAIS.
        function restoreFiltersBeforeAi() {
            if (!aiFilterBaseline || !aiAppliedFilters) {
                return;
            }

            var filters = captureBuscaFilters();
            var groups = [
                ['distancia_inicio', 'distancia_fim'],
                ['periodo_inicio', 'periodo_fim'],
                ['estado'], ['cidade'], ['estados']
            ];
            groups.forEach(function (keys) {
                if (keys.every(function (key) {
                    return JSON.stringify(filters[key]) === JSON.stringify(aiAppliedFilters[key]);
                })) {
                    keys.forEach(function (key) {
                        filters[key] = aiFilterBaseline[key];
                    });
                }
            });
            filters.termo_livre = state.buscaApiTermo;
            filters.tipo_termo = 'indefinido';
            filtersController.syncBuscaFilters(filters);
            aiFilterBaseline = null;
            aiAppliedFilters = null;
        }

        function isCurrentSearch(requestId) {
            return requestId === undefined || requestId === aggregateSearchRequestId;
        }

        // ALTERA A ABA ATIVA E MOSTRA SOMENTE AS SECOES COMPATIVEIS

        function setBuscaTipo(nextTipo) {
            var normalizedTipo = ['todos', 'eventos', 'resultados', 'atletas', 'noticias', 'videos'].indexOf(nextTipo) >= 0 ? nextTipo : 'todos';
            var filtrosPanel = document.getElementById('busca-filtros-panel');

            if (buscaTipoHiddenInput) {
                buscaTipoHiddenInput.value = normalizedTipo;
            }

            document.querySelectorAll('[data-busca-results-tab]').forEach(function (tab) {
                tab.classList.toggle('active', tab.dataset.buscaResultsTab === normalizedTipo);
            });

            document.querySelectorAll('[data-busca-content-type]').forEach(function (button) {
                button.classList.toggle('is-active', button.dataset.buscaContentType === normalizedTipo);
            });

            document.querySelectorAll('[data-busca-section]').forEach(function (section) {
                section.style.display = normalizedTipo === 'todos' || section.dataset.buscaSection === normalizedTipo ? '' : 'none';
            });

            if (filtrosPanel) {
                filtrosPanel.style.display = ['todos', 'eventos', 'resultados'].indexOf(normalizedTipo) >= 0 ? '' : 'none';
            }
        }

        // IDENTIFICA TERMOS QUE INDICAM QUE RESULTADOS PASSADOS DEVEM VIR PRIMEIRO

        function hasResultsIntent() {
            var normalizedTerm = state.buscaTermo || '';

            if (typeof normalizedTerm.normalize === 'function') {
                normalizedTerm = normalizedTerm.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
            }

            normalizedTerm = normalizedTerm.toLowerCase();

            return /\b(resultados?|classificacao|classificacoes|cronometragem|tempos?|tempo oficial)\b/.test(normalizedTerm);
        }

        // REORDENA AS SECOES QUANDO A INTENCAO FOR RESULTADO OU PESSOA

        function applyAggregatePriority(termType) {
            var container = document.getElementById('container-proximas');
            var sectionMap = {
                eventos: document.getElementById('busca-eventos-section'),
                resultados: document.getElementById('busca-resultados-section'),
                atletas: document.getElementById('busca-atletas-section'),
                noticias: document.getElementById('busca-noticias-section'),
                videos: document.getElementById('busca-videos-section')
            };
            var anchor = document.getElementById('busca-no-results') || document.getElementById('spinner-proximas');
            var order = ['eventos', 'resultados', 'atletas', 'noticias', 'videos'];

            if (!container || getBuscaTipo() !== 'todos') {
                return;
            }

            if (hasResultsIntent()) {
                order = ['resultados', 'eventos', 'atletas', 'noticias', 'videos'];
            } else if (termType === 'pessoa') {
                order = ['atletas', 'eventos', 'resultados', 'noticias', 'videos'];
            } else if (termType === 'prova') {
                order = ['eventos', 'resultados', 'atletas', 'noticias', 'videos'];
            }

            order.forEach(function (sectionName) {
                if (sectionMap[sectionName]) {
                    container.insertBefore(sectionMap[sectionName], anchor);
                }
            });
        }

        // ATUALIZA CONTADORES DAS ABAS E ESCONDE "VER TODOS" QUANDO ZERADO

        function setResultCount(type, count) {
            var normalizedCount = Number(count) || 0;

            document.querySelectorAll('[data-busca-count="' + type + '"]').forEach(function (badge) {
                badge.textContent = String(normalizedCount);

                var tab = badge.closest('[data-busca-results-tab]');
                if (tab) {
                    tab.classList.toggle('is-zero', normalizedCount === 0);
                }
            });

            document.querySelectorAll('[data-busca-view-all="' + type + '"]').forEach(function (link) {
                link.style.display = normalizedCount > 0 ? '' : 'none';
            });
        }

        // SOMA OS RESULTADOS DE TODOS OS ENDPOINTS CARREGADOS

        function updateAggregateCounts(counts) {
            var total = Number(counts.eventos || 0) + Number(counts.resultados || 0) + Number(counts.atletas || 0);
            total += Number(counts.noticias || 0) + Number(counts.videos || 0);

            setResultCount('eventos', counts.eventos || 0);
            setResultCount('resultados', counts.resultados || 0);
            setResultCount('atletas', counts.atletas || 0);
            setResultCount('noticias', counts.noticias || 0);
            setResultCount('videos', counts.videos || 0);
            setResultCount('todos', total);

            return total;
        }

        // REFLETE A BUSCA ATUAL NA URL DA PAGINA

        function updateBuscaUrl() {
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca', state.buscaTermo));
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca_mode', state.buscaModo));
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca_tipo', getBuscaTipo()));
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'termo', ''));
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'redirect', ''));
            if (!state.buscaTermo.length && getBuscaTipo() === 'eventos') {
                // GUARDA O CALENDARIO RESOLVIDO, INCLUSIVE A ESCOLHA SEM UF.
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'estado', state.buscaEstado || ''));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'estados', state.buscaEstados || ''));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'cidade', state.buscaCidade || ''));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'context_uf', state.buscaEstado || 'BR'));
            }
        }

        function updateBuscaTypeUrl() {
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca_tipo', getBuscaTipo()));
        }

        function appendParam(url, key, value) {
            if (value === null || value === undefined || value === '') {
                return url;
            }

            return url + '&' + encodeURIComponent(key) + '=' + encodeURIComponent(value);
        }

        function appendLanguageParam(url) {
            if (!languageCode || languageCode === 'pt-BR') {
                return url;
            }

            return appendParam(url, 'i18n_lang', languageCode);
        }

        // MONTA URL DO ENDPOINT DE EVENTOS OU DO ENDPOINT DE RESULTADOS

        function buildEventosAsyncUrl(type) {
            var eventosState = filtersController.getState();
            var endpoint = type === 'resultados' ? '/api/resultados_busca.cfm' : '/api/eventos_busca.cfm';
            var url = endpoint + '?page=0' +
                '&badges=' + encodeURIComponent(eventosState.badges || '') +
                '&rua=' + encodeURIComponent(Boolean(eventosState.rua)) +
                '&trail=' + encodeURIComponent(Boolean(eventosState.trail)) +
                '&nacional=' + encodeURIComponent(Boolean(eventosState.nacional)) +
                '&internacional=' + encodeURIComponent(Boolean(eventosState.internacional)) +
                '&tag=' + encodeURIComponent(eventosState.tag || '') +
                '&cupom=' + encodeURIComponent(Boolean(eventosState.cupom)) +
                '&busca_mode=' + encodeURIComponent(eventosState.buscaModo || state.buscaModo);

            if (eventosState.buscaDistanciaAtiva && Number.isFinite(Number(eventosState.buscaDistanciaInicio))) {
                url = appendParam(url, 'distancia_inicio', eventosState.buscaDistanciaInicio);
            }
            if (eventosState.buscaDistanciaAtiva && Number.isFinite(Number(eventosState.buscaDistanciaFim))) {
                url = appendParam(url, 'distancia_fim', eventosState.buscaDistanciaFim);
            }
            if (eventosState.buscaApiTermo && eventosState.buscaApiTermo.length) {
                url = appendParam(url, 'busca', eventosState.buscaApiTermo);
            }
            if (eventosState.buscaModo === 'ai' && eventosState.buscaTermo && eventosState.buscaTermo.length) {
                url = appendParam(url, 'busca_original', eventosState.buscaTermo);
            }
            if (eventosState.buscaEstado && eventosState.buscaEstado.length) {
                url = appendParam(url, 'estado', eventosState.buscaEstado);
            }
            if (eventosState.buscaCidade && eventosState.buscaCidade.length) {
                url = appendParam(url, 'cidade', eventosState.buscaCidade);
            }
            if (eventosState.buscaEstados && eventosState.buscaEstados.length) {
                url = appendParam(url, 'estados', eventosState.buscaEstados);
            }
            if (eventosState.buscaPeriodoInicio && eventosState.buscaPeriodoInicio.length) {
                url = appendParam(url, 'periodo_inicio', eventosState.buscaPeriodoInicio);
            }
            if (eventosState.buscaPeriodoFim && eventosState.buscaPeriodoFim.length) {
                url = appendParam(url, 'periodo_fim', eventosState.buscaPeriodoFim);
            }
            if (!eventosState.buscaPeriodoInicio && !eventosState.buscaPeriodoFim && eventosState.periodoMesesSelecionado &&
                (eventosState.periodoMesesSelecionado[0] > 0 || eventosState.periodoMesesSelecionado[1] < 12)) {
                url = appendParam(url, 'tempo', eventosState.periodoMesesSelecionado.join(','));
            }
            if (eventosState.buscaTipoTermo && eventosState.buscaTipoTermo.length) {
                url = appendParam(url, 'tipo_termo', eventosState.buscaTipoTermo);
            }
            if (buscaLogId) {
                url = appendParam(url, 'busca_log_id', buscaLogId);
            }

            return appendLanguageParam(url);
        }

        // INSERE HTML RETORNADO POR ENDPOINTS E EXECUTA SCRIPTS EMBUTIDOS

        function renderHtml(container, html, syncEventPaging) {
            var scripts;
            var totalNode;

            if (!container) {
                return 0;
            }

            container.innerHTML = html;
            if (window.RoadRunnersAudience) {
                window.RoadRunnersAudience.adoptContext(container);
            }
            scripts = container.getElementsByTagName('script');

            updateEventQueryDebugFromContainer(container);

            for (var index = 0; index < scripts.length; index += 1) {
                window.eval(scripts[index].innerHTML);
            }

            updateEventQueryDebugFromWindow();

            if (typeof window.colorirDistancias === 'function') {
                window.colorirDistancias();
            }

            if (syncEventPaging && typeof filtersController.syncPagingStateFromWindow === 'function') {
                filtersController.syncPagingStateFromWindow();
            }

            totalNode = container.querySelector('[data-busca-total]');
            if (totalNode) {
                return Number(totalNode.getAttribute('data-busca-total') || 0);
            }

            return Number.isFinite(Number(window.totalEventos)) ? Number(window.totalEventos) : 0;
        }

        // CARREGA HTML DE UMA SECAO DA BUSCA AGREGADA

        function fetchResultHtml(url, container, syncEventPaging, requestId) {
            var audienceHeaders = {};
            if (window.RoadRunnersAudience && window.RoadRunnersAudienceConfig && url.indexOf('/api/eventos_busca.cfm') >= 0) {
                audienceHeaders['X-RR-Audience-Context'] = window.RoadRunnersAudienceConfig.contextToken;
                audienceHeaders['X-RR-Audience-Signature'] = window.RoadRunnersAudienceConfig.signature;
            }
            return window.fetch(url, { headers: audienceHeaders })
                .then(function (response) {
                    var responseUrl;

                    responseUrl = response && response.url
                        ? new window.URL(response.url, window.location.origin)
                        : null;

                    if (!response.ok || (responseUrl && /\/404\/?$/.test(responseUrl.pathname))) {
                        throw new Error('search html request failed: ' + (response ? response.status : 'unknown'));
                    }

                    return response.text();
                })
                .then(function (html) {
                    if (!isCurrentSearch(requestId)) {
                        return 0;
                    }
                    return renderHtml(container, html, syncEventPaging);
                });
        }

        // BUSCA ATLETAS USANDO O TERMO INTERPRETADO QUANDO A IA IDENTIFICOU PESSOA

        function fetchAthletesHtml(container, requestId) {
            var athleteTerm = state.buscaTipoTermo === 'pessoa' && state.buscaApiTermo
                ? state.buscaApiTermo
                : state.buscaTermo;
            var url = appendLanguageParam('/api/atletas_busca.cfm?busca=' + encodeURIComponent(athleteTerm));

            if (buscaLogId) {
                url = appendParam(url, 'busca_log_id', buscaLogId);
            }

            return window.fetch(url, { cache: 'no-store' })
                .then(function (response) {
                    if (!response.ok) {
                        throw new Error('athlete search request failed: ' + response.status);
                    }
                    return response.text();
                })
                .then(function (html) {
                    var count = 0;

                    if (!isCurrentSearch(requestId)) {
                        return count;
                    }

                    if (container) {
                        container.innerHTML = html;
                        count = container.querySelectorAll('.home-shell-card').length;
                    }

                    return count;
                });
        }

        // DEFINE O TERMO USADO EM NOTICIAS E VIDEOS

        function getContentSearchTerm() {
            return ['pessoa', 'prova'].indexOf(state.buscaTipoTermo) >= 0 && state.buscaApiTermo
                ? state.buscaApiTermo
                : state.buscaTermo;
        }

        function fetchNewsHtml(container, requestId) {
            var url = appendLanguageParam('/api/noticias_busca.cfm?busca=' + encodeURIComponent(getContentSearchTerm()) +
                '&busca_tipo=' + encodeURIComponent(getBuscaTipo()));

            if (buscaLogId) {
                url = appendParam(url, 'busca_log_id', buscaLogId);
            }

            return fetchResultHtml(url, container, false, requestId);
        }

        function fetchVideosHtml(container, requestId) {
            var url = appendLanguageParam('/api/videos_busca.cfm?busca=' + encodeURIComponent(getContentSearchTerm()) +
                '&busca_tipo=' + encodeURIComponent(getBuscaTipo()));

            if (buscaLogId) {
                url = appendParam(url, 'busca_log_id', buscaLogId);
            }

            return fetchResultHtml(url, container, false, requestId);
        }

        // ORQUESTRA A BUSCA COMPLETA: IA PRIMEIRO, ENDPOINTS DEPOIS

        function runAggregateSearch() {
            var currentRequestId = aggregateSearchRequestId + 1;
            var selectedTipo = getBuscaTipo();
            // SEM TEXTO, A ENTRADA GERAL CONTINUA O CALENDARIO DE PROVAS.
            if (!state.buscaTermo.length && selectedTipo === 'todos') {
                selectedTipo = 'eventos';
            }
            var eventContainer = document.getElementById('scroll-container-proximas');
            var resultContainer = document.getElementById('busca-resultados-results');
            var athletesContainer = document.getElementById('busca-atletas-results');
            var newsContainer = document.getElementById('busca-noticias-results');
            var videosContainer = document.getElementById('busca-videos-results');
            var emptyState = document.getElementById('busca-empty-state');
            var noResults = document.getElementById('busca-no-results');
            var tasks = [];
            var counts = {
                eventos: 0,
                resultados: 0,
                atletas: 0,
                noticias: 0,
                videos: 0
            };

            aggregateSearchRequestId = currentRequestId;
            loadedSearchTypes = {};
            buscaLogId = '';
            restoreFiltersBeforeAi();

            setAiLoading(false);
            setResultsLoading(false);
            updateAggregateCounts(counts);

            if (!state.buscaTermo.length && selectedTipo !== 'eventos' && !hasActiveFilterCriteria()) {
                setResultsSurfaceVisible(true);
                if (emptyState) {
                    emptyState.style.display = '';
                }
                return Promise.resolve();
            }

            syncBuscaInputs(state.buscaTermo);
            setBuscaTipo(selectedTipo);
            updateBuscaUrl();
            filtersController.setBuscaContext({
                buscaTermo: state.buscaTermo,
                buscaApiTermo: state.buscaModo === 'plain' ? state.buscaTermo : '',
                buscaModo: state.buscaModo
            });
            filtersController.clearResults();

            if (resultContainer) {
                resultContainer.innerHTML = '';
            }
            if (athletesContainer) {
                athletesContainer.innerHTML = '';
            }
            if (newsContainer) {
                newsContainer.innerHTML = '';
            }
            if (videosContainer) {
                videosContainer.innerHTML = '';
            }
            if (emptyState) {
                emptyState.style.display = 'none';
            }
            if (noResults) {
                noResults.style.display = 'none';
            }

            applyAggregatePriority(filtersController.getState().buscaTipoTermo || 'indefinido');

            function fetchAggregateResults() {
                // CARREGA EM PARALELO AS SECOES VISIVEIS DA BUSCA

                if (!isCurrentSearch(currentRequestId)) {
                    return Promise.resolve();
                }

                setResultsSurfaceVisible(true);
                setResultsLoading(true, !state.buscaTermo.length || state.buscaModo === 'plain');

                if (selectedTipo === 'todos' || selectedTipo === 'eventos') {
                    tasks.push(fetchResultHtml(buildEventosAsyncUrl('eventos'), eventContainer, true, currentRequestId).then(function (count) {
                        counts.eventos = count;
                        if (isCurrentSearch(currentRequestId)) { loadedSearchTypes.eventos = true; }
                    }));
                }

                if (selectedTipo === 'todos' || selectedTipo === 'resultados') {
                    tasks.push(fetchResultHtml(buildEventosAsyncUrl('resultados'), resultContainer, false, currentRequestId).then(function (count) {
                        counts.resultados = count;
                        if (isCurrentSearch(currentRequestId)) { loadedSearchTypes.resultados = true; }
                    }));
                }

                if ((selectedTipo === 'todos' || selectedTipo === 'atletas') && state.buscaTermo.length) {
                    tasks.push(fetchAthletesHtml(athletesContainer, currentRequestId).then(function (count) {
                        counts.atletas = count;
                        if (isCurrentSearch(currentRequestId)) { loadedSearchTypes.atletas = true; }
                    }));
                }

                if ((selectedTipo === 'todos' || selectedTipo === 'noticias') && state.buscaTermo.length) {
                    tasks.push(fetchNewsHtml(newsContainer, currentRequestId).then(function (count) {
                        counts.noticias = count;
                        if (isCurrentSearch(currentRequestId)) { loadedSearchTypes.noticias = true; }
                    }));
                }

                if ((selectedTipo === 'todos' || selectedTipo === 'videos') && state.buscaTermo.length) {
                    tasks.push(fetchVideosHtml(videosContainer, currentRequestId).then(function (count) {
                        counts.videos = count;
                        if (isCurrentSearch(currentRequestId)) { loadedSearchTypes.videos = true; }
                    }));
                }

                return Promise.allSettled(tasks)
                    .then(function (outcomes) {
                        if (currentRequestId !== aggregateSearchRequestId) {
                            return;
                        }

                        setResultsLoading(false);
                        updateAggregateCounts(counts);
                        loadedSearchTypes.todos = selectedTipo === 'todos' && outcomes.every(function (outcome) {
                            return outcome.status === 'fulfilled';
                        });
                        outcomes.forEach(function (outcome) {
                            if (outcome.status === 'rejected') {
                                window.console.warn('Uma seção da busca falhou.', outcome.reason);
                            }
                        });
                        if (noResults) {
                            noResults.style.display = 'none';
                        }
                    })
                    .catch(function (err) {
                        if (!isCurrentSearch(currentRequestId)) {
                            return;
                        }
                        setResultsLoading(false);
                        window.console.warn('Busca agregada falhou.', err);
                    });
            }

            if (!state.buscaTermo.length) {
                setResultsSurfaceVisible(true);
                clearBuscaDebug();
                setAiLoading(false);
                return fetchAggregateResults();
            }

            if (state.buscaModo === 'plain') {
                setResultsSurfaceVisible(true);
                resetBuscaFeedbackForPlainMode();
                setAiLoading(false);
                return fetchAggregateResults();
            }

            setResultsSurfaceVisible(false);
            return updateBuscaDebug(currentRequestId).then(function () {
                if (!isCurrentSearch(currentRequestId)) {
                    return;
                }
                applyAggregatePriority(filtersController.getState().buscaTipoTermo || 'indefinido');
                return fetchAggregateResults();
            });
        }

        // ALTERNA ENTRE BUSCA NORMAL E BUSCA COM IA

        function setBuscaMode(nextMode) {
            state.buscaModo = nextMode === 'plain' ? 'plain' : 'ai';
            filtersController.setBuscaMode(state.buscaModo);

            if (state.buscaModo === 'plain') {
                state.buscaApiTermo = state.buscaTermo;
            }

            if (buscaModeHiddenInput) {
                buscaModeHiddenInput.value = state.buscaModo;
            }
            if (buscaPlainWrapper && !isSingleBuscaField) {
                buscaPlainWrapper.style.display = state.buscaModo === 'plain' ? '' : 'none';
            }
            if (buscaAiWrapper && !isSingleBuscaField) {
                buscaAiWrapper.style.display = state.buscaModo === 'ai' ? '' : 'none';
            }

            buscaModeButtons.forEach(function (button) {
                button.classList.toggle('is-active', button.dataset.buscaMode === state.buscaModo);
            });
        }

        // CHAMA O ENDPOINT QUE INTERPRETA A FRASE COM IA E SINCRONIZA OS FILTROS

        function updateBuscaDebug(requestId) {
            if (!state.buscaTermo.length) {
                return Promise.resolve();
            }

            clearBuscaDebug();
            setAiLoading(true);

            return window.fetch(appendLanguageParam(appendParam(searchEndpoint + '?debug=1&busca=' + encodeURIComponent(state.buscaTermo), 'busca_tipo', getBuscaTipo())))
                .then(function (response) {
                    if (!response.ok) {
                        throw new Error('AI search request failed: ' + response.status);
                    }
                    return response.json();
                })
                .then(function (data) {
                    if (!isCurrentSearch(requestId)) {
                        return;
                    }
                    setAiLoading(false);

                    if (!data.ok || !data.filters) {
                        throw new Error('AI search returned no usable filters');
                    }

                    buscaLogId = data.searchLogId || (data.meta && data.meta.searchLogId) || '';

                    aiFilterBaseline = captureBuscaFilters();
                    filtersController.syncBuscaFilters(data.filters);
                    aiAppliedFilters = captureBuscaFilters();

                    if (buscaHeroCopy) {
                        buscaHeroCopy.textContent = interpolate(readI18n('debug.heroCopy', 'Mostrando eventos para “{term}”.'), {
                            term: state.buscaTermo
                        });
                    }
                    if (buscaDebugCard) {
                        buscaDebugCard.style.display = '';
                    }
                    if (buscaDebugJson) {
                        buscaDebugJson.textContent = JSON.stringify(data.filters);
                    }
                    if (buscaFeedbackMessage) {
                        buscaFeedbackMessage.textContent = data.message || '';
                    }
                    if (buscaDebugModelo) {
                        buscaDebugModelo.textContent = readI18n('debug.modelLabel', 'Modelo') + ': ' + (config.aiModel || '');
                    }
                    if (buscaDebugStatus) {
                        if (data.meta.usedAi) {
                            buscaDebugStatus.textContent = readI18n('debug.aiValidatedStatus', '');
                        } else if (data.meta.aiConfigured) {
                            buscaDebugStatus.textContent = interpolate(readI18n('debug.fallbackStatus', ''), {
                                reason: getFallbackReasonLabel(data.meta.fallbackReason)
                            });
                        } else {
                            buscaDebugStatus.textContent = readI18n('debug.notConfiguredStatus', '');
                        }
                    }
                    if (buscaDebugError) {
                        buscaDebugError.textContent = data.meta.error ? interpolate(readI18n('debug.technicalDetail', 'Detalhe técnico: {detail}'), {
                            detail: data.meta.error
                        }) : '';
                    }
                    if (buscaDebugHttpStatus) {
                        buscaDebugHttpStatus.textContent = data.meta.debug && data.meta.debug.httpStatus ? readI18n('debug.httpLabel', 'HTTP OpenAI') + ': ' + data.meta.debug.httpStatus : '';
                    }
                    if (buscaDebugEndpoint) {
                        if (data.meta.debug && (data.meta.debug.endpoint || data.meta.debug.model)) {
                            buscaDebugEndpoint.textContent = readI18n('debug.endpointLabel', 'Endpoint') + ': ' + (data.meta.debug.endpoint || '') + ' | ' + readI18n('debug.modelLabel', 'Modelo') + ': ' + (data.meta.debug.model || '');
                        } else {
                            buscaDebugEndpoint.textContent = '';
                        }
                    }

                    updateEventQueryDebug(data.meta.debug && data.meta.debug.eventSearch ? data.meta.debug.eventSearch : null);

                    if (buscaDebugRaw) {
                        var shouldShowRaw = Boolean(
                            data.meta.debug &&
                            data.meta.debug.httpStatus &&
                            String(data.meta.debug.httpStatus).slice(0, 3) !== '200'
                        );

                        buscaDebugRaw.textContent = shouldShowRaw ? JSON.stringify(data.meta.debug, null, 2) : '';
                        buscaDebugRaw.style.display = shouldShowRaw ? '' : 'none';
                    }

                    if (buscaDebugIgnored) {
                        buscaDebugIgnored.style.display = 'none';
                    }

                    return data;
                })
                .catch(function (err) {
                    if (!isCurrentSearch(requestId)) {
                        return;
                    }
                    setAiLoading(false);
                    restoreFiltersBeforeAi();
                    buscaLogId = '';
                    setBuscaMode('plain');
                    filtersController.setBuscaContext({ buscaApiTermo: state.buscaTermo, buscaModo: 'plain' });
                    updateBuscaUrl();
                    resetBuscaFeedbackForPlainMode();
                    window.console.warn('Busca debug failed.', err);
                });
        }

        filtersController.setCallbacks({
            setResultsLoading: setResultsLoading,
            updateEventQueryDebug: updateEventQueryDebug
        });

        buscaModeButtons.forEach(function (button) {
            button.addEventListener('click', function () {
                var activeInput = getActiveBuscaInput();
                var currentValue = activeInput ? activeInput.value.trim() : state.buscaTermo;
                syncBuscaInputs(currentValue);
                setBuscaMode(button.dataset.buscaMode);
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca_mode', state.buscaModo));
            });
        });

        setBuscaMode(state.buscaModo);
        syncBuscaInputs(state.buscaTermo);

        if (buscaForm && buscaHiddenInput) {
            buscaForm.addEventListener('submit', function (event) {
                var activeInput;

                activeInput = getActiveBuscaInput();
                state.buscaTermo = activeInput ? activeInput.value.trim() : '';
                state.buscaModo = buscaModeHiddenInput && buscaModeHiddenInput.value === 'ai' ? 'ai' : 'plain';
                state.buscaApiTermo = state.buscaModo === 'plain' ? state.buscaTermo : '';

                if (isSingleBuscaField) {
                    event.preventDefault();
                    runAggregateSearch();
                    return;
                }

                filtersController.setBuscaContext({
                    buscaTermo: state.buscaTermo,
                    buscaApiTermo: state.buscaApiTermo,
                    buscaModo: state.buscaModo
                });
                syncBuscaInputs(state.buscaTermo);
                clearBuscaDebug();
                filtersController.clearResults();

                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca', state.buscaTermo));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca_mode', state.buscaModo));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'termo', ''));
                window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'redirect', ''));

                if (!shouldInterceptSubmit) {
                    return;
                }

                event.preventDefault();

                if (state.buscaModo === 'plain') {
                    resetBuscaFeedbackForPlainMode();
                    setAiLoading(false);
                    filtersController.callAPI();
                    return;
                }

                updateBuscaDebug().finally(function () {
                    filtersController.callAPI();
                });
            });
        }

        if (state.buscaTermo.length && !window.location.search.includes('busca=')) {
            window.history.replaceState('', '', window.updateURLParameter(window.location.href, 'busca', state.buscaTermo));
        }

        document.addEventListener('click', function (event) {
            var tab = event.target.closest('[data-busca-results-tab]');

            if (!tab || !isSingleBuscaField) {
                return;
            }

            event.preventDefault();
            event.stopPropagation();
            setBuscaTipo(tab.dataset.buscaResultsTab);
            updateBuscaTypeUrl();
            if (!loadedSearchTypes[getBuscaTipo()]) {
                runAggregateSearch();
            }
        }, true);

        if (isSingleBuscaField && (state.buscaTermo.length || hasActiveFilterCriteria() ||
            getBuscaTipo() === 'todos' || getBuscaTipo() === 'eventos')) {
            window.setTimeout(runAggregateSearch, 0);
        }
    }

    window.RunnerHubBuscaPage = {
        init: init
    };
})(window, document);
