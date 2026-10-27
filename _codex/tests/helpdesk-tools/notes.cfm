<cfscript>
checks=0;function check(required boolean ok,required string name){if(!ok)throw(message=name);checks++;}
service=new __NOTES__();
transaction {
 actors=queryExecute('SELECT min(id) FILTER(WHERE is_admin) AS staff,min(id) FILTER(WHERE NOT coalesce(is_admin,false)) AS owner FROM tb_usuarios',{},{datasource='runner_dba'});
 sector=queryExecute('SELECT min(id_setor) AS id FROM tb_helpdesk_setores',{},{datasource='runner_dba'});
 t=queryExecute("INSERT INTO tb_helpdesk_chamados(protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at) VALUES(:protocol,:owner,:sector,'Fixture privada notas','aguardando_cliente',localtimestamp-interval '50 hours',localtimestamp) RETURNING id_chamado,to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US') revision",{protocol={value='CODEX-NOTE-'&left(createUUID(),16),cfsqltype='cf_sql_varchar'},owner={value=actors.owner,cfsqltype='cf_sql_integer'},sector={value=sector.id,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
 args={ticketId=t.id_chamado,actorId=actors.staff,text='Nota privada <script> & multilinha'&chr(10)&'linha 2',revision=t.revision,lastMessage=0};
 bad=duplicate(args);bad.actorId=actors.owner;denied=false;try{service.save(argumentCollection=bad);}catch(HelpdeskNotes.Forbidden e){denied=true;}check(denied,'Não admin não pode registrar nota');
 service.save(argumentCollection=args);
 state=queryExecute("SELECT status,id_setor,(SELECT count(*) FROM tb_helpdesk_mensagens WHERE id_chamado=c.id_chamado AND interno) notes,(SELECT count(*) FROM tb_helpdesk_mensagens WHERE id_chamado=c.id_chamado AND NOT interno) public FROM tb_helpdesk_chamados c WHERE id_chamado=:id",{id={value=t.id_chamado,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
 check(state.status EQ 'aguardando_cliente' AND state.id_setor EQ sector.id,'Nota preserva status e setor');check(state.notes EQ 1 AND state.public EQ 0,'Nota não fica na consulta pública');
 qChamadoAtual=queryNew('id_chamado','integer',[{id_chamado=t.id_chamado}]);URL.id_chamado=t.id_chamado;
 include 'legacy-messages.cfm';check(qChamadoMensagens.recordCount EQ 0,'Página legada RR não expõe notas internas');
 m=queryExecute('SELECT id_usuario,mensagem,interno FROM tb_helpdesk_mensagens WHERE id_chamado=:id',{id={value=t.id_chamado,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});check(m.id_usuario EQ actors.staff AND m.mensagem EQ args.text AND m.interno,'Autor e texto íntegros');
 denied=false;try{service.save(argumentCollection=args);}catch(HelpdeskNotes.Conflict e){denied=true;}check(denied,'Snapshot antigo impede nota duplicada');
 transaction action='rollback';
}
check(queryExecute('SELECT count(*) AS n FROM tb_helpdesk_chamados WHERE id_chamado=:id',{id={value=t.id_chamado,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'}).n EQ 0,'Fixture revertida');
writeOutput('HELPDESK_TOOLS_NOTES_PASSED '&checks);
</cfscript>
