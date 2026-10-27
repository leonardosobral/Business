component extends="ScopedClose" {
 public string function candidatesSql(boolean locking=false){return replace(super.candidatesSql(arguments.locking),'last_reply.id_mensagem,','(-last_reply.id_mensagem) AS id_mensagem,','one');}
}
