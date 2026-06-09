<div class="tab-pane fade <cfif URL.sessao EQ "fornecedores">show active</cfif>" id="ex1-tabs-2" role="tabpanel" aria-labelledby="ex1-tab-2" tabindex="1">

    <cfquery name="qFornecedores">
        select descricao_tipo, cfo.id_fornecedor, cfo.id_fornecedor_tipo, nome_fornecedor
        from tb_evento_corridas_fornecedores cfo
        inner join tb_fornecedores_tipos tip on cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
        inner join tb_fornecedores cor on cfo.id_fornecedor = cor.id_fornecedor and cfo.id_fornecedor_tipo = tip.id_fornecedor_tipo
        where cfo.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
        ORDER BY tip.id_fornecedor_tipo
    </cfquery>

    <cfquery name="qListaFornecedores">
        SELECT id_fornecedor, nome_fornecedor from tb_fornecedores
        ORDER BY nome_fornecedor
    </cfquery>

    <cfquery name="qListaTipoFornecedores">
        SELECT id_fornecedor_tipo, descricao_tipo from tb_fornecedores_tipos
    </cfquery>

    <cfif len(trim(qEvento.organizador))><p><cfoutput>Organizador: #qEvento.organizador#</cfoutput></p></cfif>
    <cfif len(trim(qEvento.url_resultado))><p><cfoutput>Timer: #rereplace(qEvento.url_resultado, "^\w+://([^\/:]+)[\w\W]*$", "\1", "one")#</cfoutput></p></cfif>

    <!--- CAMPOS DE FORNECEDORES --->
    <cfset arrFornecedores = []/>

    <!--- FORNECEDORES EXISTENTES --->
    <cfloop query="qFornecedores">
        <cfset registro = arrayAppend(arrFornecedores, {id_fornecedor:qFornecedores.id_fornecedor, id_fornecedor_tipo:qFornecedores.id_fornecedor_tipo}, true)/>
    </cfloop>

    <!--- CALCULANDO CAMPOS ADICIONAIS VAZIOS --->
    <cfset camposAdicionais = 1/>
    <cfif camposAdicionais + arraylen(arrFornecedores) LT 2>
        <cfset camposAdicionais = 2/>
    </cfif>

    <!--- CRIANDO CAMPOS VAZIOS --->
    <cfloop from="1" to="#camposAdicionais#" index="index">
        <cfset registro = arrayAppend(arrFornecedores, {id_fornecedor:'', id_fornecedor_tipo:''}, true)/>
    </cfloop>

    <form class="form" method="post">

        <cfloop array="#arrFornecedores#" index="item">

            <div class="row mb-3">

                <div class="col-md-12">
                    <div class="row">
                        <div class="col-md-6">
                            <select class="form-select" name="id_fornecedor" id="selectIdFornecedor">
                                <option value="">Empresa</option>
                                <cfoutput query="qListaFornecedores">
                                    <option value="#qListaFornecedores.id_fornecedor#" <cfif item.id_fornecedor EQ qListaFornecedores.id_fornecedor>selected</cfif>>#qListaFornecedores.nome_fornecedor#</option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <select class="form-select" name="id_fornecedor_tipo" id="selectIdTipoFornecedor">
                                <option value="">Tipo</option>
                                <cfoutput query="qListaTipoFornecedores">
                                    <option value="#qListaTipoFornecedores.id_fornecedor_tipo#" <cfif item.id_fornecedor_tipo EQ qListaTipoFornecedores.id_fornecedor_tipo>selected</cfif>>#qListaTipoFornecedores.descricao_tipo#</option>
                                </cfoutput>
                            </select>
                        </div>
                    </div>
                </div>

            </div>

        </cfloop>

        <div class="row">

            <div class="col-md-12">
                <input type="hidden" name="action" value="editar_evento_fornecedores"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100">Salvar Fornecedores</button>
            </div>

        </div>

    </form>

    <hr class="my-4"/>

    <cfquery name="qModalidades">
        SELECT prc.* FROM tb_evento_corridas_percursos prc
        WHERE prc.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    </cfquery>

    <cfquery name="qFRGeral">
        SELECT * from tb_badges
        WHERE badge = 'foco' AND percurso = 0
        AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
    </cfquery>

    <form class="form" method="post">

        <div class="row">

            <div class="col-md-6">

                <div class="input-group mb-3">
                      <div data-mdb-input-init class="form-outline">
                        <input type="text" class="form-control pt-3" readonly style="background: transparent;" maxlength="16" id="txtFoco" name="valor_badge" value="<cfoutput>#qFRGeral.valor_badge#</cfoutput>"/>
                        <label class="form-label" for="txtFoco">Competition ID Foco Radical</label>
                    </div>
                    <cfif len(trim(qFRGeral.valor_badge))>
                        <a target="_blank" href="<cfoutput>#qFRGeral.valor_badge#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                            Abrir Link
                        </a>
                    </cfif>
                </div>
            </div>

            <div class="col-md-6">
                <input type="hidden" name="action" value="editar_evento_competition_id"/>
                <input type="hidden" name="id_evento" value="<cfoutput>#qEvento.id_evento#</cfoutput>"/>
                <button type="submit" class="btn btn-primary w-100" style="padding-top:14px; padding-bottom:14px;" disabled data-mdb-ripple-init>Salvar ID</button>
            </div>

        </div>

    </form>

    <div class="row">
        <div class="col-md-12">
            <a target="_blank" class="btn btn-outline-primary me-2" href="https://runnerhub.run/api/foco/eventos.cfm?id_evento=<cfoutput>#qEvento.id_evento#</cfoutput>">Verificar API</a>
        </div>
    </div>

    <script>
        function getFornecedores() {
            $.getJSON("/api/Evento.cfc?method=getCidades&uf=" + $("#selectEstado").val() + "&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23", function(result) {
                var $dropdown = $("#selectCidade").find('option').remove().end();
                $.each(result.data, function() {
                    $dropdown.append($("<option />").val(this.cod_cidade).text(this.nome_cidade));
                });
            });
        }
    </script>

</div>
