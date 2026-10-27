<cfscript>
// Remove only the uniquely identified synthetic template created by browser validation.
s=createObject('component','helpdesk'&'.includes.HelpdeskReplies').init();data=s.list();found=false;
for(item in data.items)if(item.id EQ 'b1781465-e6b7-3150-4074a2d15a0f7a3f' AND item.title EQ '[Validação temporária] Help Desk' AND item.text EQ 'Modelo temporário editado com sucesso.'&chr(13)&chr(10)&'Segunda linha preservada.'){
 fileCopy('/var/lib/runnerhub-business/helpdesk/quick-replies.json',getDirectoryFromPath(getCurrentTemplatePath())&'library-before-cleanup.json');
 data=s.remove(item.id,data.revision,item.updatedBy);found=true;break;
}
if(!found OR arrayLen(data.items) NEQ 3)throw(message='Synthetic template not found or library changed; inspect before cleanup');
writeOutput('HELPDESK_TOOLS_CLEANUP_PASSED temporary model removed, three defaults preserved');
</cfscript>
