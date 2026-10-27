<cfscript>
function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
checks=0;
repo=new repositories.VickyBrasilGiganteRepository().init('runner_dba','meta_cloud');
fixture="WITH tb_vicky_notificacao_regra(id_vicky_notificacao_regra,codigo,trigger_type,enabled,admin_only,days_before,web_enabled,whatsapp_enabled,quiet_start,quiet_end) AS (VALUES (1,'brasil_gigante_d7','manual',true,false,7,true,true,time '20:00',time '08:00')),
tb_vicky_notificacao_template(id_vicky_notificacao_template,id_vicky_notificacao_regra,channel,status,language) AS (VALUES (10,1,'web','active','pt-BR'),(11,1,'whatsapp','active','pt-BR')),
tb_usuarios(id,is_admin) AS (VALUES (1,false),(2,false),(3,false),(4,false),(5,false),(6,false)),
tb_usuarios_gestao(id_usuario,ativo,excluido) AS (VALUES (6,false,true)),
desafios(id_usuario,produto,desafio) AS (VALUES (1,'circuitobrasilgigante',''),(1,'circuitobrasilgigante',''),(2,'','circuitobrasilgigante'),(3,'outro','outro'),(4,'circuitobrasilgigante',''),(5,'circuitobrasilgigante',''),(6,'circuitobrasilgigante','')),
tb_evento_corridas(id_evento,nome_evento,tag,data_inicial,id_agrega_evento,ativo,status_evento) AS (VALUES (100,'Etapa certa','etapa',date '2026-10-31',77,true,'confirmado'),(101,'Fora do dia','outra',date '2026-11-01',17,true,'confirmado'),(102,'Inativa','inativa',date '2026-10-31',17,false,'confirmado'),(103,'Outro circuito','outro',date '2026-10-31',200,true,'confirmado')),
tb_agregadores_eventos(id_evento,agregador_tag) AS (VALUES (100,'brasil-gigante'),(100,'brasil-gigante'),(101,'brasil-gigante'),(102,'brasil-gigante'),(103,'outro')),
tb_vicky_notificacao_preferencia(id_usuario,web_enabled,whatsapp_enabled,agenda_enabled,whatsapp_consented_at,revoked_at,quiet_start,quiet_end) AS (VALUES (1,true,true,false,now(),NULL::timestamptz,NULL::time,NULL::time),(2,true,true,true,NULL::timestamptz,NULL::timestamptz,NULL::time,NULL::time),(4,false,true,true,now(),now(),NULL::time,NULL::time)),
tb_vicky_channel_link(id_usuario,provider,channel,status) AS (VALUES (1,'meta_cloud','whatsapp','active'),(2,'meta_cloud','whatsapp','active')),
tb_vicky_manychat_link(id_usuario,channel,status) AS (VALUES (1,'whatsapp','active')) ";
sql=fixture & repo.candidatesSql();
params={today={value='2026-10-24',cfsqltype='cf_sql_date'}};
q=queryExecute(sql,params,{datasource='runner_dba'});
check(q.recordCount EQ 4,'Somente usuários 1/web,1/whatsapp,2/web,5/web; inscrição duplicada não duplica');
keys=[];for(r in q)arrayAppend(keys,r.id_usuario & ':' & r.channel & ':' & r.id_evento);arraySort(keys,'text');
check(arrayToList(keys) EQ '1:web:100,1:whatsapp:100,2:web:100,5:web:100','Público, etapa, preferências e consentimento corretos; agenda desabilitada não exclui inscrito');
q=queryExecute(sql,{today={value='2026-10-25',cfsqltype='cf_sql_date'}},{datasource='runner_dba'});
check(q.recordCount EQ 4 AND q.id_evento[1] EQ 101,'D−7 acompanha data da etapa sem retroativo');
q=queryExecute(replace(sql,"true,false,7,true,true","false,false,7,true,true"),params,{datasource='runner_dba'});check(q.recordCount EQ 0,'Regra desativada não gera');
q=queryExecute(replace(sql,"true,false,7,true,true","true,true,7,true,true"),params,{datasource='runner_dba'});check(q.recordCount EQ 0,'Modo somente administradores respeitado');
q=queryExecute(replace(sql,"(1,'meta_cloud','whatsapp','active')","(1,'meta_cloud','whatsapp','revoked')"),params,{datasource='runner_dba'});check(q.recordCount EQ 3,'Vínculo revogado não gera WhatsApp');
// Same real query compiles against the actual schema, with no queue insertion.
q=queryExecute(repo.candidatesSql(),{today={value='1900-01-01',cfsqltype='cf_sql_date'}},{datasource='runner_dba',timeout=10});check(q.recordCount EQ 0,'Consulta real compila sem dados retroativos');
writeOutput('VICKY_CBG_NATIVE_PASSED ' & checks);
</cfscript>
