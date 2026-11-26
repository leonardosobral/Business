"""Offline authoring helper for the reviewable DataGrip SQL files. No DB client."""
from pathlib import Path
import hashlib,json,re
W=Path(__file__).resolve().parent
M=W.parent/'dba-load-review/current-metadata.json'
D=Path('/Users/leonardosobral/Downloads/script_perfil_br_corre_2026.sql')
meta=json.loads(M.read_text())
assert hashlib.sha256(D.read_bytes()).hexdigest()=='d9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08'
FACT='estudo.fat_perfil_br_2026_20261109'
AUDIT='estudo.fat_perfil_br_2026_20261109_audit'
BI='estudo.vwbi_perfil_br_2026_20261109'
RESULT='estudo.vw_resultados_2026_20261109'
COLUMNS=[('id_fat_perfil_br_2026','integer'),('id_data','integer'),('id_localidade','integer'),('id_evento','integer'),('id_organizador','integer'),('id_cronometrador','integer'),('id_resultado','integer'),('id_geracao','integer'),('id_cbat_categoria','integer'),('id_faixa','integer'),('data_evento','date'),('percurso','numeric'),('sexo','varchar(1)'),('tempo_total','time without time zone'),('idade_range','int4range'),('id_usuario','integer'),('id_atleta_strava','integer'),('pcd','boolean'),('evento_homologado','boolean'),('resultado_homologado','boolean')]
DIMS=[('tbbi_dim_data','id_data'),('tbbi_dim_localidade','id_localidade'),('tbbi_dim_geracoes','id_geracao'),('tbbi_dim_faixas','id_faixa'),('tbbi_dim_cbat_categorias','id_cbat_categoria'),('tbbi_dim_organizacao_2026','id_organizacao'),('tbbi_dim_cronometragem','id_cronometragem')]
PUBLIC_VIEW='public.vwbi_fat_perfil_br_2026'
VIEW_OLD={k if '.' in k else 'public.'+k:v for k,v in meta['views'].items()}
FUNCTIONS={f['identity']:f['hash'] for f in meta['functions']}
q=lambda s:"'"+str(s).replace("'","''")+"'"
sha=lambda s:hashlib.sha256(s.encode()).hexdigest()
md5=lambda s:hashlib.md5(s.encode()).hexdigest()
write=lambda name,s:(W/name).write_text(s.rstrip()+'\n')
ENTRY_PREFACE=('-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.\n'
               '-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.\n'
               '-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.\n')
def secure_entry(sql):
    sql=sql.replace('BEGIN;','BEGIN ISOLATION LEVEL REPEATABLE READ;',1)
    sql=sql.replace('SET LOCAL search_path=pg_catalog,public;',
                    'SET LOCAL search_path=pg_catalog,public;\nSET LOCAL standard_conforming_strings=on;',1)
    marker='DO $guard$\nBEGIN\n'
    guard=" IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION 'A sessão não está em REPEATABLE READ; encerre a transação anterior'; END IF;\n"
    assert marker in sql
    return ENTRY_PREFACE+sql.replace(marker,marker+guard,1)

raw="""SELECT r.id_resultado,r.id_evento,r.percurso,r.sexo,r.tempo_total,
 r.idade_range,r.data_nascimento,r.id_usuario,r.pcd,
 r.homologado AS resultado_homologado,r.concluinte,r.status_final,r.modalidade,
 e.data_final,e.data_inicial,e.estado,e.cidade,e.organizador,
 e.homologado AS evento_homologado,e.tipo_corrida
FROM public.tb_resultados r
JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR'
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE"""
lookup="""lookup_data AS (
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
)"""
normalized="""SELECT row_number() OVER(ORDER BY r.id_resultado)::integer AS id_fat_perfil_br_2026,
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
LEFT JOIN lookup_strava st ON st.id=r.id_usuario AND r.id_usuario<>0"""
source="-- CANDIDATO SELECT: universo Q3 vigente, todas as idades/modalidades.\n-- Sem DDL/DML. Dados individuais apenas na projeção interna; para evidência use agregados/EXPLAIN.\nWITH fonte AS MATERIALIZED (\n"+raw+'\n), '+lookup+'\n'+normalized
write('source-select.sql',source+';')
function_values=','.join('('+q('public.'+identity)+','+q(h)+')' for identity,h in FUNCTIONS.items())
view_values=','.join('('+q(name)+','+q(md5(body))+')' for name,body in VIEW_OLD.items())
function_guard="""IF EXISTS(SELECT 1 FROM (VALUES "+function_values+") f(signature,expected) WHERE to_regprocedure(signature) IS NULL OR md5(pg_get_functiondef(to_regprocedure(signature))) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'Função mudou ou assinatura ausente; releia antes da carga'; END IF;"""
view_guard="""IF EXISTS(SELECT 1 FROM (VALUES "+view_values+") v(name,expected) WHERE to_regclass(name) IS NULL OR md5(pg_get_viewdef(to_regclass(name),true)) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'View vigente mudou; releia antes de prosseguir'; END IF;"""
dim_union=' UNION ALL '.join("SELECT "+q(t)+" AS dimension,count(*) AS duplicate_keys FROM (SELECT "+c+" FROM public."+t+" WHERE "+c+" IS NOT NULL GROUP BY "+c+" HAVING count(*)>1)d" for t,c in DIMS)
# One SELECT JSON: no transaction settings, DO blocks or writes.
preflight="""-- CANDIDATO READ ONLY: um único SELECT JSON agregado, sem PII.
WITH fonte AS MATERIALIZED (
"""+raw+"""
), nulls AS (
 SELECT count(*) AS eligible,count(DISTINCT id_resultado) AS unique_results,
 count(*) FILTER(WHERE id_resultado IS NULL) AS null_id,
 count(*) FILTER(WHERE sexo IS NULL) AS null_sex,
 count(*) FILTER(WHERE length(sexo)>1) AS sex_over_varchar1,
 count(*) FILTER(WHERE percurso IS NULL) AS null_distance,
 count(*) FILTER(WHERE pcd IS NULL) AS null_pcd,
 count(*) FILTER(WHERE evento_homologado IS NULL) AS null_event_homologated,
 count(*) FILTER(WHERE evento_homologado IS FALSE) AS false_event_homologated,
 count(*) FILTER(WHERE tempo_total IS NULL) AS null_time,
 count(*) FILTER(WHERE tempo_total=TIME '00:00:00') AS zero_time,
 count(*) FILTER(WHERE modalidade='KIDS') AS kids,
 count(*) FILTER(WHERE modalidade IS NULL) AS null_modality,
 count(*) FILTER(WHERE tipo_corrida NOT IN ('rua','trail') OR tipo_corrida IS NULL) AS other_event_types,
 count(*) FILTER(WHERE data_inicial IS NULL) AS null_start_date
 FROM fonte
), date_keys AS (
 SELECT data_referencia,count(*) AS matches FROM public.tbbi_dim_data GROUP BY data_referencia
), dimensions AS (
"""+dim_union+"""
), months AS (
 SELECT date_trunc('month',data_final)::date AS month,count(*) AS eligible FROM fonte GROUP BY 1
), generations AS (
 SELECT public.get_id_geracao(idade_range,extract(year FROM data_final)::integer,data_nascimento,data_final) AS generation_id,count(*) AS eligible FROM fonte GROUP BY 1
), signatures AS (
 SELECT signature,expected,to_regprocedure(signature) AS oid FROM (VALUES """+function_values+"""
 ) f(signature,expected)
)
SELECT jsonb_build_object(
 'transaction_read_only',current_setting('transaction_read_only'),'actor',current_user,
 'range','[2026-01-01,2026-10-01)','source_script_sha256','d9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08',
 'nulls_and_universe',(SELECT to_jsonb(n) FROM nulls n),
 'months',(SELECT jsonb_agg(to_jsonb(m) ORDER BY month) FROM months m),
 'generation',(SELECT jsonb_agg(to_jsonb(g) ORDER BY generation_id) FROM generations g),
 'duplicate_dimension_ids',(SELECT jsonb_agg(to_jsonb(d) ORDER BY dimension) FROM dimensions d),
 'missing_start_date_dimension',(SELECT count(*) FROM fonte f LEFT JOIN date_keys d ON d.data_referencia=f.data_inicial WHERE coalesce(d.matches,0)=0),
 'ambiguous_start_date_dimension',(SELECT count(*) FROM fonte f JOIN date_keys d ON d.data_referencia=f.data_inicial WHERE d.matches>1),
 'functions',(SELECT jsonb_agg(jsonb_build_object('signature',signature,'expected_md5',expected,'actual_md5',CASE WHEN oid IS NOT NULL THEN md5(pg_get_functiondef(oid)) END,'matches',CASE WHEN oid IS NOT NULL THEN md5(pg_get_functiondef(oid))=expected ELSE false END)) FROM signatures),
 'current_view_columns',(SELECT jsonb_agg(jsonb_build_object('relation',a.attrelid::regclass::text,'position',a.attnum,'name',a.attname,'type',format_type(a.atttypid,a.atttypmod)) ORDER BY a.attrelid,a.attnum) FROM pg_attribute a WHERE a.attrelid IN('estudo.vwbi_perfil_br_2026'::regclass,'estudo.vw_resultados_2026'::regclass) AND a.attnum>0 AND NOT a.attisdropped),
 'can_create_in_estudo',has_schema_privilege(current_user,'estudo','CREATE'),
 'target_exists',to_regclass('"""+FACT+"""') IS NOT NULL
) AS payload;"""
write('00-preflight.sql',preflight)
# Exact current view contracts, only relations are redirected.
bi_body=VIEW_OLD['estudo.vwbi_perfil_br_2026'].strip().rstrip(';')
bi_body,n=re.subn(r'\bFROM\s+(?:public\.)?tbbi_fat_perfil_br_2026\b(?!\.)','FROM '+FACT+' AS tbbi_fat_perfil_br_2026',bi_body,count=1)
assert n==1
bi_body=re.sub(r'LEFT JOIN (tbbi_dim_\w+)\b',r'LEFT JOIN public.\1',bi_body)
result_body=VIEW_OLD['estudo.vw_resultados_2026'].strip().rstrip(';').replace('estudo.vwbi_perfil_br_2026',BI)
result_body=re.sub(r'LEFT JOIN (?:public\.)?tb_resultados\b','LEFT JOIN public.tb_resultados',result_body)
assert 'FROM '+BI+' v' in result_body
create_views='CREATE VIEW '+BI+' AS\n'+bi_body+';\n\nCREATE VIEW '+RESULT+' AS\n'+result_body+';'
contract_pairs=[('estudo.vwbi_perfil_br_2026',BI),('estudo.vw_resultados_2026',RESULT)]
contract_values=','.join('('+q(old)+','+q(new)+')' for old,new in contract_pairs)
contract_guard="""IF EXISTS (
 SELECT 1 FROM (VALUES "+contract_values+") p(old_name,new_name)
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.old_name) AND attnum>0 AND NOT attisdropped) old
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.new_name) AND attnum>0 AND NOT attisdropped) new
 WHERE old.signature IS DISTINCT FROM new.signature
) THEN RAISE EXCEPTION 'Contrato de colunas/tipos/ordem da view mudou'; END IF;"""
# String concatenation in triple-quoted snippets above is intentional authoring:
# render the literal interpolation markers rather than execute SQL.
for name in ['function_guard','view_guard','contract_guard']:
 value=locals()[name]
 for key in ['function_values','view_values','contract_values']:
  value=value.replace('"+atom+"'.replace('atom',key),locals()[key])
 locals()[name]=value
col_list=','.join(c for c,t in COLUMNS)
row_left=','.join('f.'+c for c,t in COLUMNS)
row_right=','.join('n.'+c for c,t in COLUMNS)
quality="""jsonb_build_object('eligible',(SELECT count(*) FROM _bqc_q3_source),
 'fact',(SELECT count(*) FROM "+FACT+"),'null_pcd',(SELECT count(*) FROM "+FACT+" WHERE pcd IS NULL),
 'null_sex',(SELECT count(*) FROM "+FACT+" WHERE sexo IS NULL),'null_distance',(SELECT count(*) FROM "+FACT+" WHERE percurso IS NULL),
 'null_time',(SELECT count(*) FROM "+FACT+" WHERE tempo_total IS NULL),'zero_time',(SELECT count(*) FROM "+FACT+" WHERE tempo_total=TIME '00:00:00'),
 'null_event_homologated',(SELECT count(*) FROM "+FACT+" WHERE evento_homologado IS NULL),
 'unresolved_locality',(SELECT count(*) FROM "+FACT+" WHERE id_localidade=0),
 'missing_date_dimension',(SELECT count(*) FROM "+FACT+" WHERE id_data IS NULL),
 'unresolved_organizer',(SELECT count(*) FROM "+FACT+" WHERE id_organizador=0),
 'unresolved_timer',(SELECT count(*) FROM "+FACT+" WHERE id_cronometrador=0))""".replace('"+FACT+"',FACT)
load="""-- CANDIDATO DATAGRIP. NÃO EXECUTADO. Executar o arquivo inteiro como uma transação.
-- Não usa DROP/TRUNCATE/CASCADE nem escreve em public. Não troca as views vigentes.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path=pg_catalog,public;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='15min';
DO $guard$
BEGIN
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Outra carga Q3 está em curso'; END IF;
 IF to_regclass('"""+FACT+"""') IS NOT NULL OR to_regclass('"""+AUDIT+"""') IS NOT NULL
 OR to_regclass('"""+BI+"""') IS NOT NULL OR to_regclass('"""+RESULT+"""') IS NOT NULL THEN RAISE EXCEPTION 'Versão candidata já existe; não sobrescrever'; END IF;
 """+function_guard+'\n '+view_guard+"""
 IF EXISTS(SELECT 1 FROM ("""+dim_union+"""
 ) d WHERE duplicate_keys>0) THEN RAISE EXCEPTION 'IDs duplicados nas dimensões; left join poderia multiplicar linhas'; END IF;
END;
$guard$;

-- A primeira leitura das tabelas analíticas abaixo e todos os nove meses usam
-- o mesmo snapshot da transação. Flags, sexo/percurso/tempo NULL são conservados.
CREATE TEMP TABLE _bqc_q3_source ON COMMIT DROP AS
"""+raw+""";
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
"""+lookup+'\n'+normalized+""";
CREATE UNIQUE INDEX _bqc_q3_normalized_result_idx ON _bqc_q3_normalized(id_resultado);

CREATE TABLE """+FACT+' (\n '+',\n '.join(c+' '+t+(' PRIMARY KEY' if i==0 else '') for i,(c,t) in enumerate(COLUMNS))+"""\n);
CREATE TABLE """+AUDIT+""" (
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
  INSERT INTO """+FACT+'('+col_list+"""\n  ) SELECT """+col_list+""" FROM _bqc_q3_normalized
  WHERE data_evento>=v_month AND data_evento<(v_month+INTERVAL '1 month')::date;
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  v_monthly=v_monthly||jsonb_build_array(jsonb_build_object('month',v_month,'rows',v_rows));
 END LOOP;
 INSERT INTO """+AUDIT+"""(loaded_at,snapshot_id,source_script_sha256,function_contract,views_before,monthly_rows,quality,status)
 VALUES(clock_timestamp(),txid_current_snapshot()::text,
 'd9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08',
 """+q(json.dumps(FUNCTIONS))+"::jsonb,"+q(json.dumps(VIEW_OLD,ensure_ascii=False))+"::jsonb,v_monthly,'{}'::jsonb,'loading');\nEND;\n$months$;\n"+"CREATE UNIQUE INDEX fat_perfil_br_2026_20261109_result_idx ON "+FACT+"(id_resultado);\nCREATE INDEX fat_perfil_br_2026_20261109_event_idx ON "+FACT+"(id_evento);\nCREATE INDEX fat_perfil_br_2026_20261109_date_idx ON "+FACT+"(data_evento);\n\n"+create_views+"\n\nDO $validate$\nBEGIN\n "+contract_guard+"\n IF (SELECT count(*) FROM "+FACT+")<>(SELECT count(*) FROM _bqc_q3_source) THEN RAISE EXCEPTION 'Conservação de linhas falhou'; END IF;\n IF EXISTS(SELECT 1 FROM "+FACT+" f FULL JOIN _bqc_q3_normalized n USING(id_resultado) WHERE ROW("+row_left+") IS DISTINCT FROM ROW("+row_right+")) THEN RAISE EXCEPTION 'Conservação de valores/flags/NULL falhou'; END IF;\n IF (SELECT count(*) FROM "+BI+")<>(SELECT count(*) FROM "+FACT+") OR (SELECT count(DISTINCT id_resultado) FROM "+BI+")<>(SELECT count(*) FROM "+FACT+") THEN RAISE EXCEPTION 'Fanout/perda no adaptador BI'; END IF;\n IF (SELECT count(*) FROM "+RESULT+")<>(SELECT count(*) FROM "+FACT+") OR (SELECT count(DISTINCT id_resultado) FROM "+RESULT+")<>(SELECT count(*) FROM "+FACT+") THEN RAISE EXCEPTION 'Fanout/perda no adaptador de resultados'; END IF;\n "+function_guard+'\n '+view_guard+"\nEND;\n$validate$;\nUPDATE "+AUDIT+" SET quality="+quality+",status='ready_for_review';\nGRANT SELECT ON "+FACT+','+AUDIT+','+BI+','+RESULT+" TO estudo_reader;\nCOMMENT ON TABLE "+FACT+" IS 'Versão Q3 2026 de 09/11; fonte materializada em snapshot repeatable_read; público preservado; cutover separado.';\nANALYZE "+FACT+";\nSELECT to_jsonb(a) AS load_receipt FROM "+AUDIT+" a;\nCOMMIT;"
monthly_assert="""IF EXISTS (
 WITH expected AS (
  SELECT month::date AS month,count(s.id_resultado) AS n
  FROM generate_series(DATE '2026-01-01',DATE '2026-09-01',INTERVAL '1 month') AS g(month)
  LEFT JOIN _bqc_q3_source s ON s.data_final>=month AND s.data_final<month+INTERVAL '1 month' GROUP BY month
 ), actual AS (
  SELECT (v->>'month')::date AS month,(v->>'rows')::bigint AS n
  FROM "+AUDIT+",jsonb_array_elements(monthly_rows) v
 ) SELECT 1 FROM expected e FULL JOIN actual a USING(month) WHERE e.n IS DISTINCT FROM a.n
) OR (SELECT jsonb_array_length(monthly_rows) FROM "+AUDIT+")<>9 THEN RAISE EXCEPTION 'Conservação mensal dos nove meses falhou'; END IF;
 """.replace('"+AUDIT+"',AUDIT)
load=load.replace("IF (SELECT count(*) FROM "+FACT+")<>(SELECT count(*) FROM _bqc_q3_source)",monthly_assert+"IF (SELECT count(*) FROM "+FACT+")<>(SELECT count(*) FROM _bqc_q3_source)")
load=secure_entry(load)
write('10-load-version.sql',load)
verify="-- CANDIDATO READ ONLY: resumo da versão carregada, sem PII.\nSELECT jsonb_build_object('load',(SELECT to_jsonb(a) FROM "+AUDIT+" a),'fact',(SELECT jsonb_build_object('rows',count(*),'unique_results',count(DISTINCT id_resultado),'min_date',min(data_evento),'max_date',max(data_evento),'null_sex',count(*) FILTER(WHERE sexo IS NULL),'null_distance',count(*) FILTER(WHERE percurso IS NULL),'null_pcd',count(*) FILTER(WHERE pcd IS NULL)) FROM "+FACT+"),'bi_view_rows',(SELECT count(*) FROM "+BI+"),'result_view_rows',(SELECT count(*) FROM "+RESULT+"),'public_view_md5',md5(pg_get_viewdef('"+PUBLIC_VIEW+"'::regclass,true))) AS payload;"
write('20-verify-version.sql',verify)
cutover="""-- CANDIDATO SEPARADO. Só após revisão e controle da carga10.
-- Troca exclusivamente os dois adaptadores do estudo; produto/publicações ficam fixados.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path=pg_catalog,public;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='15min';
DO $guard$
BEGIN
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Carga/cutover em curso'; END IF;
 """+function_guard+'\n '+view_guard+'\n '+contract_guard+"\n IF NOT EXISTS(SELECT 1 FROM "+AUDIT+" WHERE status='ready_for_review') THEN RAISE EXCEPTION 'Carga não está validada'; END IF;\n IF (SELECT count(*) FROM "+FACT+")<>(SELECT (quality->>'fact')::bigint FROM "+AUDIT+") THEN RAISE EXCEPTION 'Fato candidata mudou após validação'; END IF;\nEND;\n$guard$;\nCREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS SELECT * FROM "+BI+";\nCREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS SELECT * FROM "+RESULT+";\nDO $verify$\nBEGIN\n IF (SELECT count(*) FROM estudo.vw_resultados_2026)<>(SELECT count(*) FROM "+FACT+") THEN RAISE EXCEPTION 'Conservação após cutover falhou'; END IF;\n IF md5(pg_get_viewdef('"+PUBLIC_VIEW+"'::regclass,true))<>"+q(md5(VIEW_OLD[PUBLIC_VIEW]))+" THEN RAISE EXCEPTION 'View pública mudou'; END IF;\nEND;\n$verify$;\nUPDATE "+AUDIT+" SET status='activated',activated_at=clock_timestamp(),activated_views=jsonb_build_object('estudo.vwbi_perfil_br_2026',md5(pg_get_viewdef('estudo.vwbi_perfil_br_2026'::regclass,true)),'estudo.vw_resultados_2026',md5(pg_get_viewdef('estudo.vw_resultados_2026'::regclass,true)));\nSELECT to_jsonb(a) AS cutover_receipt FROM "+AUDIT+" a;\nCOMMIT;"
cutover=secure_entry(cutover)
write('30-cutover-study.sql',cutover)
# Operational entry point: a single snapshot and commit for additive load plus
# adapter cutover. The two files above remain independently reviewable.
combined=load.rstrip()
assert combined.endswith('COMMIT;')
combined=combined[:-len('COMMIT;')].rstrip()
cutover_tail=cutover.replace('BEGIN ISOLATION LEVEL REPEATABLE READ;','',1).strip()
combined=ENTRY_PREFACE+'-- ENTRADA OPERACIONAL CANDIDATA: carga aditiva + dois adaptadores do estudo.\n-- Nenhum objeto public/produto/publicação é alterado. Uma transação; qualquer erro exige ROLLBACK.\n'+combined+'\n\n'+cutover_tail
write('15-load-and-cutover.sql',combined)
rollback="-- CANDIDATO DE RECUPERAÇÃO; conserva a fato versionada e todos os congelamentos.\nBEGIN;\nSET LOCAL search_path=pg_catalog,public;\nSET LOCAL lock_timeout='2s';\nDO $guard$\nBEGIN\n IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Carga/cutover em curso'; END IF;\n IF NOT EXISTS(SELECT 1 FROM "+AUDIT+" WHERE status='activated' AND activated_views->>'estudo.vwbi_perfil_br_2026'=md5(pg_get_viewdef('estudo.vwbi_perfil_br_2026'::regclass,true)) AND activated_views->>'estudo.vw_resultados_2026'=md5(pg_get_viewdef('estudo.vw_resultados_2026'::regclass,true))) THEN RAISE EXCEPTION 'Adaptadores mudaram; recuperação requer nova revisão'; END IF;\nEND;\n$guard$;\n"+'\n'.join('CREATE OR REPLACE VIEW '+name+' AS\n'+VIEW_OLD[name] for name in ['estudo.vwbi_perfil_br_2026','estudo.vw_resultados_2026'])+'\nUPDATE '+AUDIT+" SET status='restored_previous_adapters';\nCOMMIT;"
rollback=secure_entry(rollback)
write('40-rollback-study.sql',rollback)
write('captured-contract.json',json.dumps({'metadata_file':str(M),'source_script_sha256':hashlib.sha256(D.read_bytes()).hexdigest(),'function_md5':FUNCTIONS,'views_md5':{k:md5(v)for k,v in VIEW_OLD.items()},'fact_columns':COLUMNS,'versioned_views_columns':{name:len([c for c in meta['columns']if c['schema']+'.'+c['table']==name])for name in ['estudo.vwbi_perfil_br_2026','estudo.vw_resultados_2026']}},ensure_ascii=False,indent=2))
write('manifest.json',json.dumps({'candidate_only':True,'sql_executed':False,'source_metadata_sha256':hashlib.sha256(M.read_bytes()).hexdigest(),'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest()for p in sorted(W.glob('*.sql'))}},indent=2))
print(json.dumps({'written':sorted(p.name for p in W.glob('*.sql')),'executed_sql':False}))
