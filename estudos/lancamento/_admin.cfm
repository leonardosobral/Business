<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../_context.cfm"/>
<cfscript>
// The page and every document share the same personal administrator check.
centralFile=listLast(getBaseTemplatePath(),'/');
if(centralFile=='_admin.cfm') {cfheader(statuscode=404);abort;}
centralAllowed=centralFile=='arquivo.cfm'?'doc':(centralFile=='maratonas.cfm'?'ano':'');
centralValid=CGI.request_method=='GET' && (!structKeyExists(CGI,'path_info') || !len(CGI.path_info));
for(centralKey in URL) if(!listFindNoCase(centralAllowed,centralKey) || !isSimpleValue(URL[centralKey])) centralValid=false;
if(centralValid && centralFile=='maratonas.cfm' && structKeyExists(URL,'ano')) centralValid=reFind('^(2025|2026)$',toString(URL.ano))==1;
if(!centralValid) {cfheader(statuscode=403);writeOutput('Requisição não permitida.');abort;}
if(!studyActor) {
    cfheader(statuscode=401);
    writeOutput('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Central do lançamento</title><p>Esta central reúne materiais internos da equipe. <a href="/estudos/">Entre no Business com sua conta de administrador</a> e abra Gestão de convites → Central do lançamento.</p></html>');
    abort;
}
try {centralIdentity=studyService.dashboard(studyActor).user;}
catch(any denied) {cfheader(statuscode=403);writeOutput('Entre novamente com sua conta de administrador.');abort;}
if(!centralIdentity.is_admin) {cfheader(statuscode=403);writeOutput('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Central do lançamento</title><p>Materiais internos disponíveis para administradores. <a href="/estudos/">Voltar à biblioteca</a>.</p></html>');abort;}
</cfscript>
