<cfscript>
// Harness privado; recusa qualquer banco ou origem fora dos testes.
if(!listFind('127.0.0.1,::1',CGI.remote_addr)) {cfheader(statuscode=403);abort;}
if(queryExecute('SELECT current_database() AS name',{}, {datasource='codex_comparador_test'}).name!='comparador_codex_test') throw(message='Banco de teste obrigatório');
s=new services.ComparadorAdminService().init('codex_comparador_test');c={actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};count=0;
function check(ok,label){if(!ok)throw(message=label);count++;}
transaction {
 try {
  data={loja='Loja sintética',link='https://example.com/oferta',preco_promocional='99.90',cupom='',condicoes='Fixture',data_expiracao='2099-01-01'};
  s.addOffer(c,900001,s.load(c,900001).token,data);
  first=s.load(c,900001).offers.id_cupom;
  s.addOffer(c,900001,s.load(c,900001).token,data);
  latest=s.load(c,900001).offers.id_cupom;
  old=s.loadOffer(c,latest);data.preco_promocional='89,90';
  s.updateOffer(c,latest,old.token,data);
  check(s.loadOffer(c,latest).offer.preco_promocional==89.9,'Edição grava preço decimal');
  s.updateOffer(c,latest,s.loadOffer(c,latest).token,{},true);
  detail=s.load(c,900001);
  check(detail.offers.id_cupom==latest AND detail.offers.expired,'Encerramento preserva ID mais recente e vence oferta');
  check(queryExecute('SELECT count(*) AS n FROM comparador.tb_cupom WHERE id_cupom=:id',{id={value=first,cfsqltype='cf_sql_integer'}},{datasource='codex_comparador_test'}).n==1,'Oferta anterior permanece');
  check(s.listOffers(c,'Loja sintética','vencidas').total>=1,'Lista encontra oferta encerrada');
  check(queryExecute("SELECT count(*) AS n FROM comparador.tb_admin_auditoria WHERE id_produto=900001 AND acao='oferta_encerrar'",{},{datasource='codex_comparador_test'}).n>=1,'Encerramento auditado');
  conflict=false;try{s.updateOffer(c,latest,old.token,data);}catch(Comparador.Conflict e){conflict=true;}
  check(conflict,'Edição concorrente recusada');
  transaction action='rollback';
 }catch(any e){transaction action='rollback';rethrow;}
}
writeOutput(serializeJSON({passed=count}));
</cfscript>
