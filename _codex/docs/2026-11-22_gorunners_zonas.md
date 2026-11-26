# Homologação de zonas patrocinadas no Business

O item **GoRunners** fica logo abaixo de **Publicidade** no menu lateral, em **Marketing e audiência → Campanhas** para administradores e em **Divulgação** para contas diretas. A aba dentro de Publicidade abre a mesma rota `/ads/gorunners/`. Em **Todas as contas**, o administrador vê o status da integração. Pedidos e compras exigem uma conta selecionada. A integração nasce desativada. A página abre para contas diretas aprovadas com acesso à publicidade. As operações de compra usam a permissão financeira do Business. Acesso delegado, workspace pendente e compras em simulação ou sessão de suporte ficam fora do piloto.

## Demonstração sem API

Em **GoRunners → Testar mapa e compra em demonstração** (`/ads/gorunners/demo.cfm`), usuários com acesso ao painel podem desenhar a zona ou carregar a área de exemplo, escolher datas, cotar, simular a reserva e aprovar um pagamento fictício. A demonstração usa o mesmo seletor de mapa da compra e cobra um valor ilustrativo de R$ 10 por dia na simulação. As etapas ficam na memória da página. Recarregar inicia uma nova simulação. A demonstração não cria pedidos no banco, não chama os provedores comerciais e não altera o inventário do jogo.

## Preparação

1. Aplicar a [migração aditiva](../sql/2026-11-22_business_gorunners_zonas.sql) no PostgreSQL do Business. Ela cria a tabela de vendas, um índice por conta e permissões de leitura, inclusão e atualização para a role do datasource `runnerhub`.
2. Obter da equipe GoRunners o endereço HTTPS do ambiente de homologação, uma chave `grk_test_` com escopos `orders:write` e `reports:read`, modo de cobrança `external` e o segredo do webhook. Confirmar com a equipe se os pedidos de teste serão criados em um inventário apropriado para homologação.
3. Cadastrar `https://business.roadrunners.run/api/gorunners/webhook.cfm` no GoRunners para os eventos de pedido. Na conta **sandbox do Pagar.me**, cadastrar `https://business.roadrunners.run/api/gorunners/webhook.cfm?provider=pagarme` para eventos de pedido e cobrança. Para o piloto, o Business usa checkout hospedado no sandbox com cartão ou Pix.
4. Copiar [gorunners.local.example.cfm](../../config/gorunners.local.example.cfm) para `config/gorunners.local.cfm` no servidor, preencher as credenciais e os IDs das contas piloto e ativar `enabled`. O arquivo local é ignorado pelo Git. A configuração é lida por requisição.
5. Acessar o painel com uma conta piloto. Marcar pelo menos três vértices no mapa, informar as datas e consultar o preço. O término é exclusivo. O GoRunners converte o polígono em hexágonos, verifica conflitos e calcula o total. Reservar a área, informar marca e cliente e fechar o pedido. A tabela e a reserva têm a validade devolvida pela API.
6. Gerar a cobrança, pagar no sandbox e conferir separadamente o recebimento e a veiculação. Uma campanha com início futuro pode estar paga antes de entrar no ar. Verificar o relatório agregado e testar a expiração e a entrega duplicada dos webhooks. Confirmar que outra conta não consegue abrir o pedido pelo endereço direto.

## Contrato e recuperação

A implementação segue a [branch comercial do GoRunners](https://github.com/juan-silveira/GoRunners/tree/9b3045937ba295c28a9f723abe260fb62c247630/docs/commerce). O widget atual oferece zona e naming right e o pedido público não devolve `seller_id`. O painel de zonas usa diretamente `/quotes`, `/holds` e `/orders`. Ele fixa o produto `sponsor_zone` e envia uma referência aleatória `RHGR-` vinculada à conta. O ID remoto, o valor e a referência são conferidos no servidor. O Business guarda os dados operacionais da venda. Nome, documento e e-mail do cliente são enviados ao GoRunners no fechamento.

O webhook do GoRunners verifica HMAC-SHA256 sobre os bytes recebidos e confere os identificadores da entrega. Atualizações repetidas e antigas preservam o estado do pedido. O webhook do Pagar.me solicita nova consulta autenticada ao provedor. O Business confirma o pagamento no jogo somente após verificar a referência, a moeda BRL e o valor integral da cobrança paga. O botão **Conferir pagamento** repete a reconciliação quando um provedor fica indisponível. O saldo de créditos de publicidade não participa da compra.

Uma falha ambígua ao criar o link de checkout exige conferência da referência no Pagar.me. O painel evita emitir um segundo link para o mesmo pedido. Estornos, contestações e divergências de valor entram em conferência. O piloto não cancela campanhas pagas automaticamente nessas situações.

**Desativação.** Definir `enabled=false` bloqueia a compra e a recepção de novos eventos. Antes de encerrar um piloto com pagamentos pendentes, reconciliar os pedidos e conferir a fila de reentregas dos provedores. Preservar a tabela para histórico.

**Teste local.** A [suíte CFML](../tests/gorunners-zones.cfm) usa um [provedor simulado](../tests/GoRunnersZoneFake.cfc), a migração real e um PostgreSQL descartável. A configuração do runtime de teste fornece `runner_dba` apontando para essa base, as contas fictícias 21 e 22 e `request.gorunnersTestFixture=true`. O teste executa a compra dentro de uma transação revertida ao final.

## Publicação de 22/11/2026

Oito arquivos de runtime publicados em `business.roadrunners.run`. A compilação no Adobe ColdFusion cobriu sete templates/componentes e os oito hashes coincidiram com a versão local após o deploy. Backup e manifesto em `/var/backups/gorunners-zones-20261122-8uopcf20` no servidor do Business. Com o piloto desativado, a página redirecionou o visitante anônimo para o login, o JavaScript do mapa retornou HTTP 200 e o webhook recusou o POST com HTTP 503.

A tabela ainda estava ausente na consulta de produção após a tentativa pelo datasource, que bloqueia DDL. O operador ficou responsável por executar o SQL no schema `public`. A liberação das contas depende da verificação dessa migração e das credenciais de teste dos dois provedores.

A validação local cobriu doze cenários com CFML, PostgreSQL e respostas simuladas, além da assinatura de webhook, configuração sandbox e desenho do mapa em duas larguras (390 e 1280 px). A regressão dos serviços de pagamento de Ads passou. O teste estático antigo do painel de pagamentos ainda aponta a mesma divergência no padrão de acesso administrativo na versão anterior à entrega.

A atualização do menu lateral e da aba global foi publicada no mesmo dia. Os cinco templates passaram na compilação do Adobe ColdFusion. O backup está em `/var/backups/gorunners-menu-m7uzfwsd`. A navegação e as permissões passaram por 23 cenários locais. Em produção, o clique em **GoRunners** no menu lateral de uma conta abriu **Zonas patrocinadas GoRunners** com o status **Vendas em preparação**.
