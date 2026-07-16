-- Execute isoladamente em instalações que já aplicaram user_management_schema.sql.
-- CONCURRENTLY evita bloquear gravações em tb_resultados_vinculo durante a criação.
CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_resultados_vinculo_usuario_ativo_idx
    ON tb_resultados_vinculo (id_usuario, id_resultado)
    WHERE vinculo_resultado = true;
