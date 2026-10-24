<!--- JQUERY --->

<script src="/assets/js/code.jquery.com_jquery-3.7.1.min.js"></script>


<!--- CORES --->

<script>

    function colorirDistancias() {
        var mc = {
            "0-5": "k5",
            "6-10": "k10",
            "11-21": "k21",
            "22-42": "k42",
            "43-99999": "ultra"
        };

        function between(x, min, max) {
            return x >= min && x <= max;
        }

        var dc;
        var first;
        var second;
        var th;

        $("div").each(function (index) {
            th = $(this);

            dc = parseInt($(this).attr("data-color"), 10);

            $.each(mc, function (name, value) {
                first = parseInt(name.split("-")[0], 10);
                second = parseInt(name.split("-")[1], 10);

                if (between(dc, first, second)) {
                    th.addClass(value);
                }
            });
        });
    }

    colorirDistancias();

</script>


<!--- ORIGEM DOS LINKS EXTERNOS (INDEPENDENTE DO MODAL) --->
<script src="/assets/js/outbound-links.js?v=<cfoutput>#VARIABLES.cssVersion#</cfoutput>"></script>

<!--- BOOTSTRAP --->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

<cfinclude template="modal_roadrunners.cfm"/>


<!--- DATATABLES --->

<script src="/assets/js/datatables/datatables.min.js"></script>


<!--- MDB ESSENTIAL --->

<script type="text/javascript" src="/assets/js/mdb.umd.min.js"></script>


<!--- MDB PLUGINS --->

<script type="text/javascript" src="/assets/plugins/js/all.min.js"></script>


<!--- ATIVANDO TOOLTIPS --->

<script>
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    })
</script>


<!--- STRAVA EMBEDS --->

<script src="https://strava-embeds.com/embed.js"></script>


<!--- ATIVANDO DATATABLES --->

<script>

    $(document).ready( function () {

        if ($('#tableResultados').length) {
            const resultadosRemoteUrl = $('#tableResultados').data('remote-url');
            const resultadosBaseOptions = {
                language: {
                    url: '//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json',
                },
                info: <cfif isDefined("qEvento.resultado_completo") AND qEvento.resultado_completo>true<cfelse>false</cfif>,
                scrollY: '50vh',
                scrollCollapse: true,
                autoWidth: false,
                initComplete: function( settings, json ) {
                    $('#divResultados').show();
                    $('#loading').hide();
                }
            };

            let tableResultados;

            if (resultadosRemoteUrl) {
                const resultadosTable = $('#tableResultados');
                const resultadosBody = resultadosTable.find('tbody');
                const resultadosStatus = $('#resultadosInfiniteStatus');
                let resultadosOffset = 0;
                let resultadosLoading = false;
                let resultadosHasMore = true;
                let resultadosBusca = '';
                let resultadosAbortController = null;

                $('#loading').hide();
                $('#divResultados').show();

                $('#tableResultados_filter').remove();
                const resultadosScroll = resultadosTable.closest('.or-results-scroll');
                (resultadosScroll.length ? resultadosScroll : resultadosTable).before(
                    '<div class="d-flex justify-content-end mb-2">' +
                    '<div class="input-group input-group-sm" style="max-width: 320px;">' +
                    '<span class="input-group-text bg-white"><i class="fa-solid fa-magnifying-glass"></i></span>' +
                    '<input id="resultadosInfiniteSearch" type="search" class="form-control" placeholder="Pesquisar na listagem">' +
                    '</div>' +
                    '</div>'
                );

                function updateResultadosStatus(text) {
                    resultadosStatus.text(text || '');
                }

                function buildResultadosUrl(reset) {
                    const url = new URL(resultadosRemoteUrl, window.location.origin);
                    url.searchParams.set('offset', reset ? 0 : resultadosOffset);
                    url.searchParams.set('limit', 100);
                    url.searchParams.set('busca', resultadosBusca);
                    return url.toString();
                }

                function loadResultados(reset) {
                    if (resultadosLoading) {
                        return;
                    }

                    if (!reset && !resultadosHasMore) {
                        return;
                    }

                    resultadosLoading = true;
                    updateResultadosStatus('Carregando resultados...');

                    if (reset && resultadosAbortController) {
                        resultadosAbortController.abort();
                    }

                    resultadosAbortController = new AbortController();

                    fetch(buildResultadosUrl(reset), {
                        headers: {
                            'Accept': 'application/json'
                        },
                        signal: resultadosAbortController.signal
                    })
                        .then(function(response) {
                            if (!response.ok) {
                                throw new Error('HTTP ' + response.status);
                            }
                            return response.json();
                        })
                        .then(function(payload) {
                            const payloadOk = payload.ok !== undefined ? payload.ok : payload.OK;
                            const payloadError = payload.error || payload.ERROR || 'Erro ao carregar resultados.';
                            const payloadHtml = payload.html !== undefined ? payload.html : payload.HTML;
                            const payloadNextOffset = payload.nextOffset !== undefined ? payload.nextOffset : payload.NEXTOFFSET;
                            const payloadHasMore = payload.hasMore !== undefined ? payload.hasMore : payload.HASMORE;
                            const payloadRecordsFiltered = payload.recordsFiltered !== undefined ? payload.recordsFiltered : payload.RECORDSFILTERED;

                            if (!payloadOk) {
                                throw new Error(payloadError);
                            }

                            if (reset) {
                                resultadosBody.empty();
                                resultadosOffset = 0;
                            }

                            resultadosBody.append(payloadHtml || '');
                            resultadosOffset = payloadNextOffset || resultadosBody.find('tr').length;
                            resultadosHasMore = !!payloadHasMore;

                            if (payloadRecordsFiltered === 0) {
                                updateResultadosStatus('Nenhum resultado encontrado.');
                            } else if (resultadosHasMore) {
                                updateResultadosStatus('Exibindo ' + resultadosOffset.toLocaleString('pt-BR') + ' de ' + payloadRecordsFiltered.toLocaleString('pt-BR') + ' resultados.');
                            } else {
                                updateResultadosStatus('Todos os ' + payloadRecordsFiltered.toLocaleString('pt-BR') + ' resultados foram carregados.');
                            }
                        })
                        .catch(function(error) {
                            if (error.name === 'AbortError') {
                                return;
                            }

                            updateResultadosStatus('');
                            if (!$('#resultadosAjaxError').length) {
                                const errorDetail = window.location.hostname.indexOf('dev.') === 0 ? '<br><small>' + error.message + '</small>' : '';
                                $('#divResultados').prepend('<div id="resultadosAjaxError" class="alert alert-warning p-2 mt-2">Não foi possível carregar os resultados agora. Tente novamente em instantes.' + errorDetail + '</div>');
                            }
                            console.error(error);
                        })
                        .finally(function() {
                            resultadosLoading = false;
                        });
                }

                let resultadosSearchTimer;
                $(document).on('input', '#resultadosInfiniteSearch', function() {
                    clearTimeout(resultadosSearchTimer);
                    resultadosBusca = this.value.trim();
                    resultadosSearchTimer = setTimeout(function() {
                        resultadosOffset = 0;
                        resultadosHasMore = true;
                        $('#resultadosAjaxError').remove();
                        loadResultados(true);
                    }, 350);
                });

                $(window).on('scroll.resultadosInfinite', function() {
                    if ($(window).scrollTop() + $(window).height() > $(document).height() - 700) {
                        loadResultados(false);
                    }
                });

                loadResultados(true);
            } else {
                tableResultados = new DataTable('#tableResultados', {
                    ...resultadosBaseOptions,
                    ordering: true,
                    paging: false,
                    columnDefs: [
                        { width: '40px', targets: 0 },
                        { width: '80px', targets: 1 },
                        { width: '50px', targets: 2 },
                        { width: 'auto', targets: 3 },
                        { width: 'auto', targets: 4 },
                        { width: '40px', targets: 5 },
                        { width: '60px', targets: 6 },
                        { width: '60px', targets: 7 },
                        //{ width: '26px', targets: 8 }
                    ],
                    initComplete: function( settings, json ) {
                        $('#divResultados').show();
                        tableResultados.columns.adjust().draw();
                        $('#loading').hide();
                    }
                });
            }
        }

        let tableTopAtletas = new DataTable('#tableTopAtletas', {
            language: {
                url: '//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json',
            },
            info: true,
            ordering: true,
            paging: false,
            scrollCollapse: true,
            scrollY: '50vh',
            autoWidth: true
        })

    } );
</script>


<!--- SCROLL TO TOP --->

<script>

    // Get the button:
    let mybutton = document.getElementById("scrollTop");

    // When the user scrolls down 20px from the top of the document, show the button
    window.onscroll = function() {scrollFunction()};

    function scrollFunction() {
        if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
            mybutton.style.display = "block";
        } else {
            mybutton.style.display = "none";
        }
    }

    // When the user clicks on the button, scroll to the top of the document
    function topFunction() {
        document.body.scrollTop = 0; // For Safari
        document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
    }

</script>


<!--- URL PARAMS --->

<script>
    function updateURLParameter(url, param, paramVal){
        var newAdditionalURL = "";
        var tempArray = url.split("?");
        var baseURL = tempArray[0];
        var additionalURL = tempArray[1];
        var temp = "";
        if (additionalURL) {
            tempArray = additionalURL.split("&");
            for (var i=0; i<tempArray.length; i++){
                if(tempArray[i].split('=')[0] != param){
                    newAdditionalURL += temp + tempArray[i];
                    temp = "&";
                }
            }
        }

        var rows_txt = temp + "" + param + "=" + paramVal;
        return baseURL + "?" + newAdditionalURL + rows_txt;
    }
</script>


<!--- FEATURED EVENTS CAROUSEL --->

<script>
    (function () {
        function initFeaturedCarousel(section) {
            const viewport = section.querySelector('.or-featured-events-viewport');
            const track = section.querySelector('.or-featured-events-track');
            const controls = section.querySelectorAll('[data-featured-scroll]');

            if (!viewport || !track || !controls.length) {
                return;
            }

            function getStep() {
                const firstCard = track.querySelector('.or-featured-event-card');

                if (!firstCard) {
                    return track.clientWidth;
                }

                const styles = window.getComputedStyle(track);
                const gap = parseFloat(styles.columnGap || styles.gap || 0) || 0;

                return firstCard.getBoundingClientRect().width + gap;
            }

            function updateState() {
                const maxScroll = Math.max(0, track.scrollWidth - track.clientWidth - 2);
                const canScrollLeft = track.scrollLeft > 2;
                const canScrollRight = track.scrollLeft < maxScroll;

                viewport.classList.toggle('can-scroll-left', canScrollLeft);
                viewport.classList.toggle('can-scroll-right', canScrollRight);

                controls.forEach(function (control) {
                    const direction = control.dataset.featuredScroll;
                    const canScroll = direction === 'prev' ? canScrollLeft : canScrollRight;

                    if (control.classList.contains('or-featured-events-nav')) {
                        control.setAttribute('aria-disabled', canScroll ? 'false' : 'true');
                    } else {
                        control.disabled = !canScroll;
                    }
                });
            }

            function scrollFeaturedTrack(direction) {
                const amount = getStep() * direction;

                try {
                    track.scrollBy({
                        left: amount,
                        behavior: 'smooth'
                    });
                } catch (error) {
                    track.scrollLeft += amount;
                }

                window.setTimeout(updateState, 220);
            }

            controls.forEach(function (control) {
                control.addEventListener('click', function (event) {
                    event.preventDefault();
                    scrollFeaturedTrack(control.dataset.featuredScroll === 'prev' ? -1 : 1);
                });
            });

            track.addEventListener('keydown', function (event) {
                if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') {
                    return;
                }

                event.preventDefault();
                scrollFeaturedTrack(event.key === 'ArrowLeft' ? -1 : 1);
            });

            track.addEventListener('scroll', updateState, { passive: true });
            window.addEventListener('resize', updateState);
            window.requestAnimationFrame(updateState);
            window.setTimeout(updateState, 350);
        }

        document.addEventListener('DOMContentLoaded', function () {
            document.querySelectorAll('.or-featured-events').forEach(initFeaturedCarousel);
        });
    })();
</script>


<!--- PAGE LOADER --->

<script>
    (function () {
        const loader = document.getElementById('orPageLoader');
        let showTimer;

        if (!loader) {
            return;
        }

        function showPageLoader() {
            clearTimeout(showTimer);
            showTimer = setTimeout(function () {
                loader.classList.add('is-active');
                loader.setAttribute('aria-hidden', 'false');
            }, 120);
        }

        function hidePageLoader() {
            clearTimeout(showTimer);
            loader.classList.remove('is-active');
            loader.setAttribute('aria-hidden', 'true');
        }

        function shouldIgnoreLink(link, event) {
            if (!link || link.dataset.noPageLoader !== undefined) {
                return true;
            }

            if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) {
                return true;
            }

            if (link.target && link.target !== '_self') {
                return true;
            }

            if (link.hasAttribute('download')) {
                return true;
            }

            const href = link.getAttribute('href');

            if (!href || href.charAt(0) === '#' || href.indexOf('javascript:') === 0 || href.indexOf('mailto:') === 0 || href.indexOf('tel:') === 0) {
                return true;
            }

            const url = new URL(link.href, window.location.href);

            return url.origin !== window.location.origin || (url.pathname === window.location.pathname && url.search === window.location.search && url.hash);
        }

        document.addEventListener('click', function (event) {
            const link = event.target.closest ? event.target.closest('a') : null;

            if (shouldIgnoreLink(link, event)) {
                return;
            }

            setTimeout(function () {
                if (!event.defaultPrevented) {
                    showPageLoader();
                }
            }, 0);
        });

        document.addEventListener('submit', function (event) {
            const form = event.target;

            setTimeout(function () {
                if (!event.defaultPrevented && form.target !== '_blank' && form.dataset.noPageLoader === undefined) {
                    showPageLoader();
                }
            }, 0);
        });

        window.addEventListener('beforeunload', showPageLoader);
        window.addEventListener('pageshow', hidePageLoader);
        document.addEventListener('DOMContentLoaded', hidePageLoader);
    })();
</script>


<!--- SOCIAL MEDIA INFO
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "Organization",
        "name": "DeuMeet",
        "url": "http://deumeet.com",
        "address": "Florianópolis, SC",
        "sameAs": [
            "https://www.facebook.com/clubedebrinquedostumtum",
            "https://www.youtube.com/c/clubedebrinquedostumtum",
            "https://www.linkedin.com/company/clube-de-brinquedos-tum-tum",
            "https://www.instagram.com/clubedebrinquedostumtum/"
        ]
    }
</script>
 --->
