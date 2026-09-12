# Jornada LIVE! no Business — implementação local

Data: 12/09/2026. Escopo deste registro: consumidor Business, implementado e validado localmente. A publicação e a conferência em Adobe/produção são coordenadas separadamente; este documento não afirma implantação.

## Comportamento

O painel de Audiência recebe uma seção “Caminho até a inscrição LIVE!”, com resumo por origem/meio/campanha UTM e detalhe por prova/cidade. A campanha conserva as chegadas apenas ao circuito e à navegação do Road Runners; visitar várias provas ou mudar a variante na mesma sessão não multiplica seu total de sessões.

| Medida | Definição no recorte |
| --- | --- |
| Sessões com abertura | Sessões distintas com pelo menos um `page_view` recebido da campanha. |
| Aberturas no Road Runners | `page_view_id` distintos com `page_view`, somados entre sessões. |
| Qualificadas | Sessões com abertura e 30 segundos ativos ou duas identidades de página abertas distintas. |
| Sessões com prova LIVE! | Sessões com `page_view` de prova do circuito `live-run-xp`; cada sessão/prova conta uma vez. |
| Sessões com saída | Sessões com o contrato de saída LIVE! recebido, deduplicadas por sessão/prova e novamente por sessão no total da campanha. |
| Visita + saída | Interseção na mesma sessão/prova; não prova compra nem uma ordem temporal de todos os eventos. |
| Taxa da campanha | Sessões com visita + saída de alguma prova / sessões com abertura da campanha. |
| Taxa da prova | Sessões com visita + saída daquela prova / sessões com visita àquela prova. |

Sem denominador ou sem saída recebida na linha, a taxa mostra `—`. Uma saída pelo modal do circuito pode existir sem abertura da página da prova: permanece no total de saídas, identificada pela prova de destino e com indicação “sem abertura correspondente”. Essa indicação também pode refletir perda de coleta. Não se fabrica uma visita para fechar o funil; por isso os totais brutos de saídas e de visita + saída podem diferir.

O relatório informa primeira recepção de saída no recorte usando `received_at` do servidor. Ausência de recepção não distingue falta de cliques de falta de instrumentação. A primeira recepção também não certifica cobertura completa nem data de ativação; não existe histórico retroativo de saídas.

## Filtros, atribuição e catálogo

- Filtros gerais de 7/30/90 dias, ambiente, região/UF, família, dispositivo e internos são aplicados antes da agregação. Representam atividade observada no recorte, não uma coorte vitalícia da sessão.
- Origem exata e campanha por trecho afetam resumo e detalhe. Cidade por trecho e ID da prova restringem apenas o detalhe, mantendo o denominador integral da campanha no recorte.
- Cidade/UF da prova vêm do cadastro atual; a UF geral continua usando a dimensão selecionada de visitante/perfil/contexto/mercado. Correções de cadastro podem alterar os rótulos do histórico.
- O relatório consome os rótulos sanitizados `source`, `medium`, `campaign` e conserva a atribuição que o produtor já registra no início da sessão. Não lê URL UTM bruta, não coleta dados pessoais novos e não infere último clique pago.
- Apenas campanhas UTM não vazias entram na seção. Não há filtro que presuma que uma campanha chamada LIVE! é paga: origem/meio ficam visíveis.
- Prova ausente do catálogo, mas com saída válida, continua visível por ID e cidade não informada. Uma saída válida também confirma o vínculo LIVE! de um ID cujo vínculo de catálogo tenha sido removido.
- São mostradas até 100 campanhas/origens e 200 combinações campanha/prova. Os totais são calculados antes dos limites; as linhas de prova não devem ser somadas para obter pessoas distintas.

## Contrato e arquivos

Saída: `event_kind='outbound_click'`, `content_type='event'`, `content_id` decimal positivo de até 10 dígitos, `event_key='outbound_click:live_registration:' || content_id`. O evento pode conservar a família/página do circuito quando veio de seu modal. Não exige `page_family='event'` para contar a saída. A visita à prova exige `page_view` com família/tipo `event`.

O produtor RoadRunners também introduz página de circuito com família/tipo `circuit`, ID do agregador e caminho canônico `/circuito/<tag>/`. O consumidor adiciona essa família aos filtros. O esquema existente suporta ambos; não há migration SQL.

Runtime Business — quatro arquivos:

- [Backend](/Users/Shared/Projects/RunnerHub/Business/portal/includes/audience_backend.cfm): valida filtros, consulta parametrizada, timeout de 15 segundos e cache de 1 minuto. A falha opcional desta consulta preserva os demais relatórios.
- [Página](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/home.cfm): preserva os filtros da jornada, adiciona navegação e inclui a seção.
- [Seção](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/live_journey.cfm): tabelas, filtros, taxas, estados sem coleta/indisponível; usa a guarda de administrador existente e saída HTML codificada.
- [SQL](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/live_journey.sql): usa o [filtro compartilhado](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/filter.sql), `audience.events`, `public.tb_evento_corridas` e `public.tb_agrega_eventos`. Requer SELECT nessas relações pelo datasource existente.

## Validação local

Os testes usam dados sintéticos e PostgreSQL temporário em socket local, sem banco ou credenciais de produção. TDD teve falha inicial por ausência do relatório e falhas específicas antes das correções de horário de recepção e taxa sem coleta.

- `node _codex/scripts/test_audience_live_report_local.mjs`: **28 asserções comportamentais SQL**. Inclui repetição de CTA, várias provas/variantes, sessões do mesmo visitante, circuito sem prova, saída de modal sem abertura, catálogo ausente, key inválida, ambiente/internos/UF/dispositivo, filtros literais, denominador preservado e histórico sem saídas.
- `node _codex/scripts/test_audience_live_cfml_local.mjs`: **15 asserções renderizadas** em Lucee local. Inclui taxas, HTML escapado, tag de link insegura, cidade ausente, escopos preservados e estado indisponível.
- `NODE_PATH=<pacotes Node locais> node _codex/scripts/test_audience_live_browser.mjs <HTML retornado pelo runner CFML>`: **desktop 1440px e celular 390px**, formulários e escopo, tabelas com rolagem local, ausência de overflow da página e funcionamento sem JavaScript. Capturas revisadas visualmente.
- Regressões: SQL de audiência existente **51**, renderização do home editorial **11**, gráficos Node **5** asserções/testes aprovados. O runner editorial usou um wrapper Java temporário para executar o CommandBox existente com saída UTF-8.

Fixtures: [SQL e cenário](/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/test_audience_live_report_local.mjs), [CFML sintético](/Users/Shared/Projects/RunnerHub/Business/_codex/tests/audience-live-business/fixture.cfm), [runner CFML](/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/test_audience_live_cfml_local.mjs), [runner browser](/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/test_audience_live_browser.mjs). Os runners locais não substituem a compilação Adobe nem a verificação autenticada após publicação.

## Ordem de publicação e limites

Publicar primeiro a consulta SQL e a seção CFML, depois o backend e a página que as consomem, preferencialmente como pacote validado. A consulta SQL deve conservar o bloqueio HTTP existente do diretório `queries`. O consumidor pode preceder o produtor e exibir ausência de saídas; o produtor pode precedê-lo porque os eventos usam o esquema já existente. Conferir hashes, compilação Adobe, relatório autenticado e recepção de um fluxo de teste controlado. Rollback do Business restaura os quatro arquivos anteriores e remove os dois novos conforme manifesto, sem remover eventos coletados.

Nada neste relatório calcula gasto por prova, compras, comissão, CPA ou ROI. Cupom público comum e planilha contendo apenas totais por cupom não atribuem uma compra ao Google Ads. Compras confirmadas exigem conciliação LIVE!; importação de conversões exige vínculo elegível aprovado pela plataforma, como um identificador de clique capturado e conciliado sob suas regras. O painel de Audiência continua usando “pedidos” para requisições de anúncio, não inscrições.
