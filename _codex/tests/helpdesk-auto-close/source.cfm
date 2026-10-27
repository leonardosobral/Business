<cfscript>
q=queryExecute("SELECT current_setting('TimeZone') zone,localtimestamp AS local_clock,now() AS clock",{},{datasource='runner_dba'});writeOutput('CLOCK ' & serializeJSON(q));
q=queryExecute("SELECT column_name,data_type,is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_helpdesk_mensagens' ORDER BY ordinal_position",{},{datasource='runner_dba'});writeOutput('MESSAGE_SCHEMA ' & serializeJSON(q));
q=queryExecute("SELECT status,count(*) tickets FROM tb_helpdesk_chamados GROUP BY status ORDER BY status",{},{datasource='runner_dba'});writeOutput('STATUSES ' & serializeJSON(q));
q=queryExecute("SELECT pg_get_constraintdef(oid) definition FROM pg_constraint WHERE conrelid='public.tb_helpdesk_mensagens'::regclass AND contype='f'",{},{datasource='runner_dba'});writeOutput('FK ' & serializeJSON(q));
q=queryExecute("SELECT c.id_chamado,c.status,c.updated_at,m.id_mensagem,m.created_at,m.interno,u.is_admin,(m.id_usuario=c.id_usuario) AS is_requester,extract(epoch FROM (localtimestamp-m.created_at))/3600 AS hours_since_reply FROM tb_helpdesk_chamados c LEFT JOIN LATERAL(SELECT * FROM tb_helpdesk_mensagens m WHERE m.id_chamado=c.id_chamado AND NOT m.interno ORDER BY m.created_at DESC,m.id_mensagem DESC LIMIT 1)m ON true LEFT JOIN tb_usuarios u ON u.id=m.id_usuario WHERE c.id_chamado=121",{},{datasource='runner_dba'});writeOutput('EXAMPLE ' & serializeJSON(q));
writeOutput('HELPDESK_CLOSE_SOURCE_PASSED');
</cfscript>
