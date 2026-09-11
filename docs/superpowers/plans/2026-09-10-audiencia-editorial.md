# Exposição editorial e profundidade de notícia

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to execute the two tasks with tests and review. No commits or publication.

**Goal:** completar a parte editorial já aprovada: separar card exposto, conteúdo aberto, reprodução e profundidade alcançada, dentro do Business.

**Architecture:** novos eventos aditivos `content_viewable` e `content_progress` no contrato existente de audiência; sem usar eventos publicitários como atalhos. RoadRunners produz e valida; Business agrega a tabela existente. Migração única anterior ao novo runtime; a coleta atualmente publicada não muda durante a preparação.

**Tech Stack:** CFML, JavaScript nativo, PostgreSQL local descartável, Node test runner.

**Spec:** `_codex/docs/estrategia_audiencia_inventario_e_midia_proposta.md`, seção Audiência e conteúdo, implementação autorizada pelas continuações do usuário.

**Execução local concluída em 10/09/2026:** ambas as tarefas implementadas, revisadas e incorporadas aos projetos; 83 testes Node RR, contratos CFML/SQL e painel aprovados. Ledger completo: `.superpowers/sdd/2026-09-10-audiencia-editorial/progress.md`. Entrega/SQL/ordem de publicação: `_codex/docs/2026-09-10_audiencia_editorial_entrega.md`. Os checklists abaixo preservam os critérios originais; a execução e suas evidências estão no ledger. SQL e publicação permanecem pendentes, não foram realizados nesta etapa.

## Global Constraints

- Preservar opt-out/GPC, identificadores mínimos, retenção detalhada de 90 dias, autenticação, DSN `runner`, Ads e cobrança.
- Não modificar `runner_dba`, configurações Cloudflare ou criar acesso ao banco de produção.
- Não desligar `tb_log`, apagar histórico, criar commits/branches ou publicar este lote sem autorização.
- Basear a preparação no checkout atual, preservando alterações preexistentes. RoadRunners candidato em `/private/tmp/rr-editorial.NFzNdW/RoadRunners`; Business pode receber mudanças estritamente do painel. Não alterar checkout RoadRunners antes da revisão.
- Não representar falha/ausência de instrumentação como exposição zero medida. Não equiparar rolagem a leitura, nem abertura a reprodução.
- Payload sem novos dados pessoais, URL livre, identificadores financeiros ou acesso a Ads. Páginas, sessões, oportunidades e impressões existentes não aumentam por causa das novas categorias.

### Task 1: produtor editorial, contrato compatível e SQL único

**Files:** candidato RR: `assets/js/rr-audience.js`, `includes/analytics/bootstrap.cfm`, `services/AudienceMeasurementService.cfc`, `_codex/sql/2026-09-10_audience_editorial.sql`, testes `_codex/tests/audience-editorial*` e runner local. Templates concretos do inventário editorial: home, notícia detalhe/lista/relacionados, vídeos lista, lateral compartilhada, busca e partials infinitas. Manter edições de template apenas nos marcadores.

**Interfaces:** mesmos campos do contrato v1. `content_viewable`: `contentType` news/video, ID estável igual ao usado na abertura, `ratio >= 0.5`, `maxContinuousMs >= 1000`, nenhum slot/campanha/entrega, `activeMs=0`. `content_progress`: somente news, ratio em 0.25/0.5/0.75/1, nenhum slot/campanha/entrega e `activeMs=0`. `visibleMs` pode registrar o tempo de qualificação do card, sem se tornar tempo ativo de página. Marcadores DOM `[data-audience-content-type][data-audience-content-id]` nos cards e `[data-audience-article]` somente no corpo da notícia. Chaves deduplicadas por página+tipo+conteúdo (+marco no progresso), nunca por reentrada ou nova partial.

```js
// Exemplos do contrato consumido pelo relatório, não chamadas manuais em produção.
{kind:'content_viewable',key:'content_viewable:news:news-1',contentType:'news',contentId:'news-1',ratio:0.5,maxContinuousMs:1000,visibleMs:1000}
{kind:'content_progress',key:'content_progress:news:news-1:75',contentType:'news',contentId:'news-1',ratio:0.75}
```

- [ ] Escrever e executar RED: card por 999 ms não qualifica; 1000 ms qualifica; documento oculto, imagem quebrada, CSS oculto, clipping, saída/reentrada entre amostras, troca de elemento/ID não acumulam intervalo; dois exemplares do mesmo card não somam exposição e produzem no máximo uma contagem; partial nova não cria page_view; opt-out interrompe e limpa a fila.
- [ ] Escrever e executar RED para profundidade: apenas o corpo de notícia e aba visível; altura positiva; bottom da viewport alcança os marcos; chamada repetida não duplica; sidebar/rodapé não entram na altura; profundidade não gera uso ativo nem nova abertura. Chave usa o ID canônico da notícia do contexto.
- [ ] Implementar amostragem reutilizando as proteções geométricas e ciclo existentes, sem duplicar tracker, sem listeners por card e sem impedir playback/navegação. Separar estados por elemento para continuidade, deduplicar por identidade de conteúdo na emissão. Preservar capacidade da fila e limite de eventos.
- [ ] Instrumentar os templates ativos apontados pelo inventário, incluindo conteúdo assíncrono e IDs de vídeo iguais ao ID do player (não UUID de mídia). Notícias usam ID da API com fallback de slug igual ao buildContext. Sem alteração visual/consulta de dados nova.
- [ ] RED/ GREEN CFML e PostgreSQL: aceitar e deduplicar novos eventos; rejeitar identidade vazia/tipo errado/limiar insuficiente/IDs financeiros/progresso inválido; eventos antigos continuam válidos. Novo SQL transacional/aditivo único amplia a CHECK de event_kind e a função de ingestão, sem drops de dados, grants, revokes, alteração de owner ou roles. Reaplicação mantém dados/ACLs; testar `SET ROLE runner` após atualização e preservar privilégios anteriores de `runner_dba`. Não executar em produção.
- [ ] Atualizar hash do tracker no bootstrap; executar as 69 regressões Node anteriores e contratos locais. Entregar patch limitado contra snapshot inicial, lista de arquivos/hashes, relatório RED/GREEN e limites de validação.

### Task 2: mostrar exposição e profundidade no Business

**Files:** `portal/audiencia/queries/content.sql`, `portal/audiencia/home.cfm`, teste SQL em `_codex/scripts/test_audience_report_local.mjs` ou runner editorial independente que reutilize consultas reais; fixture de renderização local. Não modificar autenticação ou queries de inventário.

**Interfaces:** Task 1 produz os dois eventos descritos acima na tabela `audience.events`. Colunas SQL novas: `card_views` (páginas distintas com content_viewable), `exposed_visitors` (navegadores distintos expostos), `depth_25`, `depth_50`, `depth_75`, `depth_100` (páginas distintas com marco >= limiar). Colunas antigas e suas definições permanecem. Caminho ilustrativo deve priorizar page_view/content_open, não o local do card; sem inventar link por ID. Vídeos/perfis/eventos exibem travessão para profundidade não aplicável. Sem CTR abertura/card, pois tráfego direto e superfícies não instrumentadas tornam o denominador inválido.

```sql
count(DISTINCT page_view_id) FILTER (WHERE event_kind='content_viewable') AS card_views,
count(DISTINCT visitor_id) FILTER (WHERE event_kind='content_viewable') AS exposed_visitors,
count(DISTINCT page_view_id) FILTER (WHERE event_kind='content_progress' AND view_ratio>=0.75) AS depth_75
```

- [ ] Testes RED com fixture explícita: card sem abertura aparece com uma exposição e zero abertura/início; duas superfícies do mesmo conteúdo/página não duplicam; mesmo visitante em duas páginas soma duas exposições/uma pessoa; marcos repetidos não duplicam; legado sem eventos novos continua com métricas antigas e indicação de cobertura ainda ausente; filtros UF/família/dispositivo/interno continuam isolados; resumo/inventário inalterados pelos eventos extras dentro de páginas já conhecidas.
- [ ] Atualizar query e tabela Conteúdo usando agregações filtradas; acrescentar cartões expostos e alcance exposto separados de visitantes de abertura; profundidade 25/50/75/100 em notícia; preservar início/conclusão e uso ativo da página. Ranking top 100 deve contemplar conteúdo apenas exposto, mantendo limite explícito.
- [ ] Indicar no painel que exposição exige 50% por 1 s; profundidade é trecho alcançado na tela, não leitura comprovada; números editoriais novos começam na ativação e não têm histórico retroativo. Não anunciar instrumentação ativa só porque a query compila.
- [ ] Executar SQL real em PostgreSQL descartável, regressões do painel, render CFML e checagem desktop/mobile quando runtime viável. Testes locais não são evidência de produção. Revisão de contrato e de código após integração.
- [ ] Registrar entrega local, arquivos exatos, ordem SQL → serviço → tracker/templates/bootstrap → Business e rollback de runtime sem desfazer SQL aditivo; fornecer ao usuário o único SQL e o próximo passo. Não publicar nem acessar banco de produção.
