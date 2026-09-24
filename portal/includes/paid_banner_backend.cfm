<cfinclude template="banner_form_helpers.cfm"/>
<cfif NOT structKeyExists(VARIABLES,"paidBannerText")><cfinclude template="paid_banner_helpers.cfm"/></cfif>
<cfinclude template="paid_banner_actions.cfm"/>
<cfinclude template="paid_banner_queries.cfm"/>
<cfset VARIABLES.paidBannerReady=false/>
<cfset VARIABLES.paidBannerError=''/>
<cfset VARIABLES.paidBannerNotice=''/>
<cfset VARIABLES.paidBannerConflict=false/>
<cfset VARIABLES.paidBannerEditId=''/>
<cfset VARIABLES.paidBannerEditRow={}/>
<cfset VARIABLES.paidBannerShowForm=false/>
<cfset VARIABLES.paidBannerRows=[]/>
<cfset VARIABLES.paidBannerChartRows=[]/>
<cfset VARIABLES.paidBannerDays=30/>
<cfset VARIABLES.paidBannerFilter=''/>
<cfset VARIABLES.paidBannerTotals={impressions=0,clicks=0,cost=0}/>
<cfset VARIABLES.paidBannerBalanceValue=0/>
<cfset VARIABLES.paidBannerContext={method=CGI.request_method,accountId=VARIABLES.adsAccessAccountId,actorId=VARIABLES.adsAccessActorId,canManage=VARIABLES.adsAccessCanManageCampaign,canReview=VARIABLES.adsAccessCanReviewCampaign,canView=VARIABLES.adsAccessCanView,csrf=''}/>
<cflock scope="session" type="exclusive" timeout="5">
    <cfif NOT structKeyExists(SESSION,'paidBannerCsrfSeed')><cfset SESSION.paidBannerCsrfSeed=generateSecretKey('AES',256)/></cfif>
    <!--- Bind the form to the selected account, including the global review view. --->
    <cfset VARIABLES.paidBannerCsrf=hmac(VARIABLES.paidBannerContext.actorId & ':' & VARIABLES.paidBannerContext.accountId,SESSION.paidBannerCsrfSeed,'HmacSHA256')/>
</cflock>
<cfset VARIABLES.paidBannerContext.csrf=VARIABLES.paidBannerCsrf/>
<cfif VARIABLES.adsAccessCanView OR VARIABLES.adsAccessCanReviewCampaign>
    <cftry>
        <cfquery name="qPaidBannerReady" datasource="runnerhub">
            SELECT bool_and(procedure_oid IS NOT NULL AND has_function_privilege(current_user, procedure_oid, 'EXECUTE')) AS ready
            FROM unnest(ARRAY[
                to_regprocedure('ads.save_paid_banner_campaign(uuid,bigint,integer,jsonb,boolean)'),
                to_regprocedure('ads.submit_paid_banner_review(uuid,bigint,integer)'),
                to_regprocedure('ads.review_paid_banner_campaign(uuid,text,integer,text,text,bigint)')
            ]) AS required(procedure_oid)
        </cfquery>
        <cfset VARIABLES.paidBannerReady=qPaidBannerReady.ready/>
        <cfif VARIABLES.paidBannerReady>
            <cfif CGI.request_method EQ 'POST'>
                <cfset VARIABLES.paidBannerNewFiles=[]/>
                <cfset VARIABLES.paidBannerStaging=''/>
                <cfset VARIABLES.paidBannerSaveAttempted=false/>
                <cftry>
                    <cfset VARIABLES.paidBannerAction=paidBannerText(FORM,'paid_banner_action')/>
                    <cfset paidBannerAssertAction(CGI.request_method,paidBannerText(FORM,'paid_banner_csrf'),VARIABLES.paidBannerCsrf,VARIABLES.paidBannerContext.canManage,VARIABLES.paidBannerContext.canReview,VARIABLES.paidBannerContext.accountId GT 0,VARIABLES.paidBannerAction)/>
                    <cfif VARIABLES.paidBannerAction EQ 'save'>
                        <cfset VARIABLES.paidBannerEditId=paidBannerText(FORM,'campaign_id')/>
                        <cfset paidBannerValues(FORM)/>
                        <cfif len(VARIABLES.paidBannerEditId)>
                            <cfset qPaidBannerEdit=paidBannerCampaigns(VARIABLES.paidBannerContext,VARIABLES.paidBannerEditId)/>
                            <cfif qPaidBannerEdit.recordcount NEQ 1><cfthrow type="AdsV1.Validation" message="Banner não encontrado nesta conta."/></cfif>
                            <cfset VARIABLES.paidBannerEditRow=paidBannerRow(qPaidBannerEdit,1)/>
                            <cfif VARIABLES.paidBannerEditRow.status NEQ 'DRAFT' OR listFind('PENDING_REVIEW,WAITING_PREREQUISITES,APPROVED',VARIABLES.paidBannerEditRow.review_status)><cfthrow type="AdsV1.Conflict" message="O banner mudou de estado em outra sessão. Seus valores foram preservados abaixo somente para conferência; reabra a versão atual antes de editar."/></cfif>
                            <cfif paidBannerText(FORM,'expected_version') NEQ (VARIABLES.paidBannerEditRow.version & '')><cfthrow type="AdsV1.Conflict" message="O banner foi alterado em outra sessão. Seus valores foram preservados abaixo somente para conferência; reabra a versão atual antes de editar."/></cfif>
                        </cfif>
                        <cfset VARIABLES.paidBannerImages={}/>
                        <cfloop list="desktop,mobile" index="paidBannerKind">
                            <cfloop list="image_url,width,height" index="paidBannerImageField">
                                <cfset paidBannerImageKey=paidBannerImageField & '_' & paidBannerKind/>
                                <cfif structKeyExists(VARIABLES.paidBannerEditRow,paidBannerImageKey)><cfset VARIABLES.paidBannerImages[paidBannerImageKey]=VARIABLES.paidBannerEditRow[paidBannerImageKey]/></cfif>
                            </cfloop>
                            <cfif len(paidBannerText(FORM,'banner_arquivo_' & paidBannerKind))>
                                <!--- Only a known deployment origin may publish uploaded assets. Never echo an arbitrary Host header. --->
                                <cfif compareNoCase(CGI.server_name,'business.roadrunners.run') NEQ 0><cfthrow type="AdsV1.Validation" message="Uploads de banners não estão configurados neste ambiente."/></cfif>
                                <cfif NOT len(VARIABLES.paidBannerStaging)>
                                    <cfset VARIABLES.paidBannerStaging=getTempDirectory() & 'paid-banner-' & lCase(replace(createUUID(),'-','','all')) & '/'/>
                                    <cfdirectory action="create" directory="#VARIABLES.paidBannerStaging#" mode="700"/>
                                </cfif>
                                <cffile action="upload" filefield="banner_arquivo_#paidBannerKind#" destination="#VARIABLES.paidBannerStaging#" nameconflict="makeunique" result="paidBannerUpload"/>
                                <cfset paidBannerSource=VARIABLES.paidBannerStaging & paidBannerUpload.serverFile/>
                                <cfset paidBannerInfo=bannerImageMetadata(paidBannerSource)/>
                                <cfset paidBannerFile='paid-banner-' & lCase(replace(createUUID(),'-','','all')) & '.' & paidBannerInfo.extension/>
                                <cfset paidBannerDiskDirectory=getDirectoryFromPath(getCurrentTemplatePath()) & '../banners/assets/'/>
                                <cfif NOT directoryExists(paidBannerDiskDirectory)><cfdirectory action="create" directory="#paidBannerDiskDirectory#"/></cfif>
                                <cfset paidBannerPath=paidBannerDiskDirectory & paidBannerFile/>
                                <cffile action="move" source="#paidBannerSource#" destination="#paidBannerPath#"/>
                                <cfset arrayAppend(VARIABLES.paidBannerNewFiles,paidBannerPath)/>
                                <cfset VARIABLES.paidBannerImages['image_url_' & paidBannerKind]='https://business.roadrunners.run/portal/banners/assets/' & paidBannerFile/>
                                <cfset VARIABLES.paidBannerImages['width_' & paidBannerKind]=paidBannerInfo.width/>
                                <cfset VARIABLES.paidBannerImages['height_' & paidBannerKind]=paidBannerInfo.height/>
                            </cfif>
                        </cfloop>
                        <!--- An uncertain DB response must never delete a possibly committed image. --->
                        <cfset VARIABLES.paidBannerSaveAttempted=true/>
                        <cfset VARIABLES.paidBannerOutcome=paidBannerSave(FORM,VARIABLES.paidBannerContext,VARIABLES.paidBannerImages)/>
                        <cfset VARIABLES.paidBannerNotice=VARIABLES.paidBannerOutcome.review_status EQ 'PENDING_REVIEW' ? 'Banner salvo e enviado para análise. Ele só entra no ar após aprovação.' : (VARIABLES.paidBannerOutcome.review_status EQ 'WAITING_PREREQUISITES' ? 'Banner salvo. O envio para análise aguarda a aprovação da conta.' : 'Rascunho salvo. Envie para análise quando estiver pronto.')/>
                    <cfelse>
                        <cfset qPaidBannerAction=paidBannerManage(FORM,VARIABLES.paidBannerContext)/>
                        <cfset VARIABLES.paidBannerNotice='Operação concluída. Confira o status atualizado abaixo.'/>
                    </cfif>
                    <cfset SESSION.paidBannerFlash={accountId=VARIABLES.paidBannerContext.accountId,message=VARIABLES.paidBannerNotice}/>
                    <cfset VARIABLES.paidBannerNext=VARIABLES.paidBannerAction EQ 'prepare' ? '/portal/banners/?edit=' & encodeForURL(paidBannerText(FORM,'campaign_id')) & '##paid-banner-form' : '/portal/banners/'/>
                    <cfcatch type="any">
                        <cfif compareNoCase(cfcatch.type,'AdsV1.Conflict') EQ 0><cfset VARIABLES.paidBannerConflict=true/></cfif>
                        <cfif NOT VARIABLES.paidBannerSaveAttempted><cfloop array="#VARIABLES.paidBannerNewFiles#" index="paidBannerFailedFile"><cfif fileExists(paidBannerFailedFile)><cffile action="delete" file="#paidBannerFailedFile#"/></cfif></cfloop></cfif>
                        <cfset VARIABLES.paidBannerError=listFindNoCase('AdsV1.Validation,AdsV1.Conflict',cfcatch.type) ? cfcatch.message : 'Não foi possível concluir. Atualize a listagem e confira se o banner foi salvo antes de tentar novamente.'/>
                        <cflog file="business_ads_v1" type="error" text="paid banner action account=#VARIABLES.paidBannerContext.accountId# actor=#VARIABLES.paidBannerContext.actorId# type=#cfcatch.type# message=#cfcatch.message#"/>
                    </cfcatch>
                    <cffinally><cfif len(VARIABLES.paidBannerStaging) AND directoryExists(VARIABLES.paidBannerStaging)><cfdirectory action="delete" directory="#VARIABLES.paidBannerStaging#" recurse="true"/></cfif></cffinally>
                </cftry>
                <cfif NOT len(VARIABLES.paidBannerError)><cflocation url="#VARIABLES.paidBannerNext#" addtoken="false" statuscode="303"/></cfif>
            </cfif>
            <cfif structKeyExists(SESSION,'paidBannerFlash')>
                <cfif SESSION.paidBannerFlash.accountId EQ VARIABLES.paidBannerContext.accountId><cfset VARIABLES.paidBannerNotice=SESSION.paidBannerFlash.message/></cfif>
                <cfset structDelete(SESSION,'paidBannerFlash')/>
            </cfif>
            <cfset qPaidBannerCampaigns=paidBannerCampaigns(VARIABLES.paidBannerContext)/>
            <cfloop query="qPaidBannerCampaigns"><cfset arrayAppend(VARIABLES.paidBannerRows,paidBannerRow(qPaidBannerCampaigns,qPaidBannerCampaigns.currentrow))/></cfloop>
            <cfset VARIABLES.paidBannerDays=val(paidBannerText(URL,'periodo','30'))/>
            <cfset VARIABLES.paidBannerFilter=paidBannerText(URL,'banner')/>
            <cfif len(VARIABLES.paidBannerFilter) AND NOT listFindNoCase(valueList(qPaidBannerCampaigns.campaign_id),VARIABLES.paidBannerFilter)><cfthrow type="AdsV1.Validation" message="Banner do filtro não encontrado nesta conta."/></cfif>
            <cfset qPaidBannerDaily=paidBannerDaily(VARIABLES.paidBannerContext,VARIABLES.paidBannerDays,VARIABLES.paidBannerFilter)/>
            <cfloop query="qPaidBannerDaily">
                <cfset arrayAppend(VARIABLES.paidBannerChartRows,{'date'=dateFormat(qPaidBannerDaily.metric_date,'yyyy-mm-dd'),'impressions'=val(qPaidBannerDaily.impressions),'clicks'=val(qPaidBannerDaily.clicks),'cost'=val(qPaidBannerDaily.cost)})/>
                <cfloop list="impressions,clicks,cost" index="paidBannerMetric"><cfset VARIABLES.paidBannerTotals[paidBannerMetric]+=val(qPaidBannerDaily[paidBannerMetric][qPaidBannerDaily.currentrow])/></cfloop>
            </cfloop>
            <cfset qPaidBannerBalance=paidBannerBalance(VARIABLES.paidBannerContext)/>
            <cfif qPaidBannerBalance.recordcount><cfset VARIABLES.paidBannerBalanceValue=qPaidBannerBalance.available_balance/></cfif>
            <cfif VARIABLES.paidBannerContext.canManage>
                <cfif CGI.request_method EQ 'GET'><cfset VARIABLES.paidBannerEditId=paidBannerText(URL,'edit')/></cfif>
                <cfif len(VARIABLES.paidBannerEditId)>
                    <cfset qPaidBannerEdit=paidBannerCampaigns(VARIABLES.paidBannerContext,VARIABLES.paidBannerEditId)/>
                    <cfif qPaidBannerEdit.recordcount NEQ 1><cfthrow type="AdsV1.Validation" message="Banner não encontrado nesta conta."/></cfif>
                    <cfset VARIABLES.paidBannerEditRow=paidBannerRow(qPaidBannerEdit,1)/>
                    <cfif NOT VARIABLES.paidBannerConflict AND (VARIABLES.paidBannerEditRow.status NEQ 'DRAFT' OR listFind('PENDING_REVIEW,WAITING_PREREQUISITES,APPROVED',VARIABLES.paidBannerEditRow.review_status))><cfthrow type="AdsV1.Validation" message="Use Editar na listagem para pausar ou retirar o banner da análise primeiro."/></cfif>
                </cfif>
                <cfset VARIABLES.paidBannerShowForm=VARIABLES.paidBannerConflict OR len(VARIABLES.paidBannerEditId) GT 0 OR paidBannerText(URL,'novo') EQ '1' OR (CGI.request_method EQ 'POST' AND paidBannerText(FORM,'paid_banner_action') EQ 'save')/>
                <cfset VARIABLES.paidBannerFormData=paidBannerForm(FORM,VARIABLES.paidBannerEditRow)/>
                <!--- Keep the version the user actually edited on validation failure. --->
                <cfif CGI.request_method EQ 'POST' AND len(VARIABLES.paidBannerEditId) AND structKeyExists(FORM,'expected_version')><cfset VARIABLES.paidBannerEditRow.version=paidBannerText(FORM,'expected_version')/></cfif>
            </cfif>
        </cfif>
        <cfcatch type="any">
            <cfset VARIABLES.paidBannerError=cfcatch.type EQ 'AdsV1.Validation' ? cfcatch.message : 'Não foi possível carregar os banners. Tente novamente.'/>
            <cfset VARIABLES.paidBannerShowForm=false/>
            <cflog file="business_ads_v1" type="error" text="paid banner read account=#VARIABLES.paidBannerContext.accountId# actor=#VARIABLES.paidBannerContext.actorId# type=#cfcatch.type# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>
