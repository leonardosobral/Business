
<div class="accordion accordion-flush" id="accordion">

    <cfoutput query="qStatsEvento">

        <cfset dados = deserializeJSON(qStatsEvento.body)/>

        <div class="accordion-item">

            <!--- ACORDION HEADERS --->

            <h2 class="accordion-header" id="flush-heading#id_usuario#">

                <button
                data-mdb-collapse-init
                class="accordion-button collapsed p-2"
                type="button"
                data-mdb-target="##flush-collapse#id_usuario#"
                aria-expanded="false"
                aria-controls="flush-collapse#id_usuario#">

                    <!--- BOTOES --->

                    <cfif URL.preset EQ "treinos">

                        #presencas#/#total#

                    <cfelse>

                        <cfif NOT len(trim(qStatsEvento.data_checkin))>
                            <cfif NOT len(trim(qStatsEvento.data_checkin))>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-success"><i class="fa fa-check"></i></a>
                            </cfif>
                        <cfelse>
                            <cfif len(trim(qStatsEvento.flag_sorteio)) AND qStatsEvento.flag_sorteio EQ true>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-success"><i class="fa fa-gift"></i></a>
                            <cfelseif len(trim(qStatsEvento.flag_sorteio)) AND qStatsEvento.flag_sorteio EQ false>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-danger"><i class="fa fa-gift"></i></a>
                            <cfelse>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-secondary"><i class="fa fa-gift"></i></a>
                            </cfif>
                        </cfif>

                    </cfif>

                    <!--- NOME --->

                    <span class="px-2">
                    <!---cfif URL.periodo EQ "checkin">
                        #presencas#/#total# -
                    </cfif--->
                    #qStatsEvento.name#
                    </span>

                    <!--- MIF --->

                    <cfif len(trim(qStatsEvento.mif)) AND qStatsEvento.mif GT 0>
                        <cfif qStatsEvento.mif CONTAINS "42">
                                <div class="badge bg-42k text-white" title="#qStatsEvento.mif#">42K</div>
                            <cfelseif qStatsEvento.mif CONTAINS "21">
                                <div class="badge bg-21k" title="#qStatsEvento.mif#">21K</div>
                            <cfelseif qStatsEvento.mif CONTAINS "5">
                                <div class="badge bg-5k" title="#qStatsEvento.mif#">5K</div>
                        <cfelse>
                                <div class="badge bg-warning" title="#qStatsEvento.mif#">MIF</div>
                        </cfif>
                    </cfif>

                </button>

            </h2>

            <!--- ACORDION DETALHES --->

            <div
              id="flush-collapse#id_usuario#"
              class="accordion-collapse collapse"
              aria-labelledby="flush-heading#id_usuario#"
              data-mdb-parent="##accordion">

                <div class="accordion-body">

                    <a target="_blank" href="https://roadrunners.run/atleta/#qStatsEvento.tag_usuario#" class="btn btn-secondary">
                        Perfil do atleta
                    </a><br>

                    Celular: #qStatsEvento.celular# <br>

                    Email: #qStatsEvento.email# <br>

                    <cfif len(trim(qStatsEvento.assessoria))>
                        Equipe: <i class="fa fa-person-running"></i> #qStatsEvento.assessoria# <br>
                    </cfif>
                    <cfif len(trim(qStatsEvento.observacoes))>
                        Notas: <i class="fa fa-gift"></i> #qStatsEvento.observacoes# <br>
                    </cfif>

                    <cfif URL.preset EQ "treinos">
                        <cfquery name="qInscricoesTreino" dbtype="query">
                            select *
                            from qBaseTreinoes
                            WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#qStatsEvento.id_usuario#"/>
                            ORDER BY id_evento DESC
                        </cfquery>
                        <cfloop query="qInscricoesTreino">
                            <br/><cfif len(trim(qInscricoesTreino.data_checkin))><i class="fa fa-check"></i><cfelse><i class="fa fa-calendar"></i></cfif> #qInscricoesTreino.nome_evento# (número #qInscricoesTreino.num_pedido#)
                        </cfloop>
                    </cfif>

                    <!---<cfif NOT len(trim(qStatsEvento.data_checkin))>
                        <cfif NOT len(trim(qStatsEvento.data_checkin))><a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-success"><i class="fa fa-check"></i></a></cfif>
                    <cfelse>
                            <cfif len(trim(qStatsEvento.flag_sorteio)) AND qStatsEvento.flag_sorteio EQ true>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-success"><i class="fa fa-gift"></i></a>
                            <cfelseif len(trim(qStatsEvento.flag_sorteio)) AND qStatsEvento.flag_sorteio EQ false>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-danger"><i class="fa fa-gift"></i></a>
                            <cfelse>
                                <a target="_blank" href="https://roadrunners.run/mif/treinao/checkin/?num=#num_pedido#" class="btn btn-sm btn-secondary"><i class="fa fa-gift"></i></a>
                            </cfif>
                    </cfif>--->

                </div>

            </div>

        </div>

    </cfoutput>

</div>

<!---cfif len(trim(qStatsEvento.mif)) AND qStatsEvento.mif GT 0>
    <cfquery name="qMifDetalhes">
        select body from tb_ticketsports_participantes where documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qStatsEvento.documento#"/>
    </cfquery>
    <cfset dadosMif = deserializeJSON(qMifDetalhes.body)/>
    #dadosMif.modalidade#
</cfif--->
