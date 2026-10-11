from pathlib import Path
import json
S=Path(__file__).resolve().parent
q=(S/'baseline/business/portal/includes/seo_queue_data.cfm').read_text()
q=q.replace('2026-10-08T19:10:18-03:00','2026-10-08T19:27:41-03:00').replace('08/10/2026 às 19:10 (Brasília)','08/10/2026 às 19:27 (Brasília)')
items='''        {
            resolved = true,
            id = "RR-35", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Páginas de maratonas",
            title = "Identificar as páginas de maratonas com um H1",
            summary = "Quarenta e sete páginas de maratonas passaram a apresentar um título principal H1, usando o cabeçalho já existente e mantendo sua aparência.",
            impact = "Identifica o assunto principal dessas páginas no HTML e melhora a estrutura acessível; não comprova ganho de ranking.",
            owner = "RoadRunners — cabeçalho compartilhado de temas",
            rule = "semrush.103; content.heading",
            evidence = "A auditoria concluída em 06/10 apontava 14 páginas sem H1, incluindo a Maratona Internacional de São Paulo. Consulta somente leitura ao catálogo identificou 47 maratonas com tag; todas responderam 200 e tinham zero H1 antes da correção. O cabeçalho existente já fornecia H1 para organizadores, cronometristas e circuitos; a condição passou a incluir apenas /maratona/. Vinte cenários Adobe passaram antes e após publicação: quatro casos de maratona, com e sem tema e em modo compacto/normal, mais 16 controles de outros tipos. Um template compilado e publicado com backup recuperável; 12 dependências preservadas por hash. Conferência pública após publicação: 47 respostas 200 com exatamente um H1 e nome cadastrado, e oito controles com status e metadados preservados. Títulos, descrições, canonical e alternates das 47 páginas preservados. Desktop 1280 e celular 390: H1 confirmado, dimensões do cabeçalho iguais ao baseline e sem overflow horizontal. Nenhum cadastro, evento, resultado, consulta de listagem ou autenticação alterado. A nova auditoria de 5.000 páginas foi iniciada em 08/10 antes desta publicação; pode alcançar a versão anterior em parte das URLs. Contadores permanecem os da coleta de 06/10 até nova conclusão.",
            acceptance = "Publicado e verificado em 08/10 em todas as 47 páginas com tag. Semrush classificava a ausência de H1 como advertência, não um dos 27 erros. Medir sua baixa após rastreamento; separar as páginas de outros sistemas.",
            urls = [{url = "https://roadrunners.run/maratona/maratona-internacional-de-sao-paulo/", label = "Maratona Internacional de São Paulo"}, {url = "https://roadrunners.run/maratona/maratona-de-aracaju/", label = "Maratona de Aracaju"}],
            stateLabel = "Publicado — 47 páginas com H1; aguardando reauditoria"
        },
        {
            resolved = false,
            id = "RR-36", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Metadados da loja",
            title = "Corrigir títulos e descrições na plataforma da loja",
            summary = "Quatro páginas da loja tinham título igual e seis compartilhavam a descrição na auditoria de 06/10. A correção pertence à aplicação externa que serve store.roadrunners.run.",
            impact = "Distingue catálogo, conta e páginas institucionais e esclarece quais páginas da loja devem participar da busca.",
            owner = "Plataforma externa da Road Runners Store",
            rule = "semrush.6; semrush.15",
            evidence = "Inspeção em 08/10 das seis URLs detalhadas pelo Semrush e da raiz da loja: respostas finais 200, com quatro títulos Road Runners Store e uma descrição comum nas seis páginas. A raiz faz 301 e 302 até /roadrunnersstore/inactive; essa página retorna X-Robots-Tag noindex. Catálogo, sua página 2 e login mantêm o título igual; política de privacidade e termos têm títulos distintos, mas usam a mesma descrição. O servidor público informa Heroku e não há vhost store.roadrunners.run no Apache RunnerHub conferido. Não foi localizado o código da aplicação da loja neste projeto. Os dados atuais não autorizam concluir que todas as páginas da loja estão fora da busca nem que a página inactive representa os demais caminhos.",
            acceptance = "Revisar o tema/editor da plataforma da loja: títulos e descrições por finalidade, política de indexação para login e inactive, e consistência entre catálogo e paginação. Validar respostas públicas e confirmar a baixa na auditoria de 5.000 páginas. A entrega depende de acesso à plataforma responsável, indisponível nesta sessão.",
            urls = [],
            stateLabel = "Pendente — depende da plataforma da loja"
        },
'''
needle='    items = [\n';assert q.count(needle)==1;q=q.replace(needle,needle+items)
q=q.replace('quatro títulos e seis descrições da loja aguardam revisão.','quatro títulos e seis descrições da loja seguem no RR-36.')
q=q.replace('Descrições e títulos da loja exigem revisão da plataforma que os serve.','Descrições e títulos da loja estão detalhados em RR-36: inspeção pública confirmou aplicação externa ao Apache RunnerHub.')
(S/'candidate/business/portal/includes/seo_queue_data.cfm').write_text(q)
v=(S/'baseline/business/portal/conteudo/seo_semrush.cfm').read_text()
v=v.replace('<h3 class="h6">Auditoria concluída · resultados da amostra</h3>','<h3 class="h6">Última auditoria concluída · resultados da amostra</h3>')
needle='  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"comparison")>'
note='''  <p class="seo-note"><strong>Nova auditoria iniciada em 08/10:</strong> a campanha de 5.000 páginas estava rastreando na última consulta. Os números acima continuam os da conclusão de 06/10. Correção adicional publicada em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-35">RR-35</a>: 47 páginas de maratonas agora têm um H1; essa ausência era advertência. A publicação ocorreu durante o rastreamento e pode exigir outra coleta para confirmação integral. Os títulos e descrições da <a href="https://store.roadrunners.run/roadrunnersstore/products" target="_blank" rel="noopener noreferrer">loja externa</a> seguem em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-36">RR-36</a>.</p>
'''
assert v.count(needle)==1;(S/'candidate/business/portal/conteudo/seo_semrush.cfm').write_text(v.replace(needle,note+needle))
print(json.dumps({'runtime_files':2,'resolved':'RR-35','external_pending':'RR-36','audit_and_organic_snapshot':'unchanged'}))
