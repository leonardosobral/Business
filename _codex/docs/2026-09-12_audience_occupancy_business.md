# Business — resumo de potencial e ocupação

> **Definição superada:** o usuário esclareceu que o potencial deve incluir oportunidades sem campanha e sem visibilidade. A definição abaixo, baseada em `slot_viewable`, excluía espaços vazios recolhidos e não respondia à necessidade comercial. Ver a [correção de oportunidades de entrega](2026-09-12_audience_delivery_opportunities.md). Este documento preserva o histórico da primeira implementação, não deve governar o novo indicador.

Implementação de 12/09/2026, **publicada às 22:36:23 de Brasília** após a instrução “no final sempre publique”. Conferência autenticada do novo resumo concluída em produção. [Recibo de publicação](2026-09-12_audience_occupancy_publicado.md). A publicação anterior de capacidade permanece independente.

## Escopo aprovado

O topo passa de seis contadores técnicos para três indicadores da mesma população: potencial observado, preenchidos e sem anúncio. Visitantes estimados e sessões ficam juntos em Audiência, com sessões qualificadas e páginas com atividade como apoio. Duas barras mostram Ads e banners em quantidade e percentual; outros formatos aparecem apenas quando observados. Institucionais entram em preenchimento. Consumo de créditos, receita e “realmente pago” foram explicitamente adiados.

Os sinais técnicos antigos não foram removidos: ficam em detalhes recolhidos, junto das definições. Filtros, abas, tabelas, relatórios editoriais, LIVE, retenção e cenários de capacidade continuam existentes. Não há alteração em RoadRunners, banco, permissões, autenticação, carteira nem tb_log.

## Definições e origem

Fonte de produção: `audience.events`, lida pelo DSN já existente `runnerhub`.

- A primeira `slot_opportunity` fixa identidade por `page_view_id + slot_key + UF da dimensão selecionada`, incluindo família/dispositivo. Os filtros são aplicados a essa identidade; depois as UFs selecionadas são colapsadas por `page_view_id + slot_key`.
- **Registradas:** observações físicas com oportunidade dentro do período, incluindo aquelas não vistas. Ficam em segundo plano, sem inferir entrega.
- **Potencial observado:** físicas registradas com `slot_viewable` na mesma observação regional e dentro da mesma janela. Não soma rotações, campanhas nem contextos regionais sobrepostos.
- **Preenchidas:** há `slot_viewable` com `filled`/`house`, ou `ad_viewable` com esse estado e ambos os IDs válidos, desde que a mesma observação regional tenha visibilidade física. Um anúncio em SP não preenche a observação filtrada para SC.
- **Sem anúncio:** nenhum preenchimento demonstrado, todos os estados visíveis indicam `empty` e nenhum sinal de anúncio incompatível invalida essa conclusão.
- **Sem classificação:** há visibilidade física mas evidência insuficiente/conflitante sobre ocupação. `disabled` e eventos malformados não viram espaço vazio.
- Potencial = preenchidas + sem anúncio + sem classificação. Percentuais usam potencial da própria linha; total geral e formatos são calculados antes de qualquer limite de apresentação.
- Formatos usam listas explícitas de slots e placements existentes. Slots/placements não reconhecidos ou conflitantes ficam em outros formatos, inclusive conflitos entre UFs selecionadas.

A janela começa à meia-noite de Brasília e termina no instante da consulta. 7/30/90 dias incluem hoje; não são períodos completos para previsão. UF comercial, de acesso, perfil e contexto permanecem alternativas distintas. Diagnósticos permitem ambiente e acessos internos selecionados, sem convertê-los em cenários comerciais.

### Limites

O produtor mantém o primeiro estado de cada `slot_viewable`, atualizando durações posteriormente. Sinais próprios de anúncio podem complementar a ocupação, mas mudanças sem evento persistido não são reconstruídas. Ocupação não comprova um segundo de exposição de cada criativo nem cobrança. Bloqueios, opt-out, lacunas de coleta e posições recolhidas limitam a cobertura. Os números físicos podem diferir dos antigos sinais técnicos e de somas de linhas regionais.

## Arquivos de publicação

1. `portal/audiencia/queries/occupancy.sql` — consulta nova, somente leitura; não é migração a executar no banco.
2. `portal/audiencia/occupancy.cfm` — topo e barras HTML sem dependência de JavaScript.
3. `portal/includes/audience_backend.cfm` — leitura opcional, mesmos sete filtros tipados, timeout 15s e cache 1min; valida formato/partições e preserva os demais relatórios em caso de falha.
4. `portal/audiencia/home.cfm` — inclui o novo topo.
5. `assets/css/audience-dashboard.css` — composição responsiva.

Os dois arquivos novos foram publicados antes de ativar os includes consumidores. Backup dos três arquivos substituídos preservado; os arquivos novos podem permanecer inativos em um rollback. Não foi necessário reiniciar aplicação nem alterar DSN. CFML Adobe real e consulta do resumo confirmados no painel autenticado, com totais conciliados e bloqueio HTTP direto do SQL. Não foi realizado teste de carga nem medição isolada de tempo da consulta.

## Verificações locais

- PostgreSQL 16 descartável, socket Unix sem TCP, papel apenas SELECT: `_codex/scripts/test_audience_occupancy_report_local.mjs`, 1047 assertions. Cobriu todos os formatos explícitos, sobreposição UF, rotações, estados vazios/desconhecidos/house, ad-only, filtros, limites exatos de data, valores com aparência de injeção, 205 slots sem truncamento e comparação física com capacity.sql. Acesso de escrita existe somente no administrador da fixture sintética descartável.
- RED inicial: consulta ausente. Refinamento conservador RED: fixture de anúncio incompatível retornava `[14,13,1,4,8]`, esperado `[14,13,1,0,12]`; corrigido sem alocar exposição desconhecida como vazio.
- CFML Lucee real, sem bootstrap/DSN: 19 verificações renderizadas do topo, incluindo 100 = 60 preenchidas + 30 vazias + 10 desconhecidas, denominadores, vazio, sem visibilidade e consulta indisponível.
- Backend real com substituição apenas da operação de banco: 17 verificações de parâmetros/DSN/cache, isolamento de erro, zero verdadeiro, schema ausente e resultado inválido, além de 8 verificações preexistentes de capacidade.
- Regressão editorial CFML: 11 verificações. Node: 5 testes de gráficos e 1 guarda do literal incompatível com binding Adobe.
- Chrome com HTML gerado pelo CFML, dados sintéticos e rede externa bloqueada: 1440, 768 e 390 px, largura real dos segmentos, nomes acessíveis, contadores, disclosure, seis abas, teclado/histórico, filtros GET e ausência de overflow. Fallbacks sem JavaScript, sem biblioteca de gráficos e JSON de gráficos inválido passaram. Inspeção visual das capturas desktop/mobile realizada.
- Revisão independente somente leitura aprovada, sem achados materiais. Referência CSS incrementada para `20260912-occupancy1` para não reutilizar o estilo antigo após publicação.
- Limite dos testes locais: Lucee e a guarda estática não equivalem à execução da consulta pelo Adobe em produção. Essa execução foi posteriormente confirmada na publicação, com valores reais registrados no recibo; performance/carga permanecem não medidas.
