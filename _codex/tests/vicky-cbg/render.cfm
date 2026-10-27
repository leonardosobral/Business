<cfscript>
transaction {
 queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'install.sql'),{},{datasource='runner_dba'});
 qPerfil=queryNew('id','integer',[[142]]);URL.secao='interacoes';URL.periodo='30';URL.execucao='0';
 include '../administracao/vicky/includes/backend.cfm';
 if(!VARIABLES.vickyReady)throw(type='Test.Failed',message='Backend indisponível: ' & VARIABLES.vickyMessage);
 savecontent variable='rendered'{include '../administracao/vicky/home.cfm';}
 if(!find('brasil_gigante_d7',rendered))throw(type='Test.Failed',message='Nova regra não aparece no gerenciador');
 if(!find('Sem depender da agenda',rendered) OR !find('atualize_cbg',rendered) OR !find('csrf_token',rendered))throw(type='Test.Failed',message='Público, modelo ou proteção do formulário ausentes');
 transaction action='rollback';
}
writeOutput('VICKY_CBG_RENDER_PASSED');
</cfscript>
