<cfif Len(trim(URL.id_evento))>

    <div class="col-md-6">

        <div class="card">

            <div class="card-header pb-0">
                <h6 class="float-start"><cfif qEvento.recordcount><cfoutput>#qEvento.nome_evento#</cfoutput><cfelse>NOVO EVENTO</cfif></h6>
                <h5 class="float-end"><a href="<cfoutput>#VARIABLES.template#?periodo=#URL.periodo#&preset=#URL.preset#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">X</a></h5>
            </div>

            <div class="card-body p-3 g-3">

                <!--- ABAS --->

                <cfif Len(trim(URL.id_evento)) and URL.id_evento NEQ 0>

                    <ul class="nav nav-tabs mb-3" id="ex1" role="tablist">
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "dados">active</cfif> px-3" id="ex1-tab-1" href="#ex1-tabs-1" role="tab" aria-controls="ex1-tabs-1" aria-selected="true">Dados</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "forncedores">active</cfif> px-3" id="ex1-tab-2" href="#ex1-tabs-2" role="tab" aria-controls="ex1-tabs-2" aria-selected="false">Fornecedores</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "conteudo">active</cfif> px-3" id="ex1-tab-3" href="#ex1-tabs-3" role="tab" aria-controls="ex1-tabs-3" aria-selected="false">Conteúdo</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "percursos">active</cfif> px-3" id="ex1-tab-4" href="#ex1-tabs-4" role="tab" aria-controls="ex1-tabs-4" aria-selected="false">Percursos</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "configuracoes">active</cfif> px-3" id="ex1-tab-5" href="#ex1-tabs-5" role="tab" aria-controls="ex1-tabs-5" aria-selected="false">Configurações</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a data-mdb-tab-init class="nav-link <cfif URL.sessao EQ "or">active</cfif> px-3" id="ex1-tab-6" href="#ex1-tabs-6" role="tab" aria-controls="ex1-tabs-6" aria-selected="false">OR</a>
                        </li>
                    </ul>

                </cfif>


                <!--- CONTEUDO DAS ABAS --->

                <div class="tab-content pt-2" id="ex1-content">


                    <!--- DADOS PRINCIPAIS --->

                    <div class="tab-pane fade <cfif URL.sessao EQ "dados">show active</cfif>" id="ex1-tabs-1" role="tabpanel" aria-labelledby="ex1-tab-1" tabindex="0">

                        <cfquery name="qEstados">
                            SELECT DISTINCT uf from tb_cidades ORDER BY uf
                        </cfquery>

                        <cfquery name="qCidades">
                            SELECT cod_cidade, nome_cidade
                            FROM tb_cidades
                            where uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.estado#"/>
                            order by nome_cidade
                        </cfquery>

                        <form class="form" method="post">

                            <div class="row">

                                <div class="col-md-4 mb-3">
                                    <div class="form-outline">
                                        <select data-mdb-select-init class="form-select" name="tipo_corrida" id="selectTipoCorrida">
                                            <option value="rua" <cfif qEvento.tipo_corrida EQ "rua">selected</cfif>>Rua</option>
                                            <option value="trail" <cfif qEvento.tipo_corrida EQ "trail">selected</cfif>>Trail</option>
                                            <option value="treino" <cfif qEvento.tipo_corrida EQ "treino">selected</cfif>>Treino</option>
                                        </select>
                                        <label class="form-label select-label">Tipo de Corrida</label>
                                    </div>
                                </div>

                                <div class="col-md-4 mb-3">
                                    <div class="form-outline" data-mdb-input-init>
                                        <input type="text" class="form-control" id="dataInicial" name="data_inicial" placeholder="aaaa-mm-dd" value="<cfoutput>#qEvento.data_inicial#</cfoutput>" />
                                        <label for="dataInicial" class="form-label">Data Inicial</label>
                                    </div>
                                </div>

                                <div class="col-md-4 mb-3">
                                    <div class="form-outline" data-mdb-input-init>
                                        <input type="text" class="form-control" id="dataFinal" name="data_final" placeholder="aaaa-mm-dd" value="<cfoutput>#qEvento.data_final#</cfoutput>" />
                                        <label for="dataFinal" class="form-label">Data Final</label>
                                    </div>
                                </div>

                            </div>

                            <div data-mdb-input-init class="form-outline mb-3">
                                <input type="text" class="form-control pt-3" maxlength="128" id="txtNomeEvento" name="nome_evento" value="<cfoutput>#qEvento.nome_evento#</cfoutput>" onblur="getTag()"/>
                                <label class="form-label" for="txtNomeEvento">Nome do Evento</label>
                            </div>

                            <div class="input-group mb-3">
                                  <div data-mdb-input-init class="form-outline">
                                    <input type="text" class="form-control pt-3" maxlength="512" id="txtTagEvento" name="tag" value="<cfoutput>#qEvento.tag#</cfoutput>"/>
                                    <label class="form-label" for="txtTagEvento">Tag</label>
                                </div>
                                <cfif len(trim(qEvento.tag))>
                                    <a target="_blank" href="https://roadrunners.run/evento/<cfoutput>#qEvento.tag#</cfoutput>/" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                                        Abrir Link
                                    </a>
                                </cfif>
                            </div>

                            <div class="row">

                                <div class="col-md-3 mb-3">
                                    <div class="form-outline">
                                        <select data-mdb-select-init class="form-select pt-3" name="estado" id="selectEstado" onchange="getCidades()">
                                            <option value="">Estado</option>
                                            <cfoutput query="qEstados">
                                                <option value="#qEstados.uf#" <cfif qEvento.estado EQ qEstados.uf>selected</cfif>>#qEstados.uf#</option>
                                            </cfoutput>
                                        </select>
                                        <label class="form-label select-label">Estado</label>
                                    </div>
                                </div>

                                <div class="col-md-9 mb-3">
                                    <div class="form-outline">
                                        <select data-mdb-select-init data-mdb-filter="true" class="form-select pt-3" name="cidade" id="selectCidade">
                                            <option value="">Cidade</option>
                                            <cfoutput query="qCidades">
                                                <option value="#qCidades.cod_cidade#" <cfif qEvento.cidade EQ qCidades.nome_cidade>selected</cfif>>#qCidades.nome_cidade#</option>
                                            </cfoutput>
                                        </select>
                                        <label class="form-label select-label">Cidade</label>
                                    </div>
                                </div>

                            </div>

                            <div class="row">

                                <div class="col-md-7 mb-3">
                                    <div data-mdb-input-init class="form-outline">
                                        <input type="text" class="form-control pt-3" id="txtEndereco" name="endereco" value="<cfoutput>#qEvento.endereco#</cfoutput>" />
                                        <label for="txtEndereco" class="form-label">Endereço</label>
                                    </div>
                                </div>

                                <div class="col-md-5 mb-3">
                                    <div data-mdb-input-init class="form-outline">
                                        <input type="text" class="form-control pt-3" id="txtCoordenadas" name="coordenadas" value="<cfoutput>#qEvento.coordenadas#</cfoutput>" />
                                        <label for="txtCoordenadas" class="form-label">Coordenadas</label>
                                    </div>
                                </div>

                            </div>

                            <hr class="mt-0"/>

                            <div class="input-group mb-3">
                                  <div data-mdb-input-init class="form-outline">
                                    <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlInscricao" name="url_inscricao" value="<cfoutput>#qEvento.url_inscricao#</cfoutput>"/>
                                    <label class="form-label" for="txtUrlInscricao">URL de Inscrição</label>
                                </div>
                                <cfif len(trim(qEvento.url_inscricao))>
                                    <a target="_blank" href="<cfoutput>#qEvento.url_inscricao#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                                        Abrir Link
                                    </a>
                                </cfif>
                            </div>

                            <div class="input-group mb-3">
                                  <div data-mdb-input-init class="form-outline">
                                    <input type="text" class="form-control pt-3" maxlength="512" id="txtUrlWebsite" name="url_hotsite" value="<cfoutput>#qEvento.url_hotsite#</cfoutput>"/>
                                    <label class="form-label" for="txtUrlWebsite">URL do Site Oficial</label>
                                </div>
                                <cfif len(trim(qEvento.url_hotsite))>
                                    <a target="_blank" href="<cfoutput>#qEvento.url_hotsite#</cfoutput>" class="btn btn-outline-secondary" type="button" data-mdb-ripple-init data-mdb-ripple-color="dark">
                                        Abrir Link
                                    </a>
                                </cfif>
                            </div>

                            <div class="row">

                                <div class="col-md-12">
                                    <input type="hidden" name="action" value="editar_evento_basico"/>
                                    <input type="hidden" name="id_evento" value="<cfoutput>#URL.id_evento#</cfoutput>"/>
                                    <button type="submit" class="btn btn-primary w-100">Salvar Dados Básicos</button>
                                </div>

                            </div>

                        </form>

                        <script>
                            function getCidades() {
                                $.getJSON("/api/Evento.cfc?method=getCidades&uf=" + $("#selectEstado").val() + "&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23", function(result) {
                                    var $dropdown = $("#selectCidade").find('option').remove().end();
                                    $.each(result.data, function() {
                                        $dropdown.append($("<option />").val(this.cod_cidade).text(this.nome_cidade));
                                    });
                                    mdb.Select.getInstance(document.getElementById("selectCidade")).dispose();
                                    new mdb.Select(document.getElementById("selectCidade"));
                                });
                            }
                            function getTag() {
                                if ($("#txtTagEvento").val().length === 0) {
                                    $.getJSON("/api/Evento.cfc?method=getTag&nome_evento=" + $("#txtNomeEvento").val() + "&data_final=" + $("#dataFinal").val() + "&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23", function(result) {
                                        console.log(result.data);
                                        $("#txtTagEvento").val(result.data);
                                    });
                                }
                            }
                        </script>

                    </div>


                    <cfif Len(trim(URL.id_evento)) and URL.id_evento NEQ 0>


                    <!--- FORNECEDORES --->

                    <cfinclude template="form_edicao_fornecedores.cfm"/>


                    <!--- DESCRICAO --->

                    <cfinclude template="form_edicao_conteudo.cfm"/>


                    <!--- PERCURSOS --->

                    <cfinclude template="form_edicao_percursos.cfm"/>


                    <!--- CONFIGURACOES --->

                    <cfinclude template="form_edicao_configuracoes.cfm"/>


                    <!--- OR --->

                    <cfinclude template="form_edicao_or.cfm"/>


                    <!---
                                        <div class="tab-pane fade" id="pd_imagens" role="tabpanel" aria-labelledby="pd_imagens_tab">

                                            <div class="row">

                                                <div class="col-md-12">
                                                    <div class="card mb-3">
                                                        <div class="card-header fw-bold">Upload Vídeos</div>
                                                        <div class="card-body">
                                                            <iframe src="https://www.youtube.com/embed/<cfoutput>#qYoutube.media_url#</cfoutput>" class="col mx-12" style="height: 300px;width: 450px;" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

                                                            <form method="post">

                                                                <div class="form-group row mb-3">
                                                                    <label class="col-sm-4 col-form-label">URL</label>
                                                                    <div class="col-sm-8">
                                                                        <input class="form-control" type="text" placeholder="URL da mídia" name="media_url"/>
                                                                    </div>
                                                                </div>

                                                                <div class="form-group row mb-3">
                                                                    <label class="col-sm-4 col-form-label">Tipo</label>
                                                                    <div class="col-sm-8">
                                                                        <input class="form-control" type="text" placeholder="Tipo" name="media_tipo" value="codigo_youtube"/>
                                                                    </div>
                                                                </div>

                                                                <div class="form-group row mb-3">
                                                                    <label class="col-sm-4 col-form-label"></label>
                                                                <div class="col-sm-8">
                                                                    <input type="hidden" name="action" value="adicionarmidia"/>
                                                                    <input type="hidden" name="id_tenis" value="<cfoutput>#qEvento.id_tenis#</cfoutput>"/>
                                                                    <button class="btn btn-primary w-100" type="submit">Salvar</button>
                                                                </div>
                                                                </div>

                                                            </form>
                                                        </div>
                                                    </div>
                                                </div>

                                            </div>

                                            <div class="row">

                                                <div class="col-md-12">
                                                    <div class="card mb-3">
                                                <div class="card-header fw-bold">Imagens</div>
                                                <div class="card-body">

                                                <div class="tab-content" id="nav-tabContent">

                                                <cfloop query="qGenero">
                                                    <div class="row">

                                                        <img src="<cfoutput>/assets/images/#qGenero.media_url#</cfoutput>" class="col mx-12 img-tenis"  alt="" style="height: 300px;"/>
                                                        <div style="padding-top: 20px"></div>

                                                    </div>

                                                </cfloop>

                                                </div>

                                                </div>
                                                </div>
                                                    <button type="submit" class="btn btn-sm btn-primary">Salvar</button>
                                                </div>

                                            </div>

                                        </div>


                                        --->


                    <!--- UPLOAD DE IMAGEM

                    <div style="width: 100%; height: 60px; text-align: center; background: grey" id="pasteTarget">
                        Cole a imagem aqui
                    </div>

                    <hr/>

                     --->

                    </cfif>

                </div>


            </div>

        </div>

    </div>


    <!--- UPLOAD DE IMAGEMS --->

    <!---cfif qEvento.recordcount>

        <script type="text/javascript">

            document.addEventListener("DOMContentLoaded", function() {
                var pasteTarget = document.getElementById("pasteTarget");

                pasteTarget.addEventListener("paste", handlePaste);
            });

            function handlePaste(e) {
                for (var i = 0 ; i < e.clipboardData.items.length ; i++) {
                    var item = e.clipboardData.items[i];
                    console.log("Item type: " + item.type);
                    if (item.type.indexOf("image") != -1) {
                        uploadFile(item.getAsFile(), 'M');
                    } else {
                        alert("Discarding non-image paste data");
                    }
                }
            }

            function uploadFile(file, genero) {
                var xhr = new XMLHttpRequest();

                xhr.upload.onprogress = function(e) {
                    var percentComplete = (e.loaded / e.total) * 100;
                    console.log("Uploaded: " + percentComplete + "%");
                };

                xhr.onload = function() {
                    if (xhr.status == 200) {
                        window.location.reload();
                    } else {
                        alert("Error! Upload failed");
                    }
                };

                xhr.onerror = function() {
                    alert("Error! Upload failed. Can not connect to server.");
                };

                xhr.open("POST", "../assets/images/upload.cfm?id_evento=<cfoutput>#URL.id_evento#</cfoutput>&genero=" + genero, true);
                xhr.setRequestHeader("Content-Type", file.type);
                xhr.send(file);
            }

        </script>

    </cfif--->

</cfif>



