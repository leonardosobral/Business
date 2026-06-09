-- Grants complementares para o fluxo Business de contas, usuarios e eventos.
-- Necessario quando o datasource da aplicacao usa o usuario runner, nao o owner runner_dba.

GRANT SELECT, USAGE ON SEQUENCE tb_contas_id_conta_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_conta_usuarios_id_conta_usuario_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_conta_eventos_id_conta_evento_seq TO runner;
GRANT SELECT, USAGE ON SEQUENCE tb_conta_evento_solicitacoes_id_solicitacao_seq TO runner;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON tb_contas TO runner;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON tb_conta_usuarios TO runner;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON tb_conta_eventos TO runner;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON tb_conta_evento_solicitacoes TO runner;
