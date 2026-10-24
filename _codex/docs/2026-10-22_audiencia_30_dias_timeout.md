# Audiência: timeout ao ampliar de 7 para 30 dias — 22/10/2026

## Causa comprovada

O painel executa 14 consultas de relatório sequencialmente antes de renderizar a página. O `Application.cfc` define orçamento de 20 segundos por requisição. No recorte de 30 dias, produção, contexto comercial e demais filtros vazios, a soma das medições individuais sem cache foi 55.955 ms. A tela anterior do usuário mostrava timeout já durante a renderização do menu: a consulta do menu era o ponto da interrupção, depois do orçamento consumido nos relatórios.

O plano de `summary.sql` mostrou materialização de `regional` e `filtered`, com estimativa de 729 mil linhas intermediárias e largura de 877 bytes em `filtered`. Os mesmos eventos eram copiados/reprocessados em vários relatórios. A tabela tinha aproximadamente 1 milhão de linhas e já possuía índice por `(environment, is_internal, occurred_at)`; não foi necessária migração de banco ou novo índice.

## Alterações publicadas

- `portal/audiencia/queries/filter.sql`: CTEs `regional` e `filtered` passam a `NOT MATERIALIZED`, permitindo ao PostgreSQL propagar filtros e selecionar as colunas necessárias de cada consulta. Regras de período, regiões, identidade da página, internos, dispositivos e contagens preservadas.
- `portal/audiencia/index.cfm`: orçamento de 60 segundos, aplicado após autenticação e autorização administrativa. O orçamento global continua 20 segundos. Timeouts de 15 segundos por consulta e cache de até 1 minuto permanecem como antes.

## Medições sem cache de resultado

Diagnósticos temporários no servidor, restritos a loopback e POST com token aleatório, removidos em `finally`. Consultas em transação READ ONLY com limite de 16 segundos. Candidata executada antes de publicar, sem alterar as consultas de produção. Os valores são amostras sequenciais, não uma promessa de latência nem um benchmark de HTTP completo; a coleta continuou recebendo eventos durante as medições.

| Consulta | Antes (ms) | Candidata (ms) |
| --- | ---: | ---: |
| summary | 6.759 | 3.574 |
| inventory | 3.022 | 420 |
| regions | 3.792 | 876 |
| content | 3.227 | 574 |
| origins | 4.403 | 2.357 |
| acquisition | 5.468 | 3.592 |
| daily | 2.869 | 1.121 |
| coverage | 3.578 | 1.757 |
| coverage_paths | 3.963 | 561 |
| live_journey | 7.326 | 5.260 |
| advertiser_acquisition | 5.042 | 501 |

Ocupação geral, ocupação regional e capacidade têm SQL independente desse filtro e não foram alteradas. Somando seus tempos originais aos candidatos, o total estimado das 14 consultas é 27.099 ms, redução aproximada de 52%. Isso ainda supera os 20 segundos globais, justificando o orçamento específico e finito deste painel.

## Verificação

- `node _codex/scripts/test_audience_report_local.mjs`: 56 asserções SQL, PostgreSQL temporário isolado.
- `node _codex/scripts/test_audience_live_report_local.mjs`: 40 asserções SQL.
- `node _codex/scripts/test_audience_editorial_report_local.mjs`: 21 asserções SQL.
- Node tests de gráficos, navegação regional e compatibilidade Adobe: 9 aprovados.
- A primeira tentativa de PostgreSQL local foi impedida pelo sandbox de criar memória compartilhada; a mesma suíte passou fora dessa restrição, sem conexão de produção.
- Baseline dos dois arquivos publicados idêntico ao HEAD local antes da alteração. Hashes de `Application.cfc` e do backend foram conferidos como guardas no momento de publicar.
- Link exato do usuário recarregado no Chrome autenticado: relatório de 30 dias, indicadores e gráficos visíveis, sem timeout.
- Pela própria interface, aplicado 7 dias e depois 30 dias: ambos concluíram, preservando filtros e a aba Visão geral.
- Hashes dos arquivos publicados e presença do backup conferidos novamente.

Backup recuperável no servidor: `/var/backups/business-audience-timeout-20261022-pqgvqn9_/`, com os dois arquivos anteriores e `manifest.json`. Publicação atômica por arquivo, primeiro o filtro e depois o index. Nenhum serviço reiniciado. Somente esses dois arquivos de runtime foram publicados; mudanças preexistentes de outras frentes foram preservadas.

Evidências e ferramentas: `_codex/staging/audience-timeout-20261022/`. Captura real: `30-days-verified.png`. Para rollback, conferir os hashes atuais contra `publication.json` antes de restaurar os dois arquivos do backup; não sobrescrever alterações posteriores.

## Limites

O primeiro carregamento sem cache continua sendo um relatório de dezenas de segundos. Esta correção elimina trabalho desnecessário e torna o orçamento compatível com o painel atual; não introduz resumo agregado persistente nem carregamento por aba. O recorte de 90 dias não foi homologado nesta tarefa.
