component output="false" {
  variables.datasource='runner_dba';
  public any function init(string datasource='runner_dba'){variables.datasource=arguments.datasource;return this;}
  public string function message(){return '[Mensagem automática] Este chamado foi encerrado automaticamente por falta de interação. Não recebemos uma nova resposta sua nas últimas 48 horas após a mensagem da equipe de atendimento. Se ainda precisar de ajuda, responda a este chamado para continuar o atendimento.';}
  public boolean function authorized(required string method,required struct headers,required string secret){
    if(arguments.method NEQ 'POST' OR !len(trim(arguments.secret)) OR !structKeyExists(arguments.headers,'Authorization'))return false;
    var header=trim(arguments.headers.Authorization&'');
    if(!reFindNoCase('^Bearer\s+\S+$',header))return false;
    var token=reReplaceNoCase(header,'^Bearer\s+','','one');
    return createObject('java','java.security.MessageDigest').isEqual(binaryDecode(hash(token,'SHA-256'),'hex'),binaryDecode(hash(arguments.secret,'SHA-256'),'hex'));
  }
  public struct function input(required string body){
    if(len(arguments.body) GT 4096 OR !isJSON(arguments.body))throw(type='HelpdeskAutoClose.InvalidRequest',message='Invalid JSON body');
    var data=deserializeJSON(arguments.body);
    if(isNull(data) OR !isStruct(data))throw(type='HelpdeskAutoClose.InvalidRequest',message='Expected JSON object');
    for(var key in data)if(!listFindNoCase('limit,dryRun',key))throw(type='HelpdeskAutoClose.InvalidRequest',message='Unknown field');
    if(structKeyExists(data,'limit') AND (!reFind('^[0-9]+$',serializeJSON(data.limit)) OR val(data.limit) LT 1 OR val(data.limit) GT 100))throw(type='HelpdeskAutoClose.InvalidRequest',message='Invalid limit');
    if(structKeyExists(data,'dryRun') AND !listFind('true,false',serializeJSON(data.dryRun)))throw(type='HelpdeskAutoClose.InvalidRequest',message='Invalid dryRun');
    return {limit=structKeyExists(data,'limit')?val(data.limit):50,dryRun=structKeyExists(data,'dryRun')?data.dryRun:false};
  }
  private string function eligibleSql(){
    return "SELECT cham.id_chamado,cham.status,cham.updated_at,last_reply.id_mensagem,last_reply.id_usuario,last_reply.created_at
      FROM tb_helpdesk_chamados cham
      CROSS JOIN LATERAL(SELECT m.id_mensagem,m.id_usuario,m.mensagem,m.created_at FROM tb_helpdesk_mensagens m
        WHERE m.id_chamado=cham.id_chamado AND NOT coalesce(m.interno,false)
        ORDER BY m.created_at DESC,m.id_mensagem DESC LIMIT 1) last_reply
      JOIN tb_usuarios staff ON staff.id=last_reply.id_usuario
      WHERE cham.status IN ('aberto','cliente_respondeu','aguardando_cliente','resolvido')
      AND coalesce(staff.is_admin,false) AND last_reply.id_usuario<>cham.id_usuario
      AND last_reply.created_at < localtimestamp-interval '48 hours'
      AND last_reply.mensagem<>:message";
  }
  public string function candidatesSql(boolean locking=false){
    return eligibleSql() & ' ORDER BY last_reply.created_at,cham.id_chamado LIMIT :limit' & (arguments.locking?' FOR UPDATE OF cham SKIP LOCKED':'');
  }
  public struct function run(numeric limit=50,boolean dryRun=false){
    if(arguments.limit LT 1 OR arguments.limit GT 100 OR arguments.limit NEQ int(arguments.limit))throw(type='HelpdeskAutoClose.InvalidLimit',message='Invalid batch limit');
    var params={limit={value=arguments.limit,cfsqltype='cf_sql_integer'},message={value=message(),cfsqltype='cf_sql_longvarchar'}};
    var options={datasource=variables.datasource,timeout=10};var closed=[];var selected=0;var ticket={};
    if(arguments.dryRun){
      var preview=queryExecute(candidatesSql(false),params,options);var ids=[];
      for(ticket in preview)arrayAppend(ids,val(ticket.id_chamado));
      return {success=true,status='dry_run',eligible=preview.recordCount,closed=0,tickets=ids};
    }
    transaction {
      var batch=queryExecute(candidatesSql(true),params,options);selected=batch.recordCount;
      for(ticket in batch){
        // A fresh READ COMMITTED statement after the parent lock sees replies
        // committed between selection's snapshot and acquisition of that lock.
        var guard=queryExecute(eligibleSql() & ' AND cham.id_chamado=:id',
          {id={value=ticket.id_chamado,cfsqltype='cf_sql_integer'},message=params.message},options);
        if(!guard.recordCount OR guard.id_mensagem NEQ ticket.id_mensagem)continue;
        queryExecute("INSERT INTO tb_helpdesk_mensagens(id_chamado,id_usuario,mensagem,interno,created_at) VALUES(:id,:author,:message,false,localtimestamp)",
          {id={value=ticket.id_chamado,cfsqltype='cf_sql_integer'},author={value=guard.id_usuario,cfsqltype='cf_sql_integer'},message=params.message},options);
        queryExecute("UPDATE tb_helpdesk_chamados SET status='fechado',updated_at=localtimestamp WHERE id_chamado=:id",{id={value=ticket.id_chamado,cfsqltype='cf_sql_integer'}},options);
        arrayAppend(closed,val(ticket.id_chamado));
      }
    }
    return {success=true,status='completed',selected=selected,closed=arrayLen(closed),tickets=closed};
  }
}
