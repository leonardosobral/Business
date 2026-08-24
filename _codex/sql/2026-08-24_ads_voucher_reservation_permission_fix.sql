-- Corrige a execucao SECURITY DEFINER da reserva de voucher em conta pendente.
-- ads.reserve_voucher precisa ler e gravar o voucher escolhido na solicitacao.

BEGIN;

GRANT SELECT ON TABLE public.tb_contas TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_usuarios TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_eventos TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_evento_solicitacoes TO ads_owner;
GRANT SELECT ON TABLE public.tb_evento_corridas TO ads_owner;
GRANT SELECT ON TABLE public.tb_usuarios TO ads_owner;
GRANT SELECT, UPDATE ON TABLE public.tb_conta_cadastro_solicitacoes TO ads_owner;

COMMIT;
