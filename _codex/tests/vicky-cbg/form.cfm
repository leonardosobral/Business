<cfscript>
transaction {
 queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'install.sql'),{},{datasource='runner_dba'});
 qPerfil=queryNew('id','integer',[[142]]);URL.secao='interacoes';URL.periodo='30';URL.execucao='0';
 SESSION.vickyAdminCsrfToken='cbg-private-test';
 FORM.action='save_proactive_rule';FORM.rule_code='brasil_gigante_d7';FORM.days_before=0;FORM.max_per_day=20;
 FORM.provider_template_name='wrong_model';FORM.web_content='Teste de configuração';FORM.whatsapp_content='Prévia estática';FORM.quiet_start='20:00';FORM.quiet_end='08:00';FORM.web_enabled='on';FORM.whatsapp_enabled='on';
 FORM.csrf_token='invalid';
 include '../administracao/vicky/includes/backend.cfm';
 q=queryExecute("SELECT days_before FROM tb_vicky_notificacao_regra WHERE codigo='brasil_gigante_d7'",{},{datasource='runner_dba'});
 if(q.days_before NEQ 7 OR !findNoCase('sess',VARIABLES.vickyMessage))throw(type='Test.Failed',message='CSRF inválido não foi bloqueado');
 FORM.csrf_token='cbg-private-test';
 include '../administracao/vicky/includes/backend.cfm';
 q=queryExecute("SELECT r.days_before,r.max_per_day,r.admin_only,t.provider_template_name,t.content FROM tb_vicky_notificacao_regra r JOIN tb_vicky_notificacao_template t USING(id_vicky_notificacao_regra) WHERE codigo='brasil_gigante_d7' AND t.channel='whatsapp'",{},{datasource='runner_dba'});
 if(q.days_before NEQ 7 OR q.max_per_day NEQ 1 OR q.admin_only OR q.provider_template_name NEQ 'atualize_cbg' OR q.content NEQ 'Prévia estática')throw(type='Test.Failed',message='Save da regra não preservou gatilho, público e modelo');
 transaction action='rollback';
}
writeOutput('VICKY_CBG_FORM_PASSED');
</cfscript>
