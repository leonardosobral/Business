drop view if exists  vwbi_fat_perfil_br_2026;
drop table if exists tbbi_fat_perfil_br_2026;

create table tbbi_fat_perfil_br_2026
(
    id_fat_perfil_br_2026     serial,
    id_data              integer              not null,
    id_localidade        integer              not null,
    id_evento            integer              not null,
    id_organizador       integer              not null,
    id_cronometrador     integer              not null,
    id_resultado         integer              not null,
    id_geracao           integer              not null,
    id_cbat_categoria    integer              not null,
    id_faixa             integer              not null,
    data_evento          date                 not null,    
    percurso             numeric              not null,
    sexo                 varchar(1)           not null,
    tempo_total          time,
    idade_range          int4range,
    id_usuario           integer,
    id_atleta_strava     integer,
    pcd                  boolean default false,
    evento_homologado    boolean default true,
    resultado_homologado boolean default true
);

alter table tbbi_fat_perfil_br_2026
    owner to runner_dba;

grant insert, select, update on tbbi_fat_perfil_br_2026 to runner;

insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
) 
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select      
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-01-01'
                        AND evt.data_final <= '2026-01-31'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
) 
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select      
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-02-01'
                        AND evt.data_final <= '2026-02-28'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-03-01'
                        AND evt.data_final <= '2026-03-31'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;


insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-04-01'
                        AND evt.data_final <= '2026-04-30'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-05-01'
                        AND evt.data_final <= '2026-05-31'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-06-01'
                        AND evt.data_final <= '2026-06-30'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-07-01'
                        AND evt.data_final <= '2026-07-31'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-08-01'
                        AND evt.data_final <= '2026-08-31'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2026 (
    id_data,
    id_localidade,
    id_evento,
    id_organizador,
    id_cronometrador,
    id_resultado,
    id_geracao,
    id_faixa,
    id_cbat_categoria,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado
)
    ------------------------------------------------------------------
    -- 1. Base normalizada + validada
(          select
           id_data,
           coalesce((select min(id_localidade) from tbbi_dim_localidade loc where upper(loc.estado) = upper(evt.estado) and upper(loc.nome_cidade) = upper(evt.cidade)),0) AS id_localidade,
           evt.id_evento,
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2026 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
           coalesce((select min(id_fornecedor)  from tb_evento_corridas_fornecedores frn where frn.id_evento = evt.id_evento and frn.id_fornecedor_tipo = 2),0) AS id_cronometrador,
            id_resultado,
            get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao,
            get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
            get_id_categoria_cbat(idade_range) as id_cbat_categoria,
            evt.data_final AS data_evento,
            percurso,
            sexo,
            tempo_total,
            idade_range,
            id_usuario,
            ( select min(strava_id) from tb_usuarios usu where usu.id = res.id_usuario and id_usuario <> 0 ) as id_atleta_strava,
            res.pcd,
            evt.homologado as evento_homologado,
            res.homologado as resultado_homologado
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt   on evt.id_evento = res.id_evento
        INNER JOIN tbbi_dim_data dtt        on dtt.data_referencia = evt.data_inicial
        WHERE res.modalidade <> 'KIDS'
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= '2026-09-01'
                        AND evt.data_final <= '2026-09-30'
                        AND evt.pais = 'BR'
                        AND evt.tipo_corrida in ('rua', 'trail')
                        AND res.tempo_total is not null
);
commit;

create or replace view vwbi_fat_perfil_br_2026 as
    select 
    id_fat_perfil_br_2026,
    id_evento,
    id_resultado,
    data_evento,
    percurso,
    sexo,
    tempo_total,
    extract(EPOCH FROM tempo_total)::integer as tempo_total_segundos,
    idade_range,
    id_usuario,
    id_atleta_strava,
    pcd,
    evento_homologado,
    resultado_homologado,
    dd.*,
    dl.*,
    dg.*,
    df.*,
    dfc.*,  
    ni.*,
    dc.*    
    from tbbi_fat_perfil_br_2026
    inner join tbbi_dim_data dd on dd.id_data = tbbi_fat_perfil_br_2026.id_data
    inner join tbbi_dim_localidade dl on dl.id_localidade = tbbi_fat_perfil_br_2026.id_localidade
    inner join tbbi_dim_geracoes dg on dg.id_geracao = tbbi_fat_perfil_br_2026.id_geracao
    inner join tbbi_dim_faixas df on df.id_faixa = tbbi_fat_perfil_br_2026.id_faixa
    inner join tbbi_dim_cbat_categorias dfc on dfc.id_cbat_categoria = tbbi_fat_perfil_br_2026.id_cbat_categoria
    inner join tbbi_dim_organizacao_2026 ni on ni.id_organizacao = tbbi_fat_perfil_br_2026.id_organizador
    inner join tbbi_dim_cronometragem dc on dc.id_cronometragem = tbbi_fat_perfil_br_2026.id_cronometrador;

    grant select on vwbi_fat_perfil_br_2026 to runner;
    grant select on vwbi_fat_perfil_br_2026 to akkio_user;