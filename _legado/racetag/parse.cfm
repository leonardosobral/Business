
        <hr/>

        <cfquery name="qEvento">
            SELECT * FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfscript>
            function arrayToQuery(data) {
                return data.reduce(function(accumulator, element) {
                    element.each(function(key) {
                        if (!accumulator.keyExists(key)) {
                            accumulator.addColumn(key, []);
                        }
                    });
                    accumulator.addRow(element);
                    return accumulator;
                }, QueryNew(""));
            }
        </cfscript>

        <cfif isDefined("eventoJSON.categories") and arraylen(eventoJSON.categories)>
            <cfset VARIABLES.qCategorias = arrayToQuery(eventoJSON.categories)/>
        <cfelse>
            <cfset VARIABLES.qCategorias = queryNew("g,h,i,n", "varchar, varchar, varchar, varchar",[{g=""},{h=""},{i="",n=""}])/>
        </cfif>
        <cfif isDefined("eventoJSON.teams") and arraylen(eventoJSON.teams)>
            <cfset VARIABLES.qEquipes = arrayToQuery(eventoJSON.teams)/>
        <cfelse>
            <cfset VARIABLES.qEquipes = queryNew("i,n")/>
        </cfif>


        <cfset VARIABLES.arrModalidades = eventoJSON.routes/>

        <!---cfdump var="#VARIABLES.qCategorias#"/--->


        <!--- PASSO 3 --->

        <cfquery>
            DELETE FROM tb_resultados_temp
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
        </cfquery>

        <p><icon class="fa fa-circle-check text-success"></icon> Passo 3: Removidos os dados da tabela de resultados temporários.</p>


        <!--- PASSO 4 --->

        <cfhttp result="resultado" url="#FORM.url_racetag#data/#VARIABLES.evento.id#/results.json"></cfhttp>

        <cfif resultado.statuscode CONTAINS "200" and len(trim(resultado.filecontent))>

            <cfset mydoc = deserializeJSON(resultado.filecontent)>

            <cfloop array="#VARIABLES.arrModalidades#" item="modalidade">

                <!---cftry--->

                    <cfloop array="#mydoc#" index="item">
                        <cfif isDefined("modalidade.d") AND isDefined("item.r") AND modalidade.i EQ item.r>
                            <cfif isDefined('item.c') and len(trim(item.c))>
                                <cfquery name="qCategoria" dbtype="query">
                                    SELECT * from VARIABLES.qCategorias
                                    WHERE i = <cfqueryparam cfsqltype="cf_sql_varchar" value="#item.c#"/>
                                </cfquery>
                            </cfif>
                            <cfif isDefined('item.t') and len(trim(item.t))>
                                <cfquery name="qEquipe" dbtype="query">
                                    SELECT * from VARIABLES.qEquipes
                                    WHERE i = <cfqueryparam cfsqltype="cf_sql_varchar" value="#item.t#"/>
                                </cfquery>
                            </cfif>
                            <cfquery>
                                insert into tb_resultados_temp
                                (
                                num_peito, nome, categoria, id_evento, modalidade, percurso, sexo, equipe, data_nascimento, nacionalidade, hora_largada, pace, tempo_total, status_final
                                )
                                values
                                (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#isDefined('item.n') ? item.n : 0#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.nm') ? item.nm : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.c') ? qCategoria.n : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.c') ? modalidade.n : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.c') ? round(modalidade.d/1000) : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.g') ? item.g : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#(isDefined('item.t') and isDefined('qEquipe')) ? qEquipe.n : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_date" value="#isDefined('item.a') ? (Year(now()) - item.a) & '-12-31' : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.na') ? item.na : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.start') ? item.start : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.pace') ? item.pace : ''#" null="#NOT isDefined('item.pace')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.s') ? item.s : isDefined('item.tn') ? left(item.tn,8) : ''#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('item.s') ? item.s : ''#"/>
                                );
                            </cfquery>
                        </cfif>
                    </cfloop>

                    <cfquery name="qMax">
                        select count(num_peito) as total
                        from tb_resultados_temp
                        WHERE modalidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#modalidade.n#"/>
                        and id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
                    </cfquery>

                    <cfif qMax.recordcount>
                        <p>
                            <cfoutput>Carregando #modalidade.n#...</cfoutput>
                            <br/>Total de atletas: <cfoutput>#lsNumberFormat(qMax.total)#</cfoutput>
                        </>
                    </cfif>

                <!---cfcatch type="any">
                    <p class="text-danger">ERRO:</p>
                    <cfdump var="#resultado.filecontent#"/>
                </cfcatch>

                </cftry--->

            </cfloop>

        <cfelse>

            <cfdump var="#resultado.statuscode#" label="resultado"/>
            <cfabort/>

        </cfif>

        <p>
            <icon class="fa fa-circle-check text-success"></icon> Passo 4: Modalidades criadas e dados gravados na tabela de resultados temporários.
        </p>

        <cfquery name="qMax">
            select max(num_peito) as max, count(num_peito) as total
            from tb_resultados_temp
            WHERE modalidade is not null
            and id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
        </cfquery>

        <cfif qMax.recordcount>
            <p>
                <icon class="fa fa-circle-check text-success"></icon> Passo 5: Criada a grade de modalidades na tabela de resultados temporários.
            </p>
        </cfif>

        <div class="row">

            <div class="col-md-6">

                <h4>Grade Pré Tratamento</h4>

                <cfquery name="qPanorama">
                    select modalidade, sexo, count(distinct num_peito) as concluintes, max(classificacao_sexo) as classificacao_sexo
                    from tb_resultados_temp
                    WHERE modalidade is not null and id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
                    group by modalidade, sexo;
                </cfquery>

                <cfif qPanorama.recordcount>
                    <table class="table table-sm table-bordered table-striped" style="font-size: small;">
                        <tr>
                            <th>Modalidade</th>
                            <th>Gênero</th>
                            <th>Concluintes</th>
                        </tr>
                    <cfoutput query="qPanorama">
                        <tr>
                            <td <cfif qPanorama.CLASSIFICACAO_SEXO EQ qPanorama.concluintes>style="background-color: lightgreen;"</cfif> >#qPanorama.MODALIDADE#</td>
                            <td>#qPanorama.SEXO#</td>
                            <td>#qPanorama.concluintes#</td>
                        </tr>
                    </cfoutput>
                    </table>
                </cfif>

            </div>

        </div>


        <!--- PASSO 6 --->

        <cfif qPanorama.recordcount>
            <cfquery>
                delete from tb_resultados_temp where percurso = '' and id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
            </cfquery>
            <p><icon class="fa fa-circle-check text-success"></icon> Passo 6: Removidos os resultados sem identificação de percurso.</p>
        </cfif>

        <div class="row">

            <div class="col-md-6">

                <h4>Grade Atualizada</h4>

                <cfquery name="qPanorama">
                    select modalidade, sexo, count(distinct num_peito) as concluintes, max(classificacao_sexo) as classificacao_sexo
                    from tb_resultados_temp
                    WHERE modalidade is not null and id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>
                    group by modalidade, sexo;
                </cfquery>

                <cfif qPanorama.recordcount>
                    <table class="table table-sm table-bordered table-striped" style="font-size: small;">
                        <tr>
                            <th>Modalidade</th>
                            <th>Gênero</th>
                            <th>Concluintes</th>
                        </tr>
                    <cfoutput query="qPanorama">
                        <tr>
                            <td <cfif qPanorama.CLASSIFICACAO_SEXO EQ qPanorama.concluintes>style="background-color: lightgreen;"</cfif> >#qPanorama.MODALIDADE#</td>
                            <td>#qPanorama.SEXO#</td>
                            <td>#qPanorama.concluintes#</td>
                        </tr>
                    </cfoutput>
                    </table>
                </cfif>

            </div>

        </div>


        <hr/>

        <!--- PASSO 7 --->

        <cfif qPanorama.recordcount>

            <cfquery>
                call gera_resultados(<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.id_evento#"/>);
            </cfquery>

            <p><icon class="fa fa-circle-check text-success"></icon> Passo 7: Chamada a procedure que gera os resultados em produção.</p>

            <div class="row">

                <div class="col-md-6">

                    <h4>Grade em Produção</h4>

                    <cfquery name="qPanorama">
                        select modalidade, sexo, count(distinct num_peito) as concluintes, max(classificacao_sexo) as classificacao_sexo
                        from tb_resultados
                        WHERE modalidade is not null and id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
                        group by modalidade, sexo;
                    </cfquery>

                    <cfif qPanorama.recordcount>

                        <table class="table table-sm table-bordered table-striped" style="font-size: small;">
                            <tr>
                                <th>Modalidade</th>
                                <th>Gênero</th>
                                <th>Concluintes</th>
                            </tr>
                        <cfoutput query="qPanorama">
                            <tr>
                                <td <cfif qPanorama.CLASSIFICACAO_SEXO EQ qPanorama.concluintes>style="background-color: lightgreen;"</cfif> >#qPanorama.MODALIDADE#</td>
                                <td>#qPanorama.SEXO#</td>
                                <td>#qPanorama.concluintes#</td>
                            </tr>
                        </cfoutput>
                        </table>

                    <cfelse>

                        <p>Sem resultados ou dados inconsistentes, veja o log.</p>

                    </cfif>

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

                        <cfloop query="qProcessamentos" endrow="1">

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

                </div>

            </div>

        </cfif>



        <!--- PASSO 8 --->

        <cfif qPanorama.recordcount>
            <cfquery>
                call atualiza_classific_f1(<cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>);
            </cfquery>
            <p><icon class="fa fa-circle-check text-success"></icon> Passo 8: Atualizada a classificação.</p>
        </cfif>


        <!--- RESULTADOS --->

        <cfif qPanorama.recordcount>

            <hr/>

            <h4>Resultados em: <cfoutput><a href="https://openresults.run/evento/#qEvento.tag#/" target="_blank">https://openresults.run/evento/#qEvento.tag#/</a></cfoutput></h4>

        </cfif>


        <!--- RESULTADOS --->

        <hr/>

        <h4>Log Completo</h4>


        <div class="accordion accordion-flush" id="accordionFlushExample">

            <cfloop query="qProcessamentos">

              <div class="accordion-item">
                <h2 class="accordion-header" id="flush-completo-heading<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>">
                  <button
                    data-mdb-collapse-init
                    class="accordion-button collapsed"
                    type="button"
                    data-mdb-toggle="collapse"
                    data-mdb-target="#flush-completo-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
                    aria-expanded="false"
                    aria-controls="flush-completo-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>">
                    <cfoutput><cfif qProcessamentos.erro_execucao><icon class="fa fa-warning"></icon></cfif> &nbsp; #LsDateFormat(qProcessamentos.data_processamento_final, "yyyy-mm-dd")# <!--- - #LsTimeFormat(qProcessamentos.data_processamento_inicial, "hh:mm:ss")# ---> às #LsTimeFormat(qProcessamentos.data_processamento_final, "HH:mm:ss")#</cfoutput>
                  </button>
                </h2>
                <div
                  id="flush-completo-collapse<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
                  class="accordion-collapse collapse"
                  aria-labelledby="flush-completo-heading<cfoutput>#qProcessamentos.chave_processamento#</cfoutput>"
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
