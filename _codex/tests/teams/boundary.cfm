<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
httpBoundary=createObject('component','__ACCOUNT_BOUNDARY__').init('runnerhub',false);
state={businessAccessSelection={accountId=42,accessMode='DELEGATED',managerAccountId=7,relationshipId=3}};before=duplicate(state);
r=httpBoundary.handle({},state,'/teams/index.cfm','GET',{},{});check(r.status==200&&!r.selectionRequired&&structIsEmpty(r.context),'Teams usa identidade pessoal sem herdar contexto empresarial');check(serializeJSON(state)==serializeJSON(before),'Teams não altera a seleção empresarial');
r=httpBoundary.handle({},state,'/teams/index.cfm','GET',{resetApp=1},{});check(r.status==403,'Reset de aplicação não permitido');
r=httpBoundary.handle({},state,'/teams/index.cfm','POST',{}, {operation='remove_athlete',actorId=1});check(r.status==403,'Ator forjado em formulário rejeitado');
r=httpBoundary.handle({},state,'/teams/index.cfm','POST',{}, {operation='save',csrf='x'},'','','csrf=a&csrf=b');check(r.status==403,'CSRF duplicado rejeitado');
r=httpBoundary.handle({},state,'/teams/convites/index.cfm','GET',{token='x'},{});check(r.status==200,'Página de aceite acessível sem concessão de autoridade');
r=httpBoundary.handle({},state,'/teams/mail-worker.cfm','POST',{resetApp=1},{});check(r.status==403,'Worker rejeita parâmetros globais');
r=httpBoundary.handle({},state,'/teams/index.cfm','GET',{team=[]},{});check(r.status==403,'Parâmetro complexo rejeitado');
r=httpBoundary.handle({},state,'/teams/index.cfm','GET',{team=1,tab='equipe',user_busca='runner'},{});check(r.status==200,'Busca da equipe permitida na fronteira pessoal');
r=httpBoundary.handle({},state,'/teams/index.cfm','POST',{}, {operation='change_admin_role',csrf='x',team=1,member=2,role='VIEWER',expected_role='ADMIN'});check(r.status==200,'Campos da edição permitidos sem atribuir autoridade');
writeOutput('TEAMS_BOUNDARY_PASSED ' & checks);
</cfscript>
