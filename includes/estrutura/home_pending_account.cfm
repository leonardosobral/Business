<cfset VARIABLES.businessPendingEventRequests = 0/>
<cfset VARIABLES.businessPendingEventLinked = false/>
<cfset VARIABLES.businessPendingWorkspaceTargetAccountId = ""/>
<cfset VARIABLES.businessPendingVoucherStatus = ""/>
<cfset VARIABLES.businessPendingVoucherAmount = 0/>
<cfset VARIABLES.businessPendingCampaignCount = 0/>
<cfset VARIABLES.businessPendingCampaignReviewStatus = ""/>
<cfset VARIABLES.businessPendingCampaignReviewReason = ""/>
<cfset VARIABLES.businessPendingIsExistingAccountRequest = isDefined("VARIABLES.businessPendingExistingAccountRequest")
    AND VARIABLES.businessPendingExistingAccountRequest/>
<cfif isDefined("VARIABLES.businessPendingAccountId")
    AND len(trim(VARIABLES.businessPendingAccountId))
    AND isNumeric(VARIABLES.businessPendingAccountId)>
    <cfset VARIABLES.businessPendingWorkspaceTargetAccountId = VARIABLES.businessPendingAccountId/>
</cfif>

<cfif len(VARIABLES.businessPendingWorkspaceTargetAccountId)
    AND NOT VARIABLES.businessPendingIsExistingAccountRequest>
  <cftry>
    <cfquery name="qBusinessPendingVoucherProgress" datasource="runnerhub">
        SELECT reservation.status,
               coalesce(voucher.credito_disponivel, voucher.credito, 0)::numeric(14, 2) AS credito
        FROM ads.voucher_reservations reservation
        INNER JOIN ads.tb_ad_vouchers voucher
          ON voucher.id_ad_voucher = reservation.id_ad_voucher
        WHERE reservation.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPendingWorkspaceTargetAccountId#"/>
          AND reservation.id_solicitacao_cadastro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPendingRegistrationId#"/>
        ORDER BY reservation.voucher_reservation_id DESC
        LIMIT 1
    </cfquery>

    <cfif qBusinessPendingVoucherProgress.recordcount>
        <cfset VARIABLES.businessPendingVoucherStatus = uCase(trim(qBusinessPendingVoucherProgress.status & ""))/>
        <cfset VARIABLES.businessPendingVoucherAmount = val(qBusinessPendingVoucherProgress.credito)/>
    </cfif>
    <cfcatch type="any"></cfcatch>
  </cftry>

  <cftry>
    <cfquery name="qBusinessPendingCampaignProgress" datasource="runnerhub">
        SELECT totals.campaign_count,
               latest_review.status AS review_status,
               latest_review.review_reason
        FROM (
            SELECT count(*)::integer AS campaign_count
            FROM ads.campaigns campaign
            WHERE campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPendingWorkspaceTargetAccountId#"/>
        ) totals
        LEFT JOIN LATERAL (
            SELECT review.status,
                   review.review_reason
            FROM ads.campaign_review_requests review
            WHERE review.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPendingWorkspaceTargetAccountId#"/>
            ORDER BY review.updated_at DESC,
                     review.campaign_review_request_id DESC
            LIMIT 1
        ) latest_review ON true
    </cfquery>

    <cfif qBusinessPendingCampaignProgress.recordcount>
        <cfset VARIABLES.businessPendingCampaignCount = val(qBusinessPendingCampaignProgress.campaign_count)/>
        <cfset VARIABLES.businessPendingCampaignReviewStatus = uCase(trim(qBusinessPendingCampaignProgress.review_status & ""))/>
        <cfset VARIABLES.businessPendingCampaignReviewReason = trim(qBusinessPendingCampaignProgress.review_reason & "")/>
    </cfif>
    <cfcatch type="any"></cfcatch>
  </cftry>
</cfif>

<cfif len(VARIABLES.businessPendingWorkspaceTargetAccountId)>
  <cftry>
    <cfquery name="qBusinessPendingWorkspaceProgress">
        SELECT count(DISTINCT req.id_solicitacao) FILTER (
                   WHERE req.status = 'PENDENTE'
               )::integer AS solicitacoes_evento_pendentes
        FROM tb_contas cont
        LEFT JOIN tb_conta_evento_solicitacoes req ON req.id_conta = cont.id_conta
            AND req.id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
        WHERE cont.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPendingWorkspaceTargetAccountId#"/>
    </cfquery>

    <cfif qBusinessPendingWorkspaceProgress.recordcount>
        <cfset VARIABLES.businessPendingEventRequests = val(qBusinessPendingWorkspaceProgress.solicitacoes_evento_pendentes)/>
    </cfif>
    <cfcatch type="any"></cfcatch>
  </cftry>
</cfif>

<style>
    .pending-workspace {
        --pending-accent: #fab120;
        background: linear-gradient(145deg, rgba(250, 177, 32, .08), rgba(255, 255, 255, .025) 42%);
        border: 1px solid rgba(250, 177, 32, .28);
        border-radius: .75rem;
        overflow: hidden;
    }

    .pending-workspace-header {
        border-bottom: 1px solid rgba(255, 255, 255, .08);
        padding: 1.5rem;
    }

    .pending-workspace-status {
        align-items: center;
        background: rgba(250, 177, 32, .12);
        border: 1px solid rgba(250, 177, 32, .25);
        border-radius: 999px;
        color: var(--pending-accent);
        display: inline-flex;
        font-size: .78rem;
        font-weight: 700;
        gap: .45rem;
        padding: .35rem .65rem;
        text-transform: uppercase;
    }

    .pending-workspace-status i {
        background: var(--pending-accent);
        border-radius: 50%;
        height: .5rem;
        width: .5rem;
    }

    .pending-workspace-title {
        font-family: "Barlow Condensed", sans-serif;
        font-size: clamp(2rem, 4vw, 3.5rem);
        font-weight: 800;
        line-height: .95;
        margin: 1rem 0 .65rem;
        text-transform: uppercase;
    }

    .pending-workspace-lead {
        color: rgba(255, 255, 255, .66);
        margin: 0;
        max-width: 760px;
    }

    .pending-workspace-grid {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        padding: 1.5rem;
    }

    .pending-workspace-step {
        background: rgba(255, 255, 255, .035);
        border: 1px solid rgba(255, 255, 255, .09);
        border-radius: .65rem;
        display: flex;
        flex-direction: column;
        min-height: 210px;
        padding: 1.1rem;
    }

    .pending-workspace-step.is-done {
        border-color: rgba(40, 167, 69, .35);
    }

    .pending-workspace-step.is-locked {
        opacity: .72;
    }

    .pending-workspace-step-top {
        align-items: center;
        display: flex;
        justify-content: space-between;
        margin-bottom: .85rem;
    }

    .pending-workspace-step-number {
        align-items: center;
        border: 1px solid rgba(255, 255, 255, .16);
        border-radius: 50%;
        display: inline-flex;
        font-weight: 800;
        height: 2rem;
        justify-content: center;
        width: 2rem;
    }

    .pending-workspace-step.is-done .pending-workspace-step-number {
        background: #198754;
        border-color: #198754;
    }

    .pending-workspace-step-state {
        color: rgba(255, 255, 255, .5);
        font-size: .72rem;
        font-weight: 700;
        text-transform: uppercase;
    }

    .pending-workspace-step h2 {
        font-size: 1.15rem;
        margin-bottom: .45rem;
    }

    .pending-workspace-step p {
        color: rgba(255, 255, 255, .58);
        font-size: .9rem;
        margin-bottom: 1rem;
    }

    .pending-workspace-step-action {
        margin-top: auto;
    }

    .pending-workspace-footnote {
        color: rgba(255, 255, 255, .5);
        font-size: .8rem;
        padding: 0 1.5rem 1.5rem;
    }

    @media (max-width: 767.98px) {
        .pending-workspace-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<section class="pending-workspace" aria-labelledby="pending-workspace-title">
    <header class="pending-workspace-header">
        <span class="pending-workspace-status"><i aria-hidden="true"></i> Conta em análise</span>
        <h1 class="pending-workspace-title" id="pending-workspace-title">Você já está dentro.</h1>
        <p class="pending-workspace-lead">
            <cfif VARIABLES.businessPendingIsExistingAccountRequest>
                Seu pedido de acesso à conta <cfoutput><strong>#htmlEditFormat(VARIABLES.businessPendingAccountName)#</strong></cfoutput> foi enviado.
                Um OWNER da conta ou a equipe RunnerHub precisa aprovar sua entrada antes que as ferramentas sejam liberadas.
            <cfelse>
                <cfoutput><strong>#htmlEditFormat(VARIABLES.businessPendingAccountName)#</strong></cfoutput> está sendo validada, mas você não precisa parar.
                Prepare agora o evento e a publicidade; a publicação será liberada assim que a conta for aprovada.
            </cfif>
        </p>
    </header>

    <div class="pending-workspace-grid">
        <article class="pending-workspace-step is-done">
            <div class="pending-workspace-step-top">
                <span class="pending-workspace-step-number"><i class="fa-solid fa-check" aria-hidden="true"></i></span>
                <span class="pending-workspace-step-state">Concluído</span>
            </div>
            <h2>Conta solicitada</h2>
            <p>Seus dados e sua identidade Google foram recebidos. Você continuará exatamente daqui nos próximos acessos.</p>
            <div class="pending-workspace-step-action">
                <span class="badge badge-success">Protocolo <cfoutput>###htmlEditFormat(VARIABLES.businessPendingRegistrationId)#</cfoutput></span>
            </div>
        </article>

        <article class="pending-workspace-step<cfif VARIABLES.businessPendingEventRequests GT 0> is-done<cfelseif VARIABLES.businessPendingIsExistingAccountRequest OR NOT len(VARIABLES.businessPendingWorkspaceTargetAccountId)> is-locked</cfif>">
            <div class="pending-workspace-step-top">
                <span class="pending-workspace-step-number"><cfif VARIABLES.businessPendingEventRequests GT 0><i class="fa-solid fa-check" aria-hidden="true"></i><cfelse>2</cfif></span>
                <span class="pending-workspace-step-state"><cfif VARIABLES.businessPendingEventRequests GT 0>Solicitado<cfelseif len(VARIABLES.businessPendingWorkspaceTargetAccountId)>Faça agora<cfelse>Aguardando aprovação</cfif></span>
            </div>
            <h2><cfif VARIABLES.businessPendingIsExistingAccountRequest>Aguarde a liberação<cfelse>Vincule seu evento</cfif></h2>
            <p><cfif VARIABLES.businessPendingIsExistingAccountRequest>Assim que seu acesso for aprovado, você poderá operar os eventos autorizados para o seu papel.<cfelse>Encontre a prova no RoadRunners e peça o vínculo. Isso pode ser feito enquanto a conta está em análise.</cfif></p>
            <div class="pending-workspace-step-action">
                <cfif len(VARIABLES.businessPendingWorkspaceTargetAccountId) AND NOT VARIABLES.businessPendingIsExistingAccountRequest>
                    <a class="btn <cfif VARIABLES.businessPendingEventRequests GT 0>btn-outline-success<cfelse>btn-warning</cfif>" href="/eventos/#primeiro-evento">
                        <cfif VARIABLES.businessPendingEventRequests GT 0>Ver solicitação<cfelse>Vincular evento</cfif>
                        <i class="fa-solid fa-arrow-right ms-2" aria-hidden="true"></i>
                    </a>
                <cfelse>
                    <span class="btn btn-outline-light disabled">Conta sendo conferida</span>
                </cfif>
            </div>
        </article>

        <article class="pending-workspace-step<cfif VARIABLES.businessPendingIsExistingAccountRequest> is-locked<cfelseif listFind("RESERVED,APPLIED", VARIABLES.businessPendingVoucherStatus)> is-done</cfif>">
            <div class="pending-workspace-step-top">
                <span class="pending-workspace-step-number"><cfif listFind("RESERVED,APPLIED", VARIABLES.businessPendingVoucherStatus)><i class="fa-solid fa-check" aria-hidden="true"></i><cfelse>3</cfif></span>
                <span class="pending-workspace-step-state"><cfif VARIABLES.businessPendingIsExistingAccountRequest><i class="fa-solid fa-lock me-1" aria-hidden="true"></i> Aguardando acesso<cfelseif VARIABLES.businessPendingVoucherStatus EQ "RESERVED">Reservado<cfelseif VARIABLES.businessPendingVoucherStatus EQ "APPLIED">Aplicado<cfelse>Faça agora</cfif></span>
            </div>
            <h2>Reserve seu voucher</h2>
            <p><cfif VARIABLES.businessPendingIsExistingAccountRequest>O voucher poderá ser usado depois que seu acesso à conta existente for aprovado.<cfelseif VARIABLES.businessPendingVoucherStatus EQ "RESERVED">Seu voucher de <cfoutput>#lsCurrencyFormat(VARIABLES.businessPendingVoucherAmount)#</cfoutput> está reservado. O crédito será aplicado automaticamente após a aprovação da conta.<cfelseif VARIABLES.businessPendingVoucherStatus EQ "APPLIED">O crédito do voucher já foi aplicado à conta.<cfelse>Informe o código dentro de Publicidade. A reserva não altera o saldo enquanto a conta está em análise.</cfif></p>
            <div class="pending-workspace-step-action">
                <cfif VARIABLES.businessPendingIsExistingAccountRequest>
                    <span class="btn btn-outline-light disabled" aria-disabled="true">Aguardando acesso</span>
                <cfelse>
                    <a class="btn <cfif VARIABLES.businessPendingVoucherStatus EQ 'RESERVED'>btn-outline-success<cfelse>btn-warning</cfif>" href="/ads/?view=payments#ads-voucher-form"><cfif VARIABLES.businessPendingVoucherStatus EQ "RESERVED">Ver voucher reservado<cfelse>Reservar voucher</cfif><i class="fa-solid fa-arrow-right ms-2" aria-hidden="true"></i></a>
                </cfif>
            </div>
        </article>

        <article class="pending-workspace-step<cfif VARIABLES.businessPendingIsExistingAccountRequest OR VARIABLES.businessPendingEventRequests LTE 0> is-locked<cfelseif VARIABLES.businessPendingCampaignCount GT 0> is-done</cfif>">
            <div class="pending-workspace-step-top">
                <span class="pending-workspace-step-number"><cfif VARIABLES.businessPendingCampaignCount GT 0><i class="fa-solid fa-check" aria-hidden="true"></i><cfelse>4</cfif></span>
                <span class="pending-workspace-step-state">
                    <cfif VARIABLES.businessPendingIsExistingAccountRequest><i class="fa-solid fa-lock me-1" aria-hidden="true"></i> Aguardando acesso
                    <cfelseif VARIABLES.businessPendingEventRequests LTE 0><i class="fa-solid fa-lock me-1" aria-hidden="true"></i> Vincule um evento primeiro
                    <cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "WAITING_PREREQUISITES">Aguardando pré-requisitos
                    <cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "PENDING_REVIEW">Em análise
                    <cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "CHANGES_REQUESTED">Ajustes solicitados
                    <cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "APPROVED">Aprovada
                    <cfelseif VARIABLES.businessPendingCampaignCount GT 0>Rascunho salvo
                    <cfelse>Faça agora</cfif>
                </span>
            </div>
            <h2>Prepare a campanha</h2>
            <p><cfif VARIABLES.businessPendingIsExistingAccountRequest>A publicidade será liberada depois que o OWNER da conta ou a RunnerHub aprovar seu acesso.<cfelseif VARIABLES.businessPendingEventRequests LTE 0>Solicite primeiro o vínculo de uma prova para preparar a publicidade desse evento.<cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "CHANGES_REQUESTED">A RunnerHub solicitou ajustes.<cfif len(VARIABLES.businessPendingCampaignReviewReason)> <cfoutput>#htmlEditFormat(VARIABLES.businessPendingCampaignReviewReason)#</cfoutput></cfif><cfelseif VARIABLES.businessPendingCampaignReviewStatus EQ "PENDING_REVIEW">A conta e o evento já foram aprovados; agora a RunnerHub está analisando o anúncio.<cfelse>Escolha período, locais e orçamento agora. A campanha ficará em rascunho ou espera até concluir todas as aprovações.</cfif></p>
            <div class="pending-workspace-step-action">
                <cfif VARIABLES.businessPendingIsExistingAccountRequest>
                    <span class="btn btn-outline-light disabled" aria-disabled="true">Aguardando acesso</span>
                <cfelseif VARIABLES.businessPendingEventRequests LTE 0>
                    <span class="btn btn-outline-light disabled" aria-disabled="true">Vincule um evento primeiro</span>
                <cfelseif VARIABLES.businessPendingCampaignCount GT 0>
                    <a class="btn btn-warning" href="/ads/?view=campaigns"><cfif VARIABLES.businessPendingCampaignReviewStatus EQ "CHANGES_REQUESTED">Corrigir campanha<cfelse>Acompanhar campanha</cfif><i class="fa-solid fa-arrow-right ms-2" aria-hidden="true"></i></a>
                <cfelse>
                    <a class="btn btn-warning" href="/ads/?view=campaigns&amp;mode=new#campaign-form">Preparar campanha<i class="fa-solid fa-arrow-right ms-2" aria-hidden="true"></i></a>
                </cfif>
            </div>
        </article>
    </div>

    <p class="pending-workspace-footnote mb-0">
        <i class="fa-solid fa-shield-halved me-1" aria-hidden="true"></i>
        Você pode preparar tudo agora. O voucher só vira saldo após a aprovação da conta, e a campanha só poderá entrar no ar após a aprovação da conta, do evento e da equipe RunnerHub.
    </p>
</section>
