<!--- This include is used only by the CBG branch; retain the module's existing access policy. --->
<cfif NOT (VARIABLES.businessCanManageBrasilGiganteChallenge ?: false)><cfheader statuscode="403"/><cfabort/></cfif>
<cftry>
  <cfif CGI.request_method NEQ 'POST' OR NOT reFind('^[0-9]{1,9}$',FORM.id_usuario ?: '') OR NOT len(FORM.challenge_medal_csrf ?: '') OR compare(FORM.challenge_medal_csrf,VARIABLES.challengeMedalCsrf) NEQ 0>
    <cfthrow type="ChallengeMandala.Validation" message="A solicitação é inválida ou expirou. Recarregue a página antes de confirmar a entrega."/>
  </cfif>
  <cfif (FORM.confirmar_mandala ?: '') NEQ '1'><cfthrow type="ChallengeMandala.Validation" message="Confirme que conferiu o número gravado na mandala entregue a este atleta."/></cfif>
  <cfset VARIABLES.challengeMandalaResult=createObject('component','desafios.includes.MandalaDelivery').record(val(FORM.id_usuario),val(qPerfil.id),FORM.mandala_numero ?: '')/>
  <cfset VARIABLES.challengeMandalaSuccess=VARIABLES.challengeMandalaResult.alreadyDelivered ? 'mandala_numero_salvo' : 'mandala_entregue'/>
  <cflocation addtoken="false" url="/desafios/#VARIABLES.challengeTag#/?sucesso=#VARIABLES.challengeMandalaSuccess#&challenge_refresh=#getTickCount()#&busca=#urlEncodedFormat(URL.busca)#&mandala=#urlEncodedFormat(URL.mandala)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#"/>
  <cfcatch type="ChallengeMandala.Validation"><cfset VARIABLES.challengeMandalaError=cfcatch.message/></cfcatch>
  <cfcatch type="any"><cfset VARIABLES.challengeMandalaError='Não foi possível confirmar o número da mandala. Nenhuma alteração foi concluída; tente novamente.'/><cflog file="cbg-mandala" type="error" text="delivery_failed type=#left(reReplace(cfcatch.type,'[^a-zA-Z0-9_.-]','','all'),100)#"/></cfcatch>
</cftry>
