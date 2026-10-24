<cfscript>
// Private proposal test only. Requires an isolated harness mapping /services to the proposal.
// Never invokes synchronize(), uses credentials, or writes publication data.
cfsetting(showdebugoutput=false,requesttimeout=180);
service=new services.ComparadorAwinFeedService();checks=[];
function check(required boolean condition,required string label){if(!condition)throw(message=label);arrayAppend(checks,label);}
function exampleRow(required string merchant,required string fid){
    return {product_name='Tênis Unissex Olympikus Corre 4',brand_name='Olympikus',merchant_id=merchant,data_feed_id=fid,currency='BRL',search_price='599.99',in_stock='1',stock_status='',is_for_sale='',pre_order='',condition='new',aw_product_id='123',aw_deep_link='https://www.awin1.com/pclick.php?p=123&a=1455398&m=' & merchant,valid_from='',valid_to='',base_price='399.99 BRL',product_price_old='349.99 BRL',base_price_amount='39.99 BRL',store_price='1.00'};
}
columns='aw_deep_link,product_name,aw_product_id,merchant_product_id,merchant_name,merchant_id,search_price,currency,store_price,merchant_deep_link,last_updated,data_feed_id,brand_name,in_stock,stock_status,is_for_sale,pre_order,condition,valid_from,valid_to,product_type,merchant_category,colour,base_price,product_price_old';
function makeCsv(required struct row){var values=[];for(var col in listToArray(columns))arrayAppend(values,'"' & replace(structKeyExists(row,col)?row[col]:'','"','""','all') & '"');return columns & chr(10) & arrayToList(values,',');}
products=[{id=1,name='Corre',version='4',brand='olympikus',brandName='Olympikus',slug='olympikus-corre-4',type='tenis',label='Olympikus Corre 4'}];
nowMs=createObject('java','java.lang.System').currentTimeMillis();
cases=[
    {merchantId='17652',feedId='93360',shop='Nike BR',source='base_price',type='cash',value='1263.49 BRL',original='2499.99',expected=1263.49},
    {merchantId='23659',feedId='116576',shop='ASICS BR',source='product_price_old',type='standard',value='1119.99 BRL',original='1599.99',expected=1119.99},
    {merchantId='17698',feedId='51837',shop='Olympikus BR',source='base_price',type='standard',value='installament months: R$ 449,99',original='599.99',expected=449.99},
    {merchantId='17806',feedId='91869',shop='Centauro BR',source='base_price',type='cash',value='399.99 BRL',original='599.99',expected=399.99},
    {merchantId='51271',feedId='85451',shop='Mizuno BR',source='search_price',type='standard',value='599.99',original='599.99',expected=599.99},
    {merchantId='25539',feedId='114866',shop='Samsung BR',source='search_price',type='standard',value='160.55',original='160.55',expected=160.55},
    {merchantId='17652',feedId='44669',shop='Nike BR atual',source='search_price',type='cash',value='581.39',original='581.39',expected=581.39}
];
for(test in cases){
    feed=duplicate(test);feed.checkedMs=nowMs;
    row=exampleRow(test.merchantId,test.feedId);row.search_price=test.original;row[test.source]=test.value;
    check(val(service.priceValue(row,feed))==test.expected,test.shop & ': campo de total correto');
    check(!len(service.invalidRow(row,feed)),test.shop & ': linha de preço elegível');
    imported=service.importCsv(makeCsv(row),feed,products);
    check(arrayLen(imported.offers)==1 AND imported.offers[1].price==test.expected,test.shop & ': valor publicado');
    check(imported.offers[1].priceSource==test.source AND imported.offers[1].priceType==test.type,test.shop & ': origem e condição de pagamento');
    bad=duplicate(row);bad.base_price_amount='0.01 BRL';bad.store_price='0.01';
    check(val(service.priceValue(bad,feed))==test.expected,test.shop & ': ignora parcela e preço de loja física');
    bad=duplicate(row);bad.merchant_id='999';check(service.invalidRow(bad,feed)=='identidade',test.shop & ': identidade da linha');
    bad=duplicate(row);bad.in_stock='0';check(service.invalidRow(bad,feed)=='estoque',test.shop & ': estoque');
    bad=duplicate(row);bad.valid_to='2020-01-01';check(service.invalidRow(bad,feed)=='validade',test.shop & ': vencimento real');
    if(test.source!='search_price'){
        bad=duplicate(row);bad[test.source]='';check(service.invalidRow(bad,feed)=='preco',test.shop & ': sem fallback para original quando total ausente');
        bad=duplicate(row);bad.search_price='1.00';check(service.invalidRow(bad,feed)=='preco',test.shop & ': total acima do original rejeitado');
        bad=duplicate(row);bad.search_price='invalid';check(service.invalidRow(bad,feed)=='preco',test.shop & ': original inválido rejeitado');
        other=duplicate(feed);other.feedId='999';bad=duplicate(row);bad.data_feed_id='999';
        check(service.priceValue(bad,other)==test.original,test.shop & ': adaptação não vaza para outro feed');
        other=duplicate(feed);other.merchantId='999';bad=duplicate(row);bad.merchant_id='999';
        check(service.priceValue(bad,other)==test.original,test.shop & ': adaptação não vaza para outro anunciante');
    }
}
for(test in [cases[1],cases[2],cases[4]]){
    feed=duplicate(test);feed.checkedMs=nowMs;row=exampleRow(test.merchantId,test.feedId);
    for(value in ['','0 BRL','-1 BRL','1,99 BRL','1.999,99 BRL','399.99 USD','9999999 BRL','4e2 BRL','NaN BRL','699.99 BRL','399.99','R$ 399,99']){
        bad=duplicate(row);bad[test.source]=value;
        check(service.invalidRow(bad,feed)=='preco',test.shop & ': rejeita total malformado/contraditório ' & value);
    }
    row[test.source]='599.99 BRL';check(!len(service.invalidRow(row,feed)),test.shop & ': total igual ao original permitido');
    row[test.source]='349.0 BRL';check(val(service.priceValue(row,feed))==349,test.shop & ': decimal de uma casa observado na origem');
}
feed={merchantId='17698',feedId='51837',shop='Olympikus BR',checkedMs=nowMs};row=exampleRow(feed.merchantId,feed.feedId);
for(value in ['installament months: R$ 0,00','installament months: R$ -1,99','installament months: R$ 449.99','installament months: R$ 44,999','installament months: R$ 1,299.99','installament months: R$ 01.299,99','installament months: R$ 1.29,99','installament months: R$ 9999999,99','installment months: R$ 449,99','Installament months: R$ 449,99','installament months: 449,99 BRL','R$ 449,99','449.99 BRL','installament months: R$ 699,99']){
    bad=duplicate(row);bad.base_price=value;check(service.invalidRow(bad,feed)=='preco','Olympikus rejeita formato/valor contraditório: ' & value);
}
row.search_price='1599.99';row.base_price='installament months: R$ 1.299,99';check(service.priceValue(row,feed)=='1299.99','Olympikus: separador de milhar pt_BR');
row.base_price='installament months: R$ 599,99';row.search_price='599.99';check(!len(service.invalidRow(row,feed)),'Olympikus: total igual ao original');
row.valid_to='10';check(service.invalidRow(row,feed)=='validade','Exceção de parcelas na validade continua exclusiva da Centauro');
for(feed in [{merchantId='17652',feedId='44670',shop='Nike desconhecido',checkedMs=nowMs},{merchantId='999',feedId='44669',shop='Outro anunciante',checkedMs=nowMs}]){
 row=exampleRow(feed.merchantId,feed.feedId);imported=service.importCsv(makeCsv(row),feed,products);
 check(imported.offers[1].price==599.99,'Feed Nike novo não abre regra de preço para outro par de IDs');
 check(imported.offers[1].priceSource=='search_price' AND imported.offers[1].priceType=='standard','Condição Pix não vaza para feed/anunciante não auditado');
}
cfcontent(type='application/json');writeOutput(serializeJSON({passed=arrayLen(checks),checks=checks}));
</cfscript>
