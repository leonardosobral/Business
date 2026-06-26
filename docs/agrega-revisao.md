# Revisao de agregadores de eventos

O Business possui uma area administrativa em `/administracao/agrega-revisao/` para revisar sugestoes de eventos que provavelmente sao edicoes anuais do mesmo evento.

## Objetivo

- Comparar eventos de `tb_evento_corridas`.
- Considerar nome e cidade/UF.
- Ignorar anos e edicoes no nome durante a normalizacao.
- Nunca alterar `tb_evento_corridas.id_agrega_evento` automaticamente durante a geracao.
- Permitir que um admin aplique manualmente um agregador existente de `tb_agrega_eventos` aos eventos selecionados.
- Permitir criar manualmente um novo agregador quando nenhum existente representar o grupo sugerido.

## Banco

Antes de usar a tela, aplique:

`/administracao/agrega-revisao/agrega_review_schema.sql`

As tabelas auxiliares criadas sao:

- `tb_evento_agrega_review_groups`
- `tb_evento_agrega_review_candidates`

Elas armazenam apenas a fila de revisao e auditoria. O vinculo real continua em `tb_evento_corridas.id_agrega_evento`.

O campo `display_name` em `tb_evento_agrega_review_groups` guarda a sugestao humana para o nome do agregador, preservando acentuacao e capitalizacao, enquanto `normalized_name` permanece para busca/comparacao.

Grupos onde todos os eventos ja possuem o mesmo `id_agrega_evento` nao sao acionaveis e nao devem permanecer na revisao. A fila mostra apenas grupos em `review` com algum evento sem agregador ou com agregadores divergentes.

## Fluxo

1. O admin acessa `/administracao/agrega-revisao/`.
2. Clica em `Gerar sugestões`.
3. O sistema compara eventos ativos da mesma cidade e UF.
4. A tela lista grupos similares com score.
5. O admin escolhe um agregador existente.
6. O admin marca os eventos que devem receber esse agregador.
7. Ao aplicar, o sistema atualiza `tb_evento_corridas.id_agrega_evento` somente para os eventos selecionados.

Quando nao houver agregador adequado:

1. No proprio grupo, o admin usa `Criar agregador para este grupo`.
2. Informa os campos reais de `tb_agrega_eventos`: nome, tipo, tag, tema, divisao e ordem.
3. O sistema cria o registro em `tb_agrega_eventos`.
4. O novo agregador passa a ficar selecionado como sugestao daquele grupo.
5. O admin ainda precisa clicar em `Aplicar aos selecionados` para alterar os eventos.

Antes de criar, o sistema verifica se ja existe agregador com o mesmo nome ou com a mesma tag informada. Se existir, ele nao cria duplicado; apenas seleciona o agregador existente para o grupo e exibe aviso na tela.

## Pontuacao

O score e composto por:

- Similaridade de tokens do nome normalizado.
- Cidade/UF como filtro obrigatorio e componente fixo de confianca.

Datas nao entram no score, pois edicoes anuais devem poder ser agrupadas.
