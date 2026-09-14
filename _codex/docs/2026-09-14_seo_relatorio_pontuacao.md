# Relatório técnico e pontuação SEO — 14/09/2026

## Escopo autorizado

O usuário pediu que a tela do Business mostre também o que está certo, com check e cores para certo, atenção e erro, e uma pontuação estimada para acompanhar o progresso. A entrega amplia `/portal/conteudo/?visao=seo` no Business; os sites públicos continuam donos das correções. Preserva a fila existente e não altera o cron de tradução, tratado em outra frente.

## Contrato da nota

Nota técnica **interna**, de 0 a 100, baseada na auditoria datada de cada site. Não é nota do Google nem do WooRank e não estima ranking. A amostra não é estatisticamente representativa do universo de URLs. A descoberta do sitemap e a quantidade de páginas efetivamente analisadas aparecem separadas.

Cada critério tem um peso fixo. Seu estado é o pior resultado conhecido: certo recebe 100% do peso, atenção recebe 50%, erro recebe 0%. Critérios inteiramente não medidos ficam fora do denominador. Evidência desconhecida dentro de um critério permanece explícita na cobertura. A nota representa atendimento aos critérios na amostra, não a porcentagem de páginas saudáveis. Um único erro pode mudar o estado e a contribuição de todo o critério.

| Critério | Peso |
| --- | ---: |
| Resposta HTTP final 2xx | 15 |
| URL sem redirecionamento | 5 |
| Entrega final HTTPS | 5 |
| Título presente | 10 |
| H1 presente | 10 |
| Canonical único e válido | 15 |
| Canonical alinhado à URL de origem | 15 |
| Sem noindex nas diretivas observadas | 10 |
| Googlebot permitido no robots.txt observado | 10 |
| Sitemaps válidos e descoberta completa | 5 |

Múltiplos H1 aparecem como revisão editorial, sem peso. Meta description, hreflang, dados estruturados, Core Web Vitals e indexação/tráfego Google aparecem como não medidos e fora da nota. Ausência de noindex, resposta 200 e presença no sitemap não comprovam indexação. Redirect e canonical diferente são avisos para revisar intenção, não erros presumidos.

## Dados e histórico

O gerador operacional lê apenas relatórios completos privados, valida integridade e o hash do manifesto apontado por `latest-complete.json`, calcula os critérios e gera um include CFML com agregados e exemplos de URLs públicas. A página não lê relatórios privados nem executa coleta, e mantém os guards administrativos existentes.

O primeiro ponto é uma base reconstruída com o método atual a partir da auditoria anterior; não inventa uma série histórica. Correções direcionadas posteriores continuam na fila e não elevam automaticamente essa nota. Novas auditorias registram novos pontos. Variações somente são apresentadas como comparáveis com método, configuração, regras, escopo, coorte e cobertura compatíveis. Troca da amostra não é evolução comprovada.

A distribuição e as notas retêm todos os critérios. O filtro de verificações altera somente a lista de checks; os filtros existentes continuam restritos à fila de correções.

## Implementação e validação

- Gerador e testes: `_codex/scripts/seo_scorecard.mjs` e `_codex/tests/seo_scorecard.test.mjs`.
- Snapshot gerado: `portal/includes/seo_score_data.cfm`.
- Contrato e filtro: `portal/includes/seo_score_backend.cfm`.
- Relatório: `portal/conteudo/seo_report.cfm`, incluído pela view SEO existente.
- Validação: cálculos e integridade em Node, renderização/autorização/filtros em CFML, compilação Adobe e conferência de interface em desktop e mobile após publicação.

Os resultados das verificações e o registro de publicação estão abaixo.

## Revisão de comparabilidade

A revisão independente com Astra reproduziu um caso em que duas auditorias tinham a mesma quantidade de campos conhecidos, mas em URLs diferentes. A comparação foi corrigida para considerar quais URLs têm evidência conhecida em cada critério, incluindo sitemaps. Os estados certo/atenção/erro ficam fora dessa assinatura para permitir medir uma correção nas mesmas páginas. O cenário que trocava evidência entre páginas deixou de gerar uma melhora indevida; o reparo comprovado na mesma URL permanece comparável.

O histórico definitivo fica em `/Users/Shared/RunnerHubReports/seo/score-history`. A base experimental anterior à publicação foi preservada separadamente e não é apresentada como outro ponto de progresso.

## Publicação e resultado

Publicado em **14/09/2026 às 10:41:07 (Brasília)** em `https://business.roadrunners.run/portal/conteudo/?visao=seo`. Quatro arquivos de runtime, com backup recuperável em `/var/backups/seo-score-Business-ycv76bd7`. Hashes e metadados foram conferidos após upload; os cinco arquivos protegidos de fila, entrada e autorização permaneceram iguais ao baseline.

Verificação concluída: 37 testes Node; 23 cenários CFML distintos; quatro templates compilados no Adobe ColdFusion; nove consultas públicas GET/POST sem exposição dos dados. A interface autenticada mostrou duas notas, 32 verificações, dois pontos iniciais e sete frentes na fila. Filtro de erros mostrou uma verificação Road Runners e o estado vazio Open Results sem alterar notas ou fila. Desktop e mobile390 foram conferidos; URLs expansíveis não produziram rolagem horizontal. O viewport foi restaurado e a tela ficou aberta.

Baseline exibido: Road Runners 70,0, Open Results 87,5, ambos sobre amostras de 100 URLs de 13/09. Não é uma nova auditoria nem atualização automática após cada correção. A fila continua com quatro frentes concluídas e três pendentes. Nenhuma alteração nesta entrega foi feita no runtime RoadRunners/OpenResults, no cron de tradução ou no banco.

Recibo: `2026-09-14_seo_relatorio_publicacao.json`. Evidências privadas e fontes congeladas: `/Users/Shared/RunnerHubReports/seo/score-report-20260914`.

Para recuperação, conferir primeiro os hashes atuais com o recibo, restaurar a versão anterior de `portal/conteudo/seo.cfm` do backup e verificar a tela anterior. Os três includes novos podem permanecer sem uso ou ser removidos somente após confirmar que nenhuma outra publicação passou a depender deles. Não sobrescrever alterações concorrentes. Nenhum commit, branch, push ou PR foi criado.
