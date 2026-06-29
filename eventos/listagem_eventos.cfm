<cfset VARIABLES.eventosClientListMode = isDefined("VARIABLES.adminRestrictByConta")
    AND VARIABLES.adminRestrictByConta
    AND NOT VARIABLES.adminIsAdmin
    AND NOT Len(trim(URL.id_evento))/>
<cfset VARIABLES.eventosListMaxRows = qEventos.recordcount/>
<cfset VARIABLES.eventosListIsLimited = false/>
<cfset VARIABLES.eventosListBaseQuery = "preset=#urlEncodedFormat(URL.preset)#&periodo=#urlEncodedFormat(URL.periodo)#&busca=#urlEncodedFormat(URL.busca)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#&id_agrega_evento=#urlEncodedFormat(URL.id_agrega_evento)#&agregador_tag=#urlEncodedFormat(URL.agregador_tag)#&sessao=#urlEncodedFormat(URL.sessao)#"/>

<cfif VARIABLES.eventosClientListMode AND compareNoCase(URL.mostrar, "todos") NEQ 0 AND qEventos.recordcount GT 80>
    <cfset VARIABLES.eventosListMaxRows = 80/>
    <cfset VARIABLES.eventosListIsLimited = true/>
</cfif>

<div class="<cfif Len(trim(URL.id_evento))>col-md-6<cfelse>col-md-12</cfif> <cfif VARIABLES.eventosClientListMode>business-page events-list-section</cfif>">

    <div class="card <cfif VARIABLES.eventosClientListMode>shadow-0 business-page-card events-list-card</cfif>">

        <div class="card-body <cfif VARIABLES.eventosClientListMode>business-page-body<cfelse>p-3 g-3</cfif>">

            <cfif VARIABLES.eventosClientListMode>
                <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                    <div>
                        <div class="business-label mb-1">Lista da conta</div>
                        <h4 class="mb-1">Eventos vinculados</h4>
                        <p class="text-muted mb-0">
                            <cfif VARIABLES.eventosListIsLimited>
                                <cfoutput>Mostrando #VARIABLES.eventosListMaxRows# de #qEventos.recordcount# eventos. Use a busca ou filtros para encontrar uma prova específica.</cfoutput>
                            <cfelseif qEventos.recordcount>
                                <cfoutput>#qEventos.recordcount# eventos encontrados com os filtros atuais.</cfoutput>
                            <cfelse>
                                Nenhum evento encontrado com os filtros atuais.
                            </cfif>
                        </p>
                    </div>
                    <div class="business-page-actions">
                        <cfif VARIABLES.eventosListIsLimited>
                            <cfoutput><a class="btn btn-sm btn-outline-warning" href="/eventos/?#VARIABLES.eventosListBaseQuery#&mostrar=todos">Ver todos</a></cfoutput>
                        <cfelseif compareNoCase(URL.mostrar, "todos") EQ 0 AND qEventos.recordcount GT 80>
                            <cfoutput><a class="btn btn-sm btn-outline-light" href="/eventos/?#VARIABLES.eventosListBaseQuery#">Compactar lista</a></cfoutput>
                        </cfif>
                    </div>
                </div>
            </cfif>


            <!--- WIDGETS --->

            <cfif qEventos.recordcount AND NOT VARIABLES.eventosClientListMode>
                <div class="row g-3">
                    <div class="col-md-3 mb-3">
                        <div class="card bg-primary py-2 px-3">
                            <p class="h4 m-0"><cfoutput>#numberFormat((qStatsInsc.recordcount*100)/qEventos.recordcount, "9.9")#%</cfoutput></p>
                            <p class="m-0">Inscrição</p>
                        </div>
                    </div>
                    <div class="col-md-3 mb-3">
                        <div class="card bg-primary py-2 px-3">
                            <p class="h4 m-0"><cfoutput>#numberFormat((qStatsEnd.recordcount*100)/qEventos.recordcount, "9.9")#%</cfoutput></p>
                            <p class="m-0">Endereço</p>
                        </div>
                    </div>
                    <div class="col-md-3 mb-3">
                        <div class="card bg-primary py-2 px-3">
                            <p class="h4 m-0"><cfoutput>#numberFormat((qStatsConteudo.recordcount*100)/qEventos.recordcount, "9.9")#%</cfoutput></p>
                            <p class="m-0">Conteúdo</p>
                        </div>
                    </div>
                    <cfif URL.preset EQ "futuros">
                        <div class="col-md-3 mb-3">
                            <div class="card bg-primary py-2 px-3">
                                <p class="h4 m-0"><cfoutput>#numberFormat((qStatsDistancias.recordcount*100)/qEventos.recordcount, "9.9")#%</cfoutput></p>
                                <p class="m-0">Distancias</p>
                            </div>
                        </div>
                    <cfelse>
                        <div class="col-md-3 mb-3">
                            <div class="card bg-primary py-2 px-3">
                                <p class="h4 m-0"><cfoutput>#numberFormat((qStatsResultados.recordcount*100)/qEventos.recordcount, "9.9")#%</cfoutput></p>
                                <p class="m-0">Resultados</p>
                            </div>
                        </div>
                    </cfif>
                </div>
            </cfif>


            <!--- LISTAGEM DE EVENTOS --->

            <div class="<cfif VARIABLES.eventosClientListMode>events-client-table-wrap<cfelse>table-responsive</cfif>">
            <table id="tblEventos" class="table table-stripped table-bordered table-condensed table-sm mb-0">

                <tr>
                    <th>Data</th>
                    <th colspan="2">UF</th>
                    <cfif  URL.preset EQ "2024_hoje">
                        <th colspan="3">Eventos (<cfoutput>#qStatsResultados.recordcount#/#qEventos.recordcount#</cfoutput>)</th>

                        <cfelse>
                            <th colspan="3">Eventos (<cfoutput>#qEventos.recordcount#</cfoutput>)</th>
                    </cfif>

                    <cfif NOT Len(trim(URL.id_evento))>
                        <th class="text-start">Categorias</th>
                    </cfif>

                    <!--- PROCESSAR RESULTADOS --->
                    <cfif URL.preset NEQ "futuros">
                        <cfif Len(trim(URL.id_evento))>
                            <th class="text-start">Results</th>
                        <cfelse>
                            <th class="text-start" colspan="3">Results</th>
                        </cfif>
                    </cfif>

                    <cfif URL.preset EQ "obs">
                        <td class="text-end"></td>
                    </cfif>

                </tr>

                <cfif qEventos.recordcount>
                <cfoutput query="qEventos" maxrows="#VARIABLES.eventosListMaxRows#">

                    <cfif Len(trim(URL.id_evento))>

                        <cfif qEventos.id_evento EQ URL.id_evento>
                            <cfset VARIABLES.linhaSelecionada = qEventos.currentrow/>
                        </cfif>

                    </cfif>

                    <tr style="font-size: small;">

                        <td nowrap>#lsDateFormat(data_inicial, "yyyy-mm-dd")#</td>

                        <!--- UF --->
                        <td><a href="./?preset=#URL.preset#&busca=#URL.busca#&estado=#qEventos.estado#&sessao=#URL.sessao#">#qEventos.estado#</a>

                        </td>

                        <!--- ENDERECO --->
                        <td>
                                <!---#qEventos.cidade#--->
                                <cfif len(trim(qEventos.endereco))><span class="badge bg-primary" title="Endereço">E</span></cfif>
                        </td>

                        <!--- EVENTO --->
                        <td>
                            <a target="processar" href="https://roadrunners.run/evento/#qEventos.tag#/"><icon class="fa fa-link me-1"></icon></a>
                            <a href="./?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qEventos.id_evento#">#qEventos.nome_evento#</a>
                            <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qEventos.nome_evento)#"><i class="fa-brands fa-google ms-1"></i></a>
                        </td>

                        <td width="16">
                            <cfif len(trim(qEventos.url_inscricao))><a target="processar" href="#qEventos.url_inscricao#"><span class="badge bg-primary">I</span></a></cfif>
                        </td>
                        <td width="16">
                            <cfif len(trim(qEventos.descricao))><span class="badge bg-primary" title="Conteúdo">C</span></cfif>
                        </td>

                        <cfif NOT Len(trim(URL.id_evento))>
                            <td class="text-start">#qEventos.categorias#</td>
                        </cfif>

                        <!--- PROCESSAR RESULTADO --->
                        <cfif URL.preset NEQ "futuros">

                            <cfif NOT Len(trim(URL.id_evento))>

                                <td nowrap class="text-end">#total#</td>

                            <cfelse>

                                <td nowrap class="text-end">
                                    <cfif total GT 0>
                                        #total#
                                    </cfif>
                                </td>

                            </cfif>

                        </cfif>

                    </tr>

                </cfoutput>
                <cfelse>
                    <tr>
                        <td colspan="8" class="text-center text-muted py-4">Nenhum evento encontrado.</td>
                    </tr>
                </cfif>

            </table>
            </div>

            <cfif VARIABLES.eventosListIsLimited>
                <div class="events-list-more mt-3">
                    <cfoutput>
                        <span>Existem mais #qEventos.recordcount - VARIABLES.eventosListMaxRows# eventos ocultos para manter a tela leve.</span>
                        <a class="btn btn-sm btn-outline-warning" href="/eventos/?#VARIABLES.eventosListBaseQuery#&mostrar=todos">Mostrar todos</a>
                    </cfoutput>
                </div>
            </cfif>

        </div>

    </div>

</div>

<cfif isDefined("VARIABLES.linhaSelecionada")>

    <script>
        var rows = document.querySelectorAll('#tblEventos tr');

        // line is zero-based
        // line is the row number that you want to see into view after scroll
        rows[<cfoutput>#VARIABLES.linhaSelecionada#</cfoutput>].scrollIntoView({
            behavior: 'smooth',
            block: 'start'
        });
    </script>

</cfif>
