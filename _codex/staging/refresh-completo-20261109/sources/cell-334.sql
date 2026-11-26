-- Referência externa verificada na NYRR em03/10/2026, não uma consulta à base brasileira.
-- https://www.nyrr.org/tcsnycmarathon (consultada em testcache.nyrr.org/tcsnycmarathon)
-- https://www.nyrr.org/media-center/press-release/2026_0304_tcsnycmdrawingday
-- Homepage informa59.226 concluintes2025 e data01/11/2026; release04/03/2026 confirma ambos.
-- Rodar esta célula registra a referência verificada; não busca atualizações no site.
--2026 ainda não realizada no corte26/09 ou nesta verificação03/10: valorNULL, nuncazero.
SELECT jsonb_build_object('verificado_em','2026-10-03','registrado_em',current_timestamp,
 'fonte','New York Road Runners (NYRR)','url','https://www.nyrr.org/tcsnycmarathon',
 'url_consultada','https://testcache.nyrr.org/tcsnycmarathon',
 'confirmacao','https://www.nyrr.org/media-center/press-release/2026_0304_tcsnycmdrawingday',
 'linhas',jsonb_build_array(
 jsonb_build_object('ano',2025,'data_prova','2025-11-02','valor','59226','situacao','realizada','nota','Concluintes da edição2025 informados pela organizadora. Referência externa; não usa a população ou os filtros das dez maratonas brasileiras.'),
 jsonb_build_object('ano',2026,'data_prova','2026-11-01','valor',NULL,'situacao','ainda_nao_realizada','nota','Prova prevista para 01/11/2026; ainda não realizada no corte26/09 e na verificação03/10/2026. Concluintes ausentes, não zero; não copiar2025.'))) AS payload
