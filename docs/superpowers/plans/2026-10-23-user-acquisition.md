# User Acquisition Implementation Plan

> Executar inline com superpowers:executing-plans e TDD. Sem operações Git; publicação autorizada pelas instruções Business.

**Goal:** Gráfico diário com seleção 7/30/90/365, métricas reconciliadas e publicação verificada.
**Architecture:** UserAcquisitionMetrics agrega 365 dias; include isolado integra o painel à listagem; JS/CSS próprios renderizam SVG e seleção local.
**Tech Stack:** CF2025/PostgreSQL/JS nativo/SVG, sem dependências novas.
**Spec:** docs/superpowers/specs/2026-10-23-user-acquisition-design.md

## Global Constraints
- Mesma autorização ADMIN/DEV/contexto real; nenhuma alteração de dados ou schema.
- Data de criação da conta, calendário America/Sao_Paulo; hoje parcial, valores diários incluindo zeros medidos.
- Escopo global independente da busca/status/papel da lista; preservar esses filtros ao alternar período.
- Sem API paga, credenciais ou reativação de geolocalização. Somente arquivos da tarefa na publicação.

## Review Focus
- Série com buracos, bordas inclusivas/exclusivas e mudança de ano deve contar cada conta uma vez.
- Erro de consulta não pode virar aquisição zero nem quebrar edição/mesclagem.
- Período adulterado/array não pode alterar SQL nem escapar para HTML/JS.
- 365 pontos e todos os valores zero precisam permanecer legíveis e acessíveis no mobile.
- Filtros da listagem não podem aparentar filtrar os números globais ou ser removidos pelo gráfico.

## Tasks
- [x] 1. RED/GREEN serviço services/UserAcquisitionMetrics.cfc: period(value), sql(), parameters(lastDay), summarize(rows,days), load(days). Testes native.cfm com CTE de datas sintéticas e reconciliação independente real.
- [x] 2. RED/GREEN JS/CSS/include: slicePeriod/summary/geometry; gráfico responsivo e controles; backend somente na listagem com falha isolada. Testes Node e render CF.
- [x] 3. Regressão de gerenciamento/DEV, revisão independente, testes de acesso e browser; publicar 6 arquivos runtime com backup e verificar filtros/períodos e metadados de produção preservados.

## Ledger
- Pedido específico suficiente para implementação pontual; padrões declarados: 30 dias incluindo hoje parcial e indicadores globais independentes da lista.
- Aplicar as orientações de dados à integração CF existente; não gerar outro app React/Sites nem nova fonte de dados.
- Verificação: três suítes CF nativas (fonte, calendário/reconciliação, render), quatro testes Node, três contratos de mesclagem e 52 verificações DEV, com quatro renders de regressão. Testes privados removidos da raiz pública após execução.
- Revisão independente única: sem achados bloqueantes ou menores; limites de evidência de produção/browser validados pelo implementador.
- Publicados somente seis arquivos runtime, com CAS e backup recuperável `/var/backups/business-user-acquisition-64gusgg2`; dez probes de acesso e seis hashes finais corretos. Arquivos preservados de outras frentes conferidos antes/depois.
- Aceitação instalada: quatro períodos e geolocalização pausada; arquivo privado arquivado em `/var/backups/business-user-acquisition-test-ya34e9n5`.
- Browser autenticado em produção: quatro períodos, atualização conjunta de gráfico/KPIs, tabela diária e critérios; filtro sem resultados preservou sete dias e os indicadores globais. Filtro limpo e período final 30 dias. Console sem erros na verificação final.
- Preview com dados agregados reais: teclado (incluindo Espaço), tooltip, viewport móvel real de 375 px e quatro períodos. Evidência final de produção: `/private/tmp/business-user-acquisition-20261023.png`.
- Sem alteração de schema, credenciais, contas ou estado da geolocalização; sem commit/push neste pedido.
