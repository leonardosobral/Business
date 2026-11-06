<cfscript>
checks=0;function check(required boolean yes,required string name){if(!yes)throw(message=name);checks++;}
s=new __MANDALA__();opts={datasource='runner_dba'};
actor=queryExecute('SELECT min(id) id FROM tb_usuarios WHERE is_admin=true',{},opts).id;
users=queryExecute("SELECT DISTINCT d.id_usuario FROM desafios d JOIN tb_resultados r ON r.id_usuario=d.id_usuario AND r.percurso=42 JOIN tb_evento_corridas e ON e.id_evento=r.id_evento JOIN tb_agregadores_eventos a ON a.id_evento=e.id_evento AND a.agregador_tag='brasil-gigante' WHERE d.desafio='circuitobrasilgigante' AND e.id_agrega_evento IN(17,1000,26,9,14,28,15,77) AND NOT EXISTS(SELECT 1 FROM desafios_obs h WHERE h.produto=d.desafio AND h.id_usuario=d.id_usuario AND h.obs ~ '^mandala_numero:') GROUP BY d.id_usuario HAVING count(DISTINCT e.id_agrega_evento)>=7 ORDER BY d.id_usuario LIMIT 2",{},opts);
check(users.recordCount EQ 2,'Dois participantes elegíveis disponíveis para fixture revertida');
n='9'&right(reReplace(createUUID(),'[^0-9]','','all')&'12345',5);VARIABLES.challengeTag='circuitobrasilgigante';
baseline=queryExecute("SELECT count(*) n FROM desafios_obs WHERE produto='circuitobrasilgigante'",{},opts).n;
transaction {
  queryExecute("DELETE FROM desafios_obs WHERE produto='circuitobrasilgigante' AND id_usuario=:id AND obs='mandala_entregue'",{id={value=users.id_usuario[1],cfsqltype='cf_sql_integer'}},opts);
  a=s.record(users.id_usuario[1],actor,n);check(!a.alreadyDelivered AND !a.reused,'Nova entrega grava número e marcador');
  b=s.record(users.id_usuario[1],actor,n);check(b.reused,'Repetição não duplica');
  include 'lookup.cfm';check(compare(lookup.numero,n) EQ 0 AND isDate(lookup.data_entrega),'Consulta real da listagem lê número e data');
  q=queryExecute("SELECT obs,id_atendente FROM desafios_obs WHERE produto='circuitobrasilgigante' AND id_usuario=:id AND obs IN('mandala_entregue',:obs)",{id={value=users.id_usuario[1],cfsqltype='cf_sql_integer'},obs={value='mandala_numero:'&n,cfsqltype='cf_sql_varchar'}},opts);check(q.recordCount EQ 2 AND q.id_atendente[1] EQ actor,'Marcador e número persistem com autor');
  transaction action='rollback';
}
// Separate transactions: expected exceptions roll back their own fixture state too.
transaction {
  s.record(users.id_usuario[1],actor,n);
  rejected=false;try{s.record(users.id_usuario[2],actor,'00'&n);}catch(ChallengeMandala.Validation e){rejected=findNoCase('outro atleta',e.message)>0;}
  check(rejected,'Mesmo número não pode ser usado por outro atleta');transaction action='rollback';
}
transaction {
  queryExecute("INSERT INTO desafios_obs(id_usuario,produto,obs,id_atendente,data_obs) SELECT :id,'circuitobrasilgigante','mandala_entregue',:actor,localtimestamp-interval '10 days' WHERE NOT EXISTS(SELECT 1 FROM desafios_obs WHERE id_usuario=:id AND produto='circuitobrasilgigante' AND obs='mandala_entregue')",{id={value=users.id_usuario[1],cfsqltype='cf_sql_integer'},actor={value=actor,cfsqltype='cf_sql_integer'}},opts);
  before=queryExecute("SELECT max(data_obs) dt,count(*) n FROM desafios_obs WHERE id_usuario=:id AND produto='circuitobrasilgigante' AND obs='mandala_entregue'",{id={value=users.id_usuario[1],cfsqltype='cf_sql_integer'}},opts);
  a=s.record(users.id_usuario[1],actor,n);after=queryExecute("SELECT max(data_obs) dt,count(*) n FROM desafios_obs WHERE id_usuario=:id AND produto='circuitobrasilgigante' AND obs='mandala_entregue'",{id={value=users.id_usuario[1],cfsqltype='cf_sql_integer'}},opts);
  check(a.alreadyDelivered AND before.dt EQ after.dt AND before.n EQ after.n,'Completar número preserva data original');transaction action='rollback';
}
check(queryExecute("SELECT count(*) n FROM desafios_obs WHERE produto='circuitobrasilgigante'",{},opts).n EQ baseline,'Toda alteração da fixture revertida');
transaction {
 s.record(users.id_usuario[1],actor,n);rejected=false;try{s.record(users.id_usuario[1],actor,'8'&n);}catch(ChallengeMandala.Validation e){rejected=findNoCase('não foi alterado',e.message)>0;}
 check(rejected,'Número de entrega existente não é sobrescrito');transaction action='rollback';
}
writeOutput('CBG_MANDALA_PERSISTENCE_PASSED '&checks);
</cfscript>
