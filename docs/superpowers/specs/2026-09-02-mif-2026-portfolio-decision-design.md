# Decisão de portfólio de canais — Maratona de Floripa 2026

Data: 2026-09-02

## 1. Decisão que o módulo deve apoiar

O módulo deve ajudar a direção a reduzir o número de canais em 2027 sem eliminar parceiros que entreguem escala ou cobertura comercial difícil de substituir.

Ele responderá três perguntas:

1. quais canais combinam escala e diferenciação em geografia, distância, lote, momento de venda ou produtos;
2. quais pares têm sobreposição suficiente para merecer revisão comercial conjunta;
3. quais segmentos observados ficariam mais concentrados se um conjunto de canais deixasse de ser ativado.

Os resultados descrevem o histórico de 2026. O módulo não afirmará que inscrições seriam perdidas, não estimará causalidade do cupom e não decidirá automaticamente quais contratos encerrar.

## 2. Escopo aprovado

Incluído:

- mapa de escala e diferenciação por dimensão;
- matriz e lista de redundância entre canais;
- simulador de cobertura em risco;
- leitura executiva quase estática, autenticada e própria para PDF;
- navegação integrada ao relatório atual;
- processamento derivado da base congelada de 2026, sem nova extração.

Fora deste ciclo:

- ROI, margem ou retorno contratual sem custos, cachês, permutas e comissões;
- previsão de vendas perdidas;
- retenção entre eventos;
- atribuição digital por UTM ou sessão;
- mudança da tela `/inscricoes/`;
- incorporação do módulo inteiro à análise geral ou aos 144 dossiês.

## 3. Abordagem escolhida

O módulo ficará separado da análise geral e dos dossiês. Isso preserva a velocidade das páginas existentes e permite recalcular apenas os novos agregados.

Rotas:

- `/relatorios/maratona-floripa-2026/portfolio/` — relatório estático de decisão;
- `/relatorios/maratona-floripa-2026/portfolio/simulador.cfm` — simulador controlado;
- as páginas atuais receberão somente um botão de navegação para `Portfólio 2027`.

Artefatos privados:

- `portfolio/summary.json` — definições, benchmarks, quadrantes, Top 10 por dimensão, pares de redundância e narrativa executiva;
- `portfolio/simulator.json` — cubo compacto por canal × fase × distância × estado, sem cidade, semana, perfil pessoal ou produto individual.

O relatório estático carregará apenas `summary.json`. O simulador carregará apenas `simulator.json`. Nenhum dos dois carregará os dossiês completos ou o cubo geral do explorador.

## 4. Universo analisado

As visões de decisão usarão o mesmo universo comercial aprovado no relatório atual:

- ticket médio por inscrição acima de R$ 10,00;
- canais em caixa alta na apresentação;
- aliases de cupom já consolidados no canal canônico;
- orgânico presente como referência e denominador, mas indisponível para seleção como parceiro a remover;
- Sports Week, PCD e Benefício seguem a regra comercial comum e não são excluídos por tipo;
- canais com menos de 10 inscrições podem aparecer no simulador, mas não sustentam conclusões fortes de diferenciação ou redundância;
- canais com 10 a 29 inscrições recebem qualificação de amostra reduzida.

O denominador do evento continua incluindo todas as inscrições pagas reconciliadas. O corte de R$ 10,00 altera somente as visões comerciais, nunca os totais do evento nem os dossiês auditáveis por URL direta.

## 5. Mapa de escala e diferenciação

### 5.1 Escala

A escala será mostrada por medidas observadas, sem score mestre:

- inscrições pagas;
- valor bruto alocado;
- participação nas inscrições do evento;
- ticket por inscrição.

Para os quadrantes, `escala alta` significa estar no quartil superior de valor bruto entre os canais comerciais não orgânicos. O valor do corte e a população usada serão exibidos.

### 5.2 Diferenciação

A diferenciação será calculada separadamente nas cinco dimensões acionáveis:

- geografia;
- distância/modalidade;
- fase temporal;
- lote;
- produtos adicionais, excluindo `kit_incluso`.

Idade e gênero permanecem como evidência auxiliar, não como eixos de decisão comercial.

Para cada canal e dimensão, será usada a similaridade Jensen-Shannon já adotada pelos dossiês. O indicador exibido será a similaridade com o par válido mais próximo. Um canal será classificado como `mais diferenciado relativamente` quando a similaridade de seu vizinho mais próximo estiver no quartil inferior da distribuição de vizinhos mais próximos daquela dimensão.

A classificação só será permitida quando:

- o canal tiver pelo menos 10 inscrições;
- os dois lados da comparação tiverem cobertura mínima de 70% na dimensão;
- existir ao menos um par válido.

Não haverá soma das cinco dimensões. A página terá um painel independente por dimensão. Cada painel mostrará quatro grupos:

- escala alta e mais diferenciado;
- escala alta e semelhante aos pares;
- escala menor e mais diferenciado;
- escala menor e semelhante aos pares.

O visual dos quadrantes terá somente quatro grupos. A tabela abaixo mostrará no máximo os dez canais mais relevantes da dimensão e manterá a relação completa em uma seção expansível ou tabela paginada.

## 6. Redundância entre canais

A redundância será tratada como uma lista de pares para revisão, não como recomendação automática de corte.

Para cada dimensão, os limites de forte similaridade serão definidos pelo percentil 90 dos pares válidos daquela dimensão. Os limites serão recalculados a partir da base congelada e publicados em `summary.json`.

Um par entra em `sobreposição multidimensional` quando:

- estiver no decil superior de similaridade em pelo menos quatro das cinco dimensões acionáveis;
- pelo menos geografia ou fase temporal estiver entre as dimensões qualificadas;
- ambos os canais tiverem no mínimo 10 inscrições;
- a cobertura mínima de 70% for atendida em cada dimensão contada.

Os pares serão ordenados deterministicamente por:

1. quantidade de dimensões qualificadas, decrescente;
2. valor bruto combinado, decrescente;
3. nomes dos canais.

O relatório mostrará Top 10 pares. Cada linha exibirá os cinco valores de similaridade, coberturas, inscrições, valor bruto e uma interpretação curta. Não haverá média ou score agregado escondido.

A matriz visual ficará limitada aos dez maiores canais comerciais por valor bruto. A lista de pares continuará permitindo que canais menores e diferenciados apareçam quando atenderem às regras.

## 7. Simulador de cobertura em risco

O simulador aceitará de um a dez canais comerciais não orgânicos. A seleção será preservada na URL para compartilhamento e impressão.

A unidade de análise será a célula:

`fase × distância × estado`

Para cada seleção, o simulador calculará:

- inscrições e valor bruto observados dos canais selecionados;
- participação selecionada no evento inteiro;
- participação selecionada dentro de cada célula;
- participação selecionada entre canais comerciais não orgânicos da célula;
- canais comerciais remanescentes na mesma célula;
- principal alternativa observada por volume;
- estados, distâncias e fases com maior concentração na seleção.

Classificação de exposição:

- **alta:** seleção representa pelo menos 40% de todas as inscrições da célula e contém ao menos 10 inscrições;
- **média:** seleção representa de 20% a 39,99% da célula e contém ao menos 10 inscrições;
- **dependência entre parceiros:** seleção representa pelo menos 60% das inscrições comerciais não orgânicas, mas menos de 20% do total da célula;
- **baixa:** demais células publicáveis.

Células com menos de cinco inscrições selecionadas não serão detalhadas; seus valores permanecerão apenas nos totais agregados. Categorias de gráficos seguirão Top 10 + `Outros`, sempre com `Outros` no final.

O texto usará `cobertura em risco`, `concentração observada` e `alternativa observada`. Nunca usará `vendas perdidas`, `substituição garantida` ou outra alegação causal.

## 8. Composição do relatório estático

O relatório de decisão terá seis capítulos:

1. **Resumo executivo:** concentração atual, quantidade de canais comerciais, principais dependências e implicação para 2027.
2. **Escala e diferenciação:** cinco painéis dimensionais com quadrantes e tabelas Top 10.
3. **Pares para revisão:** Top 10 sobreposições multidimensionais com evidências separadas.
4. **Dependências observadas:** Top 10 células em que um único canal comercial concentra parcela relevante do evento.
5. **Como usar o simulador:** limites do cenário e acesso ao módulo interativo.
6. **Método e limitações:** definições, cobertura, amostras pequenas e ausência de causalidade.

O cabeçalho seguirá o padrão visual atual, com botões para Análise geral, Dossiês, Simulador e Gerar PDF. A análise geral, a lista de canais e os dossiês receberão um botão `Portfólio 2027`.

## 9. Fluxo de dados e atualização incremental

O novo transformador consumirá somente artefatos derivados já congelados:

- índice de canais para escala, ticket, slug e recomendação;
- similaridades dimensionais dos dossiês para pares e vizinhos;
- cubo de inscrições do explorador para células de cobertura.

Ele não consultará o banco e não reprocessará pedidos brutos. O manifesto registrará hashes das três dependências e da regra do transformador.

Mudanças futuras terão escopo previsível:

- texto ou CSS: somente código web;
- regra dos quadrantes: `portfolio/summary.json`;
- regra do simulador: `portfolio/simulator.json`;
- mudança nos fatos congelados: invalida os dois artefatos e segue a cadeia modular existente.

## 10. Falhas e estados incompletos

- artefato ausente ou com hash incompatível impede a página de emitir conclusões;
- dimensão sem pares válidos aparece como `evidência insuficiente`, nunca como zero;
- canal desconhecido na URL do simulador é rejeitado e informado;
- mais de dez canais selecionados bloqueiam o cálculo com mensagem clara;
- cenário sem células publicáveis mostra os totais e explica o limiar mínimo;
- ausência de alternativa observada aparece como `sem alternativa comercial observada`;
- dados ausentes não são convertidos em zero.

## 11. Validação e critérios de aceite

### Dados

- totais do evento reconciliados com 14.027 pedidos pagos, 15.713 inscrições pagas e R$ 4.321.891,20 de valor bruto;
- soma dos perfis de cada canal reconciliada ao índice;
- pares simétricos e sem duplicação A–B/B–A;
- percentis determinísticos e coberturas mínimas respeitadas;
- orgânico e canais com ticket de até R$ 10,00 fora da seleção do simulador;
- totais gerais preservados apesar do corte comercial;
- cenários de uma e várias seleções reconciliados por célula;
- células pequenas suprimidas somente no detalhe;
- nenhum `kit_incluso` nos perfis de produto;
- nenhum dado pessoal nos novos artefatos.

### Interface

- relatório estático imprimível sem carregar o cubo do simulador;
- simulador carrega sem os dossiês e limita a seleção a dez canais;
- gráficos com Top 10 + `Outros` e tabelas em ordem decrescente;
- navegação consistente em desktop e celular;
- estados de vazio e erro legíveis;
- URL compartilhável reproduz exatamente a seleção;
- `/inscricoes/` permanece byte a byte inalterada.

### Desempenho e implantação

- `portfolio/summary.json` deve permanecer abaixo de 750 KB;
- `portfolio/simulator.json` deve permanecer abaixo de 2 MB;
- o build modular verifica hashes, privacidade e reconciliação antes da publicação;
- deploy incremental publica somente a nova rota, seus assets e os novos artefatos privados;
- o CFML é compilado e as rotas autenticadas são verificadas antes do fechamento.

## 12. Limitações assumidas

O cupom identifica associação observada, não prova incrementalidade. O simulador mede concentração histórica, não demanda futura. Sem custo de contrato, cachê, permuta, mídia ou comissão, o módulo não compara ROI. Essas informações podem formar uma camada financeira posterior sem alterar as definições deste módulo.
