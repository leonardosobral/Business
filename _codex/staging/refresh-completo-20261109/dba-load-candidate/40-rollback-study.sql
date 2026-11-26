-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.
-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.
-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.
-- CANDIDATO DE RECUPERAÇÃO; conserva a fato versionada e todos os congelamentos.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path=pg_catalog,public;
SET LOCAL standard_conforming_strings=on;
SET LOCAL lock_timeout='2s';
DO $guard$
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION 'A sessão não está em REPEATABLE READ; encerre a transação anterior'; END IF;
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Carga/cutover em curso'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.fat_perfil_br_2026_20261109_audit WHERE status='activated' AND activated_views->>'estudo.vwbi_perfil_br_2026'=md5(pg_get_viewdef('estudo.vwbi_perfil_br_2026'::regclass,true)) AND activated_views->>'estudo.vw_resultados_2026'=md5(pg_get_viewdef('estudo.vw_resultados_2026'::regclass,true))) THEN RAISE EXCEPTION 'Adaptadores mudaram; recuperação requer nova revisão'; END IF;
END;
$guard$;
CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS
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
   FROM tbbi_fat_perfil_br_2026
     LEFT JOIN tbbi_dim_data dd ON dd.id_data = tbbi_fat_perfil_br_2026.id_data
     LEFT JOIN tbbi_dim_localidade dl ON dl.id_localidade = tbbi_fat_perfil_br_2026.id_localidade
     LEFT JOIN tbbi_dim_geracoes dg ON dg.id_geracao = tbbi_fat_perfil_br_2026.id_geracao
     LEFT JOIN tbbi_dim_faixas df ON df.id_faixa = tbbi_fat_perfil_br_2026.id_faixa
     LEFT JOIN tbbi_dim_cbat_categorias dfc ON dfc.id_cbat_categoria = tbbi_fat_perfil_br_2026.id_cbat_categoria
     LEFT JOIN tbbi_dim_organizacao_2026 ni ON ni.id_organizacao = tbbi_fat_perfil_br_2026.id_organizador
     LEFT JOIN tbbi_dim_cronometragem dc ON dc.id_cronometragem = tbbi_fat_perfil_br_2026.id_cronometrador;
CREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS
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
   FROM estudo.vwbi_perfil_br_2026 v
     LEFT JOIN tb_resultados r ON r.id_resultado = v.id_resultado
  WHERE v.data_evento >= '2026-01-01'::date AND v.data_evento < '2026-10-01'::date;
UPDATE estudo.fat_perfil_br_2026_20261109_audit SET status='restored_previous_adapters';
COMMIT;
