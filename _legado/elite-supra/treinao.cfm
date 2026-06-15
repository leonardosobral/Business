<!--- WIDGETS PRESETS --->

<div class="row g-3 mb-3 d-none d-md-flex d-print-none">

    <div class="col">
        <a href="./">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qBaseInscritos.recordCount, "9")#</cfoutput></p>
            <p class="m-0">Inscritos</p>
        </div>
        </a>
    </div>

    <div class="col d-none d-md-block">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=calendario">
        <div class="card bg-43k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCalendario.recordCount*100)/qBaseInscritos.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCountCalendario.recordCount, "9")#</cfoutput> com Calendário</p>
        </div>
        </a>
    </div>
    <div class="col d-none d-md-block">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=resultados">
        <div class="card bg-43k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCountResultados.recordCount*100)/qBaseInscritos.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCountResultados.recordCount, "9")#</cfoutput> com Resultados</p>
        </div>
        </a>
    </div>
    <div class="col d-none d-md-block">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=strava">
        <div class="card bg-strava py-2 px-3">
            <div class="d-flex">
                <i class="fa-brands fa-strava h1 me-2"></i>
                <div class="col">
                    <p class="h4 m-0"><cfoutput>#numberFormat(((qCountStrava.recordCount*100)/qBaseInscritos.recordCount), "9")#%</cfoutput></p>
                    <p class="m-0"><cfoutput>#numberFormat(qCountStrava.recordCount, "9")#</cfoutput> com Strava</p>
                </div>
            </div>
        </div>
        </a>
    </div>
    <div class="col d-none d-md-block">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=assessoria">
        <div class="card bg-43k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCountAssessoria.recordCount*100)/qBaseInscritos.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCountAssessoria.recordCount, "9")#</cfoutput> com Assessoria</p>
        </div>
        </a>
    </div>

</div>


<!--- WIDGETS STRAVA --->

<cfif URL.preset EQ "strava">

<div class="row g-3 mb-3 d-none d-md-flex d-print-none">

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(((qStravaPremium.recordCount*100)/qCountStrava.recordCount), "9.9")#%</cfoutput> premium</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(qStravaWeight.strava_weight, "9.9")#kg</cfoutput> peso/usu</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(qStravaFollowers.strava_full_follower_count, "9")#</cfoutput> followers/usu</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(qStravaFriends.strava_full_friend_count, "9")#</cfoutput> friends/usu</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(VARIABLES.shoeCount/qStravaShoes.recordCount, "9.9")#</cfoutput> tênis/usu</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(VARIABLES.shoeKm/VARIABLES.shoeCount, "9.9")#</cfoutput> km/tênis</p>
            </div>
        </div>

        <div class="col">
            <div class="card bg-strava text-black py-2 px-3">
                <p class="m-0"><cfoutput>#numberFormat(VARIABLES.clubCount/qStravaClubs.recordCount, "9.9")#</cfoutput> clubs/usu</p>
            </div>
        </div>

    </div>

</cfif>


<!--- FILTROS BUSCA

<div class="row my-3">

    <div class="col">

        <form action="" method="get">
            <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
            <input type="hidden" name="preset" value=""/>
        </form>

    </div>

</div>

 --->


<!--- ESTATISTICAS --->

<div class="row g-3">

    <cfset eventosMap = {
    01 = "Maratona Intl. de Porto Alegre",
    02 = "Maratona do Rio de Janeiro",
    03 = "SP City Marathon",
    04 = "Maratona Intl. de João Pessoa",
    05 = "Maratona Intl. de Floripa",
    06 = "Maratona Intl. de Goiânia",
    07 = "Maratona de Salvador",
    08 = "Maratona Monumental de Brasília",
    09 = "Maratona de Curitiba",
    10 = "Maratona Intl. de São Paulo"
    }
    />

    <div class="col-md-4 d-print-none">

        <div class="row g-3 d-none d-md-flex">

            <!--- LISTAGEM DE REGIAO --->

            <div class="col-md-8">

                <div class="card">

                    <div class="card-header px-3 py-2">Por Região</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper">

                            <table id="tblEventos" class="table table-stripped table-hovered table-condensed table-sm mb-0" >
                                <cfoutput query="qStatsRegiao">
                                    <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = '././?preset=#URL.preset#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
                                        <td>#qStatsRegiao.regiao#</td>
                                        <td>#qStatsRegiao.total#</td>
                                    </tr>
                                </cfoutput>
                            </table>

                        </div>

                    </div>

                </div>

            </div>

            <!--- LISTAGEM DE UF --->

            <div class="col-md-4">

                <div class="card">

                    <div class="card-header px-3 py-2">Por UF</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper">

                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                <cfoutput query="qStatsEstado">
                                    <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
                                        <td>#qStatsEstado.estado#</td>
                                        <td>#qStatsEstado.total#</td>
                                    </tr>
                                </cfoutput>
                            </table>

                        </div>

                    </div>

                </div>

            </div>

            <!--- LISTAGEM DE CIDADE --->

            <div class="col-md-12">

                <div class="card">

                    <div class="card-header px-3 py-2">Por Cidade</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper-sm">

                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                <cfoutput query="qStatsCidade">
                                    <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
                                        <td>#qStatsCidade.cidade# - #qStatsCidade.estado#</td>
                                        <td>#qStatsCidade.total#</td>
                                    </tr>
                                </cfoutput>
                            </table>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </div>

    <div class="col-md-8">

        <div class="row g-3">

            <!--- LISTAGEM --->

            <div class="col-md-12">

                <!---RELATORIO IMPRESSO--->

                <div class="d-none d-print-block">
                    <cfoutput query="qStatsEvento">
                    <h2 class="text-center">Desafio Corre Supra 2025</h2>
                    <h4 class="text-center MB-5">Relatório de inscritos</h4>
                    <cfset dados = deserializeJSON(qStatsEvento.body)/>
                        <div class="row border border-1 mb-3">
                            <h5 class="bg-black bg-opacity-10 text-capitalize">#lCase(dados.nome_completo)#</h5>
                            <div class="col-2">Registro CBAt</div><div class="col-4">#dados.cbat#</div>
                            <div class="col-2">CPF</div><div class="col-4">#dados.documento#</div>
                            <div class="col-2">Email</div><div class="col-4">#qStatsEvento.email#</div>
                            <div class="col-2">Cel/WhatsApp</div><div class="col-4">#dados.celular#</div>
                            <div class="col-2">Data de nasc.</div><div class="col-4">#dados.nascimento#</div>
                            <div class="col-2">Gênero</div><div class="col-4">#dados.genero#</div>
                            <div class="col-2">Equipe</div><div class="col-4">#dados.equipe#</div>
                            <div class="col-2">Instagram</div><div class="col-4">#dados.instagram#</div>
                            <hr class="my-1 opacity-10"/>
                            <div class="col-2">Endereço</div><div class="col-4">#dados.endereco#</div>
                            <div class="col-2">Número</div><div class="col-4">#dados.numero#</div>
                            <div class="col-2">Complemento</div><div class="col-4">#dados.complemento#</div>
                            <div class="col-2">Bairro</div><div class="col-4">#dados.bairro#</div>
                            <div class="col-2">Cidade</div><div class="col-4">#dados.cidade#</div>
                            <div class="col-2">UF</div><div class="col-4">#dados.UF#</div>
                            <div class="col-2">CEP</div><div class="col-4">#dados.CEP#</div>
                            <hr class="my-1 opacity-10"/>
                            <div class="col-2">Apoiado</div><div class="col-4">#dados.marcas#</div>
                            <div class="col-2">Marcas</div><div class="col-4">#dados.marca#</div>
                            <div class="col-2">Tam. calçado</div><div class="col-4">#dados.calcado#</div>
                            <div class="col-2">Tam. vestuário</div><div class="col-4">#dados.vestuario#</div>
                            <div class="col-2">Tam. top</div><div class="col-4">#dados.top#</div>
                            <div class="col-2">Tam. calça</div><div class="col-4">#dados.calca#</div>
                            <hr class="my-1 opacity-10"/>
                            <div class="col-2">RP nos 42k</div><div class="col-4">#dados.rp42#</div>
                            <div class="col-2">Prova do RP</div><div class="col-4">#dados.rp42prova#</div>
                            <div class="col-2">Provas que fará</div><div class="col-4">#dados.provas#</div>
                            <div class="col-2">Inscrito Desafio</div><div class="col-4">#qStatsEvento.data_inscricao#</div>
                        </div>
                        <footer class="container-fluid text-center text-lg-start">
                            <div id="sticky-stop" class="row my-3">
                                <div class="col-lg-6 text-center text-lg-start"><img src="/assets/rh_grafite.png" class="w-100px" alt="Logo do RunnerHub"></div>
                                <div class="col-lg-6 small text-center text-lg-end">
                                    <img src="/assets/br.png" style="height: 8px; vertical-align: baseline;" alt="Feito no Brasil"> RunnerHub Inteligência Esportiva
                                </div>
                            </div>
                        </footer>
                        <div style="page-break-after: always"></div>
                    </cfoutput>
                </div>

                <!---RELATORIO XML--->

                <div class="d-none d-print-none">
                    <table id="relatorioSupra">
                        <tr>
                            <th>Nome</th>
                            <th>Registro CBAt</th>
                            <th>CPF</th>
                            <th>Email</th>
                            <th>Cel/WhatsApp</th>
                            <th>Data de nasc.</th>
                            <th>Gênero</th>
                            <th>Equipe</th>
                            <th>Instagram</th>
                            <th>Endereço</th>
                            <th>Número</th>
                            <th>Complemento</th>
                            <th>Bairro</th>
                            <th>Cidade</th>
                            <th>UF</th>
                            <th>CEP</th>
                            <th>Apoiado</th>
                            <th>Marcas</th>
                            <th>Tam. calçado</th>
                            <th>Tam. vestuário</th>
                            <th>Tam. top</th>
                            <th>Tam. calça</th>
                            <th>RP nos 42k</th>
                            <th>Prova do RP</th>
                            <th>Provas que fará</th>
                        </tr>
                        <cfoutput query="qStatsEvento">
                            <cfset dados = deserializeJSON(qStatsEvento.body)/>
                            <tr>
                                <td>#dados.nome_completo#</td>
                                <td>#dados.cbat#</td>
                                <td>#dados.documento#</td>
                                <td>#qStatsEvento.email#</td>
                                <td>#dados.celular#</td>
                                <td>#dados.nascimento#</td>
                                <td>#dados.genero#</td>
                                <td>#dados.equipe#</td>
                                <td>#dados.instagram#</td>
                                <td>#dados.endereco#</td>
                                <td>#dados.numero#</td>
                                <td>#dados.complemento#</td>
                                <td>#dados.bairro#</td>
                                <td>#dados.cidade#</td>
                                <td>#dados.UF#</td>
                                <td>#dados.CEP#</td>
                                <td>#dados.marcas#</td>
                                <td>#dados.marca#</td>
                                <td>#dados.calcado#</td>
                                <td>#dados.vestuario#</td>
                                <td>#dados.top#</td>
                                <td>#dados.calca#</td>
                                <td>#dados.rp42#</td>
                                <td>#dados.rp42prova#</td>
                                <td>
                                    <cfset provasArray = dados.provas />
                                    <cfif isArray(dados.provas)>
                                        <cfset provasArray = dados.provas>
                                        <cfelseif isSimpleValue(dados.provas) AND listLen(dados.provas) GT 0>
                                        <cfset provasArray = listToArray(dados.provas)>
                                    <cfelse>
                                        <cfset provasArray = []>
                                    </cfif>

                                    <cfif arrayLen(provasArray)>
                                        <cfloop array="#provasArray#" index="prova">
                                            <cfif structKeyExists(eventosMap, prova)>
                                                #prova# - #eventosMap[prova]# <br/>
                                            <cfelse>
                                                #prova# - Evento desconhecido
                                            </cfif>
                                        </cfloop>
                                    <cfelse>
                                        Nenhuma prova informada.
                                    </cfif>

                                </td>
                            </tr>
                        </cfoutput>
                    </table>
                </div>

                <!---LISTAGEM NA TELA--->

                <div class="card d-print-none">

                    <div class="card-header px-3 py-2">
                        Atletas <cfoutput>(#qStatsEvento.recordcount#)</cfoutput>
                        <!---<a class="float-end px-1" onclick="window.print()" href="#"><i class="fa-solid fa-print"></i></a>--->
                        <a class="float-end px-1" id="exporta-relatorio" href="#"><i class="fa-solid fa-download"></i></a>
                    </div>

                    <div class="card-body p-2">

                        <div class="accordion accordion-flush" id="accordion">
                            <cfset atleta = 0 />
                            <cfoutput query="qStatsEvento">
                            <cfquery name="qObsDesafio">
                                SELECT obs.*, usr.name
                                FROM desafios_obs obs
                                INNER JOIN tb_usuarios usr ON obs.id_atendente = usr.id
                                WHERE obs.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStatsEvento.id#"/>
                                ORDER BY obs.data_obs DESC
                            </cfquery>
                            <cfset dados = deserializeJSON(qStatsEvento.body)/>
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="heading#atleta++#">
                                    <button
                                            data-mdb-collapse-init
                                            class="accordion-button collapsed
                                                        <cfif qStatsEvento.status EQ "sem_cbat" OR qStatsEvento.status EQ "outra_marca">bg-danger bg-opacity-50 opacity-50</cfif>
                                                        <cfif qStatsEvento.status EQ "aguardando_cbat" OR qStatsEvento.status EQ "aguardando_comprovante">bg-warning bg-opacity-25</cfif>
                                                        <cfif qStatsEvento.status EQ "nao_enviar" OR qStatsEvento.status EQ "enviar" OR qStatsEvento.status EQ "enviado">bg-success bg-opacity-25</cfif>
                                                        text-dark p-2 "
                                            type="button"
                                            data-mdb-target="##tab#atleta#"
                                            aria-expanded="false"
                                            aria-controls="tab#atleta#"
                                    >
                                        <!---span class="small fw-bold">#atleta#</span--->
                                        <span class="small fw-bold me-2">#left(dados.genero,1)#</span>
                                        <span class="small text-capitalize">#lCase(dados.nome_completo)#</span>
                                        <cfif len(trim(qStatsEvento.tempo))><span class="fa fa-person-running ms-2"></span><span class="small fw-bold ms-2">#qStatsEvento.tempo#</span></cfif>
                                        <cfif qStatsEvento.obs GT 0><span class="fa fa-edit ms-2"></span>OBS</cfif>
                                        <cfif len(trim(URL.prova)) AND URL.prova EQ "01">
                                            <cfquery name="qCheckCorreu">
                                                SELECT *
                                                FROM tb_resultados
                                                WHERE upper(nome) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#UCase(dados.nome_completo)#"/>
                                                AND id_evento = 24998
                                            </cfquery>
                                            <cfif qCheckCorreu.recordcount>
                                                <span class="fa fa-person-running ms-2 text-success small">start list</span>
                                            </cfif>
                                        </cfif>
                                        <cfif len(trim(URL.prova)) AND URL.prova EQ "02">
                                            <cfquery name="qCheckCorreu">
                                                SELECT *
                                                FROM tb_resultados
                                                WHERE upper(nome) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#UCase(dados.nome_completo)#"/>
                                                AND id_evento = 24999
                                            </cfquery>
                                            <cfif qCheckCorreu.recordcount>
                                                <span class="fa fa-person-running ms-2 text-success small">start list</span>
                                            </cfif>
                                        </cfif>
                                        <cfif len(trim(URL.prova)) AND URL.prova EQ "03">
                                            <cfquery name="qCheckCorreu">
                                                SELECT *
                                                FROM tb_resultados
                                                WHERE upper(nome) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#UCase(dados.nome_completo)#"/>
                                                AND id_evento = 26867
                                            </cfquery>
                                            <cfif qCheckCorreu.recordcount>
                                                <span class="fa fa-person-running ms-2 text-success small">start list</span>
                                            </cfif>
                                        </cfif>
                                    </button>
                                </h2>
                                <div id="tab#atleta#" class="accordion-collapse collapse" aria-labelledby="heading#atleta#" data-mdb-parent="##accordion">
                                    <div class="accordion-body small py-1 px-3">
                                        <!---<cfdump var="#dados#"/>--->
                                        <div class="row mb-2">
                                            <div class="col-8 p-0">
                                                <select data-mdb-select-init data-mdb-visible-options="7" class="form-select w-50" onchange="window.location.href='./?id_usuario=#qStatsEvento.id#&status=' + this.value">>
                                                        <option value="I" <cfif qStatsEvento.status EQ "I">selected</cfif> >Status</option>
                                                        <option value="sem_cbat" <cfif qStatsEvento.status EQ "sem_cbat">selected</cfif> >Sem CBAt</option>
                                                        <option value="aguardando_cbat" <cfif qStatsEvento.status EQ "aguardando_cbat">selected</cfif> >Aguardando CBAt</option>
                                                        <option value="aguardando_comprovante" <cfif qStatsEvento.status EQ "aguardando_comprovante">selected</cfif> >Aguardando comprovante</option>
                                                        <option value="outra_marca" <cfif qStatsEvento.status EQ "outra_marca">selected</cfif> >Outra marca</option>
                                                        <option value="nao_enviar" <cfif qStatsEvento.status EQ "nao_enviar">selected</cfif> >Já tem</option>
                                                        <option value="enviar" <cfif qStatsEvento.status EQ "enviar">selected</cfif> >Enviar</option>
                                                        <option value="enviado" <cfif qStatsEvento.status EQ "enviado">selected</cfif> >Enviado</option>
                                                </select>
                                            </div>
                                            <div class="col-4 p-0 pt-1 text-end">
                                                <cfif Len(trim(qPerfil.is_admin)) and qPerfil.is_admin>
                                                    <a href="https://roadrunners.run/?action=dev_auth&dev_auth=#qStatsEvento.email#" target="_blank" class="link-secondary" title="Login as">
                                                        <i class="fas fa-screwdriver-wrench me-2 fa-2x"></i>
                                                    </a>
                                                </cfif>
                                                <a href="https://roadrunners.run/atleta/#qStatsEvento.tag_usuario#/" target="_blank" class="link-secondary" title="Perfil do atleta">
                                                    <i class="fa-solid fa-circle-user me-2 fa-2x"></i>
                                                </a>
                                                <cfif IsNumeric(#dados.cbat#)>
                                                    <a href="https://cbat.org.br/atletas/#dados.cbat#/#dados.cbat#" target="_blank" class="link-secondary" title="Ficha CBAt">
                                                        <i class="fa-solid fa-certificate me-2 fa-2x"></i>
                                                    </a>
                                                <cfelse>
                                                    <a class="disabled link-danger">
                                                        <i class="fa-solid fa-certificate me-2 fa-2x" title="Ficha CBAt"></i>
                                                    </a>
                                                </cfif>
                                                <cfif len(trim(dados.instagram))>
                                                    <a href="https://instagram.com/#trim(LCase(replace(dados.instagram,'@','')))#" target="_blank" class="link-secondary" title="Instagram">
                                                        <i class="fa-brands fa-instagram me-2 fa-2x"></i>
                                                    </a>
                                                </cfif>
                                                <cfif len(trim(dados.celular))>
                                                    <a href="https://wa.me/+55#reReplace(dados.celular, "[^0-9]", "", "all")#" target="_blank" class="link-secondary" title="WhatsApp">
                                                        <i class="fa-brands fa-whatsapp me-2 fa-2x"></i>
                                                    </a>
                                                </cfif>
                                            </div>
                                        </div>
                                        <div class="row bg-black rounded p-1 bg-opacity-10">
                                            <div class="col-4 col-md-2 fw-bold px-1 ">Registro CBAt</div>
                                                <div class="col-8 col-md-4 <cfif IsNumeric(dados.cbat)>text-warning text-decoration-underline<cfelse>text-danger</cfif>"><cfif IsNumeric(dados.cbat)>
                                                    <a href="https://cbat.org.br/atletas/#dados.cbat#/atleta" class="link-warning" target="_blank">
                                                        <span id="nome_#dados.cbat#">Carregando...</span>

                                                        <script>
                                                            fetch("https://runnerhub.run/includes/getH1.cfm?external=https://cbat.org.br/atletas/#dados.cbat#/atleta")
                                                                    .then(response => response.json())
                                                                    .then(data => {
                                                                        const container = document.getElementById("nome_#dados.cbat#");
                                                                        const h1 = data.H1?.trim();

                                                                        if (!h1) {
                                                                            container.innerHTML = `<span>⚠️ Não identificado!</span>`;
                                                                        } else if (h1.length > 100) {
                                                                            container.innerHTML = `<span>⚠️ Não identificado!</span>`;
                                                                        } else {
                                                                            container.innerHTML = `${h1}`;
                                                                        }
                                                                    })
                                                                    .catch(err => {
                                                                        document.getElementById("resultado").innerHTML = `<span>❌ Erro!</span>`;
                                                                        console.error(err);
                                                                    });
                                                        </script>
                                                        (#dados.cbat#)
                                                    </a><cfelse>#dados.cbat#</cfif>
                                                </div>
                                            <div class="col-4 col-md-2 fw-bold px-1">CPF</div><div class="col-8 col-md-4">#dados.documento#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Email</div><div class="col-8 col-md-4">#qStatsEvento.email#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Cel/WhatsApp</div><div class="col-8 col-md-4"><a href="https://wa.me/+55#reReplace(dados.celular, "[^0-9]", "", "all")#" target="_blank">#dados.celular#</a></div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Data de nasc.</div><div class="col-8 col-md-4">#dados.nascimento#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Gênero</div><div class="col-8 col-md-4">#dados.genero#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Equipe</div><div class="col-8 col-md-4">#dados.equipe#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Instagram</div><div class="col-8 col-md-4">#trim(LCase(replace(dados.instagram,'@','')))#</div>
                                            <hr class="my-1 opacity-10"/>
                                            <div class="col-4 col-md-2 fw-bold px-1">Endereço</div><div class="col-8 col-md-4">#dados.endereco#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Número</div><div class="col-8 col-md-4">#dados.numero#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Complemento</div><div class="col-8 col-md-4">#dados.complemento#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Bairro</div><div class="col-8 col-md-4">#dados.bairro#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Cidade</div><div class="col-8 col-md-4">#dados.cidade#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">UF</div><div class="col-8 col-md-4">#dados.UF#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">CEP</div><div class="col-8 col-md-4">#dados.CEP#</div>
                                            <hr class="my-1 opacity-10"/>
                                            <div class="col-4 col-md-2 fw-bold px-1">Apoiado</div><div class="col-8 col-md-4">#dados.marcas#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Marcas</div><div class="col-8 col-md-4">#dados.marca#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Tam. calçado</div><div class="col-8 col-md-4">#dados.calcado#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Tam. vestuário</div><div class="col-8 col-md-4">#dados.vestuario#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Tam. top</div><div class="col-8 col-md-4">#dados.top#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Tam. calça</div><div class="col-8 col-md-4">#dados.calca#</div>
                                            <hr class="my-1 opacity-10"/>
                                            <div class="col-4 col-md-2 fw-bold px-1">RP nos 42k</div><div class="col-8 col-md-4">#dados.rp42#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Prova do RP</div><div class="col-8 col-md-4">#dados.rp42prova#</div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Provas que fará</div>
                                            <div class="col-8 col-md-4">

                                                <!---#dados.provas#--->
                                                <cfset provasArray = dados.provas />
                                                <cfif isArray(dados.provas)>
                                                <cfset provasArray = dados.provas>
                                                <cfelseif isSimpleValue(dados.provas) AND listLen(dados.provas) GT 0>
                                                    <cfset provasArray = listToArray(dados.provas)>
                                                <cfelse>
                                                    <cfset provasArray = []>
                                                </cfif>

                                                <cfif arrayLen(provasArray)>
                                                    <ul class="list-unstyled">
                                                        <cfloop array="#provasArray#" index="prova">
                                                            <li>
                                                                <cfif structKeyExists(eventosMap, prova)>
                                                                    #prova# - #eventosMap[prova]#
                                                                <cfelse>
                                                                    #prova# - Evento desconhecido
                                                                </cfif>
                                                            </li>
                                                        </cfloop>
                                                    </ul>
                                                <cfelse>
                                                    Nenhuma prova informada.
                                                </cfif>

                                            </div>
                                            <div class="col-4 col-md-2 fw-bold px-1">Inscrito no Desafio</div><div class="col-8 col-md-4">#DateTimeFormat(qStatsEvento.data_inscricao,'dd/mm/yyyy HH:nn')#</div>
                                        </div>
                                        <div class="py-2">
                                            <div class="row small mb-2">
                                                    <div class="col-2 bold border-bottom">Data</div>
                                                    <div class="col-2 bold border-bottom">Autor</div>
                                                    <div class="col-8 bold border-bottom">Observação</div>
                                                <cfloop query="qObsDesafio">
                                                    <div class="col-2 border-bottom">#DateTimeFormat(qObsDesafio.data_obs,'dd/mm/yyyy HH:nn')#</div>
                                                    <div class="col-2 border-bottom">#qObsDesafio.name#</div>
                                                    <div class="col-8 border-bottom">#qObsDesafio.obs#</div>
                                                </cfloop>
                                            </div>
                                            <form method="post" action="./">
                                                <!---<div class="row">
                                                    <div class="col-10">
                                                        <div class="form-outline" data-mdb-input-init>
                                                            <input type="text" id="obs" name="obs" class="form-control" />
                                                            <label class="form-label" for="obs">Observação</label>
                                                        </div>
                                                    </div>
                                                    <div class="col-2">
                                                        <button type="submit" class="btn btn-secondary ">Enviar</button>
                                                    </div>
                                                    <input type="hidden" name="id_usuario" value="#qStatsEvento.id#"/>
                                                </div>--->

                                                <div class="input-group">
                                                    <div class="form-outline" data-mdb-input-init>
                                                        <input type="text" id="obs" name="obs" class="form-control" />
                                                        <label class="form-label" for="obs">Observação</label>
                                                    </div>
                                                    <button type="submit" class="btn btn-outline-warning" data-mdb-ripple-init>
                                                        Enviar
                                                    </button>
                                                </div>
                                                <input type="hidden" name="id_usuario" value="#qStatsEvento.id#"/>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            </cfoutput>
                        </div>

                        <!---<div class="table-wrapper-lg">--->

                            <!---<table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                <tbody>
                                <cfoutput query="qStatsEvento">
                                    <cfset dados = deserializeJSON(qStatsEvento.body)/>
                                    <tr>
                                        <td nowrap>#dados.nome_completo#</td>
                                        <!---td nowrap>#lsDateFormat(qStatsEvento.data_inscricao, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_inscricao, "HH:mm")#</td--->
                                        <!---td>#qStatsEvento.estado#</td--->
                                        <!--- EVENTO --->
                                        <td><cfif isdefined("dados.equipe")>#trim(dados.equipe)#</cfif></td>
                                        <td><cfif isdefined("dados.celular")>#dados.celular#</cfif></td>
                                        <td><cfif isdefined("qStatsEvento.email")>#qStatsEvento.email#</cfif></td>
                                        <!---td><cfif len(trim(qStatsEvento.strava_code))><a target="_blank" href="https://www.strava.com/athletes/#strava_id#/"><div class="badge bg-strava"><i class="fa-brands fa-strava"></i></div></a></cfif></td--->
                                    </tr>
                                    <tr>
                                        <td colspan="6">
                                            <cfdump var="#dados#"/>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </tbody>
                            </table>--->

                        <!---</div>--->

                    </div>

                </div>

            </div>

        </div>

    </div>

</div>
