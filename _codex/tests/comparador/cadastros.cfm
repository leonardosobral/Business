<cfscript>
// Executar somente no harness privado com datasource de teste. Nunca publicar este arquivo.
if(!listFind('127.0.0.1,::1',CGI.remote_addr)) {cfheader(statuscode=403);abort;}
if(queryExecute('SELECT current_database() AS name',{}, {datasource='codex_comparador_test'}).name!='comparador_codex_test') throw(message='Banco de teste obrigatório');
s=new services.ComparadorCatalogService().init('codex_comparador_test');
c={actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};count=0;
function check(ok,label){if(!ok) throw(message=label);count++;}
function fails(action,type,label){var caught=false;try{action();}catch(any e){if(e.type==type)caught=true;else rethrow;}check(caught,label);}
try {
  fails(function(){s.listRecords({actorId=99,isAdmin=false,delegated=false},'marcas');},'Comparador.Forbidden','Usuário comum recusado');
  fails(function(){s.saveRecord({actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=false},'marcas',{tag_marca='teste-catalogo',marca='Teste'});},'Comparador.Forbidden','CSRF obrigatório');
  hidden=s.saveRecord(c,'tipos',{tag_tipo_produto='teste-oculto',nome_tipo_produto='Oculto',sequencia_exibicao=''});
  check(queryExecute('SELECT sequencia_exibicao IS NULL AS hidden FROM comparador.tb_tipo_produto WHERE tag_tipo_produto=:key',{key=hidden},{datasource='codex_comparador_test'}).hidden,'Tipo sem ordem permanece oculto');
  fails(function(){s.saveRecord(c,'tipos',{tag_tipo_produto='tipo_invalido',nome_tipo_produto='Inválido',sequencia_exibicao='1'});},'Comparador.Validation','Tipo com rota inválida recusado');
  fails(function(){s.saveRecord(c,'caracteristicas',{tag_caracteristica='tag-invalida',nome_caracteristica='Inválida',tipo_caracteristica='string',un_caracteristica='',descricao_caracteristica='Fixture'});},'Comparador.Validation','Característica com alias SQL inválido recusada');
  key=s.saveRecord(c,'marcas',{tag_marca='teste-catalogo',marca='Teste'});
  item=s.loadRecord(c,'marcas',key);check(item.data.marca=='Teste','Criação legível');
  key=s.saveRecord(c,'marcas',{chave=key,token=item.token,tag_marca=key,marca='Teste alterado'});
  check(s.loadRecord(c,'marcas',key).data.marca=='Teste alterado','Edição persistida');
  fails(function(){s.saveRecord(c,'marcas',{chave=key,token=item.token,tag_marca=key,marca='Sobrescrita'});},'Comparador.Conflict','Edição antiga recusada');
  item=s.loadRecord(c,'marcas',key);
  queryExecute("INSERT INTO comparador.tb_produto(id_produto,nome_produto,tag_marca,tag_tipo_produto) VALUES(909901,'Teste cadastro',:brand,'tenis')",{brand=key},{datasource='codex_comparador_test'});
  fails(function(){s.deleteRecord(c,'marcas',key,item.token);},'Comparador.Validation','Marca em uso preservada');
  fails(function(){s.saveRecord(c,'filtros',{tag_filtro='teste-filtro',tag_tipo_produto='tenis',campo='sql_injetado',rotulo='Teste',sequencia_exibicao='1',ativo='true'});},'Comparador.Validation','Campo de filtro fora do contrato recusado');
  fk=s.saveRecord(c,'filtros',{tag_filtro='teste-filtro',tag_tipo_produto='tenis',campo='peso',rotulo='Peso',sequencia_exibicao='1',ativo='true'});
  fails(function(){s.saveRecord(c,'opcoes',{tag_opcao='teste-opcao',tag_filtro=fk,valor='LT999',rotulo='Inválido',sequencia_exibicao='1'});},'Comparador.Validation','Faixa não suportada recusada');
  ok=s.saveRecord(c,'opcoes',{tag_opcao='teste-opcao',tag_filtro=fk,valor='LT250',rotulo='Até 250 g',sequencia_exibicao='1'});
  fails(function(){s.deleteRecord(c,'filtros',fk,s.loadRecord(c,'filtros',fk).token);},'Comparador.Validation','Filtro com opções preservado');
  s.deleteRecord(c,'opcoes',ok,s.loadRecord(c,'opcoes',ok).token);
  s.deleteRecord(c,'filtros',fk,s.loadRecord(c,'filtros',fk).token);
  check(queryExecute("SELECT count(*) AS n FROM comparador.tb_cadastro_auditoria WHERE chave='teste-filtro'",{},{datasource='codex_comparador_test'}).n==2,'Criação e exclusão auditadas');
} finally {
 // CF rolls back an enclosing transaction when a nested transaction throws.
 // Run service calls independently and remove only these owned synthetic records.
 transaction {
  queryExecute("DELETE FROM comparador.tb_produto WHERE id_produto=909901 AND tag_marca='teste-catalogo'",{},{datasource='codex_comparador_test'});
  queryExecute("DELETE FROM comparador.tb_filtro_opcao WHERE tag_opcao='teste-opcao'",{},{datasource='codex_comparador_test'});
  queryExecute("DELETE FROM comparador.tb_filtro WHERE tag_filtro='teste-filtro'",{},{datasource='codex_comparador_test'});
  queryExecute("DELETE FROM comparador.tb_marca WHERE tag_marca='teste-catalogo'",{},{datasource='codex_comparador_test'});
  queryExecute("DELETE FROM comparador.tb_tipo_produto WHERE tag_tipo_produto='teste-oculto'",{},{datasource='codex_comparador_test'});
  queryExecute("DELETE FROM comparador.tb_cadastro_auditoria WHERE ator_id=99 AND chave IN ('teste-catalogo','teste-oculto','teste-filtro','teste-opcao')",{},{datasource='codex_comparador_test'});
 }
}
writeOutput(serializeJSON({passed=count}));
</cfscript>
