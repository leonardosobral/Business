<cfscript>
checks=0;
function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
transaction {
 queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'install.sql'),{},{datasource='runner_dba'});
 queryExecute("UPDATE tb_vicky_notificacao_regra SET enabled=true,quiet_start='00:00',quiet_end='00:00' WHERE codigo='brasil_gigante_d7'",{},{datasource='runner_dba'});
 repo=new repositories.VickyBrasilGiganteRepository().init('runner_dba','meta_cloud');
 today=queryExecute("SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today",{},{datasource='runner_dba'});
 candidates=queryExecute(repo.candidatesSql(),{today={value=today.today,cfsqltype='cf_sql_date'}},{datasource='runner_dba'});
 check(candidates.recordCount GT 0,'Etapa real em D−7 disponível para teste transacional');
 limited=new LimitedCbgRepository().init('runner_dba','meta_cloud');limited.limitUser(candidates.id_usuario[1]);
 count=limited.generate();check(count GTE 1 AND count LTE 2,'Gerador grava um job por canal elegível');
 check(limited.generate() EQ 0,'Reexecução não duplica job');
 jobs=queryExecute("SELECT f.* FROM tb_vicky_notificacao_fila f JOIN tb_vicky_notificacao_regra r USING(id_vicky_notificacao_regra) WHERE r.codigo='brasil_gigante_d7' AND f.id_usuario=:id AND f.reference_id::bigint>=1000000000",{id={value=candidates.id_usuario[1],cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
 job={};for(col in listToArray(jobs.columnList))job[lCase(col)]=jobs[col][1];
 job.reference_id=val(job.reference_id)-1000000000;
 state=limited.deliveryState(job);check(state.eligible AND !state.deferred,'Entrega válida revalida inscrição/etapa/canal');
 queryExecute("UPDATE tb_vicky_notificacao_regra SET enabled=false WHERE codigo='brasil_gigante_d7'",{},{datasource='runner_dba'});
 check(!limited.deliveryState(job).eligible,'Regra desligada depois do enfileiramento impede entrega');
 queryExecute("UPDATE tb_vicky_notificacao_regra SET enabled=true,quiet_start='00:00',quiet_end='23:59:59' WHERE codigo='brasil_gigante_d7'",{},{datasource='runner_dba'});
 state=limited.deliveryState(job);check(state.deferred,'Silêncio diurno posterga sem consumir tentativa');
 check(reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$',state.availableAt&'') GT 0,'Adiamento carrega instante UTC explícito, independente do fuso JDBC');
 queryExecute("UPDATE tb_vicky_notificacao_fila SET status='processing',attempts=2 WHERE id_vicky_notificacao_fila=:id",{id={value=job.id_vicky_notificacao_fila,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
 workerRepo=new repositories.VickyProactiveRepository().init('runner_dba','meta_cloud');workerRepo.deferBrasilGigante(job.id_vicky_notificacao_fila,state.availableAt);
 deferred=queryExecute("SELECT status,attempts,to_char(available_at AT TIME ZONE 'UTC','YYYY-MM-DD""T""HH24:MI:SS""Z""') AS instant FROM tb_vicky_notificacao_fila WHERE id_vicky_notificacao_fila=:id",{id={value=job.id_vicky_notificacao_fila,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
 check(deferred.status EQ 'queued' AND deferred.attempts EQ 1 AND deferred.instant EQ state.availableAt,'Silêncio preserva instante e não consome tentativa de entrega');
 metaUsers=queryExecute("SELECT l.id_usuario FROM tb_vicky_channel_link l JOIN tb_vicky_channel_config c ON c.provider=l.provider AND c.channel=l.channel WHERE l.provider='meta_cloud' AND l.channel='whatsapp' AND l.status='active' AND c.enabled LIMIT 1",{},{datasource='runner_dba'});
 if(metaUsers.recordCount){legacyRepo=new repositories.VickyProactiveRepository().init('runner_dba','manychat');check(!structIsEmpty(legacyRepo.activeWhatsappLink(metaUsers.id_usuario,'meta_cloud')),'Override de provedor consulta vínculo Meta sem depender do ManyChat global');}
 transaction action='rollback';
}
writeOutput('VICKY_CBG_QUEUE_PASSED ' & checks & ' all writes rolled back; no delivery invoked');
</cfscript>
