<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfparam name="FORM.id_evento" default="0"/>
<cfparam name="FORM.id_inscricao" default="0"/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeBibActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeBibActorName = isDefined("qPerfil") AND qPerfil.recordcount ? left(trim(qPerfil.name & ""), 160) : "Operador do Business"/>
<cfset VARIABLES.saudeBibIp = trim(listFirst(CGI.REMOTE_ADDR & "", ","))/>
<cfif NOT reFindNoCase("^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-f:]+$", VARIABLES.saudeBibIp)>
    <cfset VARIABLES.saudeBibIp = ""/>
</cfif>
<cfset VARIABLES.saudeBibStage = "validacao"/>

<cfif CGI.REQUEST_METHOD NEQ "POST">
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfoutput>#serializeJSON({success=false,message="Use a ficha do atleta para desvincular o BIB."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT VARIABLES.saudeCanUnlinkBib>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="Somente Admins Globais podem desvincular um BIB."})#</cfoutput>
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
    OR NOT isNumeric(FORM.id_inscricao) OR val(FORM.id_inscricao) LTE 0>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Evento ou número de peito inválido."})#</cfoutput>
    <cfabort/>
</cfif>

<cftry>
    <cftransaction>
        <cfset VARIABLES.saudeBibStage = "evento"/>
        <cfquery name="qSaudeBibEvent" datasource="runner_dba">
            SELECT cfg.id_evento
            FROM tb_evento_saude_config cfg
            WHERE cfg.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND cfg.ativo = true
            FOR UPDATE
        </cfquery>
        <cfif NOT qSaudeBibEvent.recordcount>
            <cfthrow type="Saude.EventoIndisponivel" message="O painel deste evento não está ativo."/>
        </cfif>

        <cfset VARIABLES.saudeBibStage = "atleta"/>
        <cfquery name="qSaudeBibAthlete" datasource="runner_dba">
            SELECT num_pedido, num_peito, id_usuario, observacoes
            FROM tb_inscricoes
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
              AND num_peito IS NOT NULL
            FOR UPDATE
        </cfquery>
        <cfif NOT qSaudeBibAthlete.recordcount>
            <cfthrow type="Saude.BibNaoEncontrado" message="O BIB informado não está mais vinculado a este evento."/>
        </cfif>

        <cfset VARIABLES.saudeBibStage = "desvinculo"/>
        <cfquery name="qSaudeBibUnlink" datasource="runner_dba">
            WITH desvinculo AS (
                UPDATE tb_inscricoes
                SET num_peito = NULL,
                    observacoes = NULL,
                    data_scan = NULL
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
                  AND num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
                RETURNING num_pedido, id_usuario
            )
            INSERT INTO tb_evento_saude_historico
            (
                id_evento, num_pedido, num_peito, id_usuario_atleta,
                status_anterior, status_novo, tipo_acao, descricao, origem,
                id_usuario_operador, autor_nome, endereco_ip
            )
            SELECT
                <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>,
                desvinculo.num_pedido,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeBibAthlete.num_peito#"/>,
                desvinculo.id_usuario,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qSaudeBibAthlete.observacoes#" null="#NOT len(trim(qSaudeBibAthlete.observacoes & ''))#"/>,
                'bib_desvinculado',
                'bib_desvinculado',
                'Número de peito desvinculado da inscrição.',
                'business_central',
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeBibActorId#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeBibActorName#"/>,
                CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeBibIp#" null="#!len(VARIABLES.saudeBibIp)#"/> AS inet)
            FROM desvinculo
            RETURNING id_historico
        </cfquery>
        <cfif qSaudeBibUnlink.recordcount NEQ 1>
            <cfthrow type="Saude.BibNaoDesvinculado" message="O BIB não pôde ser localizado para desvinculação."/>
        </cfif>
    </cftransaction>

    <cfoutput>#serializeJSON({success=true,message="BIB #qSaudeBibAthlete.num_peito# desvinculado. O número já está livre para outro atleta."})#</cfoutput>
    <cfcatch type="Saude">
        <cfheader statuscode="404" statustext="Not Found"/>
        <cfoutput>#serializeJSON({success=false,message=cfcatch.message})#</cfoutput>
    </cfcatch>
    <cfcatch type="any">
        <cflog file="business-saude-eventos" type="error" text="bib_unlink stage=#VARIABLES.saudeBibStage# event=#int(FORM.id_evento)# registration=#int(FORM.id_inscricao)# actor=#VARIABLES.saudeBibActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(structKeyExists(cfcatch, 'detail') ? cfcatch.detail & '' : '', 3000)# code=#structKeyExists(cfcatch, 'errorCode') ? cfcatch.errorCode & '' : ''#"/>
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false,message="Não foi possível desvincular o BIB."})#</cfoutput>
    </cfcatch>
</cftry>
