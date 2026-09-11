# Transição condicional do log de eventos — Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans somente quando esta frente for retomada. Os checkboxes abaixo são critérios futuros, não autorização para executar agora.

**Goal:** Desligar **somente no final** a gravação de visualização de página de evento RR em `tb_log`, se a nova audiência cobrir os usos necessários, mantendo todos os outros logs e o histórico.

**Architecture:** Manter a nova audiência ativa e independente. Antes do desligamento, conferir cobertura e leitores; estabelecer uma fronteira entre as fontes sem dupla contagem. Não remover a tabela nem apagar registros.

**Tech Stack:** CFML/Adobe ColdFusion, PostgreSQL e tracker próprio.

**Spec:** [Estratégia de audiência](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/estrategia_audiencia_inventario_e_midia_proposta.md) e esclarecimento do usuário em 10/09/2026: somente o writer de view de página de evento, no final; demais tipos de `tb_log` intactos. Prioridade atual é continuar o plano, não desenvolver esta transição agora.

## Estado e limites

- Inspeção local somente leitura. Nenhum writer, reader, esquema, flag ou dado foi alterado nesta etapa; sem banco, SSH ou navegador.
- Coleta ativa desde 08/09 ([recibo](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-08_audience_activation_receipt.json:2)); banners restaurados em 09/09 ([publicação](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-09_ads_config_publicado.md:5)). Notas anteriores de coleta desligada são históricas.
- **Esta transição não bloqueia a medição nova nem as demais entregas.** O writer legado permanece enquanto seus critérios de aposentadoria não forem atendidos.
- Nenhum desligamento está tecnicamente liberado por este documento. Não iniciar agora implementação, migração de leitores ou desenho adicional.

## Global Constraints

- Alvo exclusivo: INSERT dedicado com `log_item='evento'` para view da página de evento RR. Não desabilitar `tb_log` globalmente nem logs de ações relacionadas a um evento.
- Preservar erros/404, busca, login/logout, certificados, cupons, vínculos de resultados, auditoria administrativa, favoritos/check-ins e demais tipos. Não alterar auth, billing, permissões, geolocalização ou trabalhos concorrentes.
- Não copiar IP/UA para audiência, burlar opt-out/GPC ou gravar no legado para recuperar pessoas que recusaram medição.
- Não mudar produtores OR/CT/hotsite por consequência lateral. Não apagar histórico; sem `DELETE`, `TRUNCATE`, `DROP`, backfill fictício ou ampliação de retenção.
- Eventos detalhados novos têm política de 90 dias. Agregados permanentes não estão implicitamente autorizados. Sem commits ou deploy nesta entrega documental.

## Matriz de evidências e cobertura

Linhas do checkout inspecionado em 10/09; reconfirmar ao retomar. Busca local não comprova ausência de consumidores externos ou dependências exclusivas do banco.

| Uso / origem | Evidência | Situação para a transição |
| --- | --- | --- |
| Writer RR | [backend_evento:815](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend_evento.cfm:815); [chamador:53](/Users/Shared/Projects/RunnerHub/RoadRunners/evento/index.cfm:53) | Grava `evento`, `qEvento.id_evento` em texto, IP em `log_user`, UA e `APPLICATION.codSite`; exclui só admin logado. ID/timestamp são defaults da [tabela:1470](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/schema.sql:1470). |
| Hotsite compartilhado | [Floripa/index:34](/Users/Shared/Projects/RunnerHub/RoadRunners/maratonadefloripa/index.cfm:34), [404:21](/Users/Shared/Projects/RunnerHub/RoadRunners/maratonadefloripa/404/index.cfm:21) | Incluem o mesmo writer. `/maratonadefloripa/` e `/404/` caem em `other`, sem ID de evento; domínio próprio está fora da allowlist nova. Há `index_bkp.cfm:19`, sem uso ativo comprovado. Não remover o bloco inteiro sem resolver esse alcance. |
| Outros sites | [OpenResults/backend_evento:110](/Users/Shared/Projects/RunnerHub/OpenResults/includes/backend_evento.cfm:110); site OR em `Application.cfc:34` | Writer separado. Business aceita RR/OR/CT; audiência RR não os substitui. Leitura de OpenResults foi limitada à dependência indicada pelo painel. |
| Painel antigo | [event_analytics_backend:98](/Users/Shared/Projects/RunnerHub/Business/portal/includes/event_analytics_backend.cfm:98) | Onze consultas de log: resumo 98, ranking 177, cidade 239, site 296, dispositivo 352, hora 413, fluxo 469, origens 538, recentes 595, detalhe 696/729. Amostra 500/1000/3000 e janelas 1/7/30/90 dias. Continua dependente. |
| Home administrativa | [home_admin_dashboard:219](/Users/Shared/Projects/RunnerHub/Business/includes/estrutura/home_admin_dashboard.cfm:219), saída 816 | Contador de eventos de sete dias, sem filtro de site, junto de `erro`/`404`. Eventual troca deve atingir somente `event_views`. |
| BI mensal RR | [bi/backend_parceiros:561](/Users/Shared/Projects/RunnerHub/Business/bi/backend_parceiros.cfm:561), [duplicata:541](/Users/Shared/Projects/RunnerHub/Business/includes/backend/backend_parceiros.cfm:541) | `qAcessosRR` agrega evento/mês/ano sem limite temporal. `/bi/bi.cfm:28` executa o primeiro backend. Só foram encontradas as duas declarações, sem saída visual explícita; confirmar uso. |
| Erros e dados funcionais | [erros:108](/Users/Shared/Projects/RunnerHub/Business/portal/includes/error_log_backend.cfm:108), [check-in:641](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend_evento.cfm:641), [resultado:754](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend_perfil_publico.cfm:754), [agenda:1123](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend_perfil_publico.cfm:1123) | Erros leem só `erro`/`404`. Histórico/agenda usam `tb_resultados`, `tb_resultados_desvincular` e `tb_evento_corridas_checkin`, não esse pageview. Logs `vincularcorrida` (762) e `desvincularcorrida` (802) permanecem. |

## Equivalência e diferenças deliberadas

- Para evento identificado, usar `event_kind='page_view' AND content_type='event'`, por `content_id` canônico, contando `DISTINCT page_view_id`. O tracker emite também `content_open` na mesma abertura: **não somar ambos**. [Contexto:63](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:63), [tracker:175](/Users/Shared/Projects/RunnerHub/RoadRunners/assets/js/rr-audience.js:175), [consulta:2](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/content.sql:2).
- Nome/cidade/UF/data podem ser associados pelo cadastro. A tela nova mostra ID/path e top 100 conteúdos; esse top não é universo para contador geral. UF do evento não é UF física do visitante.
- Legado conta requests de servidor; novo exige JS/aba visível e respeita opt-out/GPC, exclusão de bots/prefetch e falhas de entrega. Não exigir totais iguais. Internos diferem: legado exclui admin; novo marca admin ou dev e os exclui por padrão. [Controles:49](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceRequestControlService.cfc:49).
- Novo guarda UUID pseudônimo de visitante/sessão, não IP/UA. Origens/IP, navegador/UA, bots e fluxo aproximado por IP não têm equivalência direta: decidir substituição ou visão só histórica. Não produzir zeros fictícios nem acrescentar PII.
- `site_host` não equivale automaticamente a `site=RR/OR/CT`. O [host/familyMap:43](/Users/Shared/Projects/RunnerHub/RoadRunners/services/AudienceMeasurementService.cfc:43) confirma a lacuna do hotsite.
- `log_timestamp` não tem timezone; `occurred_at` é timestamptz da ingestão. Confirmar timezone legado; atraso de fila limita equivalência temporal. [Ingestão:95](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-09-07_audience_inventory.sql:95).

## Gates futuros — somente quando esta frente for retomada

- [ ] **Dependências:** reconferir referências/includes, catálogo real e consumidores externos. Dar destino a cada reader: novo, histórico ou aposentado. Resolver uso do BI mensal e alcance do hotsite; ausência na busca não prova desuso.
- [ ] **Cobertura:** testar `/evento/` desktop/mobile, anônimo/logado/interno, reenvio, aba oculta, recusa/GPC e falha de coleta. Uma abertura mensurável tem um pageview canônico; `content_open`/reenvio não duplicam. Hotsite precisa de cobertura específica ou preservar seu writer. OR/CT ficam intactos.
- [ ] **Leitores:** antes de parar novas linhas, comprovar substitutos com fixtures de dois eventos, dados OR, períodos vazio/indisponível e logs não alvo. Preservar `erro`/`404` na home. Não iniciar essa migração agora.
- [ ] **Corte/histórico:** registrar instante real `cutover_utc`, timezone legado e superfícies. Legado RR somente `< corte`, audiência somente `>= corte`; durante convivência, séries separadas. Não somar o overlap iniciado em 08/09. Manter histórico anterior intacto e explicar a mudança de metodologia/atrasos. Decidir uso mensal futuro além de 90 dias sem inventar retenção permanente.
- [ ] **Desligamento final:** com gates atendidos, observar teste RED/GREEN isolado: INSERT dedicado cessa para superfície coberta, outros logs/superfícies preservados continuam. Alteração mínima e publicação autorizada com backup/hashes. Não condicionar escrita legada à recusa ou ao sucesso individual de beacon.
- [ ] **Pós-corte:** verificar por leitura uma janela com tráfego observado: novas linhas RR cobertas cessam e pageviews novos chegam; OR/hotsite preservados não precisam zerar. Ausência de tráfego não prova regressão. Se houver rollback, registrar intervalo reativado e manter fontes separadas, sem apagar dados para ajustar totais.

## Testabilidade futura: catálogo e contadores

Roteiro somente leitura, **não executado**. Usar conexão autorizada, transação `READ ONLY` e timeout; sem imprimir credenciais, IPs, UAs ou corpos de rotinas. Conferir primeiro `to_regclass('tb_log')`, `to_regclass('public.tb_log')`, `to_regclass('audience.events')` e `current_setting('TimeZone')`; divergência da tabela esperada interrompe o diagnóstico.

```sql
SELECT DISTINCT pg_describe_object(d.classid, d.objid, d.objsubid) AS dependent
FROM pg_depend d
WHERE d.refclassid='pg_class'::regclass
  AND d.refobjid=to_regclass('public.tb_log');

SELECT n.nspname, p.proname
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE p.prokind IN ('f','p') AND p.prosrc ~* '\mtb_log\M';
```

O catálogo não cobre todo SQL dinâmico, job externo, planilha ou aplicativo. Complementar com confirmação operacional, sem habilitar extensões ou alterar banco.

Para contadores, usar a mesma janela limitada e parâmetros tipados, convertendo os limites ao timezone confirmado do legado. Comparar `tb_log` agrupado por `site,log_item` com `audience.events` por `site_host,environment,is_internal,page_family,content_type,content_id`, filtrando `event_kind='page_view'`. Não usar amostra/top 100 como total, não exigir igualdade bruta e não retornar PII. Fixtures isoladas devem comprovar preservação de `erro`, `404`, `vincularcorrida` e auditoria administrativa; não provocar mutações de usuários ou cliques em anúncios em produção para alimentar testes.

**Próxima ação agora:** nenhuma nesta frente além de manter este registro. Prosseguir a nova medição; retomar esta aposentadoria apenas no final, conforme prioridade esclarecida pelo usuário.
