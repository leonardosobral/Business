-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.
-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.
-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.
-- ENTRADA OPERACIONAL CANDIDATA: carga aditiva + dois adaptadores do estudo.
-- Nenhum objeto public/produto/publicação é alterado. Uma transação; qualquer erro exige ROLLBACK.
-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.
-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.
-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.
-- CANDIDATO DATAGRIP. NÃO EXECUTADO. Executar o arquivo inteiro como uma transação.
-- Não usa DROP/TRUNCATE/CASCADE nem escreve em public. Não troca as views vigentes.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path=pg_catalog,public;
SET LOCAL standard_conforming_strings=on;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='15min';
DO $guard$
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION 'A sessão não está em REPEATABLE READ; encerre a transação anterior'; END IF;
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Outra carga Q3 está em curso'; END IF;
 IF to_regclass('estudo.fat_perfil_br_2026_20261109') IS NOT NULL OR to_regclass('estudo.fat_perfil_br_2026_20261109_audit') IS NOT NULL
 OR to_regclass('estudo.vwbi_perfil_br_2026_20261109') IS NOT NULL OR to_regclass('estudo.vw_resultados_2026_20261109') IS NOT NULL THEN RAISE EXCEPTION 'Versão candidata já existe; não sobrescrever'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('public.get_id_categoria_cbat(int4range)','aa6fe20f75af7d049cc0cb1bb49fbfc5'),('public.get_id_dim_faixa(numeric,time without time zone)','547a306bfba2b1bd9fe072b76869608d'),('public.get_id_geracao(int4range,integer)','4ceab31871e33e5eb841c16d6e37cd82'),('public.get_id_geracao(int4range,integer,date,date)','221972b658c5e11554e75a9b361da415')) f(signature,expected) WHERE to_regprocedure(signature) IS NULL OR md5(pg_get_functiondef(to_regprocedure(signature))) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'Função mudou ou assinatura ausente; releia antes da carga'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','19b2d5dfdaec0ff8eaeea4bdf5c57cdb'),('estudo.vw_resultados_2026','51d27f43da989bb1f50bdc414f54192e'),('public.vwbi_fat_perfil_br_2026','fddd821daa89826c4284eb5a81b954d0'),('estudo.vw_resultados_comparativo_2025_2026','5d6c7b6d81cbbe774e0963e6e8ab65fb')) v(name,expected) WHERE to_regclass(name) IS NULL OR md5(pg_get_viewdef(to_regclass(name),true)) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'View vigente mudou; releia antes de prosseguir'; END IF;
 IF EXISTS(SELECT 1 FROM (SELECT 'tbbi_dim_data' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_data FROM public.tbbi_dim_data WHERE id_data IS NOT NULL GROUP BY id_data HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_localidade' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_localidade FROM public.tbbi_dim_localidade WHERE id_localidade IS NOT NULL GROUP BY id_localidade HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_geracoes' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_geracao FROM public.tbbi_dim_geracoes WHERE id_geracao IS NOT NULL GROUP BY id_geracao HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_faixas' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_faixa FROM public.tbbi_dim_faixas WHERE id_faixa IS NOT NULL GROUP BY id_faixa HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_cbat_categorias' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_cbat_categoria FROM public.tbbi_dim_cbat_categorias WHERE id_cbat_categoria IS NOT NULL GROUP BY id_cbat_categoria HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_organizacao_2026' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_organizacao FROM public.tbbi_dim_organizacao_2026 WHERE id_organizacao IS NOT NULL GROUP BY id_organizacao HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_cronometragem' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_cronometragem FROM public.tbbi_dim_cronometragem WHERE id_cronometragem IS NOT NULL GROUP BY id_cronometragem HAVING count(*)>1)d
 ) d WHERE duplicate_keys>0) THEN RAISE EXCEPTION 'IDs duplicados nas dimensões; left join poderia multiplicar linhas'; END IF;
END;
$guard$;

-- A primeira leitura das tabelas analíticas abaixo e todos os nove meses usam
-- o mesmo snapshot da transação. Flags, sexo/percurso/tempo NULL são conservados.
CREATE TEMP TABLE _bqc_q3_source ON COMMIT DROP AS
SELECT r.id_resultado,r.id_evento,r.percurso,r.sexo,r.tempo_total,
 r.idade_range,r.data_nascimento,r.id_usuario,r.pcd,
 r.homologado AS resultado_homologado,r.concluinte,r.status_final,r.modalidade,
 e.data_final,e.data_inicial,e.estado,e.cidade,e.organizador,
 e.homologado AS evento_homologado,e.tipo_corrida
FROM public.tb_resultados r
JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR'
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE;
DO $source_check$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM _bqc_q3_source) THEN RAISE EXCEPTION 'Fonte vazia'; END IF;
 IF EXISTS(SELECT 1 FROM _bqc_q3_source WHERE id_resultado IS NULL) OR
 (SELECT count(*) FROM _bqc_q3_source)<>(SELECT count(DISTINCT id_resultado) FROM _bqc_q3_source) THEN RAISE EXCEPTION 'Resultado sem ID ou duplicado na fonte'; END IF;
 IF EXISTS(SELECT 1 FROM _bqc_q3_source WHERE length(sexo)>1) THEN RAISE EXCEPTION 'Sexo excede varchar(1); não truncar nem substituir silenciosamente'; END IF;
 IF EXISTS(SELECT 1 FROM public.tbbi_dim_data d JOIN (SELECT DISTINCT data_inicial FROM _bqc_q3_source WHERE data_inicial IS NOT NULL) f ON f.data_inicial=d.data_referencia GROUP BY d.data_referencia HAVING count(*)>1) THEN RAISE EXCEPTION 'Dimensão de data ambígua; revisar em vez de multiplicar'; END IF;
END;
$source_check$;
CREATE TEMP TABLE _bqc_q3_normalized ON COMMIT DROP AS
WITH fonte AS (SELECT * FROM _bqc_q3_source),
lookup_data AS (
 SELECT data_referencia,min(id_data) AS id_data FROM public.tbbi_dim_data GROUP BY data_referencia
), lookup_local AS (
 SELECT upper(estado) AS estado,upper(nome_cidade) AS cidade,min(id_localidade) AS id_localidade
 FROM public.tbbi_dim_localidade GROUP BY upper(estado),upper(nome_cidade)
), lookup_org AS (
 SELECT nome_original,min(id_organizacao) AS id_organizacao
 FROM public.tbbi_dim_organizacao_2026 GROUP BY nome_original
), lookup_crono AS (
 SELECT id_evento,min(id_fornecedor) AS id_cronometrador
 FROM public.tb_evento_corridas_fornecedores WHERE id_fornecedor_tipo=2 GROUP BY id_evento
), lookup_strava AS (
 SELECT id,min(strava_id) AS id_atleta_strava FROM public.tb_usuarios WHERE id<>0 GROUP BY id
)
SELECT row_number() OVER(ORDER BY r.id_resultado)::integer AS id_fat_perfil_br_2026,
 dd.id_data,
 coalesce(dl.id_localidade,0) AS id_localidade,
 r.id_evento,
 coalesce(org.id_organizacao,0) AS id_organizador,
 coalesce(cr.id_cronometrador,0) AS id_cronometrador,
 r.id_resultado,
 public.get_id_geracao(r.idade_range,extract(year FROM r.data_final)::integer,
                      r.data_nascimento,r.data_final) AS id_geracao,
 public.get_id_categoria_cbat(r.idade_range) AS id_cbat_categoria,
 public.get_id_dim_faixa(r.percurso,r.tempo_total) AS id_faixa,
 r.data_final AS data_evento,r.percurso,r.sexo,r.tempo_total,r.idade_range,r.id_usuario,
 st.id_atleta_strava,r.pcd,r.evento_homologado,r.resultado_homologado
FROM fonte r
LEFT JOIN lookup_data dd ON dd.data_referencia=r.data_inicial
LEFT JOIN lookup_local dl ON dl.estado=upper(r.estado) AND dl.cidade=upper(r.cidade)
LEFT JOIN lookup_org org ON org.nome_original=r.organizador
LEFT JOIN lookup_crono cr ON cr.id_evento=r.id_evento
LEFT JOIN lookup_strava st ON st.id=r.id_usuario AND r.id_usuario<>0;
CREATE UNIQUE INDEX _bqc_q3_normalized_result_idx ON _bqc_q3_normalized(id_resultado);

CREATE TABLE estudo.fat_perfil_br_2026_20261109 (
 id_fat_perfil_br_2026 integer PRIMARY KEY,
 id_data integer,
 id_localidade integer,
 id_evento integer,
 id_organizador integer,
 id_cronometrador integer,
 id_resultado integer,
 id_geracao integer,
 id_cbat_categoria integer,
 id_faixa integer,
 data_evento date,
 percurso numeric,
 sexo varchar(1),
 tempo_total time without time zone,
 idade_range int4range,
 id_usuario integer,
 id_atleta_strava integer,
 pcd boolean,
 evento_homologado boolean,
 resultado_homologado boolean
);
CREATE TABLE estudo.fat_perfil_br_2026_20261109_audit (
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 loaded_at timestamptz NOT NULL,snapshot_id text NOT NULL,source_script_sha256 text NOT NULL,
 function_contract jsonb NOT NULL,views_before jsonb NOT NULL,
 monthly_rows jsonb NOT NULL,quality jsonb NOT NULL,status text NOT NULL,
 activated_at timestamptz,activated_views jsonb
);

DO $months$
DECLARE v_month date; v_rows bigint; v_monthly jsonb='[]'::jsonb;
BEGIN
 FOR v_month IN SELECT generate_series(DATE '2026-01-01',DATE '2026-09-01',INTERVAL '1 month')::date LOOP
  INSERT INTO estudo.fat_perfil_br_2026_20261109(id_fat_perfil_br_2026,id_data,id_localidade,id_evento,id_organizador,id_cronometrador,id_resultado,id_geracao,id_cbat_categoria,id_faixa,data_evento,percurso,sexo,tempo_total,idade_range,id_usuario,id_atleta_strava,pcd,evento_homologado,resultado_homologado
  ) SELECT id_fat_perfil_br_2026,id_data,id_localidade,id_evento,id_organizador,id_cronometrador,id_resultado,id_geracao,id_cbat_categoria,id_faixa,data_evento,percurso,sexo,tempo_total,idade_range,id_usuario,id_atleta_strava,pcd,evento_homologado,resultado_homologado FROM _bqc_q3_normalized
  WHERE data_evento>=v_month AND data_evento<(v_month+INTERVAL '1 month')::date;
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  v_monthly=v_monthly||jsonb_build_array(jsonb_build_object('month',v_month,'rows',v_rows));
 END LOOP;
 INSERT INTO estudo.fat_perfil_br_2026_20261109_audit(loaded_at,snapshot_id,source_script_sha256,function_contract,views_before,monthly_rows,quality,status)
 VALUES(clock_timestamp(),txid_current_snapshot()::text,
 'd9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08',
 '{"get_id_categoria_cbat(int4range)": "aa6fe20f75af7d049cc0cb1bb49fbfc5", "get_id_dim_faixa(numeric,time without time zone)": "547a306bfba2b1bd9fe072b76869608d", "get_id_geracao(int4range,integer)": "4ceab31871e33e5eb841c16d6e37cd82", "get_id_geracao(int4range,integer,date,date)": "221972b658c5e11554e75a9b361da415"}'::jsonb,'{"estudo.vwbi_perfil_br_2026": " SELECT tbbi_fat_perfil_br_2026.id_fat_perfil_br_2026,\n    tbbi_fat_perfil_br_2026.id_evento,\n    tbbi_fat_perfil_br_2026.id_resultado,\n    tbbi_fat_perfil_br_2026.data_evento,\n    tbbi_fat_perfil_br_2026.percurso,\n    tbbi_fat_perfil_br_2026.sexo,\n    tbbi_fat_perfil_br_2026.tempo_total,\n    EXTRACT(epoch FROM tbbi_fat_perfil_br_2026.tempo_total)::integer AS tempo_total_segundos,\n    tbbi_fat_perfil_br_2026.idade_range,\n    tbbi_fat_perfil_br_2026.id_usuario,\n    tbbi_fat_perfil_br_2026.id_atleta_strava,\n    tbbi_fat_perfil_br_2026.pcd,\n    tbbi_fat_perfil_br_2026.evento_homologado,\n    tbbi_fat_perfil_br_2026.resultado_homologado,\n    dd.id_data,\n    dd.data_referencia,\n    dd.ano,\n    dd.mes,\n    dd.mes_extenso,\n    dd.dia,\n    dd.dia_do_ano,\n    dd.dia_da_semana,\n    dd.semana_calendario,\n    dd.data_formatada,\n    dd.trimestre,\n    dd.trimestre_ano,\n    dd.mes_ano,\n    dd.ano_semana_calendario,\n    dd.tipo_dia_semana,\n    dd.feriado_nacional,\n    dd.calendario_inicio_semana,\n    dd.calendario_final_semana,\n    tbbi_fat_perfil_br_2026.id_localidade,\n    dl.nome_pais,\n    dl.regiao,\n    dl.estado,\n    dl.nome_estado,\n    dl.nome_cidade,\n    dl.capital,\n    dl.id_paises_iso3166,\n    dg.id_geracao,\n    dg.nome_geracao,\n    df.id_faixa,\n    df.nome_faixa,\n    dfc.id_cbat_categoria,\n    dfc.nome_cbat_categoria,\n    ni.id_organizacao,\n    ni.agrupamento,\n    ni.nome_padrao,\n    ni.nome_original,\n    dc.id_cronometragem,\n    dc.nome_cronometragem\n   FROM tbbi_fat_perfil_br_2026\n     LEFT JOIN tbbi_dim_data dd ON dd.id_data = tbbi_fat_perfil_br_2026.id_data\n     LEFT JOIN tbbi_dim_localidade dl ON dl.id_localidade = tbbi_fat_perfil_br_2026.id_localidade\n     LEFT JOIN tbbi_dim_geracoes dg ON dg.id_geracao = tbbi_fat_perfil_br_2026.id_geracao\n     LEFT JOIN tbbi_dim_faixas df ON df.id_faixa = tbbi_fat_perfil_br_2026.id_faixa\n     LEFT JOIN tbbi_dim_cbat_categorias dfc ON dfc.id_cbat_categoria = tbbi_fat_perfil_br_2026.id_cbat_categoria\n     LEFT JOIN tbbi_dim_organizacao_2026 ni ON ni.id_organizacao = tbbi_fat_perfil_br_2026.id_organizador\n     LEFT JOIN tbbi_dim_cronometragem dc ON dc.id_cronometragem = tbbi_fat_perfil_br_2026.id_cronometrador;", "estudo.vw_resultados_2026": " SELECT v.id_resultado,\n    r.num_peito,\n    r.nome,\n    r.data_nascimento,\n    v.id_evento,\n    r.modalidade,\n    r.pace,\n    v.percurso,\n    v.sexo::character varying AS sexo,\n    r.tempo_bruto,\n    v.tempo_total,\n    r.classificacao_categoria,\n    r.classificacao_sexo,\n    r.classificacao_total,\n    r.velocidade_media,\n    r.equipe,\n    r.nome_categoria,\n    v.id_usuario,\n    r.id_categoria,\n    v.resultado_homologado AS homologado,\n    r.concluinte,\n    r.chave_processamento,\n    r.chave_verificacao,\n    r.nacionalidade,\n    r.status_final,\n    r.hora_largada,\n    r.tempo_f1_categoria,\n    r.tempo_f1_sexo,\n    r.tempo_f1_total,\n    r.posicao_ranking,\n    r.classificacao_pais,\n    v.pcd,\n    r.nome_full_text,\n    v.idade_range,\n    r.nome_normalizado,\n    r.origem_resultado\n   FROM estudo.vwbi_perfil_br_2026 v\n     LEFT JOIN tb_resultados r ON r.id_resultado = v.id_resultado\n  WHERE v.data_evento >= ''2026-01-01''::date AND v.data_evento < ''2026-10-01''::date;", "public.vwbi_fat_perfil_br_2026": " SELECT tbbi_fat_perfil_br_2026.id_fat_perfil_br_2026,\n    tbbi_fat_perfil_br_2026.id_evento,\n    tbbi_fat_perfil_br_2026.id_resultado,\n    tbbi_fat_perfil_br_2026.data_evento,\n    tbbi_fat_perfil_br_2026.percurso,\n    tbbi_fat_perfil_br_2026.sexo,\n    tbbi_fat_perfil_br_2026.tempo_total,\n    EXTRACT(epoch FROM tbbi_fat_perfil_br_2026.tempo_total)::integer AS tempo_total_segundos,\n    tbbi_fat_perfil_br_2026.idade_range,\n    tbbi_fat_perfil_br_2026.id_usuario,\n    tbbi_fat_perfil_br_2026.id_atleta_strava,\n    tbbi_fat_perfil_br_2026.pcd,\n    tbbi_fat_perfil_br_2026.evento_homologado,\n    tbbi_fat_perfil_br_2026.resultado_homologado,\n    dd.id_data,\n    dd.data_referencia,\n    dd.ano,\n    dd.mes,\n    dd.mes_extenso,\n    dd.dia,\n    dd.dia_do_ano,\n    dd.dia_da_semana,\n    dd.semana_calendario,\n    dd.data_formatada,\n    dd.trimestre,\n    dd.trimestre_ano,\n    dd.mes_ano,\n    dd.ano_semana_calendario,\n    dd.tipo_dia_semana,\n    dd.feriado_nacional,\n    dd.calendario_inicio_semana,\n    dd.calendario_final_semana,\n    dl.id_localidade,\n    dl.nome_pais,\n    dl.regiao,\n    dl.estado,\n    dl.nome_estado,\n    dl.nome_cidade,\n    dl.capital,\n    dl.id_paises_iso3166,\n    dg.id_geracao,\n    dg.nome_geracao,\n    df.id_faixa,\n    df.nome_faixa,\n    dfc.id_cbat_categoria,\n    dfc.nome_cbat_categoria,\n    ni.id_organizacao,\n    ni.agrupamento,\n    ni.nome_padrao,\n    ni.nome_original,\n    dc.id_cronometragem,\n    dc.nome_cronometragem\n   FROM tbbi_fat_perfil_br_2026\n     JOIN tbbi_dim_data dd ON dd.id_data = tbbi_fat_perfil_br_2026.id_data\n     JOIN tbbi_dim_localidade dl ON dl.id_localidade = tbbi_fat_perfil_br_2026.id_localidade\n     JOIN tbbi_dim_geracoes dg ON dg.id_geracao = tbbi_fat_perfil_br_2026.id_geracao\n     JOIN tbbi_dim_faixas df ON df.id_faixa = tbbi_fat_perfil_br_2026.id_faixa\n     JOIN tbbi_dim_cbat_categorias dfc ON dfc.id_cbat_categoria = tbbi_fat_perfil_br_2026.id_cbat_categoria\n     JOIN tbbi_dim_organizacao_2026 ni ON ni.id_organizacao = tbbi_fat_perfil_br_2026.id_organizador\n     JOIN tbbi_dim_cronometragem dc ON dc.id_cronometragem = tbbi_fat_perfil_br_2026.id_cronometrador;", "estudo.vw_resultados_comparativo_2025_2026": " SELECT r.id_resultado,\n    r.num_peito,\n    r.nome,\n    r.data_nascimento,\n    r.id_evento,\n    r.modalidade,\n    r.pace,\n    r.percurso,\n    r.sexo,\n    r.tempo_bruto,\n    r.tempo_total,\n    r.classificacao_categoria,\n    r.classificacao_sexo,\n    r.classificacao_total,\n    r.velocidade_media,\n    r.equipe,\n    r.nome_categoria,\n    r.id_usuario,\n    r.id_categoria,\n    r.homologado,\n    r.concluinte,\n    r.chave_processamento,\n    r.chave_verificacao,\n    r.nacionalidade,\n    r.status_final,\n    r.hora_largada,\n    r.tempo_f1_categoria,\n    r.tempo_f1_sexo,\n    r.tempo_f1_total,\n    r.posicao_ranking,\n    r.classificacao_pais,\n    r.pcd,\n    r.nome_full_text,\n    r.idade_range,\n    r.nome_normalizado,\n    r.origem_resultado\n   FROM tb_resultados r\n     JOIN tb_evento_corridas e USING (id_evento)\n  WHERE e.pais::text = ''BR''::text AND e.data_final >= ''2025-01-01''::date AND e.data_final < ''2026-01-01''::date\nUNION ALL\n SELECT vw_resultados_2026.id_resultado,\n    vw_resultados_2026.num_peito,\n    vw_resultados_2026.nome,\n    vw_resultados_2026.data_nascimento,\n    vw_resultados_2026.id_evento,\n    vw_resultados_2026.modalidade,\n    vw_resultados_2026.pace,\n    vw_resultados_2026.percurso,\n    vw_resultados_2026.sexo,\n    vw_resultados_2026.tempo_bruto,\n    vw_resultados_2026.tempo_total,\n    vw_resultados_2026.classificacao_categoria,\n    vw_resultados_2026.classificacao_sexo,\n    vw_resultados_2026.classificacao_total,\n    vw_resultados_2026.velocidade_media,\n    vw_resultados_2026.equipe,\n    vw_resultados_2026.nome_categoria,\n    vw_resultados_2026.id_usuario,\n    vw_resultados_2026.id_categoria,\n    vw_resultados_2026.homologado,\n    vw_resultados_2026.concluinte,\n    vw_resultados_2026.chave_processamento,\n    vw_resultados_2026.chave_verificacao,\n    vw_resultados_2026.nacionalidade,\n    vw_resultados_2026.status_final,\n    vw_resultados_2026.hora_largada,\n    vw_resultados_2026.tempo_f1_categoria,\n    vw_resultados_2026.tempo_f1_sexo,\n    vw_resultados_2026.tempo_f1_total,\n    vw_resultados_2026.posicao_ranking,\n    vw_resultados_2026.classificacao_pais,\n    vw_resultados_2026.pcd,\n    vw_resultados_2026.nome_full_text,\n    vw_resultados_2026.idade_range,\n    vw_resultados_2026.nome_normalizado,\n    vw_resultados_2026.origem_resultado\n   FROM estudo.vw_resultados_2026;"}'::jsonb,v_monthly,'{}'::jsonb,'loading');
END;
$months$;
CREATE UNIQUE INDEX fat_perfil_br_2026_20261109_result_idx ON estudo.fat_perfil_br_2026_20261109(id_resultado);
CREATE INDEX fat_perfil_br_2026_20261109_event_idx ON estudo.fat_perfil_br_2026_20261109(id_evento);
CREATE INDEX fat_perfil_br_2026_20261109_date_idx ON estudo.fat_perfil_br_2026_20261109(data_evento);

CREATE VIEW estudo.vwbi_perfil_br_2026_20261109 AS
SELECT tbbi_fat_perfil_br_2026.id_fat_perfil_br_2026,
    tbbi_fat_perfil_br_2026.id_evento,
    tbbi_fat_perfil_br_2026.id_resultado,
    tbbi_fat_perfil_br_2026.data_evento,
    tbbi_fat_perfil_br_2026.percurso,
    tbbi_fat_perfil_br_2026.sexo,
    tbbi_fat_perfil_br_2026.tempo_total,
    EXTRACT(epoch FROM tbbi_fat_perfil_br_2026.tempo_total)::integer AS tempo_total_segundos,
    tbbi_fat_perfil_br_2026.idade_range,
    tbbi_fat_perfil_br_2026.id_usuario,
    tbbi_fat_perfil_br_2026.id_atleta_strava,
    tbbi_fat_perfil_br_2026.pcd,
    tbbi_fat_perfil_br_2026.evento_homologado,
    tbbi_fat_perfil_br_2026.resultado_homologado,
    dd.id_data,
    dd.data_referencia,
    dd.ano,
    dd.mes,
    dd.mes_extenso,
    dd.dia,
    dd.dia_do_ano,
    dd.dia_da_semana,
    dd.semana_calendario,
    dd.data_formatada,
    dd.trimestre,
    dd.trimestre_ano,
    dd.mes_ano,
    dd.ano_semana_calendario,
    dd.tipo_dia_semana,
    dd.feriado_nacional,
    dd.calendario_inicio_semana,
    dd.calendario_final_semana,
    tbbi_fat_perfil_br_2026.id_localidade,
    dl.nome_pais,
    dl.regiao,
    dl.estado,
    dl.nome_estado,
    dl.nome_cidade,
    dl.capital,
    dl.id_paises_iso3166,
    dg.id_geracao,
    dg.nome_geracao,
    df.id_faixa,
    df.nome_faixa,
    dfc.id_cbat_categoria,
    dfc.nome_cbat_categoria,
    ni.id_organizacao,
    ni.agrupamento,
    ni.nome_padrao,
    ni.nome_original,
    dc.id_cronometragem,
    dc.nome_cronometragem
   FROM estudo.fat_perfil_br_2026_20261109 AS tbbi_fat_perfil_br_2026
     LEFT JOIN public.tbbi_dim_data dd ON dd.id_data = tbbi_fat_perfil_br_2026.id_data
     LEFT JOIN public.tbbi_dim_localidade dl ON dl.id_localidade = tbbi_fat_perfil_br_2026.id_localidade
     LEFT JOIN public.tbbi_dim_geracoes dg ON dg.id_geracao = tbbi_fat_perfil_br_2026.id_geracao
     LEFT JOIN public.tbbi_dim_faixas df ON df.id_faixa = tbbi_fat_perfil_br_2026.id_faixa
     LEFT JOIN public.tbbi_dim_cbat_categorias dfc ON dfc.id_cbat_categoria = tbbi_fat_perfil_br_2026.id_cbat_categoria
     LEFT JOIN public.tbbi_dim_organizacao_2026 ni ON ni.id_organizacao = tbbi_fat_perfil_br_2026.id_organizador
     LEFT JOIN public.tbbi_dim_cronometragem dc ON dc.id_cronometragem = tbbi_fat_perfil_br_2026.id_cronometrador;

CREATE VIEW estudo.vw_resultados_2026_20261109 AS
SELECT v.id_resultado,
    r.num_peito,
    r.nome,
    r.data_nascimento,
    v.id_evento,
    r.modalidade,
    r.pace,
    v.percurso,
    v.sexo::character varying AS sexo,
    r.tempo_bruto,
    v.tempo_total,
    r.classificacao_categoria,
    r.classificacao_sexo,
    r.classificacao_total,
    r.velocidade_media,
    r.equipe,
    r.nome_categoria,
    v.id_usuario,
    r.id_categoria,
    v.resultado_homologado AS homologado,
    r.concluinte,
    r.chave_processamento,
    r.chave_verificacao,
    r.nacionalidade,
    r.status_final,
    r.hora_largada,
    r.tempo_f1_categoria,
    r.tempo_f1_sexo,
    r.tempo_f1_total,
    r.posicao_ranking,
    r.classificacao_pais,
    v.pcd,
    r.nome_full_text,
    v.idade_range,
    r.nome_normalizado,
    r.origem_resultado
   FROM estudo.vwbi_perfil_br_2026_20261109 v
     LEFT JOIN public.tb_resultados r ON r.id_resultado = v.id_resultado
  WHERE v.data_evento >= '2026-01-01'::date AND v.data_evento < '2026-10-01'::date;

DO $validate$
BEGIN
 IF EXISTS (
 SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','estudo.vwbi_perfil_br_2026_20261109'),('estudo.vw_resultados_2026','estudo.vw_resultados_2026_20261109')) p(old_name,new_name)
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.old_name) AND attnum>0 AND NOT attisdropped) old
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.new_name) AND attnum>0 AND NOT attisdropped) new
 WHERE old.signature IS DISTINCT FROM new.signature
) THEN RAISE EXCEPTION 'Contrato de colunas/tipos/ordem da view mudou'; END IF;
 IF EXISTS (
 WITH expected AS (
  SELECT month::date AS month,count(s.id_resultado) AS n
  FROM generate_series(DATE '2026-01-01',DATE '2026-09-01',INTERVAL '1 month') AS g(month)
  LEFT JOIN _bqc_q3_source s ON s.data_final>=month AND s.data_final<month+INTERVAL '1 month' GROUP BY month
 ), actual AS (
  SELECT (v->>'month')::date AS month,(v->>'rows')::bigint AS n
  FROM estudo.fat_perfil_br_2026_20261109_audit,jsonb_array_elements(monthly_rows) v
 ) SELECT 1 FROM expected e FULL JOIN actual a USING(month) WHERE e.n IS DISTINCT FROM a.n
) OR (SELECT jsonb_array_length(monthly_rows) FROM estudo.fat_perfil_br_2026_20261109_audit)<>9 THEN RAISE EXCEPTION 'Conservação mensal dos nove meses falhou'; END IF;
 IF (SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109)<>(SELECT count(*) FROM _bqc_q3_source) THEN RAISE EXCEPTION 'Conservação de linhas falhou'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.fat_perfil_br_2026_20261109 f FULL JOIN _bqc_q3_normalized n USING(id_resultado) WHERE ROW(f.id_fat_perfil_br_2026,f.id_data,f.id_localidade,f.id_evento,f.id_organizador,f.id_cronometrador,f.id_resultado,f.id_geracao,f.id_cbat_categoria,f.id_faixa,f.data_evento,f.percurso,f.sexo,f.tempo_total,f.idade_range,f.id_usuario,f.id_atleta_strava,f.pcd,f.evento_homologado,f.resultado_homologado) IS DISTINCT FROM ROW(n.id_fat_perfil_br_2026,n.id_data,n.id_localidade,n.id_evento,n.id_organizador,n.id_cronometrador,n.id_resultado,n.id_geracao,n.id_cbat_categoria,n.id_faixa,n.data_evento,n.percurso,n.sexo,n.tempo_total,n.idade_range,n.id_usuario,n.id_atleta_strava,n.pcd,n.evento_homologado,n.resultado_homologado)) THEN RAISE EXCEPTION 'Conservação de valores/flags/NULL falhou'; END IF;
 IF (SELECT count(*) FROM estudo.vwbi_perfil_br_2026_20261109)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) OR (SELECT count(DISTINCT id_resultado) FROM estudo.vwbi_perfil_br_2026_20261109)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) THEN RAISE EXCEPTION 'Fanout/perda no adaptador BI'; END IF;
 IF (SELECT count(*) FROM estudo.vw_resultados_2026_20261109)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) OR (SELECT count(DISTINCT id_resultado) FROM estudo.vw_resultados_2026_20261109)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) THEN RAISE EXCEPTION 'Fanout/perda no adaptador de resultados'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('public.get_id_categoria_cbat(int4range)','aa6fe20f75af7d049cc0cb1bb49fbfc5'),('public.get_id_dim_faixa(numeric,time without time zone)','547a306bfba2b1bd9fe072b76869608d'),('public.get_id_geracao(int4range,integer)','4ceab31871e33e5eb841c16d6e37cd82'),('public.get_id_geracao(int4range,integer,date,date)','221972b658c5e11554e75a9b361da415')) f(signature,expected) WHERE to_regprocedure(signature) IS NULL OR md5(pg_get_functiondef(to_regprocedure(signature))) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'Função mudou ou assinatura ausente; releia antes da carga'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','19b2d5dfdaec0ff8eaeea4bdf5c57cdb'),('estudo.vw_resultados_2026','51d27f43da989bb1f50bdc414f54192e'),('public.vwbi_fat_perfil_br_2026','fddd821daa89826c4284eb5a81b954d0'),('estudo.vw_resultados_comparativo_2025_2026','5d6c7b6d81cbbe774e0963e6e8ab65fb')) v(name,expected) WHERE to_regclass(name) IS NULL OR md5(pg_get_viewdef(to_regclass(name),true)) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'View vigente mudou; releia antes de prosseguir'; END IF;
END;
$validate$;
UPDATE estudo.fat_perfil_br_2026_20261109_audit SET quality=jsonb_build_object('eligible',(SELECT count(*) FROM _bqc_q3_source),
 'fact',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109),'null_pcd',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE pcd IS NULL),
 'null_sex',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE sexo IS NULL),'null_distance',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE percurso IS NULL),
 'null_time',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE tempo_total IS NULL),'zero_time',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE tempo_total=TIME '00:00:00'),
 'null_event_homologated',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE evento_homologado IS NULL),
 'unresolved_locality',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE id_localidade=0),
 'missing_date_dimension',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE id_data IS NULL),
 'unresolved_organizer',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE id_organizador=0),
 'unresolved_timer',(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109 WHERE id_cronometrador=0)),status='ready_for_review';
GRANT SELECT ON estudo.fat_perfil_br_2026_20261109,estudo.fat_perfil_br_2026_20261109_audit,estudo.vwbi_perfil_br_2026_20261109,estudo.vw_resultados_2026_20261109 TO estudo_reader;
COMMENT ON TABLE estudo.fat_perfil_br_2026_20261109 IS 'Versão Q3 2026 de 09/11; fonte materializada em snapshot repeatable_read; público preservado; cutover separado.';
ANALYZE estudo.fat_perfil_br_2026_20261109;
SELECT to_jsonb(a) AS load_receipt FROM estudo.fat_perfil_br_2026_20261109_audit a;

-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.
-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.
-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.
-- CANDIDATO SEPARADO. Só após revisão e controle da carga10.
-- Troca exclusivamente os dois adaptadores do estudo; produto/publicações ficam fixados.

SET LOCAL search_path=pg_catalog,public;
SET LOCAL standard_conforming_strings=on;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='15min';
DO $guard$
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION 'A sessão não está em REPEATABLE READ; encerre a transação anterior'; END IF;
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Carga/cutover em curso'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('public.get_id_categoria_cbat(int4range)','aa6fe20f75af7d049cc0cb1bb49fbfc5'),('public.get_id_dim_faixa(numeric,time without time zone)','547a306bfba2b1bd9fe072b76869608d'),('public.get_id_geracao(int4range,integer)','4ceab31871e33e5eb841c16d6e37cd82'),('public.get_id_geracao(int4range,integer,date,date)','221972b658c5e11554e75a9b361da415')) f(signature,expected) WHERE to_regprocedure(signature) IS NULL OR md5(pg_get_functiondef(to_regprocedure(signature))) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'Função mudou ou assinatura ausente; releia antes da carga'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','19b2d5dfdaec0ff8eaeea4bdf5c57cdb'),('estudo.vw_resultados_2026','51d27f43da989bb1f50bdc414f54192e'),('public.vwbi_fat_perfil_br_2026','fddd821daa89826c4284eb5a81b954d0'),('estudo.vw_resultados_comparativo_2025_2026','5d6c7b6d81cbbe774e0963e6e8ab65fb')) v(name,expected) WHERE to_regclass(name) IS NULL OR md5(pg_get_viewdef(to_regclass(name),true)) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'View vigente mudou; releia antes de prosseguir'; END IF;
 IF EXISTS (
 SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','estudo.vwbi_perfil_br_2026_20261109'),('estudo.vw_resultados_2026','estudo.vw_resultados_2026_20261109')) p(old_name,new_name)
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.old_name) AND attnum>0 AND NOT attisdropped) old
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.new_name) AND attnum>0 AND NOT attisdropped) new
 WHERE old.signature IS DISTINCT FROM new.signature
) THEN RAISE EXCEPTION 'Contrato de colunas/tipos/ordem da view mudou'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.fat_perfil_br_2026_20261109_audit WHERE status='ready_for_review') THEN RAISE EXCEPTION 'Carga não está validada'; END IF;
 IF (SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109)<>(SELECT (quality->>'fact')::bigint FROM estudo.fat_perfil_br_2026_20261109_audit) THEN RAISE EXCEPTION 'Fato candidata mudou após validação'; END IF;
END;
$guard$;
CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS SELECT * FROM estudo.vwbi_perfil_br_2026_20261109;
CREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS SELECT * FROM estudo.vw_resultados_2026_20261109;
DO $verify$
BEGIN
 IF (SELECT count(*) FROM estudo.vw_resultados_2026)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) THEN RAISE EXCEPTION 'Conservação após cutover falhou'; END IF;
 IF md5(pg_get_viewdef('public.vwbi_fat_perfil_br_2026'::regclass,true))<>'fddd821daa89826c4284eb5a81b954d0' THEN RAISE EXCEPTION 'View pública mudou'; END IF;
END;
$verify$;
UPDATE estudo.fat_perfil_br_2026_20261109_audit SET status='activated',activated_at=clock_timestamp(),activated_views=jsonb_build_object('estudo.vwbi_perfil_br_2026',md5(pg_get_viewdef('estudo.vwbi_perfil_br_2026'::regclass,true)),'estudo.vw_resultados_2026',md5(pg_get_viewdef('estudo.vw_resultados_2026'::regclass,true)));
SELECT to_jsonb(a) AS cutover_receipt FROM estudo.fat_perfil_br_2026_20261109_audit a;
COMMIT;
