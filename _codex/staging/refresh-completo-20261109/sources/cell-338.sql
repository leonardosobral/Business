WITH base AS (
 SELECT id_evento,nome_evento,valor_inscricao,precos FROM public.tb_evento_corridas
 WHERE ativo IS TRUE AND pais='BR' AND tipo_corrida='rua'
 AND (ranking IS NULL OR ranking<>'false')
 AND data_final>=DATE '2026-01-01' AND data_final<DATE '2027-01-01'
), opcoes AS (
 SELECT b.id_evento, t.value AS v, CASE WHEN jsonb_typeof(t.value->'valor')='number' THEN (t.value->>'valor')::numeric END valor,
 lower(concat_ws(' ',t.value->>'nome',t.value->>'categoria',t.value->>'modalidade',t.value->>'grupo',t.value->>'kit',t.value->>'lote')) rotulo
 FROM base b CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(b.precos)='array' THEN b.precos ELSE '[]'::jsonb END) AS t
), marcadas AS (
 SELECT id_evento,count(*) n, bool_or(rotulo ~ '(pcd|idoso|60[+] |60[+]|kids|infantil|50%|meia entrada|meia-entrada)') indicio_especial,
 bool_or(v ? 'lote') lote_identificado, bool_or(rotulo ~ '(chip|kit)') kit_ou_chip_no_rotulo
 FROM opcoes GROUP BY id_evento
)
SELECT jsonb_build_object(
 'coletado_em',current_timestamp,'base', (SELECT count(*) FROM base),
 'opcoes_capturadas',(SELECT count(*) FROM opcoes),
 'provas_com_opcoes',(SELECT count(*) FROM marcadas),
 'provas_com_rotulo_especial',(SELECT count(*) FROM marcadas WHERE indicio_especial),
 'provas_com_lote',(SELECT count(*) FROM marcadas WHERE lote_identificado),
 'provas_com_rotulo_kit_chip',(SELECT count(*) FROM marcadas WHERE kit_ou_chip_no_rotulo),
 'exemplos',(SELECT jsonb_agg(to_jsonb(x)) FROM (
   SELECT b.id_evento,b.nome_evento,b.valor_inscricao::text valor_inscricao,
   (SELECT jsonb_agg(o.v ORDER BY o.valor) FROM opcoes o WHERE o.id_evento=b.id_evento) precos
   FROM base b JOIN marcadas m USING(id_evento)
   WHERE m.indicio_especial AND b.valor_inscricao>0.01 AND b.valor_inscricao<=60
   ORDER BY b.valor_inscricao,b.id_evento LIMIT 4
 ) x),
 'nota','Rótulos são indícios de mistura, não classificação validada. Contagens de provas se sobrepõem. Lote identificado indica presença da chave, não histórico completo de vendas.'
)::text payload