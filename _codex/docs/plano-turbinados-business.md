# Plano - Turbinados Business

## Objetivo

Transformar `/ads/` na principal tela de valor do Road Runners Business: o usuario deve entender quanto credito tem, quais eventos estao sendo impulsionados, qual retorno esta tendo e o que fazer para melhorar a divulgacao dos eventos no RoadRunners.run.

A logica se aproxima do Google Ads, mas com linguagem de organizador de eventos: o foco nao e "campanha abstrata", e sim "turbinar uma prova" para ela aparecer com destaque em busca, listagens e areas editoriais/comerciais do RoadRunners.run.

## Principios de produto

- A tela deve responder rapidamente: o topo mostra leitura executiva; os detalhes ficam abaixo.
- O usuario precisa enxergar valor antes de configurar: alcance, cliques, taxa de click, custo e saldo.
- Usar termos do negocio: "Turbinar evento", "Eventos em destaque", "Credito Ads", "Clicks", "Taxa de click".
- Evitar metricas tecnicas ou internas. Nada de logs, erro, 404, tempo de query ou infraestrutura nesta area.
- Dados sempre restritos a conta efetiva em `VARIABLES.businessEffectiveAccountIds`.
- Admin simulando conta deve ver exatamente a mesma experiencia da conta.

## Estado atual

- `/ads/` ja restringe dados por conta quando o usuario nao e admin efetivo global.
- A criacao de campanha usa eventos ativos vinculados a conta.
- Existe credito por voucher em `tb_ad_vouchers`.
- Voucher e ativado dentro de `/ads/`; `/cadastro/` fica somente para solicitacao de acesso Business.
- Existe consumo em `tb_ad_log`.
- A tabela de campanhas ja mostra views, clicks, taxa, CPC medio e custo.
- O topo foi reduzido para 4 cards: Performance, Investimento, Credito Ads e Campanhas.

## MVP visual da tela

- [x] Reduzir widgets do topo para no maximo 4 cards.
- [x] Consolidar views/clicks/taxa em um card de Performance.
- [x] Consolidar investimento/CPC/conversao em um card financeiro.
- [x] Consolidar credito/saldo/uso em um card de Credito Ads.
- [x] Consolidar total/ativas/pausadas/finalizadas em um card de Campanhas.
- [x] Ajustar o bloco "Credito de ads" para nao repetir informacao do topo quando nao houver vouchers.
- [x] Transformar "Turbinar Evento" em um painel de acao mais compacto quando nao houver formulario aberto.
- [x] Melhorar estados vazios: sem credito, sem evento aprovado, sem campanha ativa e campanha aguardando aprovacao.

## Indicadores principais

### Performance

- Views: exibicoes do destaque.
- Clicks: cliques no destaque/evento.
- Taxa de click: `clicks / views`.
- Tendencia: comparacao contra periodo anterior.

### Investimento

- Custo consumido.
- CPC medio.
- Orcamento planejado.
- Limite diario ativo.

### Credito

- Credito total resgatado.
- Credito usado.
- Saldo disponivel.
- Vouchers ativos/expirando.

### Campanhas

- Ativas.
- Em aprovacao.
- Pausadas.
- Finalizadas.
- Eventos sem campanha ativa, mas elegiveis para turbinar.

## Graficos recomendados

### Linha diaria

Grafico principal com periodo selecionavel:

- ultimos 7 dias;
- ultimos 30 dias;
- mes atual;
- periodo personalizado.

Series:

- views por dia;
- clicks por dia;
- custo por dia;
- taxa de click como linha secundaria.

### Funil simples

Um bloco compacto:

1. Impressoes/views.
2. Clicks.
3. Acessos ou redirecionamentos para inscricao quando a fonte estiver confiavel.

No primeiro corte, a etapa 3 pode ficar como "em breve" ou usar apenas clicks se ainda nao houver evento de conversao.

### Ranking de eventos

Tabela curta com os 5 eventos com melhor desempenho:

- evento;
- status da campanha;
- views;
- clicks;
- taxa de click;
- custo;
- CPC medio;
- saldo/limite restante da campanha.

### Alertas comerciais

- Campanha ativa sem views nos ultimos dias.
- Campanha com clicks, mas taxa baixa.
- Credito acabando.
- Evento proximo sem campanha ativa.
- Campanha aguardando aprovacao.

## Acompanhamento temporal

### Diario

Mostrar "Hoje" e "Ontem":

- views;
- clicks;
- gasto;
- taxa de click.

Objetivo: o usuario abre a tela e entende se a divulgacao esta rodando.

### Semanal

Comparar ultimos 7 dias contra 7 dias anteriores:

- variacao de views;
- variacao de clicks;
- variacao do custo;
- variacao da taxa de click.

Objetivo: orientar melhora de campanha e budget.

### Mensal

Resumo do mes:

- investimento acumulado;
- credito restante;
- eventos turbinados;
- melhores campanhas;
- campanhas que precisam de acao.

Objetivo: prestacao de contas e tomada de decisao.

## Estrutura sugerida da pagina

### 1. Cabecalho

- Titulo: `Turbinados`.
- Subtitulo: `Destaque seus eventos no RoadRunners.run`.
- CTA primario: `Turbinar evento`.
- CTA secundario: `Resgatar voucher` ou `Ver credito`.

### 2. Resumo executivo

Quatro cards:

- Performance.
- Investimento.
- Credito Ads.
- Campanhas.

### 3. Grafico principal

Card largo com:

- seletor de periodo;
- linha/barras por dia;
- toggles para views, clicks, custo e taxa.

### 4. Acoes recomendadas

Lista curta com no maximo 3 recomendacoes acionaveis:

- "LIVE! RUN XP Jundiai 2026 esta proximo e nao tem campanha ativa."
- "A campanha X tem boa taxa de click; considere aumentar limite diario."
- "Seu credito acaba em aproximadamente N dias no ritmo atual."

### 5. Campanhas

Tabs atuais podem permanecer, mas com melhorias:

- Ativas.
- Em aprovacao.
- Pausadas.
- Finalizadas.

Cada linha deve ter:

- evento;
- status;
- periodo;
- views;
- clicks;
- taxa;
- custo;
- CPC medio;
- limite diario;
- acoes.

### 6. Credito e vouchers

Virar bloco menor ou aba secundaria:

- saldo;
- vouchers disponiveis para ativacao na conta;
- vouchers resgatados;
- vencimentos;
- historico.

Nao deve ocupar muito espaco quando nao houver voucher.

## Dados necessarios

### Fontes atuais

- `tb_ad_eventos`: configuracao da campanha.
- `tb_ad_log`: views/clicks/custo.
- `tb_ad_vouchers`: credito.
- `tb_conta_eventos`: eventos liberados da conta.
- `tb_evento_corridas`: metadados do evento.

### Agregacoes recomendadas

Para performance, evitar recalcular tudo em tela a cada request quando o volume crescer.

Criar uma view/materialized view ou tabela diaria:

`tb_ad_evento_metricas_dia`

Campos sugeridos:

- `data_metrica date`;
- `id_ad_evento bigint`;
- `id_evento integer`;
- `id_conta bigint`;
- `views integer`;
- `clicks integer`;
- `custo numeric`;
- `created_at timestamp`;
- `updated_at timestamp`.

Indices:

- `(id_conta, data_metrica)`;
- `(id_ad_evento, data_metrica)`;
- `(id_evento, data_metrica)`.

Essa estrutura permite grafico diario/semanal/mensal sem varrer `tb_ad_log` em tempo real.

## Conversao

No MVP, taxa de click pode ser chamada de taxa de click, nao taxa de conversao final.

Para conversao real, definir o que conta:

- click para pagina do evento;
- click em inscricao;
- redirecionamento para plataforma externa;
- inscricao confirmada quando houver integracao.

Definicao inicial para o Business: `INSCRICAO_CLICK` e a primeira conversao real exibida na tela. `INSCRICAO_CONFIRMADA` fica reservada para quando houver integracao confiavel com a plataforma de inscricao.

Tabela/evento futuro recomendado:

`tb_ad_conversion_log`

Campos sugeridos:

- `id_conversion bigserial`;
- `id_ad_evento bigint`;
- `id_evento integer`;
- `id_conta bigint`;
- `tipo_conversion varchar`: `EVENTO_VIEW`, `INSCRICAO_CLICK`, `INSCRICAO_CONFIRMADA`;
- `valor numeric null`;
- `data_criacao timestamp`;
- `metadata jsonb`.

## Fases de implementacao

### Fase 1 - Produto e layout

- [x] Redesenhar `/ads/` com cabecalho, 4 cards, grafico inicial e campanhas.
- [x] Diminuir/recolher bloco de vouchers.
- [x] Melhorar estados vazios e textos de acao.
- [x] Garantir boa leitura em 1366px com menu aberto.
- [x] Criar estado inicial guiado sem KPIs zerados quando a conta ainda nao tem campanhas.
- [x] No primeiro uso, orientar voucher, solicitacao de vinculo de evento por URL/tag/nome e criacao da primeira campanha.

### Fase 2 - Metricas por periodo

- [x] Criar consulta agregada por dia usando `tb_ad_log`.
- [x] Adicionar seletor 7/30 dias.
- [x] Exibir grafico de views, clicks e custo.
- [x] Exibir comparacao com periodo anterior.

### Fase 3 - Agregacao escalavel

- [x] Propor DDL de `tb_ad_evento_metricas_dia`.
- [x] Criar job ou rotina de consolidacao diaria.
- [x] Trocar grafico para usar a tabela agregada quando existir.
- [x] Manter fallback por `tb_ad_log` apenas para ambiente sem agregacao.

### Fase 4 - Recomendacoes

- [x] Criar cards de recomendacao com regras simples.
- [x] Evento proximo sem campanha ativa.
- [x] Credito acabando.
- [x] Campanha com CTR baixo.
- [x] Campanha performando bem com budget limitado.

### Fase 5 - Conversao real

- [x] Definir evento de conversao.
- [ ] Instrumentar click de inscricao/origem.
- [x] Criar tabela/log de conversao.
- [x] Exibir taxa de conversao separada de taxa de click.

Status da instrumentacao: o Business ja possui o endpoint `/api/ads/conversion-click.cfm` para registrar `INSCRICAO_CLICK` em `tb_ad_conversion_log` e redirecionar para a inscricao/hotsite do evento. Para admin, a tabela de campanhas ativas tambem exibe um link de teste para validar esse redirecionamento. Falta o site publico RoadRunners.run trocar os links de inscricao originados de destaque/turbinado para passar por esse endpoint.

Contrato recomendado para o site publico:

```text
/api/ads/conversion-click.cfm?id_ad_evento=123&tipo=INSCRICAO_CLICK&origem=busca
```

`id_ad_evento` e o caminho preferencial. Se o site publico tiver apenas `id_evento`, o endpoint aceita `id_evento=456` e tenta localizar uma campanha ativa do evento. A campanha precisa estar aprovada/ativa (`status = 2`) e dentro da janela de inicio/fim quando essas datas existirem. O destino nao vem por parametro para evitar redirect aberto; o Business busca `url_inscricao`, depois `url_hotsite`, depois a pagina publica do evento.

## Criterios de aceite

- Usuario de conta entende em menos de 10 segundos se seus eventos estao sendo divulgados e se precisa agir.
- Tela nao mostra mais de 4 cards no topo.
- A tabela detalhada continua disponivel, mas nao domina o primeiro viewport.
- Graficos e metricas respeitam a conta efetiva.
- Admin simulando conta ve os mesmos numeros da conta.
- Nao ha metricas tecnicas/internas expostas para cliente.
- A tela permanece utilizavel em 1366px de largura com o menu aberto.
