SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
LOCK TABLE tb_agrega_eventos,tb_agregadores,tb_agregadores_eventos,tb_evento_corridas IN SHARE ROW EXCLUSIVE MODE;
CREATE TEMP TABLE circuito_cupons_antes ON COMMIT DROP AS
 SELECT e.id_evento,c.id_cupom,c.cupom,c.data_validade_inicio,c.data_validade_fim FROM tb_evento_corridas e JOIN vw_evento_corridas_cupom c ON (c.tipo_evento=1 AND c.id_evento_agrega=e.id_evento) OR (c.tipo_evento=2 AND c.id_evento_agrega=e.id_agrega_evento);
CREATE TEMP TABLE circuito_vw_cupom_antes ON COMMIT DROP AS SELECT * FROM vw_cupom;
CREATE TEMP TABLE circuito_edicoes_antes ON COMMIT DROP AS SELECT id_evento,id_agrega_evento FROM tb_evento_corridas WHERE id_agrega_evento IS NOT NULL AND id_agrega_evento NOT IN(SELECT id_agrega_evento_legado FROM tb_agregadores WHERE id_agrega_evento_legado IS NOT NULL);
-- Catch registrations made between preparation and activation.
INSERT INTO tb_agregadores_eventos(agregador_tag,id_evento)
 SELECT g.agregador_tag,e.id_evento FROM tb_evento_corridas e JOIN tb_agregadores g ON g.id_agrega_evento_legado=e.id_agrega_evento
 WHERE NOT EXISTS(SELECT 1 FROM tb_agregadores_eventos ge WHERE ge.agregador_tag=g.agregador_tag AND ge.id_evento=e.id_evento);
DO $$ BEGIN
 IF (SELECT count(*) FROM tb_agregadores WHERE id_agrega_evento_legado IS NOT NULL)<>39 THEN RAISE EXCEPTION 'Preparação incompleta'; END IF;
END $$;
CREATE OR REPLACE VIEW vw_evento_corridas_cupom AS
 SELECT cc.id_evento_cupom,
    cc.id_cupom,
    1 AS tipo_evento,
    cc.id_evento AS id_evento_agrega,
    cc.qtd_limite_cupom,
    cc.data_cadastro AS data_cadastro_cupom_evento,
    cc.data_validade_inicio,
    cc.data_validade_fim,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao
   FROM (tb_evento_corridas_cupom cc
     JOIN tb_cupom cp ON ((cp.id_cupom = cc.id_cupom)))
UNION ALL
 SELECT cc.id_evento_cupom,
    cc.id_cupom,
    2 AS tipo_evento,
    cc.id_agrega_evento AS id_evento_agrega,
    cc.qtd_limite_cupom,
    cc.data_cadastro AS data_cadastro_cupom_evento,
    cc.data_validade_inicio,
    cc.data_validade_fim,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao
   FROM (tb_evento_circuitos_cupom cc
     JOIN tb_cupom cp ON ((cp.id_cupom = cc.id_cupom)))
 WHERE NOT EXISTS(SELECT 1 FROM tb_agregadores g WHERE g.id_agrega_evento_legado=cc.id_agrega_evento)
UNION ALL
 SELECT cc.id_evento_cupom,
    cc.id_cupom,
    1 AS tipo_evento,
    ge.id_evento AS id_evento_agrega,
    cc.qtd_limite_cupom,
    cc.data_cadastro AS data_cadastro_cupom_evento,
    cc.data_validade_inicio,
    cc.data_validade_fim,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao
   FROM (tb_evento_circuitos_cupom cc
     JOIN tb_cupom cp ON ((cp.id_cupom = cc.id_cupom)))
 JOIN tb_agregadores g ON g.id_agrega_evento_legado=cc.id_agrega_evento
 JOIN (SELECT DISTINCT agregador_tag,id_evento FROM tb_agregadores_eventos) ge ON ge.agregador_tag=g.agregador_tag;
CREATE OR REPLACE VIEW vw_cupom AS
 SELECT 'pagina'::text AS tipo_cupom,
    pg.id_pagina,
    pg.id_pagina AS id_tipo_cupom,
    tp.nome AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    cp.url AS curl,
    cp.ativo,
    NULL::integer AS id_evento,
    NULL::character varying AS url_inscricao
   FROM ((tb_cupom cp
     JOIN tb_paginas_cupom pg ON ((pg.id_cupom = cp.id_cupom)))
     JOIN tb_paginas tp ON ((tp.id_pagina = pg.id_pagina)))
  WHERE ((NOT (EXISTS ( SELECT ev.id_cupom
           FROM tb_evento_circuitos_cupom ev
          WHERE (ev.id_cupom = cp.id_cupom)))) AND (NOT (EXISTS ( SELECT cr.id_cupom
           FROM tb_evento_corridas_cupom cr
          WHERE (cr.id_cupom = cp.id_cupom)))))
UNION ALL
 SELECT 'evento'::text AS tipo_cupom,
    1 AS id_pagina,
    pg.id_evento AS id_tipo_cupom,
    tp.nome_evento AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    COALESCE(tp.url_inscricao, tp.url_hotsite) AS curl,
    cp.ativo,
    tp.id_evento,
    tp.url_inscricao
   FROM ((tb_cupom cp
     JOIN tb_evento_corridas_cupom pg ON ((pg.id_cupom = cp.id_cupom)))
     JOIN tb_evento_corridas tp ON (((tp.id_evento = pg.id_evento) AND (tp.data_inicial > CURRENT_DATE))))
UNION ALL
 SELECT 'circuito'::text AS tipo_cupom,
    1 AS id_pagina,
    pg.id_agrega_evento AS id_tipo_cupom,
    tp.nome_evento AS nome_tipo_cupom,
    cp.id_cupom,
    cp.cupom,
    cp.descricao,
    cp.parceiro,
    cp.condicoes,
    cp.data_cadastro,
    cp.data_expiracao,
    COALESCE(tp.url_inscricao, tp.url_hotsite) AS curl,
    cp.ativo,
    tp.id_evento,
    tp.url_inscricao
   FROM ((tb_cupom cp
     JOIN tb_evento_circuitos_cupom pg ON ((pg.id_cupom = cp.id_cupom)))
     JOIN tb_evento_corridas tp ON ((((tp.id_agrega_evento = pg.id_agrega_evento AND NOT EXISTS(SELECT 1 FROM tb_agregadores g WHERE g.id_agrega_evento_legado=pg.id_agrega_evento)) OR EXISTS(SELECT 1 FROM tb_agregadores g JOIN tb_agregadores_eventos ge USING(agregador_tag) WHERE g.id_agrega_evento_legado=pg.id_agrega_evento AND ge.id_evento=tp.id_evento)) AND (tp.data_inicial > CURRENT_DATE))));
UPDATE tb_evento_corridas e SET id_agrega_evento=NULL FROM tb_agregadores g WHERE g.id_agrega_evento_legado=e.id_agrega_evento;
CREATE OR REPLACE FUNCTION impedir_circuito_como_edicao() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.id_agrega_evento IS NOT NULL AND EXISTS(SELECT 1 FROM tb_agrega_eventos a WHERE a.id_agrega_evento=NEW.id_agrega_evento AND lower(trim(a.tipo_agregacao))='circuito') THEN
 RAISE EXCEPTION 'Circuitos devem ser vinculados em Agregadores e circuitos; este campo é reservado às edições da prova.';
 END IF; RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS circuito_fora_do_vinculo_edicao ON tb_evento_corridas;
CREATE TRIGGER circuito_fora_do_vinculo_edicao BEFORE INSERT OR UPDATE OF id_agrega_evento ON tb_evento_corridas FOR EACH ROW EXECUTE FUNCTION impedir_circuito_como_edicao();
DO $$ BEGIN
 IF EXISTS(SELECT * FROM circuito_edicoes_antes EXCEPT SELECT id_evento,id_agrega_evento FROM tb_evento_corridas) THEN RAISE EXCEPTION 'Vínculo de edição alterado indevidamente'; END IF;
 IF EXISTS(SELECT * FROM circuito_cupons_antes EXCEPT SELECT e.id_evento,c.id_cupom,c.cupom,c.data_validade_inicio,c.data_validade_fim FROM tb_evento_corridas e JOIN vw_evento_corridas_cupom c ON (c.tipo_evento=1 AND c.id_evento_agrega=e.id_evento) OR (c.tipo_evento=2 AND c.id_evento_agrega=e.id_agrega_evento)) THEN RAISE EXCEPTION 'Cobertura de cupom perdida'; END IF;
 IF EXISTS(SELECT * FROM circuito_vw_cupom_antes EXCEPT SELECT * FROM vw_cupom) THEN RAISE EXCEPTION 'Catálogo de cupom perdeu evento'; END IF;
 IF EXISTS(SELECT 1 FROM tb_evento_corridas e JOIN tb_agrega_eventos a USING(id_agrega_evento) WHERE tipo_agregacao='circuito') THEN RAISE EXCEPTION 'Circuito ainda ocupa vínculo de edição'; END IF;
END $$;
