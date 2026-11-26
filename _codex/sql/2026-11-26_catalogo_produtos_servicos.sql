-- Business | Catálogo de produtos e serviços RH
-- Executar o arquivo inteiro no DataGrip no banco runnerhub, como runner_dba.
-- Pode ser reaplicado. Edições posteriores e itens adicionais são preservados.
BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_business_produtos_servicos (
    codigo text PRIMARY KEY CHECK (codigo ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    grupo text NOT NULL CHECK (btrim(grupo) <> ''),
    ordem integer NOT NULL CHECK (ordem > 0),
    nome text NOT NULL CHECK (btrim(nome) <> ''),
    comprador text NOT NULL CHECK (btrim(comprador) <> ''),
    cobranca text NOT NULL CHECK (btrim(cobranca) <> ''),
    inicio text NOT NULL CHECK (btrim(inicio) <> ''),
    termino text NOT NULL CHECK (btrim(termino) <> ''),
    registro text NOT NULL CHECK (btrim(registro) <> ''),
    a_confirmar text
);

INSERT INTO public.tb_business_produtos_servicos
    (codigo, grupo, ordem, nome, comprador, cobranca, inicio, termino, registro, a_confirmar)
VALUES
    ('selo-verificado', 'Atletas e consumidores', 10, 'Selo Verificado', 'Atleta ou usuário do Road Runners.',
     'Pagamento único de R$ 9,90 por um ano na oferta de lançamento. Pix ou cartão em uma parcela, com renovação manual.',
     'Na confirmação do pagamento. Se o perfil já tem selo com prazo, o novo ano começa no fim da validade atual.',
     'Ao completar o ano adquirido. Concessões permanentes continuam sem vencimento.',
     'Pagar.me e Road Runners. rr_verified.orders guarda o pedido, rr_verified.payment_events registra os eventos e rr_verified.grants identifica o perfil, a origem e a validade.', NULL),

    ('assinatura', 'Atletas e consumidores', 20, 'Assinatura', 'Atleta do Road Runners.',
     'Mensal, conforme o modelo proposto.',
     'Na confirmação do primeiro pagamento, conforme a proposta.',
     'A proposta prevê 12 meses a partir do pagamento.',
     'Pagar.me é o meio previsto. A área Assinaturas do Business atende às empresas. O registro da assinatura individual do atleta está por identificar.',
     'Definir se existe compromisso anual cobrado em mensalidades ou se cada mensalidade renova o acesso por um mês.'),

    ('desafios', 'Atletas e consumidores', 30, 'Desafios', 'Atleta participante do desafio.',
     'Pagamento único pela inscrição anual. No Todo Santo Dia há anuidade Básica, VIP e compra avulsa de upgrade para VIP.',
     'Na confirmação do pagamento da inscrição ou do upgrade. O VIP e o upgrade dão direito ao selo inclusive quando há somente um upgrade pago.',
     'Conforme a edição. Para o selo do Todo Santo Dia, pagamentos até 31/12/2025 dão validade até 31/12/2026. A partir de 01/01/2026, vale um ano a partir do pagamento do VIP ou do upgrade.',
     'Pagar.me e Road Runners. public.desafios_produtos registra os produtos, public.desafios registra as inscrições e rr_verified.challenge_orders vincula o pagamento VIP ou upgrade ao perfil.', NULL),

    ('go-runners', 'Atletas e consumidores', 40, 'Go Runners', 'Atleta que adere a um plano do Go Runners.',
     'Mensalidade, com valor conforme o plano escolhido.',
     'Na confirmação do pagamento do plano comercial.',
     'Na data de vencimento registrada para aquele plano.',
     'App Go Runners. gorunners.subscriptions guarda plano, estado, vigência, valor e referência de pagamento. O checkout tem integração com a Pagar.me.',
     'A proposta cita 12 meses. Confirmar a quais planos esse prazo se aplica.'),

    ('comparador', 'Atletas e consumidores', 50, 'Comparador', 'Atleta ou consumidor que compra na loja parceira.',
     'Compra por produto. A RunnerHub recebe a comissão da venda atribuída ao parceiro.',
     'Na compra confirmada pela loja parceira.',
     'Ao concluir a compra. Uma nova compra gera uma nova operação.',
     'O Comparador mantém os produtos em comparador.tb_produto e encaminha o consumidor à loja. Há integração de afiliados com a Awin.',
     'Identificar a fonte de confirmação das vendas, comissões e estornos por parceiro.'),

    ('transmissao', 'Organizadores e parceiros', 60, 'Transmissão', 'Organizador da prova ou do evento.',
     'Por evento contratado.',
     'Na confirmação do pagamento.',
     'O prazo informado é de dois dias antes da transmissão ou prova.',
     'O Business registra o evento e a operação da transmissão no leaderboard. A Pagar.me foi indicada para o pagamento.',
     'Confirmar se os dois dias são o limite para contratar ou pagar e qual data encerra o serviço. Identificar o vínculo entre evento, contrato e cobrança.'),

    ('patrocinado', 'Organizadores e parceiros', 70, 'Patrocinado', 'Organizador que divulga evento ou banner.',
     'Recarga de créditos para campanhas de divulgação.',
     'Quando o crédito é lançado na conta do anunciante.',
     'Quando o saldo disponível se esgota. Uma nova recarga repõe o saldo.',
     'Business Ads e Pagar.me. ads.payment_intents e ads.payment_events registram a cobrança. ads.credit_ledger registra os créditos e débitos da conta.', NULL),

    ('estudo', 'Organizadores e parceiros', 80, 'Estudo', 'Organizadores, marcas, jornalistas e atletas.',
     'Pagamento único por estudo ou material digital.',
     'Na confirmação do pagamento da compra avulsa.',
     'A operação comercial termina na compra. O acesso ao material segue a licença da edição.',
     'Business Estudos. estudo.produtos identifica as edições, estudo.acessos registra as liberações e estudo.vouchers identifica os vouchers.',
     'Confirmar a fonte do pagamento da venda avulsa e a duração do acesso em cada licença.'),

    ('cupom', 'Organizadores e parceiros', 90, 'Cupom', 'Organizador que vende inscrições usando um cupom.',
     'Comissão por venda de inscrição atribuída ao cupom.',
     'Quando a plataforma de inscrição confirma o pagamento da venda com cupom.',
     'Na quitação da comissão devida à RunnerHub.',
     'O Business cadastra os cupons em public.tb_cupom e os associa às provas em public.tb_evento_corridas_cupom. A plataforma de inscrição registra a venda.',
     'Identificar o registro de apuração e quitação da comissão e confirmar o meio de repasse.')
ON CONFLICT (codigo) DO NOTHING;

COMMIT;

SELECT count(*) AS itens_no_catalogo,
       count(*) FILTER (WHERE grupo = 'Atletas e consumidores') AS atletas_e_consumidores,
       count(*) FILTER (WHERE grupo = 'Organizadores e parceiros') AS organizadores_e_parceiros
FROM public.tb_business_produtos_servicos;
