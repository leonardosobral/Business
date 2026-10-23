# Painel de consumo OpenAI — Implementation Plan

> **For agentic workers:** usar execução nativa desta tarefa, TDD e uma revisão independente ao final. Sem commits/branches: não foram solicitados.

**Goal:** publicar painel de consumo por módulo com medição mínima segura e histórico, mantendo as chaves existentes.
**Architecture:** Observer CFML escreve diário privado compartilhado; Pricing normaliza uso e calcula estimativa; Store combina diário com legado explicitamente parcial; interface autenticada renderiza agregados e histórico.
**Tech Stack:** Adobe ColdFusion 2025, PostgreSQL existente (somente leitura), JSONL, CSS/JS nativos do Business.
**Spec:** `docs/superpowers/specs/2026-10-23-openai-usage-design.md`.

## Global Constraints

- Nenhuma credencial/modelo/tentativa existente muda. Nenhuma chamada paga nos testes.
- Nenhum dado de prompt, resposta, pessoa ou segredo entra no diário.
- Só admin global efetivo, sem delegação; GET somente, sem ação sobre filas.
- USD estimado não é faturamento; dados ausentes não valem zero.
- Preservar todas as mudanças preexistentes e publicar somente escopo com CAS/backup.

## Review Focus

- Cache write não pode ser contado duas vezes; testando 12.000 input/4.000 read/3.000 write30m/4.000 write12h.
- Resposta rejeitada/incompleta com uso continua contada; timeout sem uso é desconhecido.
- Legado não duplica diário depois da ativação nem presume cron = chamada.
- Coleta concorrente e arquivos corrompidos não derrubam serviços ou somem silenciosamente.
- Alteração de filtro não expõe dados a contas clientes nem perde contexto das abas.

## Task 1 — Pricing e diário seguro
- [x] RED: fixture nativa de custo/cache, uso desconhecido, sanitização, falha de escrita e concorrência.
- [x] Implementar `services/openaiUsage/Pricing.cfc` e `Observer.cfc`; interface `normalize(module,operation,model,response,durationMs)` e `observe(...)`.
- [x] GREEN: fixture nativa sem rede externa, diário em diretório privado de teste.

## Task 2 — Consolidação, legado e acesso
- [x] RED: agregados/filtros/cutover, ausência de tarifa, paginação, datas e admin efetivo.
- [x] Implementar `Store.cfc`, `Access.cfc` e consultas legadas limitadas; GET validado, sem DDL.
- [x] GREEN: fixtures com eventos locais e queries legadas reais somente leitura.

## Task 3 — Instrumentação por módulo
- [x] RED: wrappers reais com fronteira de transporte substituída por fixture sintética, cobrindo HTTP 200/429/timeout e erro de validação posterior.
- [x] Business: Observer em AIClient, EventDescriptionRewriteService, AI-mails e HelpdeskAI; RR Vicky e News providers, sempre antes da validação posterior e por tentativa HTTP.
- [x] GREEN: sem diferenças no retorno/erro original, eventos mínimos por chamada, modelo/chave/payload preservados.

## Task 4 — Painel
- [x] RED: renderização de métricas conhecidas/desconhecidas, filtros, tabs, links e histórico escapado.
- [x] Implementar `/administracao/consumo-openai/`, assets, includes e link restrito no menu Plataforma.
- [x] GREEN: testes nativos, JS e navegador autenticado, estados vazios/legado/medição ativa e acesso negado.

## Task 5 — Revisão e publicação
- [x] Revisão independente e correções acompanhadas de regressões.
- [x] Testes de regressão disponíveis; registrar limitações de runtime local sem ocultá-las.
- [x] Capturar baseline real de todos os arquivos, backup, publicação CAS e rollback automático.
- [x] Verificar hashes pós-publicação, rotas, evento sintético da telemetria separado e interface real; gerar recibo e screenshot. Sem commit/push.

## Evidências da entrega — 23/10/2026

- Sete suítes nativas: pricing, observer, store, legacy, wrappers, view e ledger. Doze escritores concorrentes; HTTP200/429/timeout; marco ausente/inválido; JSON corrompido; ausência de uso; números em notação científica; reconciliação diária de tokens e USD. Fixtures isoladas arquivadas em diretórios privados do servidor.
- Regressões: 353 verificações de reescrita, 29 guards, auditoria SQL com rollback e cinco casos de privacidade; contratos Astra/geolocalização e falha do provedor; dez checks JS de Help Desk, lote de AI-mails e resumo individual. A suíte PostgreSQL local de delegação não foi executada por falta do runtime initdb; as verificações nativas específicas de acesso passaram.
- Revisão independente corrigiu: custos diários desconhecidos, zeros legados ambíguos, corte seguro do legado e apresentação de cache. A inspeção visual revelou colisão de `day()` com o builtin CF; renomeada a função para `localDateKey` e acrescentada reconciliação obrigatória na suíte e no verificador instalado.
- Publicação: 29 arquivos de runtime em Business, News e RR; 28 arquivos de outras frentes guardados por hash. Menu publicado a partir do baseline mais novo do servidor em `_codex/staging/openai-usage/business/includes/estrutura/sidenav.cfm`, não do menu local anterior.
- Backup inicial completo: `/var/backups/business-openai-usage-i5djyp0_`. Ajustes incrementais recuperáveis: `/var/backups/business-openai-usage-oylx7uml` e `/var/backups/business-openai-usage-rj1dwo3n`. Cadeia e hashes em `_codex/deploy/openai-usage-20261023.json`.
- Validação instalada: `_codex/deploy/openai-usage-validation-20261023.json`. Classes e escrita sintética nas três aplicações; 403 para não admin, contexto de conta e delegado; 405 para POST. Diário sintético separado, sem contaminar métricas reais. Sem chamadas pagas nos testes. O pequeno artefato sintético criado por uma variável reservada de fixture foi movido para arquivo privado recuperável, não excluído.
- Navegador autenticado: visão geral, filtro AI-mails e retorno a todos, histórico e segunda página, aba de cobertura, campos de período personalizado, formatação pt-BR, módulos e barras diárias reais. Screenshot `_codex/deploy/openai-usage-20261023.png`. Layout estreito não foi validado visualmente; CSS responsivo foi inspecionado.
- Coleta real iniciou às 11:56:37 (São Paulo). Uma chamada natural de reescrita HTTP429 já foi registrada como falha sem tokens/custo, não como custo zero. Nenhuma chave, modelo, política de fila ou banco foi alterado. Histórico anterior e custos de áudio/RAG/armazenamento permanecem explicitamente parciais; não há conciliação da fatura administrativa OpenAI.
