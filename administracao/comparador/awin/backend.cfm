<cfif NOT structKeyExists(REQUEST,'comparadorAdminPage')><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
guard=new services.ComparadorAdminService();awin=new services.ComparadorAwinService();publication=new services.ComparadorAwinPublicationService();feedService=new services.ComparadorAwinFeedService();
context={actorId=isDefined('REQUEST.businessIdentity.id')?REQUEST.businessIdentity.id:0,isAdmin=isDefined('VARIABLES.businessEffectiveIsAdmin') AND VARIABLES.businessEffectiveIsAdmin,delegated=isDefined('REQUEST.businessAccessContext.accessMode') AND REQUEST.businessAccessContext.accessMode=='DELEGATED',isPost=CGI.request_method=='POST',csrfVerified=false};
guard.authorize(context);csrf=csrfGenerateToken('comparador-awin');error='';notice='';generatedLink='';data={};
tab=guard.field(URL,'aba',20);if(!listFind('campanhas,programas,links,publicacao,feed',tab))tab='campanhas';
search=guard.field(URL,'busca',160);advertiserFilter=guard.field(URL,'anunciante',20);typeFilter=guard.field(URL,'tipo',16);stateFilter=guard.field(URL,'situacao',16);
destination=guard.field(FORM,'destino',8192);linkAdvertiser=guard.field(FORM,'anunciante',20);
try {
 action=guard.field(FORM,'acao',20);
 if(len(action)) {
  context.csrfVerified=csrfVerifyToken(guard.field(FORM,'csrf_token',256),'comparador-awin');guard.authorize(context,true);
  if(action=='atualizar') {cfsetting(requesttimeout=180);awin.refresh(context);publication.synchronize(context,awin.dashboard(context));location(url='./?atualizado=1',addtoken=false);}
  else if(action=='atualizar_feed'){cfsetting(requesttimeout=180);awin.refresh(context);feedService.synchronize(context,awin.dashboard(context));location(url='./?aba=feed&atualizado=1',addtoken=false);}
  else if(action=='feed_regra'){feedService.saveBlock(context,guard.field(FORM,'vinculo',40),guard.field(FORM,'modo',20),guard.field(FORM,'feed_token',64));location(url='./?aba=feed&salvo=1',addtoken=false);}
  else if(action=='regra') {
   savedCampaign=guard.field(FORM,'campanha',20);
   publication.saveRule(context,awin.dashboard(context),savedCampaign,guard.field(FORM,'modo',20),guard.field(FORM,'produtos',240),guard.field(FORM,'publicacao_token',64),guard.field(FORM,'campanha_hash',64),guard.field(FORM,'motivo_catalogo',1000));
   savedPlan=publication.dashboard(context,awin.dashboard(context));savedQueue='revisao';
   for(savedDecision in savedPlan.plan.decisions)if(savedDecision.campaignId==savedCampaign)savedQueue=savedDecision.classification;
   location(url='./?aba=publicacao&salvo=1&fila=' & encodeForURL(savedQueue) & '&campanha=' & encodeForURL(savedCampaign),addtoken=false);
  }
  else if(action=='gerar_link') {tab='links';generatedLink=awin.generateLink(context,linkAdvertiser,destination);}
  else throw(type='Comparador.Validation',message='Ação inválida.');
 }
} catch(Comparador.Forbidden e){error=e.message;cfheader(statuscode=403);}
catch(Comparador.Conflict e){error=e.message;cfheader(statuscode=409);}
catch(Comparador.Validation e){error=e.message;cfheader(statuscode=422);}
catch(Comparador.Awin e){error=e.message;}
catch(any e){error='A operação não pôde ser concluída. Tente novamente em alguns minutos.';}
try {data=awin.dashboard(context);}catch(Comparador.Awin e){if(!len(error))error=e.message;}catch(any e){if(!len(error))error='Não foi possível carregar a conexão Awin.';}
publicationData={};campaignEdit=guard.field(URL,'campanha',20);productSearch=guard.field(URL,'produto_busca',120);
if(structKeyExists(data,'promotions'))try{publicationData=publication.dashboard(context,data);}catch(any e){if(!len(error))error='Não foi possível carregar a gestão da publicação.';}
publicationQueue=guard.field(URL,'fila',20);if(!listFind('revisao,vinculadas,fora_catalogo,bloqueadas,todas',publicationQueue))publicationQueue='revisao';
if(len(campaignEdit) AND !structKeyExists(URL,'fila') AND structKeyExists(publicationData,'plan'))for(decision in publicationData.plan.decisions)if(decision.campaignId==campaignEdit)publicationQueue=decision.classification;
publicationDecisions=[];
if(structKeyExists(publicationData,'plan'))for(decision in publicationData.plan.decisions){
 if(publicationQueue!='todas' AND decision.classification!=publicationQueue)continue;
 if(len(advertiserFilter)){foundAdvertiser=false;for(promotion in data.promotions)if(promotion.id==decision.campaignId AND promotion.advertiserId==advertiserFilter)foundAdvertiser=true;if(!foundAdvertiser)continue;}
 if(len(search) AND !findNoCase(search,decision.title & ' ' & decision.advertiser & ' ' & decision.reason))continue;
 arrayAppend(publicationDecisions,decision);
}
filtered=[];
if(structKeyExists(data,'promotions')) for(promotion in data.promotions) {
 if(len(advertiserFilter) AND compare(promotion.advertiserId,advertiserFilter)!=0)continue;
 if(len(typeFilter) AND promotion.type!=typeFilter)continue;
 if(len(stateFilter) AND promotion.state!=stateFilter)continue;
 if(len(search) AND !findNoCase(search,promotion.title & ' ' & promotion.advertiser & ' ' & promotion.code & ' ' & promotion.description))continue;
 arrayAppend(filtered,promotion);
}
</cfscript>

<cfscript>feedData={};if(tab=='feed')try{feedData=feedService.dashboard(context);}catch(any e){if(!len(error))error='Não foi possível carregar os feeds de produtos.';}</cfscript>
