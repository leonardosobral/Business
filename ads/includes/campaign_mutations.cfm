<cffunction name="adsV1MutationPrepare" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfquery name="arguments.state.qAdsV1PrepareEditTarget" datasource="#arguments.fresh.datasource#">
                    SELECT campaign.campaign_id
                    FROM ads.campaigns campaign
                    WHERE campaign.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1PrepareEditCampaignId#"/> AS uuid)
                      AND campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/>
                      AND campaign.billing_model = 'CPC'
                      AND EXISTS (
                          SELECT 1
                          FROM ads.advertisements advertisement
                          WHERE advertisement.campaign_id = campaign.campaign_id
                            AND advertisement.account_id = campaign.account_id
                            AND advertisement.ad_type = 'EVENT'
                      )
                    LIMIT 1
                </cfquery>
                <cfif NOT arguments.state.qAdsV1PrepareEditTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="A campanha de evento não foi encontrada nesta conta."/>
                </cfif>

                <cfquery name="arguments.state.qAdsV1PrepareEditResult" datasource="#arguments.fresh.datasource#">
                    SELECT *
                    FROM ads.prepare_campaign_for_edit(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1PrepareEditCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer)
                    )
                </cfquery>
<cfreturn true/></cffunction>
<cffunction name="adsV1MutationSave" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfquery name="arguments.state.qAdsV1EventTarget" datasource="#arguments.fresh.datasource#">
                    SELECT evt.id_evento,
                           evt.tag
                    FROM public.tb_conta_eventos ce
                    INNER JOIN public.tb_evento_corridas evt
                      ON evt.id_evento = ce.id_evento
                    WHERE ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/>
                      AND ce.status::text IN ('ATIVO', 'PENDENTE')
                      AND (
                        ce.status::text = 'ATIVO'
                        <cfif arguments.state.adsAccessIsPendingNewAccount>
                          OR (
                            ce.status::text = 'PENDENTE'
                            AND EXISTS (
                                SELECT 1
                                FROM public.tb_conta_evento_solicitacoes req
                                WHERE req.id_conta = ce.id_conta
                                  AND req.id_evento = ce.id_evento
                                  AND req.id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1ActorId#"/>
                                  AND req.status = 'PENDENTE'
                            )
                          )
                        </cfif>
                      )
                      AND evt.ativo = true
                      AND evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1FormEventId#"/>
                    LIMIT 1
                </cfquery>
                <cfif NOT arguments.state.qAdsV1EventTarget.recordcount OR NOT reFindNoCase("^[a-z0-9._~-]+$", trim(arguments.state.qAdsV1EventTarget.tag & ""))>
                    <cfthrow type="AdsV1.Validation" message="O evento nao esta ativo ou nao pertence a conta selecionada."/>
                </cfif>

                <cfif len(arguments.state.adsV1FormCampaignId)>
                    <cfquery name="arguments.state.qAdsV1CampaignSaveTarget" datasource="#arguments.fresh.datasource#">
                        SELECT c.campaign_id,
                               c.status,
                               review.status AS review_status
                        FROM ads.campaigns c
                        LEFT JOIN LATERAL (
                            SELECT request.status
                            FROM ads.campaign_review_requests request
                            WHERE request.campaign_id = c.campaign_id
                              AND request.account_id = c.account_id
                              AND request.ad_type = 'EVENT'
                            ORDER BY request.campaign_review_request_id DESC
                            LIMIT 1
                        ) review ON true
                        WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormCampaignId#"/> AS uuid)
                          AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/>
                          AND c.billing_model = 'CPC'
                          AND c.status IN ('DRAFT', 'PAUSED')
                          AND EXISTS (
                              SELECT 1
                              FROM ads.advertisements advertisement
                              WHERE advertisement.campaign_id = c.campaign_id
                                AND advertisement.account_id = c.account_id
                                AND advertisement.ad_type = 'EVENT'
                          )
                        LIMIT 1
                    </cfquery>
                    <cfif NOT arguments.state.qAdsV1CampaignSaveTarget.recordcount
                        OR listFind("WAITING_PREREQUISITES,PENDING_REVIEW,APPROVED", uCase(trim(arguments.state.qAdsV1CampaignSaveTarget.review_status & "")))>
                        <cfthrow type="AdsV1.Validation" message="Somente campanhas em rascunho ou pausadas e fora de análise podem ser editadas."/>
                    </cfif>
                </cfif>

                <cfset arguments.state.adsV1DestinationUrl = reReplace(arguments.state.roadRunnersBaseUrl, "/+$", "", "all")
                    & "/evento/" & trim(arguments.state.qAdsV1EventTarget.tag) & "/"/>


                    <cfquery name="arguments.state.qAdsV1CampaignSave" datasource="#arguments.fresh.datasource#">
                        SELECT *
                        <cfif arguments.state.adsAccessIsPendingNewAccount>
                        FROM ads.save_pending_event_campaign(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormCampaignId#" null="#NOT len(arguments.state.adsV1FormCampaignId)#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/> AS bigint),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsAccessRegistrationId#"/> AS bigint),
                        <cfelse>
                        FROM ads.save_event_campaign(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormCampaignId#" null="#NOT len(arguments.state.adsV1FormCampaignId)#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/> AS bigint),
                        </cfif>
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.qAdsV1EventTarget.id_evento#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormPlacementKeys[1]#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormName#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1DestinationUrl#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#arguments.state.adsV1FormCpc#" scale="2"/> AS numeric),
                            CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#arguments.state.adsV1FormBudgetTotal#" scale="2"/> AS numeric),
                            CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#arguments.state.adsV1FormBudgetDaily#" scale="2" null="#NOT len(arguments.state.adsV1FormBudgetDailyRaw)#"/> AS numeric),
                            CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.state.adsV1FormStarts#"/> AS timestamp with time zone),
                            CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.state.adsV1FormEnds#"/> AS timestamp with time zone),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormDevice#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormCountry#"/> AS character(2)),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormRegion#" null="#NOT len(arguments.state.adsV1FormRegion)#"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer)
                        )
                    </cfquery>

                    <cfquery name="arguments.state.qAdsV1CampaignPlacementSave" datasource="#arguments.fresh.datasource#">
                        SELECT *
                        FROM ads.replace_campaign_placements(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.qAdsV1CampaignSave.campaign_id#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1FormPlacementArrayLiteral#"/> AS text[]),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="Spots salvos pelo Business"/> AS text)
                        )
                    </cfquery>
                    <cfif structKeyExists(FORM, "campaign_intent") AND FORM.campaign_intent EQ "submit">
                        <cfquery name="arguments.state.qAdsV1CampaignSaveSubmit" datasource="#arguments.fresh.datasource#">
                            SELECT * FROM ads.submit_campaign_review(
                                CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.qAdsV1CampaignSave.campaign_id#"/> AS uuid),
                                CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/> AS bigint),
                                CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer),
                                CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.qAdsV1EventTarget.id_evento#"/> AS integer)
                            )
                        </cfquery>
                    </cfif>

<cfreturn true/></cffunction>
<cffunction name="adsV1MutationSubmit" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfquery name="arguments.state.qAdsV1ReviewTarget" datasource="#arguments.fresh.datasource#">
                    SELECT campaign.campaign_id,
                           advertisement.core_event_id
                    FROM ads.campaigns campaign
                    INNER JOIN ads.advertisements advertisement
                      ON advertisement.campaign_id = campaign.campaign_id
                     AND advertisement.account_id = campaign.account_id
                     AND advertisement.ad_type = 'EVENT'
                    WHERE campaign.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1ReviewCampaignId#"/> AS uuid)
                      AND campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/>
                      AND campaign.billing_model = 'CPC'
                      AND campaign.status = 'DRAFT'
                    LIMIT 1
                </cfquery>

                <cfif NOT arguments.state.qAdsV1ReviewTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="Somente um rascunho desta conta pode ser enviado para análise."/>
                </cfif>

                <cfquery name="arguments.state.qAdsV1ReviewSubmit" datasource="#arguments.fresh.datasource#">
                    SELECT *
                    FROM ads.submit_campaign_review(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1ReviewCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.qAdsV1ReviewTarget.core_event_id#"/> AS integer)
                    )
                </cfquery>
<cfreturn true/></cffunction>
<cffunction name="adsV1MutationStatus" output="false"><cfargument name="fresh" type="struct" required="true"/><cfargument name="state" type="struct" required="true"/>
<cfquery name="arguments.state.qAdsV1StatusTarget" datasource="#arguments.fresh.datasource#">
                    SELECT c.campaign_id,
                           c.status
                    FROM ads.campaigns c
                    WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1StatusCampaignId#"/> AS uuid)
                      AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.state.adsV1AccountId#"/>
                      AND c.billing_model = 'CPC'
                      AND EXISTS (
                          SELECT 1
                          FROM ads.advertisements advertisement
                          WHERE advertisement.campaign_id = c.campaign_id
                            AND advertisement.account_id = c.account_id
                            AND advertisement.ad_type = 'EVENT'
                      )
                    LIMIT 1
                </cfquery>
                <cfif NOT arguments.state.qAdsV1StatusTarget.recordcount
                    OR (arguments.state.adsV1TargetStatus EQ "PAUSED" AND arguments.state.qAdsV1StatusTarget.status NEQ "ACTIVE")
                    OR (arguments.state.adsV1TargetStatus EQ "ENDED" AND NOT listFind("DRAFT,ACTIVE,PAUSED", arguments.state.qAdsV1StatusTarget.status))>
                    <cfthrow type="AdsV1.Validation" message="A transicao de status nao e permitida."/>
                </cfif>

                <cfquery name="arguments.state.qAdsV1StatusResult" datasource="#arguments.fresh.datasource#">
                    SELECT *
                    FROM ads.change_campaign_status(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1StatusCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.state.adsV1TargetStatus#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.state.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(arguments.state.adsV1StatusReason, 500)#" null="#NOT len(arguments.state.adsV1StatusReason)#"/> AS text)
                    )
                </cfquery>
<cfreturn true/></cffunction>
