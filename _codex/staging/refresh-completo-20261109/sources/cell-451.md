# Brasil Gigante — encarte de maratonas 2026

## Pergunta e conclusão

Como se comportam as oito etapas do circuito, quantas conclusões de 42 km registramos e o que conseguimos observar sobre adesão? A comparação é descritiva: não estima o efeito causal do circuito. 2025 é uma referência anterior ao anúncio em 07/04/2026, à abertura do site em 08/04 e à cerimônia em 11/04; não é uma edição anterior do Brasil Gigante.

## Recorte e fontes

- Janeiro a setembro nos dois anos; `data_final < 01/10`. Aracaju ocorre no quarto trimestre nos dois anos, permanece na lista mas fora dos consolidados.
- Oito agregadores: São Paulo 17, Paraná 1000, Porto Alegre 26, Campo Grande 9, João Pessoa **14**, Floripa 28, Salvador 15 e Aracaju 77. Treinos de Floripa não entram. A maratona de João Pessoa do agregador **12**, em abril, não pertence a este recorte.
- Fontes congeladas: inventários 242/243, seleções 244/245, pares 246 e detalhe de provas 252/253. Tempo positivo, distância 42–42,2 km, status 0, homologado e concluinte, PCD=false, excluindo categorias especiais/revezamento, conforme SQLs originais.
- Floripa 2026 usa integralmente a captura oficial 210: 3.592 classificados Geral/Elite. Não somar nem misturar os 3.594 do BI; 2025 conserva os 5.137 do congelamento 252. Inventário 2025 tem 5.152 registros 42 km incluindo modalidades excluídas. A diferença entre anos não prova problema de captura nem redução causal de demanda.
- João Pessoa Internacional 2026 (#32450) está no inventário 243 (335), mas não na seleção geral 245. O encarte recupera esse agregado com os mesmos filtros; não altera o total das 39 provas do estudo geral. A notícia oficial relata 332, diferença de três ainda não conciliada. O número de 335 e as comparações devem ter essa ressalva visível.
- Paraná estreia em 2026: 2.245 concluintes, sem percentual contra zero. Os 42 km foram em **03/05**, enquanto cadastro e congelamento registram 28/04. A data editorial é corrigida com fonte oficial, preservando o cadastro; ambas no segundo trimestre.
- Fonte de perfil/tempo: 252/253 e 210. João Pessoa 2026: sexo, sub3, sub4 e mediana já presentes em 243. Medianas por prova; não tirar média de medianas para representar todo o circuito.

## Cálculo

Seis pares elegíveis: somar as conclusões de 2025 e de 2026 antes de calcular `(soma2026/soma2025 - 1)*100`. São 17.545 → 17.164, -381 (-2,17%). O subtotal de sete etapas realizadas de 2026, incluindo a estreia Paraná, é 19.409. Não dividir esse subtotal por 17.545 para afirmar crescimento nas mesmas provas.

Outros pares do congelamento 246, excluídos os agregadores das oito etapas: 12 pares, 23.220 → 28.972 (+24,77%). A sensibilidade sem a NB Porto Alegre deixa 11 pares e +10,75%. Não se trata de grupo de controle equivalente, e diferenças de coleta continuam possíveis. A sensibilidade das etapas do circuito sem Floripa mostra +9,38%; ela serve para expor concentração da variação, não para esconder um resultado negativo. Os seis pares completos continuam sendo o principal.

## Adesão operacional

Célula SQL própria consulta `public.desafios`, `desafio='circuitobrasilgigante'`, inscrição anterior a 01/10/2026, contas distintas. Os 5.756 cadastros têm status I; status de cadastro não significa conclusão de prova.

Resultados associados usam `estudo.vw_resultados_2026`, as sete etapas até setembro e os mesmos filtros convencionais, com `id_usuario` atual. Contam-se contas distintas e eventos distintos por conta: 1.519 contas têm ao menos uma etapa associada, 164 têm duas ou mais. Associações podem ter sido feitas depois do corte e retroativamente; ausência de associação não comprova ausência de participação. Não chamar esse percentual de conversão ou resultado causado pelo circuito.

A auditoria adicional usa a data oficial de Paraná (03/05) e verifica inscrição até o dia da prova (data de inscrição convertida para date): 810 contas em ao menos uma etapa e 89 em duas ou mais. É limite operacional; não atesta inscrição antes da largada no mesmo dia. Os IDs pessoais não são exportados. Floripa nesta métrica operacional continua com a população BI 3.594; o volume editorial usa 3.592 oficiais, com denominadores separados.

## Fontes externas

- Lançamento e calendário: https://circuitobrasilgigante.com.br/noticias/circuito-de-oito-maratonas-brasil-gigante-e-lancado-para-democratizar-as-provas-de-42-km-no-pais-2/?lang=pt-br
- Funcionamento e retroatividade: https://circuitobrasilgigante.com.br/sobre/
- João Pessoa: https://circuitobrasilgigante.com.br/noticias/joao-pessoa-marca-a-quinta-etapa-do-brasil-gigante-que-reune-corredores-em-jornada-pelas-oito-maratonas/
- Paraná, regulamento: https://www.maratonainternacionalpr.com.br/_files/ugd/4113c7_bb907a07911d44439d2933c673860efe.pdf

## Pendências

Conciliar os três concluintes de João Pessoa; preservar a diferença de fonte em Floripa; corrigir a data de Paraná no cadastro em tarefa operacional separada; incluir Aracaju apenas no fechamento anual. Não há evidência suficiente para afirmar aumento de participação provocado pelo circuito. A parcela dos 42 km no total de cada evento exige uma consulta adicional própria e não é inferida desses congelamentos.

As consultas anteriores e as publicações gerais devem permanecer intactas. Esta seção é aditiva e só seus novos resultados alimentam o encarte.

## Publicação e auditoria desta seção

Seção 67 do caderno 6. Metodologia: célula 451. Adesão: célula 452 versão 2, congelamento **265**, já com a data oficial de Paraná em 03/05 e resultado temporal de **810/89** contas. A execução 264 preserva a tentativa anterior com a data cadastral e **não alimenta a publicação**. Derivação editorial: célula 453 versão 2, congelamento **266**, com oito etapas e proveniência das nove fontes. O JSON do encarte recebe apenas os identificadores da própria publicação após o congelamento; seus indicadores vêm integralmente do SQL 266.

Validação: SQL congelado comparado a cálculo independente em Python; oito IDs/agregadores únicos, seis pares, sete etapas realizadas, totais por sexo e cortes de tempo, benchmark sem as etapas do circuito, distribuição de adesão reconciliada. Nenhum resultado individual, nome, email ou documento é exportado. Medianas não são somadas e a edição de 2025 do estudo permanece sem o encarte.
