# SEO: idiomas institucionais e painel atualizado

Lote publicado e verificado em 03/10/2026. Continuação do plano SEO/SEO para IA, com revisão Astra e preservação das outras frentes.

## Entrega

- Sobre, Ajuda e Privacidade identificam a rota também em português. Nove destinos PT/EN/ES entregam HTTP 200 direto, canonical próprio e o mesmo conjunto de três idiomas mais x-default. Reciprocidade confirmada na auditoria posterior à publicação.
- Notícias com canonical diferente do próprio deixam de emitir hreflang para versões locais. A regra editorial de canonical na fonte, REQUEST.currentRouteKey para navegação e noindex de external_only foram preservados. Foram conferidas as seis versões das duas notícias e doze páginas de controle, incluindo a notícia própria nos três idiomas. Reciprocidade não comprova tradução.
- A amostra ampliada encontrou /maratonas/ sem H1. Seu título passou de h3 para h1 class=h3, preservando texto, aparência pelo estilo h3, consultas, filtros e autenticação. A alteração foi publicada, conferida no HTML público e reauditada em rodada posterior.
- O painel tem **15 itens: 12 concluídos e 3 pendentes**, com evidências e datas atualizadas. A nota técnica conserva método e pesos; a amostra Road Runners mudou, sem delta comparável.

## Auditorias usadas no painel

| Site | Auditoria em Brasília | URLs descobertas | Inspecionadas | Erros / avisos brutos | Nota técnica |
|---|---|---:|---:|---:|---:|
| Road Runners | 03/10/2026, 17:12 (Brasília) | 103.050 | 100 | 1 / 22 | 70,0 |
| Open Results | 03/10/2026, 16:05 (Brasília) | 34.321 | 100 | 0 / 0 | 100,0 |

Road Runners recebeu nova rodada após todas as correções; Open Results conserva a rodada anterior explicitamente datada, pois seu runtime não mudou neste lote. Ambos têm descoberta completa dos sitemaps; 100 páginas por site são uma amostra, sem nova reconciliação com o banco. Os 95.037 eventos históricos Road Runners continuam na descoberta.

O erro Road Runners é o 404 da notícia retirada editorialmente, ausente do sitemap. Avisos brutos preservados incluem canonicals na fonte, destinos privados com login e diferenças de caixa nos escapes percentuais. A alteração de cobertura impede atribuir a variação do número de avisos ao progresso ou a regressões deste lote. Maratonas foi corrigida e confirmada depois do achado.

Reciprocidade Road Runners: **27 páginas aprovadas, 0 com atenção e 73 sem evidência suficiente**. As nove versões institucionais passaram. Ausência de alternates em cópias canonicalizadas não é convertida em aprovação ou prova de tradução. Open Results permanece não medido nesse check.

## Pendências

- **OR-02:** noindex das páginas individuais está publicado; a origem tem robots correto, mas a conferência pública registrada neste lote ainda encontrou o robots antigo em cache HIT bloqueando /resultados. É necessária limpeza ou expiração efetiva da borda. /perfil permanece bloqueado. Não houve mudança de Cloudflare ou de política de treinamento.
- **SH-02:** conferir fatos e completar organizadores com fontes comprovadas. A cobertura dos campos pede revisão em 37 de 38 eventos Road Runners e 96 de 99 Open Results. A consulta anterior encontrou organizador nomeado em 1.332 de 34.320 eventos ativos; cronometrador não deve preencher esse papel automaticamente.
- **RR-08:** o ajuste técnico de idiomas foi concluído, mas a revisão editorial permanece pendente. A API pública registra publication_mode=licensed_full e original_url externo, junto de authorized_republication=false e license_expires_at=null. O cadastro não comprova licença; manter a atribuição à fonte até o responsável alinhar esses campos e a política.

Traduções entregues, acesso real de bots com identidade verificada em logs, visitas/conversões e citações datadas permanecem próximos passos do plano. Hreflang, resposta ao coletor e permissão declarada não substituem essas evidências.

## Verificação e publicação

- CFML institucional/editorial: baseline com nove falhas → 39 casos aprovados. Busca em três idiomas e escape de canonical/alternates também aprovados.
- 53 testes Node do coletor, relatórios, score e idiomas passaram; o teste focal de Maratonas falhou antes e passou após o H1.
- Quatro testes Python passaram, cobrindo onze subcasos de evidência, preservação de itens adjacentes e bloqueio de publicação quando dependências mudam.
- Nove cenários CFML de contrato, renderização, dados inválidos e acesso negado passaram com os snapshots finais. JVMs executadas sequencialmente, pois o cache compartilhado CommandBox apresentou uma colisão de bootstrap na primeira execução paralela.
- Revisão Astra do lote e da extensão Maratonas: sem Critical/Important. Dois ajustes textuais Minor foram aplicados.
- Oito templates de runtime compilados Adobe antes de suas publicações, com baseline, backup recuperável e hashes reais conferidos. Dependências monitoradas preservadas; sem branch, commit, push ou PR.
- O painel foi renderizado com os templates publicados no Adobe: confirma 15/12/3, notas, datas e checks das duas auditorias. Fixture administrativa temporária com GET, loopback e chave efêmera; removida ao final. Isso não verifica o login real de um usuário.

Runtime publicado: Road Runners sobre/index.cfm, ajuda/index.cfm, privacidade/index.cfm, noticias/index.cfm, includes/estrutura/head.cfm e maratonas/index.cfm; Business portal/includes/seo_score_data.cfm e portal/includes/seo_queue_data.cfm. Não houve alteração de layout do painel.

Backups: /var/backups/seo-institutional-roadrunners-20261003/baseline; /var/backups/seo-marathons-roadrunners-20261003/baseline; /var/backups/seo-institutional-business-20261003/baseline.

Evidências: ../staging/seo-institutional-20261003, incluindo subdiretório marathons, diffs, verificações públicas, auditoria, hashes, testes e revisão. Relatórios completos e histórico privados em /Users/Shared/RunnerHubReports/seo.

Referências: [Google — versões localizadas](https://developers.google.com/search/docs/specialty/international/localized-versions) e [Google — canonicals](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls), consultadas em 03/10/2026.
