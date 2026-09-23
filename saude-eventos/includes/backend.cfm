<cfprocessingdirective pageencoding="utf-8"/>

<cfscript>
function saudeConfigBoolean(required any value) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,t,yes,sim,on", trim(arguments.value & "")) GT 0;
}

function saudeConfigLocalDateTime(any value="") {
    if (isDate(arguments.value)) return dateTimeFormat(arguments.value, "yyyy-mm-dd'T'HH:nn");
    return "";
}

function saudeConfigSafeReturn(required numeric eventId) {
    return "./?id_evento=" & int(arguments.eventId) & "&sucesso=salvo##configuracao";
}

function saudeConfigWhatsapp(any value="") {
    var digits = reReplace(arguments.value & "", "[^0-9]", "", "all");
    if (len(digits) EQ 10 OR len(digits) EQ 11) digits = "55" & digits;
    return digits;
}
</cfscript>

<cfparam name="URL.busca" default=""/>
<cfparam name="URL.status" default="todos"/>
<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.sucesso" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeConfigActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeConfigIsGlobalAdmin = isDefined("VARIABLES.businessEffectiveIsAdmin") AND saudeConfigBoolean(VARIABLES.businessEffectiveIsAdmin)/>
<cfset VARIABLES.saudeConfigIsMedical = isDefined("VARIABLES.businessCurrentAccountRole")
    AND compareNoCase(trim(VARIABLES.businessCurrentAccountRole & ""), "MEDICO") EQ 0
    AND NOT VARIABLES.saudeConfigIsGlobalAdmin/>
<cfset VARIABLES.saudeConfigViewIds = "0"/>
<cfset VARIABLES.saudeConfigWriteIds = "0"/>
<cfif isDefined("qEventosConta") AND qEventosConta.recordcount>
    <cfset VARIABLES.saudeConfigViewIds = valueList(qEventosConta.id_evento)/>
</cfif>
<cfif isDefined("qEventosContaOperacao") AND qEventosContaOperacao.recordcount>
    <cfset VARIABLES.saudeConfigWriteIds = valueList(qEventosContaOperacao.id_evento)/>
</cfif>

<cfif NOT structKeyExists(SESSION, "saudeEventosCsrf") OR NOT len(trim(SESSION.saudeEventosCsrf & ""))>
    <cfset SESSION.saudeEventosCsrf = lCase(hash(createUUID() & now() & rand(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.saudeConfigCsrf = SESSION.saudeEventosCsrf/>
<cfset VARIABLES.saudeConfigAlert = {type="", message=""}/>
<cfset VARIABLES.saudeConfigReady = false/>

<cftry>
    <cfquery name="qSaudeConfigSchema">
        SELECT to_regclass('public.tb_evento_saude_config') IS NOT NULL
               AND to_regclass('public.tb_evento_saude_historico') IS NOT NULL AS ready
    </cfquery>
    <cfset VARIABLES.saudeConfigReady = qSaudeConfigSchema.recordcount AND saudeConfigBoolean(qSaudeConfigSchema.ready)/>
    <cfcatch type="any"><cfset VARIABLES.saudeConfigReady = false/></cfcatch>
</cftry>

<cfif URL.sucesso EQ "salvo">
    <cfset VARIABLES.saudeConfigAlert = {type="success", message="Configuração da operação de saúde atualizada."}/>
</cfif>

<cfif FORM.acao EQ "salvar">
    <cfif NOT VARIABLES.saudeConfigReady>
        <cfset VARIABLES.saudeConfigAlert = {type="danger", message="A estrutura de dados da operação de saúde ainda não foi instalada."}/>
    <cfelseif compare(FORM.csrf_token, VARIABLES.saudeConfigCsrf) NEQ 0>
        <cfset VARIABLES.saudeConfigAlert = {type="danger", message="A sessão expirou. Recarregue a página e tente novamente."}/>
    <cfelseif NOT isDefined("FORM.id_evento") OR NOT isNumeric(FORM.id_evento) OR val(FORM.id_evento) LTE 0>
        <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Selecione um evento válido."}/>
    <cfelse>
        <cfset VARIABLES.saudeConfigSaveEventId = int(FORM.id_evento)/>
        <cfset VARIABLES.saudeConfigCanWriteEvent = NOT VARIABLES.saudeConfigIsMedical
            AND (VARIABLES.saudeConfigIsGlobalAdmin OR listFind(VARIABLES.saudeConfigWriteIds, VARIABLES.saudeConfigSaveEventId))/>
        <cfif NOT VARIABLES.saudeConfigCanWriteEvent>
            <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Você não possui permissão operacional para configurar este evento."}/>
        <cfelse>
            <cfquery name="qSaudeConfigSaveEvent">
                SELECT evt.id_evento
                FROM tb_evento_corridas evt
                WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSaveEventId#"/>
                  AND evt.ativo = true
            </cfquery>
            <cfset VARIABLES.saudeConfigActive = structKeyExists(FORM, "ativo") AND saudeConfigBoolean(FORM.ativo)/>
            <cfset VARIABLES.saudeConfigCourse = isDefined("FORM.percurso_padrao") AND isNumeric(FORM.percurso_padrao) ? FORM.percurso_padrao : ""/>
            <cfset VARIABLES.saudeConfigRefresh = isDefined("FORM.intervalo_atualizacao") AND isNumeric(FORM.intervalo_atualizacao) ? int(FORM.intervalo_atualizacao) : 15/>
            <cfset VARIABLES.saudeConfigRefresh = min(300, max(10, VARIABLES.saudeConfigRefresh))/>
            <cfset VARIABLES.saudeConfigStart = isDefined("FORM.inicio_operacao") AND len(trim(FORM.inicio_operacao)) AND isDate(FORM.inicio_operacao) ? parseDateTime(FORM.inicio_operacao) : ""/>
            <cfset VARIABLES.saudeConfigEnd = isDefined("FORM.fim_operacao") AND len(trim(FORM.fim_operacao)) AND isDate(FORM.fim_operacao) ? parseDateTime(FORM.fim_operacao) : ""/>
            <cfset VARIABLES.saudeConfigName = left(trim(isDefined("FORM.nome_operacao") ? FORM.nome_operacao : ""), 120)/>
            <cfset VARIABLES.saudeConfigLocation = left(trim(isDefined("FORM.local_atendimento") ? FORM.local_atendimento : ""), 180)/>
            <cfset VARIABLES.saudeConfigMedicalDirectorInput = trim(isDefined("FORM.id_diretor_medico") ? FORM.id_diretor_medico : "")/>
            <cfset VARIABLES.saudeConfigMedicalDirectorId = len(VARIABLES.saudeConfigMedicalDirectorInput) AND isNumeric(VARIABLES.saudeConfigMedicalDirectorInput) AND val(VARIABLES.saudeConfigMedicalDirectorInput) GT 0 ? int(VARIABLES.saudeConfigMedicalDirectorInput) : ""/>
            <cfset VARIABLES.saudeConfigMedicalDirector = ""/>
            <cfset VARIABLES.saudeConfigMedicalWhatsapp = saudeConfigWhatsapp(isDefined("FORM.whatsapp_equipe") ? FORM.whatsapp_equipe : "")/>
            <cfset VARIABLES.saudeConfigInstructions = left(trim(isDefined("FORM.instrucoes") ? FORM.instrucoes : ""), 4000)/>

            <cfif len(VARIABLES.saudeConfigMedicalDirectorInput) AND NOT len(VARIABLES.saudeConfigMedicalDirectorId)>
                <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Selecione um diretor médico válido."}/>
            <cfelseif len(VARIABLES.saudeConfigMedicalDirectorId)>
                <cfquery name="qSaudeConfigMedicalDirectorCheck">
                    SELECT usr.id, usr.name
                    FROM tb_conta_eventos ce
                    INNER JOIN tb_contas cont
                        ON cont.id_conta = ce.id_conta
                       AND cont.status = 'ATIVA'::status_conta
                    INNER JOIN tb_conta_usuarios cu
                        ON cu.id_conta = ce.id_conta
                       AND cu.id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeConfigMedicalDirectorId#"/>
                       AND cu.papel = 'MEDICO'::papel_usuario_conta
                       AND cu.status = 'ATIVO'::status_usuario_conta
                    INNER JOIN tb_usuarios usr ON usr.id = cu.id_usuario
                    WHERE ce.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSaveEventId#"/>
                      AND ce.status = 'ATIVO'::status_conta_evento
                      <cfif NOT VARIABLES.saudeConfigIsGlobalAdmin>
                          AND ce.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
                      </cfif>
                    ORDER BY usr.name, usr.email
                    LIMIT 1
                </cfquery>
                <cfif qSaudeConfigMedicalDirectorCheck.recordcount>
                    <cfset VARIABLES.saudeConfigMedicalDirector = left(trim(qSaudeConfigMedicalDirectorCheck.name & ""), 160)/>
                <cfelse>
                    <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Selecione um médico ativo da conta responsável pelo evento."}/>
                </cfif>
            </cfif>

            <cfif NOT qSaudeConfigSaveEvent.recordcount>
                <cfset VARIABLES.saudeConfigAlert = {type="danger", message="O evento selecionado não está disponível."}/>
            <cfelseif VARIABLES.saudeConfigActive AND NOT len(VARIABLES.saudeConfigCourse)>
                <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Escolha o percurso padrão antes de ativar o painel."}/>
            <cfelseif len(VARIABLES.saudeConfigStart) AND len(VARIABLES.saudeConfigEnd) AND VARIABLES.saudeConfigEnd LT VARIABLES.saudeConfigStart>
                <cfset VARIABLES.saudeConfigAlert = {type="danger", message="O encerramento da operação não pode ser anterior ao início."}/>
            <cfelseif len(VARIABLES.saudeConfigMedicalWhatsapp) AND (len(VARIABLES.saudeConfigMedicalWhatsapp) LT 10 OR len(VARIABLES.saudeConfigMedicalWhatsapp) GT 15)>
                <cfset VARIABLES.saudeConfigAlert = {type="danger", message="Informe um WhatsApp válido, com DDD e número."}/>
            <cfelseif len(VARIABLES.saudeConfigCourse)>
                <cfquery name="qSaudeConfigCourseCheck">
                    SELECT 1
                    FROM tb_evento_corridas_percursos
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSaveEventId#"/>
                      AND percurso_evento = <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.saudeConfigCourse#"/>
                </cfquery>
                <cfif NOT qSaudeConfigCourseCheck.recordcount>
                    <cfset VARIABLES.saudeConfigAlert = {type="danger", message="O percurso selecionado não pertence a este evento."}/>
                </cfif>
            </cfif>

            <cfif NOT len(VARIABLES.saudeConfigAlert.message)>
                <cfquery>
                    INSERT INTO tb_evento_saude_config
                    (
                        id_evento, ativo, nome_operacao, percurso_padrao,
                        intervalo_atualizacao, inicio_operacao, fim_operacao,
                        local_atendimento, id_diretor_medico, diretor_medico, whatsapp_equipe,
                        instrucoes, id_usuario_atualizacao,
                        data_atualizacao
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSaveEventId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.saudeConfigActive#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#len(VARIABLES.saudeConfigName) ? VARIABLES.saudeConfigName : 'Central de Saúde'#"/>,
                        <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.saudeConfigCourse#" null="#NOT len(VARIABLES.saudeConfigCourse)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigRefresh#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.saudeConfigStart#" null="#NOT len(VARIABLES.saudeConfigStart)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.saudeConfigEnd#" null="#NOT len(VARIABLES.saudeConfigEnd)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeConfigLocation#" null="#NOT len(VARIABLES.saudeConfigLocation)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeConfigMedicalDirectorId#" null="#NOT len(VARIABLES.saudeConfigMedicalDirectorId)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeConfigMedicalDirector#" null="#NOT len(VARIABLES.saudeConfigMedicalDirector)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeConfigMedicalWhatsapp#" null="#NOT len(VARIABLES.saudeConfigMedicalWhatsapp)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.saudeConfigInstructions#" null="#NOT len(VARIABLES.saudeConfigInstructions)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeConfigActorId#" null="#VARIABLES.saudeConfigActorId LTE 0#"/>,
                        now()
                    )
                    ON CONFLICT (id_evento) DO UPDATE SET
                        ativo = excluded.ativo,
                        nome_operacao = excluded.nome_operacao,
                        percurso_padrao = excluded.percurso_padrao,
                        intervalo_atualizacao = excluded.intervalo_atualizacao,
                        inicio_operacao = excluded.inicio_operacao,
                        fim_operacao = excluded.fim_operacao,
                        local_atendimento = excluded.local_atendimento,
                        id_diretor_medico = excluded.id_diretor_medico,
                        diretor_medico = excluded.diretor_medico,
                        whatsapp_equipe = excluded.whatsapp_equipe,
                        instrucoes = excluded.instrucoes,
                        id_usuario_atualizacao = excluded.id_usuario_atualizacao,
                        data_atualizacao = now()
                </cfquery>
                <cflocation addtoken="false" url="#saudeConfigSafeReturn(VARIABLES.saudeConfigSaveEventId)#"/>
            </cfif>
        </cfif>
    </cfif>
</cfif>

<cfset VARIABLES.saudeConfigSelectedId = isNumeric(URL.id_evento) ? int(URL.id_evento) : 0/>
<cfset qSaudeConfigEvents = queryNew("id_evento,nome_evento,data_inicial,data_final,cidade,estado,ativo_painel,nome_operacao,percurso_padrao,intervalo_atualizacao,inicio_operacao,fim_operacao,local_atendimento,diretor_medico,whatsapp_equipe,instrucoes,data_atualizacao,percursos,total_atletas,aguardando_triagem,em_atendimento,atendidos")/>
<cfset qSaudeConfigSelected = queryNew("id_evento,nome_evento,data_inicial,data_final,cidade,estado,ativo_painel,nome_operacao,percurso_padrao,intervalo_atualizacao,inicio_operacao,fim_operacao,local_atendimento,id_diretor_medico,diretor_medico,whatsapp_equipe,instrucoes,data_atualizacao")/>
<cfset qSaudeConfigCourses = queryNew("percurso_evento,unidade_de_medida,tipo_corrida")/>
<cfset qSaudeConfigDoctors = queryNew("id_usuario,nome,email,nome_conta")/>

<cfif VARIABLES.saudeConfigReady>
    <cfquery name="qSaudeConfigEvents">
        SELECT evt.id_evento,
               evt.nome_evento,
               evt.data_inicial,
               evt.data_final,
               evt.cidade,
               evt.estado,
               coalesce(cfg.ativo, false) AS ativo_painel,
               coalesce(cfg.nome_operacao, 'Central de Saúde') AS nome_operacao,
               cfg.percurso_padrao,
               coalesce(cfg.intervalo_atualizacao, 15) AS intervalo_atualizacao,
               cfg.inicio_operacao,
               cfg.fim_operacao,
               cfg.local_atendimento,
               cfg.diretor_medico,
               cfg.whatsapp_equipe,
               cfg.instrucoes,
               cfg.data_atualizacao,
               coalesce(rotas.percursos, 'Sem percursos') AS percursos,
               coalesce(operacao.total_atletas, 0) AS total_atletas,
               coalesce(operacao.aguardando_triagem, 0) AS aguardando_triagem,
               coalesce(operacao.em_atendimento, 0) AS em_atendimento,
               coalesce(operacao.atendidos, 0) AS atendidos
        FROM tb_evento_corridas evt
        LEFT JOIN tb_evento_saude_config cfg ON cfg.id_evento = evt.id_evento
        LEFT JOIN LATERAL (
            SELECT string_agg(p.percurso_evento::text || lower(coalesce(p.unidade_de_medida, 'km')), ' · ' ORDER BY p.percurso_evento) AS percursos
            FROM tb_evento_corridas_percursos p
            WHERE p.id_evento = evt.id_evento
        ) rotas ON true
        LEFT JOIN LATERAL (
            SELECT count(*) AS total_atletas,
                   count(*) FILTER (WHERE ins.observacoes IN ('scan','acionado')) AS aguardando_triagem,
                   count(*) FILTER (WHERE ins.observacoes IN ('diligencia','atendimento')) AS em_atendimento,
                   count(*) FILTER (WHERE ins.observacoes = 'atendido') AS atendidos
            FROM tb_inscricoes ins
            WHERE ins.id_evento = evt.id_evento
        ) operacao ON cfg.id_evento IS NOT NULL
        WHERE evt.ativo = true
          AND (evt.data_final >= current_date - interval '365 days' OR cfg.id_evento IS NOT NULL)
          <cfif NOT VARIABLES.saudeConfigIsGlobalAdmin>
              AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigViewIds#" list="true"/>)
          </cfif>
          <cfif len(trim(URL.busca))>
              AND (evt.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
                   OR evt.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
                   OR evt.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.busca)#"/>)
          </cfif>
          <cfswitch expression="#URL.status#">
              <cfcase value="ativos">AND cfg.ativo = true</cfcase>
              <cfcase value="inativos">AND cfg.id_evento IS NOT NULL AND cfg.ativo = false</cfcase>
              <cfcase value="nao_configurados">AND cfg.id_evento IS NULL</cfcase>
          </cfswitch>
        ORDER BY coalesce(cfg.ativo, false) DESC,
                 CASE WHEN evt.data_final >= current_date THEN 0 ELSE 1 END,
                 CASE WHEN evt.data_final >= current_date THEN evt.data_inicial END,
                 evt.data_final DESC,
                 evt.nome_evento
        LIMIT 150
    </cfquery>

    <cfif VARIABLES.saudeConfigSelectedId GT 0>
        <cfquery name="qSaudeConfigSelected">
            SELECT evt.id_evento, evt.nome_evento, evt.data_inicial, evt.data_final,
                   evt.cidade, evt.estado, coalesce(cfg.ativo, false) AS ativo_painel,
                   coalesce(cfg.nome_operacao, 'Central de Saúde') AS nome_operacao,
                   cfg.percurso_padrao, coalesce(cfg.intervalo_atualizacao, 15) AS intervalo_atualizacao,
                   cfg.inicio_operacao, cfg.fim_operacao, cfg.local_atendimento,
                   cfg.id_diretor_medico,
                   coalesce(nullif(trim(diretor.name), ''), cfg.diretor_medico) AS diretor_medico,
                   cfg.whatsapp_equipe, cfg.instrucoes, cfg.data_atualizacao
            FROM tb_evento_corridas evt
            LEFT JOIN tb_evento_saude_config cfg ON cfg.id_evento = evt.id_evento
            LEFT JOIN tb_usuarios diretor ON diretor.id = cfg.id_diretor_medico
            WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSelectedId#"/>
              AND evt.ativo = true
              <cfif NOT VARIABLES.saudeConfigIsGlobalAdmin>
                  AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigViewIds#" list="true"/>)
              </cfif>
        </cfquery>
        <cfif qSaudeConfigSelected.recordcount>
            <cfquery name="qSaudeConfigCourses">
                SELECT percurso_evento, unidade_de_medida, tipo_corrida
                FROM tb_evento_corridas_percursos
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSelectedId#"/>
                ORDER BY percurso_evento
            </cfquery>
            <cfquery name="qSaudeConfigDoctors">
                SELECT DISTINCT usr.id AS id_usuario,
                       usr.name AS nome,
                       usr.email,
                       cont.nome_conta
                FROM tb_conta_eventos ce
                INNER JOIN tb_contas cont
                    ON cont.id_conta = ce.id_conta
                   AND cont.status = 'ATIVA'::status_conta
                INNER JOIN tb_conta_usuarios cu
                    ON cu.id_conta = ce.id_conta
                   AND cu.papel = 'MEDICO'::papel_usuario_conta
                   AND cu.status = 'ATIVO'::status_usuario_conta
                INNER JOIN tb_usuarios usr ON usr.id = cu.id_usuario
                WHERE ce.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeConfigSelectedId#"/>
                  AND ce.status = 'ATIVO'::status_conta_evento
                  <cfif NOT VARIABLES.saudeConfigIsGlobalAdmin>
                      AND ce.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
                  </cfif>
                ORDER BY usr.name, usr.email, cont.nome_conta
            </cfquery>
        <cfelse>
            <cfset VARIABLES.saudeConfigSelectedId = 0/>
        </cfif>
    </cfif>
</cfif>
