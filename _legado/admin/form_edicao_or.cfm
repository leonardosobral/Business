<div class="tab-pane fade <cfif URL.sessao EQ "or">show active</cfif>" id="ex1-tabs-6" role="tabpanel" aria-labelledby="ex1-tab-6" tabindex="5">

    <div class="row">

        <div class="col-md-12 mb-3">


            <!--- CONFIGURACOES DO RESULTADO --->

            <form class="form" method="post">

                <div class="input-group mb-3">
                      <div data-mdb-input-init class="form-outline">
                        <input type="text" class="form-control pt-3" readonly id="txtOpenResults" style="background:transparent;" name="url_openresults" value="https://openresults.run/evento/<cfoutput>#qEvento.tag#</cfoutput>/"/>
                        <label class="form-label" for="txtOpenResults">URL Open Results</label>
                    </div>
                    <cfif len(trim(qEvento.tag))>
                        <a target="_blank" href="https://openresults.run/evento/<cfoutput>#qEvento.tag#</cfoutput>/" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                            Abrir Link
                        </a>
                    </cfif>
                </div>

                <div class="input-group mb-3">
                      <div data-mdb-input-init class="form-outline">
                        <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlResultado" name="url_resultado" value="<cfoutput>#qEvento.url_resultado#</cfoutput>"/>
                        <label class="form-label" for="txtUrlResultado">URL de Resultado Oficial</label>
                    </div>
                    <cfif len(trim(qEvento.url_resultado))>
                        <a target="_blank" href="<cfoutput>#qEvento.url_resultado#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                            Abrir Link
                        </a>
                    </cfif>
                </div>

                <div class="input-group mb-3">
                      <div data-mdb-input-init class="form-outline">
                        <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlWiclax" name="url_wiclax" value="<cfoutput>#qEvento.url_wiclax#</cfoutput>"/>
                        <label class="form-label" for="txtUrlWiclax">URL do Wiclax/Racezone</label>
                    </div>
                    <cfif len(trim(qEvento.url_wiclax))>
                        <a target="_blank" href="<cfoutput>#qEvento.url_wiclax#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                            Abrir Link
                        </a>
                    </cfif>
                </div>

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <div class="form-outline">
                            <select data-mdb-select-init class="form-select" name="ranking" id="selectRanking">
                                <option value="">Selecione</option>
                                <option value="1" <cfif qEvento.ranking EQ true>selected</cfif>>Sim</option>
                                <option value="0" <cfif qEvento.ranking EQ false>selected</cfif>>Não</option>
                            </select>
                            <label class="form-label select-label">Ranking</label>
                        </div>
                    </div>

                    <div class="col-md-6 mb-3">
                        <div class="form-outline">
                            <select data-mdb-select-init class="form-select" name="homologado" id="selectHomologado">
                                <option value="">Selecione</option>
                                <option value="1" <cfif qEvento.homologado EQ true>selected</cfif>>Sim</option>
                                <option value="0" <cfif qEvento.homologado EQ false>selected</cfif>>Não</option>
                            </select>
                            <label class="form-label select-label">Homologado</label>
                        </div>
                    </div>

                    <div class="col-md-12 mb-3">

                        <div data-mdb-input-init class="form-outline">
                                <input type="text" class="form-control pt-3" maxlength="128" id="txtObsResultado" name="obs_resultado" value="<cfoutput>#qEvento.obs_resultado#</cfoutput>"/>
                                <label class="form-label" for="txtObsResultado">OBS Resultado</label>
                        </div>

                    </div>

                    <div class="col-md-12 mb-3">

                        <div data-mdb-input-init class="form-outline">
                                <input type="text" class="form-control pt-3" maxlength="128" id="txtObsHomologacao" name="obs_homologacao" value="<cfoutput>#qEvento.obs_homologacao#</cfoutput>"/>
                                <label class="form-label" for="txtObsHomologacao">OBS Homologação</label>
                        </div>

                    </div>

                </div>

                <div class="row">

                    <div class="col-md-12">
                        <input type="hidden" name="action" value="editar_evento_or"/>
                        <input type="hidden" name="id_evento" value="<cfoutput>#URL.id_evento#</cfoutput>"/>
                        <button type="submit" class="btn btn-primary w-100">Salvar Dados de Resultado</button>
                    </div>

                </div>

            </form>

            <hr class="my-4"/>


            <!--- DADOS DO RESULTADO --->

            <p>
                <cfoutput>
                    <a target="processar" class="btn btn-secondary me-2" href="/api/racezone/?id_evento=#qEvento.id_evento#">Importar Racezone</a>
                    <a target="processar" class="btn btn-secondary me-2" href="/api/wiclax/?id_evento=#qEvento.id_evento#">Importar Wiclax</a>
                    <a target="processar" class="btn btn-secondary" href="/api/excel/?id_evento=#qEvento.id_evento#">Importar Excel</a>
                </cfoutput>
            </p>

            <cfquery name="qCountResult">
                select count(id_resultado) as total
                from tb_resultados
                where id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            </cfquery>

            <cfquery name="qCountTemp">
                select count(id_resultado) as total
                from tb_resultados_temp
                where id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.id_evento#"/>
            </cfquery>

            <cfquery name="qProcessamentos">
                select * from tb_resultados_processa
                where id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                ORDER BY data_processamento_final desc
            </cfquery>

            <p>Registros na importação: <cfoutput>#qCountTemp.total#</cfoutput></p>

            <p>Registros finais: <cfoutput>#qCountResult.total#</cfoutput></p>

            <div class="accordion accordion-flush" id="accordionFlushExample">

                <cfloop query="qProcessamentos">

                  <div class="accordion-item">
                    <h2 class="accordion-header" id="flush-heading<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>">
                      <button
                        data-mdb-collapse-init
                        class="accordion-button collapsed"
                        type="button"
                        data-mdb-toggle="collapse"
                        data-mdb-target="#flush-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
                        aria-expanded="false"
                        aria-controls="flush-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>">
                        <cfoutput><cfif qProcessamentos.erro_execucao><icon class="fa fa-warning"></icon></cfif> &nbsp; #LsDateFormat(qProcessamentos.data_processamento_final, "yyyy-mm-dd")# <!--- - #LsTimeFormat(qProcessamentos.data_processamento_inicial, "hh:mm:ss")# ---> às #LsTimeFormat(qProcessamentos.data_processamento_final, "HH:mm:ss")#</cfoutput>
                      </button>
                    </h2>
                    <div
                      id="flush-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
                      class="accordion-collapse collapse"
                      aria-labelledby="flush-heading<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
                      data-mdb-parent="#accordionFlushExample">
                      <div class="accordion-body p-0">

                        <p class="px-2 pt-3">chave_processamento: <cfoutput>#qProcessamentos.chave_processamento#</cfoutput></p>
                        <p class="px-2">chave_verificacao: <cfoutput>#qProcessamentos.chave_verificacao#</cfoutput></p>
                        <p class="px-2 pt-3"><a target="_blank" href="/api/log/?chave_processamento=<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>">Ver log da importação </a></p>

                      </div>
                    </div>
                  </div>

                </cfloop>

            </div>

            <hr class="mt-4 mb-5"/>


            <!--- EXCLUIR RESULTADO --->

            <div class="row">

                <div class="col-md-12">
                    <form class="form" method="post">
                        <p class="text-danger-emphasis">ATENÇÃO: A exclusão dos resultados é permanente.</p>
                        <input type="checkbox" name="aceite" value="true"/> &nbsp; Confirmo a exclusão dos resultados
                        <br/>
                        <br/>
                        <input type="hidden" name="action" value="excluir_resultados"/>
                        <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                        <button type="submit" class="btn btn-danger w-100">Excluir Resultados</button>
                    </form>
                </div>

            </div>

        </div>

    </div>

</div>
