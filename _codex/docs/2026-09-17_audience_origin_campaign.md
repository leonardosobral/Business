# Origem e Campanha — audiência e eventos

Pedido: duas abas separadas nas telas `/portal/audiencia/` e `/portal/eventos-analytics/`, consolidando todos os links de uma mesma origem (por exemplo, Open Results).

## Comportamento publicado

- Origem agrupa somente pela origem atribuída, sem separar meio, campanha ou criativo. Visitantes e sessões distintos são recalculados nos registros completos antes do limite de exibição; não são somas das linhas de campanha.
- Na audiência, tempo ativo é deduplicado por página e a qualificação de sessão é recalculada por origem (30 segundos ou duas páginas distintas). Até 100 origens.
- Nos eventos, preservados recorte, filtros, deduplicação das aberturas e origem com fallback de referrer já existentes. Até 30 origens.
- Campanha preserva o detalhamento anterior. Jornada LIVE! fica em Campanha na audiência.
- Links originais de Origem preservados: `#audience-acquisition` e `?aba=origem`. Novos links: `#audience-campaigns` e `?aba=campanha`.
- Identificação de origem/coleta não foi alterada. Nenhuma migração, credencial, modelo ou outro projeto foi alterado.

## Runtime do escopo

`portal/audiencia/queries/origins.sql` (novo), `portal/audiencia/queries/event_interest.sql`, `portal/includes/audience_backend.cfm`, `portal/includes/event_interest_backend.cfm`, `portal/audiencia/home.cfm`, `portal/eventos-analytics/home.cfm`.

## Validação

- Teste de navegação renderizada falhou com 7 abas antes da alteração e passou com 8 depois.
- Consulta real PostgreSQL: mesma origem entre campanhas/meios/criativos e página repetida resultou em 3 páginas, 2 visitantes, 2 sessões, 55 segundos e 1 sessão qualificada, sem duplicidade.
- Suite SQL de eventos: origem consolidada entre campanhas e meios, contagens distintas, filtros, paginação, agenda e janelas semanais/mensais aprovados.
- 24 cenários de renderização CFML de eventos aprovados, incluindo ambas as abas, escaping, acesso proibido, relatório vazio e indisponível.
- Prévia local real no navegador: alternância Origem/Campanha na audiência, jornada LIVE! preservada, dados e cabeçalhos corretos. Desktop e celular de 390px; sem overflow da página, tabelas responsivas com rolagem própria.
- Revisão independente sem bugs concretos. `git diff --check` aprovado.
- Quatro templates compilados no Adobe ColdFusion fora do webroot.
- Testes PostgreSQL executados em cluster temporário isolado via loopback, com pacotes oficiais Ubuntu extraídos sem instalação, sob usuário sem privilégios e dados sintéticos. PostgreSQL local indisponível por limite de memória compartilhada do macOS. Cluster temporário removido após os testes.

## Publicação

Backup: `/var/backups/business-origin-campaign.c1abe40ce5a3`.
Recibos de prepare/publish/verify: `2026-09-17_audience_origin_campaign*.json`.
Hashes dos seis arquivos e 125 guardas de arquivos alheios confirmados.
Rollback pelo publisher `_codex/scripts/deploy_audience_origin_campaign.py rollback`, condicionado aos hashes do pacote.

## Verificação real

Eventos, 7 dias, todas as provas, tráfego público: aba Origem publicada e exibindo Open Results em uma linha: **228 aberturas, 138 visitantes, 142 sessões**. Nova aba Campanha presente.
Audiência, recorte padrão: Origem mostra Open Results em uma única linha, **214 visitantes, 262 sessões, 146 qualificadas (55,7%)**. Campanha mantém linhas distintas de `openresults_to_roadrunners` e criativos como `salvar_tabela_resultados`, `salvar_busca_atleta` e `salvar_pagina_atleta`, além da jornada LIVE!.

A aba Campanha de eventos também foi aberta e confirmada em produção, com Open Results e sua campanha. Ambas as telas foram verificadas em sessão administrativa real.
