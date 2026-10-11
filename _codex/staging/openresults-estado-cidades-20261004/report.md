# OpenResults — filtro de cidade nas páginas de estado

Publicado em 04/10/2026 e conferido em produção em `https://openresults.run/estado/ba/`.

## Comportamento entregue

- Seletores de estado e cidade juntos no computador e no celular.
- Busca por cidade ignora acentos e caixa; opção Todas as cidades remove a seleção.
- Cidade pertence à UF atual. Trocar estado limpa a cidade anterior e preserva os outros parâmetros suportados.
- Abas Últimos, Maiores e Maratonas preservam a cidade e recalculam as contagens.
- Maiores seleciona até 20 eventos dentro da cidade escolhida. Sua contagem também fica limitada a 20.
- Cidades conhecidas continuam no seletor mesmo quando a aba/filtros atuais têm zero eventos. Opções com zero são desabilitadas, exceto a selecionada.
- Paginação usa o endpoint estadual com a cidade, os filtros e o divisor de mês. Estados inválidos retornam 404.

## Escopo e compatibilidade

A rota é `/estado/<uf>/?cidade=<slug>`. O canonical existente continua estadual. As estatísticas de UF continuam estaduais. Não foram criadas páginas municipais independentes, URLs de sitemap ou novas regras de indexação.

O construtor de navegação preserva `filtro`, `ano`, `distancia`, `tempo`, `rua`, `trail`, `nacional`, `internacional`, `cupom` e `badges`. OpenResults não possui os controles visíveis de período/distância nessa tela; a semântica legada desses parâmetros foi mantida. A lista histórica continua disponível.

A alteração no backend compartilhado se limita a deixar o filtro de cidade da rota estadual para o novo include; as demais rotas mantêm o filtro anterior. Foi removido da página estadual o inicializador de sliders ausentes, responsável por erro JavaScript na versão anterior.

Não houve SQL de escrita, alterações de eventos/resultados, autenticação, Cloudflare, privacidade/noindex, ações de salvar ou mudanças no RoadRunners.

## Evidência de validação

- 7 testes Node aprovados, incluindo navegação, filtros, abas, busca, parâmetros inválidos e URL da paginação. Testes de navegação tiveram reprodução RED antes da implementação.
- 4 templates compilados pelo Adobe ColdFusion.
- 33 verificações CFML aprovadas: facetas, modalidades, top 20 por seleção, filtros, cidade/UF, URLs e cidades vazias. Guardas adicionais confirmaram 403 para include sem queries válidas e 404 para UF inválida.
- A fixture CFML substitui somente a consulta de nomes de cidades por dados sintéticos. A consulta SQL real foi conferida separadamente com o render completo do candidato, usando os dados do OpenResults: 174 cidades na Bahia e 7 maratonas em Salvador.
- 8 URLs públicas conferidas: estado BA, Feira de Santana, Salvador/Maratonas, segundo lote de Feira, UF inválida, JS, CSS e home. Todas tiveram o status esperado. Feira mostrou 50 cards no primeiro lote e 23 no segundo; Salvador/Maratonas mostrou 7.
- No navegador publicado, Feira carregou 73 links únicos após rolar a lista. A busca `conceicao` encontrou Conceição da Feira e Conceição do Jacuipe. Escape fechou o seletor e devolveu foco ao resumo; Todas as cidades retirou o parâmetro de cidade. Trocar BA por SC manteve a aba Maratonas.
- Seletores lado a lado em 1280 px e 390 px. Em 390 px, `scrollWidth` também foi 390, sem transbordamento horizontal. Console da aba nova sem erros/avisos nas navegações e paginação verificadas. Tamanho temporário do navegador restaurado.

Uma primeira checagem HTTP do segundo lote usou `page=2` e encontrou zero cards. Foi corrigido apenas o verificador para `page=1`, pois o contrato existente começa em `page=0`. A interface publicada já carregava os 73 eventos corretamente.

## Revisão e decisões

Revisão independente encontrou um problema relevante: cidade com nome formado só por espaços podia resolver a seleção vazia como uma cidade. Corrigido com resolução apenas para seleção não vazia e exclusão de nomes vazios; a fixture reproduziu a falha antes da correção. Também foram corrigidos `aria-selected` das abas e o guarda explícito de queries no escopo VARIABLES.

A última consulta de nomes, independente de badges e com as mesmas condições de resultados públicos do OpenResults, recebeu compilação, fixture e render com dados reais após a revisão. Não se atribui ao revisor uma revisão desse último ajuste SQL.

Uma tentativa de publicação foi rejeitada pela revisão automática por um erro JavaScript registrado na aba antiga. A investigação vinculou o registro ao inicializador de sliders da versão anterior. Uma aba nova do site publicado confirmou ausência desse trecho e console limpo; a repetição da publicação com essa evidência foi aprovada.

## Publicação e recuperação

Seis arquivos de runtime publicados por substituição atômica por arquivo, preservando proprietário e permissões:

1. `includes/backend_estado_cidades.cfm` (novo)
2. `assets/js/openresults-estado-cidades.js` (novo)
3. `assets/css/openresults-estado-cidades.css` (novo)
4. `includes/backend.cfm`
5. `api/eventos_por_estado.cfm`
6. `estado/index.cfm`

Hashes dos seis arquivos locais/publicados confirmados; oito dependências monitoradas permaneceram idênticas. Mudanças preexistentes no workspace foram preservadas. Não houve commit, branch, tag, push ou PR. Documentação e testes não foram enviados ao runtime.

Recuperação dos três arquivos existentes: Git `e769528c34b23beb6fc3a16ea615184849ce5e5c`, que coincidiu exatamente com o baseline de produção desses arquivos. Reconstituir somente esses arquivos com `git show`, comparar o hash atual antes de republicar e remover os três novos arquivos após restaurar os consumidores. Não criar backups avulsos. Pastas temporárias de fixture, render, compilação e transporte foram removidas.

Manifesto, recibos, fixtures, render e evidência HTTP: `Business/_codex/staging/openresults-estado-cidades-20261004/`. Teste durável: `OpenResults/_codex/tests/estado-city-navigation.test.cjs`.
