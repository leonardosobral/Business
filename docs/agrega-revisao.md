# Revisao de agregadores de eventos

O Business possui uma area administrativa em `/administracao/agrega-revisao/` para revisar sugestoes de eventos que provavelmente sao edicoes anuais do mesmo evento.

## Objetivo

- Comparar eventos de `tb_evento_corridas`.
- Considerar nome, cidade/UF, país e tipo de corrida.
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
3. O sistema compara os calendários completos dos dois anos e sugere pares de eventos ativos.
4. A tela lista pares com os critérios de correspondência.
5. O admin escolhe um agregador existente.
6. O admin marca os eventos que devem receber esse agregador.
7. Ao aplicar, o sistema atualiza `tb_evento_corridas.id_agrega_evento` somente para os eventos selecionados.

Quando nao houver agregador adequado:

1. No proprio grupo, o admin usa `Criar agregador para este grupo`.
2. Informa os campos reais de `tb_agrega_eventos`: nome, tipo, tag, tema, divisao e ordem.
3. O sistema cria o registro em `tb_agrega_eventos`.
4. O novo agregador passa a ficar selecionado como sugestao daquele grupo.
5. O admin ainda precisa clicar em `Aplicar aos selecionados` para alterar os eventos.

Na tela de detalhe, `Criar agregador` e `Aplicar aos selecionados` executam a ação ao clicar, sem diálogo de confirmação. As validações dos campos e as permissões administrativas continuam no fluxo existente.

Antes de criar, o sistema verifica se ja existe agregador com o mesmo nome ou com a mesma tag informada. Se existir, ele nao cria duplicado; apenas seleciona o agregador existente para o grupo e exibe aviso na tela.

## Geração por edições — 27/09/2026

A geração usa dois anos consecutivos escolhidos na tela (por padrão, anterior e atual), sem o antigo limite de 5.000 eventos ordenados por cidade. A data de referência é `coalesce(data_final, data_inicial)`. Não depende de resultados coletados: calendários completos incluem provas futuras.

`includes/matching.cfm` é a implementação do Business; não depende de arquivos do estudo no RoadRunners. O estudo usa uma coorte com período e resultados elegíveis adicionais, por isso a quantidade de sugestões desta ferramenta não é o tamanho da coorte.

Critérios:

- Nome idêntico após remover acentos, pontuação, os dois anos comparados e ordinais explícitos de edição ou no início do nome. Um ordinal antes de `Etapa` é preservado. Distâncias, números de etapas, patrocinadores e outros anos no nome são preservados.
- Pelo menos três palavras e 15 caracteres no nome normalizado.
- Mesma cidade, UF, país e tipo de corrida, todos preenchidos.
- Exatamente um evento de cada ano para essa chave, contando também inativos para não esconder ambiguidades; ambos precisam estar ativos para gerar sugestão.
- Data comparada deslocada para o ano base a até 90 dias da outra edição. O ajuste de ano trata 29/02.
- Se os dois nomes informam número de edição, os números precisam ser consecutivos.
- Eventos vinculados a agregadores `circuito` não entram. Pares que já usam o mesmo agregador também não precisam de sugestão.

Nomes alterados, múltiplas edições anuais, circuitos e mudanças grandes de calendário continuam acessíveis na busca/criação manual. A geração antiga por similaridade de tokens foi substituída por correspondência exata normalizada; score não representa probabilidade. Os grupos novos guardam 100 nos campos legados de score para compatibilidade, e a tela explica o critério.

Cada sugestão nova é um par, com chave estável `edicoes-v1:<id antigo>:<id novo>`. Não encadeia A≈B≈C. A geração grava somente as tabelas de revisão. O vínculo real só é alterado por `Aplicar aos selecionados` no detalhe ou `Aceitar sugestão` na listagem, após decisão do administrador.

A geração preserva pares existentes em qualquer status e pula eventos ativos em outra revisão pendente. Um advisory lock transacional evita duas gerações simultâneas. Quando só um agregador já existe, ele é sugerido; quando existem dois divergentes, o administrador precisa escolher. Repetir a geração não recria pares aplicados ou ignorados.

A lista agora tem contadores reais, busca, ordenação e paginação de dez grupos. O resumo abre a revisão completa pelo link do grupo. O status atual dos vínculos vem de `tb_evento_corridas`, sem modificar a fotografia histórica na tabela de candidatos. Páginas que ficaram vazias voltam à primeira página mantendo os filtros. Filtros de aplicados/ignorados exibem o histórico em modo de consulta.

## Verificação e publicação

- Testes do normalizador e dos pares: `_codex/tests/agrega_edicoes_test.cfm` (colocar junto de uma cópia de `matching.cfm` em ambiente de teste protegido; não publicar os testes como página aberta).
- Publicação limitada aos três arquivos de runtime: `includes/matching.cfm`, `includes/backend.cfm` e `home.cfm`.
- Sem migração de schema, alteração de autenticação ou dependência nova. O `index.cfm` mantém login e `require_admin.cfm`.
- Verificar geração repetida, histórico, busca/paginação, visualização desktop/mobile e ausência de alterações nos vínculos antes/depois de gerar.

## Resultado da publicação

Publicado em 27/09/2026, com compilação dos três templates e backup em `/var/backups/business-agrega-edicoes-20260927/baseline`. A geração autenticada analisou 19.515 eventos de 2025–2026 e criou **1.036 pares pendentes**; um par já estava no histórico. Repetir a operação criou zero novos pares. Os hashes dos vínculos dos 34.181 eventos e do histórico anterior permaneceram iguais; não há evento em duas revisões pendentes. Os 24 casos automatizados passaram. Busca com acento, paginação, revisão individual e layout de 390 px foram conferidos no Chrome autenticado.

Recibos e resultados ficam em `_codex/docs/agrega_edicoes_2026_09_27/`. Nenhum agregador foi criado e nenhum vínculo foi aplicado nesta publicação; esses passos continuam manuais.


## Aceitar sugestão na listagem — 27/09/2026

Pares `edicoes-v1:` em revisão, com exatamente duas candidatas ativas, duas provas ativas sem agregador e sem agregador sugerido, mostram o campo **Nome do agregador** preenchido com a sugestão e o botão **Aceitar sugestão**. O nome é editável. Um clique cria o agregador e vincula as duas provas, sem diálogo adicional. **Revisar este par** continua disponível para conferir detalhes ou escolher campos avançados.

O atalho usa os mesmos valores iniciais do formulário detalhado: tipo `corrida`, tema `1`, divisão `distancia`, ordem `300` e tag vazia. As três mudanças (criação, vínculos e auditoria da revisão) pertencem à mesma transação. O servidor exige POST com token da sessão e verifica novamente o grupo, os IDs exibidos, os status e os vínculos atuais com bloqueio de linhas. Um envio repetido de grupo já aplicado não cria outro agregador.

Se já existir agregador com o mesmo nome, a ação não cria nem vincula: orienta a abrir a revisão detalhada ou ajustar o nome. A criação na listagem e no detalhe compartilha um advisory lock por nome. Mudanças concorrentes nas provas são verificadas antes de gravar. O botão fica desabilitado durante o envio. Após sucesso, o navegador volta à listagem preservando filtros, ordenação e página, com mensagem junto à lista.

Implementação em `includes/quick_accept.cfm`, chamada pelo backend existente. Testes em `_codex/tests/agrega_quick_accept_test.cfm`: 14 casos com tabelas temporárias locais à conexão e rollback, sem usar eventos reais. Conferidos também a renderização completa em transação somente leitura, o bloqueio de envio inválido, a compilação dos três templates, a listagem autenticada e a revisão detalhada no Chrome. Layout conferido em desktop e 390 px, sem rolagem horizontal.

Publicado somente `includes/quick_accept.cfm`, `includes/backend.cfm` e `home.cfm`. Backup: `/var/backups/business-agrega-aceitar-sugestao-20260927/baseline`. Recibos em `_codex/docs/agrega_edicoes_2026_09_27/quick_accept/`. Nenhum agregador ou vínculo real foi criado nos testes.

## Circuitos separados — 28/09/2026

Circuitos foram migrados para `tb_agregadores` / `tb_agregadores_eventos`. O campo de edição foi liberado, e agora as etapas podem entrar no gerador normalmente. Os cadastros legados de circuito não são oferecidos como grupos de edições. Revisões historicamente aplicadas a circuitos migrados são preservadas e não bloqueiam uma nova sugestão de edições; as demais proteções de histórico e pendências permanecem.

Execução, números, compatibilidade de cupons e recuperação em [Migração de circuitos](../_codex/docs/2026-09-28_circuitos_migracao.md).

## Atalho para agregador existente — 28/09/2026

A listagem oferece **Vincular ao agregador existente** nos pares `edicoes-v1:` pendentes com exatamente duas candidatas ativas, uma sem vínculo e outra em um único agregador de edições válido. Mostra nome/ID do destino e preserva a revisão detalhada. Grupos conflitantes, circuitos, candidatos inativos ou sugestões de outro destino não recebem o atalho. O botão de criar agregador continua disponível para pares sem vínculos.

O mesmo POST `aceitar_sugestao` recebe `agregador_esperado`. A operação administrativa mantém CSRF, bloqueia grupo/candidatas/eventos e revalida os IDs esperados e o destino. Reutilizar não cria nem renomeia agregadores: atualiza somente a prova ainda sem vínculo, conclui os dois candidatos e registra auditoria em uma transação. Repetir um envio concluído não reaplica. A listagem conserva busca, ordenação e página após o POST, sem confirmação JavaScript.

Validação: 27 cenários CFML/PostgreSQL passaram usando tabelas temporárias com nomes exclusivos e rollback; incluem criação anterior, reutilização, repetição, destino alterado, dois destinos, circuito, inatividade e falha de escrita. Compilação dos três arquivos bem-sucedida, publicação limitada ao escopo e hashes verificados. Chrome autenticado mostrou o atalho do grupo 5777 para **Corrida dos Bancários - Salvador · #1253**, mantendo o grupo pendente; nenhum vínculo real foi aplicado no teste. Desktop e mobile 390px verificados, sem overflow horizontal. Evidências em `_codex/docs/agrega_existing_2026_09_28/`; backup remoto `/var/backups/circuitos-20260928/quick-existing/Business/baseline`.
