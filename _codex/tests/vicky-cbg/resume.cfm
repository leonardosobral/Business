<cfscript>
// Resume only the incorrectly suppressed CBG job, and only if still eligible.
repo=createObject('component','cbgPublishedRR.repositories.VickyBrasilGiganteRepository').init('runner_dba','meta_cloud');
q=queryExecute("SELECT f.* FROM tb_vicky_notificacao_fila f JOIN tb_vicky_notificacao_regra r USING(id_vicky_notificacao_regra) WHERE r.codigo='brasil_gigante_d7' AND f.channel='whatsapp' AND f.status='suppressed' AND f.error_code='whatsapp_not_linked'",{},{datasource='runner_dba'});
resumed=0;
for(i=1;i LTE q.recordCount;i++){
 job={};for(col in listToArray(q.columnList))job[lCase(col)]=q[col][i];
 state=repo.deliveryState(job);
 if(state.eligible){
  updated=queryExecute("UPDATE tb_vicky_notificacao_fila SET status='queued',available_at=now(),completed_at=NULL,error_code=NULL,processing_started_at=NULL,updated_at=now() WHERE id_vicky_notificacao_fila=:id AND status='suppressed' AND error_code='whatsapp_not_linked' RETURNING id_vicky_notificacao_fila",{id={value=job.id_vicky_notificacao_fila,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});resumed+=updated.recordCount;
 }
}
writeOutput('VICKY_CBG_RESUME_PASSED resumed=' & resumed & '; no worker or send invoked');
</cfscript>
