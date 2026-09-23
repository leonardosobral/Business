<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfparam name="FORM.id_evento" default="0"/>
<cfparam name="FORM.id_inscricao" default="0"/>
<cfparam name="FORM.anotacao" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeNoteActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeNoteActorName = isDefined("qPerfil") AND qPerfil.recordcount ? left(trim(qPerfil.name & ""), 160) : "Operador do Business"/>
<cfset VARIABLES.saudeNoteText = left(trim(FORM.anotacao & ""), 2000)/>
<cfset VARIABLES.saudeNoteIp = trim(listFirst(CGI.REMOTE_ADDR & "", ","))/>
<cfif NOT reFindNoCase("^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-f:]+$", VARIABLES.saudeNoteIp)>
    <cfset VARIABLES.saudeNoteIp = ""/>
</cfif>

<cfif CGI.REQUEST_METHOD NEQ "POST">
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfoutput>#serializeJSON({success=false,message="Use a ficha do atleta para adicionar uma anotação."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT VARIABLES.saudeCanOperate>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="Somente Médicos e Admins Globais podem registrar anotações."})#</cfoutput>
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
    OR NOT len(VARIABLES.saudeNoteText)>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Informe uma anotação para este atleta."})#</cfoutput>
    <cfabort/>
</cfif>

<cftry>
    <cfquery name="qSaudeNoteAthlete" datasource="runner_dba">
        SELECT ins.num_pedido, ins.num_peito, ins.id_usuario
        FROM tb_inscricoes ins
        INNER JOIN tb_evento_saude_config cfg ON cfg.id_evento = ins.id_evento AND cfg.ativo = true
        WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
          AND ins.num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
        LIMIT 1
    </cfquery>

    <cfif NOT qSaudeNoteAthlete.recordcount>
        <cfheader statuscode="404" statustext="Not Found"/>
        <cfoutput>#serializeJSON({success=false,message="Atleta não encontrado neste evento ativo."})#</cfoutput>
        <cfabort/>
    </cfif>

    <cfquery datasource="runner_dba">
        INSERT INTO tb_evento_saude_historico
        (
            id_evento, num_pedido, num_peito, id_usuario_atleta,
            tipo_acao, descricao, origem,
            id_usuario_operador, autor_nome, endereco_ip
        )
        VALUES
        (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeNoteAthlete.num_pedido#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeNoteAthlete.num_peito#" null="#!len(trim(qSaudeNoteAthlete.num_peito & ''))#"/>,
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeNoteAthlete.id_usuario#" null="#!len(trim(qSaudeNoteAthlete.id_usuario & ''))#"/>,
            'anotacao',
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeNoteText#"/>,
            'business_central',
            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeNoteActorId#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeNoteActorName#"/>,
            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeNoteIp#" null="#!len(VARIABLES.saudeNoteIp)#"/> AS inet)
        )
    </cfquery>

    <cfoutput>#serializeJSON({success=true,message="Anotação adicionada à cronologia."})#</cfoutput>
    <cfcatch type="any">
        <cflog file="business-saude-eventos" type="error" text="note_create event=#int(FORM.id_evento)# registration=#int(FORM.id_inscricao)# actor=#VARIABLES.saudeNoteActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(structKeyExists(cfcatch, 'detail') ? cfcatch.detail & '' : '', 3000)#"/>
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false,message="Não foi possível adicionar a anotação."})#</cfoutput>
    </cfcatch>
</cftry>
