component output="false" {
  public struct function filters(required struct input) {
    var f = {busca=left(trim(arguments.input.busca ?: ""),160), status=lCase(trim(arguments.input.status ?: "")), setor=0, fila=lCase(trim(arguments.input.fila ?: "")), ordem=lCase(trim(arguments.input.ordem ?: "prioridade")), pagina=1};
    if (!listFindNoCase("aberto,cliente_respondeu,em_atendimento,aguardando_cliente,resolvido,fechado",f.status)) f.status="";
    if (!listFindNoCase("pendentes,sem_atualizacao,meus",f.fila)) f.fila="";
    if (!listFindNoCase("prioridade,recentes,antigos",f.ordem)) f.ordem="prioridade";
    if (reFind("^[0-9]{1,9}$",trim(arguments.input.setor ?: ""))) f.setor=val(arguments.input.setor);
    if (reFind("^[0-9]{1,6}$",trim(arguments.input.pagina ?: ""))) f.pagina=max(1,val(arguments.input.pagina));
    return f;
  }

  public struct function plan(required struct filters, required numeric userId) {
    var f=arguments.filters;
    var p={sql=" WHERE 1=1",params={}};
    if (len(f.busca)) {
      p.sql &= " AND (cham.protocolo ILIKE :busca ESCAPE '!' OR cham.assunto ILIKE :busca ESCAPE '!' OR usr.name ILIKE :busca ESCAPE '!' OR usr.email ILIKE :busca ESCAPE '!')";
      p.params.busca={value="%" & replace(replace(replace(f.busca,"!","!!","all"),"%","!%","all"),"_","!_","all") & "%",cfsqltype="cf_sql_varchar"};
    }
    if (len(f.status)) {
      p.sql &= " AND cham.status=:status";
      p.params.status={value=f.status,cfsqltype="cf_sql_varchar"};
    }
    if (f.setor GT 0) {
      p.sql &= " AND cham.id_setor=:setor";
      p.params.setor={value=f.setor,cfsqltype="cf_sql_integer"};
    }
    if (f.fila EQ "pendentes") p.sql &= " AND cham.status IN ('aberto','cliente_respondeu')";
    if (f.fila EQ "sem_atualizacao") p.sql &= " AND cham.status NOT IN ('resolvido','fechado') AND cham.updated_at < now()-interval '48 hours'";
    if (f.fila EQ "meus") {
      p.sql &= " AND setr.id_usuario_responsavel=:responsavel";
      p.params.responsavel={value=arguments.userId,cfsqltype="cf_sql_integer"};
    }
    p.order="cham.updated_at DESC, cham.id_chamado DESC";
    if (f.ordem EQ "antigos") p.order="cham.created_at ASC, cham.id_chamado ASC";
    if (f.ordem EQ "prioridade") p.order="CASE WHEN cham.status='cliente_respondeu' THEN 0 WHEN cham.status='aberto' THEN 1 WHEN cham.status='em_atendimento' THEN 2 WHEN cham.status='aguardando_cliente' THEN 3 ELSE 4 END, cham.updated_at ASC, cham.id_chamado ASC";
    return p;
  }

  public struct function load(required struct filters, required numeric userId) {
    var p=plan(arguments.filters,arguments.userId);
    var base=" FROM tb_helpdesk_chamados cham INNER JOIN tb_usuarios usr ON usr.id=cham.id_usuario INNER JOIN tb_helpdesk_setores setr ON setr.id_setor=cham.id_setor LEFT JOIN tb_usuarios resp ON resp.id=setr.id_usuario_responsavel";
    var options={datasource="runner_dba"};
    var result={};
    result.total=queryExecute("SELECT count(*) AS total" & base & p.sql,p.params,options).total[1];
    result.pages=max(1,ceiling(result.total/20));
    result.page=min(arguments.filters.pagina,result.pages);
    p.params.limite={value=20,cfsqltype="cf_sql_integer"};
    p.params.deslocamento={value=(result.page-1)*20,cfsqltype="cf_sql_integer"};
    result.tickets=queryExecute("SELECT cham.id_chamado,cham.protocolo,cham.assunto,cham.status,cham.id_setor,cham.created_at,cham.updated_at,usr.name AS nome_usuario,usr.email AS email_usuario,setr.nome_setor,coalesce(resp.name,'Sem responsável') AS nome_responsavel,
      (SELECT count(*) FROM tb_helpdesk_mensagens m WHERE m.id_chamado=cham.id_chamado) AS mensagens,
      (cham.status NOT IN ('resolvido','fechado') AND cham.updated_at < now()-interval '48 hours') AS sem_atualizacao"
      & base & p.sql & " ORDER BY " & p.order & " LIMIT :limite OFFSET :deslocamento",p.params,options);
    result.stats=queryExecute("SELECT count(*) AS total,
      count(*) FILTER (WHERE status IN ('aberto','cliente_respondeu')) AS pendentes,
      count(*) FILTER (WHERE status='em_atendimento') AS em_atendimento,
      count(*) FILTER (WHERE status='aguardando_cliente') AS aguardando_cliente,
      count(*) FILTER (WHERE status IN ('resolvido','fechado')) AS encerrados,
      count(*) FILTER (WHERE status NOT IN ('resolvido','fechado') AND updated_at < now()-interval '48 hours') AS sem_atualizacao
      FROM tb_helpdesk_chamados",{},options);
    return result;
  }
}
