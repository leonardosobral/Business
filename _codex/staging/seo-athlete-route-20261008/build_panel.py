from pathlib import Path
import json
S=Path(__file__).resolve().parent
queue=S/'candidate/business/portal/includes/seo_queue_data.cfm';q=(S/'baseline/business/portal/includes/seo_queue_data.cfm').read_text()
q=q.replace('2026-10-08T18:55:46-03:00','2026-10-08T19:10:18-03:00').replace('08/10/2026 às 18:55 (Brasília)','08/10/2026 às 19:10 (Brasília)')
item='''        {
            resolved = true,
            id = "RR-34", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Erros de acesso",
            title = "Corrigir o 403 de URLs de atleta com espaço",
            summary = "A rota de atleta com espaço deixa de falhar no Apache em PT/EN/ES e volta ao fluxo de login já exigido pelo site. A classificação anterior como bloqueio de privacidade foi corrigida.",
            impact = "Elimina a falha de codificação apontada como HTTP 4xx e link interno quebrado, mantendo as permissões dos perfis.",
            owner = "RoadRunners — regras de URL na raiz e em /atleta/",
            rule = "semrush.2; semrush.4; routing.backreferences",
            evidence = "Relatório detalhado da auditoria de 06/10 consultado novamente em 08/10: um dos dois 4xx é a rota /atleta/ com espaço, vinculada no ranking Trail Run do Circuito Catarinense. O log Apache confirmou AH10411: espaço na query reescrita. A revisão anterior havia atribuído o 403 à proteção do perfil; essa causa não se confirmou. Adicionada a codificação das capturas nas três regras de atleta, sem alterar autenticação, privacidade, nomes ou tags no banco. Vinte e quatro cenários Apache passaram: espaços GET/HEAD nos três idiomas, sinais + e &, acentos, codificação literal, filtros, entrada direta, arquivos e diretórios. Após publicação de dois arquivos com backup recuperável, sete requisições públicas antes 403 responderam 302 para o login existente; quinze controles conservaram status, redirecionamentos e metadados. Dez dependências, incluindo os guards de login, preservadas por hash. Navegador anônimo confirmou a tela de login; nenhum perfil foi aberto ao Google. Os 27 erros e notas da auditoria de 06/10 continuam históricos até novo rastreamento.",
            acceptance = "Publicado e verificado em 08/10. Confirmar a baixa do 4xx e do link quebrado na próxima auditoria de 5.000 páginas. A proteção de e-mail e os metadados da loja permanecem fora desta correção.",
            urls = [{url = "https://roadrunners.run/circuitocatarinense/trailrun/", label = "Origem do link auditado"}],
            stateLabel = "Publicado — 403 corrigido; login preservado; aguardando reauditoria"
        },
'''
needle='    items = [\n';assert q.count(needle)==1;q=q.replace(needle,needle+item)
old='Os dois 4xx detalhados continuam sendo o perfil protegido (403) e o endpoint Cloudflare de proteção de e-mail (404). Autenticação e proteção não foram removidas.'
new='Os dois 4xx detalhados da coleta são a rota de atleta com espaço (403) e o endpoint Cloudflare de proteção de e-mail (404). Revisão em 08/10 corrigiu a classificação inicial do atleta: o 403 era AH10411 do Apache, não uma decisão de privacidade. Correção publicada em RR-34 retorna ao login 302 exigido pelo site, sem alterar permissões. A proteção de e-mail permanece.'
assert q.count(old)==1;q=q.replace(old,new)
q=q.replace('Night Run e alias hreflang corrigidos em RR-32; quatro títulos','Night Run e alias hreflang corrigidos em RR-32, 403 do atleta em RR-34; quatro títulos')
old='Os 12 links foram classificados: 11 apontam à proteção de e-mail Cloudflare e um ao perfil com acesso protegido; continuam contados pela auditoria, sem remoção de proteção.'
new='Dos 12 links da coleta, 11 apontam à proteção de e-mail Cloudflare e um à rota de atleta com espaço, cujo 403 foi corrigido em RR-34. A rota agora segue para o login existente; não tornou o perfil indexável. Os totais continuam os da coleta até reauditoria, e a proteção de e-mail foi preservada.'
assert q.count(old)==1;q=q.replace(old,new)
queue.write_text(q)
view=S/'candidate/business/portal/conteudo/seo_semrush.cfm';v=(S/'baseline/business/portal/conteudo/seo_semrush.cfm').read_text()
v=v.replace('Os dois 4xx são o perfil protegido (403) e a proteção de e-mail (404).','Os dois 4xx da coleta são a rota de atleta com espaço (403) e a proteção de e-mail (404). A revisão de 08/10 identificou falha de codificação no Apache e corrigiu o 403 em RR-34, mantendo o login exigido pelo site.')
v=v.replace('uma do perfil com acesso protegido.','uma da rota de atleta com espaço, corrigida em RR-34 sem ampliar acesso ao perfil.')
needle='  <cfif structKeyExists(VARIABLES.seoSemrush.audit,"comparison")>'
note='''  <p class="seo-note"><strong>Correção de acesso em 08/10:</strong> o 403 da rota de atleta com espaço vinha da codificação de URL no Apache. A correção nos três idiomas foi publicada e verificada; sete requisições antes 403 agora seguem para o login já exigido. A classificação anterior como bloqueio de privacidade foi corrigida. Evidências em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-34">RR-34</a>. Os 27 erros acima continuam sendo os da auditoria de 06/10; a baixa deste caso aguarda novo rastreamento.</p>
'''
assert v.count(needle)==1;view.write_text(v.replace(needle,note+needle))
print(json.dumps({'business_candidates':2,'queue_item':'RR-34','audit_counts':'preserved'}))
