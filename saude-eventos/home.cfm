<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="includes/backend.cfm"/>

<section class="saude-eventos-shell">
    <header class="saude-eventos-hero">
        <div class="saude-eventos-hero__icon"><i class="fa-solid fa-kit-medical"></i></div>
        <div class="flex-grow-1">
            <span class="saude-eventos-eyebrow">Gestão do evento</span>
            <h1>Operação de saúde</h1>
            <p>Prepare a central médica de cada prova e acompanhe o atendimento em tempo real.</p>
        </div>
        <div class="saude-eventos-hero__summary">
            <strong><cfoutput>#qSaudeConfigEvents.recordcount#</cfoutput></strong>
            <span>eventos nesta visão</span>
        </div>
    </header>

    <cfif len(VARIABLES.saudeConfigAlert.message)>
        <div class="alert alert-<cfoutput>#VARIABLES.saudeConfigAlert.type#</cfoutput> d-flex align-items-center gap-2" role="alert">
            <i class="fa-solid <cfif VARIABLES.saudeConfigAlert.type EQ 'success'>fa-circle-check<cfelse>fa-triangle-exclamation</cfif>"></i>
            <cfoutput>#htmlEditFormat(VARIABLES.saudeConfigAlert.message)#</cfoutput>
        </div>
    </cfif>

    <cfif NOT VARIABLES.saudeConfigReady>
        <div class="saude-eventos-empty">
            <i class="fa-solid fa-database"></i>
            <h2>Configuração pendente</h2>
            <p>A estrutura da operação de saúde ainda precisa ser instalada no servidor.</p>
        </div>
    <cfelse>
        <div class="saude-eventos-toolbar">
            <form method="get" action="./" class="row g-2 align-items-end w-100">
                <div class="col-12 col-lg">
                    <label for="saude-busca" class="form-label">Buscar evento</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
                        <input id="saude-busca" class="form-control" type="search" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Nome, cidade ou código"/>
                    </div>
                </div>
                <div class="col-12 col-md-8 col-lg-3">
                    <label for="saude-status" class="form-label">Situação do painel</label>
                    <select id="saude-status" class="form-select" name="status">
                        <option value="todos" <cfif URL.status EQ "todos">selected</cfif>>Todos os eventos</option>
                        <option value="ativos" <cfif URL.status EQ "ativos">selected</cfif>>Painel ativo</option>
                        <option value="inativos" <cfif URL.status EQ "inativos">selected</cfif>>Painel pausado</option>
                        <option value="nao_configurados" <cfif URL.status EQ "nao_configurados">selected</cfif>>Não configurado</option>
                    </select>
                </div>
                <div class="col-12 col-md-4 col-lg-auto d-flex gap-2">
                    <button class="btn btn-warning flex-grow-1" type="submit">Filtrar</button>
                    <a class="btn btn-outline-light" href="./" title="Limpar filtros"><i class="fa-solid fa-rotate-left"></i></a>
                </div>
            </form>
        </div>

        <cfif qSaudeConfigSelected.recordcount>
            <cfset VARIABLES.saudeConfigCanEditSelected = NOT VARIABLES.saudeConfigIsMedical
                AND (VARIABLES.saudeConfigIsGlobalAdmin OR listFind(VARIABLES.saudeConfigWriteIds, qSaudeConfigSelected.id_evento))/>
            <cfset VARIABLES.saudeConfigCentralUrl = "https://business.roadrunners.run/saude-eventos/central/?id_evento=" & qSaudeConfigSelected.id_evento/>
            <cfset VARIABLES.saudeConfigInviteMessage = "Olá! Você foi convidado(a) para acessar a Central de Saúde do evento "
                & trim(qSaudeConfigSelected.nome_evento & "") & "."
                & chr(10) & chr(10) & "Acesse: " & VARIABLES.saudeConfigCentralUrl
                & chr(10) & chr(10) & "Entre com sua conta Road Runners. Se ainda não tiver permissão como Médico, solicite o acesso na própria página."/>
            <cfset VARIABLES.saudeConfigWhatsappInviteUrl = "https://wa.me/?text=" & urlEncodedFormat(VARIABLES.saudeConfigInviteMessage)/>
            <article id="configuracao" class="saude-config-card">
                <div class="saude-config-card__head">
                    <div>
                        <span class="saude-eventos-eyebrow">Evento selecionado · #<cfoutput>#qSaudeConfigSelected.id_evento#</cfoutput></span>
                        <h2><cfoutput>#htmlEditFormat(qSaudeConfigSelected.nome_evento)#</cfoutput></h2>
                        <p>
                            <i class="fa-regular fa-calendar me-1"></i>
                            <cfoutput>#dateFormat(qSaudeConfigSelected.data_inicial, "dd/mm/yyyy")#</cfoutput>
                            <cfif len(trim(qSaudeConfigSelected.cidade & ""))>
                                <span class="mx-2">·</span><cfoutput>#htmlEditFormat(qSaudeConfigSelected.cidade)#<cfif len(trim(qSaudeConfigSelected.estado & ""))>/#htmlEditFormat(qSaudeConfigSelected.estado)#</cfif></cfoutput>
                            </cfif>
                        </p>
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <cfif qSaudeConfigSelected.ativo_painel AND VARIABLES.saudeConfigCanEditSelected>
                            <cfoutput><a class="btn btn-outline-success" href="#htmlEditFormat(VARIABLES.saudeConfigWhatsappInviteUrl)#" target="_blank" rel="noopener" aria-label="Convidar um médico pelo WhatsApp para a Central de Saúde"><i class="fa-brands fa-whatsapp me-2"></i>Convidar médico</a></cfoutput>
                        </cfif>
                        <cfif qSaudeConfigSelected.ativo_painel AND len(trim(qSaudeConfigSelected.percurso_padrao & ""))>
                            <cfoutput><a class="btn btn-outline-warning" href="/saude-eventos/central/?id_evento=#qSaudeConfigSelected.id_evento#&percurso=#urlEncodedFormat(qSaudeConfigSelected.percurso_padrao)#" target="_blank" rel="noopener"><i class="fa-solid fa-kit-medical me-2"></i>Abrir central</a></cfoutput>
                        </cfif>
                        <a class="btn btn-outline-light" href="./"><i class="fa-solid fa-xmark me-2"></i>Fechar</a>
                    </div>
                </div>

                <cfif NOT VARIABLES.saudeConfigCanEditSelected>
                    <div class="alert alert-warning mb-0"><cfif VARIABLES.saudeConfigIsMedical>O perfil Médico pode abrir e operar a Central, mas não pode alterar sua configuração.<cfelse>Você pode consultar esta configuração, mas não possui permissão operacional para alterá-la.</cfif></div>
                </cfif>

                <form method="post" action="./?id_evento=<cfoutput>#qSaudeConfigSelected.id_evento#</cfoutput>##configuracao" class="saude-config-form">
                    <input type="hidden" name="acao" value="salvar"/>
                    <input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.saudeConfigCsrf#</cfoutput>"/>
                    <input type="hidden" name="id_evento" value="<cfoutput>#qSaudeConfigSelected.id_evento#</cfoutput>"/>

                    <div class="saude-config-toggle">
                        <div>
                            <strong>Disponibilizar o painel operacional</strong>
                            <span>A equipe autorizada poderá selecionar este evento na Central de Saúde do Business.</span>
                        </div>
                        <div class="form-check form-switch m-0">
                            <input class="form-check-input" type="checkbox" role="switch" id="saude-ativo" name="ativo" value="true" <cfif qSaudeConfigSelected.ativo_painel>checked</cfif> <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                            <label class="form-check-label" for="saude-ativo"><cfif qSaudeConfigSelected.ativo_painel>Ativo<cfelse>Pausado</cfif></label>
                        </div>
                    </div>

                    <div class="row g-3">
                        <div class="col-12 col-lg-6">
                            <label class="form-label" for="saude-nome">Nome da operação</label>
                            <input id="saude-nome" class="form-control" type="text" name="nome_operacao" maxlength="120" value="<cfoutput>#htmlEditFormat(qSaudeConfigSelected.nome_operacao)#</cfoutput>" placeholder="Central de Saúde" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                        </div>
                        <div class="col-12 col-sm-7 col-lg-4">
                            <label class="form-label" for="saude-percurso">Percurso padrão</label>
                            <select id="saude-percurso" class="form-select" name="percurso_padrao" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>>
                                <option value="">Selecione</option>
                                <cfoutput query="qSaudeConfigCourses">
                                    <option value="#qSaudeConfigCourses.percurso_evento#" <cfif qSaudeConfigSelected.percurso_padrao EQ qSaudeConfigCourses.percurso_evento>selected</cfif>>#qSaudeConfigCourses.percurso_evento##lCase(qSaudeConfigCourses.unidade_de_medida)#<cfif len(trim(qSaudeConfigCourses.tipo_corrida & ''))> · #htmlEditFormat(qSaudeConfigCourses.tipo_corrida)#</cfif></option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-12 col-sm-5 col-lg-2">
                            <label class="form-label" for="saude-refresh">Atualização</label>
                            <select id="saude-refresh" class="form-select" name="intervalo_atualizacao" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>>
                                <cfloop list="10,15,30,60,120,300" index="VARIABLES.saudeRefreshOption">
                                    <cfoutput><option value="#VARIABLES.saudeRefreshOption#" <cfif qSaudeConfigSelected.intervalo_atualizacao EQ VARIABLES.saudeRefreshOption>selected</cfif>>#VARIABLES.saudeRefreshOption# s</option></cfoutput>
                                </cfloop>
                            </select>
                        </div>
                        <div class="col-12 col-md-6">
                            <label class="form-label" for="saude-inicio">Início da operação</label>
                            <input id="saude-inicio" class="form-control" type="datetime-local" name="inicio_operacao" value="<cfoutput>#saudeConfigLocalDateTime(qSaudeConfigSelected.inicio_operacao)#</cfoutput>" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                        </div>
                        <div class="col-12 col-md-6">
                            <label class="form-label" for="saude-fim">Encerramento da operação</label>
                            <input id="saude-fim" class="form-control" type="datetime-local" name="fim_operacao" value="<cfoutput>#saudeConfigLocalDateTime(qSaudeConfigSelected.fim_operacao)#</cfoutput>" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                        </div>
                        <div class="col-12 col-lg-6">
                            <label class="form-label" for="saude-local">Local da base médica</label>
                            <input id="saude-local" class="form-control" type="text" name="local_atendimento" maxlength="180" value="<cfoutput>#htmlEditFormat(qSaudeConfigSelected.local_atendimento)#</cfoutput>" placeholder="Ex.: tenda médica ao lado do pórtico de chegada" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                        </div>
                        <div class="col-12 col-lg-6">
                            <label class="form-label" for="saude-diretor-medico">Diretor médico</label>
                            <select id="saude-diretor-medico" class="form-select" name="id_diretor_medico" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>>
                                <option value=""><cfif len(trim(qSaudeConfigSelected.diretor_medico & "")) AND NOT len(trim(qSaudeConfigSelected.id_diretor_medico & ""))>Cadastro anterior: <cfoutput>#htmlEditFormat(qSaudeConfigSelected.diretor_medico)#</cfoutput> — selecione novamente<cfelse>Selecione um médico</cfif></option>
                                <cfoutput query="qSaudeConfigDoctors">
                                    <option value="#qSaudeConfigDoctors.id_usuario#" <cfif qSaudeConfigSelected.id_diretor_medico EQ qSaudeConfigDoctors.id_usuario>selected</cfif>>#htmlEditFormat(qSaudeConfigDoctors.nome)#<cfif len(trim(qSaudeConfigDoctors.email & ''))> · #htmlEditFormat(qSaudeConfigDoctors.email)#</cfif><cfif VARIABLES.saudeConfigIsGlobalAdmin AND len(trim(qSaudeConfigDoctors.nome_conta & ''))> · #htmlEditFormat(qSaudeConfigDoctors.nome_conta)#</cfif></option>
                                </cfoutput>
                            </select>
                            <div class="form-text"><cfif qSaudeConfigDoctors.recordcount>Somente usuários ativos com perfil Médico na conta responsável pelo evento.<cfelse>Nenhum usuário com perfil Médico está ativo na conta responsável pelo evento.</cfif></div>
                        </div>
                        <div class="col-12 col-lg-6">
                            <label class="form-label" for="saude-whatsapp-equipe">WhatsApp da equipe médica</label>
                            <input id="saude-whatsapp-equipe" class="form-control" type="tel" name="whatsapp_equipe" maxlength="24" inputmode="tel" value="<cfoutput>#htmlEditFormat(qSaudeConfigSelected.whatsapp_equipe)#</cfoutput>" placeholder="Ex.: (48) 99999-9999" aria-describedby="saude-whatsapp-ajuda" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>/>
                            <div id="saude-whatsapp-ajuda" class="form-text">O DDI 55 será incluído automaticamente quando necessário.</div>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="saude-instrucoes">Instruções para a equipe</label>
                            <textarea id="saude-instrucoes" class="form-control" name="instrucoes" rows="3" maxlength="4000" placeholder="Procedimentos, contatos e orientações específicas da prova" <cfif NOT VARIABLES.saudeConfigCanEditSelected>disabled</cfif>><cfoutput>#htmlEditFormat(qSaudeConfigSelected.instrucoes)#</cfoutput></textarea>
                        </div>
                    </div>
                    <cfif VARIABLES.saudeConfigCanEditSelected>
                        <div class="d-flex justify-content-end mt-4">
                            <button class="btn btn-warning px-4" type="submit"><i class="fa-solid fa-floppy-disk me-2"></i>Salvar configuração</button>
                        </div>
                    </cfif>
                </form>
            </article>
        </cfif>

        <div class="saude-eventos-grid">
            <cfif NOT qSaudeConfigEvents.recordcount>
                <div class="saude-eventos-empty">
                    <i class="fa-regular fa-calendar-xmark"></i>
                    <h2>Nenhum evento encontrado</h2>
                    <p>Ajuste os filtros ou vincule eventos à conta ativa.</p>
                </div>
            <cfelse>
                <cfoutput query="qSaudeConfigEvents">
                    <article class="saude-event-card <cfif qSaudeConfigEvents.ativo_painel>is-active</cfif>">
                        <div class="saude-event-card__top">
                            <span class="saude-event-status <cfif qSaudeConfigEvents.ativo_painel>is-active<cfelseif len(trim(qSaudeConfigEvents.data_atualizacao & ''))>is-paused<cfelse>is-new</cfif>">
                                <i class="fa-solid <cfif qSaudeConfigEvents.ativo_painel>fa-circle-play<cfelseif len(trim(qSaudeConfigEvents.data_atualizacao & ''))>fa-circle-pause<cfelse>fa-circle-plus</cfif>"></i>
                                <cfif qSaudeConfigEvents.ativo_painel>Ativo<cfelseif len(trim(qSaudeConfigEvents.data_atualizacao & ''))>Pausado<cfelse>Não configurado</cfif>
                            </span>
                            <span class="saude-event-id">###qSaudeConfigEvents.id_evento#</span>
                        </div>
                        <h2>#htmlEditFormat(qSaudeConfigEvents.nome_evento)#</h2>
                        <div class="saude-event-meta">
                            <span><i class="fa-regular fa-calendar"></i>#dateFormat(qSaudeConfigEvents.data_inicial, 'dd/mm/yyyy')#</span>
                            <cfif len(trim(qSaudeConfigEvents.cidade & ''))><span><i class="fa-solid fa-location-dot"></i>#htmlEditFormat(qSaudeConfigEvents.cidade)#<cfif len(trim(qSaudeConfigEvents.estado & ''))>/#htmlEditFormat(qSaudeConfigEvents.estado)#</cfif></span></cfif>
                            <span><i class="fa-solid fa-route"></i>#htmlEditFormat(qSaudeConfigEvents.percursos)#</span>
                        </div>

                        <cfif len(trim(qSaudeConfigEvents.data_atualizacao & ''))>
                            <div class="saude-event-metrics">
                                <div><strong>#qSaudeConfigEvents.aguardando_triagem#</strong><span>Triagem</span></div>
                                <div><strong>#qSaudeConfigEvents.em_atendimento#</strong><span>Em cuidado</span></div>
                                <div><strong>#qSaudeConfigEvents.atendidos#</strong><span>Atendidos</span></div>
                            </div>
                        <cfelse>
                            <p class="saude-event-card__hint">Defina o percurso e os detalhes da operação antes de liberar o painel.</p>
                        </cfif>

                        <div class="saude-event-card__actions">
                            <a class="btn btn-sm btn-outline-light" href="./?busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(URL.status)#&id_evento=#qSaudeConfigEvents.id_evento###configuracao"><i class="fa-solid <cfif VARIABLES.saudeConfigIsMedical>fa-eye<cfelse>fa-sliders</cfif> me-2"></i><cfif VARIABLES.saudeConfigIsMedical>Ver detalhes<cfelse>Configurar</cfif></a>
                            <cfif qSaudeConfigEvents.ativo_painel AND len(trim(qSaudeConfigEvents.percurso_padrao & ''))>
                                <a class="btn btn-sm btn-warning" href="/saude-eventos/central/?id_evento=#qSaudeConfigEvents.id_evento#&percurso=#urlEncodedFormat(qSaudeConfigEvents.percurso_padrao)#" target="_blank" rel="noopener"><i class="fa-solid fa-kit-medical me-2"></i>Abrir central</a>
                            </cfif>
                        </div>
                    </article>
                </cfoutput>
            </cfif>
        </div>
    </cfif>
</section>
