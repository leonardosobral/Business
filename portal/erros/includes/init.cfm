<cfif NOT structKeyExists(VARIABLES,"requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
etService=new portal.erros.includes.ErrorTriage().init();
etReady=etService.ready();etError="";
etStatuses={new="Novo",investigating="Investigando",ready="Correção pronta",published="Publicado",verified="Verificado",ignored="Ignorado",reopened="Reaberto"};
etCategories={unclassified="Não classificado",code="Código / CFML",database="Banco / SQL",external="Serviço externo",input="Entrada inválida / robô",not_found="Página não encontrada"};
if(!structKeyExists(SESSION,"errorTriageCsrf")) SESSION.errorTriageCsrf=lCase(hash(createUUID() & createUUID(),"SHA-256"));
etCsrf=SESSION.errorTriageCsrf;
function etHtml(value=""){return encodeForHTML(arguments.value & "");}
function etDate(value=""){return isDate(arguments.value) ? dateTimeFormat(arguments.value,"dd/mm/yyyy HH:nn:ss") : "—";}
function etLabel(required struct labels,value=""){return structKeyExists(labels,value) ? labels[value] : value;}
function etPositive(value=""){return reFind("^[1-9][0-9]{0,8}$",arguments.value & "")>0;}
function etField(required string name,any fallback="") {return structKeyExists(FORM,"triage_action") && FORM.triage_action=="save" && structKeyExists(FORM,arguments.name) ? FORM[arguments.name] : arguments.fallback;}
etProblemId=etPositive(URL.problem_id ?: "") ? val(URL.problem_id) : 0;
etFilters={scope=(URL.scope ?: "recent")=="all" ? "all" : "recent",status=URL.status ?: "",category=URL.category ?: "",site=left(URL.triage_site ?: "",32),page=max(1,int(val(URL.page ?: 1)))};
if(len(etFilters.status) && !structKeyExists(etStatuses,etFilters.status))etFilters.status="";
if(len(etFilters.category) && etFilters.category!="all" && !structKeyExists(etCategories,etFilters.category))etFilters.category="";
etOwners=queryExecute("SELECT id,name FROM tb_usuarios WHERE is_admin=true ORDER BY name",{},{datasource="runner_dba"});
</cfscript>
