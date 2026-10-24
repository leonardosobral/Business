<cfscript>
cfsetting(showdebugoutput=false,requesttimeout=180);
service=new services.ComparadorAwinFeedService();checks=[];
function check(required boolean condition,required string label){if(!condition)throw(message=label);arrayAppend(checks,label);}
feed={merchantId='17806',feedId='91869',shop='Centauro BR',checkedMs=createObject('java','java.lang.System').currentTimeMillis()};
row={product_name='Tênis Unissex Olympikus Corre 4',brand_name='Olympikus',merchant_id='17806',data_feed_id='91869',currency='BRL',search_price='599.99',in_stock='1',stock_status='',is_for_sale='',pre_order='',condition='new',aw_product_id='123',aw_deep_link='https://www.awin1.com/pclick.php?p=123&a=1455398&m=17806',valid_from='',valid_to='10',base_price='399.99 BRL'};
for(n=1;n<=10;n++){row.valid_to=n & '';check(!len(service.invalidRow(row,feed)),'Anomalia Centauro conhecida: ' & n);}
for(value in ['0','11','99','2026','1.0','01','NaN','amanhã','2026-02-30','2020-01-01','2020-01-01 00:00:00','2020-01-01T00:00:00Z']){bad=duplicate(row);bad.valid_to=value;check(service.invalidRow(bad,feed)=='validade','Vencimento não permitido: ' & value);}
for(test in [{key='valid_from',value='10',reason='validade'},{key='valid_from',value='2099-01-01',reason='validade'},{key='valid_from',value='2099-01-01 00:00:00',reason='validade'},{key='valid_from',value='2026-02-30T00:00:00',reason='validade'},{key='search_price',value='0',reason='preco'},{key='currency',value='USD',reason='preco'},{key='in_stock',value='0',reason='estoque'},{key='pre_order',value='1',reason='estoque'},{key='condition',value='used',reason='condicao'},{key='merchant_id',value='17698',reason='identidade'},{key='data_feed_id',value='999',reason='identidade'},{key='aw_deep_link',value='https://example.com/',reason='link'}]){bad=duplicate(row);bad[test.key]=test.value;check(service.invalidRow(bad,feed)==test.reason,'Centauro mantém proteção: ' & test.key);}
otherFeed=duplicate(feed);otherFeed.feedId='999';bad=duplicate(row);bad.data_feed_id='999';check(service.invalidRow(bad,otherFeed)=='validade','Outro feed Centauro não recebe exceção');
otherFeed=duplicate(feed);otherFeed.merchantId='999';bad=duplicate(row);bad.merchant_id='999';check(service.invalidRow(bad,otherFeed)=='validade','Outro anunciante não recebe exceção');
for(value in ['2099-12-31','2099-12-31T23:59:59','2099-12-31 23:59:59','2099-12-31T23:59:59-03:00','2099-12-31T23:59:59Z']){bad=duplicate(row);bad.valid_to=value;check(!len(service.invalidRow(bad,feed)),'Formato Awin aceito: ' & value);}
check(service.offerDateEpoch('2026-10-17','valid_from')==service.offerDateEpoch('2026-10-17T03:00:00Z','valid_from'),'Data inicial no fuso de Brasília');
check(service.offerDateEpoch('2026-10-17','valid_to')==service.offerDateEpoch('2026-10-18T03:00:00Z','valid_to'),'Data final inclui todo o dia em Brasília');
check(service.offerDateEpoch('2026-10-17 23:59:59','valid_to')==service.offerDateEpoch('2026-10-18T02:59:59Z','valid_to'),'Horário local interpretado em Brasília');
products=[{id=1,name='Corre',version='4',brand='olympikus',brandName='Olympikus',slug='olympikus-corre-4',type='tenis',label='Olympikus Corre 4'}];
columns='aw_deep_link,product_name,aw_product_id,merchant_product_id,merchant_name,merchant_id,search_price,currency,store_price,merchant_deep_link,last_updated,data_feed_id,brand_name,in_stock,stock_status,is_for_sale,pre_order,condition,valid_from,valid_to,product_type,merchant_category,colour,base_price,product_price_old';
function makeCsv(required struct row){var values=[];for(var col in listToArray(columns))arrayAppend(values,'"' & replace(structKeyExists(row,col)?row[col]:'','"','""','all') & '"');return columns & chr(10) & arrayToList(values,',');}
imported=service.importCsv(makeCsv(row),feed,products);check(arrayLen(imported.offers)==1 AND imported.matched==1,'Centauro gera oferta com preço do feed');
check(imported.warnings.centauro_expiry_unavailable==1,'Anomalia auditável sem tratar como vencimento');
check(service.offerDateEpoch(imported.offers[1].expiresAt,'valid_to')<=feed.checkedMs+86400000,'Prazo limitado à atualização da origem');
check(imported.offers[1].price==399.99 AND imported.offers[1].priceType=='cash' AND imported.offers[1].priceSource=='base_price','Preço à vista explícito do feed, sem calcular desconto');
soon=createObject('java','java.time.Instant').now().plusSeconds(3600).toString();bad=duplicate(row);bad.valid_to=soon;imported=service.importCsv(makeCsv(bad),feed,products);check(imported.offers[1].expiresAt==soon AND !structCount(imported.warnings),'Vencimento real Centauro continua limitando a oferta');
bad=duplicate(row);bad.valid_to='2020-01-01';imported=service.importCsv(makeCsv(bad),feed,products);check(!arrayLen(imported.offers) AND imported.rejected.validade==1,'Oferta Centauro vencida não é publicada');
for(value in ['','0 BRL','-1 BRL','1,99 BRL','399.99 USD','9999999 BRL','4e2 BRL','NaN BRL','699.99 BRL']){bad=duplicate(row);bad.base_price=value;check(service.invalidRow(bad,feed)=='preco','Rejeita preço Centauro: ' & value);}
bad=duplicate(row);bad.valid_to='1';check(service.priceValue(bad,feed)=='399.99','Número em validade não altera preço');
bad=duplicate(row);bad.base_price='599.99 BRL';check(!len(service.invalidRow(bad,feed)),'Preço à vista igual ao original permitido');
otherFeed={merchantId='51271',feedId='85451'};check(service.priceValue(row,otherFeed)=='599.99','Outros feeds continuam usando search_price');
cfcontent(type='application/json');writeOutput(serializeJSON({passed=arrayLen(checks),checks=checks}));
</cfscript>
