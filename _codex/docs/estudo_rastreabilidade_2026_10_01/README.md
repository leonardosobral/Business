# Estudo — rastreabilidade 2026, publicada em 01/10/2026

O trabalho permanece no [caderno único 6](https://business.roadrunners.run/estudo/?caderno=6). A [web 2026](https://roadrunners.run/brasilquecorreprovas/web/?ano=2026#fontes) usa a publicação 25, versão 12, congelamento 126 (célula 251/rev21, contrato 8). Todos os 672 valores observados da exportação têm fonte explícita. Números e coortes preservados; 2025 permanece v13/#120.

As consultas iniciais foram importadas exatamente nas células 317–322/rev1, sem nova execução. A nota 324/rev1 e o mapa 256/rev3 registram as fontes; a auditoria 323/rev3 tem o congelamento 125. Os SQLs analíticos existentes do DBA foram preservados. Das 161 células antigas, somente a saída 251 e o mapa 256 receberam revisão, com conferência da revisão e do hash esperados.

O `SqlReadGuard.cfc` passou a reconhecer CTE `AS [NOT] MATERIALIZED`, listas de colunas de CTE, `GROUPING SETS` e as funções puras necessárias aos SQLs iniciais. Escritas, funções arbitrárias e chamadas de configuração continuam bloqueadas. Executor, permissões e limites permanecem vigentes. Passaram 16 casos reais em ColdFusion; componente compilado e hash de produção conferido. O arquivo preexistente `estudo/home.cfm` não foi alterado nesta etapa.

Esta pasta preserva o manifesto, SQLs de auditoria/saída/contrato, notas, integridade e recibos do componente. O registro completo, incluindo os 145 testes Node/Python, validação do CSV, HTTP e desktop/celular, está em [RoadRunners — rastreabilidade 2026](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/brasil_que_corre_provas/rastreabilidade_2026_10_01/README.md).

A publicação acrescenta fontes a 448 valores e a dois totais; preserva 222 fontes anteriores. A comparação PostgreSQL usa o JSON nativo para preservar precisão e tipos. A atribuição de fonte não encerra as pendências de cobertura/14+, referências históricas e tempos de Floripa.

Recuperação: republicar o congelamento 122 com a guarda do destino corrente. O backup do componente Business fica em `/var/backups/roadrunners-estudo-rastreabilidade-20261001/runtime-v3/Business`. Contratos anteriores e validador de publicação permanecem intactos.
