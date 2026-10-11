# Funil — inscrições com cupom RoadRunners

O Business lê `public.tb_ticketsports_participantes` e `public.tb_ticketsports_pedidos` e cruza os participantes com `public.tb_usuarios`. Não cria vínculos persistidos, não altera as inscrições ou o cadastro, não envia campanhas e não depende de migração.

## Regra da etapa

- Código normalizado exatamente `ROADRUNNERS`. Sem código, admite os títulos normalizados `ROADRUNNERS` e `ROADRUNNERS INFLU X 10 CASHBACK`. O segundo alias possui revisão explícita no registro ROADRUNNERS de `_codex/analyses/mif_2026_channels/channel_mapping.csv`. Um código diferente não é substituído por um título semelhante. Não entram os outros cupons da TicketSports.
- Pedido com estado importado `Pago`, ligado pela chave `(cod_evento,numero_pedido)`; participante identificado por `(cod_evento,numero_inscricao)`.
- `data_pedido` do participante anterior ao final exclusivo do dia escolhido, em Brasília. Datas ausentes não são inventadas.
- Usa o e-mail do **participante** (payload ou coluna), normalizado apenas por caixa e espaços nas extremidades. Exige e-mail válido e uma única conta correspondente em toda a tabela de usuários, mesmo que a conta duplicada esteja fora da coorte selecionada. E-mails divergentes entre payload e coluna, ausentes, inválidos e ambíguos não vinculam pessoas. Não usa nome, documento ou e-mail do comprador para inferir identidade; não remove pontos nem sufixos de e-mail.
- A etapa conta pessoas únicas, independentemente da compra do Desafio. Seu percentual usa a base como denominador; não apresenta conversão a partir dos renovados. A consulta preserva as regras das etapas dos desafios.
- Inscrições são acumuladas até a data final. A leitura “Cadastros no período” restringe a base de usuários pela data de criação; não restringe a data inicial das inscrições. Um cadastro posterior à inscrição pode ser associado se existir até a data final, sem presumir que já estava cadastrado no dia da compra.

## Interface e contrato

`etapa=coupon` filtra os usuários associados. O JSON adiciona `metrics.coupon`, `metrics.coupon_registrations`, `coverage.coupons_mapped`, `coverage.coupon_stats` e os campos `coupon*` das pessoas (contagens, última prova/modalidade/data). Não retorna e-mails ou documentos usados no cruzamento. Quando a fonte ou o público não estiverem mapeados, a etapa apresenta travessão e não classifica pessoas.

No Funil a etapa abre “Usuários e clientes”. A tabela informa a quantidade de inscrições e provas por usuário e a última inscrição. A aba “Retenção e origem” discrimina inscrições ligadas, sem conta, fora do recorte, com contas duplicadas, com e-mails divergentes e sem e-mail válido. As categorias de cobertura são exclusivas e somam o total de inscrições elegíveis.

## Limites

A cobertura depende das provas e inscrições já importadas na TicketSports. O estado importado `Pago` não é receita auditada, liquidação nem comprovação de cashback. Inscrição não comprova participação efetiva na corrida. O cruzamento por e-mail é uma correspondência cadastral, não identidade autenticada. Inscrições sem correspondência ficam fora da etapa; ausência do vínculo não demonstra ausência de uso do cupom.

## Validação

- SQL exato de `ticketsports_coupons.cfm` executado com dados sintéticos em PostgreSQL via PGlite 0.5.8 isolado em `/private/tmp`, sem dependência adicionada ao runtime.
- Teste `_codex/scripts/test_funnel_coupons.mjs`: pessoas únicas, inscrições repetidas, aliases exatos, cupom de terceiro, cancelamento, pedido com mesmo número em provas distintas, datas, coorte, duplicidade fora da coorte, conflitos e ausência de e-mail, preservação de sufixos de e-mail e reconciliação das categorias.
- Execução: `FUNNEL_SQL_PGLITE_MODULE=/private/tmp/funnel-coupon-sql/node_modules/@electric-sql/pglite/dist/index.js node _codex/scripts/test_funnel_coupons.mjs`.
- Sintaxe JavaScript, compilação Python do helper e `git diff --check` passaram. Teste de retomada de publicação/rollback passou.
- Validação de volume com mais 50 mil usuários e 10 mil inscrições sintéticas: passou. O cruzamento usa `UNION ALL` de chaves de usuários/participantes e funções de janela por e-mail, sem a junção repetida de uma base agregada. O agregado por pessoa é materializado e a última inscrição é obtida no mesmo agrupamento das contagens.
- A primeira e a segunda tentativa foram restauradas após falha real. O diagnóstico por categorias e SQLSTATE confirmou limite de tempo (`57014`), sem erro de parâmetro, coluna, sintaxe ou permissão. A forma anterior também apresentou lentidão no teste sintético de volume; o teste foi encerrado e o cruzamento reescrito. O log permanente registra apenas categorias e SQLSTATE, sem SQL, argumentos ou dados pessoais. O limite de consulta é 40 segundos e o da requisição permanece 90 segundos.
- Publicação escopo `funnel-coupons`: seis arquivos Business, quatro CFML compilados nativamente, baseline por hash e backup privado. Registros em `.superpowers/sdd/2026-09-24-crm-interno/release-funnel-coupons*.json`.

## Resultado verificado em produção

Em 11/10/2026, às 05:38 de Brasília, público atletas, produto Desafio, base acumulada até 11/10/2026:

| Indicador | Total |
| --- | ---: |
| Base cadastrada | 56.735 |
| Pessoas com inscrição usando ROADRUNNERS | 510 |
| Inscrições ligadas a essas pessoas | 522 |
| Inscrições elegíveis importadas (pedido Pago e data utilizável) | 2.766 |
| Inscrições sem usuário correspondente | 2.244 |
| Fora do recorte / ambíguas / divergentes / sem e-mail válido | 0 / 0 / 0 / 0 |

As categorias de cobertura reconciliam 2.766 = 522 + 2.244. As etapas dos desafios preservaram 3.003 vínculos, 2.513 pagantes 365/TSD, 715 pagantes TSD e 273 compradores dos dois. A base cresceu durante a verificação; as variações de cadastros são leituras reais em momentos distintos.

Clique na etapa abriu “Usuários e clientes”, com 25 linhas, sete colunas, todas as linhas exibindo inscrição com ROADRUNNERS e paginação “510 pessoas · Página 1 de 21”. O produto Perfil.Run apresentou as etapas financeiras indisponíveis e preservou os 510 usuários do cupom, confirmando a independência da etapa. Verificada navegação por teclado entre abas.

Desktop 1541px e mobile 390x844px sem overflow horizontal da página; em mobile, a tabela possui rolagem interna. Viewport restaurado. Evidência visual: `output/funil-business/2026-10-11-cupom.jpg`.

Publicação final: `/var/backups/crm-interno.cada4bbd6ab1e5db`, seis hashes e guards conferidos pelo modo `verify`, fase `published`, quatro CFML compilados nativamente. As tentativas anteriores foram restauradas antes das novas publicações. Não houve alteração de banco, RoadRunners, credenciais, permissões ou envio de mensagens/campanhas.
