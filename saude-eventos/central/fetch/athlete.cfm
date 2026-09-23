<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "fragment"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfparam name="URL.id_evento" type="numeric" default="0"/>
<cfparam name="URL.id_inscricao" type="numeric" default="0"/>

<cfscript>
function saudeMedicalValue(required struct ficha, required string key) {
    if (structKeyExists(arguments.ficha, arguments.key) AND !isNull(arguments.ficha[arguments.key])) {
        return trim(arguments.ficha[arguments.key] & "");
    }
    return "";
}

function saudeFriendlyTimestamp(required any value) {
    if (!isDate(arguments.value)) return "Data não informada";
    if (dateCompare(arguments.value, now(), "d") == 0) return "Hoje às " & timeFormat(arguments.value, "HH:mm");
    if (dateCompare(arguments.value, dateAdd("d", -1, now()), "d") == 0) return "Ontem às " & timeFormat(arguments.value, "HH:mm");
    return dateFormat(arguments.value, "dd/mm/yyyy") & " às " & timeFormat(arguments.value, "HH:mm");
}

function saudeStatusName(any value = "") {
    var status = lCase(trim(arguments.value & ""));
    if (status == "scan") return "Scan";
    if (status == "acionado") return "Acionado";
    if (status == "diligencia") return "Diligência";
    if (status == "atendimento") return "Em atendimento";
    if (status == "atendido") return "Atendido";
    if (status == "bib_desvinculado") return "BIB desvinculado";
    if (!len(status)) return "Lista da prova";
    return status;
}
</cfscript>

<cfquery name="qPagina" datasource="runner_dba">
    SELECT ins.num_pedido, ins.id_evento, ins.num_peito, ins.nome, ins.modalidade,
           ins.observacoes, ins.data_nascimento AS nascimento_inscricao,
           usr.ficha_medica, usr.id AS id_usuario, usr.data_nascimento,
           coalesce(
               nullif(trim(atleta_pag.nome), ''),
               nullif(trim(ins.nome), ''),
               nullif(trim(usr.name), ''),
               'Atleta · BIB ' || coalesce(ins.num_peito::text, 'não informado')
           ) AS nome_exibicao,
           coalesce(nullif(trim(atleta_pag.cidade), ''), nullif(trim(usr.cidade), ''), '') AS cidade,
           coalesce(nullif(trim(atleta_pag.uf), ''), nullif(trim(usr.estado), ''), '') AS uf,
           coalesce(nullif(trim(atleta_pag.path_imagem), ''), '') AS path_imagem
    FROM tb_inscricoes ins
    LEFT JOIN tb_usuarios usr ON usr.id = ins.id_usuario
    LEFT JOIN LATERAL (
        SELECT pag.nome, pag.cidade, pag.uf, pag.path_imagem
        FROM tb_paginas_usuarios pgusr
        INNER JOIN tb_paginas pag ON pag.id_pagina = pgusr.id_pagina
        WHERE pgusr.id_usuario = ins.id_usuario
        ORDER BY (pag.tag_prefix = 'atleta') DESC, pag.id_pagina
        LIMIT 1
    ) atleta_pag ON true
    INNER JOIN tb_evento_saude_config cfg ON cfg.id_evento = ins.id_evento AND cfg.ativo = true
    WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(URL.id_evento)#"/>
      AND ins.num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(URL.id_inscricao)#"/>
    LIMIT 1
</cfquery>

<cfif NOT qPagina.recordcount>
    <div class="saude-drawer-empty">
        <i class="fa-solid fa-user-slash"></i>
        <h2>Atleta não encontrado</h2>
        <p>O número de peito não pertence ao evento ativo.</p>
    </div>
    <cfabort/>
</cfif>

<cfquery name="qSaudeHistory" datasource="runner_dba">
    SELECT hist.id_historico,
           hist.id_evento,
           hist.num_peito,
           hist.status_anterior,
           hist.status_novo,
           hist.tipo_acao,
           hist.descricao,
           hist.origem,
           hist.data_alteracao,
           coalesce(nullif(trim(hist.autor_nome), ''), nullif(trim(operador.name), ''), 'Sistema') AS autor_exibicao,
           coalesce(nullif(trim(evt.nome_evento), ''), 'Evento ##' || hist.id_evento::text) AS evento_exibicao
    FROM tb_evento_saude_historico hist
    LEFT JOIN tb_usuarios operador ON operador.id = hist.id_usuario_operador
    LEFT JOIN tb_evento_corridas evt ON evt.id_evento = hist.id_evento
    <cfif len(trim(qPagina.id_usuario & ""))>
        WHERE hist.id_usuario_atleta = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPagina.id_usuario#"/>
    <cfelse>
        WHERE hist.num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPagina.num_pedido#"/>
    </cfif>
    ORDER BY hist.data_alteracao DESC, hist.id_historico DESC
</cfquery>

<cfset VARIABLES.saudeMedicalData = {}/>
<cfif len(trim(qPagina.ficha_medica & ""))>
    <cftry>
        <cfset VARIABLES.saudeMedicalData = deserializeJSON(qPagina.ficha_medica)/>
        <cfcatch type="any"><cfset VARIABLES.saudeMedicalData = {}/></cfcatch>
    </cftry>
</cfif>
<cfset VARIABLES.saudeBirthDate = isDate(qPagina.data_nascimento) ? qPagina.data_nascimento : (isDate(qPagina.nascimento_inscricao) ? qPagina.nascimento_inscricao : "")/>
<cfset VARIABLES.saudeAvatar = len(trim(qPagina.path_imagem & "")) ? "https://roadrunners.run/assets/paginas/" & qPagina.path_imagem : "https://roadrunners.run/assets/user.png"/>

<cfoutput>
<div class="saude-drawer-head">
    <div class="saude-drawer-title">
        <span>Ficha do atleta</span>
        <div class="saude-drawer-bib">
            <strong><cfif len(trim(qPagina.num_peito & ''))>BIB #qPagina.num_peito#<cfelse>Sem BIB</cfif></strong>
            <cfif VARIABLES.saudeCanUnlinkBib AND len(trim(qPagina.num_peito & ''))>
                <button type="button" class="saude-bib-unlink" onclick="prepararDesvinculoBib(#qPagina.num_pedido#,#qPagina.num_peito#)" title="Desvincular este número de peito">
                    <i class="fa-solid fa-link-slash"></i><span>Desvincular</span>
                </button>
            </cfif>
        </div>
    </div>
    <button type="button" class="saude-icon-button" onclick="fecharAtleta()" aria-label="Fechar ficha"><i class="fa-solid fa-xmark"></i></button>
</div>

<cfif VARIABLES.saudeCanUnlinkBib AND len(trim(qPagina.num_peito & ''))>
    <div class="saude-bib-confirmation" id="bibUnlinkConfirmation" data-inscricao="#qPagina.num_pedido#" data-bib="#qPagina.num_peito#" role="alertdialog" aria-labelledby="bibUnlinkTitle" hidden>
        <div>
            <strong id="bibUnlinkTitle">Desvincular o BIB #qPagina.num_peito#?</strong>
            <p>A inscrição será preservada, mas este número ficará livre para ser vinculado a outro atleta.</p>
        </div>
        <div class="saude-bib-confirmation-actions">
            <button type="button" class="is-cancel" onclick="cancelarDesvinculoBib()">Cancelar</button>
            <button type="button" class="is-confirm" id="bibUnlinkConfirmButton" onclick="desvincularBib(#qPagina.num_pedido#,#qPagina.num_peito#)"><i class="fa-solid fa-link-slash"></i> Confirmar desvínculo</button>
        </div>
    </div>
</cfif>

<div class="saude-athlete-profile">
    <img src="#htmlEditFormat(VARIABLES.saudeAvatar)#" alt="Foto do atleta" onerror="this.src='https://roadrunners.run/assets/user.png'" class="<cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>"/>
    <div>
        <span class="saude-athlete-kicker">#htmlEditFormat(len(trim(qPagina.modalidade & '')) ? qPagina.modalidade : 'Percurso não informado')#</span>
        <h2 class="<cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(qPagina.nome_exibicao)#</h2>
        <p><cfif len(trim(qPagina.cidade & ''))>#htmlEditFormat(qPagina.cidade)#<cfif len(trim(qPagina.uf & ''))>/#htmlEditFormat(qPagina.uf)#</cfif><cfelse>Localidade não informada</cfif><cfif isDate(VARIABLES.saudeBirthDate)><span> · #dateDiff('yyyy', VARIABLES.saudeBirthDate, now())# anos</span></cfif></p>
    </div>
</div>

<div class="saude-status-actions">
    <button type="button" class="is-danger" <cfif VARIABLES.saudeCanOperate>onclick="atualizarStatus(#qPagina.num_pedido#,'diligencia')"<cfelse>disabled title="Somente Médicos e Admins Globais podem alterar o status."</cfif>><i class="fa-solid fa-triangle-exclamation"></i>Diligência</button>
    <button type="button" class="is-warning" <cfif VARIABLES.saudeCanOperate>onclick="atualizarStatus(#qPagina.num_pedido#,'atendimento')"<cfelse>disabled title="Somente Médicos e Admins Globais podem alterar o status."</cfif>><i class="fa-solid fa-stethoscope"></i>Em atendimento</button>
    <button type="button" class="is-success" <cfif VARIABLES.saudeCanOperate>onclick="atualizarStatus(#qPagina.num_pedido#,'atendido')"<cfelse>disabled title="Somente Médicos e Admins Globais podem alterar o status."</cfif>><i class="fa-solid fa-check"></i>Atendido</button>
    <button type="button" class="is-neutral" <cfif VARIABLES.saudeCanOperate>onclick="atualizarStatus(#qPagina.num_pedido#,'')"<cfelse>disabled title="Somente Médicos e Admins Globais podem alterar o status."</cfif>><i class="fa-solid fa-rotate-left"></i>Falso positivo</button>
</div>
<cfif NOT VARIABLES.saudeCanOperate><p class="saude-operation-notice"><i class="fa-solid fa-lock"></i> Alteração de status disponível apenas para Médicos e Admins Globais.</p></cfif>

<div class="saude-medical-title"><i class="fa-solid fa-notes-medical"></i><span>Ficha médica</span></div>

<cfif structIsEmpty(VARIABLES.saudeMedicalData)>
    <cfif VARIABLES.saudeCanViewMedicalData>
        <div class="saude-medical-empty"><i class="fa-regular fa-address-card"></i><p>Ficha médica não preenchida.</p></div>
    <cfelse>
        <div class="saude-medical-confidential"><i class="fa-solid fa-user-lock"></i><div><strong>Informações sob sigilo médico</strong><p>Somente usuários com perfil Médico podem visualizar os dados deste quadro.</p></div></div>
    </cfif>
<cfelse>
    <div class="saude-medical-grid">
        <section class="saude-medical-card">
            <h3>Identificação</h3>
            <dl>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'nome'))><div><dt>Nome completo</dt><dd class="<cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'nome'))#</dd></div></cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'documento'))><div><dt>CPF</dt><dd class="<cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'documento'))#</dd></div></cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'celular'))>
                    <div class="saude-medical-contact">
                        <dt>Celular / WhatsApp</dt>
                        <dd class="saude-medical-contact-value <cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">
                            <span>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'celular'))#</span>
                            <cfif VARIABLES.saudeCanOperate>
                                <span class="saude-contact-actions" aria-label="Contatar atleta">
                                    <button type="button" class="is-whatsapp" onclick="acionarContato(#qPagina.num_pedido#,'atleta','whatsapp',this)" title="Chamar atleta pelo WhatsApp" aria-label="Chamar atleta pelo WhatsApp"><i class="fa-brands fa-whatsapp"></i></button>
                                    <button type="button" class="is-phone" onclick="acionarContato(#qPagina.num_pedido#,'atleta','telefone',this)" title="Ligar para o atleta" aria-label="Ligar para o atleta"><i class="fa-solid fa-phone"></i></button>
                                </span>
                            </cfif>
                        </dd>
                    </div>
                </cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'tipo_sanguineo'))><div><dt>Tipo sanguíneo</dt><dd><strong>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'tipo_sanguineo'))#</strong></dd></div></cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'sexo'))><div><dt>Sexo</dt><dd>#(uCase(saudeMedicalValue(VARIABLES.saudeMedicalData,'sexo')) EQ 'M' ? 'Masculino' : 'Feminino')#</dd></div></cfif>
            </dl>
        </section>

        <cfif VARIABLES.saudeCanViewMedicalData>
            <section class="saude-medical-card is-alert">
                <h3>Informações médicas</h3>
                <dl>
                    <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'doencas'))><div><dt>Doenças crônicas</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'doencas'))#</dd></div></cfif>
                    <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'alergias'))><div><dt>Alergias e restrições</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'alergias'))#</dd></div></cfif>
                    <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'medicamentos'))><div><dt>Medicamentos contínuos</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'medicamentos'))#</dd></div></cfif>
                    <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'cirurgias'))><div><dt>Cirurgias / dispositivos</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'cirurgias'))#</dd></div></cfif>
                    <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'altura'))><div><dt>Altura</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'altura'))# m</dd></div></cfif>
                </dl>
            </section>
        <cfelse>
            <section class="saude-medical-card saude-medical-confidential">
                <i class="fa-solid fa-user-lock"></i>
                <div><strong>Informações sob sigilo médico</strong><p>Somente usuários com perfil Médico podem visualizar os dados deste quadro.</p></div>
            </section>
        </cfif>

        <section class="saude-medical-card">
            <h3>Contato de emergência</h3>
            <dl>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'nomecontato'))><div><dt>Nome</dt><dd class="<cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'nomecontato'))#</dd></div></cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'grau'))><div><dt>Relação</dt><dd>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'grau'))#</dd></div></cfif>
                <cfif len(saudeMedicalValue(VARIABLES.saudeMedicalData,'celularcontato'))>
                    <div class="saude-medical-contact">
                        <dt>Celular / WhatsApp</dt>
                        <dd class="saude-medical-contact-value <cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">
                            <span>#htmlEditFormat(saudeMedicalValue(VARIABLES.saudeMedicalData,'celularcontato'))#</span>
                            <cfif VARIABLES.saudeCanOperate>
                                <span class="saude-contact-actions" aria-label="Contatar contato de emergência">
                                    <button type="button" class="is-whatsapp" onclick="acionarContato(#qPagina.num_pedido#,'emergencia','whatsapp',this)" title="Chamar contato de emergência pelo WhatsApp" aria-label="Chamar contato de emergência pelo WhatsApp"><i class="fa-brands fa-whatsapp"></i></button>
                                    <button type="button" class="is-phone" onclick="acionarContato(#qPagina.num_pedido#,'emergencia','telefone',this)" title="Ligar para o contato de emergência" aria-label="Ligar para o contato de emergência"><i class="fa-solid fa-phone"></i></button>
                                </span>
                            </cfif>
                        </dd>
                    </div>
                </cfif>
            </dl>
        </section>
    </div>
</cfif>

<div class="saude-history-section">
    <div class="saude-history-heading">
        <div>
            <span>Cronologia permanente</span>
            <strong>#qSaudeHistory.recordcount# registro<cfif qSaudeHistory.recordcount NEQ 1>s</cfif> em todos os eventos</strong>
        </div>
        <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i>
    </div>

    <cfif VARIABLES.saudeCanOperate>
        <div class="saude-note-composer">
            <label for="saudeNoteText">Adicionar anotação</label>
            <textarea id="saudeNoteText" maxlength="2000" rows="3" placeholder="Registre uma observação clínica ou operacional relevante."></textarea>
            <button type="button" id="saudeNoteButton" onclick="adicionarAnotacao(#qPagina.num_pedido#)">
                <i class="fa-solid fa-plus"></i> Adicionar à cronologia
            </button>
        </div>
    </cfif>

    <div class="saude-history-timeline">
        <cfif NOT qSaudeHistory.recordcount>
            <div class="saude-history-empty"><i class="fa-regular fa-clock"></i><span>A cronologia será formada a partir das próximas interações.</span></div>
        <cfelse>
            <cfloop query="qSaudeHistory">
                <cfset VARIABLES.saudeHistoryTitle = "Status atualizado"/>
                <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-arrow-right-arrow-left"/>
                <cfset VARIABLES.saudeHistoryTone = "neutral"/>
                <cfswitch expression="#lCase(trim(qSaudeHistory.tipo_acao & ''))#">
                    <cfcase value="acesso_ficha">
                        <cfset VARIABLES.saudeHistoryTitle = "Ficha acessada"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-eye"/>
                        <cfset VARIABLES.saudeHistoryTone = "blue"/>
                    </cfcase>
                    <cfcase value="acionar_equipe">
                        <cfset VARIABLES.saudeHistoryTitle = "Equipe médica acionada"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-bell"/>
                        <cfset VARIABLES.saudeHistoryTone = "danger"/>
                    </cfcase>
                    <cfcase value="abrir_whatsapp">
                        <cfset VARIABLES.saudeHistoryTitle = "WhatsApp da equipe aberto"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-brands fa-whatsapp"/>
                        <cfset VARIABLES.saudeHistoryTone = "success"/>
                    </cfcase>
                    <cfcase value="contato_atleta_whatsapp">
                        <cfset VARIABLES.saudeHistoryTitle = "WhatsApp do atleta aberto"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-brands fa-whatsapp"/>
                        <cfset VARIABLES.saudeHistoryTone = "success"/>
                    </cfcase>
                    <cfcase value="contato_atleta_telefone">
                        <cfset VARIABLES.saudeHistoryTitle = "Ligação para o atleta iniciada"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-phone"/>
                        <cfset VARIABLES.saudeHistoryTone = "blue"/>
                    </cfcase>
                    <cfcase value="contato_emergencia_whatsapp">
                        <cfset VARIABLES.saudeHistoryTitle = "WhatsApp do contato de emergência aberto"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-brands fa-whatsapp"/>
                        <cfset VARIABLES.saudeHistoryTone = "success"/>
                    </cfcase>
                    <cfcase value="contato_emergencia_telefone">
                        <cfset VARIABLES.saudeHistoryTitle = "Ligação para o contato de emergência iniciada"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-phone"/>
                        <cfset VARIABLES.saudeHistoryTone = "blue"/>
                    </cfcase>
                    <cfcase value="anotacao">
                        <cfset VARIABLES.saudeHistoryTitle = "Anotação do operador"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-note-sticky"/>
                        <cfset VARIABLES.saudeHistoryTone = "warning"/>
                    </cfcase>
                    <cfcase value="bib_desvinculado">
                        <cfset VARIABLES.saudeHistoryTitle = "Número de peito desvinculado"/>
                        <cfset VARIABLES.saudeHistoryIcon = "fa-solid fa-link-slash"/>
                    </cfcase>
                    <cfdefaultcase>
                        <cfset VARIABLES.saudeHistoryTitle = len(trim(qSaudeHistory.status_novo & ''))
                            ? "Status alterado para " & saudeStatusName(qSaudeHistory.status_novo)
                            : "Registro devolvido à lista da prova"/>
                    </cfdefaultcase>
                </cfswitch>
                <article class="saude-history-item is-#VARIABLES.saudeHistoryTone#">
                    <span class="saude-history-icon"><i class="#VARIABLES.saudeHistoryIcon#"></i></span>
                    <div class="saude-history-content">
                        <div class="saude-history-row">
                            <strong>#htmlEditFormat(VARIABLES.saudeHistoryTitle)#</strong>
                            <time datetime="#dateFormat(qSaudeHistory.data_alteracao, 'yyyy-mm-dd')#T#timeFormat(qSaudeHistory.data_alteracao, 'HH:mm:ss')#">#htmlEditFormat(saudeFriendlyTimestamp(qSaudeHistory.data_alteracao))#</time>
                        </div>
                        <cfif lCase(trim(qSaudeHistory.tipo_acao & '')) EQ "anotacao" AND NOT VARIABLES.saudeCanViewMedicalData>
                            <p><i class="fa-solid fa-lock"></i> Conteúdo protegido por sigilo médico.</p>
                        <cfelseif len(trim(qSaudeHistory.descricao & ''))><p>#htmlEditFormat(qSaudeHistory.descricao)#</p></cfif>
                        <cfif lCase(trim(qSaudeHistory.tipo_acao & '')) EQ "status">
                            <div class="saude-history-transition">
                                <span>#htmlEditFormat(saudeStatusName(qSaudeHistory.status_anterior))#</span>
                                <i class="fa-solid fa-arrow-right"></i>
                                <span>#htmlEditFormat(saudeStatusName(qSaudeHistory.status_novo))#</span>
                            </div>
                        </cfif>
                        <div class="saude-history-meta">
                            <span><i class="fa-solid fa-user"></i> #htmlEditFormat(qSaudeHistory.autor_exibicao)#</span>
                            <span><i class="fa-solid fa-flag-checkered"></i> #htmlEditFormat(qSaudeHistory.evento_exibicao)# · <cfif len(trim(qSaudeHistory.num_peito & ''))>BIB #qSaudeHistory.num_peito#<cfelse>Sem BIB</cfif></span>
                        </div>
                    </div>
                </article>
            </cfloop>
        </cfif>
    </div>
</div>
</cfoutput>
