<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0>
  <cfheader statuscode="405" statustext="Method Not Allowed"/><cfabort/>
</cfif>
<h2 class="h5 mb-2">SEO para IA</h2>
<p class="seo-subtitle">Condições para que assistentes encontrem e leiam as páginas públicas. A auditoria está indicada em cada site; conferências complementares de traduções, logs e audiência informam suas próprias datas e escopos nos detalhes. A avaliação não comprova indexação, compreensão ou citação nas respostas.</p>
<p class="seo-note seo-report-note">Busca e treinamento têm controles independentes. Não é necessário liberar GPTBot para permitir a busca do ChatGPT. A nota técnica permanece na aba Relatório técnico; estes checks não criam uma pontuação de recomendação por IA.</p>
<div class="seo-checklist-grid mt-3">
  <cfloop array="#VARIABLES.seoScoreSnapshot.sites#" index="seoAiSite">
    <cfoutput>
    <section class="seo-checklist" aria-label="SEO para IA — #encodeForHtmlAttribute(seoAiSite.label)#">
      <h3 class="h5">#encodeForHtml(seoAiSite.label)#</h3>
      <p class="seo-note">Auditoria: #encodeForHtml(seoAiSite.auditLabel)# · #seoAiSite.inspected# páginas</p>
      <cfif NOT structKeyExists(seoAiSite,"aiChecks")>
        <p>Esta auditoria ainda não contém a avaliação para IA.</p>
      <cfelse>
        <cfloop array="#seoAiSite.aiChecks#" index="seoAiCheck">
          <cfif NOT listFind("pass,warning,error,unknown",seoAiCheck.status)><cfthrow type="SEOAIContract" message="Estado inválido no relatório para IA."/></cfif>
          <details class="seo-check seo-status-#encodeForHtmlAttribute(seoAiCheck.status)#">
            <summary>
              <span class="seo-check-icon" aria-hidden="true">#encodeForHtml(seoAiCheck.icon)#</span>
              <span class="seo-check-summary"><strong>#encodeForHtml(seoAiCheck.label)#</strong><span class="seo-check-summary-meta"><span class="seo-status-text">#encodeForHtml(seoAiCheck.statusLabel)#</span></span></span>
              <span class="seo-check-chevron" aria-hidden="true">›</span>
            </summary>
            <div class="seo-check-body">
              <p>#encodeForHtml(seoAiCheck.note)#</p>
              <cfif seoAiCheck.total GT 0>
                <p>#seoAiCheck.total# páginas: #seoAiCheck.pass# certas · #seoAiCheck.warning# com atenção · #seoAiCheck.error# com erro · #seoAiCheck.unknown# sem evidência conclusiva.</p>
              </cfif>
              <cfif arrayLen(seoAiCheck.cases)>
                <p>Exemplos com atenção, erro ou evidência incompleta:</p>
                <ul class="seo-urls">
                  <cfloop array="#seoAiCheck.cases#" index="seoAiUrl">
                    <cfif NOT reFindNoCase("^https://(roadrunners[.]run|openresults[.]run)/",seoAiUrl) OR reFind("[\x00-\x20\x7F\\]",seoAiUrl)><cfthrow type="SEOAIContract" message="URL inválida na avaliação para IA."/></cfif>
                    <li><a href="#encodeForHtmlAttribute(seoAiUrl)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(seoAiUrl)#</a></li>
                  </cfloop>
                </ul>
                <p class="seo-note">Exemplos limitados a três URLs exibíveis; as contagens incluem todos os casos avaliados.</p>
              </cfif>
            </div>
          </details>
        </cfloop>
      </cfif>
    </section>
    </cfoutput>
  </cfloop>
</div>
<details class="seo-method mt-3">
  <summary>Como interpretar e próximos passos</summary>
  <div class="seo-method-body">
    <p>✓ Certo confirma somente o critério descrito. Atenção indica uma regra ou entrega que merece revisão; pode ser intencional. Erro indica falha observada. Não medido indica ausência de evidência suficiente.</p>
    <p>Prioridades: conferir acesso real nos logs; validar fatos de eventos e resultados, dados estruturados e idiomas; registrar citações e visitas com data e fonte. A série histórica para IA começará com medições próprias; o histórico técnico existente continua na primeira aba.</p>
    <p>Não alteramos nesta etapa políticas de treinamento, robots.txt ou proteções de acesso.</p>
    <p>Referências: <a href="https://developers.openai.com/api/docs/bots" target="_blank" rel="noopener noreferrer">OpenAI</a> · <a href="https://docs.perplexity.ai/docs/resources/perplexity-crawlers" target="_blank" rel="noopener noreferrer">Perplexity</a> · <a href="https://developers.google.com/search/docs/appearance/ai-features" target="_blank" rel="noopener noreferrer">Google</a>.</p>
  </div>
</details>
