<div class="<cfif Len(trim(URL.id_evento))>col-md-6<cfelse>col-md-12</cfif>">

    <div class="card">

        <div class="card-body p-3 g-3">


            <!--- WIDGETS --->

            <cfif qEventos.recordcount>
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

            <table id="tblEventos" class="table table-stripped table-bordered table-condensed table-sm mb-0" style="height: calc(100vh - 275px);overflow: auto;display: inline-block;">

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

                <cfoutput query="qEventos">

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

            </table>

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
