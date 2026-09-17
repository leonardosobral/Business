  public void function fixtureReset(string mode='admin') {variables.fixtureMode=mode;variables.calls=[];}
  public array function fixtureCalls(){return variables.calls;}
  private query function fixtureQuery(required string sql,struct params={},struct options={}) {
    if (!structKeyExists(variables,'calls')) fixtureReset();
    arrayAppend(variables.calls,{sql=sql,params=params});
    if (options.datasource NEQ 'runner_dba') throw(message='Wrong datasource');
    if (find('ads.',sql)) throw(message='Advertising mutation');
    if (find('AS allowed',sql)) return queryNew('allowed','bit',[[variables.fixtureMode EQ 'owned']]);
    if (find('FOR UPDATE OF c',sql) OR find('c.xmin::text',sql)) return queryNew('id_cupom,cupom,parceiro,descricao,condicoes,url,data_expiracao,ativo,revision','integer,varchar,varchar,varchar,varchar,varchar,date,bit,varchar',[[77,'CORRIDA10','Organizador de teste','Descrição','10%','https://example.invalid/',createDate(2026,12,31),true,'42']]);
    if (find('SELECT id_evento FROM',sql)) return variables.fixtureMode EQ 'no-event' ? queryNew('id_evento') : queryNew('id_evento','integer',[[123]]);
    if (find('RETURNING id_cupom',sql)) return queryNew('id_cupom','integer',[[77]]);
    if (find('lower(trim(c.cupom))',sql)) return variables.fixtureMode EQ 'duplicate' ? queryNew('id_cupom','integer',[[88]]) : queryNew('id_cupom');
    if (find('SELECT id_evento_cupom',sql)) return queryNew('id_evento_cupom');
    if (find(' AS ativos',sql)) return queryNew('total,ativos,inativos,expirados','integer,integer,integer,integer',[[2,1,1,0]]);
    if (find('count(*) AS total',sql)) return queryNew('total','integer',[[2]]);
    if (find('AS situacao',sql)) return queryNew('id_cupom,cupom,parceiro,condicoes,data_expiracao,situacao','integer,varchar,varchar,varchar,date,varchar',[[77,'CORRIDA10','Organizador de teste','10%',createDate(2026,12,31),'Ativo'],[78,'INATIVO','Parceiro <script>alert(1)</script>','R$ 15',createDate(2026,12,31),'Inativo']]);
    return queryNew('id_cupom');
  }
