<cfif NOT listFind('127.0.0.1,::1',CGI.remote_addr)><cfheader statuscode="404"><cfabort></cfif>
<cfscript>
cfsetting(showdebugoutput=false,requesttimeout=120);
service=new services.ComparadorAwinFeedService();source=new services.ComparadorAwinService();checks=[];
function check(required boolean value,required string message){if(!value)throw(type='Variant.TestFailure',message=message);arrayAppend(checks,message);}
cases=[
 {row={suitable_for='Masculino',product_name='Tênis Nike Modelo 1 Masculino'},gender='M',source='suitable_for'},
 {row={suitable_for='feminino',product_name='Tênis Nike Modelo 1'},gender='F',source='suitable_for'},
 {row={suitable_for='unissex',product_name='Tênis Modelo 1',product_type='Masculino - Calçados - Corrida'},gender='U',source='suitable_for'},
 {row={suitable_for='',product_name='Tênis ASICS Modelo 1 Feminino'},gender='F',source='product_name'},
 {row={suitable_for='',product_name='Tênis ASICS Modelo 1 Masculino'},gender='M',source='product_name'},
 {row={suitable_for='',product_name='Tênis ASICS Modelo 1 Unissex'},gender='U',source='product_name'},
 {row={suitable_for='',product_name='Tênis ASICS Modelo 1 40 Azul'},gender='',source='unknown'},
 {row={suitable_for='',product_name='Tênis ASICS Modelo 1',product_type='Masculino'},gender='',source='unknown'},
 {row={suitable_for='Marketplace',product_name='Tênis Modelo 1 Feminino'},gender='',source='unknown'},
 {row={suitable_for='feminino',product_name='Tênis Modelo 1 Masculino'},gender='',source='conflict'},
 {row={suitable_for='unissex',product_name='Tênis Modelo 1 Feminino'},gender='',source='conflict'},
 {row={suitable_for='masculino',product_name='Tênis Modelo 1 Masculino Feminino'},gender='',source='conflict'},
 {row={suitable_for='',product_name='Tênis Modelo 1 Unissex Feminino'},gender='',source='conflict'},
 {row={suitable_for='infantil',product_name='Tênis Modelo 1'},gender='',source='unknown'}
];
for(item in cases){g=service.offerGender(item.row);check(g.gender==item.gender,'Gênero: ' & serializeJSON(item.row));check(g.genderSource==item.source,'Fonte explícita ou desconhecida: ' & item.source);}
for(fixtureUrl in ['https://imgnike-a.akamaihd.net/1500x1500/abc.jpg','https://imgcentauro-a.akamaihd.net/600x600/abc.jpg','https://asicsbr.vteximg.com.br/arquivos/ids/123/a.jpg?v=639208402981230000','https://mizunobr.vteximg.com.br/arquivos/ids/123_2','https://vulcabras.vteximg.com.br/arquivos/ids/123_2','https://samsungbrshop.vteximg.com.br/arquivos/ids/123.jpg'])check(service.offerImage(fixtureUrl)==fixtureUrl,'Imagem direta do CDN auditado aceita');
for(fixtureUrl in ['http://imgnike-a.akamaihd.net/a.jpg','https://user:password@imgnike-a.akamaihd.net/a.jpg','https://127.0.0.1/a.jpg','https://imgnike-a.akamaihd.net:443/a.jpg','https://imgnike-a.akamaihd.net/a.jpg##fragment','https://imgnike-a.akamaihd.net/a.jpg?token=secret','https://imgnike-a.akamaihd.net.evil.test/a.jpg','https://images2.productserve.com/?url=abc&k=signature','javascript:alert(1)','https://imgnike-a.akamaihd.net/a.jpg?v=1&token=secret','https://imgnike-a.akamaihd.net/a.jpg?v=abc','https://imgnike-a.akamaihd.net/a.jpg' & chr(10)])check(service.offerImage(fixtureUrl)=='','Imagem insegura/fora do contrato rejeitada');
logo='https://ui.awin.com/images/upload/merchant/profile/17652.png';
check(source.programmeLogo(logo,'17652')==logo,'Logo oficial fornecido pela API');
for(fixtureUrl in ['https://ui.awin.com/images/upload/merchant/profile/99999.png',logo & '?token=secret','http://ui.awin.com/images/upload/merchant/profile/17652.png','https://ui.awin.com.evil.test/images/upload/merchant/profile/17652.png'])check(source.programmeLogo(fixtureUrl,'17652')=='','Logo deve corresponder ao anunciante e caminho público');
feed={merchantId='17652',feedId='44669',shop='Nike BR',shopLogo=logo,checkedMs=createObject('java','java.lang.System').currentTimeMillis()};
product={id=909001,name='Modelo CTA',version='1',slug='modelo-cta-1',brand='nike',brandName='Nike',type='tenis',label='Nike Modelo CTA 1'};
columns='aw_deep_link,product_name,aw_product_id,merchant_product_id,merchant_name,merchant_id,search_price,currency,store_price,merchant_deep_link,last_updated,data_feed_id,brand_name,in_stock,stock_status,is_for_sale,pre_order,condition,valid_from,valid_to,product_type,merchant_category,colour,base_price,product_price_old,suitable_for,merchant_image_url,aw_image_url,aw_thumb_url,size';
function row(required string sku,required numeric price,required string gender,required string color,required string image,required string title){return {aw_deep_link='https://www.awin1.com/pclick.php?p=' & sku & '&a=1455398&m=17652',product_name=title,aw_product_id=sku,merchant_product_id='sku-' & sku,merchant_name='Nike BR',merchant_id='17652',search_price=price & '',currency='BRL',data_feed_id='44669',brand_name='Nike',in_stock='1',condition='new',colour=color,suitable_for=gender,merchant_image_url=image};}
function csvText(required array rows,required string columns){var text=columns & chr(10);for(var row in rows){var values=[];for(var column in listToArray(columns))arrayAppend(values,'"' & replace(structKeyExists(row,column)?row[column] & '':'','"','""','all') & '"');text&=arrayToList(values,',') & chr(10);}return text;}
rows=[row('1001',200,'Feminino','Branco','https://imgnike-a.akamaihd.net/f-white.jpg','Tênis Nike Modelo CTA 1 Feminino Branco'),row('1002',150,'Feminino','Branco','https://imgnike-a.akamaihd.net/f-white.jpg','Tênis Nike Modelo CTA 1 Feminino Branco'),row('1003',170,'Feminino','Preto','https://imgnike-a.akamaihd.net/f-black.jpg','Tênis Nike Modelo CTA 1 Feminino Preto'),row('1004',230,'Masculino','Branco','https://imgnike-a.akamaihd.net/m-white.jpg','Tênis Nike Modelo CTA 1 Masculino Branco'),row('1005',190,'Unissex','Branco','https://imgnike-a.akamaihd.net/u-white.jpg','Tênis Nike Modelo CTA 1 Unissex Branco'),row('1006',210,'','Azul','https://imgnike-a.akamaihd.net/unknown.jpg','Tênis Nike Modelo CTA 1 Azul')];
result=service.importCsv(csvText(rows,columns),feed,[product]);check(arrayLen(result.offers)==1,'Um vínculo administrativo por produto/loja');parent=result.offers[1];
check(parent.key=='17652:909001','Chave de bloqueio preservada');check(parent.price==150 AND parent.awinProductId=='1002','Mínimo global preservado');check(parent.variants==6,'Contagem numérica de registros preservada');check(parent.gender=='F' AND parent.imageUrl=='https://imgnike-a.akamaihd.net/f-white.jpg','Metadados do mínimo pertencem ao mesmo SKU');
check(arrayLen(parent.variantOffers)==5,'Retém gêneros/cores/imagens distintas, agrupando tamanho');
for(child in parent.variantOffers){check(!structKeyExists(child,'variantOffers'),'Filhos sem recursão');check(child.key==parent.key AND child.productId==parent.productId AND child.merchantId==parent.merchantId,'Identidade e bloqueio iguais ao pai');check(child.shopLogo==logo,'Logo oficial propagado');check(child.priceType=='cash' AND child.priceSource=='search_price','Política de preço anterior preservada');}
check(parent.variantOffers[1].awinProductId=='1002' AND parent.variantOffers[1].variants==2,'Menor SKU exato representa a cor/gênero');
check(parent.variantOffers[2].awinProductId=='1003' AND parent.variantOffers[2].color=='Preto','Outra cor mantém sua própria foto e preço');
meta=service.offerMetadata({suitable_for='feminino',product_name='Tênis',colour='',merchant_image_url='javascript:alert(1)'},feed);check(meta.color=='' AND meta.imageUrl=='','Ausência de cor/foto não inventa metadados');
cfcontent(type='application/json');writeOutput(serializeJSON({passed=arrayLen(checks),parentOffers=arrayLen(result.offers),variantOffers=arrayLen(parent.variantOffers),checks=checks}));
</cfscript>
