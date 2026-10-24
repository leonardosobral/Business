from pathlib import Path
import base64,json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');out=Path(__file__).resolve().parent
ids=[37556,37526,40833,45366,37570,40834,41834,48557,37483,37528,40103,37572,37564]
sql="""SELECT jsonb_build_object('observed_at',now(),'coupon_view_definition',pg_get_viewdef('public.vw_evento_corridas_cupom'::regclass,true),'coupon_target_view_definition',pg_get_viewdef('public.vw_cupom'::regclass,true),'events',(SELECT jsonb_agg(to_jsonb(x) ORDER BY data_inicial,cidade,id_evento) FROM (
SELECT e.id_evento,e.nome_evento,e.tag,e.cidade,e.estado,e.data_inicial,e.data_final,e.id_agrega_evento,e.ativo,e.inscricao_disponibilidade,e.url_hotsite,e.url_inscricao,e.info_duplicado,
(SELECT jsonb_agg(jsonb_build_object('agregador_tag',g.agregador_tag,'tipo',g.agregador_tipo,'canonical_tag',coalesce(nullif(a.tag,''),g.agregador_tag))) FROM public.tb_agregadores_eventos ge JOIN public.tb_agregadores g USING(agregador_tag) LEFT JOIN public.tb_agrega_eventos a ON a.id_agrega_evento=g.id_agrega_evento_legado WHERE ge.id_evento=e.id_evento) AS circuit_links,
(SELECT jsonb_agg(to_jsonb(c)||jsonb_build_object('valid_today',current_date between c.data_validade_inicio and c.data_validade_fim)) FROM public.vw_evento_corridas_cupom c WHERE (c.tipo_evento=1 AND c.id_evento_agrega=e.id_evento) OR (c.tipo_evento=2 AND c.id_evento_agrega=e.id_agrega_evento)) AS coupons,
(SELECT jsonb_agg(jsonb_build_object('id_cupom',c.id_cupom,'code',c.cupom,'url',c.curl,'active',c.ativo)) FROM public.vw_cupom c WHERE c.id_evento=e.id_evento) AS coupon_targets,
(SELECT jsonb_agg(jsonb_build_object('id',r.id_evento_percurso,'distance',r.percurso_evento,'unit',r.unidade_de_medida,'date',r.data_percurso) ORDER BY r.id_evento_percurso) FROM public.tb_evento_corridas_percursos r WHERE r.id_evento=e.id_evento) AS routes
FROM public.tb_evento_corridas e WHERE e.id_evento IN (IDS)) x))::text payload""".replace('IDS',','.join(map(str,ids)))
body='opts={datasource="runnerhub",timeout=40}; transaction {queryExecute("SET TRANSACTION READ ONLY",{},opts);q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{},opts);report=deserializeJSON(q.payload[1]);}'
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'\nprint(json.dumps(bridge(ROOT,'+repr(body)+')))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=110)
if r.returncode:raise SystemExit(r.stderr[-4000:])
data=json.loads(r.stdout);(out/'city-matrix-read.json').write_text(json.dumps(data,ensure_ascii=False,indent=2));print(json.dumps(data,ensure_ascii=False))
