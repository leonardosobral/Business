<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfparam name="FORM.id_evento" default="0"/>
<cfparam name="FORM.id_inscricao" default="0"/>
<cfparam name="FORM.contato" default=""/>
<cfparam name="FORM.canal" default=""/>
<cfparam name="FORM.csrf_token" default=""/>

<cfset VARIABLES.saudeContactType = lCase(trim(FORM.contato & ""))/>
<cfset VARIABLES.saudeContactChannel = lCase(trim(FORM.canal & ""))/>
<cfset VARIABLES.saudeContactActorId = isDefined("qPerfil") AND qPerfil.recordcount ? val(qPerfil.id) : 0/>
<cfset VARIABLES.saudeContactActorName = isDefined("qPerfil") AND qPerfil.recordcount ? left(trim(qPerfil.name & ""), 160) : "Operador do Business"/>
<cfset VARIABLES.saudeContactIp = trim(listFirst(CGI.REMOTE_ADDR & "", ","))/>
<cfif NOT reFindNoCase("^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-f:]+$", VARIABLES.saudeContactIp)>
    <cfset VARIABLES.saudeContactIp = ""/>
</cfif>

<cfif CGI.REQUEST_METHOD NEQ "POST">
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfoutput>#serializeJSON({success=false,message="Use os botões da ficha do atleta para iniciar o contato."})#</cfoutput>
    <cfabort/>
</cfif>

<cfif NOT VARIABLES.saudeCanOperate>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfoutput>#serializeJSON({success=false,message="Somente Médicos e Admins Globais podem iniciar contatos pela ficha."})#</cfoutput>
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
    OR NOT listFindNoCase("atleta,emergencia", VARIABLES.saudeContactType)
    OR NOT listFindNoCase("whatsapp,telefone", VARIABLES.saudeContactChannel)>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Dados de contato inválidos."})#</cfoutput>
    <cfabort/>
</cfif>

<cftry>
    <cftransaction>
        <cfquery name="qSaudeContactAthlete" datasource="runner_dba">
            SELECT ins.num_pedido, ins.num_peito, ins.id_usuario, ins.observacoes, usr.ficha_medica
            FROM tb_inscricoes ins
            LEFT JOIN tb_usuarios usr ON usr.id = ins.id_usuario
            INNER JOIN tb_evento_saude_config cfg ON cfg.id_evento = ins.id_evento AND cfg.ativo = true
            WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_evento)#"/>
              AND ins.num_pedido = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(FORM.id_inscricao)#"/>
            LIMIT 1
            FOR UPDATE OF ins
        </cfquery>

        <cfif NOT qSaudeContactAthlete.recordcount>
            <cfthrow type="Saude.ContatoIndisponivel" message="Atleta não encontrado neste evento ativo."/>
        </cfif>

        <cfset VARIABLES.saudeContactMedical = {}/>
        <cfif len(trim(qSaudeContactAthlete.ficha_medica & ""))>
            <cftry>
                <cfset VARIABLES.saudeContactMedical = deserializeJSON(qSaudeContactAthlete.ficha_medica)/>
                <cfcatch type="any"><cfset VARIABLES.saudeContactMedical = {}/></cfcatch>
            </cftry>
        </cfif>

        <cfset VARIABLES.saudeContactKey = VARIABLES.saudeContactType EQ "atleta" ? "celular" : "celularcontato"/>
        <cfset VARIABLES.saudeContactPhone = structKeyExists(VARIABLES.saudeContactMedical, VARIABLES.saudeContactKey)
            ? reReplace(VARIABLES.saudeContactMedical[VARIABLES.saudeContactKey] & "", "[^0-9]", "", "all")
            : ""/>
        <cfif left(VARIABLES.saudeContactPhone, 2) EQ "00">
            <cfset VARIABLES.saudeContactPhone = removeChars(VARIABLES.saudeContactPhone, 1, 2)/>
        </cfif>
        <cfif len(VARIABLES.saudeContactPhone) GTE 10 AND len(VARIABLES.saudeContactPhone) LTE 11>
            <cfset VARIABLES.saudeContactPhone = "55" & VARIABLES.saudeContactPhone/>
        </cfif>
        <cfif NOT reFind("^[0-9]{12,15}$", VARIABLES.saudeContactPhone)>
            <cfthrow type="Saude.ContatoIndisponivel" message="O telefone informado na ficha médica não é válido para contato."/>
        </cfif>

        <cfset VARIABLES.saudeContactPersonLabel = VARIABLES.saudeContactType EQ "atleta" ? "atleta" : "contato de emergência"/>
        <cfset VARIABLES.saudeContactAction = "contato_" & VARIABLES.saudeContactType & "_" & VARIABLES.saudeContactChannel/>
        <cfset VARIABLES.saudeContactDescription = VARIABLES.saudeContactChannel EQ "whatsapp"
            ? "WhatsApp do " & VARIABLES.saudeContactPersonLabel & " aberto pela Central de Saúde."
            : "Ligação para o " & VARIABLES.saudeContactPersonLabel & " iniciada pela Central de Saúde."/>
        <cfset VARIABLES.saudeContactTarget = VARIABLES.saudeContactChannel EQ "whatsapp"
            ? "https://wa.me/" & VARIABLES.saudeContactPhone
            : "tel:+" & VARIABLES.saudeContactPhone/>

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
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeContactAthlete.num_pedido#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeContactAthlete.num_peito#" null="#!len(trim(qSaudeContactAthlete.num_peito & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qSaudeContactAthlete.id_usuario#" null="#!len(trim(qSaudeContactAthlete.id_usuario & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qSaudeContactAthlete.observacoes#" null="#!len(trim(qSaudeContactAthlete.observacoes & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qSaudeContactAthlete.observacoes#" null="#!len(trim(qSaudeContactAthlete.observacoes & ''))#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeContactAction#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeContactDescription#"/>,
                'business_central',
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.saudeContactActorId#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeContactActorName#"/>,
                CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saudeContactIp#" null="#!len(VARIABLES.saudeContactIp)#"/> AS inet)
            )
        </cfquery>
    </cftransaction>

    <cfoutput>#serializeJSON({success=true,message="Contato registrado na cronologia.",target=VARIABLES.saudeContactTarget})#</cfoutput>
    <cfcatch type="Saude.ContatoIndisponivel">
        <cfheader statuscode="422" statustext="Unprocessable Entity"/>
        <cfoutput>#serializeJSON({success=false,message=cfcatch.message})#</cfoutput>
    </cfcatch>
    <cfcatch type="any">
        <cflog file="business-saude-eventos" type="error" text="contact_action event=#int(FORM.id_evento)# registration=#int(FORM.id_inscricao)# contact=#VARIABLES.saudeContactType# channel=#VARIABLES.saudeContactChannel# actor=#VARIABLES.saudeContactActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(structKeyExists(cfcatch, 'detail') ? cfcatch.detail & '' : '', 3000)#"/>
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false,message="Não foi possível iniciar o contato."})#</cfoutput>
    </cfcatch>
</cftry>
