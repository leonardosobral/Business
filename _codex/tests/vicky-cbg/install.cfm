<cfscript>
// Only the named new rule and its two templates; never activate or send here.
queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'install.sql'),{},{datasource='runner_dba'});
q=queryExecute("SELECT r.codigo,r.enabled,r.admin_only,r.days_before,r.web_enabled,r.whatsapp_enabled,count(t.*) templates FROM tb_vicky_notificacao_regra r JOIN tb_vicky_notificacao_template t USING(id_vicky_notificacao_regra) WHERE r.codigo='brasil_gigante_d7' GROUP BY r.id_vicky_notificacao_regra",{},{datasource='runner_dba'});
if(q.recordCount NEQ 1 OR q.enabled OR q.admin_only OR q.days_before NEQ 7 OR !q.web_enabled OR !q.whatsapp_enabled OR q.templates NEQ 2)throw(message='Installed rule configuration mismatch');
writeOutput('VICKY_CBG_INSTALL_PASSED ' & serializeJSON(q));
</cfscript>
