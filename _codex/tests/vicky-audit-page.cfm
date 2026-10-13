<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try{
  candidate=structKeyExists(URL,'candidate') && URL.candidate=='1';
  base=candidate?'/__vicky_audit_stage/administracao/vicky/':'/administracao/vicky/';
  VARIABLES.requireAdminAllowed=true;
  qPerfil=queryExecute('SELECT id FROM tb_usuarios WHERE id=142 AND is_admin=true',{}, {datasource='runner_dba'});
  if(!qPerfil.recordCount)throw(message='O administrador de validação não está disponível.');
  transaction {
    before=queryExecute('SELECT count(*) total FROM tb_vicky_audit_access WHERE id_operador=142',{}, {datasource='runner_dba'}).total;
    started=getTickCount();
    include base&'includes/backend.cfm';
    if(!VARIABLES.vickyReady){
      if(candidate && structKeyExists(VARIABLES,'vickyDiagnosticError'))throw(message=VARIABLES.vickyMessage,detail=VARIABLES.vickyDiagnosticError.detail);
      throw(message=VARIABLES.vickyMessage);
    }
    savecontent variable='pageHtml'{include base&'home.cfm';}
    after=queryExecute('SELECT count(*) total FROM tb_vicky_audit_access WHERE id_operador=142',{}, {datasource='runner_dba'}).total;
    result={success=true,section=VARIABLES.vickySection,milliseconds=getTickCount()-started,htmlLength=len(pageHtml),registeredAccesses=after-before};
    if(VARIABLES.vickySection=='auditoria'){
      result.users=VARIABLES.vickyAudit.userTotal;result.loadedUsers=VARIABLES.vickyAudit.users.recordCount;
      result.interactions=VARIABLES.vickyAudit.turnTotal;result.loadedInteractions=VARIABLES.vickyAudit.turns.recordCount;
      result.chatPresent=find('data-vp-audit',pageHtml)>0;
      if(!result.chatPresent || result.registeredAccesses!=result.loadedInteractions)throw(message='Interface ou quantidade de acessos registrados inconsistente.');
      for(i=2;i<=VARIABLES.vickyAudit.users.recordCount;i++)if(dateCompare(VARIABLES.vickyAudit.users.last_at[i-1],VARIABLES.vickyAudit.users.last_at[i])<0)throw(message='Ordem de usuários inválida.');
      for(i=2;i<=VARIABLES.vickyAudit.turns.recordCount;i++)if(dateCompare(VARIABLES.vickyAudit.turns.created_at[i-1],VARIABLES.vickyAudit.turns.created_at[i])>0)throw(message='Ordem do histórico inválida.');
    }
    transaction action='rollback';
  }
  writeOutput(serializeJSON(result));
}catch(any e){cfheader(statuscode=500);writeOutput(serializeJSON({success=false,message=e.message,detail=e.detail,line=e.tagContext[1].line}));}
</cfscript>
