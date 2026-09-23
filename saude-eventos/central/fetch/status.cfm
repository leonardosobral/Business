<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfparam name="FORM.id_evento" default="0"/>
<cfparam name="FORM.id_inscricao" default="0"/>
<cfparam name="FORM.status" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeStatusAllowed = "scan,diligencia,atendimento,atendido"/>
<cfset VARIABLES.saudeStatusValue = lCase(trim(FORM.status & ""))/>
<cfset VARIABLES.saudeStatusActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeStatusActorName = isDefined("qPerfil") AND qPerfil.recordcount ? left(trim(qPerfil.name & ""), 160) : "Operador do Business"/>
<cfset VARIABLES.saudeStatusIp = trim(listFirst(CGI.REMOTE_ADDR & "", ","))/>
<cfif NOT reFindNoCase("^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-f:]+$", VARIABLES.saudeStatusIp)>
    <cfset VARIABLES.saudeStatusIp = ""/>
</cfif>
<cfset VARIABLES.saudeStatusStage = "validacao"/>

<cfif CGI.REQUEST_METHOD NEQ "POST">
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfoutput>#serializeJSON({success=false,message="Use o formulário do painel para alterar o atendimento."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT VARIABLES.saudeCanOperate>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="Somente Médicos e Admins Globais podem alterar o status do atendimento."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT structKeyExists(SESSION, "saudeBusinessCsrfToken")
    OR NOT len(trim(SESSION.saudeBusinessCsrfToken & ""))
    OR compare(FORM.csrf_token & "", SESSION.saudeBusinessCsrfToken & "") NEQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="A sessão de segurança expirou. Recarregue o painel."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT isNumeric(FORM.id_evento) OR val(FORM.id_evento) LTE 0
    OR NOT isNumeric(FORM.id_inscricao) OR val(FORM.id_inscricao) LTE 0
    OR (len(VARIABLES.saudeStatusValue) AND NOT listFindNoCase(VARIABLES.saudeStatusAllowed, VARIABLES.saudeStatusValue))>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Dados de atendimento inválidos."})#</cfoutput>
    <cfabort/>
</cfif>

<cftry>
    <cftransaction>
        <cfset VARIABLES.saudeStatusStage = "evento"/>
        <cfquery name="qSaudeStatusEvent" datasource="runner_dba">
            SELECT cfg.id_evento
            FROM tb_evento_saude_config cfg
            WHERE cfg.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND cfg.ativo = true
            FOR UPDATE
        </cfquery>
        <cfif NOT qSaudeStatusEvent.recordcount>
            <cfthrow type="Saude.EventoIndisponivel" message="O painel deste evento não está ativo."/>
        </cfif>

        <cfset VARIABLES.saudeStatusStage = "atleta"/>
        <cfquery name="qSaudeStatusAthlete" datasource="runner_dba">
            SELECT num_pedido, num_peito, id_usuario, observacoes
            FROM tb_inscricoes
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
            FOR UPDATE
        </cfquery>
        <cfif NOT qSaudeStatusAthlete.recordcount>
            <cfthrow type="Saude.AtletaNaoEncontrado" message="Atleta não encontrado neste evento."/>
        </cfif>

        <cfset VARIABLES.saudeStatusStage = "atualizacao"/>
        <cfquery name="qSaudeStatusUpdate" datasource="runner_dba" result="qSaudeStatusUpdateMeta">
            UPDATE tb_inscricoes
            SET observacoes = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeStatusValue#" null="#NOT len(VARIABLES.saudeStatusValue)#"/>,
                data_scan = CASE
                    WHEN <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeStatusValue#" null="#NOT len(VARIABLES.saudeStatusValue)#"/> IS NOT NULL
                         AND data_scan IS NULL THEN now()
                    ELSE data_scan
                END
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
        </cfquery>
        <cfif NOT structKeyExists(qSaudeStatusUpdateMeta, "recordCount") OR val(qSaudeStatusUpdateMeta.recordCount) NEQ 1>
            <cfthrow type="Saude.AtletaNaoAtualizado" message="O atendimento não pôde ser localizado para atualização."/>
        </cfif>

        <cfset VARIABLES.saudeStatusStage = "historico"/>
        <cfquery datasource="runner_dba">
            INSERT INTO tb_evento_saude_historico
            (
                id_evento, num_pedido, num_peito, id_usuario_atleta,
                status_anterior, status_novo, tipo_acao, descricao, origem,
                id_usuario_operador, autor_nome, endereco_ip
            )
            VALUES
            (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeStatusAthlete.num_pedido#" null="#NOT len(trim(qSaudeStatusAthlete.num_pedido & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeStatusAthlete.num_peito#" null="#!len(trim(qSaudeStatusAthlete.num_peito & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeStatusAthlete.id_usuario#" null="#NOT len(trim(qSaudeStatusAthlete.id_usuario & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qSaudeStatusAthlete.observacoes#" null="#NOT len(trim(qSaudeStatusAthlete.observacoes & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeStatusValue#" null="#NOT len(VARIABLES.saudeStatusValue)#"/>,
                'status',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#len(VARIABLES.saudeStatusValue) ? 'Status atualizado na Central de Saúde.' : 'Registro marcado como falso positivo e devolvido à lista da prova.'#"/>,
                'business_central',
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeStatusActorId#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeStatusActorName#"/>,
                CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeStatusIp#" null="#!len(VARIABLES.saudeStatusIp)#"/> AS inet)
            )
        </cfquery>
    </cftransaction>
    <cfoutput>#serializeJSON({success=true,status=VARIABLES.saudeStatusValue,message="Atendimento atualizado."})#</cfoutput>
    <cfcatch type="Saude">
        <cfheader statuscode="404" statustext="Not Found"/>
        <cfoutput>#serializeJSON({success=false,message=cfcatch.message})#</cfoutput>
    </cfcatch>
    <cfcatch type="any">
        <cflog file="business-saude-eventos" type="error" text="status_update stage=#VARIABLES.saudeStatusStage# event=#int(FORM.id_evento)# registration=#int(FORM.id_inscricao)# actor=#VARIABLES.saudeStatusActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(structKeyExists(cfcatch, 'detail') ? cfcatch.detail & '' : '', 3000)# code=#structKeyExists(cfcatch, 'errorCode') ? cfcatch.errorCode & '' : ''#"/>
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false,message="Não foi possível atualizar o atendimento."})#</cfoutput>
    </cfcatch>
</cftry>
