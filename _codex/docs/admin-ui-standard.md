# Admin UI Standard

Camada comum: `/assets/css/business-ui.css`, carregada em `includes/estrutura/head.cfm`.

## Classes base

- `business-page`: escopo da tela administrativa.
- `business-page-card`: card principal ou card de bloco.
- `business-page-body`: padding padronizado do corpo do card.
- `business-page-header`: cabecalho da tela/bloco com separador inferior.
- `business-page-title`: titulo principal compacto.
- `business-page-actions`: grupo de botoes no cabecalho.
- `business-kpi-grid`: grid responsivo de indicadores.
- `business-kpi` e `business-kpi-value`: card de indicador, pode ser `<a>`.
- `business-tabs` e `business-tab-count`: abas de secoes operacionais.
- `business-filterbar`: area de filtros.
- `business-panel`: painel interno ou card operacional menor.
- `business-table`: tabela administrativa.
- `business-row-actions`: celula de acoes com botoes compactos.
- `business-text-wrap`: quebra defensiva para textos longos.

## Padrao de tela

1. Envolver a tela em `section.business-page`.
2. Usar um `card.shadow-0.business-page-card` com `card-body.business-page-body`.
3. Criar um cabecalho com `business-page-header`, titulo em `business-page-title` e acoes em `business-page-actions`.
4. Usar `business-kpi-grid` para indicadores e transformar indicadores navegaveis em links.
5. Usar `business-filterbar` para filtros com botao principal + acao de limpar.
6. Usar `business-table` e `business-row-actions` para listas operacionais.

## Telas ja migradas

- `/administracao/cron-jobs/`
- Home logada admin
- `/administracao/foco-revisao/`
- `/administracao/agrega-revisao/`
- `/administracao/permissoes/`
