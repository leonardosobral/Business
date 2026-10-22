<cfscript>
VARIABLES.descriptionAuditCanAdmin=true;
VARIABLES.auditError="";VARIABLES.auditEventId=0;VARIABLES.auditPage=1;VARIABLES.auditHasNext=false;VARIABLES.auditLanguage="";VARIABLES.auditId=1;VARIABLES.auditView="facts";
VARIABLES.auditRows=queryNew("id,id_evento,language,occurred_at,error_code,has_output,nome_evento");
VARIABLES.auditSelected={id=1,id_evento=42,language="pt-BR",occurred_at="15/10/2026 10:00:00",error_code="distances_changed",nome_evento='<script>EVENT_XSS</script>'};
VARIABLES.auditEvidence={version=1,source="Corrida de 5 km.",candidate='<img src=x onerror="CANDIDATE_XSS()"> 15 km.',reviewReason='<script>REVIEW_XSS</script>',reasons=["distances_changed"]};
VARIABLES.auditDifferences=service.compareAuditFacts(VARIABLES.auditEvidence.source,VARIABLES.auditEvidence.candidate);
savecontent variable="renderedAudit" {include "audit-view-runtime.cfm";}
check(find("5 km",renderedAudit) GT 0 AND find("15 km",renderedAudit) GT 0,"Private viewer renders omitted and introduced factual values");
check(!find("<script>EVENT_XSS",renderedAudit) AND !find("<script>REVIEW_XSS",renderedAudit),"Audit labels and reviewer notes cannot execute HTML");
VARIABLES.auditView="texts";
savecontent variable="renderedAudit" {include "audit-view-runtime.cfm";}
check(find("&lt;img",renderedAudit) GT 0 AND !find('<img src=x onerror=',renderedAudit),"Rejected model HTML is displayed as inert text");
check(find("Corrida de 5 km.",renderedAudit) GT 0,"Full source remains available beside the rejected response");
VARIABLES.auditEvidence={};
savecontent variable="renderedAudit" {include "audit-view-runtime.cfm";}
check(find("não foi guardada",renderedAudit) GT 0,"Historical rejections without a saved candidate are clearly identified");
</cfscript>
