# Regiões, gêneros, UFs e cidades — 30/09/2026

Publicado às 23h47 BRT: [2025, recálculo](https://roadrunners.run/brasilquecorreprovas/web/?ano=2025&fonte=atual#geografia) web v7 / congelamento 80; [2026](https://roadrunners.run/brasilquecorreprovas/web/?ano=2026#geografia-4) web v6 / congelamento 81. O único local de autoria permanece [Business Estudo, caderno 6](https://business.roadrunners.run/estudo/?caderno=6). Esta pasta guarda recibos e evidências; não é uma fonte alternativa para sobrescrever queries do notebook.

## Entrega

- P09: regiões de 2024/2025, composição de cada região por gênero e distribuição de cada gênero pelo país. Norte vem das contagens reais congeladas; categorias não informadas permanecem visíveis. A referência PDF continua com os quatro rótulos legíveis de distribuição F/M; não recebeu valores inventados.
- P10: todas as UFs e as nove destacadas no PDF mais Outros usam a fonte DataGrip congelada. Cidades passam a validar uma chave normalizada de nome/UF e a concordância do código positivo. Não há cruzamento apenas pelo nome, aliases inventados, alteração de cadastro ou multiplicação de resultados.
- 2026: novo bloco de distribuição de gênero por região a partir das contagens já congeladas; ranking de cidades com UF e uma única Brasília/DF. As cidades têm nova coleta própria; totais, calendário, crescimento, coortes e demais indicadores de provas continuam no congelamento anterior.
- Chart.js com barras regionais horizontais mantém nomes legíveis no celular. Tabelas apresentam contagem, base e fonte; categorias novas de recálculo entram nas exportações atuais sem aparecer no CSV histórico.

## Fontes e revisões

| Uso | Célula / revisão | Congelamento |
| --- | --- | --- |
| Regiões e gêneros; UFs | 287 / 1 | 75, derivado de 21, 22/DataGrip e 74 |
| Cidades validadas | 288 / 2 | 77 |
| Conciliação P09/P10 com o PDF | 291 / 1 | 82, 87 linhas |
| Saída 2025 | 249 / 13 | 80, contrato 3 |
| Saída 2026 | 251 / 10 | 81, contrato 2 |

Notas 289/290 registram regras e pendências nas seções P09/P10. Relidos os notebooks antes das alterações; conferidas **129 células existentes intactas**, excluindo apenas as duas saídas web atualizadas com revisão esperada. As consultas do DBA 195, 199 e 201, inclusive seus conteúdos, permaneceram intactas. Execução 76 de cidades ficou truncada e não foi congelada; a revisão 2 retorna um resultado completo de 36 linhas.

## Populações e pendências

Regiões/UFs 2025 usam 5.279.415 participações da fonte congelada de `vw_resultados`: BR, status 0, homologado, ano pela data final, sem filtros adicionais de modalidade, conclusão ou idade. Região de 2024 conserva 246 participações sem classificação regional. F/M dentro de cada região inclui o saldo dos outros gêneros no denominador; distribuição de F/M entre regiões usa o total nacional daquele gênero.

A comparação regional de 2024 é uma pendência real: PDF p.9 mostra Nordeste 19,3% / Sul 18,1%, enquanto a consulta congelada mostra Nordeste 18,1% / Sul 19,3% quando arredondada. As duas referências foram preservadas. O aparente intercâmbio de rótulos precisa de revisão com o DBA; a falta da base histórica impede atribuir automaticamente o erro ao PDF ou à consulta.

| Ranking de cidades | Base nacional própria | Participações validadas | Pendências mantidas na base |
| --- | --- | --- | --- |
| 2025 anual | 5.279.220 | 5.247.745 | 31.081 em 26 eventos com código divergente; 394 em 3 eventos sem correspondência |
| 2026 até 26/09 | 4.274.231 | 4.266.163 | 8.068 em 19 eventos sem correspondência |

Cidade 2025 usa status 0/homologado, todas as modalidades e idades, sem conclusão adicional; 2026 acrescenta concluinte. Ambas têm coleta própria de 30/09. O denominador de cidades 2025 difere da fonte 23 (5.279.415), portanto as diferenças também envolvem base viva/coleta posterior. Brasília/DF validada: 228.132 em 2025 e 190.151 em 2026. A lista 2025 mantém as 14 cidades do PDF; a de 2026 é um ranking novo das 14 maiores validadas. Os subconjuntos não somam 100% nem são ajustados para isso.

2026 por gênero/região deriva da saída 74: F=2.268.950, M=1.943.942. Região não informada é o saldo nacional após as cinco regiões (F=8.061, M=6.598). O panorama mantém 4.214.040 participações e seu corte/coleta anteriores. Capital/interior continua em sua população própria de rua, fonte 52.

Conciliação atual 2025: 396 valores de notebook em conciliação, 45 compatíveis por arredondamento, 25 divergentes da fonte inicial, 108 não recalculados; total 574 comparações, incluindo oito categorias exclusivas do recálculo. Esses estados não certificam equivalência histórica. 2026: 465 calculados e 74 pendentes, 539 categorias.

## Contratos e publicação

Migração aditiva `contract-geography.sql`: novas bases de contrato 2025/3 e 2026/2. O contrato 2025 mantém todas as definições e valores históricos, acrescentando apenas categorias de comparação atuais; o de 2026 registra os novos rótulos canônicos do ranking de cidades. A função passa a selecionar versões explicitamente cadastradas em `web_base_versoes`. Comparações por categorias e definições continuam exatas, campos desconhecidos são rejeitados, e contratos antigos ainda passam no preview. Nenhuma permissão foi ampliada.

Backup antes da migração: `/var/backups/business-estudo-web-20260928/database/regioes-cidades-v3-v2-20260930-before.json`. A primeira aplicação foi recusada por aspas e a segunda pelo terminador do DDL; nenhuma passou da análise sintática. Migração corrigida aplicada com digest da definição anterior e transação. O SQL nesta pasta é o recibo corrigido aplicado.

Runtime: quatro arquivos RoadRunners (`dados.js`, `graficos.js`, `estudo.js`, `parcial.js`), gerados de `previa/` pelo script existente. Backup remoto `/var/backups/roadrunners-estudo-regioes-cidades-20260930/runtime/RoadRunners`; recibos `release-*.json`. O frontend Business não foi modificado nesta etapa. A rota segue sem divulgação na página original, `noindex, nofollow` e `private, no-store`.

## Validação e recuperação

55 testes passaram, incluindo preservação de todo CSV histórico, percentuais com denominadores independentes, outros gêneros, região não informada, UFs + Outros, integridade antes/depois do cruzamento de cidades e preservação de todos os comparativos não geográficos. Preview oficial de 80/81 e dos anteriores 72/74 passou. JSON de produção idêntico aos candidatos, removido apenas o carimbo de publicação. Cabeçalhos de privacidade e hashes dos quatro arquivos conferidos. Chrome: desktop e 390 px, alternância PDF/recálculo, seletor Nordeste, cidades e novos blocos, sem erros de console; gráfico novo sem transbordamento horizontal. O evento de download de CSV do navegador não retornou confirmação nesta sessão; valores/categorias do CSV foram conferidos pelos testes do adaptador.

Para reverter dados, selecionar e publicar os congelamentos anteriores 72/74 no Business com a publicação esperada atual (IDs 12/13 nesta entrega). Para reverter código, restaurar apenas os quatro arquivos a partir do backup desta entrega, após conferir o runtime atual. Os novos contratos e congelamentos são aditivos e podem continuar guardados; nenhuma recuperação exige apagar o histórico.

O aceite integral do plano continua aberto: idade/gerações, estações, regras de medalhas, métricas de perfil, cobertura e contagens históricas exatas dependem de fontes ou decisões metodológicas. Geografia publicada não encerra essas pendências.
