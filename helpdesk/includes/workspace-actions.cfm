<!--- Included only after the authenticated global-admin gate. Public support stays unchanged. --->
<cfif NOT structKeyExists(VARIABLES,"helpdeskCanManage") OR NOT VARIABLES.helpdeskCanManage><cfheader statuscode="403" statustext="Forbidden"/><cfabort/></cfif>
<cfif structKeyExists(FORM,"helpdesk_action")>
  <cfif CGI.request_method NEQ "POST" OR NOT structKeyExists(FORM,"helpdesk_csrf") OR compare(FORM.helpdesk_csrf,SESSION.helpdeskCsrf) NEQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/><cfoutput><p>Sessão de atendimento expirada. Volte ao chamado e recarregue a página antes de tentar novamente.</p></cfoutput><cfabort/>
  </cfif>
  <cfif listFindNoCase("responder_ticket,atualizar_ticket",FORM.helpdesk_action)>
    <cfset helpdeskAdminHandled=true/>
    <cfset hdMessage=trim(FORM.ticket_mensagem ?: "")/>
    <cfset hdNextStatus=lCase(trim(FORM.ticket_status ?: ""))/>
    <cfset hdActionReply=FORM.helpdesk_action EQ "responder_ticket"/>
    <cfif NOT reFind("^[0-9]{1,9}$",FORM.ticket_id ?: "") OR NOT reFind("^[0-9]{1,9}$",FORM.ticket_setor_id ?: "") OR NOT listFindNoCase("aberto,cliente_respondeu,em_atendimento,aguardando_cliente,resolvido,fechado",hdNextStatus)>
      <cfset hdError="Selecione um chamado, um setor e um status válidos."/>
    <cfelseif hdActionReply AND (NOT len(hdMessage) OR len(hdMessage) GT 12000)>
      <cfset hdError="Escreva uma resposta entre 1 e 12.000 caracteres. Seu texto foi preservado."/>
    <cfelse>
      <cftry>
        <cftransaction>
          <cfquery name="hdLocked">
            SELECT id_chamado,id_setor,to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US') AS revision,
              (SELECT coalesce(max(id_mensagem),0) FROM tb_helpdesk_mensagens WHERE id_chamado=tb_helpdesk_chamados.id_chamado) AS last_message_id
            FROM tb_helpdesk_chamados WHERE id_chamado=<cfqueryparam value="#FORM.ticket_id#" cfsqltype="cf_sql_integer"/> FOR UPDATE
          </cfquery>
          <cfif NOT hdLocked.recordcount OR compare(hdLocked.revision,FORM.ticket_revision ?: "") NEQ 0 OR hdLocked.last_message_id NEQ val(FORM.ticket_last_message ?: -1)>
            <cfthrow type="Helpdesk.Conflict" message="O chamado recebeu uma atualização enquanto você atendia. Leia a conversa atualizada e revise sua resposta antes de tentar novamente. Seu texto foi preservado."/>
          </cfif>
          <cfquery name="hdValidSector">
            SELECT id_setor FROM tb_helpdesk_setores WHERE id_setor=<cfqueryparam value="#FORM.ticket_setor_id#" cfsqltype="cf_sql_integer"/>
            AND (ativo=true OR id_setor=<cfqueryparam value="#hdLocked.id_setor#" cfsqltype="cf_sql_integer"/>)
          </cfquery>
          <cfif NOT hdValidSector.recordcount><cfthrow type="Helpdesk.Validation" message="Escolha um setor ativo. O setor atual pode ser mantido."/></cfif>
          <cfquery>
            UPDATE tb_helpdesk_chamados SET status=<cfqueryparam value="#hdNextStatus#" cfsqltype="cf_sql_varchar"/>,
            id_setor=<cfqueryparam value="#FORM.ticket_setor_id#" cfsqltype="cf_sql_integer"/>,updated_at=now()
            WHERE id_chamado=<cfqueryparam value="#FORM.ticket_id#" cfsqltype="cf_sql_integer"/>
          </cfquery>
          <cfif hdActionReply>
            <cfquery>
              INSERT INTO tb_helpdesk_mensagens (id_chamado,id_usuario,mensagem,interno,created_at)
              VALUES (<cfqueryparam value="#FORM.ticket_id#" cfsqltype="cf_sql_integer"/>,<cfqueryparam value="#qPerfil.id#" cfsqltype="cf_sql_integer"/>,<cfqueryparam value="#hdMessage#" cfsqltype="cf_sql_longvarchar"/>,false,now())
            </cfquery>
          </cfif>
        </cftransaction>
        <cfif hdActionReply><cftry><cfset helpdeskNotifyTicketOwner(val(FORM.ticket_id),val(qPerfil.id))/><cfcatch type="any"></cfcatch></cftry></cfif>
        <cflocation url="#hdUrl({ticket_id=val(FORM.ticket_id),salvo=hdActionReply ? 'resposta' : 'status'})#" addtoken="false"/>
        <cfcatch type="Helpdesk.Conflict"><cfset hdError=cfcatch.message/></cfcatch>
        <cfcatch type="Helpdesk.Validation"><cfset hdError=cfcatch.message/></cfcatch>
        <cfcatch type="any"><cfset hdError="Não foi possível salvar o atendimento. Seu texto foi preservado; tente novamente em instantes."/></cfcatch>
      </cftry>
    </cfif>
  </cfif>
</cfif>
