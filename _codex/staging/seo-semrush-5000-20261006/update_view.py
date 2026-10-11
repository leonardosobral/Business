from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import re

P=Path(__file__).resolve().parent
view=P/'candidate/business/portal/conteudo/seo_semrush.cfm'
s=(P/'baseline/business/portal/conteudo/seo_semrush.cfm').read_text()
s=s.replace('Esta rodada tem amostra e configurações diferentes das anteriores de 500 páginas; a diferença de notas não mede uma piora ou melhora comparável.', 'Comparativo disponível com a rodada anterior de 5.000 páginas. As auditorias de 500 páginas ficam no histórico, por terem outro limite e outras configurações observadas.')
start=s.index('  <p class="seo-note"><strong>Prioridades da auditoria')
end=s.index('  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"errorsByType")',start)
old_deliveries=s[start:end]
old_deliveries=old_deliveries[old_deliveries.index('  <p class="seo-note"><strong>Correções publicadas'):]
old_deliveries=old_deliveries.replace('Correções publicadas após esta auditoria:', 'Correções após a auditoria de 05/10:')
old_deliveries=old_deliveries.replace('As 126 ocorrências de erro e as notas acima continuam sendo as da coleta concluída em 05/10 às 01:37; a próxima auditoria deve medir o efeito das correções.', 'Aquela rodada tinha 126 ocorrências de erro. O comparativo de 06/10 acima apresenta o novo rastreamento.')
old_deliveries=old_deliveries.replace('Os contadores Semrush acima continuam históricos; indexação e ranking no Google ainda não foram medidos.', 'O comparativo do fornecedor marcou os 62 casos anteriores de título duplicado como corrigidos. Indexação e ranking no Google têm acompanhamento próprio.')
old_deliveries=old_deliveries.replace('os totais da auditoria permanecem históricos.', 'estes limites foram preservados na reauditoria.')
s=s[:start]+'''  <p class="seo-note"><strong>Pendências da auditoria de 06/10:</strong> 12 links internos quebrados, seis páginas com títulos duplicados, seis com descrições duplicadas, duas com HTTP 4xx e um conflito de hreflang. Os títulos novos são duas edições da Night Run Vitória e quatro URLs da loja; as seis descrições repetidas estão na loja. Os dois 4xx são o perfil protegido (403) e a proteção de e-mail (404). Revisão por URL e próximos passos em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-20">RR-20</a>.</p>
  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"comparison")>
  <p class="seo-note"><strong>Evolução medida:</strong> Site Health de 69% para 75% e erros de 126 para 27 (99 a menos). O fornecedor marcou 112 ocorrências anteriores de erro como corrigidas e encontrou 13 novas. Conteúdo duplicado, página não rastreada e página lenta chegaram a zero nesta amostra. Advertências aumentaram de 37.581 para 45.495, e a nota de IA passou de 81% para 78%.</p>
  <details class="seo-method"><summary>Comparar as duas auditorias de 5.000 páginas</summary><div class="seo-method-body">
    <p class="seo-note">#encodeForHtml(VARIABLES.seoSemrush.audit.comparison.previousLabel)# → #encodeForHtml(VARIABLES.seoSemrush.audit.comparison.currentLabel)#. #encodeForHtml(VARIABLES.seoSemrush.audit.comparison.note)#</p>
    <div class="sr-table-wrap" tabindex="0" role="region" aria-label="Comparação das auditorias Semrush"><table>
      <caption class="visually-hidden">Comparação dos rastreamentos de 05 e 06 de outubro de 2026.</caption>
      <thead><tr><th scope="col">Métrica ou grupo</th><th scope="col">05/10</th><th scope="col">06/10</th><th scope="col">Variação</th><th scope="col">Corrigidos</th><th scope="col">Novos</th></tr></thead><tbody>
      <cfloop array="#VARIABLES.seoSemrush.audit.comparison.rows#" index="srCompare"><tr>
        <th scope="row">#encodeForHtml(srCompare.label)#</th><td>#LSNumberFormat(srCompare.previous,"9,999")#</td><td>#LSNumberFormat(srCompare.current,"9,999")#</td>
        <td><span class="seo-label seo-status-#encodeForHtmlAttribute(srCompare.tone)# seo-status-badge">#encodeForHtml(srCompare.deltaLabel)#</span></td>
        <td><cfif srCompare.fixedLabel EQ "—">—<cfelse>#LSNumberFormat(val(srCompare.fixedLabel),"9,999")#</cfif></td><td><cfif srCompare.newLabel EQ "—">—<cfelse>#LSNumberFormat(val(srCompare.newLabel),"9,999")#</cfif></td>
      </tr></cfloop>
      </tbody></table></div>
    <p class="seo-note">Corrigidos e novos são as classificações do comparativo Semrush. Os seis títulos e as seis descrições atuais são novos casos; o aumento das advertências inclui URLs e recursos encontrados nesta rodada. Zero em um grupo vale para a amostra rastreada.</p>
  </div></details>
  </cfif>
''' +s[end:]
s=s.replace('Snapshot #encodeForHtml(VARIABLES.seoSemrush.audit.snapshotId)#. Contadores importados pela API; notas e configurações conferidas na interface do Semrush.', 'Campanha #VARIABLES.seoSemrush.audit.projectId# · auditoria de #encodeForHtml(VARIABLES.seoSemrush.audit.lastFinishedLabel)#. Contadores, comparativo, notas e configurações lidos na interface autenticada do Semrush no Chrome. Horário de conclusão informado com precisão de minuto. <a href="#encodeForHtmlAttribute(VARIABLES.seoSemrush.audit.sourceUrl)#" target="_blank" rel="noopener noreferrer">Abrir esta campanha ↗</a>.')
s=s.replace('<tr><td>Erro</td><td>#encodeForHtml(srAuditIssue.label)#</td><td>#LSNumberFormat(srAuditIssue.count,"9,999")#</td></tr>', '<tr><td><cfif srAuditIssue.count EQ 0><span class="seo-label seo-status-pass seo-status-badge">✓ Zero na amostra</span><cfelse>Erro</cfif></td><td>#encodeForHtml(srAuditIssue.label)#</td><td>#LSNumberFormat(srAuditIssue.count,"9,999")#</td></tr>')
s=s.replace('<summary>Histórico das auditorias de 500 páginas e entregas anteriores</summary><div class="seo-method-body">', '<summary>Histórico e correções publicadas antes desta auditoria</summary><div class="seo-method-body">\n'+old_deliveries)
s=s.replace('Primeira referência, sem série histórica comparável. O histórico técnico', 'Palavras-chave e tráfego estimado mantêm a coleta original de 04/10; não foram atualizados pela auditoria técnica de 06/10. O histórico técnico')
view.write_text(s)
q=P/'candidate/business/portal/includes/seo_queue_data.cfm'
s=(P/'baseline/business/portal/includes/seo_queue_data.cfm').read_text()
now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=re.sub(r'updatedAt = "[^"]+"', 'updatedAt = "'+now.isoformat(timespec='seconds')+'"',s,count=1)
s=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',s,count=1)
start=s.index('            resolved = false, id = "RR-20"')
end=s.index('        {\n            resolved = true, id = "RR-18"',start)
block=s[start:end]
block=block.replace('A amostra ampliada apontou 126 erros e 37.581 avisos. Primeiro lote de URLs e títulos publicado em RR-28; os demais grupos continuam em revisão.', 'Reauditoria de 06/10: Site Health 75%, 27 erros e 45.495 advertências. Erros caíram 99; seis títulos novos e seis descrições da loja continuam em revisão.')
evidence='Reauditoria concluída em 06/10/2026 às 17:20 (Brasília), campanha 26661911, lida no Chrome autenticado: 5.000/5.000 páginas, Site Health 75%, pesquisa IA 78%, 27 erros, 45.495 advertências e 2.328 observações. Comparativo com 05/10 às 01:37: saúde 69 para 75, erros 126 para 27; 112 ocorrências antigas marcadas como corrigidas e 13 novas. Títulos 62 para 6, sendo os 62 anteriores corrigidos e seis novos: Night Run Vitória 2025/2026 e quatro URLs store.roadrunners.run. Conteúdo duplicado oito para zero; links internos quebrados 35 para 12 (24 corrigidos e um novo); HTTP 4xx 14 para dois. Descrições quatro para seis: quatro anteriores corrigidas e seis novas, todas na loja. Página não rastreada e lenta uma para zero; conflito de hreflang uma para uma. Limite, rastreador móvel e ausência de renderização JS coincidem nas duas rodadas; o conjunto de URLs mudou, com novas páginas da loja. Os dois 4xx detalhados continuam sendo o perfil protegido (403) e o endpoint Cloudflare de proteção de e-mail (404). Autenticação e proteção não foram removidas. Redirecionamentos temporários 26.249 para 27.850 e recursos sem minificação 6.394 para 11.995 concentram os avisos. O comparativo diferencia problemas corrigidos de recém-encontrados; nota técnica e queda de erros não comprovam indexação ou ganho de posição. A coleta orgânica de 04/10 foi preservada. '
block=block.replace('            evidence = "','            evidence = "'+evidence,1)
block=re.sub(r'            acceptance = "[^"]*",', '            acceptance = "Priorizar a revisão dos metadados da Night Run Vitória, do conflito hreflang e das origens dos 12 links quebrados. Descrições e títulos da loja exigem revisão da plataforma que os serve. Investigar recursos repetidos e redirects com amostras por URL; preservar perfis privados e proteção. Medir indexação e ranking no Search Console separadamente. Repetir 5.000 páginas após um novo lote publicado para acompanhar a baixa dos casos atuais.",',block,count=1)
block=block.replace('Auditoria ampliada importada — correções parciais publicadas', 'Reauditoria de 06/10 importada — 99 erros a menos; 27 pendentes')
s=s[:start]+block+s[end:]
q.write_text(s)
print('View and queue refreshed; historical deliveries preserved.')
