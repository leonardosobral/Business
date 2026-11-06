component output="false" {
  variables.options={datasource='runner_dba',timeout=10};
  private struct function p(required any value,string type='cf_sql_varchar'){return {value=arguments.value,cfsqltype=arguments.type};}
  public string function number(required string value){
    var n=trim(arguments.value);
    if(!reFind('^[0-9]{1,12}$',n) OR !len(reReplace(n,'^0+','','one')))throw(type='ChallengeMandala.Validation',message='Informe o número gravado na mandala: de 1 a 12 dígitos, maior que zero.');
    return n;
  }
  public struct function record(required numeric userId,required numeric actorId,required string serial){
    var n=number(arguments.serial);var key=reReplace(n,'^0+','','one');var result={};
    if(arguments.userId LTE 0 OR arguments.actorId LTE 0)throw(type='ChallengeMandala.Validation',message='Participante ou atendente inválido.');
    transaction {
      // Serialize assignments across all application requests/JVMs, including different athletes.
      queryExecute("SELECT pg_advisory_xact_lock(hashtext('business.cbg.mandala'),0)",{},variables.options);
      var registered=queryExecute("SELECT id_usuario FROM desafios WHERE desafio='circuitobrasilgigante' AND id_usuario=:id FOR UPDATE",{id=p(arguments.userId,'cf_sql_integer')},variables.options);
      if(!registered.recordCount)throw(type='ChallengeMandala.Validation',message='A inscrição do atleta não foi encontrada no Circuito Brasil Gigante.');
      var history=queryExecute("SELECT obs FROM desafios_obs WHERE produto='circuitobrasilgigante' AND id_usuario=:id AND (obs='mandala_entregue' OR obs ~ '^mandala_numero:[0-9]{1,12}$') ORDER BY data_obs DESC,id_desafio_obs DESC",{id=p(arguments.userId,'cf_sql_integer')},variables.options);
      var delivered=false;var saved='';
      for(var row in history){
        if(row.obs EQ 'mandala_entregue')delivered=true;
        else if(!len(saved))saved=listLast(row.obs,':');
      }
      if(len(saved)){
        if(reReplace(saved,'^0+','','one') NEQ key)throw(type='ChallengeMandala.Validation',message='Este atleta já tem a mandala nº '&saved&' registrada. O número não foi alterado.');
        if(!delivered)throw(type='ChallengeMandala.Validation',message='Histórico de entrega inconsistente. Solicite a conferência antes de confirmar novamente.');
        result={number=saved,alreadyDelivered=true,reused=true};
      }else{
        var occupied=queryExecute("SELECT id_usuario FROM desafios_obs WHERE produto='circuitobrasilgigante' AND obs ~ '^mandala_numero:[0-9]{1,12}$' AND ltrim(substring(obs FROM '^mandala_numero:([0-9]{1,12})$'),'0')=:serial AND id_usuario<>:id LIMIT 1",{serial=p(key),id=p(arguments.userId,'cf_sql_integer')},variables.options);
        if(occupied.recordCount)throw(type='ChallengeMandala.Validation',message='Esse número de mandala já está registrado para outro atleta. Confira o número antes de confirmar.');
        if(!delivered){
          var eligible=queryExecute("SELECT count(DISTINCT evt.id_agrega_evento) etapas FROM tb_resultados res INNER JOIN tb_evento_corridas evt ON evt.id_evento=res.id_evento INNER JOIN tb_agregadores_eventos agr ON agr.id_evento=evt.id_evento AND agr.agregador_tag='brasil-gigante' WHERE res.id_usuario=:id AND res.percurso=42 AND evt.id_agrega_evento IN (17,1000,26,9,14,28,15,77)",{id=p(arguments.userId,'cf_sql_integer')},variables.options);
          if(val(eligible.etapas) LT 7)throw(type='ChallengeMandala.Validation',message='O atleta ainda não possui sete etapas reconhecidas no Circuito Brasil Gigante.');
          queryExecute("INSERT INTO desafios_obs(id_usuario,produto,obs,id_atendente,data_obs) VALUES(:id,'circuitobrasilgigante','mandala_entregue',:actor,localtimestamp)",{id=p(arguments.userId,'cf_sql_integer'),actor=p(arguments.actorId,'cf_sql_integer')},variables.options);
        }
        queryExecute("INSERT INTO desafios_obs(id_usuario,produto,obs,id_atendente,data_obs) VALUES(:id,'circuitobrasilgigante',:obs,:actor,localtimestamp)",{id=p(arguments.userId,'cf_sql_integer'),obs=p('mandala_numero:'&n),actor=p(arguments.actorId,'cf_sql_integer')},variables.options);
        result={number=n,alreadyDelivered=delivered,reused=false};
      }
    }
    return result;
  }
}
