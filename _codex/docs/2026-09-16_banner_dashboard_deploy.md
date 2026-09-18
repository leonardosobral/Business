# Painel de banners — publicado em 16/09/2026

## Escopo

Somente Business: `portal/banners/home.cfm`, os três includes
`banner_dashboard_backend.cfm`, `banner_dashboard_helpers.cfm`,
`banner_dashboard_list.cfm`, `assets/css/portal-banner-dashboard.css` e
`assets/js/portal-banner-dashboard.js`.

Header Marketing/Banners, resumo histórico, gráfico diário de impressões visíveis
e cliques válidos (7/30 dias e banner individual), listagem compacta com expansão
nativa por clique ou teclado. Imagens, estados, páginas, período, destino e ações
ficam nos detalhes. O formulário existente e as regras de CSRF, administração e
pausa antes de editar foram preservados. Indicadores da listagem são históricos;
os do gráfico respeitam o filtro. CTR sem impressões aparece como travessão.

Leitura de `ads.daily_metrics` restrita a HOUSE/BANNER e à conta institucional,
com dias sem registros preenchidos com zero. Sem migration, alterações de dados,
mudanças no RoadRunners ou operações Git. O gráfico reutiliza a configuração e
o componente MDB Chart existentes em Ads, removendo apenas a série monetária.

## Verificações executadas

- Node: 12 testes aprovados (dashboard novo, Ads existente, upload HTTPS e escopo).
- CFML offline: 13 verificações do novo painel; regressão completa de
  `banner-scope-form.cfm` aprovada, incluindo renderização real e upload.
- Compilação nativa Adobe ColdFusion: 4/4 templates aprovados.
- Revisão independente: sem defeitos críticos/importantes; ajuste de rótulos
  acessíveis aplicado antes da publicação.
- `git diff --check` sem erros.
- Produção/Chrome: gráfico renderizado; filtro Avaí/7 dias retorna 7 datas
  (10–16/09), 2.044 impressões e 8 cliques, iguais à soma do JSON do gráfico.
- Lista Rascunho vazia exibe mensagem explícita sem alterar filtro do gráfico.
- Maratona de Floripa/7 dias exibe zero registros e CTR indisponível corretamente.
- Expansão e recolhimento por Enter verificados; Avaí mostra SC, os outros
  mostram Todo o Brasil. Nenhum botão de mutação foi acionado durante testes.
- Desktop 1280px e mobile 390px verificados visualmente; mobile com detalhe aberto
  tem largura de documento e viewport de 390px, sem overflow horizontal.
- Formulário Novo banner e retorno por Cancelar verificados; viewport restaurado.

## Publicação e recuperação

Manifesto final: `2026-09-16_banner_dashboard_release_v2.json`.
Recibos prepare/publish/verify: `2026-09-16_banner_dashboard_prepare_v2*.json`.
Backup: `/var/backups/house-banner-scope.aa9b8a1c8498`.
Os 6 arquivos publicados, backup e 115 arquivos protegidos foram verificados.
O baseline de home correspondia exatamente à publicação anterior de regionalização.
A primeira preparação não foi publicada; v2 adicionou labels acessíveis e a
condição explícita para lista sem campanhas antes do deploy.

Rollback controlado (somente se necessário, sem sobrescrever mudanças posteriores):

```sh
python3 _codex/scripts/deploy_banner_dashboard.py rollback _codex/docs/2026-09-16_banner_dashboard_release_v2.json _codex/docs/2026-09-16_banner_dashboard_prepare_v2.json
```
