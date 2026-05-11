# Banco e Entidades

## Visao geral

O modelo de dados nao esta centralizado em um unico lugar. Ele precisa ser inferido dos backends e queries embutidas.

## Entidades nucleares observadas

### Usuarios

Tabelas frequentemente citadas:

- `tb_usuarios`
- `tb_paginas_usuarios`

Campos recorrentes:

- `id`
- `name`
- `email`
- `is_admin`
- `is_partner`
- `is_dev`
- `strava_id`
- `partner_info`

### Paginas / perfis

Tabela:

- `tb_paginas`

Campos recorrentes:

- `id_pagina`
- `nome`
- `tag`
- `tag_prefix`
- `path_imagem`
- `cidade`
- `uf`
- `instagram`
- `youtube`
- `website`

### Permissoes e BI

Tabelas:

- `tb_permissoes`
- `tb_bi`
- `tb_agregadores`
- `tb_agrega_eventos`
- `tb_temas`

Uso principal:

- montagem de escopo visual e operacional do usuario
- navegacao por agregadores e temas

### Midia do Portal

Tabela:

- `tb_media`

Campos inferidos do modulo Portal:

- `id_media` ou equivalente
- `media_titulo`
- `media_url`
- `media_tipo`
- `media_canal_nome`
- `media_canal_slug`
- `data_publicacao`
- `pub_status`

### Canais do YouTube

Tabela:

- `tb_youtube_canais`

Campos inferidos:

- `id_youtube_canal`
- `name`
- `id_pagina`
- `id_usuario`
- `max_results`
- `sort`
- booleano de status

### Configuracao de treinos

Tabela:

- `tb_evento_treinos_config`

Comportamento observado:

- tela dinamica baseada em metadata de coluna
- datas de inscricao
- limite de inscritos
- relacao com `tb_evento_corridas`

### Conteudo editorial externo

Tabela:

- `news.tb_content_types`

Uso atual dentro do Business:

- governanca de canais editoriais do portal

Flags adicionais esperadas:

- `rr_portal_enabled`
- `rr_home_featured_enabled`
- `rr_news_featured_enabled`

## Entidades de leaderboard

Tabelas observadas:

- `tb_resultados_temp`
- `tb_leaderboard_marca`
- `tb_leaderboard_pc`
- `tb_leaderboard_evento`

Uso:

- ranking
- parciais
- pace
- previsao de chegada
- startlists e widgets de transmissao

## Entidades de log

Tabelas observadas:

- `tb_log`
- referencia comentada a `webtumtum.logs`

Uso:

- login / logout
- rastreamento de eventos operacionais
- rastreamento historico em trechos legados

## Observacao metodologica

Como nao ha dicionario de dados consolidado no repositorio, futuras integracoes devem sempre validar:

1. nome exato das colunas em producao
2. constraints e defaults reais do banco
3. se o modulo usa reflection via `information_schema`
4. se a tabela e do schema `public` ou `news`
