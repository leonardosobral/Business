# Relatório modular de vendas — Maratona de Floripa 2026

Data: 2026-09-01

## 1. Objetivo

Refatorar o estudo encerrado de vendas da Maratona de Floripa 2026 para que ele:

- explique o ciclo de vendas por tempo, distância, lote, território, canal e produto;
- identifique em quem e no que focar em cada fase comercial;
- ajude a reduzir o portfólio de canais em 2027, preservando parceiros que tenham escala ou perfis complementares;
- ofereça uma leitura executiva pronta para pessoas que não saibam explorar dados;
- gere um PDF geral e PDFs individuais por canal;
- permita investigações adicionais em um explorador controlado;
- aceite alterações incrementais sem reconstruir o relatório inteiro.

O estudo continuará separando pedidos, inscrições e produtos para não misturar grãos nem duplicar valores.

## 2. Restrições e decisões já aprovadas

- A tela `/inscricoes/` não será alterada.
- A versão principal será uma leitura editorial quase estática, não um dashboard dependente de exploração livre.
- Os dossiês ficarão fora da análise geral e serão carregados individualmente.
- O explorador será secundário e autenticado.
- A nova versão completa será restrita a usuários autenticados no Business.
- A versão pública atual permanecerá disponível durante o desenvolvimento e será protegida somente na troca final.
- O HTML monolítico atual será preservado no histórico e arquivado fora da área pública após a troca.
- Gráficos categóricos exibirão no máximo dez itens; o restante será consolidado em `Outros`, sempre na última posição.
- Tabelas manterão a relação completa, com ordenação e paginação quando necessário.
- ROADRUNNERS receberá uma leitura aprofundada adicional.
- Sports Week e PCD permanecerão explicitamente no escopo. Benefício só será elevado a dossiê estratégico se atender às regras gerais ou houver decisão posterior.

## 3. Entregáveis

### 3.1 Análise geral

Documento contínuo, próprio para leitura e impressão, composto por:

1. resumo executivo;
2. ciclo de vendas;
3. distâncias;
4. lotes;
5. territórios;
6. produtos;
7. portfólio de canais;
8. conclusões e plano de ativação para 2027.

A análise geral não conterá os dossiês completos, apenas o índice e a leitura comparativa do portfólio.

### 3.2 Dossiês de canais

Cada canal elegível terá uma página autenticada independente e imprimível. O modelo será igual para todos:

1. resumo executivo;
2. momento de venda;
3. distâncias e lotes;
4. territórios;
5. produtos;
6. diferenciação e sobreposição;
7. recomendação para 2027;
8. notas de cobertura, base e limitações.

Aliases e múltiplos cupons continuarão consolidados sob o canal canônico, mas o dossiê mostrará a composição por cupom para auditoria comercial.

### 3.3 PDFs

Saídas padrão:

- um PDF da análise geral, sem os dossiês;
- um PDF independente para cada canal.

Uma exportação extraordinária com todos os dossiês poderá existir, mas não será a saída padrão. O modo de impressão carregará todos os capítulos necessários antes de abrir a impressão e aplicará quebras de página, cabeçalhos, legendas, fontes e tabelas adequadas.

### 3.4 Explorador

Área separada para usuários autenticados investigarem cruzamentos adicionais. O explorador não altera os textos nem as conclusões do relatório editorial.

## 4. Modelo temporal

O relatório manterá duas leituras simultâneas:

- semana civil real, iniciada na segunda-feira;
- fase relativa do ciclo de vendas.

As fases serão calculadas entre a primeira e a última venda paga válidas do ciclo fechado:

- **Lançamento:** primeiros 14 dias, limitado ao marco de 25% do ciclo;
- **Início:** depois do lançamento até 25% do ciclo;
- **Meio:** acima de 25% até 70%;
- **Reta final:** acima de 70% até 90%;
- **Encerramento:** acima de 90% até o fechamento.

As mudanças de lote serão marcadores independentes sobre a linha do tempo. Elas não definirão as fases, evitando confundir efeito de preço com sazonalidade. A mesma regra será reutilizável em 2027.

## 5. Modelo analítico

### 5.1 Fato de pedidos

Grão: um pedido pago único.

Medidas:

- pedidos pagos;
- valor bruto;
- desconto;
- taxas;
- cashback, quando aplicável;
- valor líquido transferido;
- ticket por pedido, calculado como razão entre totais.

### 5.2 Fato de inscrições

Grão: uma inscrição vinculada a pedido pago.

Dimensões:

- semana;
- fase;
- distância/modalidade;
- lote;
- estado e cidade válidos;
- canal canônico;
- cupom observado;
- atributos auxiliares com cobertura suficiente.

Medidas:

- inscrições pagas;
- valores de pedido alocados;
- desconto alocado;
- participação no grupo;
- participação no evento;
- ticket por inscrição, calculado a partir dos totais do recorte.

### 5.3 Fato de produtos

Grão: inscrição-produto normalizada.

As classificações `adicional` e `kit_incluso` permanecerão separadas. Medidas:

- inscrições distintas com o produto;
- quantidade de itens;
- taxa de adoção;
- receita explícita;
- cobertura da receita explícita.

O fato de produtos não será somado ao fato de inscrições. Ticket de pedido e receita alocada não serão inferidos a partir de linhas de produto.

## 6. Cruzamentos editoriais

### 6.1 Ciclo de vendas

- semana e fase por inscrições, receita, ticket e desconto;
- distância por semana e fase;
- lote por semana e fase;
- mudanças de lote sobre a curva de vendas;
- velocidade, picos e concentração temporal.

### 6.2 Distâncias

- 5K, 21K, 42K, Desafio e Kids;
- distância × fase;
- distância × lote;
- distância × estado;
- distância × canal;
- distância × produto.

### 6.3 Lotes

- composição de distâncias em cada lote;
- estados e canais de cada lote;
- ticket e desconto;
- comparação entre efeito de preço, momento do ciclo e mudança de público.

### 6.4 Territórios

- curva de vendas por estado;
- comportamento antecipado, constante ou tardio;
- estado × distância;
- estado × fase;
- estado × canal;
- ticket e desconto por estado;
- cidades como aprofundamento em Top 10 + Outros.

### 6.5 Produtos

- adicionais separados de itens incluídos;
- produto × distância;
- produto × fase;
- produto × lote;
- produto × canal;
- receita somente onde o valor estiver explícito e reconciliado.

## 7. Portfólio e recomendações de canais

O índice comercial continuará ordenado por:

1. valor bruto alocado decrescente;
2. inscrições pagas decrescentes;
3. nome do canal.

Cada canal será analisado em cinco eixos:

- escala comercial;
- especialização por distância;
- especialização territorial;
- momento do ciclo;
- produtos e diferenciação em relação ao orgânico e aos demais canais.

As recomendações possíveis serão:

- **Priorizar:** escala relevante e contribuição diferenciada;
- **Manter com função definida:** útil em território, distância, fase ou produto específico;
- **Testar/renegociar:** potencial existente, mas evidência, escala ou retorno insuficientes;
- **Reduzir/descontinuar:** baixa contribuição e forte redundância.

Canais com menos de dez inscrições permanecerão na cauda longa, salvo exceções estratégicas explícitas. Bases entre dez e 29 inscrições receberão aviso de amostra reduzida e não poderão receber recomendação forte de descontinuação apenas por esse resultado. ROADRUNNERS, Sports Week e PCD terão leitura explícita mesmo quando uma regra geral de volume não os priorizar.

As categorias serão justificadas por evidências visíveis; não haverá pontuação opaca nem alegação causal.

## 8. Explorador controlado

O explorador permitirá:

- escolher uma métrica principal: inscrições, receita bruta, desconto, ticket ou adoção de produto;
- escolher uma dimensão principal: semana, fase, distância, lote, estado, canal ou produto;
- adicionar no máximo uma dimensão de comparação;
- filtrar por fase, período, distância, lote, estado, canal e produto;
- comparar com o evento inteiro ou com o orgânico;
- preservar filtros na URL.

Regras:

- no máximo duas dimensões visíveis;
- Top 10 + Outros em gráficos com mais de dez categorias;
- tabela completa ordenada;
- denominador, grão e cobertura sempre visíveis;
- combinações incompatíveis bloqueadas;
- amostras pequenas qualificadas;
- nenhuma consulta livre a pedidos ou participantes.

## 9. Arquitetura modular e atualização incremental

A extração encerrada de 2026 será congelada. O processamento terá estágios independentes:

1. fontes congeladas;
2. fatos normalizados e cacheados;
3. agregados por domínio;
4. narrativas e recomendações;
5. artefatos de leitura e impressão.

Agregados de saída:

- análise geral;
- ciclo e distâncias;
- territórios;
- produtos;
- índice de canais;
- um agregado por dossiê;
- cubos permitidos para o explorador.

Cada agregado terá versão, hash da entrada, hash da regra de transformação e data de geração. Um estágio só será reconstruído se sua entrada ou regra tiver mudado.

Consequências esperadas:

- texto ou estilo: recompila apenas a interface afetada;
- alteração de um canal: atualiza seu agregado, índice e comparações dependentes;
- alteração territorial: atualiza territórios e páginas que o consomem;
- mudança nas regras financeiras: invalida os agregados financeiros dependentes, mas não exige nova extração;
- nova fonte: invalida fatos e dependentes de forma explícita.

## 10. Aplicação e rotas

Rotas planejadas:

- `/relatorios/maratona-floripa-2026/` — análise geral;
- `/relatorios/maratona-floripa-2026/canais/` — índice de canais;
- `/relatorios/maratona-floripa-2026/canais/dossie.cfm?canal=<slug>` — dossiê individual;
- `/relatorios/maratona-floripa-2026/explorador/` — explorador controlado.

As páginas de leitura usarão conteúdo pré-calculado e comportamento mínimo. Recursos visuais compartilhados serão versionados e cacheáveis. O dossiê carregará somente um canal. A análise geral não carregará os dossiês.

## 11. Autenticação e proteção dos dados

- Todas as páginas analíticas, dossiês, PDFs e endpoints de dados reutilizarão a autenticação existente do Business.
- Acesso não autenticado será redirecionado ao login com retorno seguro para a página solicitada.
- Dados analíticos ficarão fora da raiz pública ou serão servidos exclusivamente por endpoint autenticado com lista explícita de conjuntos permitidos.
- O identificador de dossiê será validado contra o manifesto de canais; caminhos arbitrários serão rejeitados.
- Nenhum pedido, participante, e-mail, documento, endereço ou outro identificador pessoal será implantado.
- Os ativos públicos de JavaScript e CSS não conterão dados comerciais nem recomendações.
- A versão pública antiga será removida da raiz servida somente no corte final aprovado.

## 12. Falhas e estados incompletos

- Ausência de dados será exibida como `indisponível`, nunca como zero.
- Versões incompatíveis de agregados impedirão a página de publicar conclusões.
- Falha em um módulo não esconderá os demais, mas a página exibirá aviso claro e não produzirá PDF final silenciosamente incompleto.
- Receita de produto sem cobertura explícita suficiente não será estimada.
- Cobertura territorial e de perfil acompanhará todo cruzamento correspondente.
- O modo PDF falhará de forma visível se algum capítulo obrigatório não carregar.

## 13. Validação

### 13.1 Dados

- reconciliação de pedidos, inscrições, valor bruto, desconto, taxas e líquido;
- reconciliação entre fases, semanas, distâncias e lotes e os totais do evento;
- teste contra duplicação em cruzamentos de produtos;
- teste de tickets como razão de totais;
- teste de valores ausentes versus zero;
- teste de Top 10 + Outros e ordem de `Outros`;
- comparação de rebuild incremental com rebuild completo.

### 13.2 Canais

- consolidação de múltiplos cupons por canal canônico;
- ordenação comercial determinística;
- limiares de amostra e avisos;
- evidências das quatro categorias de recomendação;
- casos dedicados a ROADRUNNERS, Sports Week e PCD.

### 13.3 Segurança

- acesso não autenticado às páginas e dados;
- tentativa de consultar conjunto ou slug não permitido;
- varredura de identificadores pessoais;
- confirmação de que arquivos privados não são servidos diretamente.

### 13.4 Interface e impressão

- desktop e mobile;
- navegação por teclado e contraste;
- ausência de overflow horizontal;
- gráficos limitados a Top 10 + Outros;
- quebras de página, cabeçalhos e tabelas no PDF;
- PDF geral sem dossiês;
- PDF de dossiê contendo somente o canal selecionado.

## 14. Implantação

1. Construir a versão modular em rota autenticada de validação.
2. Manter a versão pública atual durante o desenvolvimento.
3. Validar dados, interface, impressão e autenticação.
4. Fazer revisão executiva da análise geral e de dossiês estratégicos.
5. Substituir a URL atual pela entrada autenticada.
6. Arquivar o HTML monolítico fora da área pública.
7. Confirmar que `/inscricoes/` não mudou.
8. Validar o origin e a URL externa após o deploy.

## 15. Fora do escopo

- alterar a operação de inscrições;
- reabrir vendas ou modificar pedidos;
- atribuir causalidade a cupons ou canais;
- expor dados individuais;
- criar um BI livre ou permitir SQL no navegador;
- automatizar decisões contratuais sem revisão humana;
- produzir uma versão pública resumida nesta primeira refatoração.
