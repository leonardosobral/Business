# Estudo de performance dos canais de venda — Maratona de Floripa 2026

## Contexto

A área `/inscricoes/` do Road Runners Business apresenta um acompanhamento
operacional da Maratona Internacional de Floripa 2026, usando o evento
TicketSports `72611`. A tela atual agrupa inscrições por título de cupom e
mostra volume, vendas, repasse e ticket, mas não foi desenhada para encerrar a
análise estratégica da edição nem para apoiar a seleção de canais de 2027.

O estudo deve responder, com evidências, que perfil cada canal trouxe para o
evento: alcance geográfico, modalidades, momento da compra, valor, composição
da cesta e características do público. A direção quer reduzir o número de
canais na próxima edição e precisa reconhecer quais canais trazem públicos
distintos. A decisão final permanecerá humana; o estudo não produzirá nota,
ranking geral ou recomendação automática de corte.

## Decisões aprovadas

- O resultado será um estudo fechado de 2026 em HTML autônomo, preparado para
  impressão e futura conversão em PDF.
- A área `/inscricoes/` permanecerá inalterada.
- O canal/parceiro consolidado será a unidade principal de análise; títulos e
  códigos de cupom permanecerão disponíveis no detalhamento.
- Todos os mecanismos comerciais serão analisados. Sports Week será tratado
  como canal estratégico. PCD e Benefício serão identificados como políticas
  ou mecanismos comerciais, sem serem confundidos automaticamente com
  parceiros selecionáveis.
- Não haverá pontuação, ranking estratégico ou classificação automática em
  manter, cortar ou expandir. O relatório apresentará dossiês comparáveis,
  singularidades, sobreposições, limitações e perguntas para decisão.
- Canais com pelo menos 10 inscrições pagas receberão dossiê completo. Canais
  abaixo desse limite receberão ficha compacta e comporão a cauda longa no
  apêndice de impressão. Todos permanecerão consultáveis no HTML.

## Objetivo e audiência

O relatório será dirigido à direção e às equipes comercial, marketing e
operação do evento. Ele deve permitir que essas pessoas:

1. entendam a performance comercial consolidada da edição 2026;
2. comparem canais usando a mesma definição e o mesmo período;
3. identifiquem alcance nacional, concentração regional e cidades relevantes;
4. vejam quais modalidades, lotes e perfis cada canal favoreceu;
5. entendam a contribuição de produtos adicionais à cesta;
6. reconheçam canais semelhantes e canais que adicionam cobertura distinta;
7. decidam manualmente quais relações merecem continuidade em 2027.

## Escopo

### Incluído

- Evento TicketSports `72611`.
- Pedidos, participantes/inscrições e produtos relacionados ao evento.
- Situação dos pedidos, datas, lote, cupom, modalidades e valores disponíveis.
- Perfil agregado por geografia, faixa etária, gênero, pace e
  assessoria/grupo, quando os campos tiverem cobertura suficiente.
- Descontos, taxas, repasse e cashback registrados ou determináveis por fonte
  confiável.
- Produtos incluídos no kit e produtos adicionais, separados por regra
  explícita.
- Visão geral do evento, dossiês completos e fichas da cauda longa.
- Metodologia, reconciliação, cobertura dos campos e limitações.

### Fora do escopo

- Alterar, substituir ou ampliar `/inscricoes/`.
- Criar uma nova rota autenticada ou um painel recorrente no Business.
- Publicar dados pessoais ou respostas individuais.
- Estimar financeiramente cortesias, permutas, espaço de Expo ou outras
  contrapartidas que não tenham fonte confiável.
- Decidir automaticamente quais canais devem ser cortados, mantidos ou
  expandidos.
- Tratar o dump antigo do repositório como fotografia final da edição.

## Fontes e congelamento da análise

A fonte de verdade será um extrato atualizado e somente leitura das tabelas:

- `public.tb_ticketsports_pedidos`;
- `public.tb_ticketsports_participantes`.

O acesso preferencial será uma conexão de banco já configurada e capaz de
executar consultas somente leitura. Se ela não estiver disponível, serão
solicitados novos exports das duas tabelas. O relatório não será fechado com o
dump antigo sem identificá-lo como incompleto.

O extrato final será congelado com data e hora. Os arquivos brutos conterão
dados pessoais e, por isso, ficarão fora do repositório, em área temporária de
trabalho. O repositório poderá guardar apenas:

- consultas e regras de transformação;
- mapeamento revisado de canais e códigos;
- tabelas agregadas e anônimas usadas pelo relatório;
- metadados de reconciliação, contagens e cobertura;
- o artefato HTML final e seu conteúdo canônico.

## Modelo analítico e granularidade

O estudo terá três fatos separados.

### Pedido

Uma linha por `(cod_evento, numero_pedido)`, originada de
`tb_ticketsports_pedidos`. Esta é a granularidade para:

- quantidade de pedidos;
- status e datas de pedido/pagamento;
- quantidade de inscrições por pedido;
- faturamento, desconto, taxa e repasse do pedido;
- forma de pagamento e dispositivo, se úteis e com cobertura adequada;
- ticket médio por pedido.

Somente pedidos com status final `Pago`, após normalização de espaços e caixa,
entrarão nos indicadores comerciais. Pedidos pendentes e cancelados aparecerão
apenas na reconciliação de cobertura e status.

### Participante/inscrição

Uma linha por `(cod_evento, numero_inscricao)`, originada de
`tb_ticketsports_participantes` e vinculada ao pedido pela chave composta
`(cod_evento, numero_pedido)`. Esta é a granularidade para:

- inscrições e modalidades;
- lote;
- cupom e canal;
- preço, desconto, taxa e repasse informados por inscrição;
- geografia do participante;
- faixa etária na data do evento, gênero, pace e assessoria/grupo;
- ticket por inscrição.

O estudo não chamará inscrições distintas de pessoas únicas sem uma regra de
deduplicação validada. Dados do responsável pelo pedido não substituirão a
geografia ou o perfil do participante sem que essa mudança de significado seja
explicitada.

### Produto

Uma linha por item do array `produtos` do participante. Os itens serão
classificados em:

- item obrigatório ou incluído no kit da modalidade;
- produto adicional;
- item não classificado.

A classificação usará identificadores e nomes revisados. Camisetas básicas da
modalidade não serão contadas como upsell. O estudo mostrará adesão e mix de
produtos adicionais. Receita de produto só será calculada quando houver valor
autoritativo; preços aparentes no nome do produto não serão tratados como fonte
financeira sem validação.

## Consolidação de canais

O processo de consolidação terá duas camadas:

1. **normalização determinística:** espaços, caixa, acentos apenas para chave
   técnica e valores vazios convertidos em Orgânico;
2. **mapeamento revisado:** títulos ou códigos diferentes só serão unidos quando
   houver evidência explícita de que pertencem ao mesmo parceiro ou mecanismo.

Não haverá fusão agressiva por semelhança textual. Cada canal guardará:

- nome consolidado;
- natureza: parceiro, influenciador, assessoria, campanha, orgânico, política,
  benefício, cortesia ou outro tipo revisado;
- títulos de cupom observados;
- códigos de cupom observados;
- quantidade de registros por código;
- justificativa de alias quando mais de um título for consolidado.

O exemplo já identificado de `CORRECRICIUMA` e `CORRECRICIUMA_100` demonstra
por que título e código precisam permanecer em níveis separados.

## Definições dos indicadores

### Visão geral

- pedidos pagos;
- inscrições pagas;
- inscrições por pedido;
- faturamento bruto;
- desconto;
- taxas;
- repasse líquido;
- ticket médio por pedido;
- ticket médio por inscrição;
- vendas orgânicas e vendas com cupom;
- composição por modalidade;
- composição e ticket por lote;
- vendas semanais;
- adesão a produtos adicionais.

Médias gerais serão ponderadas pela população correspondente. A média simples
dos tickets dos canais não será usada como ticket médio geral.

### Geografia

- participação por país, UF e cidade;
- número de UFs e cidades cobertas;
- participação da principal UF e das principais cidades;
- classificação descritiva de abrangência nacional, multirregional, regional
  ou local, baseada na distribuição observada e acompanhada dos percentuais;
- cobertura dos campos geográficos.

Rótulos de abrangência serão explicativos e não comporão uma nota estratégica.

### Modalidades e lotes

- distribuição entre 42K, 21K, 5K, Desafio e Maratoninha;
- diferença em pontos percentuais em relação ao perfil geral do evento;
- distribuição por lote;
- ticket por lote;
- concentração em vendas antecipadas ou tardias;
- evolução semanal quando houver pontos suficientes para mostrar uma tendência
  honesta.

### Perfil

- faixas etárias calculadas na data do evento;
- gênero conforme valores normalizados disponíveis;
- pace em faixas interpretáveis, após validação de formato;
- assessorias/grupos mais frequentes;
- cobertura e quantidade válida de cada campo.

Valores inválidos ou ausentes permanecerão como `Não informado`/`Inválido` e
não serão transformados em zero.

### Economia e cesta

- faturamento, desconto, taxas e repasse por canal;
- ticket por pedido e por inscrição;
- inscrições por pedido;
- quantidade e taxa de adesão a produtos adicionais;
- mix dos produtos adicionais mais escolhidos;
- cashback apenas quando registrado ou suportado por regra confiável;
- contrapartidas externas descritas como conhecidas, desconhecidas ou não
  mensuradas.

### Singularidade e sobreposição

O relatório não condensará a singularidade em uma nota. Cada dossiê mostrará,
por dimensão:

- diferenças de geografia contra o evento;
- diferenças de modalidades contra o evento;
- diferenças de momento/lote contra o evento;
- diferenças de perfil e cesta quando a cobertura permitir;
- canais que apresentam padrões materialmente semelhantes em dimensões
  específicas, sem formar ranking de proximidade;
- sinais exclusivos ou raros, acompanhados da base que os sustenta.

Comparações com amostras pequenas serão descritas como indícios, não como
características estáveis.

## Estrutura do relatório

### Abertura

1. título, escopo e data do congelamento;
2. resumo executivo factual;
3. definições essenciais de pedido, inscrição, produto e canal;
4. qualidade e cobertura da fonte.

### Performance geral

1. volume e economia da edição;
2. vendas ao longo do tempo;
3. lotes e ticket;
4. modalidades;
5. geografia;
6. canais e concentração;
7. produtos adicionais.

### Dossiês completos

Cada canal com pelo menos 10 inscrições pagas terá:

1. identificação e códigos;
2. escala e participação;
3. ticket e cesta;
4. geografia;
5. modalidades;
6. timing e lotes;
7. perfil;
8. economia;
9. singularidade e sobreposição;
10. síntese factual, limitações e perguntas para decisão.

### Cauda longa

Canais com menos de 10 inscrições terão ficha compacta com:

- volume;
- faturamento e ticket disponíveis;
- principal geografia;
- modalidades;
- lotes;
- códigos;
- ressalva de amostra;
- observações relevantes.

No HTML, todas as fichas permanecerão pesquisáveis. Na impressão, formarão um
apêndice compacto.

## Visualizações

O relatório usará gráficos apenas quando facilitarem uma comparação concreta:

- linha para evolução semanal com pontos suficientes;
- barras horizontais para canais, UFs, cidades e produtos;
- barras empilhadas para composição por modalidade e lote;
- cartões para poucos indicadores de abertura;
- tabelas para valores financeiros exatos, reconciliação e cauda longa;
- pequenos gráficos comparativos nos dossiês quando a amostra for suficiente.

Cada gráfico terá título descritivo, período, unidade, denominador e texto
adjacente explicando a leitura. Não haverá radar, decoração sem função ou cor
como único meio de distinção. O HTML terá navegação por seções, busca por canal,
layout responsivo e estilo de impressão preparado para PDF.

## Privacidade e segurança

O extrato bruto pode conter nome, documento, e-mail, telefone, endereço, data
de nascimento, contato de emergência e respostas de questionário. Esses campos
não aparecerão individualmente no relatório nem em tabelas agregadas que
permitam reidentificação.

Regras:

- não versionar o extrato bruto;
- não registrar amostras de dados pessoais em logs, fixtures ou mensagens;
- usar apenas faixas etárias e distribuições agregadas;
- suprimir cortes excessivamente pequenos quando a combinação de dimensões
  puder identificar alguém;
- fazer varredura final do HTML contra e-mails, documentos, telefones e chaves
  de identificação;
- manter fontes e metodologia sem incorporar credenciais ou caminhos sensíveis.

## Qualidade, erros e lacunas

O processo interromperá a conclusão do relatório quando faltar uma fonte
necessária para os totais finais. O dump antigo poderá servir para desenvolver e
testar o método, mas não substituirá silenciosamente o extrato atualizado.

Tratamentos explícitos:

- registros sem correspondência entre pedido e participante serão contabilizados
  e investigados, não descartados silenciosamente;
- duplicidades nas chaves compostas serão erro de integridade;
- falhas de parsing numérico ou de data serão registradas como cobertura
  inválida;
- campos opcionais sem cobertura suficiente serão omitidos do dossiê ou
  apresentados com limitação visível;
- custos externos desconhecidos serão rotulados como não mensurados;
- canais com menos de 10 inscrições terão ficha compacta e alerta de amostra;
- comparações mais finas usarão denominador visível e serão suprimidas quando
  criarem falsa precisão.

## Reconciliação e testes

Antes da entrega, o processo deverá confirmar:

1. uma linha por pedido pago na chave composta do evento;
2. uma linha por inscrição na chave composta do evento;
3. vínculo entre pedido e inscrição usando também `cod_evento`;
4. soma das inscrições por canal, modalidade e lote igual à população elegível,
   considerando explicitamente `Não informado`;
5. reconciliação de faturamento, desconto, taxa e repasse no nível correto;
6. ticket geral ponderado e tickets por lote/canal recalculados a partir das
   bases, não por média de médias;
7. mapeamento de títulos e códigos revisado e sem fusões ambíguas;
8. classificação de produtos validada por amostra de identificadores e nomes;
9. cobertura de geografia, idade, gênero, pace e assessoria informada;
10. ausência de dados pessoais no artefato final;
11. validação estrutural do artefato de relatório;
12. inspeção do HTML em largura de desktop, largura móvel e impressão.

Testes automatizados cobrirão parsing de números brasileiros, datas, pace,
modalidades, lotes, consolidação de canais, separação de kit e produto adicional,
granularidade dos joins e cálculos financeiros. Fixtures serão sintéticas ou
anonimizadas.

## Artefatos planejados

A implementação deverá produzir, em uma pasta isolada do estudo:

- consulta ou instrução reproduzível de extração;
- script de transformação e análise;
- arquivo revisável de consolidação de canais;
- testes automatizados;
- tabelas agregadas e anônimas;
- inventário de fontes, cobertura e reconciliação;
- conteúdo canônico do relatório;
- `report.html` autônomo, principal entregável.

O local exato será definido no plano de implementação, seguindo as convenções de
`_codex` para análises e relatórios internos. Nenhum arquivo de `/inscricoes/`
será alterado.

## Critérios de conclusão

O trabalho estará concluído quando:

- o extrato final estiver identificado por data/hora e reconciliado;
- os três níveis analíticos estiverem separados e validados;
- todos os canais estiverem consolidados e presentes;
- canais com 10 ou mais inscrições tiverem dossiê completo;
- a cauda longa tiver fichas compactas;
- a visão geral e os dossiês cobrirem as dimensões aprovadas;
- limitações de custo, cobertura e amostra estiverem visíveis;
- o HTML estiver validado, sem dados pessoais e pronto para impressão;
- `/inscricoes/` permanecer sem alterações.

