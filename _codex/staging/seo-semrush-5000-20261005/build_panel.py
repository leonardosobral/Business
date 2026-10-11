from pathlib import Path
import importlib.util,json,shutil,re
from datetime import datetime
from zoneinfo import ZoneInfo
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
spec=importlib.util.spec_from_file_location('snapshot',ROOT/'_codex/scripts/seo_semrush_snapshot.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
source=json.loads(Path('/Users/Shared/RunnerHubReports/seo/semrush/roadrunners/20261004T171554Z/baseline.json').read_text())
audit=json.loads(Path('/private/tmp/seo-5000-audit-state.json').read_text())
snapshot=mod.build_snapshot(source,audit)
a=snapshot['audit'];assert a['status']=='complete' and a['crawled']==5000 and a['errors']==126
# Health scores and crawl settings read in the authenticated Semrush interface for this snapshot.
a.update(siteHealth=69,aiHealth=81,snapshotId='6ac31bf647d73ceec1b0b861',deviceLabel='Móvel',javascriptRendered=False,settingsChanged=True,
 scoreSource='Semrush — interface autenticada, auditoria 6ac31bf647d73ceec1b0b861',
 errorsByType=[{'label':'Grupos de títulos duplicados','count':62},{'label':'Links internos quebrados','count':35},{'label':'Páginas com HTTP 4xx','count':14},{'label':'Grupos de conteúdo duplicado','count':8},{'label':'Descrições duplicadas','count':4},{'label':'Página não rastreada','count':1},{'label':'Conflito hreflang','count':1},{'label':'Página lenta','count':1}],
 warningsByType=[{'label':'Redirecionamentos temporários','count':26249},{'label':'Recursos sem minificação','count':6394},{'label':'Baixa proporção de texto/HTML','count':3628},{'label':'Links internos nofollow','count':632},{'label':'Títulos longos','count':520}])
assert sum(x['count'] for x in a['errorsByType'])==a['errors']
for name in ['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']:
 dest=P/'candidate/business'/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/'baseline/business'/name,dest)
(P/'candidate/business/portal/includes/seo_semrush_data.cfm').write_text(mod.render_cfml(snapshot))
view=P/'candidate/business/portal/conteudo/seo_semrush.cfm';s=view.read_text()
s=s.replace('.seo-semrush .sr-metric {','.seo-semrush .sr-audit-metrics { grid-template-columns:repeat(2,minmax(0,1fr)); }\n.seo-semrush .sr-metric {',1)
s=s.replace('#VARIABLES.seoSemrush.audit.crawled# páginas rastreadas.','#LSNumberFormat(VARIABLES.seoSemrush.audit.crawled,"9,999")# páginas rastreadas.')
s=s.replace('    <p class="seo-note mb-0">Estado consultado', '''    <cfif VARIABLES.seoSemrush.audit.status EQ "complete" AND structKeyExists(VARIABLES.seoSemrush.audit,"siteHealth") AND structKeyExists(VARIABLES.seoSemrush.audit,"aiHealth")>
      <dl class="sr-metrics sr-audit-metrics">
        <div class="sr-metric"><dt>Site Health Semrush · amostra técnica</dt><dd>#VARIABLES.seoSemrush.audit.siteHealth#%</dd></div>
        <div class="sr-metric"><dt>Estado de pesquisa IA · Semrush</dt><dd>#VARIABLES.seoSemrush.audit.aiHealth#%</dd></div>
      </dl>
      <p class="seo-note">Limite de #LSNumberFormat(VARIABLES.seoSemrush.audit.limit,"9,999")# páginas atingido · rastreador móvel · sem renderização JavaScript. Esta rodada tem amostra e configurações diferentes das anteriores de 500 páginas; a diferença de notas não mede uma piora ou melhora comparável. As notas não comprovam indexação no Google, audiência nem uso por assistentes de IA.</p>
    </cfif>
    <p class="seo-note mb-0">Estado consultado''')
start=s.index('  <p class="seo-note"><strong>Comparação das auditorias')
end=s.index('  <nav class="sr-nav"',start)
s=s[:start]+'''  <p class="seo-note"><strong>Prioridades da auditoria de 5.000 páginas:</strong> 62 grupos de títulos duplicados, 35 links internos quebrados e 14 páginas com HTTP 4xx. Redirecionamentos temporários somam 26.249 ocorrências e concentram 69,8% dos avisos. Os grupos e ocorrências não correspondem a páginas únicas. A revisão por URL segue em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-20">RR-20</a>.</p>
  <p class="seo-note"><strong>Correções publicadas após esta auditoria:</strong> links de eventos com caracteres especiais, três variantes de maiúsculas, links de cinco assessorias, canonical/alternates e títulos das etapas com o mesmo nome em datas diferentes. Conferências públicas e limites em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-28">RR-28</a>. As 126 ocorrências de erro e as notas acima continuam sendo as da coleta concluída em 05/10 às 01:37; a próxima auditoria deve medir o efeito das correções.</p>
  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"errorsByType") AND structKeyExists(VARIABLES.seoSemrush.audit,"warningsByType")>
  <details class="seo-method"><summary>Grupos de erros e principais avisos desta auditoria</summary><div class="seo-method-body">
    <div class="sr-table-wrap" tabindex="0" role="region" aria-label="Grupos da auditoria Semrush"><table>
      <caption class="visually-hidden">Erros e principais avisos da auditoria Semrush de 5.000 páginas.</caption>
      <thead><tr><th scope="col">Tipo</th><th scope="col">Grupo</th><th scope="col">Ocorrências</th></tr></thead><tbody>
      <cfloop array="#VARIABLES.seoSemrush.audit.errorsByType#" index="srAuditIssue"><tr><td>Erro</td><td>#encodeForHtml(srAuditIssue.label)#</td><td>#LSNumberFormat(srAuditIssue.count,"9,999")#</td></tr></cfloop>
      <cfloop array="#VARIABLES.seoSemrush.audit.warningsByType#" index="srAuditIssue"><tr><td>Aviso</td><td>#encodeForHtml(srAuditIssue.label)#</td><td>#LSNumberFormat(srAuditIssue.count,"9,999")#</td></tr></cfloop>
      </tbody></table></div>
    <p class="seo-note">Snapshot #encodeForHtml(VARIABLES.seoSemrush.audit.snapshotId)#. Contadores importados pela API; notas e configurações conferidas na interface do Semrush. Saúde técnica e prontidão para IA são métricas próprias do fornecedor.</p>
  </div></details>
  </cfif>
  <details class="seo-method"><summary>Histórico das auditorias de 500 páginas e entregas anteriores</summary><div class="seo-method-body">
    <p class="seo-note">Comparação das auditorias de 04/10/2026, 14:39 e 15:40: Site Health Semrush de 68 para 76; erros de 114 para 9. Ambas rastrearam 500 páginas, com os mesmos limites e configurações observáveis. Hreflang passou de 42 para 0, descrições duplicadas de 27 para 0, problemas de sitemap de 4 para 0 e imagens quebradas de 1 para 0. Evidências: <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-17">RR-17</a>, <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-18">RR-18</a> e <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-19">RR-19</a>. Estes são resultados históricos de outra amostra.</p>
    <p class="seo-note">Entregas posteriores: ranking RR-21, metadados dos circuitos RR-22, recursos compactados RR-23, reconciliação ABAVSE RR-25, diretório experimental llms.txt RR-26, ALT e H1 RR-27. Fontes e medições continuam na fila. Disponibilidade permanece em RR-24; revisões factuais com fonte permanecem em SH-02.</p>
  </div></details>
''' +s[end:]
view.write_text(s)
q=P/'candidate/business/portal/includes/seo_queue_data.cfm';s=q.read_text()
now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=s.replace('updatedAt = "2026-10-04T19:30:42-03:00"','updatedAt = "'+now.isoformat(timespec='seconds')+'"').replace('updatedLabel = "04/10/2026 às 19:30 (Brasília)"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"')
start=s.index('        {\n            resolved = false, id = "RR-20"');end=s.index('        {\n            resolved = true, id = "RR-18"',start)
s=s[:start]+'''        {
            resolved = false, id = "RR-20", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Rastreamento e metadados",
            title = "Tratar os achados da auditoria Semrush de 5.000 páginas",
            summary = "A amostra ampliada apontou 126 erros e 37.581 avisos. Primeiro lote de URLs e títulos publicado em RR-28; os demais grupos continuam em revisão.",
            impact = "Prioriza links quebrados, páginas inacessíveis e sinais duplicados sem confundir nota técnica com indexação ou audiência.",
            owner = "RoadRunners — conteúdo, navegação e rastreamento",
            rule = "semrush.2; semrush.6; semrush.7; semrush.8; semrush.15; semrush.24; semrush.111",
            evidence = "Auditoria concluída em 05/10/2026 às 01:37 (Brasília), snapshot 6ac31bf647d73ceec1b0b861: 5.000/5.000 páginas, Site Health 69%, estado de pesquisa IA 81%, 126 erros, 37.581 avisos e 3.455 observações. Rastreador móvel e JavaScript sem renderização; configurações e amostra mudaram, portanto não comparar diretamente com 500 páginas. Erros: 62 grupos de títulos iguais, 35 links internos quebrados, 14 páginas 4xx, oito grupos de conteúdo duplicado, quatro descrições duplicadas, um não rastreado, um hreflang e um lento. Dos 35 links, 12 apontam a eventos com tags mal codificadas ou diferença de maiúsculas, cinco a assessorias no caminho inexistente /assessoria/, um a atleta com 403 e 17 à proteção de e-mail. Correções de geração de links, variantes de maiúsculas e títulos de etapas publicadas em RR-28. A revisão não abrangeu todos os 62 grupos. Redirecionamentos temporários (26.249), recursos sem minificação (6.394) e baixa proporção de texto/HTML (3.628) são os maiores grupos de avisos; não são correções independentes nem autorização para remover autenticação ou proteção.",
            acceptance = "Revisar os exemplos restantes por URL, preservando fatos e proteção de páginas privadas. Conferir o efeito do RR-28 em nova auditoria com as mesmas configurações e limite de 5.000; manter os totais e notas atuais até nova coleta. Estabilidade em RR-24 e indexação no Search Console têm medições próprias.",
            urls = [{url = "https://roadrunners.run/evento/2026-live-run-xp-sao-paulo-2026/", label = "LIVE São Paulo — títulos de etapas"}, {url = "https://roadrunners.run/timer/branca-esportes-saude-e-lazer/", label = "Assessoria — caminho válido"}, {url = "https://roadrunners.run/privacidade/", label = "Proteção de e-mail — revisão pendente"}],
            stateLabel = "Auditoria ampliada importada — correções parciais publicadas"
        },
''' +s[end:]
assert (P/'public-details-passed.json').exists(),'Public verification required before queue completion'
record='''        {
            resolved = true,
            id = "RR-28", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · URLs e etapas",
            title = "Corrigir links de eventos, assessorias e títulos de etapas",
            summary = "Links codificam os caracteres especiais das tags; variantes únicas de maiúsculas redirecionam; assessorias usam o caminho existente. Etapas com nome igual ganham a data já cadastrada no título.",
            impact = "Remove as referências malformadas confirmadas nesta amostra e distingue etapas diferentes nas buscas, sem alterar datas ou nomes no banco.",
            owner = "RoadRunners — links e metadados de eventos",
            rule = "semrush.2; semrush.6; semrush.8; event.encoded-tag; supplier.route",
            evidence = "Auditoria 6ac31bf647d73ceec1b0b861 apontou sete eventos e cinco assessorias com 404, associados a 17 dos links quebrados. Causa confirmada: aspas, quebra de linha e fragmento na tag sem codificação, três diferenças de maiúsculas e links para /assessoria/ quando a página real usa /timer/. Publicados sete arquivos em três lotes, com baseline, backups, compilação e preservação de quatro dependências. Testes isolados Adobe/PostgreSQL: lote inicial passou em 36 cenários; follow-up de canonical e alternates passou em 57, incluindo ambiguidade, POST, ações, caracteres especiais e idiomas; nove cenários do include real confirmaram destinos 301 sem repetição da origem. Quarenta e quatro verificações HTTP em produção: sete eventos 200, três variantes 301, quatro calendários e cinco assessorias 200, dezoito páginas das seis etapas LIVE São Paulo em PT/EN/ES com títulos distintos por data, canonical sem conversão da tag para minúsculas, alternates e data estruturada conferidos, seis redirects localizados e include direto 404. Conferidos os quatro links especiais e cinco links de assessoria na fonte publicada. Nenhuma alteração de cadastro, data, nome ou tag; proteção do atleta e de e-mail preservada. Alteração posterior à coleta, sem nova pontuação Semrush.",
            acceptance = "Correção publicada e verificada em 05/10. Encerrada a entrega deste lote; a próxima auditoria deve confirmar sua baixa nos grupos Semrush. Demais títulos, conteúdo duplicado, hreflang e links protegidos continuam no RR-20.",
            urls = [{url = "https://roadrunners.run/evento/2026-live-run-xp-sao-paulo-2026/", label = "LIVE São Paulo — título com data"}, {url = "https://roadrunners.run/estado/sp/ubatuba/", label = "Calendário com link codificado"}, {url = "https://roadrunners.run/timer/branca-esportes-saude-e-lazer/", label = "Assessoria — navegação corrigida"}],
            stateLabel = "Publicado e verificado — efeito Semrush ainda não medido"
        },
'''
s=s.replace('    items = [\n','    items = [\n'+record,1);q.write_text(s)
print(json.dumps({'keywords':len(snapshot['keywords']),'opportunities':len(snapshot['opportunities']),'audit':a['status'],'crawled':a['crawled'],'errors':a['errors'],'siteHealth':a['siteHealth']}))
