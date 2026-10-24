<cfsetting showdebugoutput="false" requesttimeout="60"><cfcontent type="application/json; charset=utf-8">
<cfscript>
if(!listFind('127.0.0.1,::1',CGI.remote_addr)) {cfheader(statuscode=403);abort;}
</cfscript><cftry><cfscript>
if(queryExecute('SELECT current_database() AS name',{}, {datasource='codex_comparador_test'}).name!='comparador_codex_test') throw(message='Banco de teste obrigatório');
s=new ComparadorAdminService().init('codex_comparador_test');c={actorId=99,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};results=[];
data={loja='Loja WA sintética',link='https://example.com/oferta-wa',preco_promocional='99.90',cupom='',condicoes='Fixture',data_expiracao='2099-01-01'};
function rejects(run,kind='Comparador.Validation'){try{run();return false;}catch(any e){return e.type==kind;}}
function runCase(name,run,withSource=true){
 transaction {
  try {
   s.addOffer(c,900001,s.load(c,900001).token,data);
   offerId=s.load(c,900001).offers.id_cupom;
   if(withSource){
  queryExecute("INSERT INTO comparador.tb_wa_sincronizacao(id_sync,consultado_em,ator_id,fonte_url,hash_snapshot,total_origem,payload) VALUES('11111111-1111-4111-8111-111111111111',now(),99,'https://certcheck.worldathletics.org/FullList','fixture',1,'{}')",{},{datasource='codex_comparador_test'});
  queryExecute("INSERT INTO comparador.tb_wa_registro(id_wa,id_produto,chave_produto,marca,modelo,aprovado_pista,aprovado_salto,aprovado_dardo,aprovado_rua,prototipo,validade,modelo_numero,foto_url,restricoes,raw,hash_origem,primeiro_visto,ultimo_visto,ultima_alteracao,ultimo_sync) VALUES('22222222-2222-4222-8222-222222222222',900001,'wa-fixture','Sintética','Protótipo WA',false,false,false,true,true,'2099-01-01','WA-TEST-42','https://certcheck.worldathletics.org/OpenDocument/33333333-3333-4333-8333-333333333333','Restrição <segura>','{}','fixture',now(),now(),now(),'11111111-1111-4111-8111-111111111111')",{},{datasource='codex_comparador_test'});

   }
   current=s.load(c,900001);
   arrayAppend(results,{name=name,pass=run()});
   transaction action='rollback';
  }catch(any e){transaction action='rollback';arrayAppend(results,{name=name,pass=false,error=e.message,detail=e.detail});}
 }
}
runCase('Sem fonte continua não verificado',function(){return current.product.wa_status=='nao_verificado' AND !current.product.wa_compra_bloqueada;},false);
runCase('WA carrega foto e código',function(){return current.product.wa_status=='aprovado_restricoes' AND current.product.wa_prototipo AND current.product.wa_compra_bloqueada AND current.product.wa_modelo_numero=='WA-TEST-42' AND find('/OpenDocument/',current.product.wa_foto_url)>0;});
runCase('Oferta carrega bloqueio',function(){return s.loadOffer(c,offerId).offer.wa_compra_bloqueada;});
runCase('Protótipo não recebe oferta',function(){return rejects(function(){s.addOffer(c,900001,current.token,data);});});
runCase('Protótipo não permite editar oferta',function(){return rejects(function(){s.updateOffer(c,offerId,current.token,data);});});
runCase('CSRF segue obrigatório',function(){return rejects(function(){var denied=duplicate(c);denied.csrfVerified=false;s.updateOffer(denied,offerId,current.token,{},true);},'Comparador.Forbidden');});
runCase('Delegação segue bloqueada',function(){return rejects(function(){var denied=duplicate(c);denied.delegated=true;s.addOffer(denied,900001,current.token,data);},'Comparador.Forbidden');});
runCase('Token antigo segue bloqueado',function(){return rejects(function(){s.updateOffer(c,offerId,repeatString('0',64),{},true);},'Comparador.Conflict');});
runCase('Protótipo permite encerrar e auditar',function(){s.updateOffer(c,offerId,current.token,{},true);return s.loadOffer(c,offerId).offer.data_expiracao<now() AND s.load(c,900001).history.acao=='oferta_encerrar';});
runCase('Modelo comercial permite editar oferta',function(){queryExecute("UPDATE comparador.tb_wa_registro SET prototipo=false,validade=NULL WHERE id_produto=900001",{},{datasource='codex_comparador_test'});s.updateOffer(c,offerId,s.load(c,900001).token,data);return s.loadOffer(c,offerId).offer.preco_promocional==99.9;});
failed=0;for(r in results)if(!r.pass)failed++;
writeOutput(serializeJSON({passed=arrayLen(results)-failed,failed=failed,results=results}));
</cfscript><cfcatch type="any"><cfoutput>#serializeJSON({failed=1,error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>
