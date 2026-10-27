<cfscript>
q=queryExecute("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('desafios','tb_evento_corridas','tb_agregadores_eventos','tb_vicky_channel_config') ORDER BY table_name,ordinal_position",{},{datasource='runner_dba'});
for(r in q)if(listFindNoCase('desafios,tb_agregadores_eventos,tb_vicky_channel_config',r.table_name) OR reFindNoCase('id_evento|nome_evento|data_inicial|tag|status|ativo|exclu|cancela|id_agrega_evento',r.column_name))writeOutput(r.table_name & '.' & r.column_name & ':' & r.data_type & chr(10));
q=queryExecute("SELECT count(*) registrations,count(DISTINCT id_usuario) users,string_agg(DISTINCT coalesce(status,''),',') statuses FROM desafios WHERE produto='circuitobrasilgigante' OR desafio='circuitobrasilgigante'",{},{datasource='runner_dba'});writeOutput(serializeJSON(q));
q=queryExecute("SELECT DISTINCT e.id_evento,e.nome_evento,e.data_inicial FROM tb_evento_corridas e INNER JOIN tb_agregadores_eventos a ON a.id_evento=e.id_evento WHERE a.agregador_tag='brasil-gigante' AND e.data_inicial>=current_date ORDER BY e.data_inicial LIMIT 20",{},{datasource='runner_dba'});writeOutput(serializeJSON(q));
q=queryExecute("SELECT provider,channel,enabled,pilot_only,max_messages_per_hour FROM tb_vicky_channel_config WHERE channel='whatsapp'",{},{datasource='runner_dba'});writeOutput(serializeJSON(q));
writeOutput('VICKY_CBG_SOURCE_PASSED');
</cfscript>
