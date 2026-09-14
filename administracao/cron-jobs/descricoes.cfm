<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/administracao/cron-jobs/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="includes/description_status.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main style="margin-top:-55px;">
  <div class="container-fluid px-4 py-4">
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-4">
      <div>
        <h1 class="h3 mb-2">Descrições dos eventos</h1>
        <p class="text-body-secondary mb-0">Reescrita em português e traduções para inglês e espanhol.</p>
      </div>
      <a class="btn btn-sm btn-outline-secondary" href="./">Cron Jobs</a>
    </div>
    <cfif NOT VARIABLES.descriptionStatusReady>
      <div class="alert alert-warning" role="alert"><cfoutput>#encodeForHTML(len(VARIABLES.descriptionStatusError) ? VARIABLES.descriptionStatusError : "O processamento de traduções ainda não está instalado.")#</cfoutput></div>
    <cfelse>
      <cfoutput>
      <div class="row g-3 mb-4">
        <div class="col-12 col-md-6"><div class="card h-100"><div class="card-body">
          <div class="text-body-secondary">Etapas pendentes</div>
          <div class="display-6 fw-semibold">#numberFormat(VARIABLES.descriptionTotalPending,"9,999")#</div>
          <div class="small text-body-secondary">Inclui as próximas tentativas programadas.</div>
        </div></div></div>
        <div class="col-12 col-md-6"><div class="card h-100"><div class="card-body">
          <div class="text-body-secondary">Para revisão</div>
          <div class="display-6 fw-semibold">#numberFormat(VARIABLES.descriptionTotalReview,"9,999")#</div>
          <div class="small text-body-secondary">Rejeições e falhas que não terão nova tentativa automática.</div>
        </div></div></div>
      </div>
      <div class="card mb-3"><div class="card-body">
        <h2 class="h5 mb-3">Fila por idioma</h2>
        <div class="table-responsive">
          <table class="table align-middle mb-0">
            <thead><tr><th scope="col">Idioma</th><th scope="col">Prontas para processar</th><th scope="col">Aguardando nova tentativa</th><th scope="col">Para revisão</th></tr></thead>
            <tbody><cfloop array="#VARIABLES.descriptionStatusRows#" index="VARIABLES.descriptionRow">
              <tr><th scope="row">#encodeForHTML(VARIABLES.descriptionRow.language)#</th><td>#VARIABLES.descriptionRow.ready#</td><td>#VARIABLES.descriptionRow.waiting#</td><td>#VARIABLES.descriptionRow.review#</td></tr>
            </cfloop></tbody>
          </table>
        </div>
      </div></div>
      <p class="small text-body-secondary">Cada idioma é uma etapa. As traduções entram na fila quando a descrição em português está disponível; por isso o total pode aumentar conforme novos textos ficam prontos. Eventos futuros têm prioridade.</p>
      <cfif VARIABLES.descriptionJob.recordCount>
        <div class="d-flex flex-wrap align-items-center gap-3 mb-3">
          <span class="badge #VARIABLES.descriptionJob.ativo[1] ? 'text-bg-success' : 'text-bg-secondary'#">#VARIABLES.descriptionJob.ativo[1] ? 'Ativo' : 'Pausado'#</span>
          <span>A cada #VARIABLES.descriptionJob.interval_minutes[1]# minuto(s), uma etapa por execução.</span>
          <a href="./?job_id=#VARIABLES.descriptionJob.id_cron_job[1]#">Configurar ou pausar</a>
          <a href="./?aba=historico&amp;historico_job_id=#VARIABLES.descriptionJob.id_cron_job[1]###historico-recente">Ver histórico</a>
        </div>
      </cfif>
      <p class="small text-body-secondary mb-0">Atualizado em #dateTimeFormat(now(),"dd/mm/yyyy HH:nn:ss")#. A página atualiza a cada 30 segundos enquanto estiver visível. O processamento continua com o navegador fechado.</p>
      </cfoutput>
    </cfif>
  </div>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
<script>
setTimeout(function () { if (!document.hidden) window.location.reload(); }, 30000);
document.addEventListener('visibilitychange', function () { if (!document.hidden) window.location.reload(); });
</script>
</body>
</html>
