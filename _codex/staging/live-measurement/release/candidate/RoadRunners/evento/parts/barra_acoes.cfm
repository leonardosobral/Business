<cfset eventActions = REQUEST.i18n.event.actions />

<div class="row px-2">


    <!--- INSCRICAO / MAIS INFO --->

    <div class="mb-3 <cfif qEvento.data_final GT now() || qEvento.concluintes GT 0>col-md-6<cfelse>col-md-12</cfif>">

        <div class="d-flex shadow-0 btn-group small fs-6">

            <cfif len(trim(qEvento.url_inscricao)) OR len(trim(qEvento.url_hotsite))>

                <cfif qEvento.data_inicial GT now()>

                    <cfif qCupom.recordcount AND qEvento.status_evento NEQ 'cancelado'>

                        <!--- INSCRICAO COM CUPOM --->

                        <!---cfif Usuario.logado--->
                            <button type="button" class="btn btn-primary"
                                    data-mdb-ripple-init
                                    data-mdb-modal-init
                                    data-mdb-target="#modal_cupom_link"
                                    data-mdb-id-cupom="<cfoutput>#qCupom.id_cupom#</cfoutput>">Resgatar cupom</button>
                        <!---cfelse>
                            <button type="button" class="btn btn-primary" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">Resgatar cupom</button>
                        </cfif--->

                            <button type="button" class="btn btn-light" data-mdb-ripple-init onClick="window.open('<cfoutput>#Len(trim(qEvento.url_hotsite)) ? qEvento.url_hotsite : qEvento.url_inscricao#</cfoutput>', '_blank');"><cfoutput>#eventActions.learnMore#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></button>
                    <cfelse>

                        <!--- INSCRICAO NORMAL --->

                        <cfif qEvento.status_evento NEQ 'cancelado'>
                            <button type="button" class="btn btn-primary active" data-mdb-ripple-init
                                    data-audience-live-registration="<cfoutput>#HTMLEditFormat(qEvento.id_evento)#</cfoutput>"
                                    data-audience-registration-url="<cfoutput>#HTMLEditFormat(qEvento.url_inscricao)#</cfoutput>"
                                    onClick="window.open('<cfoutput>#qEvento.url_inscricao#</cfoutput>', '_blank');"><cfoutput>#eventActions.register#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></button>
                        </cfif>
                        <button type="button" class="btn btn-light" data-mdb-ripple-init onClick="window.open('<cfoutput>#Len(trim(qEvento.url_hotsite)) ? qEvento.url_hotsite : qEvento.url_inscricao#</cfoutput>', '_blank');"><cfoutput>#eventActions.learnMore#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></button>

                    </cfif>

                <cfelse>

                    <!--- SAIBA MAIS --->

                    <button type="button" class="btn btn-light" data-mdb-ripple-init onClick="window.open('<cfoutput>#qEvento.url_inscricao#</cfoutput>', '_blank');"><cfoutput>#eventActions.registrationsClosed#</cfoutput></button>
                    <button type="button" class="btn btn-light" data-mdb-ripple-init onClick="window.open('<cfoutput>#Len(trim(qEvento.url_hotsite)) ? qEvento.url_hotsite : qEvento.url_inscricao#</cfoutput>', '_blank');"><cfoutput>#eventActions.learnMore#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></button>

                </cfif>

            <cfelse>

                <!--- SEM LINK DE INSCRICAO --->

                <cfif qEvento.data_inicial GT now()>
                        <button type="button" class="btn disabled w-50 btn-outline-secondary" data-mdb-ripple-init><cfoutput>#eventActions.registrationsSoon#</cfoutput></button>
                <cfelse>
                        <button type="button" class="btn disabled w-50 btn-outline-secondary" data-mdb-ripple-init><cfoutput>#eventActions.registrationsClosed#</cfoutput></button>
                </cfif>

            </cfif>
        </div>

    </div>


    <!--- FAVORITAR EVENTOS --->

    <cfif qEvento.data_inicial GT now()>

        <div class="col-12 col-md-6 mb-2">
            <div class="d-flex btn-group shadow-0">
                <cfif Usuario.logado>
                    <!--- QUERO IR --->
                    <button type="button" class="btn btn-light <cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount>active</cfif>" onclick="location.href='./?acao=<cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount>remover<cfelse>calendario</cfif>'">
                        <cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount><i class="fa-solid fa-bookmark"></i><cfelse><i class="fa-regular fa-bookmark"></i></cfif> <cfoutput>#eventActions.wantToGo#</cfoutput></button>
                    <!--- JA INSCRITO --->
                    <button type="button" class="btn btn-light <cfif isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount>active</cfif>" onclick="location.href='./?acao=<cfif isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount>remover<cfelse>inscricao</cfif>'">
                        <cfif isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount><i class="fa-solid fa-square-check"></i><cfelse><i class="fa-regular fa-square-check"></i></cfif> <cfoutput>#eventActions.registered#</cfoutput></button>
                    <!--- AGENDA DA PAGINA --->
                    <!---<button type="button" class="btn btn-light" onclick="">Agenda pública</button>--->
                <cfelse>
                    <!--- QUERO IR --->
                    <button type="button" class="btn btn-light" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="calendario"><i class="fa-regular fa-bookmark"></i> <cfoutput>#eventActions.wantToGo#</cfoutput></button>
                    <!--- JA INSCRITO --->
                    <button type="button" class="btn btn-light" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="inscricao"><i class="fa-regular fa-square-check"></i> <cfoutput>#eventActions.registered#</cfoutput></button>
                </cfif>
                <!--- REMOVER --->
                <!---<cfif (isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount) OR (isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount)>--->
                    <!---<button type="button" style="width: 16%" class="btn btn-light" <cfif Usuario.logado>onclick="location.href='./?acao=remover'"<cfelse>data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="remover"</cfif>>--->
                        <!---<icon class="fa fa-trash"></icon>--->
                    <!---</button>--->
                <!---</cfif>--->
            </div>
        </div>
        <!---div class="d-flex btn-group shadow-0">
            <!--- AGENDA PUBLICA --->
            <button type="button" class="btn btn-light active" onclick=""><i class="fa-solid fa-calendar-check"></i><span class="d-none d-md-inline"> Agenda do</span> perfil</button>
            <button type="button" class="btn btn-light" onclick=""><i class="fa-regular fa-calendar"></i><span class="d-none d-md-inline"> Agenda do</span> clube</button>
        </div--->

    </cfif>


    <!--- RESULTADOS --->

    <cfif qEvento.concluintes GT 0>
        <div class="col-12 col-md-6 mb-2">
            <a href="https://openresults.run/evento/<cfoutput>#qEvento.tag#</cfoutput>" target="_blank">
                <button type="button" class="btn btn-primary w-100" data-mdb-ripple-init><cfoutput>#eventActions.results#</cfoutput></button>
            </a>
        </div>
    </cfif>

</div>
