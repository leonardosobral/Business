# Audiência no Business — escopo e pendências

Revisão de 12/09/2026, solicitada pelo usuário. Este registro orienta as próximas
continuações do [plano de audiência e inventário](estrategia_audiencia_inventario_e_midia_proposta.md).
Consolida as entregas e verificações registradas abaixo. A revisão de escopo é
documental; a continuação de 12/09 também verificou o término de um vídeo em
produção, sem alterar runtime, banco ou configurações.

## O que continua e o que saiu

Continuam: medição do site, Ads, banners, posições sem campanha e conteúdo;
recortes por página, posição, dispositivo e UF; acompanhamento no Business;
capacidade comercial baseada no inventário observado; privacidade e operação
da coleta. Origem e UTM já implementadas são preservadas.

**Saiu a segunda parte de mídia e crescimento.** Campanhas externas, investimento,
criativos, testes A/B de aquisição, canais, remarketing e expansão de público
estão em outra frente. Não solicitar verba, acessar contas de mídia, construir
um novo funil de custos de aquisição ou modificar os artefatos daquela frente.
Esta revisão não desliga funcionalidades nem apaga métricas ou dados existentes.

**Também dispensado pelo usuário em 12/09: versionamento do layout.** Não criar
campo, filtro ou SQL para isso. Mudanças podem ser tratadas como nova campanha
ou otimização de campanha, sem um mecanismo adicional de versões. Esta decisão
encerra o requisito, não o adia; não reabri-lo em outra continuação. Peças sem
campanha continuam sem identidade fictícia de Ads e sem consumo de crédito.

**Geolocalização: retirada das pendências ativas por decisão do usuário.** Manter
FreeIPAPI e a integração existente, sem troca por GeoJS nem novo fallback. O usuário
optou por tratar o 403 como pontual e retomar somente se houver evidências de
problema recorrente. Não repetir sondagens nem exigir esse tema para prosseguir
com audiência. O diagnóstico anterior fica como histórico, sem afirmar que o
bloqueio foi corrigido ou que permanece contínuo. Esta decisão não solicita uma
automação de monitoramento nem autoriza consultas a novos fornecedores.

**Capacidade em exposições aprovada nesta continuação:** entregar primeiro
volume observado, histórico/lacunas e cenários de exposição, sem estimar cliques
ou créditos nesta etapa. O usuário também pediu resumo claro no topo, abas e
tabelas compactas. [Implementação e critérios](2026-09-12_audience_capacity_business.md).

A peça institucional lateral continua: é conteúdo próprio no espaço sem campanha
para medir sua exposição física, não compra de mídia. A definição comercial de
UF também permanece: visitante de SP consultando provas em SC conta no contexto
comercial de SC; a UF física é um campo separado.

## Entregas já publicadas

- Coleta e painel ativos desde 08/09: [recibo de ativação](2026-09-08_audience_activation_receipt.json).
- Reprodução de YouTube integrada em 10/09, com inícios confirmados no Business: [recibo](2026-09-10_audience_youtube_publicado.md).
- Conclusão de YouTube confirmada na tela em 12/09, excluída do recorte comercial como acesso interno: [verificação e limites](2026-09-12_audience_youtube_conclusao_verificada.md).
- Persistência de início, 25%, 50%, 75% e conclusão de YouTube confirmada pelo resultado SQL devolvido pelo usuário em 12/09: os cinco sinais ocorreram na mesma visualização interna. Pendência dos quartis encerrada; não implica reprodução integral nem nova exibição dos quartis no painel.
- Exposição de cards e profundidade editorial em 10/09: [recibo](2026-09-10_audience_editorial_publicado.md).
- Medição das promoções estáticas do lote de 11/09: [recibo](2026-09-11_audience_static_promos_publicado.md).
- Classificação de estados de entrega em 12/09: [recibo](2026-09-12_audience_delivery_states_publicado.md).
- Piloto institucional lateral em 12/09 às 11:48:22 BRT, preservando campanhas e coleta: [recibo e limites](2026-09-12_audience_sidebar_house_publicado.md).
- Capacidade em exposições, seis abas, topo explicativo e tabelas compactas em 12/09; leitura real confirmada após correção pontual de compatibilidade Adobe no SQL: [recibo e limites](2026-09-12_audience_capacity_publicado.md).

Não reabrir esses lotes como se não estivessem publicados. Os limites abaixo
continuam explícitos; publicação não equivale a confirmação de todos os cenários.

## Trabalho restante e dependências

| Item | Estado comprovado / próximo resultado necessário |
| --- | --- |
| Histórico para cenários de capacidade | Capacidade observada e interface já publicadas e confirmadas com dados reais, sem migração. Não repetir sua implementação/publicação como pendência. Cenários exigem base recente de 14/28 dias encerrados com sinais por grupo, sem usar hoje, o primeiro dia observado ou preencher lacunas com zero. A ativação em 08/09 não fornece essa base em 12/09; o volume observado continua sendo exibido. Sinais diários não certificam continuidade da coleta nem comparabilidade do layout. Cliques e créditos ficaram para depois por aprovação do usuário. [Contrato e critérios](2026-09-12_audience_capacity_business.md), [recibo](2026-09-12_audience_capacity_publicado.md). |
| Retenção de 90 dias | Resultado SQL devolvido pelo usuário em 12/09: registro presente, 90 dias, `status=never`, tentativa e sucesso nulos. Ainda sem execução registrada; o DBA deve concluir a operação/agendamento da rotina existente. Não mudar permissões de `runner_dba` nem exigir isso para contar acessos. Não recriar a identidade já instalada. [Registro anterior](2026-09-11_audience_static_promos_publicado.md). |
| Institucional lateral sem candidato | Ramo validado localmente e arquivos publicados por hash. Navegação normal em 12/09, por volta de 17:54 BRT, da home para São Paulo pelo seletor também encontrou Avaí Run elegível, com imagem carregada (318×318). Ambiente `prod`, família `state`, acesso interno, sem erros de console capturados. O ramo sem candidato continua não observado. Não repetir esse teste sem novo cenário, desativar campanhas, injetar eventos ou forçar contexto para obter número. [Limite anterior](2026-09-12_audience_sidebar_house_publicado.md). |
| Visualização de evento em `tb_log` | Somente no final: resolver cobertura, leitores, histórico e data de corte antes de retirar exclusivamente essa gravação. Demais logs e histórico intactos. [Transição condicional](2026-09-10_tb_log_eventos_transicao.md). |

## Ordem de continuação

1. Completar as verificações de campo ainda pendentes quando houver cenário
   observável, com tráfego interno separado e sem implementar versionamento de
   layout. Início, quartis e conclusão de YouTube já verificados. Não repetir diagnósticos de infraestrutura
   inalterada nem transformar essas verificações em bloqueio da coleta.
2. Capacidade e organização do painel já publicadas; leitura autenticada real
   confirmada. O volume observado não aguarda linha de base; os cenários aparecem
   somente com histórico suficiente. Não forçar coleta para produzir projeções.
   Isso não depende de executar mídia paga.
3. Retomar a transição específica de `tb_log` por último, respeitando seus critérios.

Execução da retenção é uma pendência operacional independente; a investigação
de UF física saiu do trabalho ativo por decisão do usuário. Nenhuma delas
justifica zerar, suspender ou atrasar os contadores existentes. Permanecem
opt-out/GPC, DSN `runner`, autenticação, regras de Ads e cobrança. Não há novo
SQL necessário para esta alteração de escopo nem para o lote de capacidade.
A publicação dos seis arquivos foi concluída e está documentada no recibo acima.

## Resultado recebido das duas verificações de banco

[SQL somente leitura — vídeo e retenção](../sql/2026-09-12_audience_verificacao_final_readonly.sql).
O usuário executou a consulta e devolveu as duas linhas em 12/09. Não é necessário
repeti-la para encerrar a verificação dos vídeos. A role usada não foi informada.
Não é migração nem requisito para manter a contagem funcionando. Não conecta ao
banco por conta própria, não altera permissões e não executa ingestão ou expurgo.

- `video_teste`: recorta o teste interno de 12/09, das 16:40 às 16:50 BRT, com
  limite final exclusivo. Cada contador representa páginas de visualização com
  aquele sinal. `paginas_com_todos_os_sinais >= 1` comprova os cinco sinais na
  mesma página; não comprova reprodução integral, pois houve avanço no player.
  Resultado recebido: uma página com registros; uma com início, uma com cada
  marco (25/50/75), uma com fim e uma com todos os sinais. Persistência confirmada
  para esse teste interno em produção, sem extrapolar para toda a cobertura do site.
- `retencao`: apresenta o registro da rotina, última tentativa e último sucesso.
  `status=never` com sucesso nulo significa execução ainda não registrada;
  a consulta não dispara a rotina. `ainda_ha_expirados` é o estado salvo pela
  última execução, não uma nova varredura dos eventos expirados.
  Resultado recebido: registro presente, 90 dias, `status=never`, última tentativa
  e último sucesso nulos, código de erro vazio, zero removidos e
  `ainda_ha_expirados=false`. Esses valores iniciais não comprovam limpeza nem
  ausência atual de registros expirados; a operação da retenção segue pendente.

Validação local em 12/09: PostgreSQL 16.15, banco temporário sintético, sem rede
ou credenciais de produção, executando o arquivo como `runner` com apenas
`USAGE` no schema e `SELECT` nas duas tabelas. Passaram os casos de base vazia,
cinco sinais na mesma página, sinais distribuídos em páginas diferentes, chaves
exatas de início/fim, exclusões de ambiente/host/conteúdo/interno, limites da
janela e estados da retenção. As tabelas permaneceram idênticas antes/depois da
consulta. O ambiente temporário foi encerrado e removido. A primeira tentativa
foi impedida pelo sandbox ao iniciar o PostgreSQL; o teste passou com autorização
para execução local isolada. O agente não acessou o PostgreSQL 17.6 de produção;
a confirmação de produção acima vem exclusivamente do resultado fornecido pelo
usuário, sem publicação, alteração de runtime ou novo SQL nesta atualização.

## Continuação após o resultado SQL

Verificação de banner em aba temporária própria, encerrada ao final; abas do
usuário e das outras frentes permaneceram intactas. Não houve clique em anúncio,
alteração de viewport, conta, campanha, privacidade ou configuração. A imagem Avaí
foi conferida visualmente após rolagem; a ausência da peça de Maratonas não é
falha quando há banner elegível. Nenhuma nova persistência no Business foi alegada
com base somente no DOM.

Revisão preparatória de `tb_log`, somente leitura, confirmou as dependências já
mapeadas: painel legado com onze consultas, contador visível da home administrativa
e consulta mensal `qAcessosRR` do BI (executada, sem consumidor visual encontrado).
O writer compartilhado também atende o hotsite. Nada foi desligado ou migrado.
Quando a transição for retomada no final, o contador da home é uma superfície
pequena para começar, sem somar o período sobreposto das fontes; preservar erros,
404, OR/CT e histórico. Política mensal além de 90 dias e destino das análises
legadas baseadas em IP/UA ainda precisam de decisão, não de retenção permanente
presumida. Não antecipar essa transição por causa desta revisão.

## Resumo de ocupação publicado — 12/09, 22:36 BRT

Topo reorganizado em potencial observado, preenchidos e sem anúncio, com barras
separadas de Ads/banners e visitantes/sessões juntos. Crédito/pago adiado conforme
decisão do usuário; institucionais contam como preenchimento, não como venda.
Novo resumo conferido no Adobe e no Business autenticado com valores reais.
[Recibo do lote de cinco arquivos](2026-09-12_audience_occupancy_publicado.md).
Nenhuma alteração em coleta, autenticação, retenção ou `tb_log`. Preferência de
publicar as alterações solicitadas ao final registrada no `AGENTS.md` do Business.

## Correção comercial das oportunidades — 12/09, 23:23 BRT

A definição do resumo de 22:36 foi corrigida após o usuário demonstrar que o
denominador de posições vistas excluía oportunidades sem campanha. Não considerar
o 100% daquela versão como prova de ocupação comercial do site.

Agora o topo usa oportunidades de entrega sem exigência de visibilidade;
preenchimento servido conta independentemente do segundo de exposição, e vazio
sem campanha permanece no total. Falhas e posições desligadas ficam separadas.
Somente dois arquivos do Business publicados, sem SQL manual, alterações em
coleta, autenticação, cobrança, retenção ou `tb_log`.

Conferência real do Acre em 7 dias: 27 oportunidades de Ads, zero preenchidas e
27 sem anúncio; banners separados com 21 preenchidas. Geral: 5.258 oportunidades,
2.677 preenchidas, 2.151 sem anúncio e 430 sem confirmação. O filtro de UF atual
já funciona; uma comparação comercial consolidada de todos os estados continua
como extensão posterior, não foi acrescentada outra tabela nesta correção.
[Contrato, testes e recibo](2026-09-12_audience_delivery_opportunities.md).
