<cfif NOT structKeyExists(VARIABLES,"requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<cfif structKeyExists(FORM,"triage_action")>
  <cfif CGI.request_method NEQ "POST" OR NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,etCsrf) NEQ 0><cfheader statuscode="403"/><cfoutput>Sessão expirada. Recarregue a página.</cfoutput><cfabort/></cfif>
  <cftry>
    <cfscript>
    if(!etReady)throw(type="Triage.Validation",message="O acompanhamento ainda não foi instalado.");
    action=FORM.triage_action;redirectTo="./";
    if(action=="collect") {
      collected=etService.collect(qPerfil.id);
      SESSION.errorTriageReceipt=collected;
    } else {
      if(!etPositive(FORM.problem_id ?: "") || !etPositive(FORM.version ?: ""))throw(type="Triage.Validation",message="Problema ou versão inválidos.");
      etProblemId=val(FORM.problem_id);redirectTo="./?problem_id=" & etProblemId;
      if(action=="save") {
        if(len(trim(FORM.owner_id ?: ""))) {
          validOwner=false;for(owner in etOwners)if(owner.id & ""==FORM.owner_id)validOwner=true;
          if(!validOwner)throw(type="Triage.Validation",message="Selecione um responsável administrativo válido.");
        }
        etService.save(etProblemId,val(FORM.version),FORM,qPerfil.id);
      } else if(action=="move" || action=="split") {
        if(!etPositive(FORM.log_id ?: ""))throw(type="Triage.Validation",message="Log inválido.");
        // Bind the occurrence to the problem actually shown in this form.
        sourceCheck=queryExecute("SELECT problem_id FROM public.tb_error_occurrence WHERE id_log=:id",{id={value=val(FORM.log_id),cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        if(!sourceCheck.recordCount || sourceCheck.problem_id!=etProblemId)throw(type="Triage.Conflict",message="A ocorrência não pertence mais a este problema. Recarregue.");
        if(action=="split")redirectTo="./?problem_id=" & etService.splitOccurrence(val(FORM.log_id),val(FORM.version),FORM.reason ?: "",qPerfil.id,etProblemId);
        else {
          if(!etPositive(FORM.target_id ?: "") || !etPositive(FORM.target_version ?: ""))throw(type="Triage.Validation",message="Informe o ID e a versão atual do destino, mostrados no detalhe do problema.");
          etService.moveOccurrence(val(FORM.log_id),val(FORM.target_id),val(FORM.version),val(FORM.target_version),FORM.reason ?: "",qPerfil.id,etProblemId);
        }
      } else throw(type="Triage.Validation",message="Ação inválida.");
    }
    </cfscript>
    <cflocation url="#redirectTo#" addtoken="false"/>
    <cfcatch type="Triage.Validation"><cfset etError=cfcatch.message/></cfcatch>
    <cfcatch type="Triage.Conflict"><cfset etError=cfcatch.message/></cfcatch>
    <cfcatch type="any"><cfset etError="Não foi possível concluir a operação. Nenhuma alteração parcial foi confirmada. Tente novamente em instantes."/></cfcatch>
  </cftry>
</cfif>
