<cfscript>
localMetaWhatsappConfig={};include '../../../../roadrunners.com.br/config/meta_whatsapp.local.cfm';
env=createObject('java','java.lang.System').getenv();
writeOutput('ENV_PROVIDER=' & (structKeyExists(env,'RR_VICKY_WHATSAPP_PROVIDER')?env['RR_VICKY_WHATSAPP_PROVIDER']:'not set') & ' LOCAL_PROVIDER=' & (localMetaWhatsappConfig.proactiveProvider ?: 'not set') & ' LOCAL_META_ENABLED=' & (localMetaWhatsappConfig.enabled ?: false) & chr(10));
q=queryExecute("SELECT f.id_usuario FROM tb_vicky_notificacao_fila f JOIN tb_vicky_notificacao_regra r USING(id_vicky_notificacao_regra) WHERE r.codigo='brasil_gigante_d7' AND f.channel='whatsapp' LIMIT 1",{},{datasource='runner_dba'});
if(q.recordCount){
 for(provider in ['manychat','meta_cloud']){
  repo=createObject('component','cbgPublishedRR.repositories.VickyProactiveRepository').init('runner_dba',provider);
  writeOutput(provider & '_link_available=' & (!structIsEmpty(repo.activeWhatsappLink(q.id_usuario))) & chr(10));
 }
}
writeOutput('VICKY_CBG_PROVIDER_PASSED');
</cfscript>
