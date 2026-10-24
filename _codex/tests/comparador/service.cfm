<cfsetting showdebugoutput="false" requesttimeout="60"><cfcontent type="application/json; charset=utf-8"><cfscript>
results=[];
function check(required string name,required boolean pass){arrayAppend(results,{name=name,pass=pass});}
function rejects(required string name,required any run, string kind="Comparador.Validation") {try{run();check(name,false);}catch(any e){check(name,e.type==kind);}}
try {
 s=createObject('component','services.ComparadorAdminService').init('codex_comparador_test');
 ctx={actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};
 rejects('Non-admin cannot read catalog',function(){s.listProducts({actorId=99,isAdmin=false,delegated=false});},'Comparador.Forbidden');
 rejects('Delegation cannot read catalog',function(){s.listProducts({actorId=99,isAdmin=true,delegated=true});},'Comparador.Forbidden');
 for(bad in ['12xyz','1e3','1,234.56','NaN','-2','0']) {rejects('Reject malformed price ' & bad,function(){s.decimalValue(bad,false,false);});}
 check('Comma decimal preserved',s.decimalValue('12,50',false,false)=='12.50');
 check('Zero measurement allowed',s.decimalValue('0',false,true)=='0');
 check('Blank unknown allowed',s.decimalValue('',true,true)=='');
 for(badUrl in ['javascript:alert(1)','//evil.test','https://','https://u:p@example.com','https://exa mple.com','https://[::1]/','https://example.com:123456/','https://example.com/a''b']) {rejects('Reject unsafe URL ' & badUrl,function(){s.offerUrl(badUrl);});}
 check('Valid HTTPS accepted',s.offerUrl('https://example.com/produto?a=1&b=2')=='https://example.com/produto?a=1&b=2');
 data={nome_produto='Produto sintético <teste>',tag_tipo_produto='cameras',tag_marca='marca-a',tag_categoria='video',tag_produto='admin-sintetico-' & lCase(replace(createUUID(),'-','','all')),num_versao='0',versao='1',resumo='Teste',descricao='Descrição',preco_referencia='',data_lancamento=''};
 rejects('GET cannot write',function(){var c=duplicate(ctx);c.isPost=false;s.saveProduct(c,data);},'Comparador.Forbidden');
 rejects('CSRF cannot write',function(){var c=duplicate(ctx);c.csrfVerified=false;s.saveProduct(c,data);},'Comparador.Forbidden');
 queryExecute("SELECT setval('comparador.tb_produto_id_produto_seq',greatest((SELECT last_value FROM comparador.tb_produto_id_produto_seq),904000))",{},{datasource='codex_comparador_test'});
  id=s.saveProduct(ctx,data);
  current=s.load(ctx,id);
  check('New product is draft',current.product.estado=='rascunho');
  check('Unknown reference stays NULL',queryExecute('SELECT preco_referencia IS NULL AS empty FROM comparador.tb_produto WHERE id_produto=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'}).empty);
  check('Creation audited',current.history.recordCount==1);
  stale=current.token;
  data.id_produto=id;data.token=current.token;data.preco_referencia='1234,56';
  s.saveProduct(ctx,data);current=s.load(ctx,id);
  check('Reference decimal stored',current.product.preco_referencia==1234.56);
  rejects('Stale product rejected',function(){data.token=stale;s.saveProduct(ctx,data);},'Comparador.Conflict');
  data.token=current.token;data.tag_categoria='treino';
  rejects('Cross-type category rejected',function(){s.saveProduct(ctx,data);});
  data.tag_categoria='video';data.tag_produto='modelo';
  rejects('Duplicate slug rejected',function(){s.saveProduct(ctx,data);});
  before=s.load(ctx,id);
  rejects('Partial feature update rolls back',function(){s.saveSpecifications(ctx,id,before.token,[{id=0,tag='resolucao',value='4K',note=''},{id=0,tag='not-found',value='x',note=''}],[]);});
  check('No partial feature persisted',s.load(ctx,id).features.recordCount==0);
  s.saveSpecifications(ctx,id,before.token,[{id=0,tag='resolucao',value='4K',note=''}],[{gender='U',weight='0',size='42,5'}]);
  current=s.load(ctx,id);
  check('Type characteristic saved',current.features.caracteristica_dominio=='4K');
  check('Variants preserve zero and fraction',current.variants.peso==0 AND current.variants.tamanho==42.5);
  before=current.token;
  queryExecute('UPDATE comparador.tb_genero SET tamanho=43 WHERE id_produto=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'});
  rejects('External change detected',function(){s.changeState(ctx,id,before,'publicado');},'Comparador.Conflict');
  current=s.load(ctx,id);s.changeState(ctx,id,current.token,'publicado');
  current=s.load(ctx,id);check('Explicit publish works',current.product.estado=='publicado');
  s.addOffer(ctx,id,current.token,{preco_promocional='999,90',loja='Loja sintética',link='https://example.com/oferta',cupom='',condicoes='Teste',data_expiracao='2099-01-01'});
  current=s.load(ctx,id);check('Offer empty coupon supported',current.offers.recordCount==1 AND current.offers.cupom=='');
  s.addOffer(ctx,id,current.token,{preco_promocional='899',loja='Loja sintética',link='https://example.com/vencida',cupom='CUPOM',condicoes='Teste',data_expiracao='2000-01-01'});
  current=s.load(ctx,id);check('Latest expired remains candidate',current.offers.recordCount==2 AND current.offers.data_expiracao[1]<now() AND current.offers.is_latest[1]);
  s.changeState(ctx,id,current.token,'arquivado');
  check('Archive works',s.load(ctx,id).product.estado=='arquivado');
  check('Every successful write audited',s.load(ctx,id).history.recordCount==7);
  legacyId=queryExecute("INSERT INTO comparador.tb_produto_caracteristica(id_produto,tag_caracteristica,caracteristica_dominio) VALUES(:id,'placa','sim') RETURNING id_produto_caracteristica",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'}).id_produto_caracteristica;
  current=s.load(ctx,id);s.saveSpecifications(ctx,id,current.token,[{id=legacyId,tag='placa',value='sim',note=''}],[]);
  check('Unchanged legacy boolean preserved',queryExecute('SELECT caracteristica_dominio AS value FROM comparador.tb_produto_caracteristica WHERE id_produto_caracteristica=:id',{id={value=legacyId,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'}).value=='sim');
  current=s.load(ctx,id);s.saveSpecifications(ctx,id,current.token,[{id=legacyId,tag='placa',value='não',note=''}],[]);
  check('Portuguese boolean canonical for public reader',queryExecute('SELECT caracteristica_dominio AS value FROM comparador.tb_produto_caracteristica WHERE id_produto_caracteristica=:id',{id={value=legacyId,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'}).value=='false');

 current=s.load(ctx,id);data.tag_produto='zerar';data.token=current.token;data.tag_categoria='video';
 rejects('Reserved clear route slug rejected',function(){s.saveProduct(ctx,data);});
 current=s.load(ctx,id);data.tag_produto='comparar';data.token=current.token;
 rejects('Reserved comparison route slug rejected',function(){s.saveProduct(ctx,data);});
 current=s.load(ctx,id);data.tag_produto='marca-vs-modelo';data.token=current.token;
 rejects('Reserved comparison delimiter slug rejected',function(){s.saveProduct(ctx,data);});
 current=s.load(ctx,id);data.tag_produto='admin-final-' & id;data.token=current.token;data.data_lancamento='2026-10-16';s.saveProduct(ctx,data);
 current=s.load(ctx,id);s.changeState(ctx,id,current.token,'publicado');
 current=s.load(ctx,id);data.token=current.token;data.tag_marca='';
 rejects('Published product cannot lose mandatory brand',function(){s.saveProduct(ctx,data);});
 transaction {
  for(table in ['tb_admin_auditoria','tb_produto_editorial','tb_genero','tb_produto_caracteristica']) queryExecute('DELETE FROM comparador.' & table & ' WHERE id_produto=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'});
  queryExecute('DELETE FROM comparador.tb_cupom WHERE id_tenis=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'});
  queryExecute('DELETE FROM comparador.tb_produto WHERE id_produto=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'});
 }
 check('Cleanup removed only owned synthetic product',!queryExecute('SELECT id_produto FROM comparador.tb_produto WHERE id_produto=:id',{id={value=id,cfsqltype="cf_sql_integer"}},{datasource='codex_comparador_test'}).recordCount);
} catch(any e) {arrayAppend(results,{name='Service execution',pass=false,error=e.message,detail=e.detail});}
failed=0;for(r in results){if(!r.pass)failed++;}writeOutput(serializeJSON({passed=arrayLen(results)-failed,failed=failed,results=results}));
</cfscript>
