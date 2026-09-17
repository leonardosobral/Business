component output="false" {
  variables.db={datasource="runner_dba"};
  public numeric function id(any value="") { return reFind("^[1-9][0-9]{0,8}$",trim(arguments.value & "")) ? val(arguments.value) : 0; }
  public struct function scope(boolean admin=false,string visible="0",string operate="0",string pages="0") {
    return {admin=arguments.admin,visible=arguments.visible,operate=arguments.operate,pages=arguments.pages};
  }
  private struct function param(required any value,string type="cf_sql_varchar") { return {value=arguments.value,cfsqltype=arguments.type}; }
  private struct function ids(required string value) { return {value=len(arguments.value) ? arguments.value : '0',cfsqltype='cf_sql_integer',list=true}; }
  private struct function visibility(required struct access) {
    if (access.admin) return {sql='true',params={}};
    return {sql="(EXISTS (SELECT 1 FROM tb_evento_corridas_cupom v WHERE v.id_cupom=c.id_cupom AND v.id_evento IN (:visible)) OR EXISTS (SELECT 1 FROM tb_evento_circuitos_cupom v JOIN tb_evento_corridas e ON e.id_agrega_evento=v.id_agrega_evento WHERE v.id_cupom=c.id_cupom AND e.id_evento IN (:visible)) OR EXISTS (SELECT 1 FROM tb_paginas_cupom v WHERE v.id_cupom=c.id_cupom AND v.id_pagina IN (:pages)))",params={visible=ids(access.visible),pages=ids(access.pages)}};
  }
  public boolean function canEdit(required numeric couponId,required struct access) {
    if (access.admin) return true;
    var q=queryExecute("SELECT EXISTS (SELECT 1 FROM tb_evento_corridas_cupom WHERE id_cupom=:id) AND NOT EXISTS (SELECT 1 FROM tb_evento_corridas_cupom WHERE id_cupom=:id AND id_evento NOT IN (:operate)) AND NOT EXISTS (SELECT 1 FROM tb_evento_circuitos_cupom WHERE id_cupom=:id) AND NOT EXISTS (SELECT 1 FROM tb_paginas_cupom WHERE id_cupom=:id) AS allowed",{id=param(couponId,'cf_sql_integer'),operate=ids(access.operate)},variables.db);
    return q.allowed[1];
  }
  public query function events(required struct access,string search="",numeric selected=0) {
    var p={term=param('%' & replace(replace(replace(left(trim(search),100),'!','!!','all'),'%','!%','all'),'_','!_','all') & '%'),selected=param(selected,'cf_sql_integer')};
    var sql="SELECT id_evento,nome_evento,tag,data_inicial FROM tb_evento_corridas WHERE (nome_evento ILIKE :term ESCAPE '!' OR tag ILIKE :term ESCAPE '!' OR id_evento=:selected)";
    if (!access.admin) {sql &= ' AND id_evento IN (:operate)';p.operate=ids(access.operate);}
    return queryExecute(sql & ' ORDER BY (id_evento=:selected) DESC,data_inicial DESC NULLS LAST,id_evento DESC LIMIT 40',p,variables.db);
  }
  public query function get(required numeric couponId,required struct access,boolean locked=false) {
    var v=visibility(access);v.params.id=param(couponId,'cf_sql_integer');
    return queryExecute('SELECT c.*,c.xmin::text AS revision FROM tb_cupom c WHERE c.id_cupom=:id AND ' & v.sql & (locked ? ' FOR UPDATE OF c' : ''),v.params,variables.db);
  }
  public query function links(required numeric couponId,required struct access) {
    var p={id=param(couponId,'cf_sql_integer')};var clause='';
    if (!access.admin) {clause=' AND l.id_evento IN (:visible)';p.visible=ids(access.visible);}
    return queryExecute("SELECT l.*,e.nome_evento,e.tag FROM tb_evento_corridas_cupom l JOIN tb_evento_corridas e ON e.id_evento=l.id_evento WHERE l.id_cupom=:id" & clause & ' ORDER BY e.nome_evento,l.id_evento_cupom',p,variables.db);
  }
  public query function otherLinks(required numeric couponId,required struct access) {
    var p={id=param(couponId,'cf_sql_integer')};var circuits='';var pages='';
    if (!access.admin) {circuits=' AND EXISTS (SELECT 1 FROM tb_evento_corridas e WHERE e.id_agrega_evento=l.id_agrega_evento AND e.id_evento IN (:visible))';pages=' AND l.id_pagina IN (:pages)';p.visible=ids(access.visible);p.pages=ids(access.pages);}
    return queryExecute("SELECT 'Circuito' AS tipo,e.nome_evento_agregado AS nome FROM tb_evento_circuitos_cupom l JOIN tb_agrega_eventos e ON e.id_agrega_evento=l.id_agrega_evento WHERE l.id_cupom=:id" & circuits & " UNION ALL SELECT 'Página' AS tipo,p.nome FROM tb_paginas_cupom l JOIN tb_paginas p ON p.id_pagina=l.id_pagina WHERE l.id_cupom=:id" & pages,p,variables.db);
  }
  public struct function listing(required struct access,struct filters={}) {
    var v=visibility(access);var f={search=left(trim(filters.busca ?: ''),120),status=lCase(filters.status ?: ''),page=max(1,min(100000,val(filters.pagina ?: 1)))};
    if (!listFind('ativos,inativos,expirados',f.status)) f.status='';
    var where=' WHERE ' & v.sql;
    var stats=queryExecute("SELECT count(*) AS total,count(*) FILTER (WHERE c.ativo AND (c.data_expiracao IS NULL OR c.data_expiracao>=current_date)) AS ativos,count(*) FILTER (WHERE NOT c.ativo) AS inativos,count(*) FILTER (WHERE c.ativo AND c.data_expiracao<current_date) AS expirados FROM tb_cupom c" & where,v.params,variables.db);
    if (len(f.search)) {where &= " AND (c.cupom ILIKE :search ESCAPE '!' OR c.parceiro ILIKE :search ESCAPE '!' OR EXISTS (SELECT 1 FROM tb_evento_corridas_cupom l JOIN tb_evento_corridas e ON e.id_evento=l.id_evento WHERE l.id_cupom=c.id_cupom AND e.nome_evento ILIKE :search ESCAPE '!'" & (access.admin ? '' : ' AND e.id_evento IN (:visible)') & '))';v.params.search=param('%' & replace(replace(replace(f.search,'!','!!','all'),'%','!%','all'),'_','!_','all') & '%');}
    if (f.status EQ 'ativos') where &= ' AND c.ativo AND (c.data_expiracao IS NULL OR c.data_expiracao>=current_date)';
    if (f.status EQ 'inativos') where &= ' AND NOT c.ativo';
    if (f.status EQ 'expirados') where &= ' AND c.ativo AND c.data_expiracao<current_date';
    var total=queryExecute('SELECT count(*) AS total FROM tb_cupom c' & where,v.params,variables.db).total[1];
    var pages=max(1,ceiling(total/20));f.page=min(int(f.page),pages);v.params.offset=param((f.page-1)*20,'cf_sql_integer');
    var q=queryExecute("SELECT c.*,CASE WHEN NOT c.ativo THEN 'Inativo' WHEN c.data_expiracao<current_date THEN 'Expirado' ELSE 'Ativo' END AS situacao FROM tb_cupom c" & where & ' ORDER BY c.data_cadastro DESC,c.id_cupom DESC LIMIT 20 OFFSET :offset',v.params,variables.db);
    return {coupons=q,stats=stats,total=total,page=f.page,pages=pages,filters=f};
  }
  public struct function validate(required struct input,boolean creating=false) {
    var d={};
    for (var field in ['cupom','parceiro','descricao','condicoes','url','data_expiracao','inicio','fim','quantidade']) d[field]=trim(input[field] ?: '');
    d.id=id(input.id_cupom ?: '');d.evento=id(input.id_evento ?: '');d.link=id(input.id_evento_cupom ?: '');
    d.ativo=(input.ativo ?: 'false') EQ 'true';d.revision=input.revision ?: '';
    if (!reFind('^[A-Za-z0-9_.-]{1,32}$',d.cupom)) throw(type='Coupon.Validation',message='Use até 32 letras, números, pontos, hífens ou sublinhados no código.');
    if (!len(d.parceiro) OR !len(d.condicoes)) throw(type='Coupon.Validation',message='Informe o parceiro e o desconto ou condições do cupom.');
    for (var field in ['parceiro','descricao','condicoes']) if (len(d[field])>256) throw(type='Coupon.Validation',message='Parceiro, descrição e condições aceitam até 256 caracteres cada.');
    for (var field in ['parceiro','descricao','condicoes']) if (reFind('[<>]',d[field])) throw(type='Coupon.Validation',message='Informe parceiro, descrição e condições em texto simples, sem marcações HTML.');
    if (len(d.url) AND (len(d.url)>2048 OR !reFindNoCase('^https?://[^\s/@]+(?::[0-9]+)?(?:[/?##][^\s]*)?$',d.url))) throw(type='Coupon.Validation',message='Informe um link completo começando com https:// ou http://, sem credenciais.');
    if (reFind('[<>"' & chr(39) & '\x00-\x20]',d.url)) throw(type='Coupon.Validation',message='O link contém caracteres inválidos.');
    if (!listFind('true,false',input.ativo ?: 'false')) throw(type='Coupon.Validation',message='Selecione uma disponibilidade válida.');
    validDate(d.data_expiracao,false);
    if (creating) validateLink(d);
    return d;
  }
  private void function validDate(required string value,boolean requiredDate=true) {
    if (!len(value) AND !requiredDate) return;
    if (!reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',value) OR !isDate(value)) throw(type='Coupon.Validation',message='Informe uma data válida no formato ano-mês-dia.');
  }
  private void function validateLink(required struct d) {
    if (!d.evento) throw(type='Coupon.Validation',message='Pesquise e selecione um evento cadastrado.');
    validDate(d.inicio);validDate(d.fim);
    if (d.inicio GT d.fim) throw(type='Coupon.Validation',message='O fim da validade não pode ser anterior ao início.');
    if (len(d.data_expiracao) AND d.fim GT d.data_expiracao) throw(type='Coupon.Validation',message='A validade no evento não pode ultrapassar a expiração do cupom.');
    if (len(d.quantidade) AND (!id(d.quantidade))) throw(type='Coupon.Validation',message='A quantidade deve ser um número inteiro positivo ou ficar em branco.');
  }
  private void function assertEvent(required numeric eventId,required struct access) {
    var p={id=param(eventId,'cf_sql_integer')};var sql='SELECT id_evento FROM tb_evento_corridas WHERE id_evento=:id';
    if (!access.admin) {sql &= ' AND id_evento IN (:operate)';p.operate=ids(access.operate);}
    if (!queryExecute(sql,p,variables.db).recordcount) throw(type='Coupon.Forbidden',message='Você não tem permissão para gerenciar este evento.');
  }
  public numeric function save(required string action,required struct input,required struct access) {
    if (!access.admin AND access.operate EQ '0') throw(type='Coupon.Forbidden',message='Seu acesso permite somente consultar cupons.');
    if (!listFind('criar,editar,status,vincular,desvincular',action)) throw(type='Coupon.Validation',message='Ação inválida.');
    var couponId=action EQ 'criar' ? 0 : id(input.id_cupom ?: '');var d={};var current=queryNew('id_cupom');
    transaction {
      if (action NEQ 'criar') {
        current=get(couponId,access,true);
        if (!current.recordcount OR !canEdit(couponId,access)) throw(type='Coupon.Forbidden',message='Este cupom não pode ser alterado por sua conta. Cupons compartilhados com outros eventos, páginas ou circuitos devem ser gerenciados pela equipe global.');
        if (compare(current.revision[1],input.revision ?: '') NEQ 0) throw(type='Coupon.Conflict',message='O cupom foi atualizado em outra sessão. Recarregue os dados antes de salvar; seu texto foi mantido nesta tela.');
      }
      if (listFind('criar,editar',action)) {
        d=validate(input,action EQ 'criar');
        // Serialize duplicate checks across Business coupon writes; no unique-index migration needed.
        queryExecute("SELECT pg_advisory_xact_lock(164762,hashtext(lower(:code)))",{code=param(d.cupom)},variables.db);
        var dupSql='SELECT c.id_cupom FROM tb_cupom c WHERE lower(trim(c.cupom))=lower(:code) AND lower(trim(c.parceiro))=lower(:partner) AND c.id_cupom<>:id';
        var dupParams={code=param(d.cupom),partner=param(d.parceiro),id=param(couponId,'cf_sql_integer')};
        if (!access.admin) {var v=visibility(access);dupSql &= ' AND ' & v.sql;structAppend(dupParams,v.params);}
        var codeChanged=action EQ 'criar' OR compareNoCase(d.cupom,trim(current.cupom[1])) NEQ 0 OR compareNoCase(d.parceiro,trim(current.parceiro[1])) NEQ 0;
        if (codeChanged AND queryExecute(dupSql,dupParams,variables.db).recordcount) throw(type='Coupon.Validation',message='Já existe um cupom com esse código e parceiro no seu catálogo. Edite o existente para adicionar um evento.');
        var p={code=param(d.cupom),partner=param(d.parceiro),description=param(d.descricao),conditions=param(d.condicoes),url=param(d.url),active=param(d.ativo,'cf_sql_boolean'),expiry={value=d.data_expiracao,cfsqltype='cf_sql_date',null=!len(d.data_expiracao)},id=param(couponId,'cf_sql_integer')};
        if (action EQ 'criar') {
          assertEvent(d.evento,access);
          couponId=queryExecute('INSERT INTO tb_cupom(cupom,parceiro,descricao,condicoes,url,ativo,data_expiracao) VALUES(:code,:partner,:description,:conditions,:url,:active,:expiry) RETURNING id_cupom',p,variables.db).id_cupom[1];
        } else {
          if (len(d.data_expiracao) AND queryExecute('SELECT id_cupom FROM tb_evento_corridas_cupom WHERE id_cupom=:id AND data_validade_fim>:expiry UNION ALL SELECT id_cupom FROM tb_evento_circuitos_cupom WHERE id_cupom=:id AND data_validade_fim>:expiry',{id=p.id,expiry=p.expiry},variables.db).recordcount) throw(type='Coupon.Validation',message='Há vínculos que terminam após essa expiração. Ajuste primeiro a validade dos vínculos ou escolha uma expiração posterior.');
          queryExecute('UPDATE tb_cupom SET cupom=:code,parceiro=:partner,descricao=:description,condicoes=:conditions,url=:url,ativo=:active,data_expiracao=:expiry WHERE id_cupom=:id',p,variables.db);
        }
      }
      if (action EQ 'status') {
        if (!listFind('true,false',input.ativo ?: '')) throw(type='Coupon.Validation',message='Status inválido.');
        queryExecute('UPDATE tb_cupom SET ativo=:active WHERE id_cupom=:id',{active=param(input.ativo EQ 'true','cf_sql_boolean'),id=param(couponId,'cf_sql_integer')},variables.db);
      }
      if (listFind('criar,vincular',action)) {
        if (action EQ 'vincular') {d={evento=id(input.id_evento ?: ''),inicio=trim(input.inicio ?: ''),fim=trim(input.fim ?: ''),quantidade=trim(input.quantidade ?: ''),data_expiracao=isDate(current.data_expiracao[1]) ? dateFormat(current.data_expiracao[1],'yyyy-mm-dd') : ''};validateLink(d);assertEvent(d.evento,access);}
        var p={id=param(couponId,'cf_sql_integer'),event=param(d.evento,'cf_sql_integer'),start=param(d.inicio,'cf_sql_date'),finish=param(d.fim,'cf_sql_date'),quantity={value=d.quantidade,cfsqltype='cf_sql_integer',null=!len(d.quantidade)}};
        var existing=queryExecute('SELECT id_evento_cupom FROM tb_evento_corridas_cupom WHERE id_cupom=:id AND id_evento=:event',p,variables.db);
        if (existing.recordcount GT 1) throw(type='Coupon.Validation',message='Existem vínculos duplicados com este evento. A equipe global precisa revisar os registros antes da edição.');
        if (existing.recordcount) queryExecute('UPDATE tb_evento_corridas_cupom SET data_validade_inicio=:start,data_validade_fim=:finish,qtd_limite_cupom=:quantity WHERE id_cupom=:id AND id_evento=:event',p,variables.db);
        else queryExecute('INSERT INTO tb_evento_corridas_cupom(id_cupom,id_evento,data_cadastro,data_validade_inicio,data_validade_fim,qtd_limite_cupom) VALUES(:id,:event,current_date,:start,:finish,:quantity)',p,variables.db);
        queryExecute('UPDATE tb_cupom SET ativo=ativo WHERE id_cupom=:id',{id=p.id},variables.db);
      }
      if (action EQ 'desvincular') {
        var linkId=id(input.id_evento_cupom ?: '');
        var currentLinks=links(couponId,access);
        if (!access.admin AND currentLinks.recordcount LTE 1) throw(type='Coupon.Validation',message='Mantenha ao menos um evento vinculado. Para retirar o benefício, desative o cupom.');
        queryExecute('DELETE FROM tb_evento_corridas_cupom WHERE id_cupom=:id AND id_evento_cupom=:link',{id=param(couponId,'cf_sql_integer'),link=param(linkId,'cf_sql_integer')},variables.db);
        queryExecute('UPDATE tb_cupom SET ativo=ativo WHERE id_cupom=:id',{id=param(couponId,'cf_sql_integer')},variables.db);
      }
    }
    return couponId;
  }
}
