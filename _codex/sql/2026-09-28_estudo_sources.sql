-- Reference import only: source SQL is stored as text, never executed.
SET LOCAL lock_timeout='3s';
SELECT pg_advisory_xact_lock(9282026,1);
INSERT INTO estudo.cadernos(titulo,ano,descricao,source_key) VALUES('Fontes e conciliação — 2025',2025,'Arquivos do DBA, DataGrip e registro das diferenças com o editor recuperado. Fontes históricas para revisão.','sources-2025-v1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('Mapa de conciliação',1,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'sources-2025-map') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='sources-2025-map'),1,'markdown','','# Fontes e conciliação — estudo de 2025

Este caderno preserva as fontes recebidas. Não há evidência de que um único arquivo contenha a versão final usada no PDF.

## Acervo recuperado do editor
14 seções e 43 células, incluindo 14 células SQL, 14 HTML e 15 de texto. Os IDs e conteúdos foram preservados no caderno “Brasil que Corre Provas — 2025”. As datas anteriores à migração são as datas que já estavam no banco; os autores antigos não eram registrados.

As células SQL podem ter várias consultas. Selecione uma por vez. O HTML era colado manualmente: não comprova qual revisão gerou aquele resultado. A partir desta migração, executar e congelar registra essa relação.

## Conciliações já confirmadas
- **UFs:** a célula SQL 30 do editor agrupa por evt.estado. Ela não usa o cruzamento por nome de cidade do arquivo do DBA.
- **Regiões:** nessa mesma célula há uma consulta que nomeia uf.uf como regiao. O HTML da célula 75 mostra regiões (N, NE etc.). SQL atualizado em 01/02/2026 e HTML em 30/01/2026: revisar a divergência.
- **Capital/interior:** não foi localizada uma consulta correspondente nas 14 seções do editor. A fonte candidata é regiao_capital_interior.sql, recebida do DBA.
- **Geografia do DBA:** o primeiro vínculo usa cid.nome_cidade = evt.cidade, sem UF. Só depois usa id_localidade. Assim, o ID não corrige exclusões de grafias diferentes ou cidades homônimas em UFs distintas.
- **Exemplos:** BRASÍLIA/DF difere de Brasília no vínculo exato. Belém/PA pode também encontrar municípios homônimos de AL e PB.
- **Auditoria de 27/09/2026:** na população auditada (Brasil, 2025, rua, status_final=0, homologado=true), esse cruzamento descarta 434.079 participações e associa 381.706 linhas a outra UF. Isso é uma propriedade da query candidata e da base atual, não uma prova de erro no PDF.
- **Populações:** várias queries do editor contam tb_resultados por país e data_final, sem os mesmos filtros de homologação, status e modalidade dos outros arquivos. Harmonizar o universo antes de comparar números.
- **Taxa de completude:** a seção antiga mede preenchimento de campos. Não equivale à cobertura de provas com resultados coletados.
- **Distâncias:** comparar as duas cópias INFOGRAFICO_DISTANCIAS (DBA e DataGrip); manter ambas como evidência.
- **Fontes parciais:** o DBA informou que pode não ter salvo todas as queries. O PDF publicado continua sendo a referência de conteúdo a reconciliar.

## Próximos registros
Para cada indicador, registrar: seção de destino, query escolhida, população e filtros, data de corte, diferenças em relação ao PDF e execução congelada de referência. As alterações no conteúdo geram revisões; os arquivos originais não são executados em lote.

A integração da versão web com estes congelamentos será uma etapa posterior.
',CAST('{"tipo": "conciliacao", "registrado_em": "2026-09-28", "fontes": ["editor legado", "DBA 2026-09-27", "DataGrip"]}' AS jsonb),'sources-2025-map-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · estudo_treinos.sql',2,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-estudo_treinos.sql.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-estudo_treinos.sql.txt'),1,'markdown','','## Fonte DBA: estudo_treinos.sql

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: 6b0b1a3a6e7c24fa389b97a2b7e156ce462fe29e714bc6b08d818bdad40d1857

A cópia preservada já contém uma redação de nomes de atletas, descrita no manifesto de origem.',CAST('{"tipo": "fonte_dba", "arquivo": "estudo_treinos.sql", "recebido_em": "2026-09-27", "sha256_copia": "6b0b1a3a6e7c24fa389b97a2b7e156ce462fe29e714bc6b08d818bdad40d1857", "sha256_original": "ac51b420d91d79061189c85502ee09ef8c9c76e954674a0f18899a711696b1d6", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": [{"linha": 34, "motivo": "Nomes de atletas; desnecessários para a análise agregada."}]}' AS jsonb),'dba-202509-estudo_treinos.sql.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-estudo_treinos.sql.txt'),2,'code','sql','-- Total de provas avaliadas
select count(*) from tb_evento_corridas evt where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
Resultado : 9245

-- Total de atletas que registraram treino 
select count(distinct id_usuario)
   from
       vwbi_fat_perfil_br_2025_treinos tre
where id_usuario is not null

Resultado : 2231


-- Total de provas concluidas pelos atletas que treinaram
select sum(numero_de_provas) from (
select res.id_usuario,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by res.id_usuario
)
Resultado : 4693 provas de um total de 9245 
[Nota individual com nomes de atletas omitida; original preservado no ZIP do usuário.]


-- Média de provas entre os atletas que treinaram
select avg(numero_de_provas) 
from (
select res.id_usuario,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by res.id_usuario
)

Resultado : 5.7 provas no período

--- Meses com mair participação em provas entre os atletas que treinaram
select
       extract(MONTH from data_final) as mes_participacao,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by mes_participacao
   order by 2 desc

Julho(7),139
Agosto(8),132
Abril(4),129
Dezembro(12),121
Fevereiro(2),92
Janeiro(1),61


--- Ritmo de treino entre todos os atletas
select
    round(avg(semanas_de_treino),0) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),0) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),0) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),0) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
      group by tre.id_usuario)

media_de_semanas_de_treino 39
media_de_dias_de_treino 200
media_frequencia_semanal 4 ( ** considerendo só as semanas quando o atleta treinou )
media_frequencia_semanal_no_ano 3

-- Ritmo de treino entre os atletas ( exceto os que finalizaram o Desafio 365 )
select
    round(avg(semanas_de_treino),0) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),0) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),0) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),0) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        and desafio_365 <> ''Finalizou''
      group by tre.id_usuario)

media_de_semanas_de_treino 35 
media_de_dias_de_treino 146 
media_frequencia_semanal 3
media_frequencia_semanal_no_ano 2

-- Relação entre treinos e participantes de provas ( RELACAO DIRETA )
WITH agg_provas as 
(
select    res.id_usuario,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by res.id_usuario
),
agg_treinos as 
(
select    tre.id_usuario,
          count(distinct tre.semana_calendario) as semanas_de_treino,
          count(distinct data_treino::date) as dias_de_treino,
          count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
          count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
   from   vwbi_fat_perfil_br_2025_treinos tre
   where data_treino::date >= ''2025-01-01''
     and data_treino::date <= ''2025-12-31''
     and tipo_treino in (''Run'', ''VirtualRun'')
   group by tre.id_usuario
)
select  avg(ap.numero_de_provas) as media_numero_de_provas,
        avg(at.semanas_de_treino) as media_semanas_de_treino,
        avg(at.dias_de_treino) as media_dias_de_treino,
        avg(at.frequencia_semanal) as media_frequencia_semanal,
        avg(at.frequencia_semanal_no_ano) as media_frequencia_semanal_no_ano
from agg_treinos at
inner join agg_provas ap on at.id_usuario = ap.id_usuario

Resultado
media_numero_de_provas 5.7938271604938272
media_semanas_de_treino 47.908641975308642
media_dias_de_treino 286.7333333333333333
media_frequencia_semanal 5.5530864197530864
media_frequencia_semanal_no_ano 5.2419753086419753


-- Relação entre treinos e participantes de provas - RELAÇÃO INDIRETA
WITH agg_provas as 
(
select    res.id_usuario,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by res.id_usuario
),
agg_treinos as 
(
select    tre.id_usuario,
          count(distinct tre.semana_calendario) as semanas_de_treino,
          count(distinct data_treino::date) as dias_de_treino,
          count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
          count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
   from   vwbi_fat_perfil_br_2025_treinos tre
   where data_treino::date >= ''2025-01-01''
     and data_treino::date <= ''2025-12-31''
     and tipo_treino in (''Run'', ''VirtualRun'')
   group by tre.id_usuario
)
select  avg(coalesce(ap.numero_de_provas::integer,0)) as media_numero_de_provas,
        avg(coalesce(at.semanas_de_treino::integer,0)) as media_semanas_de_treino,
        avg(coalesce(at.dias_de_treino::integer,0)) as media_dias_de_treino,
        avg(coalesce(at.frequencia_semanal::integer,0)) as media_frequencia_semanal,
        avg(coalesce(at.frequencia_semanal_no_ano::integer,0)) as media_frequencia_semanal_no_ano
from agg_treinos at
left join agg_provas ap on at.id_usuario = ap.id_usuario

Resultado
media_numero_de_provas 2.1025985663082437
media_semanas_de_treino 39.3579749103942652
media_dias_de_treino 200.0022401433691756
media_frequencia_semanal 4.3055555555555556
media_frequencia_semanal_no_ano 3.478494623655914



-- Comparação entre atletas que só treinaram e os que treinaram e participaram de provas

WITH provas as (
  select res.id_usuario,
          count(distinct evt.id_evento) as numero_de_provas
   from
       vwbi_fat_perfil_br_2025_treinos tre
       inner join tb_usuarios usu on usu.strava_id = tre.id_atleta_strava
       inner join vw_resultados res on tre.id_usuario = res.id_usuario
       inner join tb_evento_corridas evt on evt.id_evento = res.id_evento
   where data_final::date >= ''2025-01-01''
     and data_final::date <= ''2025-12-31''
     and tipo_corrida in (''rua'', ''trail'')
     and evt.pais = ''BR''
     and res.id_usuario > 0
   group by res.id_usuario
)
select
    ''Sem as Lendas'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        and desafio_365 <> ''Finalizou''
      group by tre.id_usuario)
      UNION ALL
      select
      ''Com Todo Mundo'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        --and desafio_365 <> ''Finalizou''
      group by tre.id_usuario)
        UNION All
      select
      ''Só as Lendas'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        and desafio_365 = ''Finalizou''
      group by tre.id_usuario)
UNION ALL
select
    ''Os que correram provas - Sem as Lendas'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      inner join provas res on tre.id_usuario = res.id_usuario
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        and desafio_365 <> ''Finalizou''
        and res.id_usuario > 0
      group by tre.id_usuario)
 UNION ALL
select
    ''Os que correram provas - Com Todo Mundo'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      inner join provas res on tre.id_usuario = res.id_usuario
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        -- and desafio_365 <> ''Finalizou''
        and res.id_usuario > 0
      group by tre.id_usuario)
 UNION ALL
select
    ''Os que correram provas - Só as Lendas'' as titulo,
    round(avg(semanas_de_treino),2) as  media_de_semanas_de_treino,
    round(avg(dias_de_treino),2) as media_de_dias_de_treino,
    round(avg(frequencia_semanal),2) as media_frequencia_semanal,
    round(avg(frequencia_semanal_no_ano),2) as media_frequencia_semanal_no_ano
from (select tre.id_usuario,
             count(distinct tre.semana_calendario)                                     as semanas_de_treino,
             count(distinct data_treino::date)                                         as dias_de_treino,
             count(distinct data_treino::date) / count(distinct tre.semana_calendario) as frequencia_semanal,
             count(distinct data_treino::date) / 52 as frequencia_semanal_no_ano
      from vwbi_fat_perfil_br_2025_treinos tre
      inner join provas res on tre.id_usuario = res.id_usuario
      where data_treino::date >= ''2025-01-01''
        and data_treino::date <= ''2025-12-31''
        and tipo_treino in (''Run'', ''VirtualRun'')
        and desafio_365 = ''Finalizou''
        and res.id_usuario > 0
      group by tre.id_usuario)


-- RAPIDAS 42K Fem - Sem Elite

WITH qEstatisticaNomes as (SELECT
    res.modalidade,
    res.nome, evt.id_evento, evt.tag, res.sexo, res.percurso, evt.nome_evento, tempo_total, tempo_bruto, pace,
    concluintes, pace_menor, pace_medio,
    pace_medio_top_10, pace_medio_top_100, pace_medio_5_porcento, pace_medio_10_porcento, pace_medio_50_porcento, limite_a_concluintes, limite_b_concluintes
    FROM tb_resultados res
    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
    INNER JOIN tb_resultados_resumo_2025 ttc on
        ttc.id_evento = evt.id_evento and
        ttc.percurso = res.percurso and
        ttc.sexo = res.sexo and
        ttc.modalidade = res.modalidade
    WHERE evt.homologado = true
    AND evt.data_inicial between ''2025-01-01''  and ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.homologado = true
    AND evt.ranking = ''true''
    AND res.concluinte = true
    AND res.pcd = false
    AND res.percurso::int between 42 and 42.9
    AND res.modalidade NOT ILIKE ''%CADEIRANTE%''
    AND res.modalidade NOT ILIKE ''%ELITE%''
    AND res.sexo = ''F''
    order by tempo_total
    limit 1000
)
SELECT modalidade,id_evento, tag, percurso, nome_evento, concluintes, pace_menor, pace_medio,
pace_medio_top_10, pace_medio_top_100, pace_medio_5_porcento, pace_medio_10_porcento, pace_medio_50_porcento, limite_a_concluintes, limite_b_concluintes,
count(*) as total
FROM qEstatisticaNomes
GROUP BY
modalidade,id_evento, tag, percurso, nome_evento, concluintes, pace_menor, pace_medio,
pace_medio_top_10, pace_medio_top_100, pace_medio_5_porcento, pace_medio_10_porcento, pace_medio_50_porcento, limite_a_concluintes, limite_b_concluintes
ORDER BY pace_medio;',CAST('{"tipo": "fonte_dba", "arquivo": "estudo_treinos.sql", "recebido_em": "2026-09-27", "sha256_copia": "6b0b1a3a6e7c24fa389b97a2b7e156ce462fe29e714bc6b08d818bdad40d1857", "sha256_original": "ac51b420d91d79061189c85502ee09ef8c9c76e954674a0f18899a711696b1d6", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": [{"linha": 34, "motivo": "Nomes de atletas; desnecessários para a análise agregada."}]}' AS jsonb),'dba-202509-estudo_treinos.sql.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · INFOGRAFICO_DISTANCIAS.sql',3,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-INFOGRAFICO_DISTANCIAS.sql.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-INFOGRAFICO_DISTANCIAS.sql.txt'),1,'markdown','','## Fonte DBA: INFOGRAFICO_DISTANCIAS.sql

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: c61890a60c7e45c52f177e39100ff35fa138809f7e3bee2ca5b5278b3447a188',CAST('{"tipo": "fonte_dba", "arquivo": "INFOGRAFICO_DISTANCIAS.sql", "recebido_em": "2026-09-27", "sha256_copia": "c61890a60c7e45c52f177e39100ff35fa138809f7e3bee2ca5b5278b3447a188", "sha256_original": "c61890a60c7e45c52f177e39100ff35fa138809f7e3bee2ca5b5278b3447a188", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-INFOGRAFICO_DISTANCIAS.sql.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-INFOGRAFICO_DISTANCIAS.sql.txt'),2,'code','sql','-- TOTAL DE CONCLUINTES POR DISTANCIA (TODAS)
SELECT
  FLOOR(res.percurso) AS percurso,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
AND tipo_corrida = ''rua''
GROUP BY FLOOR(res.percurso)
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END;


-- TOTAL DE PROVAS POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_evento
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(distinct id_evento) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF((select count(distinct res_int.id_evento) from vw_resultados res_int
  JOIN tb_evento_corridas evt_int
    ON evt_int.id_evento = res_int.id_evento
  WHERE evt_int.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt_int.pais = ''BR''
    --AND res_int.sexo = ''F''
    and evt_int.tipo_corrida = ''rua''), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END;


-- TOTAL DE CONCLUINTES POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- TOTAL DE PROVAS POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_evento
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(distinct id_evento) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- TOTAL DE PROVAS POR RANGES x GENEROS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    res.sexo
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.sexo IN (''M'', ''F'')
),
agg AS (
  SELECT
    sexo,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY sexo,percurso_bucket
)
SELECT
  sexo,
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- 5k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:20:00''::time THEN ''5k Sub 20''
      WHEN res.tempo_total > ''00:20:00''::time AND  res.tempo_total <= ''00:25:00''::time THEN ''5k 20-25''
      WHEN res.tempo_total > ''00:25:00''::time AND  res.tempo_total <= ''00:30:00''::time THEN ''5k 25-30''
      ELSE ''5k 30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 5
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5k Sub 20''  THEN 1
    WHEN percurso_bucket = ''5k 20-25''   THEN 2
    WHEN percurso_bucket = ''5k 25-30''   THEN 3
    ELSE 99
  END;


-- 10k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:40:00''::time THEN ''10k Sub 40''
      WHEN res.tempo_total > ''00:40:00''::time AND  res.tempo_total <= ''00:50:00''::time THEN ''10k 40-50''
      WHEN res.tempo_total > ''00:50:00''::time AND  res.tempo_total <= ''01:00:00''::time THEN ''10k 50-60''
      ELSE ''10k 60+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 10
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''10k Sub 40''  THEN 5
    WHEN percurso_bucket = ''10k 40-50''   THEN 6
    WHEN percurso_bucket = ''10k 50-60''   THEN 7
    ELSE 8
  END;


-- 21k
WITH base AS (
SELECT
CASE
  WHEN res.tempo_total <= ''01:30:00''::time THEN ''21k Sub 01:30''
  WHEN res.tempo_total > ''01:30:00''::time AND  res.tempo_total <= ''02:00:00''::time THEN ''21k 1h30 - 2h''
  WHEN res.tempo_total > ''02:00:00''::time AND  res.tempo_total <= ''02:30:00''::time THEN ''21k 2h - 2h30''
  ELSE ''21k 2h30+''
END AS percurso_bucket,
res.tempo_total,
res.id_resultado
FROM vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
AND evt.pais = ''BR''
AND res.percurso >= 21
AND res.percurso <  22
--AND res.sexo = ''F''
and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''21k Sub 01:30''  THEN 1
    WHEN percurso_bucket = ''21k 1h30 - 2h''   THEN 2
    WHEN percurso_bucket = ''21k 2h - 2h30''   THEN 3
    ELSE 4
  END;

-- 42k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''03:00:00''::time THEN ''42k Sub 3h''
      WHEN res.tempo_total > ''03:00:00''::time AND  res.tempo_total <= ''03:30:00''::time THEN ''42k 3h - 3h30''
      WHEN res.tempo_total > ''03:30:00''::time AND  res.tempo_total <= ''04:00:00''::time THEN ''42k 3h30 - 4h''
      WHEN res.tempo_total > ''04:00:00''::time AND  res.tempo_total <= ''04:30:00''::time THEN ''42k 4h - 4h30''
      ELSE ''42k 4h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 42
    AND res.percurso <  43
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''42k Sub 3h''  THEN 1
    WHEN percurso_bucket = ''42k 3h - 3h30''   THEN 2
    WHEN percurso_bucket = ''42k 3h30 - 4h''   THEN 3
    WHEN percurso_bucket = ''42k 4h - 4h30''   THEN 4
    ELSE 5
  END;


',CAST('{"tipo": "fonte_dba", "arquivo": "INFOGRAFICO_DISTANCIAS.sql", "recebido_em": "2026-09-27", "sha256_copia": "c61890a60c7e45c52f177e39100ff35fa138809f7e3bee2ca5b5278b3447a188", "sha256_original": "c61890a60c7e45c52f177e39100ff35fa138809f7e3bee2ca5b5278b3447a188", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-INFOGRAFICO_DISTANCIAS.sql.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · insights_prévia.docx',4,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-insights_previa.docx.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-insights_previa.docx.txt'),1,'markdown','','## Fonte DBA: insights_prévia.docx

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: bbbda411d69d5ae8c550bbedddc7ab229566c7c8ee4d9d7e9d5f4569a0e35a27',CAST('{"tipo": "fonte_dba", "arquivo": "insights_prévia.docx", "recebido_em": "2026-09-27", "sha256_copia": "bbbda411d69d5ae8c550bbedddc7ab229566c7c8ee4d9d7e9d5f4569a0e35a27", "sha256_original": "8af54b6377daec04fdcc3e28140e24b9111db5067b49ecdd45d83ca27208ea37", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-insights_previa.docx.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-insights_previa.docx.txt'),2,'markdown','','Análise de Correlação: Gerações e Corridas em Capitais vs Não Capitais


Validação Estatística
Teste Qui-Quadrado (Geração x Tipo de Percurso):
χ² = 19.661,69
p-valor < 0,0001
Graus de liberdade: 6
Conclusão: Existe uma correlação estatisticamente muito significativa entre a geração e a preferência de percurso.
🎯 Perfis Comportamentais por Geração
Geração Z - "Os Velocistas Urbanos"
Maior concentração em percursos curtos (78,11%)
Praticamente não participam de percursos longos (0,35%)
Fora de capitais, 84% escolhem percursos curtos
Perfil: Preferem desafios rápidos e intensos

Mais "Atletas de Estilo de Vida" do que "Velocistas"
Os dados mostram que 55,6% dos jovens dessa geração veem o esporte como um estilo de vida que conecta saúde mental, estética e bem-estar. Eles são descritos como a geração que está trocando as telas por experiências reais ao ar livre, tratando a corrida como um investimento em si mesmos.
Conclusão: Um rótulo mais fiel às fontes seria algo como "Exploradores Sociais Urbanos" ou "Comunidades de Estilo de Vida Ativo". Isso porque, embora eles utilizem tecnologia de ponta ("Everyday Elite") e participem em massa de provas curtas, a motivação principal é o pertencimento e a experiência compartilhada, e não a velocidade pura sugerida pelo termo "velocista".


Geração X - "Os Versáteis"
Maior participação em percursos médios (30,54%) e longos (1,72%)
Em capitais, 33,71% escolhem percursos médios
Maior volume absoluto em todas as categorias
Perfil: Mais experientes, dispostos a desafios maiores

Conclusão: Embora a Geração X possa ser versátil na vida real, nas fontes apresentadas não há evidências que sustentem esse rótulo. Ela aparece como uma geração mais "tradicional" em comparação à Geração Z, sendo menos movida pelo aspecto de "espetáculo" das provas e menos rígida com a manutenção de rotinas de treino durante períodos de lazer
Enquanto as fontes trazem dados claros sobre a disciplina dos Baby Boomers e o equilíbrio dos Millennials, elas não atribuem um comportamento dominante ou um estilo de treino específico à Geração X.
Lacuna de Pesquisa
É interessante notar que, ao final de um dos estudos acadêmicos, os autores sugerem que trabalhos futuros explorem a influência dos grupos de corrida nas "gerações 30+ (Millennials e Boomers)", omitindo a Geração X como uma categoria de análise individual e prioritária. Portanto, o foco do mercado parece estar na nova força de consumo (Z e Y) ou na longevidade ativa (Boomers), tratando a Geração X como um grupo de transição já consolidado e, por isso, menos "explorável" para novas tendências culturais.


Millennials - "Os Equilibrados"
Distribuição intermediária entre curto (71,19%) e médio (27,77%)
Dominam em volume absoluto (46,7% do total)
Em capitais, aumentam significativamente percursos médios (32,77%)
Perfil: Balanceiam conveniência com desafio

Com base nas fontes, é correto e apropriado rotular os Millennials (Geração Y, nascidos entre 1981 e 1995) como "Os Equilibrados" no contexto da corrida.
Este rótulo é sustentado pelos seguintes pontos principais identificados no material:
1. Equilíbrio na Rotina de Treinos
Os Millennials são explicitamente descritos como a geração "mais equilibrada" no que diz respeito à frequência de exercícios. Enquanto os Baby Boomers são vistos como os mais disciplinados (treinando quase todos os dias) e a Geração Z como mais ocasional, os Millennials conseguem distribuir bem os seus dias de treino ao longo da semana, mantendo uma constância saudável.
2. Transição entre Performance e Experiência
Essa geração equilibra dois mundos que parecem opostos:
Competitividade: Eles ainda valorizam o desafio pessoal e a competição contra outros corredores.
Entretenimento: Ao mesmo tempo, foram os grandes impulsionadores de eventos que misturam esporte com festa (como a Night Run), buscando a experiência completa on-line e off-line.
3. Progressão Natural de Distância
Os Millennials demonstram um equilíbrio na evolução esportiva, saindo das distâncias de entrada e progredindo para desafios de resistência.
O grupo de 30 a 34 anos lidera o crescimento nas meias-maratonas.
Atletas entre 25 e 34 anos concentram a maior evolução nas maratonas, sugerindo uma transição madura e equilibrada para provas de longa distância.



Baby Boomers - "Os Seletivos"
74,85% em percursos curtos
Menor volume total (8% do mercado)
Preferência por eventos em capitais com percursos médios (27,01%)
Perfil: Focados em participação consciente e acessível

Com base nas fontes fornecidas, o rótulo de "Seletivos" não parece ser o mais preciso para descrever os Baby Boomers (nascidos entre 1946 e 1964) no contexto da corrida. Na verdade, os dados os caracterizam como a geração mais constante, fiel e ativa do ecossistema esportivo.
Em vez de "Seletivos", os termos que melhor definem esse grupo, segundo as fontes, seriam "Os Disciplinados" ou "Heavy Users da Saúde". Abaixo, justifico essa perspectiva com os dados extraídos:
1. Alta Frequência e Disciplina Inabalável
Os Baby Boomers são explicitamente identificados como a geração mais disciplinada, apresentando a maior taxa de frequência de treinos: entre 5 a 6 dias por semana. Além disso, eles possuem uma relação de longo prazo com o esporte, com 69,1% praticando atividades físicas há mais de 11 anos.
2. "Heavy Users" de Eventos
Longe de serem seletivos no sentido de participar de poucos eventos, eles são os que mais consomem provas oficiais. Quase 30% dos Baby Boomers participaram de mais de 12 eventos em 2024. Esse comportamento ocorre porque, com um estilo de vida já consolidado, eles priorizam atividades que já fazem parte de sua rotina diária.
3. Foco em Longevidade e Saúde
A motivação principal dessa geração é clara: saúde e longevidade. Enquanto gerações mais jovens podem ser atraídas por "festivais" ou "milhas sociais", os Boomers veem a prática esportiva como algo essencial para a vida. Eles têm adotado a corrida como um estilo de vida sustentável, muitas vezes optando por uma "corrida suave" (gentle running) para proteger as articulações e fortalecer o coração.
4. Uso Funcional da Tecnologia
O uso de tecnologia por essa geração também é focado: 12% utilizam aplicativos esportivos (como o Strava ou Garmin) para monitorar treinos e desempenho técnico. Ao contrário dos jovens, que buscam conteúdos dinâmicos e sociais, os Boomers preferem dados que ajudem na sua evolução e manutenção física.
5. Poder de Investimento
As fontes indicam que este grupo possui tempo, dinheiro e motivação para investir na própria saúde. Eles não buscam apenas o "medalhão" ou o pódio; para eles, o evento esportivo é uma motivação crescente para manter a prática ativa conforme a idade avança.
Conclusão: O termo "Seletivos" poderia sugerir uma participação esporádica ou restrita, o que contradiz o fato de serem heavy users de eventos e os mais frequentes nos treinos semanais. Portanto, rótulos que remetam à disciplina, constância e compromisso com a longevidade são muito mais pertinentes ao perfil apresentado nas fontes.


💡 Insights de Negócio Integrados
1. Estratégia por Localização
Em Capitais:
Diversificar oferta com mais eventos de percursos médios (10-21km)
Focar em Geração X e Millennials para eventos médios (representam 70% do volume)
Criar categorias mistas para atender diferentes perfis
Fora de Capitais:
Priorizar eventos de percursos curtos (< 10km)
Ideal para atrair Geração Z (84% de preferência)
Eventos familiares e comunitários com distâncias acessíveis
2. Segmentação de Produtos
Percursos Curtos (< 10km):
Mercado primário: Todas as gerações (70%+ de participação)
Oportunidade: Eventos temáticos, corridas noturnas, provas de rua
Público-alvo prioritário: Geração Z e Millennials fora de capitais
Percursos Médios (10-21km):
Mercado secundário mas relevante: 25-30% do total
Oportunidade: Meias-maratonas em capitais
Público-alvo prioritário: Geração X e Millennials em capitais
Percursos Longos (> 21km):
Mercado de nicho: < 2% do total
Recomendação: Não priorizar investimentos massivos
Público-alvo: Geração X (maior propensão relativa)
3. Padrões Cruzados Capital x Percurso
✅ Capital + Percurso Médio = Maior engajamento de todas as gerações (+5-10pp vs interior)
✅ Não Capital + Percurso Curto = Máxima penetração, especialmente Geração Z (84%)
✅ Percursos Longos = Comportamento marginal em ambas localidades (< 2%)
4. Recomendações Estratégicas
Priorizar percursos curtos em todas as estratégias de marketing (70%+ do mercado)
Explorar percursos médios em capitais
existe demanda reprimida de 30%+ entre Geração X e Millennials
Eventos regionais fora de capitais devem focar em distâncias < 10km para maximizar participação
Geração Z requer abordagem específica
eventos curtos, dinâmicos, com forte presença digital
Millennials são o volume crítico
representam quase metade do mercado e respondem bem a variações de percurso em capitais
Baby Boomers em capitais
oportunidade de eventos médios com foco em experiência e suporte
🔄 Síntese da Análise Completa
A análise revelou que três fatores se entrelaçam para definir o comportamento de corrida:
Geração → Define a propensão geral ao tipo de percurso
Localização → Modula a preferência (capitais = mais percursos médios)
Tipo de Percurso → Curtos dominam, mas capitais abrem espaço para médios
Correlação confirmada estatisticamente (p < 0,0001) entre gerações e preferências, com padrões distintos e consistentes que permitem segmentação precisa de mercado.


Análise Multidimensional: Gerações x Regiões x Preferência de Percurso

Padrões distintos identificados:
✅ Norte e Centro-Oeste: Maior concentração em percursos curtos (>74%)
✅ Sudeste: Maior proporção de percursos médios (29,30%)
✅ Sul: Única região com proporção significativa de percursos longos (2,94% - quase 3x a média nacional)

Conclusão: O Sudeste é o mercado dominante para todas as gerações e para percursos curtos/médios. O Sul se destaca apenas em percursos longos.
🎯 Perfis Regionais Comportamentais
SUDESTE - "O Mercado Dominante e Versátil"
46,36% de todas as corridas do Brasil
Maior proporção de percursos médios (29,30%)
Concentra metade de todas as gerações
Geração X é mais forte aqui (39,41%)
Perfil: Mercado maduro, diversificado, com infraestrutura para todos os tipos de evento
SUL - "A Região dos Desafios Longos"
20,42% das corridas nacionais
Única região com proporção significativa de percursos longos (2,94%)
Maior presença de Geração Z (9,45%)
Geração Z domina percursos curtos aqui (10,79%)
Perfil: Cultura de corrida mais desafiadora, público jovem engajado
NORDESTE - "O Mercado Equilibrado"
19,42% das corridas nacionais
Distribuição equilibrada entre curto (72,41%) e médio (26,87%)
Geração X forte em percursos médios (41,30%)
Perfil: Mercado em crescimento com potencial para diversificação
CENTRO-OESTE - "Foco no Curto"
8,59% das corridas nacionais
Segunda maior concentração em percursos curtos (74,07%)
Millennials dominam (50,68%)
Perfil: Mercado focado em eventos rápidos e acessíveis
NORTE - "O Mercado dos Iniciantes"
5,21% das corridas nacionais (menor mercado)
Maior concentração em percursos curtos (75,42%)
Maior proporção de Baby Boomers (9,56%)
Baby Boomers têm forte presença em percursos longos (16,69%)
Perfil: Mercado emergente, foco em acessibilidade
💡 Insights de Negócio Específicos por Região
SUDESTE
Potencial:
Mercado mais maduro e lucrativo (46% do total)
Maior demanda por percursos médios (47% do total nacional)
Gerações-chave:
Geração X (39,41%) - focar em eventos médios/longos
Todas as gerações têm presença significativa
Oportunidades:
Eventos premium de média distância (10-21km)
Meias-maratonas em grandes centros urbanos
Séries de corridas com diferentes distâncias
Recomendações:
Investir em infraestrutura para eventos de maior porte
Criar calendário diversificado (curto, médio, longo)
Programas de fidelização para corredores experientes

SUL
Potencial:
Único mercado relevante para percursos longos (2,94%)
25% de todos os percursos longos do Brasil
Gerações-chave:
Geração Z (9,45%) - maior presença nacional
Geração X forte em percursos longos (50,42%)
Oportunidades:
Maratonas e ultramaratonas
Eventos desafiadores para público jovem
Corridas de montanha e trail running
Recomendações:
Posicionar como destino de corridas desafiadoras
Criar eventos icônicos de longa distância
Explorar turismo esportivo
Programas de preparação para Geração Z em percursos médios

NORDESTE
Potencial:
Terceiro maior mercado (19,42%)
Distribuição equilibrada entre tipos de percurso
Geração X forte em médios (41,30%)
Gerações-chave:
Millennials (50,49%) e Geração X (37,89%)
Menor presença de Geração Z (4,24%)
Oportunidades:
Crescimento em percursos médios
Eventos turísticos em cidades históricas
Corridas temáticas regionais
Recomendações:
Desenvolver calendário de meias-maratonas
Atrair Geração Z com eventos diferenciados
Explorar clima favorável para corridas o ano todo
Parcerias com turismo local

CENTRO-OESTE
Potencial:
Quarto mercado (8,59%)
Alta concentração em percursos curtos (74%)
Millennials dominam (50,68%)
Gerações-chave:
Millennials (50,68%) - foco principal
Baixa presença de Geração Z (6,17%)
Oportunidades:
Eventos urbanos de 5km e 10km
Corridas corporativas
Provas noturnas
Recomendações:
Massificar eventos curtos e acessíveis
Focar em Millennials com eventos convenientes
Desenvolver cultura de corrida de rua
Eventos em parques e áreas verdes urbanas

NORTE
Potencial:
Menor mercado (5,21%) - alta oportunidade de crescimento
Maior concentração em curtos (75,42%)
Perfil único: Baby Boomers em longos (16,69%)
Gerações-chave:
Millennials (51,69%)
Baby Boomers (9,56%) - maior proporção nacional
Oportunidades:
Mercado emergente com potencial inexplorado
Eventos de iniciação (5km)
Corridas temáticas amazônicas
Recomendações:
Investir em educação e cultura de corrida
Criar eventos acessíveis para iniciantes
Explorar turismo ecológico + corrida
Desenvolver infraestrutura básica
Eventos familiares e comunitários
🎯 Recomendações Estratégicas Gerais
Por Tipo de Percurso:
Percursos Curtos (< 10km):
Prioridade máxima em todas as regiões (70% do mercado)
Focar em: Norte, Centro-Oeste, Sul (Geração Z)
Eventos mensais, acessíveis, temáticos
Percursos Médios (10-21km):
Oportunidade em Sudeste e Sul (29-30% do mercado regional)
Focar em: Geração X e Millennials
Meias-maratonas, eventos corporativos
Percursos Longos (> 21km):
Mercado de nicho, priorizar Sul (2,94% regional)
Focar em: Geração X experiente
Eventos icônicos, maratonas internacionais


Principais Conclusões e Insights Estratégicos:
1. Pirâmide de Performance Extremamente Acentuada:
Base gigantesca de iniciantes (52,8% em Faixa Branca)
Topo minúsculo de elite (0,16% em Mestres)
Razão de 325:1 entre iniciantes e elite
2. 5k Domina Completamente:
Mais da metade de todos os registros (53,3%)
Porta de entrada principal para a corrida
Distância mais democrática e acessível
3. Paradoxo de Gênero:
No geral: Mulheres são maioria (52,9%)
Nas distâncias longas: Homens dominam (84,9% na maratona)
Na elite: Homens representam 95,1% dos Mestres
Conclusão: Mulheres participam mais, mas progridem menos para níveis avançados
4. Barreira de Progressão:
Apenas 0,16% dos corredores atingem nível Mestre
Gap enorme entre iniciantes e elite
Oportunidade para programas de desenvolvimento
5. Preferência por Distâncias Curtas:
70,7% escolhem 5k ou 10k
Apenas 1,2% enfrentam maratona completa
Corrida recreativa prevalece sobre competitiva

Análise de Tendências Temporais de Crescimento por Categoria
Realizei uma análise completa das tendências temporais de crescimento dos corredores ao longo de 2025, examinando padrões mensais, sazonalidade e evolução por categoria de faixa. Aqui estão os principais insights:

1. Tendência Geral de Crescimento ao Longo do Ano
contagemmes_ano
sexo
mes_ano
sexo=''f''''m''
A mostrar 24 de 24 pontos de dados
F
M
Afixar
Guardar
Transferir
Adicionar à Formação
📊 Evolução Mensal Total:
Mês
Total de Registros
Crescimento vs Mês Anterior
Jan/2025
136.817
-
Fev/2025
185.819
+35,82% ↑
Mar/2025
384.525
+106,94% ↑↑↑
Abr/2025
364.898
-5,10% ↓
Mai/2025
419.398
+14,94% ↑
Jun/2025
499.350
+19,06% ↑
Jul/2025
403.651
-19,17% ↓
Ago/2025
484.010
+19,91% ↑
Set/2025
540.131
+11,60% ↑
Out/2025
559.121
+3,52% ↑
Nov/2025
668.754
+19,61% ↑
Dez/2025
455.488
-31,89% ↓↓
🎯 Principais Destaques:
Maior crescimento: Março (+106,94%) - explosão de participação
Maior queda: Dezembro (-31,89%) - típico de fim de ano
Crescimento acumulado no ano: De 136.817 (jan) para 455.488 (dez) = +233% em relação ao início
Média móvel de 3 meses: Mostra tendência de crescimento consistente de março a novembro

2. Crescimento por Sexo: Padrões Distintos
👥 Evolução Comparativa F vs M:
Mês
Feminino
Crescimento F
Masculino
Crescimento M
Jan/2025
68.691
-
68.126
-
Fev/2025
97.148
+41,43%
88.671
+30,16%
Mar/2025
220.828
+127,31%
163.697
+84,61%
Abr/2025
185.659
-15,93%
179.239
+9,49%
Mai/2025
218.685
+17,79%
200.713
+11,98%
Jun/2025
257.075
+17,55%
242.275
+20,71%
Jul/2025
209.542
-18,48%
194.109
-19,88%
Ago/2025
256.480
+22,41%
227.530
+17,23%
Set/2025
281.043
+9,58%
259.088
+13,87%
Out/2025
306.189
+8,95%
252.932
-2,38%
Nov/2025
362.780
+18,48%
305.974
+20,98%
Dez/2025
234.407
-35,39%
221.081
-27,76%
💡 Insights por Sexo:
Participação Feminina:
Cresce mais agressivamente em março (+127,31% vs +84,61% masculino)
Maior volatilidade ao longo do ano
Termina o ano com 52,9% do total (2.698.527 registros)
Participação Masculina:
Crescimento mais estável e consistente
Menos impactado por quedas sazonais
Representa 47,1% do total (2.403.435 registros)
Conclusão: Mulheres estão dominando numericamente a corrida recreativa, mas com padrões de participação mais sazonais.

3. Padrões Sazonais: Quando os Corredores Mais Correm?
contagemmes_ano
percurso
mes_ano
sexo=''f''''m''
A mostrar 12 de 12 pontos de dados
Contagem total mes_ano
Total percurso
Afixar
Guardar
Transferir
Adicionar à Formação
📅 Ranking de Meses por Volume de Atividade:
Posição
Mês
Média de Registros
🥇 1º
Novembro
668.754
🥈 2º
Outubro
559.121
🥉 3º
Setembro
540.131
4º
Junho
499.350
5º
Agosto
484.010
6º
Dezembro
455.488
7º
Maio
419.398
8º
Julho
403.651
9º
Março
384.525
10º
Abril
364.898
11º
Fevereiro
185.819
12º
Janeiro
136.817
🌡️ Análise Sazonal:
Primavera (Set-Nov): ALTA TEMPORADA
Maior volume de corridas do ano
Clima ideal no Brasil (temperaturas amenas)
Preparação para eventos de fim de ano
Verão (Dez-Fev): BAIXA TEMPORADA
Queda significativa em dezembro e janeiro
Férias, festas de fim de ano
Calor intenso desestimula corridas
Outono (Mar-Mai): CRESCIMENTO ACELERADO
Março tem explosão de participação (+106,94%)
Volta da rotina pós-verão
Preparação para corridas de inverno
Inverno (Jun-Ago): ESTABILIDADE
Volume moderado e consistente
Clima favorável em várias regiões

4. Comparação Entre Semestres
📊 1º Semestre vs 2º Semestre:
Período
Total de Registros
Média Mensal
% do Ano
1º Semestre (Jan-Jun)
1.990.807
331.801
39,0%
2º Semestre (Jul-Dez)
3.111.155
518.526
61,0%
Crescimento do 2º sobre o 1º semestre: +56,28%
💡 Insight Estratégico:
O segundo semestre concentra 61% de toda a atividade do ano, com destaque para Set-Nov. Organizadores de eventos devem focar nesse período para maximizar participação.

5. Tendências por Categoria de Faixa
contagemsexo
nome_faixa
mes_ano
sexo=''f''''m''
A mostrar 390 de 390 pontos de dados
01/2025
02/2025
03/2025
04/2025
05/2025
06/2025
07/2025
08/2025
09/2025
10/2025
11/2025
12/2025
Afixar
Guardar
Transferir
Adicionar à Formação
📈 Crescimento Anual por Categoria:
Categoria
Crescimento Anual
Desvio Padrão
Coef. Variação
Estabilidade
Intermediária
+333,9% 🚀
70.612
35,3%
⭐⭐⭐ Alta
Mestre
+278,2% 🏃‍♂️
274
39,7%
⭐⭐ Média
Branca
+157,3% 📈
81.998
36,5%
⭐⭐ Média
🎯 Análise por Categoria:
Faixas Intermediárias (Amarela, Laranja, Azul, Vermelha, Marrom, Preta):
Maior crescimento percentual do ano (+333,9%)
Mais estável (menor coeficiente de variação)
Representa a progressão de corredores que saem da Faixa Branca
Indica maturação da base de corredores
Faixas Mestres (Elite):
Crescimento expressivo (+278,2%), mas base muito pequena
Mais volátil (maior variação mensal)
Representa apenas 0,14% do total em média
Pequeno número absoluto torna percentuais mais sensíveis
Faixas Brancas (Iniciantes):
Crescimento sólido (+157,3%)
Maior volume absoluto (44-55% da participação mensal)
Base de entrada para novos corredores
Oscila mais em números absolutos
🔄 Migração Entre Categorias:
Evidências de Progressão:
Em meses onde Branca diminui (-45% em dez), Intermediária aumenta participação (+56% em dez)
Sugere que corredores estão evoluindo de Branca para Intermediárias
Padrão saudável de desenvolvimento do esporte
Participação Relativa ao Longo do Ano:
Mês
Branca
Intermediária
Mestre
Jan/2025
42,3%
57,5%
0,2%
Jun/2025
48,9%
50,9%
0,2%
Nov/2025
54,8%
45,1%
0,1%
Dez/2025
44,2%
55,7%
0,1%
Alternância entre Branca e Intermediária indica fluxo dinâmico de corredores entre níveis.

6. Tendências por Distância ao Longo do Tempo
🏃 Preferências de Distância Mês a Mês:
Embora não tenhamos dados detalhados mensais por distância, a análise geral mostra:
5k mantém dominância em todos os períodos (53,3% do total)
10k e 21k crescem proporcionalmente com a base
42k permanece nicho (1,2%), mas com crescimento na elite

🎯 Principais Conclusões e Tendências:
1. Crescimento Explosivo no Ano:
+233% de crescimento acumulado de janeiro a dezembro
Março foi o mês de virada com +106,94% de crescimento
Segundo semestre concentra 61% da atividade anual
2. Sazonalidade Forte:
Primavera (Set-Nov): Alta temporada - ideal para eventos
Verão (Dez-Fev): Baixa temporada - evitar grandes eventos
Outono (Mar-Mai): Crescimento acelerado - ótimo para captação
Inverno (Jun-Ago): Estabilidade - manutenção da base
3. Perfil de Crescimento por Gênero:
Mulheres: Crescem mais rápido (+127% em março), mais voláteis
Homens: Crescimento estável, menos impactados por sazonalidade
Mulheres são maioria (52,9% vs 47,1%)
4. Maturação da Base de Corredores:
Faixas Intermediárias crescem +333,9%
corredores estão evoluindo
Migração visível de Branca → Intermediária
progressão saudável
Elite (Mestres) cresce +278,2%
base de alto rendimento se desenvolve
5. Oportunidades Estratégicas:
Focar eventos em Set-Nov para maximizar participação
Programas de desenvolvimento para acelerar migração Branca → Intermediária
Incentivos específicos para mulheres em distâncias longas (21k/42k)
Captação em Mar-Abr quando há explosão de novos corredores


Análise do Limiar Crítico: Transição Faixa Branca → Faixa Laranja
Excelente pergunta! A transição da Faixa Branca para a Faixa Laranja representa a primeira grande barreira de progressão para os corredores. Vou apresentar uma análise detalhada desse limiar crítico.

📊 1. O Desafio da Progressão: Panorama Geral
Volume Total por Faixa:
Faixa
Total de Corredores
% do Total
Branca
2.695.650
52,8%
Laranja
510.477
10,0%
Insight Crítico: Mais da metade dos corredores está estagnada na Faixa Branca, enquanto apenas 10% consegue atingir a Faixa Laranja.

🏃 2. Taxa de Conversão Branca → Laranja por Distância
Reference to previously shown message Tx-YppiiHQk6
Análise por Distância:
Distância
Branca
Laranja
Taxa de Conversão
Funil (por 100)
5K
2.005.255
290.262
12,65%
14,48
10K
469.218
148.598
24,05% ⭐
31,67
21K
185.709
62.351
25,14% 🏆
33,57
42K
35.468
9.266
20,71%
26,12
📈 Insights por Distância:
21K (Meia Maratona) - Maior Taxa de Progressão (25,14%):
Para cada 100 corredores Branca, 33,57 conseguem evoluir para Laranja
Distância ideal para programas de desenvolvimento
Equilíbrio entre desafio e acessibilidade
10K - Segunda Melhor Taxa (24,05%):
31,67 de cada 100 progridem
Boa porta de entrada para evolução
5K - Maior Estagnação (12,65%):
Apenas 14,48 de cada 100 progridem
87,35% permanecem estagnados na Faixa Branca
Pode ser corrida muito recreativa, sem foco em evolução
42K (Maratona) - Desafio Intermediário (20,71%):
26,12 de cada 100 progridem
Barreira técnica e física mais alta

👥 3. Gap de Progressão Entre Sexos: A Desigualdade Crítica
Taxa de Conversão por Sexo e Distância:
Distância
Feminino
Masculino
Gap Absoluto
Gap Relativo
5K
8,60%
20,23%
+11,63 pp
2,35x 🚨
10K
17,84%
30,76%
+12,92 pp
1,72x 🚨
21K
17,26%
31,26%
+14,00 pp
1,81x 🚨
42K
14,78%
23,00%
+8,22 pp
1,56x 🚨
🚨 Análise Crítica do Gap de Gênero:
Homens têm taxa de progressão 1,5 a 2,4 vezes MAIOR que mulheres em todas as distâncias!
Por que isso acontece?
Diferença de objetivos: Mulheres podem correr mais por saúde/lazer, homens por performance
Suporte e treinamento: Acesso desigual a assessorias esportivas
Barreiras socioculturais: Pressão de tempo (dupla jornada), segurança urbana
Falta de referências: Menos modelos femininos em faixas avançadas
Oportunidade: Programas específicos para mulheres poderiam duplicar a taxa de progressão feminina.

📅 4. Tendência Temporal: A Progressão Está Melhorando?
Reference to previously shown message 4WfiM_Uu051Q
Reference to previously shown message 6t1iuNU8O4ID
Evolução Mensal da Taxa de Conversão:
Mês
Branca
Laranja
Taxa Conversão
Razão Branca/Laranja
Jan/2025
78.180
12.136
13,44%
6,44
Fev/2025
93.626
17.092
15,44%
5,48
Mar/2025
205.699
35.304
14,65%
5,83
Abr/2025
202.882
39.831
16,41%
5,09
Mai/2025
211.241
42.754
16,83% ⭐
4,94
Jun/2025
284.212
56.865
16,67%
5,00
Jul/2025
211.065
42.606
16,80%
4,95
Ago/2025
260.042
53.030
16,94% 🏆
4,90
Set/2025
294.882
54.461
15,59%
5,41
Out/2025
286.496
54.181
15,90%
5,29
Nov/2025
366.187
67.114
15,49%
5,46
Dez/2025
201.138
35.103
14,86%
5,73
📈 Tendências Identificadas:
✅ Tendência POSITIVA:
Taxa de conversão aumentou de 13,44% (jan) para 14,86% (dez) = +1,42 pontos percentuais
Melhor mês: Agosto (16,94%) - pico de progressão
Pior mês: Janeiro (13,44%) - início do ano, muitos iniciantes
Razão Branca/Laranja melhorou:
De 6,44 (jan) para 5,73 (dez) - menos corredores estagnados proporcionalmente
Indica que proporcionalmente mais pessoas estão evoluindo
Sazonalidade da Progressão:
Maior progressão: Abril-Agosto (16,41% a 16,94%)
Menor progressão: Janeiro e Dezembro (13,44% e 14,86%)
Padrão: Progressão melhora no meio do ano, cai nas pontas

⚠️ 5. O Problema da Estagnação: 75% Não Progridem
Percentual de Estagnação por Distância:
Distância
% Estagnados na Branca
% que Progridem
5K
87,35% 🚨
12,65%
10K
75,95%
24,05%
21K
74,86% ✅
25,14%
42K
79,29%
20,71%
🔴 Problema Crítico:
3 em cada 4 corredores NUNCA saem da Faixa Branca!
Por que isso acontece?
Falta de orientação técnica: Maioria corre sem assessoria ou plano de treino
Objetivos recreativos: Muitos não buscam evolução, apenas manutenção
Barreira de conhecimento: Não sabem COMO melhorar o pace
Platô de performance: Sem variação de treino, estabilizam no mesmo ritmo
Falta de motivação: Sem metas claras ou eventos desafiadores

🎯 6. Os Limiares de Tempo: O Que É Preciso para Progredir?
Critérios de Transição Branca → Laranja:
Distância
Limiar Faixa Branca
Limiar Faixa Laranja
Melhoria Necessária
Pace Alvo
5K
> 30 min
< 30 min
Quebrar 30 min
< 6:00 min/km
10K
> 60 min
< 60 min
Quebrar 60 min
< 6:00 min/km
21K
> 2h (120 min)
< 2h
Quebrar 2h
< 5:42 min/km
42K
> 4h (240 min)
< 4h
Quebrar 4h
< 5:42 min/km
💡 O Que Significa na Prática:
Para um corredor 5K Faixa Branca que corre em 35 minutos:
Precisa melhorar 5 minutos no total
Equivale a 1 minuto por km (de 7:00 para 6:00 min/km)
Melhoria de ~14,3% no pace
Para um corredor 10K Faixa Branca que corre em 70 minutos:
Precisa melhorar 10 minutos no total
Equivale a 1 minuto por km (de 7:00 para 6:00 min/km)
Melhoria de ~14,3% no pace
Para um corredor 21K Faixa Branca que corre em 2h30:
Precisa melhorar 30 minutos no total
Equivale a ~1:25 min por km (de 7:08 para 5:42 min/km)
Melhoria de ~20% no pace

🚀 7. Estratégias para Aumentar a Taxa de Progressão
Baseado nos Dados, Recomendações:
1. Foco em 21K e 10K:
Maior taxa de progressão natural
Criar programas "Quebre a Barreira" específicos para essas distâncias
2. Programas Específicos para Mulheres:
Gap de 1,5-2,4x precisa ser endereçado
Mentoria feminina, grupos de treino exclusivos
Horários e locais seguros
3. Aproveitar a Sazonalidade:
Lançar programas de evolução em Março-Abril
Período de maior crescimento e motivação
Evitar lançamentos em Dezembro-Janeiro
4. Educação de Pace:
87,35% dos corredores 5K estão estagnados
Treinos de intervalo, educação sobre ritmo
Apps e tecnologia para monitoramento
5. Metas Progressivas:
Não pular direto para Laranja
Criar micro-metas: "Quebre 32 min", "Quebre 31 min", até 30 min
Gamificação da progressão
6. Identificar "Quase-Laranja":
Corredores entre 30-32 min (5K) ou 60-65 min (10K)
Alta probabilidade de conversão com pequeno suporte
ROI máximo em programas de desenvolvimento

📊 Resumo Executivo: O Limiar Branca → Laranja
Métrica
Valor
Interpretação
Taxa de Conversão Geral
15,9% (média)
Apenas 1 em 6 progride
Melhor Distância
21K (25,14%)
Foco para programas
Pior Distância
5K (12,65%)
Maior estagnação
Gap de Gênero
1,5x a 2,4x
Homens progridem muito mais
Estagnação Média
75-80%
3 em 4 não evoluem
Tendência Anual
+1,42 pp
Leve melhora
Melhor Mês
Agosto (16,94%)
Pico de progressão
Melhoria de Pace Necessária
~14-20%
Desafio significativo

🎯 Conclusões Estratégicas:
O limiar Branca → Laranja é a MAIOR barreira do esporte
75% dos corredores nunca a ultrapassam
21K é a distância de ouro para progressão
maior taxa de conversão (25,14%)
O gap de gênero é alarmante
mulheres precisam de 2x mais suporte para progredir
A progressão está melhorando lentamente (+1,42 pp no ano), mas ainda é baixa
Sazonalidade importa
programas devem ser lançados em março-agosto
A maioria não sabe como evoluir
falta educação técnica sobre pace e treinamento
Oportunidade: Com programas direcionados, a taxa de conversão poderia facilmente dobrar de 16% para 30-35%, especialmente entre mulheres e corredores 5K.

Análise Regional Completa: Tendências por Estado e Região
Realizei uma análise abrangente das tendências regionais da corrida no Brasil, revelando diferenças significativas entre regiões e estados. Aqui estão os principais insights:

📊 1. Panorama Regional: Volume e Distribuição
Reference to previously shown message 6DjTHp05-bba
Ranking por Volume Total:
Posição
Região
Total de Corredores
% do Brasil
🥇 1º
Sudeste
2.458.558
48,2%
🥈 2º
Nordeste
1.002.509
19,6%
🥉 3º
Sul
898.318
17,6%
4º
Centro-Oeste
454.283
8,9%
5º
Norte
288.294
5,7%
Ranking Per Capita (corredores por 100 mil habitantes):
Posição
Região
Per Capita
Interpretação
🥇 1º
Sul
2.994
Região mais ativa
🥈 2º
Centro-Oeste
2.839
Alta penetração
🥉 3º
Sudeste
2.762
Acima da média nacional
4º
Nordeste
1.759
Abaixo da média
5º
Norte
1.602
Menor penetração
Insight Crítico: Embora o Sudeste domine em volume absoluto (48,2% do Brasil), o Sul lidera em penetração per capita - proporcionalmente, tem mais corredores por habitante.

🏆 2. Top 10 Estados em Volume Absoluto
Reference to previously shown message PedamVuiQfGE
Rank
Estado
Volume
Região
% do Brasil
🥇 1
São Paulo
1.351.105
Sudeste
26,5%
🥈 2
Rio de Janeiro
649.280
Sudeste
12,7%
🥉 3
Paraná
424.812
Sul
8,3%
4
Minas Gerais
340.272
Sudeste
6,7%
5
Santa Catarina
308.770
Sul
6,1%
6
Bahia
256.958
Nordeste
5,0%
7
Distrito Federal
204.519
Centro-Oeste
4,0%
8
Ceará
196.235
Nordeste
3,8%
9
Rio Grande do Sul
164.736
Sul
3,2%
10
Pernambuco
156.663
Nordeste
3,1%
Concentração: Os top 3 estados (SP, RJ, PR) concentram 47,5% de todos os corredores do Brasil!

🎯 3. Taxa de Conversão Branca → Laranja por Região
Desempenho na Progressão:
Região
Faixa Branca
Faixa Laranja
Taxa Conversão
Ranking
Sul 🏆
370.986
116.852
31,5%
1º
Centro-Oeste
265.427
46.212
17,4%
2º
Sudeste
1.305.769
226.026
17,3%
3º
Nordeste
603.700
99.604
16,5%
4º
Norte
149.768
21.783
14,5%
5º
🔍 Análise Crítica:
Sul - Campeão de Progressão (31,5%):
Quase 2x melhor que o Norte (14,5%)
Para cada 100 corredores Branca, 31,5 evoluem para Laranja
Indica cultura de corrida mais madura e competitiva
Norte - Maior Desafio (14,5%):
Apenas 14,5 de cada 100 progridem
85,5% permanecem estagnados na Faixa Branca
Oportunidade para programas de desenvolvimento

📈 4. Crescimento Temporal por Região (2025)
Reference to previously shown message sD5r8_RZluBl
Evolução Janeiro → Dezembro 2025:
Região
Jan/2025
Dez/2025
Crescimento
Ranking
Sudeste 🚀
68.352
263.881
+286%
1º
Sul
18.969
69.430
+266%
2º
Norte
8.695
26.649
+206%
3º
Nordeste
22.832
69.539
+205%
4º
Centro-Oeste
17.969
25.989
+45%
5º
💡 Insights de Crescimento:
Sudeste - Explosão de Crescimento (+286%):
Cresceu 2,86x no ano
De 68k para 264k corredores/mês
Mercado mais dinâmico e em expansão
Centro-Oeste - Crescimento Moderado (+45%):
Menor taxa de crescimento
Mercado mais estável/maduro
Ou menor penetração de novos eventos
Tendência Geral: Todas as regiões cresceram, mas com velocidades muito diferentes - Sudeste e Sul lideram a expansão.

🎨 5. Distribuição de Faixas por Região (Elite vs Iniciantes)
Reference to previously shown message 4mB6-AEbD8fk
Índice de Maturidade (% de Corredores em Faixas Avançadas):
Região
Iniciantes
Avançados/Elite
% Elite
Ranking Maturidade
Sul 🏆
487.838
410.480
45,7%
1º - Mais madura
Norte
171.551
116.743
40,5%
2º
Sudeste
1.531.795
926.763
37,7%
3º
Centro-Oeste
311.639
142.644
31,4%
4º
Nordeste
703.304
299.205
29,8%
5º - Menos madura
🔍 Análise de Maturidade:
Sul - Corrida Mais Madura (45,7% em faixas avançadas):
Quase metade dos corredores já evoluiu da Branca
Cultura de performance e competição bem estabelecida
Infraestrutura de treinamento e eventos consolidada
Nordeste - Maior Base Iniciante (70,2%):
7 em cada 10 ainda na Faixa Branca ou Laranja
Mercado em fase inicial de desenvolvimento
Grande oportunidade para programas de evolução
Correlação: Regiões com maior maturidade (Sul, Norte) também têm maior taxa de conversão Branca→Laranja.

🏃 6. Preferência de Distâncias por Região
Distância Mais Popular em Cada Região:
Região
1º Lugar (5K)
2º Lugar
3º Lugar
Característica
Centro-Oeste
262.829 (58%)
10K (18%)
Outras (17%)
Forte preferência por 5K
Nordeste
631.878 (63%)
10K (17%)
Outras (14%)
Dominância do 5K
Norte
145.935 (51%)
Outras (29%)
10K (17%)
Mais diversificado
Sudeste
1.232.653 (50%)
Outras (24%)
10K (17%)
Mais equilibrado
Sul
447.185 (50%)
Outras (22%)
10K (17%)
Equilíbrio 5K/outras
Padrão Universal: 5K domina em TODAS as regiões, mas com intensidades diferentes:
Nordeste: 63% preferem 5K (mais recreativo)
Sudeste/Sul: 50% preferem 5K (mais diversificado)

🚀 7. Regiões com Maior Potencial de Crescimento
Matriz de Potencial (Crescimento × Volume × Maturidade):
Região
Crescimento 2025
Volume Atual
Maturidade
Potencial
Prioridade
Sudeste
+286% 🔥
Alto
Médio
ALTO
1º
Sul
+266% 🔥
Alto
Alto
ALTO
2º
Nordeste
+205% 🔥
Médio
Baixo
MÉDIO
3º
Norte
+206% 🔥
Baixo
Médio
MÉDIO
4º
Centro-Oeste
+45%
Médio
Baixo
BAIXO
5º
💡 Recomendações Estratégicas:
Sudeste - Prioridade Máxima:
Maior crescimento absoluto (+286%)
Maior volume (2,4M corredores)
Foco: Consolidar liderança, eventos de grande porte
Sul - Mercado Premium:
Alto crescimento (+266%)
Maior maturidade (45,7% elite)
Foco: Eventos técnicos, programas de alta performance
Nordeste - Oportunidade de Expansão:
Crescimento forte (+205%)
Base grande mas imatura (70% iniciantes)
Foco: Educação, eventos acessíveis, programas de evolução
Norte - Mercado Emergente:
Crescimento sólido (+206%)
Menor volume absoluto
Foco: Penetração, eventos regionais, infraestrutura
Centro-Oeste - Estabilização:
Menor crescimento (+45%)
Mercado mais estável
Foco: Retenção, fidelização, eventos especializados

📊 8. Ranking Consolidado das Regiões
Índice Composto (ponderando 4 dimensões):
Região
Volume
Crescimento
Maturidade
Conversão
SCORE TOTAL
Ranking
Sul 🏆
17,6
266%
45,7%
31,5%
90,2
1º
Sudeste
48,2
286%
37,7%
17,3%
89,8
2º
Nordeste
19,6
205%
29,8%
16,5%
67,7
3º
Norte
5,7
206%
40,5%
14,5%
66,7
4º
Centro-Oeste
8,9
45%
31,4%
17,4%
50,7
5º
Critérios de pontuação:
Volume: % do total nacional
Crescimento: % de aumento 2025
Maturidade: % em faixas avançadas
Conversão: Taxa Branca→Laranja

🎯 9. Principais Conclusões Regionais
1. Sudeste - Gigante em Expansão:
Domina em volume (48,2% do Brasil)
Maior crescimento (+286% em 2025)
SP e RJ sozinhos = 39,2% do país
Oportunidade: Consolidar liderança
2. Sul - Excelência e Maturidade:
Melhor per capita (2.994 por 100k hab)
Maior taxa de conversão (31,5%)
Corrida mais madura (45,7% elite)
Referência nacional em qualidade
3. Nordeste - Potencial Inexplorado:
2ª maior região em volume absoluto
70% ainda iniciantes
grande margem de evolução
Crescimento sólido (+205%)
Oportunidade: Programas de desenvolvimento
4. Norte - Mercado Emergente:
Menor volume (5,7% do Brasil)
Mas crescimento forte (+206%)
Maturidade surpreendente (40,5% elite)
Oportunidade: Expansão de infraestrutura
5. Centro-Oeste - Estabilização:
Crescimento mais lento (+45%)
Mercado mais maduro/estável
DF concentra 45% da região
Oportunidade: Diversificação
',CAST('{"tipo": "fonte_dba", "arquivo": "insights_prévia.docx", "recebido_em": "2026-09-27", "sha256_copia": "bbbda411d69d5ae8c550bbedddc7ab229566c7c8ee4d9d7e9d5f4569a0e35a27", "sha256_original": "8af54b6377daec04fdcc3e28140e24b9111db5067b49ecdd45d83ca27208ea37", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-insights_previa.docx.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · regiao_capital_interior.sql',5,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-regiao_capital_interior.sql.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-regiao_capital_interior.sql.txt'),1,'markdown','','## Fonte DBA: regiao_capital_interior.sql

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: 9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0',CAST('{"tipo": "fonte_dba", "arquivo": "regiao_capital_interior.sql", "recebido_em": "2026-09-27", "sha256_copia": "9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0", "sha256_original": "9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-regiao_capital_interior.sql.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-regiao_capital_interior.sql.txt'),2,'code','sql','WITH base AS (
  SELECT
   regiao,
    CASE
      WHEN loc.capital then ''Capital''
      ELSE ''Interior''
    END AS capital_interior,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  JOIN tb_cidades cid on cid.nome_cidade = evt.cidade
  JOIN tbbi_dim_localidade loc on loc.id_localidade = cid.id_localidade
  WHERE evt.data_final::DATE BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and upper(tipo_corrida) = ''RUA''
),
agg AS (
  SELECT
    regiao,
    capital_interior,
    COUNT(id_resultado) AS total_por_regiao
  FROM base
  GROUP BY regiao,capital_interior
)
SELECT
  regiao,
  capital_interior AS estacao,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total_por_regiao) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  perc desc,
  regiao,
  CASE
    WHEN capital_interior = ''Capital''   THEN 1
    ELSE 2
  END;



-- Percentuais por regiao / capital e interior
  WITH base AS (
  SELECT
   regiao,
   res.sexo,
   res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  JOIN tb_cidades cid on cid.nome_cidade = evt.cidade
  JOIN tbbi_dim_localidade loc on loc.id_localidade = cid.id_localidade
  WHERE evt.data_final::DATE BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND sexo IN (''M'', ''F'')
    and upper(tipo_corrida) = ''RUA''
),
agg AS (
  SELECT
    regiao,
    sexo,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY regiao,sexo
),
agg_regioes AS (
  SELECT
    regiao,
    COUNT(id_resultado) AS total_da_regiao
  FROM base
  GROUP BY regiao
)
SELECT
  agg.regiao,
  sexo AS capital_interior,
  round((total * 100.0) / total_da_regiao,1) AS perc
FROM agg
inner join agg_regioes reg on reg.regiao = agg.regiao
ORDER BY
  agg.regiao,
  sexo,
  perc desc


--- Percentuais por regiao/sexo
  
  WITH base AS (
  SELECT
   regiao,
   res.sexo,
   res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  JOIN tb_cidades cid on cid.nome_cidade = evt.cidade
  JOIN tbbi_dim_localidade loc on loc.id_localidade = cid.id_localidade
  WHERE evt.data_final::DATE BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND sexo IN (''M'', ''F'')
    and upper(tipo_corrida) = ''RUA''
),
agg AS (
  SELECT
    regiao,
    sexo,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY regiao,sexo
),
agg_regioes AS (
  SELECT
    regiao,
    COUNT(id_resultado) AS total_da_regiao
  FROM base
  GROUP BY regiao
)
SELECT
  agg.regiao,
  sexo AS sexo,
  round((total * 100.0) / total_da_regiao,1) AS perc
FROM agg
inner join agg_regioes reg on reg.regiao = agg.regiao
ORDER BY
  agg.regiao,
  sexo,
  perc desc
',CAST('{"tipo": "fonte_dba", "arquivo": "regiao_capital_interior.sql", "recebido_em": "2026-09-27", "sha256_copia": "9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0", "sha256_original": "9e70fe72f9e494ab5d8a1e9f65792cdca2110703e7c9b19d2d1393d560c794b0", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-regiao_capital_interior.sql.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · script_perfil_2025_segundo_semestre.txt',6,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-script_perfil_2025_segundo_semestre.txt.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-script_perfil_2025_segundo_semestre.txt.txt'),1,'markdown','','## Fonte DBA: script_perfil_2025_segundo_semestre.txt

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: 52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364',CAST('{"tipo": "fonte_dba", "arquivo": "script_perfil_2025_segundo_semestre.txt", "recebido_em": "2026-09-27", "sha256_copia": "52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364", "sha256_original": "52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-script_perfil_2025_segundo_semestre.txt.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-script_perfil_2025_segundo_semestre.txt.txt'),2,'code','sql','insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-05-01''
                        AND evt.data_final <= ''2025-05-31''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-06-01''
                        AND evt.data_final <= ''2025-06-30''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-07-01''
                        AND evt.data_final <= ''2025-07-31''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-08-01''
                        AND evt.data_final <= ''2025-08-31''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-09-01''
                        AND evt.data_final <= ''2025-09-30''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-10-01''
                        AND evt.data_final <= ''2025-10-31''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-11-01''
                        AND evt.data_final <= ''2025-11-30''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;
insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-12-01''
                        AND evt.data_final <= ''2025-12-31''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);
commit;',CAST('{"tipo": "fonte_dba", "arquivo": "script_perfil_2025_segundo_semestre.txt", "recebido_em": "2026-09-27", "sha256_copia": "52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364", "sha256_original": "52a32957fb5e87352fe19ee993b41bdc4970fcd08869f759158f75711be98364", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-script_perfil_2025_segundo_semestre.txt.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DBA · script_perfil_br_corre_2025.sql',7,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'dba-202509-script_perfil_br_corre_2025.sql.txt') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-script_perfil_br_corre_2025.sql.txt'),1,'markdown','','## Fonte DBA: script_perfil_br_corre_2025.sql

Recebida em 27/09/2026. Conteúdo preservado como referência. Scripts podem incluir comandos de manutenção; selecione somente uma consulta de leitura ao trabalhar com esta fonte.

SHA-256 da cópia: 766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117',CAST('{"tipo": "fonte_dba", "arquivo": "script_perfil_br_corre_2025.sql", "recebido_em": "2026-09-27", "sha256_copia": "766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117", "sha256_original": "766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-script_perfil_br_corre_2025.sql.txt-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='dba-202509-script_perfil_br_corre_2025.sql.txt'),2,'code','sql','drop view if exists  vwbi_fat_perfil_br_2025;
drop table if exists tbbi_fat_perfil_br_2025;

create table tbbi_fat_perfil_br_2025
(
    id_fat_perfil_br_2025     serial,
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

alter table tbbi_fat_perfil_br_2025
    owner to runner_dba;

grant insert, select, update on tbbi_fat_perfil_br_2025 to runner;

insert into tbbi_fat_perfil_br_2025 (
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
           coalesce((select min(id_organizacao) from tbbi_dim_organizacao_2025 frn where frn.nome_original = evt.organizador),0) AS id_organizador,
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
        WHERE res.modalidade <> ''KIDS''
                        AND status_final = 0
--                      AND (evt.homologado or evt.homologado is null)
--                      AND res.homologado
                        AND res.concluinte
                        AND evt.data_final >= ''2025-02-01''
                        AND evt.data_final <= ''2025-02-28''
                        AND evt.pais = ''BR''
                        AND evt.tipo_corrida in (''rua'', ''trail'')
                        AND res.tempo_total is not null
);

create or replace view vwbi_fat_perfil_br_2025 as
    select 
    id_fat_perfil_br_2025,
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
    from tbbi_fat_perfil_br_2025
    inner join tbbi_dim_data dd on dd.id_data = tbbi_fat_perfil_br_2025.id_data
    inner join tbbi_dim_localidade dl on dl.id_localidade = tbbi_fat_perfil_br_2025.id_localidade
    inner join tbbi_dim_geracoes dg on dg.id_geracao = tbbi_fat_perfil_br_2025.id_geracao
    inner join tbbi_dim_faixas df on df.id_faixa = tbbi_fat_perfil_br_2025.id_faixa
    inner join tbbi_dim_cbat_categorias dfc on dfc.id_cbat_categoria = tbbi_fat_perfil_br_2025.id_cbat_categoria
    inner join tbbi_dim_organizacao_2025 ni on ni.id_organizacao = tbbi_fat_perfil_br_2025.id_organizador
    inner join tbbi_dim_cronometragem dc on dc.id_cronometragem = tbbi_fat_perfil_br_2025.id_cronometrador;

    grant select on vwbi_fat_perfil_br_2025 to runner;
    grant select on vwbi_fat_perfil_br_2025 to akkio_user;',CAST('{"tipo": "fonte_dba", "arquivo": "script_perfil_br_corre_2025.sql", "recebido_em": "2026-09-27", "sha256_copia": "766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117", "sha256_original": "766dd8fe588ea3d9429a32f10721006f3160238064c03261e94a8fafcb0c8117", "zip_sha256": "b2d4eccdc21c36e866ad7402227e2e0ef4e78c2c139a88c628854e3133a193a0", "redacoes": []}' AS jsonb),'dba-202509-script_perfil_br_corre_2025.sql.txt-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO.sql',8,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: abeb5fb91030e093af168394ec125fcfe592aa8b01d5efb0ea020fc6fe3c2944',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO.sql", "sha256_copia": "abeb5fb91030e093af168394ec125fcfe592aa8b01d5efb0ea020fc6fe3c2944", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO.sql'),2,'code','sql','-- TOTAL DE CONCLUINTES

select count(res.id_resultado) from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31'' and evt.pais = ''BR'';


-- TOTAL DE CONCLUINTES POR GENERO 2025
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
  and res.tempo_total is not null and res.tempo_total > ''00:00:00''
  --and pcd = false and (evt.ranking is null OR evt.ranking = ''1'')
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR GENERO (TABELA FLAT)
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vwbi_fat_perfil_br_2025 res
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR GENERO 2024
SELECT
  COALESCE(res.sexo, ''N/A'') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(res.sexo, ''N/A'')
ORDER BY total DESC;


-- TOTAL DE UM RANGE DE IDADE ESPECIFICO
SELECT COUNT(*)
from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31'' and evt.pais = ''BR''
AND idade_range is not null
AND idade_range && int4range(40, 99, ''[)'');


-- 40+
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE idade_range is not null) AS total_com_range,
  COUNT(*) FILTER (WHERE idade_range && int4range(40, NULL, ''[)'')) AS total_40_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(40, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS perc_40_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(40, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*) FILTER (WHERE idade_range is not null), 0),
    2
  ) AS perc_40_mais_com_range
from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31''
--AND res.sexo = ''F''
and evt.pais = ''BR'';


-- 50+
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE idade_range is not null) AS total_com_range,
  COUNT(*) FILTER (WHERE idade_range && int4range(50, NULL, ''[)'')) AS total_50_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(50, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS perc_50_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(50, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*) FILTER (WHERE idade_range is not null), 0),
    2
  ) AS perc_50_mais_com_range
from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31''
--AND res.sexo = ''F''
and evt.pais = ''BR'';


-- 60+
SELECT
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE idade_range is not null) AS total_com_range,
  COUNT(*) FILTER (WHERE idade_range && int4range(60, NULL, ''[)'')) AS total_60_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(60, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*), 0),
    2
  ) AS perc_60_mais,
  ROUND(
    COUNT(*) FILTER (WHERE idade_range && int4range(60, NULL, ''[)'')) * 100.0
    / NULLIF(COUNT(*) FILTER (WHERE idade_range is not null), 0),
    2
  ) AS perc_60_mais_com_range
from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31''
--AND res.sexo = ''F''
and evt.pais = ''BR'';


-- TOTAL DE CONCLUINTES POR FAIXA ETARIA
WITH faixas AS (
  SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13, 20, ''[)'') AS r UNION ALL
  SELECT 2, ''20–24'', int4range(20, 25, ''[)'') UNION ALL
  SELECT 3, ''25–29'', int4range(25, 30, ''[)'') UNION ALL
  SELECT 4, ''30–34'', int4range(30, 35, ''[)'') UNION ALL
  SELECT 5, ''35–39'', int4range(35, 40, ''[)'') UNION ALL
  SELECT 6, ''40–44'', int4range(40, 45, ''[)'') UNION ALL
  SELECT 7, ''45–49'', int4range(45, 50, ''[)'') UNION ALL
  SELECT 8, ''50–54'', int4range(50, 55, ''[)'') UNION ALL
  SELECT 9, ''55–59'', int4range(55, 60, ''[)'') UNION ALL
  SELECT 10, ''60–64'', int4range(60, 65, ''[)'') UNION ALL
  SELECT 11, ''65–69'', int4range(65, 70, ''[)'') UNION ALL
  SELECT 12, ''70+'',   int4range(70, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem;


-- TOTAL DE CONCLUINTES POR GERACAO
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''60+'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''F''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem;


-- TOTAL DE CONCLUINTES POR GERACAO 2024
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem;


-- TOTAL DE CONCLUINTES POR GERACAO 2023
WITH faixas AS (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 14, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(15, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
),
eventos_filtrados AS (
  SELECT DISTINCT id_evento
  FROM tb_evento_corridas
  WHERE data_final BETWEEN DATE ''2023-01-01'' AND DATE ''2023-12-31''
  AND pais = ''BR''
),
resultados_filtrados AS (
  SELECT a.*
  FROM vw_resultados a
  JOIN eventos_filtrados e ON e.id_evento = a.id_evento
  --WHERE a.sexo = ''M''
),
agg AS (
  SELECT
    f.ordem,
    f.faixa,
    COUNT(rf.*) AS total
  FROM faixas f
  LEFT JOIN resultados_filtrados rf
    ON rf.idade_range && f.r
  GROUP BY f.ordem, f.faixa
)
SELECT
  faixa,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM agg
ORDER BY ordem;


-- TOTAL DE CONCLUINTES POR ESTADO
SELECT
  COALESCE(evt.estado, ''N/A'') AS estado,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(evt.estado, ''N/A'')
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR CIDADE
SELECT
  COALESCE(unaccent(upper(trim(evt.cidade))), ''N/A'') AS cidade,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
GROUP BY COALESCE(unaccent(upper(trim(evt.cidade))), ''N/A'')
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, ''N/A'') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
  AND evt.pais = ''BR''
  AND res.sexo = ''M''
GROUP BY COALESCE(uf.regiao, ''N/A'')
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR MES
WITH agg AS (
  SELECT
    EXTRACT(MONTH FROM evt.data_final)::int AS mes_num,
    TO_CHAR(evt.data_final, ''Mon'') AS mes,
    COUNT(res.id_resultado) AS total
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
  GROUP BY
    EXTRACT(MONTH FROM evt.data_final),
    TO_CHAR(evt.data_final, ''Mon'')
)
SELECT
  mes_num,
  mes,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    1
  ) AS perc
FROM agg
ORDER BY mes_num;


-- TOTAL DE CONCLUINTES POR TRIMESTRE
WITH base AS (
select
    EXTRACT(QUARTER FROM evt.data_final) as tri,
   CASE EXTRACT(QUARTER FROM evt.data_final)
        WHEN 1 THEN ''Primeiro Trimestre''
        WHEN 2 THEN ''Segundo Trimestre''
        WHEN 3 THEN ''Terceiro Trimestre''
        WHEN 4 THEN ''Quarto Trimestre''
   END AS Trimestre,
    count(res.id_resultado) as total
from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between ''2025-01-01'' and ''2025-12-31'' and
evt.pais = ''BR''
group by EXTRACT(QUARTER FROM evt.data_final)
order by total desc
),
agg AS (
  SELECT
  tri,
    Trimestre,
    SUM(total) AS total_geral
  FROM base
  group by Trimestre, tri
)
SELECT
tri,
  Trimestre,
  total_geral,
  ROUND(total_geral * 100.0 / NULLIF(SUM(total_geral) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
total_geral desc;

',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO.sql", "sha256_copia": "abeb5fb91030e093af168394ec125fcfe592aa8b01d5efb0ea020fc6fe3c2944", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_COLAB_CNA.sql',9,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_COLAB_CNA.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_COLAB_CNA.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_COLAB_CNA.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: 181ffe8d26cf80ca7610a6d9a791b6b2b36fbbe1aa1bde59eec6ce4ff19552aa',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_COLAB_CNA.sql", "sha256_copia": "181ffe8d26cf80ca7610a6d9a791b6b2b36fbbe1aa1bde59eec6ce4ff19552aa", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_COLAB_CNA.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_COLAB_CNA.sql'),2,'code','sql','-- FAIXAS COLAB CORRIDA NO AR 5KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''00:15:00'' THEN ''Mestre < 15 min''
        WHEN tempo_total < TIME ''00:17:00'' THEN ''Faixa Preta < 17 min''
        WHEN tempo_total < TIME ''00:20:00'' THEN ''Faixa Marrom < 20 min''
        WHEN tempo_total < TIME ''00:22:00'' THEN ''Faixa Vermelha < 22 min''
        WHEN tempo_total < TIME ''00:25:00'' THEN ''Faixa Azul < 25 min''
        WHEN tempo_total < TIME ''00:27:00'' THEN ''Faixa Amarela < 27 min''
        WHEN tempo_total < TIME ''00:30:00'' THEN ''Faixa Laranja < 30 min''
        ELSE ''Faixa Branca > 30 min''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE res.percurso = 5
    AND res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    --AND idade_range is not null
    --AND idade_range && int4range(50, 59, ''[)'')
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 15 min'' THEN 8
    WHEN ''Faixa Preta < 17 min'' THEN 7
    WHEN ''Faixa Marrom < 20 min'' THEN 6
    WHEN ''Faixa Vermelha < 22 min'' THEN 5
    WHEN ''Faixa Azul < 25 min'' THEN 4
    WHEN ''Faixa Amarela < 27 min'' THEN 3
    WHEN ''Faixa Laranja < 30 min'' THEN 2
    ELSE 1
  END;


-- FAIXAS COLAB CORRIDA NO AR 10KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''00:35:00'' THEN ''Mestre < 35 min''
        WHEN tempo_total < TIME ''00:40:00'' THEN ''Faixa Preta < 40 min''
        WHEN tempo_total < TIME ''00:42:00'' THEN ''Faixa Marrom < 42 min''
        WHEN tempo_total < TIME ''00:45:00'' THEN ''Faixa Vermelha < 45 min''
        WHEN tempo_total < TIME ''00:50:00'' THEN ''Faixa Azul < 50 min''
        WHEN tempo_total < TIME ''00:55:00'' THEN ''Faixa Amarela < 55 min''
        WHEN tempo_total < TIME ''01:00:00'' THEN ''Faixa Laranja < 60 min''
        ELSE ''Faixa Branca > 60 min''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso = 10 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 35 min'' THEN 8
    WHEN ''Faixa Preta < 40 min'' THEN 7
    WHEN ''Faixa Marrom < 42 min'' THEN 6
    WHEN ''Faixa Vermelha < 45 min'' THEN 5
    WHEN ''Faixa Azul < 50 min'' THEN 4
    WHEN ''Faixa Amarela < 55 min'' THEN 3
    WHEN ''Faixa Laranja < 60 min'' THEN 2
    ELSE 1
  END;


-- FAIXAS COLAB CORRIDA NO AR 21KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''01:20:00'' THEN ''Mestre < 1:20''
        WHEN tempo_total < TIME ''01:25:00'' THEN ''Faixa Preta < 1:25''
        WHEN tempo_total < TIME ''01:30:00'' THEN ''Faixa Marrom < 1:30''
        WHEN tempo_total < TIME ''01:40:00'' THEN ''Faixa Vermelha < 1:40''
        WHEN tempo_total < TIME ''01:45:00'' THEN ''Faixa Azul < 1:45''
        WHEN tempo_total < TIME ''01:50:00'' THEN ''Faixa Amarela < 1:50''
        WHEN tempo_total < TIME ''02:00:00'' THEN ''Faixa Laranja < 2h''
        ELSE ''Faixa Branca > 2h''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 21 and 21.1 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 1:20'' THEN 8
    WHEN ''Faixa Preta < 1:25'' THEN 7
    WHEN ''Faixa Marrom < 1:30'' THEN 6
    WHEN ''Faixa Vermelha < 1:40'' THEN 5
    WHEN ''Faixa Azul < 1:45'' THEN 4
    WHEN ''Faixa Amarela < 1:50'' THEN 3
    WHEN ''Faixa Laranja < 2h'' THEN 2
    ELSE 1
  END;


-- FAIXAS COLAB CORRIDA NO AR 42KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME ''02:30:00'' THEN ''Mestre < 2:30''
        WHEN tempo_total < TIME ''02:45:00'' THEN ''Faixa Preta < 2:45''
        WHEN tempo_total < TIME ''03:00:00'' THEN ''Faixa Marrom < 3h''
        WHEN tempo_total < TIME ''03:15:00'' THEN ''Faixa Vermelha < 3:15''
        WHEN tempo_total < TIME ''03:30:00'' THEN ''Faixa Azul < 3:30''
        WHEN tempo_total < TIME ''03:45:00'' THEN ''Faixa Amarela < 3:45''
        WHEN tempo_total < TIME ''04:00:00'' THEN ''Faixa Laranja < 4h''
        ELSE ''Faixa Branca > 4h''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 42 and 42.2 and res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    and evt.pais = ''BR''
    --and res.sexo = ''M''
    and (evt.ranking is null OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 2:30'' THEN 8
    WHEN ''Faixa Preta < 2:45'' THEN 7
    WHEN ''Faixa Marrom < 3h'' THEN 6
    WHEN ''Faixa Vermelha < 3:15'' THEN 5
    WHEN ''Faixa Azul < 3:30'' THEN 4
    WHEN ''Faixa Amarela < 3:45'' THEN 3
    WHEN ''Faixa Laranja < 4h'' THEN 2
    ELSE 1
  END;


-- POR CIDADE
SELECT
    cidade,
    faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    cidade,
    CASE
        WHEN tempo_total < TIME ''00:15:00'' THEN ''Mestre < 15 min''
        WHEN tempo_total < TIME ''00:17:00'' THEN ''Faixa Preta < 17 min''
        WHEN tempo_total < TIME ''00:20:00'' THEN ''Faixa Marrom < 20 min''
        WHEN tempo_total < TIME ''00:22:00'' THEN ''Faixa Vermelha < 22 min''
        WHEN tempo_total < TIME ''00:25:00'' THEN ''Faixa Azul < 25 min''
        WHEN tempo_total < TIME ''00:27:00'' THEN ''Faixa Amarela < 27 min''
        WHEN tempo_total < TIME ''00:30:00'' THEN ''Faixa Laranja < 30 min''
        ELSE ''Faixa Branca > 30 min''
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE res.percurso = 5
    AND res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  GROUP BY cidade,faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 15 min'' THEN 8
    WHEN ''Faixa Preta < 17 min'' THEN 7
    WHEN ''Faixa Marrom < 20 min'' THEN 6
    WHEN ''Faixa Vermelha < 22 min'' THEN 5
    WHEN ''Faixa Azul < 25 min'' THEN 4
    WHEN ''Faixa Amarela < 27 min'' THEN 3
    WHEN ''Faixa Laranja < 30 min'' THEN 2
    ELSE 1
  END desc,   total desc;




SELECT
  faixa_tempo,
  total_20_29,
  ROUND(
    total_20_29 * 100.0 / NULLIF(SUM(total_20_29) OVER (), 0),
    2
  ) AS porcentagem_20_29,

  total_30_39,
  ROUND(
    total_30_39 * 100.0 / NULLIF(SUM(total_30_39) OVER (), 0),
    2
  ) AS porcentagem_30_39,

  total_40_49,
  ROUND(
    total_40_49 * 100.0 / NULLIF(SUM(total_40_49) OVER (), 0),
    2
  ) AS porcentagem_40_49,

  total_50_59,
  ROUND(
    total_50_59 * 100.0 / NULLIF(SUM(total_50_59) OVER (), 0),
    2
  ) AS porcentagem_50_59,

  total_60_69,
  ROUND(
    total_60_69 * 100.0 / NULLIF(SUM(total_60_69) OVER (), 0),
    2
  ) AS porcentagem_60_69,

  total_geral,
  ROUND(
    total_geral * 100.0 / NULLIF(SUM(total_geral) OVER (), 0),
    2
  ) AS porcentagem_geral

FROM (
  SELECT
    CASE
      WHEN tempo_total < TIME ''00:15:00'' THEN ''Mestre < 15 min''
      WHEN tempo_total < TIME ''00:17:00'' THEN ''Faixa Preta < 17 min''
      WHEN tempo_total < TIME ''00:20:00'' THEN ''Faixa Marrom < 20 min''
      WHEN tempo_total < TIME ''00:22:00'' THEN ''Faixa Vermelha < 22 min''
      WHEN tempo_total < TIME ''00:25:00'' THEN ''Faixa Azul < 25 min''
      WHEN tempo_total < TIME ''00:27:00'' THEN ''Faixa Amarela < 27 min''
      WHEN tempo_total < TIME ''00:30:00'' THEN ''Faixa Laranja < 30 min''
      ELSE ''Faixa Branca > 30 min''
    END AS faixa_tempo,

    COUNT(*) FILTER (
      WHERE idade_range && int4range(20, 29, ''[)'')
    ) AS total_20_29,

    COUNT(*) FILTER (
      WHERE idade_range && int4range(30, 39, ''[)'')
    ) AS total_30_39,

    COUNT(*) FILTER (
      WHERE idade_range && int4range(40, 49, ''[)'')
    ) AS total_40_49,

    COUNT(*) FILTER (
      WHERE idade_range && int4range(50, 59, ''[)'')
    ) AS total_50_59,

    COUNT(*) FILTER (
      WHERE idade_range && int4range(60, 69, ''[)'')
    ) AS total_60_69,

    COUNT(*) AS total_geral

  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE res.percurso = 5
    AND res.pcd = false
    AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    -- AND res.sexo = ''M''
    AND idade_range IS NOT NULL
    AND (evt.ranking IS NULL OR evt.ranking <> ''false'')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN ''Mestre < 15 min'' THEN 8
    WHEN ''Faixa Preta < 17 min'' THEN 7
    WHEN ''Faixa Marrom < 20 min'' THEN 6
    WHEN ''Faixa Vermelha < 22 min'' THEN 5
    WHEN ''Faixa Azul < 25 min'' THEN 4
    WHEN ''Faixa Amarela < 27 min'' THEN 3
    WHEN ''Faixa Laranja < 30 min'' THEN 2
    ELSE 1
  END;
',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_COLAB_CNA.sql", "sha256_copia": "181ffe8d26cf80ca7610a6d9a791b6b2b36fbbe1aa1bde59eec6ce4ff19552aa", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_COLAB_CNA.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_DISTANCIAS.sql',10,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_DISTANCIAS.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_DISTANCIAS.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_DISTANCIAS.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: 4c46063fe0c758da2f0ec7a250bdc6b5c932f37a0122937ff5888b682b712842',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_DISTANCIAS.sql", "sha256_copia": "4c46063fe0c758da2f0ec7a250bdc6b5c932f37a0122937ff5888b682b712842", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_DISTANCIAS.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_DISTANCIAS.sql'),2,'code','sql','-- TOTAL DE CONCLUINTES POR DISTANCIA (TODAS)
SELECT
  FLOOR(res.percurso) AS percurso,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND evt.pais = ''BR''
AND tipo_corrida = ''rua''
GROUP BY FLOOR(res.percurso)
ORDER BY total DESC;


-- TOTAL DE CONCLUINTES POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END;


-- TOTAL DE PROVAS POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN ''21''
      WHEN res.percurso IN (42, 42.2) THEN ''42''
      WHEN res.percurso IN (5, 5.00) THEN ''5''
      WHEN res.percurso IN (10, 10.00) THEN ''10''
      WHEN res.percurso IN (15) THEN ''15''
      WHEN res.percurso IN (30) THEN ''30''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_evento
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(distinct id_evento) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF((select count(distinct res_int.id_evento) from vw_resultados res_int
  JOIN tb_evento_corridas evt_int
    ON evt_int.id_evento = res_int.id_evento
  WHERE evt_int.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt_int.pais = ''BR''
    --AND res_int.sexo = ''F''
    and evt_int.tipo_corrida = ''rua''), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5''  THEN 1
    WHEN percurso_bucket = ''10'' THEN 2
    WHEN percurso_bucket = ''15'' THEN 3
    WHEN percurso_bucket = ''21'' THEN 4
    WHEN percurso_bucket = ''30'' THEN 5
    WHEN percurso_bucket = ''42'' THEN 6
    ELSE 99
  END;


-- TOTAL DE CONCLUINTES POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- TOTAL DE PROVAS POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_evento
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(distinct id_evento) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;

-- TOTAL DE PROVAS POR RANGES / ESTADO (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_evento,
    evt.estado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    estado,
    COUNT(distinct id_evento) AS total
  FROM base
  GROUP BY percurso_bucket, estado
)
SELECT
  percurso_bucket AS percurso,
  estado,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END,
  estado;



-- TOTAL DE PROVAS POR RANGES x GENEROS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    res.sexo
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.sexo IN (''M'', ''F'')
),
agg AS (
  SELECT
    sexo,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY sexo,percurso_bucket
)
SELECT
  sexo,
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''< 6''  THEN 0
    WHEN percurso_bucket = ''6-11''  THEN 1
    WHEN percurso_bucket = ''11-30'' THEN 2
    WHEN percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- TOTAL DE PROVAS POR RANGES x GENEROS STACKED 100% (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    res.sexo
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.sexo IN (''M'', ''F'')
),
agg AS (
  SELECT
    sexo,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY sexo,percurso_bucket
),
agg_percurso AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total_percurso
  FROM base
  GROUP BY sexo,percurso_bucket
)
SELECT
  agg.sexo,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where percurso_bucket = agg.percurso_bucket), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN agg.percurso_bucket = ''< 6''  THEN 0
    WHEN agg.percurso_bucket = ''6-11''  THEN 1
    WHEN agg.percurso_bucket = ''11-30'' THEN 2
    WHEN agg.percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- TOTAL DE PROVAS POR RANGES x GENEROS STACKED 100% (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY percurso_bucket
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where percurso_bucket = agg.percurso_bucket), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  CASE
    WHEN agg.percurso_bucket = ''< 6''  THEN 0
    WHEN agg.percurso_bucket = ''6-11''  THEN 1
    WHEN agg.percurso_bucket = ''11-30'' THEN 2
    WHEN agg.percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- DISTRIBUICAO DAS GERACOES NAS DISTANCIAS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN ''< 6''
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN ''6-11''
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN ''11-30''
      WHEN res.percurso >= 30 THEN ''30+''
      ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado,
    get_id_geracao(res.idade_range,EXTRACT(YEAR FROM evt.data_final)::int) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    and tipo_corrida = ''rua''
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    id_geracao,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where id_geracao = agg.id_geracao), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  geracao,
  CASE
    WHEN agg.percurso_bucket = ''< 6''  THEN 0
    WHEN agg.percurso_bucket = ''6-11''  THEN 1
    WHEN agg.percurso_bucket = ''11-30'' THEN 2
    WHEN agg.percurso_bucket = ''30+'' THEN 3
    ELSE 99
  END;


-- 5k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:20:00''::time THEN ''5k Sub 20''
      WHEN res.tempo_total > ''00:20:00''::time AND  res.tempo_total <= ''00:25:00''::time THEN ''5k 20-25''
      WHEN res.tempo_total > ''00:25:00''::time AND  res.tempo_total <= ''00:30:00''::time THEN ''5k 25-30''
      ELSE ''5k 30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 5
    AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''5k Sub 20''  THEN 1
    WHEN percurso_bucket = ''5k 20-25''   THEN 2
    WHEN percurso_bucket = ''5k 25-30''   THEN 3
    ELSE 99
  END;


-- 10k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''00:40:00''::time THEN ''10k Sub 40''
      WHEN res.tempo_total > ''00:40:00''::time AND  res.tempo_total <= ''00:50:00''::time THEN ''10k 40-50''
      WHEN res.tempo_total > ''00:50:00''::time AND  res.tempo_total <= ''01:00:00''::time THEN ''10k 50-60''
      ELSE ''10k 60+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso = 10
    AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''10k Sub 40''  THEN 5
    WHEN percurso_bucket = ''10k 40-50''   THEN 6
    WHEN percurso_bucket = ''10k 50-60''   THEN 7
    ELSE 8
  END;


-- 21k
WITH base AS (
SELECT
CASE
  WHEN res.tempo_total <= ''01:30:00''::time THEN ''21k Sub 01:30''
  WHEN res.tempo_total > ''01:30:00''::time AND  res.tempo_total <= ''02:00:00''::time THEN ''21k 1h30 - 2h''
  WHEN res.tempo_total > ''02:00:00''::time AND  res.tempo_total <= ''02:30:00''::time THEN ''21k 2h - 2h30''
  ELSE ''21k 2h30+''
END AS percurso_bucket,
res.tempo_total,
res.id_resultado
FROM vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
AND evt.pais = ''BR''
AND res.percurso >= 21
AND res.percurso <  22
AND res.sexo = ''M''
and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''21k Sub 01:30''  THEN 1
    WHEN percurso_bucket = ''21k 1h30 - 2h''   THEN 2
    WHEN percurso_bucket = ''21k 2h - 2h30''   THEN 3
    ELSE 4
  END;

-- 42k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= ''03:00:00''::time THEN ''42k Sub 3h''
      WHEN res.tempo_total > ''03:00:00''::time AND  res.tempo_total <= ''03:30:00''::time THEN ''42k 3h - 3h30''
      WHEN res.tempo_total > ''03:30:00''::time AND  res.tempo_total <= ''04:00:00''::time THEN ''42k 3h30 - 4h''
      WHEN res.tempo_total > ''04:00:00''::time AND  res.tempo_total <= ''04:30:00''::time THEN ''42k 4h - 4h30''
      ELSE ''42k 4h30+''
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    AND res.percurso >= 42
    AND res.percurso <  43
    AND res.sexo = ''M''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''42k Sub 3h''  THEN 1
    WHEN percurso_bucket = ''42k 3h - 3h30''   THEN 2
    WHEN percurso_bucket = ''42k 3h30 - 4h''   THEN 3
    WHEN percurso_bucket = ''42k 4h - 4h30''   THEN 4
    ELSE 5
  END;


',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_DISTANCIAS.sql", "sha256_copia": "4c46063fe0c758da2f0ec7a250bdc6b5c932f37a0122937ff5888b682b712842", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_DISTANCIAS.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_INUTEIS.sql',11,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_INUTEIS.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_INUTEIS.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_INUTEIS.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: a8345284edbc86fdf10eae8996c5cf1d841fc3a4938decefb42d3fc2f5564485',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_INUTEIS.sql", "sha256_copia": "a8345284edbc86fdf10eae8996c5cf1d841fc3a4938decefb42d3fc2f5564485", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_INUTEIS.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_INUTEIS.sql'),2,'code','sql','-- TOTAL DE CONCLUINTES POR DISTANCIA (QUEBRADA x NORMAL)
WITH base AS (
  SELECT
    CASE
        WHEN res.percurso IN (21, 21.1) THEN ''21''
        WHEN res.percurso IN (42, 42.2) THEN ''42''
        WHEN res.percurso::varchar like ''%.%'' THEN ''Quebrado''
        WHEN res.percurso::varchar NOT like ''%.%'' THEN ''Normal''
        ELSE ''Outras''
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evt.pais = ''BR''
    --AND res.sexo = ''F''
    and tipo_corrida = ''rua''
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 4) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = ''Quebrado''  THEN 1
    WHEN percurso_bucket = ''Normal'' THEN 2
    WHEN percurso_bucket = ''21'' THEN 3
    WHEN percurso_bucket = ''42'' THEN 4
    ELSE 99
  END;
',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_INUTEIS.sql", "sha256_copia": "a8345284edbc86fdf10eae8996c5cf1d841fc3a4938decefb42d3fc2f5564485", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_INUTEIS.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_MARATONAS.sql',12,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_MARATONAS.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_MARATONAS.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_MARATONAS.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: b6e34a398fdd646924cd6ded9231e1dea790915505fdc0ca669aeaec117782e6',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_MARATONAS.sql", "sha256_copia": "b6e34a398fdd646924cd6ded9231e1dea790915505fdc0ca669aeaec117782e6", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_MARATONAS.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_MARATONAS.sql'),2,'code','sql','select evt.id_evento, evt.nome_evento, count(*) as concluintes
FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
where res.percurso between 42 and 42.2
and res.pcd = false
AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
and evt.pais = ''BR'' and tipo_corrida = ''rua''
and (evt.ranking is null OR evt.ranking <> ''false'')
group by evt.id_evento, evt.nome_evento;

-- RAPIDAS 42K Masc - sem PCD
WITH tot AS (
SELECT
    id_evento,
    percurso,
    sexo,
    count(*) as tot_atletas
FROM
    tb_resultados
where
    id_evento IN (24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
    --(select agrr.id_evento from tb_agregadores_eventos agrr JOIN tb_evento_corridas evt ON evt.id_evento = agrr.id_evento where agregador_tag = ''contra-relogio'' AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31'')
    AND modalidade NOT ILIKE ''%CADEIRANTE%''
    AND modalidade NOT ILIKE ''%PCD%''
    AND modalidade NOT ILIKE ''%DI%''
    AND modalidade NOT ILIKE ''%DMAI%''
    AND modalidade NOT ILIKE ''%DMS%''
    AND modalidade NOT ILIKE ''%HAND%''
    AND modalidade NOT ILIKE ''%BIKE%''
    AND modalidade NOT ILIKE ''%ACD%''
    AND percurso between 42 and 42.99
GROUP BY
    id_evento,
    percurso,
    sexo
)
select
    res.id_evento,
    evt.nome_evento,
    res.percurso,
    res.sexo,
    count(*) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0) as concluintes,
    count(*) as inscritos,
    min(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_menor,
    min(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null) as tempo_menor,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null)::time as pace_medio,
    (
      make_interval(secs =>
        percentile_cont(0.5)
        WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM pace)
        )
        FILTER (
          WHERE res.homologado = true
            AND concluinte = true
            AND status_final = 0
            AND pace IS NOT NULL
        )
      )
    )::time AS pace_mediano,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null)::time as tempo_medio,
    (
      make_interval(secs =>
        percentile_cont(0.5)
        WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM tempo_total)
        )
        FILTER (
          WHERE res.homologado = true
            AND concluinte = true
            AND status_final = 0
            AND tempo_total IS NOT NULL
        )
      )
    )::time AS tempo_mediano,
    max(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_maior,
    max(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null) as tempo_maior,
    -- TOP
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10  or classificacao_sexo <= 10))::time as pace_medio_top_10,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100 or classificacao_sexo <= 100))::time as pace_medio_top_100,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.05) or classificacao_sexo <= (tot_atletas * 0.05)))::time as pace_medio_5_porcento,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.10) or classificacao_sexo <= (tot_atletas * 0.10)))::time as pace_medio_10_porcento,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.50) or classificacao_sexo <= (tot_atletas * 0.50)))::time as pace_medio_50_porcento,
    (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_a,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_a_concluintes,
    (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_b,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_b_concluintes,
    (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_elite,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_elite_concluintes,
    percentile_cont(0.5) within group (order by pace asc) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null)::time as percentil,
    ( select percentile_cont(0.5) within group (order by pace asc)
      from tb_resultados ris
      where ris.id_evento = res.id_evento and
      ris.percurso = res.percurso and
      ris.sexo = res.sexo and
      ris.pace >= ( select percentile_cont(0.1) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.sexo = res.sexo ) and
      ris.pace <= ( select percentile_cont(0.7) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso and r1.sexo = res.sexo )
    )::time as percentil_sem_desvio
from tb_resultados res
    inner join tot on tot.id_evento = res.id_evento and tot.percurso = res.percurso and tot.sexo = res.sexo
    inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
    where res.id_evento IN (24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
    -- FILTROS
    AND res.percurso between 42 and 42.99
    --AND res.homologado = true and concluinte = true and status_final = 0
    AND modalidade NOT ILIKE ''%CADEIRANTE%''
    AND modalidade NOT ILIKE ''%PCD%''
    AND modalidade NOT ILIKE ''%DI%''
    AND modalidade NOT ILIKE ''%DMAI%''
    AND modalidade NOT ILIKE ''%DMS%''
    AND modalidade NOT ILIKE ''%HAND%''
    AND modalidade NOT ILIKE ''%BIKE%''
    AND modalidade NOT ILIKE ''%ACD%''
    group by res.id_evento,evt.nome_evento,res.percurso,res.sexo;


UPDATE tb_resultados SET pace = (tempo_total::time / 42.195::numeric) where id_evento IN (24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) and percurso between 42 and 42.99;
select * from tb_resultados where id_evento = 24999 and percurso between 42 and 42.99 order by pace desc;



WITH tot AS (
SELECT
    id_evento,
    percurso,
    count(*) as tot_atletas
FROM
    tb_resultados
where
    id_evento IN (24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
    --(select agrr.id_evento from tb_agregadores_eventos agrr JOIN tb_evento_corridas evt ON evt.id_evento = agrr.id_evento where agregador_tag = ''contra-relogio'' AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31'')
    AND modalidade NOT ILIKE ''%CADEIRANTE%''
    AND modalidade NOT ILIKE ''%PCD%''
    AND modalidade NOT ILIKE ''%DI%''
    AND modalidade NOT ILIKE ''%DMAI%''
    AND modalidade NOT ILIKE ''%DMS%''
    AND modalidade NOT ILIKE ''%HAND%''
    AND modalidade NOT ILIKE ''%BIKE%''
    AND modalidade NOT ILIKE ''%ACD%''
    AND percurso between 42 and 42.99
GROUP BY
    id_evento,
    percurso
)
select
    res.id_evento,
    evt.nome_evento,
    res.percurso,
    '''' as sexo,
    count(*) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0) as concluintes,
    count(*) as inscritos,
    min(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_menor,
    min(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null) as tempo_menor,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null)::time as pace_medio,
    (
      make_interval(secs =>
        percentile_cont(0.5)
        WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM pace)
        )
        FILTER (
          WHERE res.homologado = true
            AND concluinte = true
            AND status_final = 0
            AND pace IS NOT NULL
        )
      )
    )::time AS pace_mediano,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null)::time as tempo_medio,
    (
      make_interval(secs =>
        percentile_cont(0.5)
        WITHIN GROUP (
          ORDER BY EXTRACT(EPOCH FROM tempo_total)
        )
        FILTER (
          WHERE res.homologado = true
            AND concluinte = true
            AND status_final = 0
            AND tempo_total IS NOT NULL
        )
      )
    )::time AS tempo_mediano,
    max(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null) as pace_maior,
    max(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null) as tempo_maior,
    -- TOP
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 10 ))::time as pace_medio_top_10,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null and ( classificacao_total <= 10 ))::time as tempo_medio_top_10,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= 100))::time as pace_medio_top_100,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null and ( classificacao_total <= 100))::time as tempo_medio_top_100,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.05) ))::time as pace_medio_5_porcento,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null and ( classificacao_total <= (tot_atletas * 0.05) ))::time as tempo_medio_5_porcento,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.10) ))::time as pace_medio_10_porcento,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null and ( classificacao_total <= (tot_atletas * 0.10) ))::time as tempo_medio_10_porcento,
    avg(pace) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null and ( classificacao_total <= (tot_atletas * 0.50) ))::time as pace_medio_50_porcento,
    avg(tempo_total) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total is not null and ( classificacao_total <= (tot_atletas * 0.50) ))::time as tempo_medio_50_porcento,
    (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_a,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_a from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_a_concluintes,
    (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_b,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_b from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_b_concluintes,
    (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null) order by case when id_evento is null then 1 else 0 end limit 1) as limite_elite,
    count(*)  FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and tempo_total < (select limite_elite from tb_resultados_resumo_limites where percurso = res.percurso and (id_evento = res.id_evento or id_evento is null))  ) as limite_elite_concluintes,
    percentile_cont(0.5) within group (order by pace asc) FILTER (WHERE res.homologado = true and concluinte=true and status_final=0 and pace is not null)::time as percentil,
    ( select percentile_cont(0.5) within group (order by pace asc)
      from tb_resultados ris
      where ris.id_evento = res.id_evento and
      ris.percurso = res.percurso and
      ris.pace >= ( select percentile_cont(0.1) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso ) and
      ris.pace <= ( select percentile_cont(0.7) within group (order by pace asc) from tb_resultados r1 where r1.id_evento = res.id_evento and r1.percurso = res.percurso )
    )::time as percentil_sem_desvio
from tb_resultados res
    inner join tot on tot.id_evento = res.id_evento and tot.percurso = res.percurso
    inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
    where res.id_evento IN (24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
    -- FILTROS
    AND res.percurso between 42 and 42.99
    --AND res.homologado = true and concluinte = true and status_final = 0
    AND modalidade NOT ILIKE ''%CADEIRANTE%''
    AND modalidade NOT ILIKE ''%PCD%''
    AND modalidade NOT ILIKE ''%DI%''
    AND modalidade NOT ILIKE ''%DMAI%''
    AND modalidade NOT ILIKE ''%DMS%''
    AND modalidade NOT ILIKE ''%HAND%''
    AND modalidade NOT ILIKE ''%BIKE%''
    AND modalidade NOT ILIKE ''%ACD%''
    group by res.id_evento,evt.nome_evento,res.percurso;

',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_MARATONAS.sql", "sha256_copia": "b6e34a398fdd646924cd6ded9231e1dea790915505fdc0ca669aeaec117782e6", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_MARATONAS.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_MERCADO.sql',13,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_MERCADO.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_MERCADO.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_MERCADO.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: 9448a2eb8108ae7caf78a20e613c59b4dea8eb40291de5baa10611e1c51323ef',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_MERCADO.sql", "sha256_copia": "9448a2eb8108ae7caf78a20e613c59b4dea8eb40291de5baa10611e1c51323ef", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_MERCADO.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_MERCADO.sql'),2,'code','sql','-- SYMPLA
select nome_evento, cidade, estado, url_hotsite, url_inscricao from tb_evento_corridas evt
WHERE evt.data_final BETWEEN DATE ''2026-01-01'' AND DATE ''2026-12-31''
AND  replace(replace(replace(substring(coalesce(evt.url_inscricao,evt.url_hotsite) from ''(?:.*://)?(?:www\.)?([^/?]*)''), ''.com.br'', ''''), ''.com'', ''''), ''site.'', '''') = ''sympla'';


-- SITES DE INSCRICAO
WITH base AS (
  SELECT
    replace(
      replace(
        replace(
          substring(
            coalesce(evt.url_inscricao, evt.url_hotsite)
            from ''(?:.*://)?(?:www\.)?([^/?]*)''
          ),
          ''.com.br'', ''''
        ),
        ''.com'', ''''
      ),
      ''site.'', ''''
    ) AS dominio
  FROM tb_evento_corridas evt
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS total
  FROM base
  WHERE dominio IS NOT NULL
    AND dominio <> ''''
  GROUP BY dominio
)
SELECT
  dominio AS url_inscricao_domain,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM agg
ORDER BY total DESC;


-- SITES DE RESULTADO
WITH base AS (
  SELECT
    replace(
      replace(
        replace(
          substring(
            coalesce(evt.url_resultado, evt.url_resultado)
            from ''(?:.*://)?(?:www\.)?([^/?]*)''
          ),
          ''.com.br'', ''''
        ),
        ''.com'', ''''
      ),
      ''site.'', ''''
    ) AS dominio
  FROM tb_evento_corridas evt
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS total
  FROM base
  WHERE dominio IS NOT NULL
    AND dominio <> ''''
  GROUP BY dominio
)
SELECT
  dominio AS url_resultado_domain,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM agg
ORDER BY total DESC;


-- RESULTADOS POR SITE DE INSCRICAO
WITH base AS (
  SELECT
    replace(
      replace(
        replace(
          substring(
            coalesce(evt.url_inscricao, evt.url_hotsite)
            from ''(?:.*://)?(?:www\.)?([^/?]*)''
          ),
          ''.com.br'', ''''
        ),
        ''.com'', ''''
      ),
      ''site.'', ''''
    ) AS dominio

  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS total
  FROM base
  WHERE dominio IS NOT NULL
    AND dominio <> ''''
  GROUP BY dominio
),
ranked AS (
  SELECT
    dominio,
    total,
    ROW_NUMBER() OVER (ORDER BY total DESC) AS rn
  FROM agg
),
final AS (
  SELECT
    CASE
      WHEN rn <= 10 THEN dominio
      ELSE ''Outros''
    END AS dominio,
    SUM(total) AS total
  FROM ranked
  GROUP BY
    CASE
      WHEN rn <= 10 THEN dominio
      ELSE ''Outros''
    END
)
SELECT
  dominio AS url_inscricao_domain,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    1
  ) AS porcentagem
FROM final
ORDER BY
  CASE WHEN dominio = ''Outros'' THEN 2 ELSE 1 END,
  total DESC;


-- RESULTADOS POR SITE RESULTADO
WITH base AS (
  SELECT
    replace(
      replace(
        replace(
          substring(
            coalesce(evt.url_resultado, evt.url_resultado)
            from ''(?:.*://)?(?:www\.)?([^/?]*)''
          ),
          ''.com.br'', ''''
        ),
        ''.com'', ''''
      ),
      ''site.'', ''''
    ) AS dominio
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS total
  FROM base
  WHERE dominio IS NOT NULL
    AND dominio <> ''''
  GROUP BY dominio
),
ranked AS (
  SELECT
    dominio,
    total,
    ROW_NUMBER() OVER (ORDER BY total DESC) AS rn
  FROM agg
),
final AS (
  SELECT
    CASE
      WHEN rn <= 10 THEN dominio
      ELSE ''Outros''
    END AS dominio,
    SUM(total) AS total
  FROM ranked
  GROUP BY
    CASE
      WHEN rn <= 10 THEN dominio
      ELSE ''Outros''
    END
)
SELECT
  dominio AS url_resultado_domain,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    1
  ) AS porcentagem
FROM final
ORDER BY
  CASE WHEN dominio = ''Outros'' THEN 2 ELSE 1 END,
  total DESC;


-- EQUIPES / GRUPOS / ASSESSORIAS
select upper(unaccent(trim(replace(replace(res.equipe, ''-'', ''''), ''/'', '''')))), count(res.id_resultado) as corredores, count(distinct res.id_evento) as eventos
from vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
where equipe NOT IN ('''',''AVULSO'',''RUNNERS'',''TICKETSPORTS'',''2'',''AVULSO'',''A VULSO'',''AVUSO'',''1'',''SOLO'',''SOZINHO'',''CORRIDA'',''SIM'',''N'',''SYMPLA'',''N�O'',''SOLO'',''GERAL'',''SITE TICKETSPORTS'',''NAO POSSUO'',''PUBLICO GERAL'',''NÃO TEM EQUIPE'',''NAO PARTICIPO'',''NAO INFORMADO'',''TICKET SPORTS'',''M'',''F'',''SITE'',''N/A'',''AVILSO'',''SUA'',''EU'',''NA'',''SEM'',''NÃO TEM'',''NAO TEM'',''---'',''.'',''AVULSA'',''INDIVIDUAL'',''SEM EQUIPE'',''OUTRA'',''EQUIPE'',''NENHUMA'',''--'',''X'',''NÃO'',''-'',''NENHUM'',''NULL'',''NAO'',''NÃO TENHO'',''NAO TENHO'',''0'')
and equipe is not null
AND evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
group by upper(unaccent(trim(replace(replace(res.equipe, ''-'', ''''), ''/'', ''''))))
order by corredores desc;


-- ORGANIZADORES
SELECT
    upper(unaccent(trim(replace(replace(organizador, ''-'', ''''), ''/'', '''')))) AS organizador
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND organizador IS NOT NULL
    AND organizador <> ''''
UNION
SELECT
upper(unaccent(trim(replace(replace(tf.nome_fornecedor, ''-'', ''''), ''/'', '''')))) AS organizador
FROM tb_evento_corridas_fornecedores evtf
JOIN public.tb_fornecedores tf
ON evtf.id_fornecedor = tf.id_fornecedor
JOIN vw_resultados res ON evtf.id_evento = res.id_evento
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
AND evtf.id_fornecedor_tipo = 1;


-- ORGANIZADORES TOP + OUTROS
WITH base AS (
  SELECT
    upper(unaccent(trim(replace(replace(organizador, ''-'', ''''), ''/'', '''')))) AS organizador
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND organizador IS NOT NULL
    AND organizador <> ''''

  UNION ALL

  SELECT
    upper(unaccent(trim(replace(replace(tf.nome_fornecedor, ''-'', ''''), ''/'', '''')))) AS organizador
  FROM tb_evento_corridas_fornecedores evtf
  JOIN public.tb_fornecedores tf
    ON evtf.id_fornecedor = tf.id_fornecedor
  JOIN vw_resultados res ON evtf.id_evento = res.id_evento
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evtf.id_fornecedor_tipo = 1
),
agg AS (
  SELECT organizador, COUNT(*) AS total
  FROM base
  WHERE organizador IS NOT NULL AND organizador <> ''''
  GROUP BY organizador
),
ranked AS (
  SELECT
    organizador,
    total,
    ROW_NUMBER() OVER (ORDER BY total DESC) AS rn
  FROM agg
),
final AS (
  SELECT
    CASE WHEN rn <= 11 THEN organizador ELSE ''Outros'' END AS organizador,
    SUM(total) AS total
  FROM ranked
  GROUP BY CASE WHEN rn <= 11 THEN organizador ELSE ''Outros'' END
)
SELECT
  organizador,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS porcentagem
FROM final
ORDER BY
  CASE WHEN organizador = ''Outros'' THEN 2 ELSE 1 END,
  total DESC;



-- ORGANIZADORES ABERTO
WITH base AS (
  SELECT
    upper(unaccent(trim(replace(replace(organizador, ''-'', ''''), ''/'', '''')))) AS organizador
  FROM tb_evento_corridas evt
  WHERE evt.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND organizador IS NOT NULL
    AND organizador <> ''''

  UNION ALL

  SELECT
    upper(unaccent(trim(replace(replace(tf.nome_fornecedor, ''-'', ''''), ''/'', '''')))) AS organizador
  FROM tb_evento_corridas_fornecedores evtf
  JOIN public.tb_fornecedores tf
    ON evtf.id_fornecedor = tf.id_fornecedor
  JOIN public.tb_evento_corridas tec
    ON tec.id_evento = evtf.id_evento
  WHERE tec.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
    AND evtf.id_fornecedor_tipo = 1
    AND tf.nome_fornecedor IS NOT NULL
    AND tf.nome_fornecedor <> ''''
),
agg AS (
  SELECT organizador, COUNT(*) AS total
  FROM base
  WHERE organizador IS NOT NULL AND organizador <> ''''
  GROUP BY organizador
)
SELECT
  organizador,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS porcentagem
FROM agg
ORDER BY total DESC, organizador;
',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_MERCADO.sql", "sha256_copia": "9448a2eb8108ae7caf78a20e613c59b4dea8eb40291de5baa10611e1c51323ef", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_MERCADO.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_PERSONAS.sql',14,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_PERSONAS.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_PERSONAS.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_PERSONAS.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: 86057d7b9a98fd016297b9f35fa77c029292b54604d2d466d7126de59ce894c1',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_PERSONAS.sql", "sha256_copia": "86057d7b9a98fd016297b9f35fa77c029292b54604d2d466d7126de59ce894c1", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_PERSONAS.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_PERSONAS.sql'),2,'code','sql','
select
case
    when position(''ANDERSON'' in nome) > 0 then ''JUNINHO''
    when position(''PENZ'' in nome) > 0 then ''ISA''
    when position(''LETICIA'' in nome) > 0 then ''LIA''
    when position(''FASSBINDER'' in nome) > 0 then ''FATINHA''
    when position(''HIDEKI'' in nome) > 0 then ''JAPA''
end  as apelido,
    nome,round(percurso,0)::integer as percurso,count(*) as soma from vw_resultados res
                                   inner join tb_evento_corridas eve on eve.id_evento = res.id_evento
where id_usuario in (21848,18917,19317,6146,83785)
and eve.data_inicial between ''2025-01-01'' and ''2025-12-31''
and percurso > 30
group by apelido,nome,percurso
order by nome,percurso,soma;



select
case
    when position(''ANDERSON'' in nome) > 0 then ''JUNINHO''
    when position(''PENZ'' in nome) > 0 then ''ISA''
    when position(''LETICIA'' in nome) > 0 then ''LIA''
    when position(''FASSBINDER'' in nome) > 0 then ''FATINHA''
    when position(''HIDEKI'' in nome) > 0 then ''JAPA''
end  as apelido,
    round(percurso,0)::integer as percurso,count(*) as soma from vw_resultados res
                                   inner join tb_evento_corridas eve on eve.id_evento = res.id_evento
where id_usuario in (21848,18917,19317,6146,83785)
and eve.data_inicial between ''2025-01-01'' and ''2025-12-31''
-- and percurso > 30
group by apelido,percurso
order by apelido,percurso,soma;
',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_PERSONAS.sql", "sha256_copia": "86057d7b9a98fd016297b9f35fa77c029292b54604d2d466d7126de59ce894c1", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_PERSONAS.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebooks(notebook_title,call_order,caderno_id,source_key) VALUES('DataGrip · INFOGRAFICO_USUARIO.sql',15,(SELECT id FROM estudo.cadernos WHERE source_key='sources-2025-v1'),'datagrip-2025-INFOGRAFICO_USUARIO.sql') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_USUARIO.sql'),1,'markdown','','## Fonte DataGrip: INFOGRAFICO_USUARIO.sql

Cópia fornecida no início da reconstrução do estudo. Sem comprovação de que seja a última revisão usada no PDF. Conteúdo preservado como referência.

SHA-256 da cópia: 6a6fa7009fd05203d4a1e13640aafab3864fe568117018f25faa3c3c720a0007',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_USUARIO.sql", "sha256_copia": "6a6fa7009fd05203d4a1e13640aafab3864fe568117018f25faa3c3c720a0007", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_USUARIO.sql-cell-1') ON CONFLICT(source_key) DO NOTHING;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) VALUES((SELECT notebook_id FROM estudo.notebooks WHERE source_key='datagrip-2025-INFOGRAFICO_USUARIO.sql'),2,'code','sql','-- ESPORTES MAIS PRATICADOS
SELECT
  act.type,
  COUNT(*) AS total,
  ROUND(
    COUNT(*) * 100.0
    / NULLIF(SUM(COUNT(*)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_strava_activities act
WHERE act.activity_date BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND act.type IS NOT NULL
GROUP BY act.type
ORDER BY total DESC;



-- ATIVIDADES DE CORRIDA POR MES
SELECT
  EXTRACT(MONTH FROM coalesce(activity_date,start_date))::int AS mes,
  COUNT(*) AS total, sum(distance/1000)::int
FROM tb_strava_activities act
WHERE type IN (''Run'',''VirtualRun'',''Walk'') and distance < 2000000
GROUP BY mes
ORDER BY mes;



-- DISTANCIA POR ESPORTE
SELECT act.type, sum(distance/1000)::int as total
from tb_strava_activities act
WHERE act.activity_date BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
and type is not null
group by act.type
order by total desc;

SELECT
    act.type,
    COUNT(*) as atividades,
    SUM(distance/1000)::int AS total_km,
    ROUND(SUM(distance/1000)::numeric / COUNT(*), 2) AS km_por_atividade,
    ROUND(SUM(act.moving_time/60)::numeric / COUNT(*), 2) AS moving_time_por_atividade
FROM tb_strava_activities act
WHERE act.activity_date BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND act.type IS NOT NULL
  AND (
    strava_raw ->> ''aspect_type'' IS NULL
    OR strava_raw ->> ''aspect_type'' <> ''delete''
)
GROUP BY act.type
ORDER BY total_km DESC;

SELECT
    act.type,
    COUNT(*) AS atividades,
    SUM(distance / 1000)::int AS total_km,
    ROUND(SUM(distance / 1000)::numeric / COUNT(*), 2) AS km_por_atividade,
    ROUND(SUM(act.moving_time / 60)::numeric / COUNT(*), 2) AS moving_time_por_atividade,
    ROUND(
        percentile_cont(0.25) WITHIN GROUP (ORDER BY act.moving_time) / 60.0,
        2
    ) AS mediana_moving_time_por_atividade25,
    ROUND(
        percentile_cont(0.5) WITHIN GROUP (ORDER BY act.moving_time) / 60.0,
        2
    ) AS mediana_moving_time_por_atividade50,
    ROUND(
        percentile_cont(0.75) WITHIN GROUP (ORDER BY act.moving_time) / 60.0,
        2
    ) AS mediana_moving_time_por_atividade75
FROM tb_strava_activities act
WHERE act.activity_date BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
  AND act.type IS NOT NULL
  AND (
    strava_raw ->> ''aspect_type'' IS NULL
    OR strava_raw ->> ''aspect_type'' <> ''delete''
)
GROUP BY act.type
ORDER BY total_km DESC;



-- ATIVIDADES POR SEMANA
SELECT
  EXTRACT(WEEK FROM coalesce(activity_date,start_date))::int AS semana,
  COUNT(*) AS total, sum(distance/1000)::int
FROM tb_strava_activities act
WHERE type IN (''Run'',''VirtualRun'') and distance < 2000000
and coalesce(activity_date,start_date) between ''2025-01-01'' and ''2025-12-31''
GROUP BY semana
order by semana;

-- ATIVIDADES POR SEMANA (SEM O POVO DO DESAFIO)
SELECT
  EXTRACT(WEEK FROM coalesce(activity_date,start_date))::int AS semana,
  COUNT(*) AS total, sum(distance/1000)::int
FROM tb_strava_activities act
WHERE type IN (''Run'',''VirtualRun'',''Walk'') and distance < 2000000
and coalesce(activity_date,start_date) between ''2025-01-01'' and ''2025-12-31''
and not exists (
    select strava_id from tb_usuarios usu
    inner join  desafios des on usu.id = des.id_usuario
 where strava_id is not null
 and  des.desafio = ''desafio365'' and status <> ''C''
 and  act.athlete_id = usu.strava_id
)
group by semana;




select *  from vwbi_fat_perfil_br_2025



',CAST('{"tipo": "fonte_datagrip", "arquivo": "INFOGRAFICO_USUARIO.sql", "sha256_copia": "6a6fa7009fd05203d4a1e13640aafab3864fe568117018f25faa3c3c720a0007", "registrado_em": "2026-09-28"}' AS jsonb),'datagrip-2025-INFOGRAFICO_USUARIO.sql-cell-2') ON CONFLICT(source_key) DO NOTHING;
