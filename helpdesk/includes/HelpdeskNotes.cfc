component output="false" {
  public void function save(required numeric ticketId,required numeric actorId,required string text,required string revision,required numeric lastMessage) {
    var body=trim(arguments.text);var opts={datasource='runner_dba',timeout=10};
    if(arguments.ticketId LT 1 OR !len(body) OR len(body) GT 12000)throw(type='HelpdeskNotes.Validation',message='Escreva uma nota entre 1 e 12.000 caracteres.');
    var actor=queryExecute('SELECT id FROM tb_usuarios WHERE id=:id AND is_admin=true',{id={value=arguments.actorId,cfsqltype='cf_sql_integer'}},opts);
    if(!actor.recordCount)throw(type='HelpdeskNotes.Forbidden',message='Apenas a equipe administrativa pode registrar notas internas.');
    transaction {
      var current=queryExecute("SELECT to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US') revision,(SELECT coalesce(max(id_mensagem),0) FROM tb_helpdesk_mensagens WHERE id_chamado=c.id_chamado) last_message FROM tb_helpdesk_chamados c WHERE id_chamado=:id FOR UPDATE",{id={value=arguments.ticketId,cfsqltype='cf_sql_integer'}},opts);
      if(!current.recordCount OR compare(current.revision,arguments.revision) NEQ 0 OR current.last_message NEQ arguments.lastMessage)throw(type='HelpdeskNotes.Conflict',message='O chamado recebeu uma atualização. Recarregue a conversa e revise sua nota antes de tentar novamente. Seu texto foi preservado.');
      queryExecute('INSERT INTO tb_helpdesk_mensagens(id_chamado,id_usuario,mensagem,interno,created_at) VALUES(:ticket,:actor,:body,true,localtimestamp)',{ticket={value=arguments.ticketId,cfsqltype='cf_sql_integer'},actor={value=arguments.actorId,cfsqltype='cf_sql_integer'},body={value=body,cfsqltype='cf_sql_longvarchar'}},opts);
      queryExecute('UPDATE tb_helpdesk_chamados SET updated_at=localtimestamp WHERE id_chamado=:id',{id={value=arguments.ticketId,cfsqltype='cf_sql_integer'}},opts);
    }
    // No public reply, routing change or notification dispatch here.
  }
}
