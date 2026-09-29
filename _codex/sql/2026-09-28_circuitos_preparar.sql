SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
LOCK TABLE tb_agrega_eventos,tb_agregadores,tb_agregadores_eventos,tb_evento_corridas IN SHARE ROW EXCLUSIVE MODE;
ALTER TABLE tb_agregadores ADD COLUMN IF NOT EXISTS id_agrega_evento_legado integer UNIQUE REFERENCES tb_agrega_eventos(id_agrega_evento);
COMMENT ON COLUMN tb_agregadores.id_agrega_evento_legado IS 'Compatibilidade de URLs e cupons após migração dos circuitos; não representa vínculo de edição.';
CREATE TEMP TABLE circuito_mapa (id integer PRIMARY KEY,tag text UNIQUE) ON COMMIT DROP;
INSERT INTO circuito_mapa VALUES
(1,'circuito-unimed-sc'),
(2,'live-run-xp'),
(3,'estacoes'),
(4,'sesc'),
(5,'banco-do-brasil'),
(6,'angeloni'),
(7,'corrida-do-sesi'),
(44,'trackfield-run-series'),
(45,'world-marathon-majors'),
(47,'bota-pra-correr'),
(79,'caasc'),
(80,'trackfield-experience'),
(81,'fca-trailrun'),
(82,'fca-corridaderua'),
(83,'brasil-gigante'),
(101,'circuito-de-corridas-pague-menos'),
(114,'uprise-brasil-challenge'),
(145,'circuito-capixaba-de-montanhas'),
(169,'circuito-anapolino-de-corrida-de-rua'),
(170,'circuito-anapolino'),
(176,'circuito-de-corridas-tv-atalaia'),
(193,'circuito-de-corridas-caixa'),
(202,'circuito-cervejeiro-de-corrida'),
(242,'circuito-de-corridas-das-industria'),
(251,'runforlife-airport'),
(252,'circuito-corridas-de-rua-de-bage'),
(257,'circuito-dos-vales'),
(279,'avenida-fest-run'),
(289,'circuito-de-rusticas-arroio-grande'),
(352,'trun'),
(353,'correndo-por-uma-causa'),
(373,'circuito-oab-pa'),
(375,'circuito-4-elementos'),
(431,'circuito-de-corridas-jau-serve'),
(443,'trail'),
(465,'campeonato-mineiro-de-corrida-de-rua'),
(490,'faetec-em-movimento'),
(497,'asics-run-challenge'),
(503,'corrida-verde');
DO $$ BEGIN
 IF (SELECT count(*) FROM tb_agrega_eventos WHERE tipo_agregacao='circuito')<>39 OR EXISTS (SELECT 1 FROM tb_agrega_eventos a WHERE tipo_agregacao='circuito' AND NOT EXISTS(SELECT 1 FROM circuito_mapa m WHERE m.id=a.id_agrega_evento)) THEN RAISE EXCEPTION 'Inventário de circuitos mudou'; END IF;
 IF EXISTS (SELECT 1 FROM circuito_mapa m JOIN tb_agregadores a ON a.agregador_tag=m.tag WHERE a.id_agrega_evento_legado IS NOT NULL AND a.id_agrega_evento_legado<>m.id) THEN RAISE EXCEPTION 'Colisão de circuito de destino'; END IF;
END $$;
INSERT INTO tb_agregadores(agregador_nome,agregador_tag,agregador_descricao,id_tema,agregador_tipo,ordem,id_agrega_evento_legado)
 SELECT a.nome_evento_agregado,m.tag,a.nome_evento_agregado,a.id_tema,'circuito',a.ordem,a.id_agrega_evento
 FROM tb_agrega_eventos a JOIN circuito_mapa m ON m.id=a.id_agrega_evento
 WHERE NOT EXISTS (SELECT 1 FROM tb_agregadores g WHERE g.agregador_tag=m.tag);
UPDATE tb_agregadores g SET id_agrega_evento_legado=m.id,agregador_tipo='circuito',id_tema=a.id_tema
 FROM circuito_mapa m JOIN tb_agrega_eventos a ON a.id_agrega_evento=m.id WHERE g.agregador_tag=m.tag;
INSERT INTO tb_agregadores_eventos(agregador_tag,id_evento)
 SELECT m.tag,e.id_evento FROM tb_evento_corridas e JOIN circuito_mapa m ON m.id=e.id_agrega_evento
 WHERE NOT EXISTS (SELECT 1 FROM tb_agregadores_eventos ge WHERE ge.agregador_tag=m.tag AND ge.id_evento=e.id_evento);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM tb_evento_corridas e JOIN circuito_mapa m ON m.id=e.id_agrega_evento WHERE NOT EXISTS(SELECT 1 FROM tb_agregadores_eventos ge WHERE ge.id_evento=e.id_evento AND ge.agregador_tag=m.tag)) THEN RAISE EXCEPTION 'Vínculo de circuito não preservado'; END IF;
END $$;
