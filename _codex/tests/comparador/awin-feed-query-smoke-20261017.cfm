<cfscript>
cfsetting(showdebugoutput=false);checks=[];function check(required boolean condition,required string label){if(!condition)throw(message=label);arrayAppend(checks,label);}
REQUEST.awinFeedReader=new publicservices.AwinFeedReader();REQUEST.awinFeedOffers=REQUEST.awinFeedReader.read('/var/tmp/runnerhub-awin-feed-validation/fixture/cache/feed-publication.json');REQUEST.awinFeedPrices=REQUEST.awinFeedReader.prices(REQUEST.awinFeedOffers);
VARIABLES.modoConsulta='catalogo';VARIABLES.tipo='tenis';VARIABLES.buscaAtual='';VARIABLES.ordemAtual='preco';VARIABLES.pageSize=1000;VARIABLES.paginaAtual=1;VARIABLES.parametros={filtros={}};
for(name in listToArray('marca,nome_produto,categoria,nivel_amortecimento,tamanho_drop,placa,genero,peso,preco_promocional'))VARIABLES.parametros.filtros[name]=[];
qCaracteristicas=queryNew('tag_caracteristica,coluna_resultado','varchar,varchar');
</cfscript>
<cfinclude template="/candidate/comparador/includes/consulta_produtos.cfm">
<cfscript>
check(qProdutosResultado.recordCount>100,'Consulta pública com projeção de preços executa');found=0;prior=0;
for(row in qProdutosResultado){
 prices=[];if(isNumeric(row.preco_awin))arrayAppend(prices,row.preco_awin);if(isNumeric(row.preco_promocional))arrayAppend(prices,row.preco_promocional);
 current=arrayLen(prices)?arrayMin(prices):(isNumeric(row.preco_referencia)?row.preco_referencia:0);
 if(current>0){check(current>=prior,'Ordenação por preço consistente no produto ' & row.id_produto);prior=current;}
 if(isNumeric(row.preco_awin))found++;
}
check(found==49,'49 preços do feed chegam à consulta pública');VARIABLES.parametros.filtros.preco_promocional=['LT400'];
</cfscript>
<cfinclude template="/candidate/comparador/includes/consulta_produtos.cfm">
<cfscript>
found=false;for(row in qProdutosResultado)if(row.id_produto==201 AND row.preco_awin==249.99)found=true;check(found,'Filtro abaixo de R$400 inclui o preço do feed');
REQUEST.awinFeedPrices='[]';VARIABLES.parametros.filtros.preco_promocional=[];
</cfscript>
<cfinclude template="/candidate/comparador/includes/consulta_produtos.cfm">
<cfscript>
check(qProdutosResultado.recordCount>100,'Contrato vazio mantém catálogo legado');cfcontent(type='application/json');writeOutput(serializeJSON({passed=arrayLen(checks),summary=['consulta','ordenação de todos os preços','filtro de preço','fallback sem feed']}));
</cfscript>
