<cfscript>
VARIABLES.helpdeskCanManage=URL.admin EQ '1';SESSION.helpdeskCsrf='fixture-only-csrf';
if(CGI.request_method EQ 'GET'){FORM.helpdesk_action=URL.helpdesk_action;FORM.helpdesk_csrf=URL.helpdesk_csrf;}
qPerfil=queryNew('id','integer',[{id=17}]);hdError='';hdReplyLibrary={items=[],revision=''};
hdReplies=new __REPLIES__(getDirectoryFromPath(getCurrentTemplatePath())&'guards-replies.json');
function hdUrl(struct changes={}){return './';}
include '../helpdesk/includes/workspace-actions.cfm';
if(!len(hdError))throw(message='Expected safe validation error');
writeOutput('HELPDESK_TOOLS_GUARDS_PASSED');
</cfscript>
