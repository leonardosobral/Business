<cfif NOT structKeyExists(REQUEST,"comparadorAdminPage")><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
variables.comparadorService=new services.ComparadorAdminService();
variables.comparadorContext={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED',isPost=compareNoCase(CGI.request_method,'POST')==0,csrfVerified=false};
variables.comparadorService.authorize(variables.comparadorContext);
variables.comparadorCsrf=csrfGenerateToken('comparador-admin');
variables.comparadorConflict=false;variables.comparadorError='';variables.comparadorNotice='';variables.comparadorReady=variables.comparadorService.isSchemaReady(variables.comparadorContext);
variables.comparadorSearch=variables.comparadorService.field(URL,'busca',160);
variables.comparadorType=variables.comparadorService.field(URL,'tipo',64);
variables.comparadorState=variables.comparadorService.field(URL,'estado',16);
variables.comparadorPending=variables.comparadorService.field(URL,'pendencia',16);
variables.comparadorTab=variables.comparadorService.field(URL,'aba',20);if(!listFind('dados,caracteristicas,ofertas,historico',variables.comparadorTab)) variables.comparadorTab='dados';
variables.comparadorPage=structKeyExists(URL,'pagina') AND reFind('^[1-9][0-9]{0,6}$',URL.pagina)?val(URL.pagina):1;
variables.comparadorId=structKeyExists(URL,'id') AND reFind('^[1-9][0-9]{0,9}$',URL.id) AND val(URL.id)<=2147483647?val(URL.id):0;
variables.comparadorNew=structKeyExists(URL,'novo') AND URL.novo=='1';
variables.comparadorReturn='busca=' & urlEncodedFormat(variables.comparadorSearch) & '&tipo=' & urlEncodedFormat(variables.comparadorType) & '&estado=' & urlEncodedFormat(variables.comparadorState) & '&pendencia=' & urlEncodedFormat(variables.comparadorPending) & '&pagina=' & variables.comparadorPage;
variables.comparadorForm={id_produto='',nome_produto='',tag_tipo_produto='',tag_marca='',tag_categoria='',tag_produto='',num_versao='0',versao='',resumo='',descricao='',preco_referencia='',data_lancamento=''};
variables.comparadorAction=variables.comparadorService.field(FORM,'acao',32);
if(variables.comparadorReady AND len(variables.comparadorAction)) {
 try {
  variables.comparadorContext.csrfVerified=csrfVerifyToken(variables.comparadorService.field(FORM,'csrf_token',256),'comparador-admin');
  variables.comparadorService.authorize(variables.comparadorContext,true);
  if(variables.comparadorAction=='produto') variables.comparadorId=variables.comparadorService.saveProduct(variables.comparadorContext,FORM);
  else {
   variables.comparadorId=variables.comparadorService.identifier(variables.comparadorService.field(FORM,'id_produto'));
   varToken=variables.comparadorService.field(FORM,'token',64);
   if(variables.comparadorAction=='estado') variables.comparadorService.changeState(variables.comparadorContext,variables.comparadorId,varToken,variables.comparadorService.field(FORM,'estado',16));
   else if(variables.comparadorAction=='oferta') variables.comparadorService.addOffer(variables.comparadorContext,variables.comparadorId,varToken,FORM);
   else if(variables.comparadorAction=='caracteristicas') {
    featureRows=[];variantRows=[];ids=variables.comparadorService.field(FORM,'feature_ids',2000);
    for(featureId in listToArray(ids)){variables.comparadorService.identifier(featureId);arrayAppend(featureRows,{id=featureId,tag='',value=variables.comparadorService.field(FORM,'valor_' & featureId),note=variables.comparadorService.field(FORM,'nota_' & featureId)});}
    arrayAppend(featureRows,{id=0,tag=variables.comparadorService.field(FORM,'nova_tag',64),value=variables.comparadorService.field(FORM,'novo_valor'),note=variables.comparadorService.field(FORM,'nova_nota')});
    for(gender in ['M','F','U']){if(structKeyExists(FORM,'variante_' & gender)) arrayAppend(variantRows,{gender=gender,weight=variables.comparadorService.field(FORM,'peso_' & gender),size=variables.comparadorService.field(FORM,'tamanho_' & gender)});}
    variables.comparadorService.saveSpecifications(variables.comparadorContext,variables.comparadorId,varToken,featureRows,variantRows);
   }else throw(type='Comparador.Validation',message='Ação inválida.');
  }
  location(url='./?id=' & variables.comparadorId & '&aba=' & variables.comparadorTab & '&salvo=1&' & variables.comparadorReturn,addtoken=false);
 }catch(Comparador.Conflict e){variables.comparadorConflict=true;variables.comparadorError=e.message;cfheader(statuscode=409);}
 catch(Comparador.Validation e){variables.comparadorError=e.message;cfheader(statuscode=422);}
 catch(Comparador.Forbidden e){variables.comparadorError=e.message;cfheader(statuscode=403);}
 catch(any e){variables.comparadorError='Não foi possível salvar. Nenhuma alteração desta operação foi aplicada. Recarregue a página e tente novamente.';cfheader(statuscode=500);writeLog(file='comparador-admin',type='error',text='Falha administrativa; referencia=' & createUUID());}
}
if(variables.comparadorReady){
 variables.comparadorLookups=variables.comparadorService.lookups(variables.comparadorContext);
 if(variables.comparadorId){
  try{variables.comparadorDetail=variables.comparadorService.load(variables.comparadorContext,variables.comparadorId);for(col in listToArray(variables.comparadorDetail.product.columnList)) variables.comparadorForm[col]=variables.comparadorDetail.product[col][1];}
  catch(Comparador.Validation e){variables.comparadorError=e.message;variables.comparadorId=0;cfheader(statuscode=404);}
 }
 if(!variables.comparadorId AND !variables.comparadorNew) variables.comparadorList=variables.comparadorService.listProducts(variables.comparadorContext,variables.comparadorSearch,variables.comparadorType,variables.comparadorState,variables.comparadorPending,variables.comparadorPage);
 if(len(variables.comparadorError) AND variables.comparadorAction=='produto') for(col in variables.comparadorForm){if(structKeyExists(FORM,col) AND isSimpleValue(FORM[col])) variables.comparadorForm[col]=FORM[col];}
 if(structKeyExists(URL,'salvo') AND URL.salvo=='1') variables.comparadorNotice='Alteração salva com histórico.';
}
function comparadorValue(required string key){return structKeyExists(variables.comparadorForm,key)?variables.comparadorForm[key] & '':'';}
function comparadorInput(required string key){return encodeForHTMLAttribute(comparadorValue(key));}
function comparadorPosted(required string key,required any fallback){return encodeForHTMLAttribute(len(variables.comparadorError) AND structKeyExists(FORM,key) AND isSimpleValue(FORM[key])?FORM[key]:fallback & '');}
</cfscript>
