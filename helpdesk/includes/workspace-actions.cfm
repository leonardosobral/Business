<!--- Included only after the authenticated global-admin gate. Public support stays unchanged. --->
<cfif NOT structKeyExists(VARIABLES,"helpdeskCanManage") OR NOT VARIABLES.helpdeskCanManage><cfheader statuscode="403"/><cfabort/></cfif>
<cfif structKeyExists(FORM,"helpdesk_action")>
  <cfif CGI.request_method NEQ "POST" OR NOT structKeyExists(FORM,"helpdesk_csrf") OR compare(FORM.helpdesk_csrf,SESSION.helpdeskCsrf) NEQ 0>
    <cfheader statuscode="403"/><cfoutput><p>Sessão de atendimento expirada. Volte ao chamado e recarregue a página antes de tentar novamente.</p></cfoutput><cfabort/>
  </cfif>
  <cfinclude template="workspace-replies-actions.cfm"/>
  <cfif FORM.helpdesk_action EQ "nota_ticket">
    <cfset helpdeskAdminHandled=true/>
    <cftry>
      <cfif NOT reFind("^[0-9]{1,9}$",FORM.ticket_id ?: "") OR NOT reFind("^[0-9]{1,12}$",FORM.ticket_last_message ?: "")>
        <cfthrow type="HelpdeskNotes.Validation" message="Chamado inválido. Recarregue a página antes de salvar sua nota."/>
      </cfif>
      <cfset createObject('component','helpdesk.includes.HelpdeskNotes').save(val(FORM.ticket_id),val(qPerfil.id),FORM.ticket_mensagem ?: '',FORM.ticket_revision ?: '',val(FORM.ticket_last_message))/>
      <cflocation url="#hdUrl({ticket_id=val(FORM.ticket_id),salvo='nota'})###hd-editor" addtoken="false"/>
      <cfcatch type="HelpdeskNotes.Validation"><cfset hdError=cfcatch.message/></cfcatch>
      <cfcatch type="HelpdeskNotes.Conflict"><cfset hdError=cfcatch.message/></cfcatch>
      <cfcatch type="any"><cfset hdError="Não foi possível salvar a nota interna. Seu texto foi preservado; tente novamente."/></cfcatch>
    </cftry>
  </cfif>
  <cfif listFindNoCase("responder_ticket,atualizar_ticket,fechar_ticket",FORM.helpdesk_action)>
    <cfset helpdeskAdminHandled=true/>
    <cfset hdActionClose=FORM.helpdesk_action EQ "fechar_ticket"/>
    <cfset hdActionReply=FORM.helpdesk_action EQ "responder_ticket"/>
    <cfset hdMessage=trim(FORM.ticket_mensagem ?: "")/>
    <cfset hdNextStatus=lCase(trim(FORM.ticket_status ?: ""))/>
    <cfset hdLastMessage=structKeyExists(FORM,"ticket_last_message") ? FORM.ticket_last_message : ""/>
    <cfif hdActionClose>
      <cfset hdMessage="Este chamado foi encerrado pela equipe de atendimento por falta de interação. Se ainda precisar de ajuda, responda a este chamado para continuar o atendimento."/>
      <cfset hdNextStatus="fechado"/>
    </cfif>
    <cfif NOT reFind("^[0-9]{1,9}$",FORM.ticket_id ?: "") OR (hdActionClose AND NOT reFind("^[0-9]{1,12}$",hdLastMessage))>
      <cfset hdError="Selecione um chamado válido e recarregue a conversa antes de tentar novamente."/>
    <cfelseif NOT hdActionClose AND (NOT reFind("^[0-9]{1,9}$",FORM.ticket_setor_id ?: "") OR NOT listFindNoCase("aberto,cliente_respondeu,em_atendimento,aguardando_cliente,resolvido,fechado",hdNextStatus))>
      <cfset hdError="Selecione um chamado, um setor e um status válidos."/>
    <cfelseif hdActionReply AND (FORM.message_kind ?: '') EQ 'nota'>
      <cfset hdError="Para manter esta mensagem privada, use Salvar nota interna. Seu texto foi preservado."/>
    <cfelseif hdActionReply AND (NOT len(hdMessage) OR len(hdMessage) GT 12000)>
      <cfset hdError="Escreva uma resposta entre 1 e 12.000 caracteres. Seu texto foi preservado."/>
    <cfelse>
      <cftry>
        <cfset hdForwardNotificationId=0/>
        <cftransaction>
          <cfset hdLocked=helpdeskTriage.lockTicket(val(FORM.ticket_id),val(qPerfil.id))/>
          <cfif NOT hdLocked.recordcount>
            <cfthrow type="Helpdesk.Validation" message="Chamado indisponível para este atendimento."/>
          </cfif>
          <cfif hdActionClose AND hdLocked.status EQ "fechado">
            <cfthrow type="Helpdesk.Validation" message="Este chamado já está fechado."/>
          </cfif>
          <cfif compare(hdLocked.revision,FORM.ticket_revision ?: "") NEQ 0 OR NOT len(hdLastMessage) OR hdLocked.last_message_id NEQ val(hdLastMessage)>
            <cfthrow type="Helpdesk.Conflict" message="O chamado recebeu uma atualização enquanto você atendia. Leia a conversa atualizada e revise sua resposta antes de tentar novamente. Seu texto foi preservado."/>
          </cfif>
          <cfset hdForwarding=NOT hdActionClose AND val(FORM.ticket_setor_id ?: 0) NEQ hdLocked.id_setor/>
          <cfif hdForwarding>
            <cfset hdDestination=helpdeskTriage.lockDestination(val(FORM.ticket_setor_id))/>
            <cfif NOT hdDestination.recordcount>
              <cfthrow type="Helpdesk.Validation" message="Escolha um setor cadastrado."/>
            </cfif>
            <cfif listFind(helpdeskTriage.sectorIds(),hdDestination.id_setor) AND hdDestination.responsible_id LTE 0>
              <cfthrow type="Helpdesk.Validation" message="O setor de triagem precisa de um responsável antes de receber o chamado."/>
            </cfif>
          </cfif>
          <cfquery>
            UPDATE tb_helpdesk_chamados SET status=<cfqueryparam value="#hdNextStatus#" cfsqltype="cf_sql_varchar"/>,
            <cfif NOT hdActionClose>id_setor=<cfqueryparam value="#FORM.ticket_setor_id#" cfsqltype="cf_sql_integer"/>,</cfif>
            updated_at=now()
            WHERE id_chamado=<cfqueryparam value="#FORM.ticket_id#" cfsqltype="cf_sql_integer"/>
          </cfquery>
          <cfif hdActionReply OR hdActionClose>
            <cfquery>
              INSERT INTO tb_helpdesk_mensagens (id_chamado,id_usuario,mensagem,interno,created_at)
              VALUES (<cfqueryparam value="#FORM.ticket_id#" cfsqltype="cf_sql_integer"/>,<cfqueryparam value="#qPerfil.id#" cfsqltype="cf_sql_integer"/>,<cfqueryparam value="#hdMessage#" cfsqltype="cf_sql_longvarchar"/>,false,now())
            </cfquery>
          </cfif>
          <cfif hdForwarding AND hdDestination.responsible_id GT 0>
            <cfset hdForwardNotificationId=helpdeskTriage.notifyResponsible(val(FORM.ticket_id),val(hdDestination.responsible_id),true)/>
          </cfif>
        </cftransaction>
        <cfif hdForwardNotificationId GT 0>
          <cfset helpdeskTriage.sendPush(hdForwardNotificationId,APPLICATION.notificationDispatch.secret ?: "")/>
        </cfif>
        <cfif hdActionReply OR hdActionClose><cftry><cfset helpdeskNotifyTicketOwner(val(FORM.ticket_id),val(qPerfil.id))/><cfcatch type="any"></cfcatch></cftry></cfif>
        <cfset hdSavedAction="status"/>
        <cfif hdActionClose>
          <cfset hdSavedAction="fechado"/>
        <cfelseif hdActionReply>
          <cfset hdSavedAction="resposta"/>
        <cfelseif hdForwarding>
          <cfset hdSavedAction="encaminhado"/>
        </cfif>
        <cfif hdForwarding AND listFind(helpdeskTriage.sectorIds(),hdDestination.id_setor) AND hdDestination.responsible_id NEQ qPerfil.id>
          <cflocation url="#hdUrl({ticket_id=0,salvo='encaminhado'})#" addtoken="false"/>
        </cfif>
        <cflocation url="#hdUrl({ticket_id=val(FORM.ticket_id),salvo=hdSavedAction})#" addtoken="false"/>
        <cfcatch type="Helpdesk.Conflict"><cfset hdError=cfcatch.message/></cfcatch>
        <cfcatch type="Helpdesk.Validation"><cfset hdError=cfcatch.message/></cfcatch>
        <cfcatch type="any"><cfset hdError="Não foi possível salvar o atendimento. Seu texto foi preservado; tente novamente em instantes."/></cfcatch>
      </cftry>
    </cfif>
  </cfif>
</cfif>
