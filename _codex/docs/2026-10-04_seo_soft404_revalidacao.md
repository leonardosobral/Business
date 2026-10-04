# Revalidação dos exemplos soft 404 — 04/10/2026

Consulta autenticada ao Search Console: relatório de 20/09 ainda apresenta 167 exemplos, com 121 eventos, nove buscas, 36 páginas de atletas e um endpoint interno. Lista completa observada na interface (1–167); os dados pessoais não foram exportados para o artefato. Dos eventos, 96 URLs não têm query e 25 contêm parâmetros de ação. A coleta HTTP limitou-se aos 96 endereços sem query, com duas requisições simultâneas e timeout de 30 segundos. Não foram executadas ações de login/registro, buscas IA, páginas de atletas ou endpoint interno.

## Evidência atual

- 51 URLs respondem 200, com H1, canonical e SportsEvent legíveis; isso não prova indexação nem elimina todas as causas de soft 404.
- 45 URLs respondem 404. Consulta somente leitura não encontrou tags exatas nem aliases para esses endereços. Nenhum redirect foi criado por semelhança de nomes.
- Nenhum 5xx, erro CFML visível ou erro de leitura JSON-LD entre os 96.
- Nove URLs 200 sem barra final apontam canonical para a variante com barra. Esse padrão foi preservado.
- A resposta 404 usa o handler publicado anteriormente; a coleta pode acrescentar logs operacionais de página ausente, sem alterar cadastros ou resultados.

## Diferença entre o relatório agregado e a inspeção individual

A inspeção autenticada de https://roadrunners.run/en/event/2022-2-dc-run/ informa **O URL está no Google / A página está indexada**. Último rastreamento exibido: 24/09/2026 às 11:12:49, Googlebot Smartphone, busca com êxito, rastreamento/indexação permitidos, canonical selecionado igual à URL inspecionada. Há um item de evento válido com problemas não críticos.

O relatório soft 404 é de 20/09 e lista esse endereço; a inspeção individual posterior contradiz a leitura de que esse exemplo ainda esteja fora do índice. Essa evidência vale apenas para a URL inspecionada. Não foi solicitado teste ao vivo, nova indexação ou validação global. O teste ao vivo inicialmente previsto tornou-se desnecessário para verificar que esta página já está indexada.

## Pendências

RR-16 permanece aberto: conferir os casos ainda não avaliados e obter evidência individual quando necessário. Não usar a contagem histórica de 167 como quantidade de falhas atuais confirmadas, nem anunciar recuperação dos 51 somente pelo HTTP 200. Não descartar URLs históricas úteis. Para endereços sem cadastro, manter 404 até que haja comprovação de destino equivalente; tag_301 está vazio em toda a base consultada.

Artefatos em `_codex/staging/seo-soft404-census-20261004/`: lista de URLs públicas, coletor, metadados/hashes (sem salvar corpos com resultados pessoais), consulta de tags e recibo da inspeção Google. Não houve alteração de runtime RoadRunners/OpenResults ou dados de eventos. A publicação Business registra a evidência em RR-16 e conserva 24 itens, 18 concluídos e seis pendentes; notas técnicas históricas não foram recalculadas.

Referência oficial: [Google — relatório de indexação](https://support.google.com/webmasters/answer/7440203). A documentação orienta usar inspeção de URL para situação individual e distingue URLs legitimamente não indexadas de erros.
