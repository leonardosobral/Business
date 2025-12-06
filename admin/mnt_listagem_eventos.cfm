<div class="<cfif Len(trim(URL.id_evento))>col-md-6<cfelse>col-md-12</cfif>">

    <div class="card">

        <div class="card-body p-3 g-3">


            <!--- FILTROS BUSCA

            <div class="row g-3">

                <div class="col-md-2 mb-3">

                    <select data-mdb-select-init class="form-select" onchange="window.location.href='<cfoutput>./?estado=</cfoutput>' + this.value">>
                        <option value="" <cfif URL.estado EQ "">selected</cfif> >Estado</option>
                        <cfoutput query="qEstados">
                            <option value="#qEstados.estado#" <cfif URL.estado EQ qEstados.estado>selected</cfif> >#qEstados.estado#</option>
                        </cfoutput>
                    </select>

                </div>

                <div class="col-md-5 mb-3">

                    <select data-mdb-select-init data-mdb-visible-options="12" class="form-select" onchange="window.location.href='<cfoutput>./?preset=</cfoutput>' + this.value">>

                        <optgroup label="Road Runners">
                            <option value="futuros" <cfif URL.preset EQ "futuros">selected</cfif> >Futuros</option>
                            <option value="passados" <cfif URL.preset EQ "passados">selected</cfif> >Passados</option>
                            <option value="destaques" <cfif URL.preset EQ "destaques">selected</cfif> >Destaques</option>
                            <option value="duplicados" <cfif URL.preset EQ "duplicados">selected</cfif> >Duplicados</option>
                            <option value="obs" <cfif URL.preset EQ "obs">selected</cfif> >OBS</option>
                            <option value="2024" <cfif URL.preset EQ "2024">selected</cfif> >2024</option>
                            <option value="2024_hoje" <cfif URL.preset EQ "2024_hoje">selected</cfif> >2024 Até <cfoutput>#lsDateFormat(now(),'dd/mm/yyyy')#</cfoutput></option>
                            <option value="2024_principais" <cfif URL.preset EQ "2024_principais">selected</cfif> >Principais de 2024</option>
                        </optgroup>

                        <optgroup label="Resultados">
                            <option value="2023" <cfif URL.preset EQ "2023">selected</cfif> >2023</option>
                            <option value="2023_principais" <cfif URL.preset EQ "2023_principais">selected</cfif> >Principais de 2023</option>
                            <option value="2023_sem_resultado" <cfif URL.preset EQ "2023_sem_resultado">selected</cfif> >Principais de 2023 - Sem resultados</option>
                            <option value="com_resultado" <cfif URL.preset EQ "com_resultado">selected</cfif> >Com Resultados</option>
                            <option value="sem_resultado" <cfif URL.preset EQ "sem_resultado">selected</cfif> >Sem Resultados</option>
                            <option value="wiclax" <cfif URL.preset EQ "wiclax">selected</cfif> >Wiclax</option>
                            <option value="chronomax" <cfif URL.preset EQ "chronomax">selected</cfif> >Chronomax</option>
                            <option value="wiclax_sem_resultado" <cfif URL.preset EQ "wiclax_sem_resultado">selected</cfif> >Wiclax Sem Resultados</option>
                            <option value="chronomax_sem_resultado" <cfif URL.preset EQ "chronomax_sem_resultado">selected</cfif> >Chronomax Sem Resultados</option>
                            <option value="chiptiming_sem_resultado" <cfif URL.preset EQ "chiptiming_sem_resultado">selected</cfif> >Chiptiming Sem Resultados</option>
                        </optgroup>

                        <optgroup label="Circuitos">
                            <cfoutput query="qAgregaCircuito">
                                <option value="AGR#id_agrega_evento#" <cfif URL.preset EQ "AGR#id_agrega_evento#">selected</cfif>>#nome_evento_agregado#</option>
                            </cfoutput>
                        </optgroup>

                        <optgroup label="Maratonas">
                            <cfoutput query="qAgregaMaratonas">
                                <option value="AGR#id_agrega_evento#" <cfif URL.preset EQ "AGR#id_agrega_evento#">selected</cfif>>#nome_evento_agregado#</option>
                            </cfoutput>
                        </optgroup>

                        <optgroup label="Corridas">
                            <cfoutput query="qAgregaCorridas">
                                <option value="AGR#id_agrega_evento#" <cfif URL.preset EQ "AGR#id_agrega_evento#">selected</cfif>>#nome_evento_agregado#</option>
                            </cfoutput>
                        </optgroup>

                    </select>

                </div>

                <div class="col-md-5 mb-3">

                    <form action="" method="get">
                        <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
                        <input type="hidden" name="preset" value=""/>
                    </form>

                </div>

            </div>
 --->

            <!--- WIDGETS

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
 --->

            <!--- LISTAGEM DE EVENTOS --->

            <table id="tblEventos" class="table table-stripped table-bordered table-condensed table-sm mb-0">

                <cfoutput query="qEventos">

                    <tr style="font-size: small;">

                        <td nowrap>
                            #lsDateFormat(data_inicial, "yyyy-mm-dd")#
                            <br/>
                            #lsDateFormat(data_final, "yyyy-mm-dd")#
                        </td>

                        <!--- UF --->
                        <td>
                            #qEventos.estado#
                            <br/>
                            #qEventos.cidade#
                        </td>

                        <!--- EVENTO --->
                        <td>
                            <a target="processar" href="https://roadrunners.run/busca/?termo=#qEventos.nome_evento#">#qEventos.nome_evento#</a>
                            <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qEventos.nome_evento)#"><i class="fa-brands fa-google ms-1"></i></a>
                            <br/>
                            #qEventos.categorias#
                        </td>

                        <td width="16">
                            <cfif len(trim(qEventos.url_inscricao))><a target="processar" href="#qEventos.url_inscricao#"><span class="badge bg-primary">I</span></a></cfif>
                        </td>

                        <td>
                            #qEventos.name#
                            <br/>
                            #qEventos.email#
                        </td>

                        <cfif URL.preset EQ "duplicados">
                            <td class="text-end">
                                <form class="form" method="post">
                                    <input type="hidden" name="action" value="excluir_evento"/>
                                    <input type="hidden" name="aceite" value="true"/>
                                    <input type="hidden" name="id_evento" value="#qEventos.id_evento#"/>
                                    <button type="submit" class="btn btn-sm btn-danger w-100">Excluir</button>
                                </form>
                            </td>
                        </cfif>

                    </tr>

                </cfoutput>

            </table>

        </div>

    </div>

</div>

<!---cfif isDefined("VARIABLES.linhaSelecionada")>

    <script>
        var rows = document.querySelectorAll('#tblEventos tr');

        // line is zero-based
        // line is the row number that you want to see into view after scroll
        rows[<cfoutput>#VARIABLES.linhaSelecionada#</cfoutput>].scrollIntoView({
            behavior: 'smooth',
            block: 'start'
        });
    </script>

</cfif--->
