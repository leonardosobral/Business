<div class="tab-pane fade <cfif URL.sessao EQ "configuracoes">show active</cfif>" id="ex1-tabs-5" role="tabpanel" aria-labelledby="ex1-tab-5" tabindex="4">

    <form class="form" method="post">

        <div class="row">

            <div class="col-md-6 mb-3">
                <div class="form-outline">
                    <select data-mdb-select-init class="form-select" name="destaque" id="selectDestaque">
                        <option value="nacional" <cfif qEvento.destaque EQ "nacional">selected</cfif>>Nacional</option>
                        <option value="estadual" <cfif qEvento.destaque EQ "estadual">selected</cfif>>Estadual</option>
                        <option value="" <cfif Len(trim(qEvento.destaque)) EQ 0>selected</cfif>>Não</option>
                    </select>
                    <label class="form-label select-label">Evento em Destaque no RR</label>
                </div>
            </div>

            <div class="col-md-6 mb-3">
                <div class="form-outline">
                    <select data-mdb-select-init class="form-select" name="ativo" id="selectAtivo">
                        <option value="1" <cfif qEvento.ativo EQ true>selected</cfif>>Sim</option>
                        <option value="0" <cfif qEvento.ativo EQ false>selected</cfif>>Não</option>
                    </select>
                    <label class="form-label select-label">Evento Ativo</label>
                </div>
            </div>

            <div class="col-md-6 mb-3">
                <div data-mdb-input-init class="form-outline">
                    <input type="text" class="form-control pt-3" maxlength="128" id="txtInfoDuplicadoo" name="info_duplicado" value="<cfoutput>#qEvento.info_duplicado#</cfoutput>"/>
                    <label class="form-label" for="txtInfoDuplicadoo">Info Duplicado</label>
                </div>
            </div>

            <div class="col-md-6 mb-3">
                <div data-mdb-input-init class="form-outline">
                    <input type="text" class="form-control pt-3" maxlength="128" id="txtStatusEvento" name="status_evento" value="<cfoutput>#qEvento.status_evento#</cfoutput>"/>
                    <label class="form-label" for="txtInfoDuplicadoo">Status do Evento (cancelado, adiado)</label>
                </div>
            </div>

            <hr class="mb-3"/>

            <div class="col-md-12 mb-3">
                <div class="form-outline">
                    <select data-mdb-select-init class="form-select" name="id_agrega_evento" id="selectAgrega">
                        <option value="">Selecione um Evento</option>
                        <cfoutput query="qAgrega">
                            <option value="#qAgrega.id_agrega_evento#" <cfif qEvento.id_agrega_evento EQ qAgrega.id_agrega_evento>selected</cfif>>#uCase(qAgrega.tipo_agregacao)# - #qAgrega.nome_evento_agregado#</option>
                        </cfoutput>
                    </select>
                    <label class="form-label select-label">Eventos Grandes e Circuitos</label>
                </div>
            </div>

            <div class="col-md-12 mb-3">
                <div class="form-outline">
                    <select data-mdb-select-init class="form-select" name="id_tema" id="selectTema">
                        <cfoutput query="qTema">
                            <option value="#qTema.id_tema#" <cfif qEvento.id_tema EQ qTema.id_tema>selected</cfif>>#uCase(qTema.logo)#</option>
                        </cfoutput>
                    </select>
                    <label class="form-label select-label">Tema</label>
                </div>
            </div>

        </div>

        <div class="row">

            <div class="col-md-12">
                <input type="hidden" name="action" value="editar_evento_configuracoes"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100">Salvar Configurações</button>
            </div>

        </div>

    </form>

    <hr class="my-3"/>

    <cfquery name="qFornecedores">
        select agevt.agregador_tag, agr.agregador_nome from tb_agregadores_eventos agevt inner join tb_agregadores agr ON agr.agregador_tag = agevt.agregador_tag
        where agevt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        ORDER BY agevt.agregador_tag
    </cfquery>

    <cfquery name="qListaFornecedores">
        select * from tb_agregadores
        ORDER BY agregador_tag
    </cfquery>

    <!--- CAMPOS DE FORNECEDORES --->
    <cfset arrFornecedores = []/>

    <!--- FORNECEDORES EXISTENTES --->
    <cfloop query="qFornecedores">
        <cfset registro = arrayAppend(arrFornecedores, {agregador_tag:qFornecedores.agregador_tag}, true)/>
    </cfloop>

    <!--- CALCULANDO CAMPOS ADICIONAIS VAZIOS --->
    <cfset camposAdicionais = 1/>
    <cfif camposAdicionais + arraylen(arrFornecedores) LT 2>
        <!---cfset camposAdicionais = 2/--->
    </cfif>

    <!--- CRIANDO CAMPOS VAZIOS --->
    <cfloop from="1" to="#camposAdicionais#" index="index">
        <cfset registro = arrayAppend(arrFornecedores, {agregador_tag:''}, true)/>
    </cfloop>

    <form class="form" method="post">

        <cfloop array="#arrFornecedores#" index="item">

            <div class="row mb-3">

                <div class="col-md-12">
                    <select class="form-select" name="agregador_tag" id="selectAgregadorTag">
                        <option value="">Selecionar Agregador de Evento</option>
                        <cfoutput query="qListaFornecedores">
                            <option value="#qListaFornecedores.agregador_tag#" <cfif item.agregador_tag EQ qListaFornecedores.agregador_tag>selected</cfif>>#qListaFornecedores.agregador_nome#</option>
                        </cfoutput>
                    </select>
                </div>

            </div>

        </cfloop>

        <div class="row">

            <div class="col-md-12">
                <input type="hidden" name="action" value="editar_evento_agregadores"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100">Vincular Evento</button>
            </div>

        </div>

    </form>


    <hr class="my-5"/>

    <div class="row">

        <div class="col-md-12">
            <form class="form" method="post">
                <p class="text-danger-emphasis">ATENÇÃO: A exclusão do evento é permanente.</p>
                <input type="checkbox" name="aceite" value="true"/> &nbsp; Desejo também excluir dados de resultados do evento
                <br/>
                <br/>
                <input type="hidden" name="action" value="excluir_evento"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-danger w-100">Excluir Evento</button>
            </form>
        </div>

    </div>

</div>
