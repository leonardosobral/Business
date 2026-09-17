<cfapplication name="coupon_offline_fixture" sessionmanagement="true"/>
<cfscript>
function check(required boolean value,required string message){if(!value)throw(message=message);}
svc=createObject('component','cupons-rr.includes.CouponService');svc.fixtureReset();
admin=svc.scope(true);owned=svc.scope(false,'123','123','0');reader=svc.scope(false,'123','0','0');
input={cupom='CORRIDA10',parceiro='Organizador',descricao='Detalhes',condicoes='10% de desconto',url='https://example.invalid/inscricoes',data_expiracao='2026-12-31',ativo='true',inicio='2026-09-16',fim='2026-12-30',quantidade='100',id_evento='123',id_cupom='77',revision='42'};
check(svc.id('1 OR 1=1') EQ 0 AND svc.id('-1') EQ 0 AND svc.id('9999999999') EQ 0,'IDs bounded');
check(svc.validate(input,true).quantidade EQ '100','Valid coupon');
for (change in [{cupom=''},{cupom=repeatString('x',33)},{cupom='COM ESPACO'},{parceiro=''},{condicoes=''},{url='javascript:alert(1)'},{url='https://user:pass@example.invalid'},{data_expiracao='2026-99-99'},{inicio='2026-12-31',fim='2026-01-01'},{fim='2027-01-01'},{quantidade='-1'},{quantidade='2.5'},{id_evento='0'}]) {
  invalid=duplicate(input);structAppend(invalid,change,true);rejected=false;
  try{svc.validate(invalid,true);}catch(Coupon.Validation e){rejected=true;}
  check(rejected,'Invalid coupon accepted: ' & serializeJSON(change));
}
svc.fixtureReset('owned');check(svc.canEdit(77,owned),'Owned event coupon can edit');
svc.fixtureReset('shared');check(!svc.canEdit(77,owned),'Shared coupon is read-only');
calls=svc.fixtureCalls();check(find('id_evento NOT IN (:operate)',calls[1].sql) AND find('tb_paginas_cupom',calls[1].sql) AND find('tb_evento_circuitos_cupom',calls[1].sql),'All associations protect ownership');
svc.fixtureReset();results=svc.listing(reader,{busca="50%_! O'Reilly",pagina=99999,status='ativos'});
calls=svc.fixtureCalls();check(results.page EQ 1 AND results.total EQ 2,'Clamp pagination');
check(calls[2].params.search.value EQ "%50!%!_!! O'Reilly%",'Literal search');
check(!find("O'Reilly",calls[2].sql) AND find('e.id_evento IN (:visible)',calls[2].sql),'Search is parameterized and event names scoped');
svc.fixtureReset();check(svc.save('criar',input,admin) EQ 77,'Create result');calls=svc.fixtureCalls();
check(find('INSERT INTO tb_cupom',calls[4].sql) GT 0 AND find('INSERT INTO tb_evento_corridas_cupom',calls[6].sql) GT 0 AND calls[6].params.id.value EQ 77,'Create coupon and link together');
svc.fixtureReset();svc.save('editar',input,admin);calls=svc.fixtureCalls();check(find('FOR UPDATE',calls[1].sql) GT 0,'Lock before edit');
for(action in ['status','vincular']) {svc.fixtureReset();svc.save(action,input,admin);check(arrayLen(svc.fixtureCalls()) GT 1,'Action executed');}
svc.fixtureReset('no-event');rejected=false;try{svc.save('criar',input,owned);}catch(Coupon.Forbidden e){rejected=true;}check(rejected,'Unauthorized event denied');
svc.fixtureReset('shared');rejected=false;try{svc.save('editar',input,owned);}catch(Coupon.Forbidden e){rejected=true;}check(rejected,'Shared edits denied');
svc.fixtureReset();stale=duplicate(input);stale.revision='41';rejected=false;try{svc.save('editar',stale,admin);}catch(Coupon.Conflict e){rejected=true;}check(rejected AND arrayLen(svc.fixtureCalls()) EQ 1,'Stale form does not write');
svc.fixtureReset('duplicate');rejected=false;try{svc.save('criar',input,admin);}catch(Coupon.Validation e){rejected=true;}check(rejected,'Duplicate code denied');
svc.fixtureReset();cpService=svc;cpAccess=admin;cpData=svc.listing(admin,{});cpCoupon=svc.get(77,admin);cpValues=queryGetRow(cpCoupon,1);cpValues.data_expiracao='2026-12-31';
cpLinks=queryNew('id_evento_cupom,id_evento,nome_evento,tag,data_validade_inicio,data_validade_fim,qtd_limite_cupom','integer,integer,varchar,varchar,date,date,integer',[[1,123,'Corrida de teste','teste',createDate(2026,9,16),createDate(2026,12,30),100]]);
cpOthers=queryNew('tipo,nome','varchar,varchar',[['Circuito','Circuito de teste']]);
cpSelected=77;cpNew=false;cpCanEdit=true;cpConflict=false;cpError='';cuponsRrCanOperate=true;cpTestCsrf='synthetic-token';
function cpDate(any value=''){return isDate(value)?dateFormat(value,'dd/mm/yyyy'):'Sem prazo';}
function cpListUrl(numeric page=1){return './?pagina=' & page;}
</cfscript>
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"/><link rel="stylesheet" href="/assets/css/mdb.min.css"/></head><body data-mdb-theme="dark" style="background:#151b24;padding:20px"><p>Prévia local · dados fictícios</p><cfinclude template="/cupons-rr/home.cfm"/>
<!--CP-NEW--><cfset cpNew=true/><cfset cpCoupon=queryNew('id_cupom')/><cfset cpSelected=0/><cfinclude template="/cupons-rr/home.cfm"/></body></html>
