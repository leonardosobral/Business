<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfparam name="FORM.id_evento" default="0"/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeTriageActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeTriageActorName = isDefined("qPerfil") AND qPerfil.recordcount ? left(trim(qPerfil.name & ""), 160) : "Operador do Business"/>
<cfset VARIABLES.saudeTriageIp = trim(listFirst(CGI.REMOTE_ADDR & "", ","))/>
<cfif NOT reFindNoCase("^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-f:]+$", VARIABLES.saudeTriageIp)>
    <cfset VARIABLES.saudeTriageIp = ""/>
</cfif>

<cfif CGI.REQUEST_METHOD NEQ "POST">
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfoutput>#serializeJSON({success=false,message="Use a confirmação da Central para limpar a triagem."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT VARIABLES.saudeCanOperate>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="Somente Médicos e Admins Globais podem limpar a triagem."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT structKeyExists(SESSION, "saudeBusinessCsrfToken")
    OR NOT len(trim(SESSION.saudeBusinessCsrfToken & ""))
    OR compare(FORM.csrf_token & "", SESSION.saudeBusinessCsrfToken & "") NEQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="A sessão de segurança expirou. Recarregue o painel."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT isNumeric(FORM.id_evento) OR val(FORM.id_evento) LTE 0>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Evento inválido."})#</cfoutput>
    <cfabort/>
</cfif>

<cftry>
    <cftransaction>
        <cfquery name="qSaudeTriageClear" datasource="runner_dba">
            WITH candidatos AS (
                SELECT ins.ctid AS registro_ctid,
                       ins.num_pedido,
                       ins.num_peito,
                       ins.id_usuario,
                       ins.observacoes
                FROM tb_inscricoes ins
                INNER JOIN tb_evento_saude_config cfg
                    ON cfg.id_evento = ins.id_evento
                   AND cfg.ativo = true
                WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
                  AND ins.num_peito IS NOT NULL
                  AND ins.observacoes IN ('scan', 'acionado')
                FOR UPDATE OF ins
            ), atualizados AS (
                UPDATE tb_inscricoes ins
                SET observacoes = NULL,
                    data_scan = NULL
                FROM candidatos candidato
                WHERE ins.ctid = candidato.registro_ctid
                RETURNING candidato.num_pedido,
                          candidato.num_peito,
                          candidato.id_usuario,
                          candidato.observacoes
            )
            INSERT INTO tb_evento_saude_historico
            (
                id_evento, num_pedido, num_peito, id_usuario_atleta,
                status_anterior, status_novo, tipo_acao, descricao, origem,
                id_usuario_operador, autor_nome, endereco_ip
            )
            SELECT
                <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>,
                atualizados.num_pedido,
                atualizados.num_peito,
                atualizados.id_usuario,
                atualizados.observacoes,
                NULL,
                'triagem_limpa',
                'Triagem limpa em lote; atleta devolvido à Lista da Prova.',
                'business_central',
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeTriageActorId#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeTriageActorName#"/>,
                CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeTriageIp#" null="#!len(VARIABLES.saudeTriageIp)#"/> AS inet)
            FROM atualizados
            RETURNING id_historico
        </cfquery>
    </cftransaction>

    <cfset VARIABLES.saudeTriageTotal = qSaudeTriageClear.recordcount/>
    <cfoutput>#serializeJSON({
        success=true,
        total=VARIABLES.saudeTriageTotal,
        message=VARIABLES.saudeTriageTotal EQ 1
            ? "1 atleta retornou à Lista da Prova."
            : VARIABLES.saudeTriageTotal & " atletas retornaram à Lista da Prova."
    })#</cfoutput>
    <cfcatch type="any">
        <cflog file="business-saude-eventos" type="error" text="triage_clear event=#int(FORM.id_evento)# actor=#VARIABLES.saudeTriageActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(structKeyExists(cfcatch, 'detail') ? cfcatch.detail & '' : '', 3000)#"/>
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false,message="Não foi possível limpar a triagem."})#</cfoutput>
    </cfcatch>
</cftry>
