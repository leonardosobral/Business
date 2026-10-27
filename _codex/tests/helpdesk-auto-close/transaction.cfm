<cfscript>
checks=0;function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
transaction {
 actors=queryExecute('SELECT min(id) FILTER(WHERE is_admin) AS staff,min(id) FILTER(WHERE NOT coalesce(is_admin,false)) AS owner FROM tb_usuarios',{},{datasource='runner_dba'});
 sector=queryExecute('SELECT id_setor FROM tb_helpdesk_setores ORDER BY id_setor LIMIT 1',{},{datasource='runner_dba'});
 params={owner={value=actors.owner,cfsqltype='cf_sql_integer'},staff={value=actors.staff,cfsqltype='cf_sql_integer'},sector={value=sector.id_setor,cfsqltype='cf_sql_integer'},protocol={value='CODEX-CLOSE-' & left(createUUID(),16),cfsqltype='cf_sql_varchar'}};
 ticket=queryExecute("INSERT INTO tb_helpdesk_chamados(protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at) VALUES(:protocol,:owner,:sector,'Teste privado transacional de encerramento','aguardando_cliente',localtimestamp-interval '50 hours',localtimestamp) RETURNING id_chamado",params,{datasource='runner_dba'});
 id={value=ticket.id_chamado,cfsqltype='cf_sql_integer'};
 queryExecute("INSERT INTO tb_helpdesk_mensagens(id_chamado,id_usuario,mensagem,interno,created_at) VALUES(:id,:staff,'Resposta pública sintética',false,localtimestamp-interval '49 hours')",{id=id,staff=params.staff},{datasource='runner_dba'});
 service=new ScopedClose();service.limitTicket(ticket.id_chamado);
 stale=new StaleClose();stale.limitTicket(ticket.id_chamado);check(stale.run().closed EQ 0,'Snapshot de mensagem desatualizado após lock impede fechamento');
 result=service.run(50,true);check(result.closed EQ 0 AND result.eligible EQ 1,'Dry run identifica sem fechar');
 current=queryExecute('SELECT status FROM tb_helpdesk_chamados WHERE id_chamado=:id',{id=id},{datasource='runner_dba'});check(current.status EQ 'aguardando_cliente','Dry run não altera status');
 result=service.run();check(result.closed EQ 1 AND result.tickets[1] EQ ticket.id_chamado,'Fecha somente a fixture elegível');
 current=queryExecute("SELECT status,(SELECT count(*) FROM tb_helpdesk_mensagens m WHERE m.id_chamado=c.id_chamado) AS messages,(SELECT count(*) FROM tb_helpdesk_mensagens m WHERE m.id_chamado=c.id_chamado AND m.mensagem=:message AND NOT m.interno) AS automatic FROM tb_helpdesk_chamados c WHERE id_chamado=:id",{id=id,message={value=service.message(),cfsqltype='cf_sql_longvarchar'}},{datasource='runner_dba'});
 check(current.status EQ 'fechado' AND current.messages EQ 2 AND current.automatic EQ 1,'Status e aviso público são persistidos juntos');
 check(service.run().closed EQ 0,'Execução repetida não repete aviso');
 queryExecute("UPDATE tb_helpdesk_chamados SET status='aberto' WHERE id_chamado=:id",{id=id},{datasource='runner_dba'});
 queryExecute("UPDATE tb_helpdesk_mensagens SET created_at=created_at-interval '60 hours' WHERE id_chamado=:id",{id=id},{datasource='runner_dba'});
 check(service.run().closed EQ 0,'Reabrir manualmente sem resposta humana não dispara pelo aviso automático anterior');
 queryExecute("INSERT INTO tb_helpdesk_mensagens(id_chamado,id_usuario,mensagem,interno,created_at) VALUES(:id,:owner,'Cliente respondeu novamente',false,localtimestamp)",{id=id,owner=params.owner},{datasource='runner_dba'});
 queryExecute("UPDATE tb_helpdesk_chamados SET status='cliente_respondeu' WHERE id_chamado=:id",{id=id},{datasource='runner_dba'});
 check(service.run().closed EQ 0,'Resposta posterior do solicitante permanece aberta');
 transaction action='rollback';
}
remaining=queryExecute('SELECT count(*) AS tickets FROM tb_helpdesk_chamados WHERE id_chamado=:id',{id=id},{datasource='runner_dba'});check(remaining.tickets EQ 0,'Fixture e encerramento integralmente revertidos');
writeOutput('HELPDESK_CLOSE_TRANSACTION_PASSED ' & checks & '; all synthetic writes rolled back');
</cfscript>
