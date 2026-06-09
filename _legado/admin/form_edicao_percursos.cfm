<div class="tab-pane fade <cfif URL.sessao EQ "percursos">show active</cfif>" id="ex1-tabs-4" role="tabpanel" aria-labelledby="ex1-tab-4" tabindex="3">

    <cfquery name="qModalidades">
        SELECT prc.* FROM tb_evento_corridas_percursos prc
        WHERE prc.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    </cfquery>

    <form class="form" method="post" action="/admin/?<cfoutput>busca=#URL.busca#&estado=#URL.estado#&id_evento=#URL.id_evento#&id_agrega_evento=#URL.id_agrega_evento#&preset=#URL.preset#&sessao=percursos</cfoutput>">

        <div data-mdb-input-init class="form-outline mb-3">
            <input type="text" class="form-control pt-3" maxlength="128" id="txtPercursos" name="categorias" value="<cfoutput>#qEvento.categorias#</cfoutput>"/>
            <label class="form-label" for="txtPercursos">Percursos em texto</label>
        </div>

        <div class="row mb-3">

            <div class="col-md-12">
                <input type="hidden" name="action" value="editar_evento_percursos"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100">Criar / Alterar Percursos</button>
            </div>

        </div>

    </form>

    <div class="row">

        <div class="col-md-12">

            <cfloop query="qModalidades">

                <cfquery name="qBadges">
                    SELECT tip.image_path, tip.badge, bg.valor_badge, bg.percurso, bg.complemento_badge from tb_badges_tipos tip
                    left join tb_badges bg on bg.badge = tip.badge
                        and bg.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                        and bg.percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#qModalidades.percurso_evento#"/>
                    where tip.tipo_badge = 'percurso'
                    and tip.min_km <= <cfqueryparam cfsqltype="cf_sql_integer" value="#qModalidades.percurso_evento#"/>
                    order by ordem
                </cfquery>

                <div class="card mb-3">

                    <div class="card-header bg-dark fw-bold">PERCURSO <cfoutput>#qModalidades.percurso_evento# #qModalidades.unidade_de_medida#</cfoutput></div>

                    <div class="card-body p-3 pb-0 g-3">

                        <form class="form" method="post" action="/admin/?<cfoutput>busca=#URL.busca#&estado=#URL.estado#&id_evento=#URL.id_evento#&id_agrega_evento=#URL.id_agrega_evento#&preset=#URL.preset#&sessao=percursos</cfoutput>">

                            <div class="row g-3">

                                <div class="col-md-2">
                                    <div class="form-outline">
                                        <select data-mdb-select-init class="form-select" name="tipo_corrida" id="selectTipoCorrida<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>">
                                            <option value="rua" <cfif qModalidades.tipo_corrida EQ "rua">selected</cfif>>Rua</option>
                                            <option value="trail" <cfif qModalidades.tipo_corrida EQ "trail">selected</cfif>>Trail</option>
                                        </select>
                                        <label class="form-label select-label">Tipo</label>
                                    </div>
                                </div>

                                <div class="col-md-3">
                                    <div class="form-outline" data-mdb-datepicker-init data-mdb-input-init>
                                        <input type="text" class="form-control" id="dataPercurso<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" name="data_percurso" value="<cfoutput>#qModalidades.data_percurso#</cfoutput>" />
                                        <label for="dataPercurso<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" class="form-label">Data</label>
                                    </div>
                                </div>

                                <div class="col-md-3">
                                    <div class="form-outline" data-mdb-timepicker-init data-mdb-input-init>
                                        <input type="text" class="form-control" id="horaLargada<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" name="hora_largada" value="<cfoutput>#left(qModalidades.hora_largada,5)#</cfoutput>" />
                                        <label for="horaLargada<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" class="form-label">Largada</label>
                                    </div>
                                </div>

                                <div class="col-md-2">
                                    <div class="form-outline" data-mdb-input-init>
                                        <input type="text" class="form-control" id="percurso<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" name="percurso_evento" value="<cfoutput>#qModalidades.percurso_evento#</cfoutput>" />
                                        <label for="percurso<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" class="form-label">Distância</label>
                                    </div>
                                </div>

                                <div class="col-md-2">
                                    <div class="form-outline" data-mdb-input-init>
                                        <input type="text" class="form-control" id="unidade<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" name="unidade_de_medida" value="<cfoutput>#qModalidades.unidade_de_medida#</cfoutput>" />
                                        <label for="unidade<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>" class="form-label">Unidade</label>
                                    </div>
                                </div>

                                <cfloop query="qBadges">

                                    <div class="col-md-1 pe-0">
                                        <div class="form-outline" data-mdb-input-init>
                                            <!---img src="/assets/badgets/badget_<cfoutput>#qBadges.badge#</cfoutput>.png" class="float-start mt-1 me-2" height="16px"--->
                                            <input type="checkbox" class="form-check-inline" id="<cfoutput>#qBadges.badge#-#qModalidades.id_evento_percurso#</cfoutput>" name="<cfoutput>#qBadges.badge#</cfoutput>" <cfif len(qBadges.percurso)>checked</cfif> />
                                        </div>
                                    </div>

                                    <div class="col-md-5">
                                        <div class="form-outline" data-mdb-input-init>
                                            <input type="text" class="form-control" id="<cfoutput>#qBadges.badge#-#qModalidades.id_evento_percurso#</cfoutput>" name="<cfoutput>#qBadges.badge#_valor_badge</cfoutput>" value="<cfoutput>#qBadges.valor_badge#</cfoutput>" />
                                            <label for="<cfoutput>#qBadges.badge#-#qModalidades.id_evento_percurso#</cfoutput>" class="form-label"><cfoutput>#qBadges.badge#</cfoutput></label>
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-outline" data-mdb-input-init>
                                            <input type="text" class="form-control" id="<cfoutput>#qBadges.badge#-#qModalidades.id_evento_percurso#</cfoutput>" name="<cfoutput>#qBadges.badge#_complemento_badge</cfoutput>" value="<cfoutput>#qBadges.complemento_badge#</cfoutput>" />
                                            <label for="<cfoutput>#qBadges.badge#-#qModalidades.id_evento_percurso#</cfoutput>" class="form-label">complemento</label>
                                        </div>
                                    </div>

                                </cfloop>

                                <div class="col-md-12">
                                    <input type="hidden" name="action" value="salvar_evento_percurso"/>
                                    <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                                    <input type="hidden" name="id_evento_percurso" value="<cfoutput>#qModalidades.id_evento_percurso#</cfoutput>"/>
                                    <button type="submit" class="btn btn-primary w-100">Salvar</button>
                                </div>

                            </div>

                        </form>

                    </div>
                </div>

            </cfloop>
        </div>

    </div>

</div>
