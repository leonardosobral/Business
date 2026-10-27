<!--- Called only after global-admin, POST and CSRF checks in workspace-actions. --->
<cfif listFindNoCase('salvar_resposta_rapida,remover_resposta_rapida',FORM.helpdesk_action)>
  <cfset helpdeskAdminHandled=true/>
  <cftry>
    <cfif FORM.helpdesk_action EQ 'salvar_resposta_rapida'>
      <cfset hdReplyLibrary=hdReplies.save(trim(FORM.resposta_id ?: ''),FORM.resposta_titulo ?: '',FORM.resposta_texto ?: '',FORM.respostas_revision ?: '',val(qPerfil.id))/>
    <cfelse>
      <cfif (FORM.confirmar_remocao ?: '') NEQ '1'><cfthrow type="HelpdeskReplies.Validation" message="Marque a confirmação antes de remover a resposta rápida."/></cfif>
      <cfset hdReplyLibrary=hdReplies.remove(trim(FORM.resposta_id ?: ''),FORM.respostas_revision ?: '',val(qPerfil.id))/>
    </cfif>
    <cflocation url="#hdUrl({respostas=1,salvo='modelo'})###hd-replies" addtoken="false"/>
    <cfcatch type="HelpdeskReplies.Validation"><cfset hdError=cfcatch.message/></cfcatch>
    <cfcatch type="HelpdeskReplies.Conflict"><cfset hdError=cfcatch.message/></cfcatch>
    <cfcatch type="any"><cfset hdError='Não foi possível salvar a biblioteca. O texto informado foi preservado. Tente novamente.'/></cfcatch>
  </cftry>
</cfif>
