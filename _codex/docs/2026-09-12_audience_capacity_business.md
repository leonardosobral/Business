# Business — capacidade em exposições e navegação do painel

## Escopo aprovado

Em 12/09, o usuário aprovou primeiro a capacidade em exposições, sem estimar
cliques ou consumo de créditos. Na continuação, pediu explicações mais claras
no topo, abas e tabelas compactas. Trabalho restrito ao Business; não altera
coletor, opt-out/GPC, localização, campanhas, cobrança, retenção ou `tb_log`.

Estado deste registro: capacidade, abas e compactação implementadas e validadas
localmente; lote pronto para publicação. Ainda não publicado. Os dados dos testes
são sintéticos e não descrevem a audiência de produção.

## Contrato de capacidade

- Fonte: `audience.events`, pelo datasource de leitura existente `runnerhub`.
  Nenhuma credencial, role ou permissão foi alterada; não depende de novo SQL de
  instalação nem da execução da retenção.
- Disponível somente no contexto comercial, ambiente `prod`, sem acessos internos.
  Período, UF comercial, família de página e dispositivo seguem os filtros do
  painel. As demais dimensões regionais continuam disponíveis nos outros relatórios.
- Posição regional: `page_view_id + slot_key + market_uf`. Usa a primeira
  oportunidade para identificar dia de Brasília, família e dispositivo. Remontagens,
  mudança de placement/criativo e repetição lógica não multiplicam a posição.
- Total físico: nova deduplicação por `page_view_id + slot_key` depois dos filtros.
  Não soma linhas regionais que podem se sobrepor quando uma página muda de UF.
  Não representa pessoas únicas. O inventário operacional anterior permanece com
  suas contagens de sinais e estados; não é silenciosamente redefinido.
- Registradas incluem posições vazias, institucionais, ocultas e indisponíveis.
  Montagem e exposição exigem os respectivos sinais `slot_render` e
  `slot_viewable`. Eventos sem oportunidade correspondente no período não criam
  capacidade; uma exposição após meia-noite continua vinculada ao dia da posição.
- Totais abrangem todos os grupos; consulta traz até 201 detalhes para permitir
  aviso de limite, e a tela apresenta os primeiros 200 por quantidade de registros.
  A UF desconhecida permanece explícita, sem atribuição arbitrária a um estado.

## Histórico e cenários, não compromisso de campanha

Cada grupo UF × posição × família × dispositivo tem sua própria base. São usados
os últimos 28 dias encerrados com sinais de oportunidade em todos eles, ou os
últimos 14 quando 28 ainda não estão disponíveis. Hoje e o primeiro dia observado
no período selecionado são excluídos conservadoramente por poderem ser parciais.
O filtro de 7 dias mantém contagens, mas não fornece base para cenários.

Um dia sem sinais não vira zero. Um dia com posição registrada mas sem exposição
contribui com zero exposições observadas. Sem nenhuma exposição na base, não há
cenário numérico. Histórico insuficiente, ausência de sinais e erro de consulta
são estados diferentes de previsão zero.

- Ritmo médio para 30 dias: `floor(exposições da base / dias da base × 30)`.
- Cenário inferior: `floor(menor volume entre os blocos de 7 dias / 7 × 30)`.
- Não há cenário nacional somando projeções regionais sobrepostas.

São cenários direcionais sob manutenção do ritmo observado, não intervalo de
confiança, prova de cobertura contínua, capacidade livre para venda ou promessa de
entrega. Sinais diários não detectam necessariamente interrupções dentro do dia.
Comparabilidade de apresentação, sazonalidade, campanhas concorrentes e compromissos
precisam ser considerados antes de usar esses volumes em uma contratação. Não há
CTR, CPC, receita ou consumo de créditos derivado deste cálculo.

## Integração e arquivos de runtime

- `portal/audiencia/queries/capacity.sql`: leitura parametrizada, sem DDL/DML.
- `portal/includes/audience_backend.cfm`: consulta opcional, cache de 1 minuto,
  timeout de 15 segundos, erro isolado dos sete relatórios existentes.
- `portal/audiencia/capacity.cfm`: seção administrativa, contagens observadas,
  histórico por grupo e cenários separados, escape de valores recebidos.
- `portal/audiencia/home.cfm`, `assets/js/audience-dashboard.js` e
  `assets/css/audience-dashboard.css`: organização em abas e tabelas compactas.

Os SQLs continuam protegidos pelo `.htaccess` da pasta `queries`. Autenticação e
autorização administrativa existentes não são alteradas. Sem commit, branch,
conexão a banco de produção ou publicação automática nesta etapa.

## Organização da tela

- Seis abas: Visão geral, Capacidade, Posições, Conteúdo, Origem e LIVE! e Cobertura.
  O topo mantém os seis indicadores, período/filtros ativos, última recepção e
  definições curtas de registro, exposição e cenário.
- Filtros recolhidos por padrão, com resumo do recorte sempre visível. Seleções
  internas ou de ambiente não produtivo deixam os filtros abertos para evidenciar
  o contexto. O envio GET preserva a aba e os filtros anteriores.
- Inventário e conteúdo passam a seis colunas; aquisição, a cinco. Estados de
  entrega ficam em detalhes expansíveis por posição, sem remover pedidos,
  servidos, pagos, institucionais, vazios, pendências, indisponibilidade ou erros.
  Profundidade editorial, métricas de vídeo e dados de aquisição são preservados.
- Tabelas extensas têm rolagem interna e cabeçalho fixo. Abas têm navegação por
  teclado, foco visível, links diretos e histórico voltar/avançar. Sem JavaScript,
  todas as seções e formulários continuam disponíveis; falha dos gráficos não
  impede a leitura das tabelas. Gráficos são inicializados ao exibir sua aba.

## Verificação local

Executadas e concluídas:

- `node _codex/scripts/test_audience_capacity_report_local.mjs`: 58 verificações
  em PostgreSQL 16 isolado, consulta somente leitura com role SELECT-only. RED
  reproduzido contra o inventário anterior, que não tinha o contrato de capacidade.
- `node _codex/scripts/test_audience_capacity_cfml_local.mjs`: 18 verificações do
  template CFML real com dados sintéticos, estados, valores, escape e limites.
- `node _codex/scripts/test_audience_capacity_backend_local.mjs`: 8 verificações
  do backend real, substituindo apenas a chamada externa ao banco na cópia de
  teste. Falha de capacidade preserva os sete relatórios e seus totais. Os filtros
  incompatíveis não consultam a nova capacidade.
- Regressões PostgreSQL: relatório geral 51, editorial 21, LIVE 28 verificações.
- Regressão editorial CFML: 11 verificações de renderização. Modelos dos gráficos:
  5 testes Node, incluindo datas sem medição e taxas sem denominador.
- `node _codex/scripts/test_audience_tabs_local.mjs`, com o `NODE_PATH` abaixo:
  navegador real em 1440, 768 e 390 px. Passaram as seis abas, teclado, links
  antigos e diretos, voltar/avançar inclusive sem fragmento, filtros GET, estados
  de entrega, métricas editoriais, capacidade, redimensionamento dos gráficos e
  ausência de rolagem lateral no corpo. Passaram também os modos sem JavaScript,
  sem biblioteca de gráficos e com JSON de gráficos inválido.
- A inspeção visual levou a um ajuste adicional na capacidade mobile: largura
  mínima própria para posição, histórico e cenários. O teste reproduziu a coluna
  estreita antes da correção e confirmou largura legível, altura limitada das
  linhas da fixture e rolagem interna depois dela.
- Repetição final do agente principal passou integralmente. Artefatos sintéticos
  dessa execução: `/var/folders/ct/41b1hy657kq5s56h529h2y3m0000gn/T/audience-tabs-render-H9om0Q/`.
  Capturas das seis abas e detalhes mobile em `visual/`; são arquivos temporários
  de QA, não uma publicação nem uma cópia dos números de produção.
- `node --check` dos scripts alterados e `git diff --check` sem erros.

Os runners CFML aceitam `AUDIENCE_CFML_BOX_RUNTIME`,
`AUDIENCE_CFML_COMMANDBOX_HOME` e `AUDIENCE_CFML_JAVA_RUNTIME`; verificam a presença
do runtime/cache Lucee 5.3.10.120 e não instalam dependências. PostgreSQL temporário
usa socket local sem listener TCP e não lê configurações/credenciais de produção.
O sandbox bloqueou memória compartilhada; a execução local isolada passou com
aprovação específica. Esses testes não comprovam latência com volume de produção
nem equivalência integral ao Adobe ColdFusion do servidor.

O runner das abas usa o pacote `playwright` e o Chrome já instalados. Se o pacote
não estiver no projeto, apontar `NODE_PATH` para o `node_modules` existente. Neste
ambiente foi usado `/Users/leonardosobral/.npm/_npx/31e32ef8478fbf80/node_modules`.
O teste abre somente um servidor efêmero em `127.0.0.1`, bloqueia solicitações do
navegador para outros hosts e precisa de permissão local para bind/Chrome quando
o sandbox os bloqueia. A primeira repetição sem essas condições falhou por
`EPERM` no bind e, depois, pela ausência de `playwright` na resolução padrão;
não houve instalação de pacotes ou alteração da aplicação para contornar isso.
O runner legado `test_audience_dashboard_browser.mjs` foi adaptado aos filtros
recolhidos, mas não executado: depende do harness Adobe fora deste lote.

Revisão independente da capacidade não encontrou defeito de produto. Solicitou
parametrizar os caminhos dos runners CFML; ajuste aplicado e testes repetidos.
A revisão independente da UI confirmou preservação das métricas e não encontrou
bloqueio funcional; o nome acessível de “Ver detalhes” foi ajustado para incluir
o texto visível e a quantidade de erros. LIVE populado não foi redesenhado nem
validado visualmente neste lote; sua consulta passou na regressão SQL e o include
existente foi preservado. A navegação integrada foi exercitada com o estado de
indisponibilidade dessa seção.

## Publicação posterior

Publicar somente os seis arquivos de runtime acima, com cópias de recuperação dos
arquivos substituídos e conferência de hashes. Disponibilizar SQL/template de
capacidade e assets antes dos consumidores backend/home. Preservar `.htaccess`,
configurações e fontes das outras frentes. Não precisa rodar migração nem reiniciar
o serviço por mudança de configuração. A validação autenticada posterior deverá
confirmar contagens reais, abas/filtros e histórico insuficiente enquanto a base
recente ainda não tiver os dias necessários; não gerar tráfego publicitário para
produzir projeção. Reversão é restaurar os arquivos deste lote, sem apagar dados.
