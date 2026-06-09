<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.pendingRegistrationName = isDefined("COOKIE.name") ? COOKIE.name : "Seu cadastro"/>
<cfset VARIABLES.pendingRegistrationEmail = isDefined("COOKIE.email") ? COOKIE.email : ""/>
<cfset VARIABLES.pendingRegistrationStatus = "PENDENTE"/>
<cfif isDefined("qBusinessPendingRegistration") AND qBusinessPendingRegistration.recordcount>
    <cfset VARIABLES.pendingRegistrationName = qBusinessPendingRegistration.nome_responsavel/>
    <cfset VARIABLES.pendingRegistrationEmail = qBusinessPendingRegistration.email_responsavel/>
    <cfset VARIABLES.pendingRegistrationStatus = uCase(trim(qBusinessPendingRegistration.status))/>
</cfif>

<cfset VARIABLES.pendingRegistrationBadge = "Cadastro em analise"/>
<cfset VARIABLES.pendingRegistrationTitle = "Sua solicitacao ainda esta pendente"/>
<cfset VARIABLES.pendingRegistrationMessage = "O login Google foi confirmado, mas a area Business so sera liberada depois que um admin aprovar a empresa e vincular sua conta."/>

<cfif VARIABLES.pendingRegistrationStatus EQ "APROVADA">
    <cfset VARIABLES.pendingRegistrationBadge = "Cadastro aprovado"/>
    <cfset VARIABLES.pendingRegistrationTitle = "Estamos concluindo o vinculo da sua conta"/>
    <cfset VARIABLES.pendingRegistrationMessage = "Sua solicitacao ja foi aprovada, mas este usuario ainda nao possui um vinculo ativo com a conta Business. Avise o suporte para concluirmos a associacao."/>
<cfelseif VARIABLES.pendingRegistrationStatus EQ "RECUSADA">
    <cfset VARIABLES.pendingRegistrationBadge = "Cadastro recusado"/>
    <cfset VARIABLES.pendingRegistrationTitle = "Esta solicitacao nao foi aprovada"/>
    <cfset VARIABLES.pendingRegistrationMessage = "Seu login Google foi confirmado, mas esta solicitacao nao liberou acesso ao Business. Voce pode enviar uma nova solicitacao com os dados revisados."/>
<cfelseif VARIABLES.pendingRegistrationStatus EQ "CANCELADA">
    <cfset VARIABLES.pendingRegistrationBadge = "Cadastro cancelado"/>
    <cfset VARIABLES.pendingRegistrationTitle = "Esta solicitacao foi cancelada"/>
    <cfset VARIABLES.pendingRegistrationMessage = "Seu login Google foi confirmado, mas esta solicitacao nao esta ativa. Envie uma nova solicitacao para que o time possa revisar os dados."/>
</cfif>

<cfinclude template="../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark">

<style>
  .business-pending-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    background:
      linear-gradient(180deg, rgba(7, 9, 13, .94), rgba(12, 15, 22, .98)),
      url('/assets/meta_imagem.jpg') center/cover no-repeat;
  }

  .business-pending-card {
    border: 1px solid rgba(255,255,255,.12);
    border-radius: 8px;
    background: rgba(18, 22, 31, .92);
  }

  .business-pending-detail {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: 8px;
    background: rgba(255,255,255,.035);
  }
</style>

<main class="business-pending-page text-light py-5">
  <div class="container" style="max-width: 860px;">
    <div class="business-pending-card p-4 p-lg-5">
      <div class="mb-4">
        <img src="/lib/images/runpro.svg" alt="Run Pro" style="height: 44px; max-width: 180px;"/>
      </div>

      <cfoutput>
      <span class="badge badge-warning mb-3">#htmlEditFormat(VARIABLES.pendingRegistrationBadge)#</span>
      <h1 class="h2 mb-3">#htmlEditFormat(VARIABLES.pendingRegistrationTitle)#</h1>
      <p class="text-muted mb-4">
        #htmlEditFormat(VARIABLES.pendingRegistrationMessage)#
      </p>
      </cfoutput>

      <div class="business-pending-detail p-3 mb-4">
        <cfif isDefined("qBusinessPendingRegistration") AND qBusinessPendingRegistration.recordcount>
          <cfoutput>
            <div class="fw-bold">#htmlEditFormat(qBusinessPendingRegistration.nome_empresa)#</div>
            <div class="small text-muted">Protocolo: #qBusinessPendingRegistration.id_solicitacao#</div>
            <div class="small text-muted">Responsavel: #htmlEditFormat(VARIABLES.pendingRegistrationName)#<cfif len(trim(VARIABLES.pendingRegistrationEmail))> - #htmlEditFormat(VARIABLES.pendingRegistrationEmail)#</cfif></div>
            <div class="small text-muted">Tipo: #htmlEditFormat(qBusinessPendingRegistration.tipo_prestador)#</div>
            <div class="small text-muted">Enviado em #dateTimeFormat(qBusinessPendingRegistration.data_criacao, "dd/mm/yyyy HH:nn")#</div>
          </cfoutput>
        <cfelse>
          <cfoutput>
            <div class="fw-bold">#htmlEditFormat(VARIABLES.pendingRegistrationName)#</div>
            <cfif len(trim(VARIABLES.pendingRegistrationEmail))>
              <div class="small text-muted">#htmlEditFormat(VARIABLES.pendingRegistrationEmail)#</div>
            </cfif>
          </cfoutput>
        </cfif>
      </div>

      <div class="d-flex flex-column flex-sm-row gap-2">
        <a class="btn btn-warning" href="/cadastro/">Enviar outra solicitacao</a>
        <a class="btn btn-outline-light" href="/logout.cfm">Sair</a>
      </div>
    </div>
  </div>
</main>

<script type="text/javascript" src="/assets/js/mdb.umd.min.js"></script>
<script type="text/javascript" src="/assets/plugins/js/all.min.js"></script>
<script type="text/javascript" src="/assets/js/script.js"></script>

</body>

</html>
