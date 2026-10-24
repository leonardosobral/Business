<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
service=new services.ComparadorAdminService();
context={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED',isPost=CGI.request_method=='POST',csrfVerified=false};
service.authorize(context);csrf=csrfGenerateToken('comparador-admin');ready=service.isSchemaReady(context);error='';conflict=false;
search=service.field(URL,'busca',160);status=service.field(URL,'situacao',16);
page=structKeyExists(URL,'pagina') AND reFind('^[1-9][0-9]{0,6}$',URL.pagina)?val(URL.pagina):1;
offerId=0;if(len(service.field(URL,'id',10))) {try{offerId=service.identifier(URL.id);}catch(Comparador.Validation e){error=e.message;cfheader(statuscode=400);}}
returnQuery='busca=' & urlEncodedFormat(search) & '&situacao=' & urlEncodedFormat(status) & '&pagina=' & page;
action=service.field(FORM,'acao',16);formData={};token='';
if(ready AND len(action)) {
 try {
  context.csrfVerified=csrfVerifyToken(service.field(FORM,'csrf_token',256),'comparador-admin');service.authorize(context,true);
  if(!listFind('salvar,encerrar',action)) throw(type='Comparador.Validation',message='Ação inválida.');
  offerId=service.identifier(service.field(FORM,'id_cupom',10));
  service.updateOffer(context,offerId,service.field(FORM,'token',64),FORM,action=='encerrar');
  location(url='./?id=' & offerId & '&salvo=1&' & returnQuery,addtoken=false);
 }catch(Comparador.Conflict e){error=e.message;conflict=true;cfheader(statuscode=409);}
 catch(Comparador.Validation e){error=e.message;cfheader(statuscode=422);}
 catch(Comparador.Forbidden e){error=e.message;cfheader(statuscode=403);}
 catch(any e){error='Não foi possível salvar. A operação foi desfeita. Reabra a oferta e tente novamente.';cfheader(statuscode=500);writeLog(file='comparador-admin',type='error',text='Falha em oferta; referencia=' & createUUID());}
}
if(ready) {
 if(offerId) {
  try {detail=service.loadOffer(context,offerId);token=detail.token;for(col in listToArray(detail.offer.columnList)) formData[col]=detail.offer[col][1];if(isDate(formData.data_expiracao)) formData.data_expiracao=dateFormat(formData.data_expiracao,'yyyy-mm-dd');}
  catch(Comparador.Validation e){error=e.message;offerId=0;cfheader(statuscode=404);}
 }
 if(!offerId) offers=service.listOffers(context,search,status,page);
 if(len(error) AND action=='salvar' AND !conflict) for(col in ['loja','link','preco_promocional','cupom','condicoes','data_expiracao']) if(structKeyExists(FORM,col) AND isSimpleValue(FORM[col])) formData[col]=FORM[col];
}
function value(name){return structKeyExists(formData,name)?formData[name] & '':'';}
</cfscript>
