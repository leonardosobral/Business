<cfif NOT structKeyExists(VARIABLES,"helpdeskCanManage") OR NOT VARIABLES.helpdeskCanManage><cfabort/></cfif>
<cfif NOT structKeyExists(SESSION,"helpdeskAICsrf")>
  <cfset SESSION.helpdeskAICsrf=lCase(hash(generateSecretKey("AES",256),"SHA-256"))/>
</cfif>
<div class="border rounded-3 p-3 mb-3" data-helpdesk-ai data-endpoint="/helpdesk/ai-draft.cfm" data-csrf="<cfoutput>#encodeForHTMLAttribute(SESSION.helpdeskAICsrf)#</cfoutput>">
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2">
    <div>
      <span class="fw-semibold"><i class="fa-solid fa-wand-magic-sparkles text-warning me-2" aria-hidden="true"></i>Assistente de resposta</span>
      <div class="small text-muted mt-1">Histórico do chamado + conhecimento do sistema + base RAG da Vicky.</div>
    </div>
    <button type="button" class="btn btn-outline-warning btn-sm" data-ai-generate>Criar resposta com IA</button>
  </div>
  <details class="mt-2 small">
    <summary>Orientar a IA <span class="text-muted">(opcional)</span></summary>
    <label for="helpdesk-ai-note" class="form-label mt-2">Informações confirmadas ou orientação para a resposta</label>
    <textarea id="helpdesk-ai-note" class="form-control" rows="2" maxlength="1500" data-ai-note placeholder="Ex.: já conferi o resultado oficial; pedir apenas a edição da prova que está faltando."></textarea>
  </details>
  <p class="small text-muted mt-2 mb-0">O rascunho não é enviado automaticamente. Revise os dados e ajuste o texto antes de enviar. O contexto é processado pela integração OpenAI existente.</p>
  <div class="small mt-2" role="status" aria-live="polite" aria-atomic="true" data-ai-status></div>
  <div class="small mt-2" data-ai-sources hidden></div>
  <div class="mt-2" data-ai-pending hidden>
    <label for="helpdesk-ai-preview" class="form-label small">Sugestão pronta · seu texto atual foi preservado</label>
    <textarea id="helpdesk-ai-preview" class="form-control mb-2" rows="6" readonly data-ai-preview></textarea>
    <button type="button" class="btn btn-outline-warning btn-sm" data-ai-apply>Usar sugestão no editor</button>
    <button type="button" class="btn btn-link btn-sm" data-ai-discard>Descartar sugestão</button>
  </div>
  <button type="button" class="btn btn-link btn-sm px-0 mt-2" data-ai-undo hidden>Recuperar texto anterior</button>
</div>
<script src="/helpdesk/assets/ai-draft.js?v=20260913-1" defer></script>
