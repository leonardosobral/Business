"""Read-only challenge audit for permanent badges whose reason is still unknown."""
from pathlib import Path
import importlib.util
import json
import os

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('verified_operator', ROOT.parent / 'RoadRunners/_codex/scripts/verified_dev_operator.py')
operator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(operator)
BASE = """WITH candidates AS (
 SELECT pg.id_pagina AS profile_id,pg.nome,pg.tag FROM public.tb_paginas pg
 WHERE pg.verificado OR EXISTS(SELECT 1 FROM rr_verified.grants g WHERE g.profile_id=pg.id_pagina
 AND g.origin='legacy' AND NOT EXISTS(SELECT 1 FROM rr_verified.legacy_reclassifications r WHERE r.profile_id=g.profile_id))
), pending AS (
 SELECT c.* FROM candidates c CROSS JOIN LATERAL rr_verified.profile_status(c.profile_id) st
 LEFT JOIN LATERAL(SELECT category FROM rr_verified.admin_classifications WHERE profile_id=c.profile_id ORDER BY revision DESC LIMIT 1) cl ON true
 WHERE st.permanent AND coalesce(cl.category,'nao_informado')='nao_informado'
), users AS (
 SELECT DISTINCT p.*,pu.id_usuario FROM pending p JOIN public.tb_paginas_usuarios pu ON pu.id_pagina=p.profile_id AND pu.id_usuario>0
) """
QUERIES = {
 'pending': BASE + "SELECT * FROM pending ORDER BY nome",
 'registrations': BASE + """SELECT u.profile_id,u.nome,u.tag,d.desafio,coalesce(e.titulo,d.desafio,'Sem desafio informado') AS challenge_name,
 d.produto,coalesce(pr.nome_produto,d.produto) AS product_name,d.status,d.status_final,
 to_char(d.data_inscricao,'YYYY-MM-DD HH24:MI') AS registered_at,coalesce(d.num_pedido,'') AS order_ref,
 coalesce(d.body->>'status','') AS body_status
 FROM users u JOIN public.desafios d ON d.id_usuario=u.id_usuario
 LEFT JOIN LATERAL(SELECT titulo FROM public.desafios_eventos WHERE tag=d.desafio ORDER BY id_desafio LIMIT 1) e ON true
 LEFT JOIN LATERAL(SELECT nome_produto FROM public.desafios_produtos WHERE codigo_produto=d.produto ORDER BY (desafio=d.desafio) DESC NULLS LAST,id_produto LIMIT 1) pr ON true
 ORDER BY u.nome,d.desafio,d.produto""",
 'legacy_cna': BASE + """SELECT u.profile_id,u.nome,d.produto,d.status,to_char(d.data_inscricao,'YYYY-MM-DD HH24:MI') AS registered_at,
 coalesce(d.num_pedido,'') AS order_ref,d.doador FROM users u JOIN public.desafio_cna d ON d.id_usuario=u.id_usuario ORDER BY u.nome""",
 'circuits': BASE + """SELECT u.profile_id,u.nome,d.id_agregador,a.agregador_nome AS challenge_name,to_char(d.data_inscricao,'YYYY-MM-DD HH24:MI') AS registered_at
 FROM users u JOIN public.tb_desafios_rr d ON d.id_usuario=u.id_usuario JOIN public.tb_agregadores a ON a.id_agregador=d.id_agregador ORDER BY u.nome,a.agregador_nome""",
 'circuit_races': BASE + """SELECT u.profile_id,u.nome,d.id_agregador,a.agregador_nome AS challenge_name,d.id_evento,e.nome_evento,d.status,
 to_char(d.data_inscricao,'YYYY-MM-DD HH24:MI') AS registered_at,coalesce(d.num_pedido,'') AS order_ref
 FROM users u JOIN public.tb_desafios_rr_provas d ON d.id_usuario=u.id_usuario JOIN public.tb_agregadores a ON a.id_agregador=d.id_agregador
 LEFT JOIN public.tb_evento_corridas e ON e.id_evento=d.id_evento ORDER BY u.nome,a.agregador_nome,d.id_evento""",
 'leads': BASE + """SELECT u.profile_id,u.nome,count(*) AS records FROM users u JOIN public.desafio_leads d ON d.id_usuario=u.id_usuario GROUP BY u.profile_id,u.nome ORDER BY u.nome""",
 'gorunners': BASE + """SELECT u.profile_id,u.nome,c.id AS challenge_id,c.title AS challenge_name,c.type,c.published,p.current AS progress,
 (p.completed_at IS NOT NULL) AS completed FROM users u JOIN gorunners.users gu ON gu.rr_user_id=u.id_usuario
 JOIN gorunners.challenge_progress p ON p.user_id=gu.id
 JOIN gorunners.challenges c ON c.id=p.challenge_id ORDER BY u.nome,c.title""",
 'payment_ledger': BASE + """SELECT u.profile_id,u.nome,s.source,s.account_scope,s.order_key,s.product_code,s.status,s.classification,s.coverage_kind,s.match_basis,
 s.net_amount_minor,s.currency,to_char(s.paid_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM-DD HH24:MI') AS paid_at
 FROM users u JOIN crm_interno.conversion_order_state s ON s.user_id=u.id_usuario
 WHERE EXISTS(SELECT 1 FROM public.desafios_produtos p WHERE p.codigo_produto=s.product_code)
 OR EXISTS(SELECT 1 FROM public.desafios d WHERE d.id_usuario=u.id_usuario AND d.produto=s.product_code)
 ORDER BY u.nome,s.product_code,s.paid_at""",
 'verified_challenge_sources': BASE + """SELECT p.profile_id,p.nome,c.product_code,c.state,c.provider_order_id,c.amount_cents,
 to_char(c.paid_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM-DD HH24:MI') AS paid_at,
 to_char(c.ends_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM-DD HH24:MI') AS ends_at
 FROM pending p JOIN rr_verified.challenge_orders c ON c.profile_id=p.profile_id ORDER BY p.nome,c.paid_at"""
}

if __name__ == '__main__':
    body = 'report={};transaction isolation="repeatable_read" {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});queryExecute("SET LOCAL statement_timeout=20000",{},{datasource="runner_dba"});'
    for name, sql in QUERIES.items():
        cf_sql = '"' + sql.replace('"', '""').replace('#', '##') + '"'
        body += 'report["' + name + '"]=queryExecute(' + cf_sql + ',{},{datasource="runner_dba",returntype="array"});'
    body += 'transaction action="rollback";}'
    result = {k.lower(): v for k, v in operator.run(body).items()}
    target = ROOT / '_codex/analyses/verified-challenges-20261124'
    target.mkdir(parents=True, exist_ok=True)
    path = target / 'audit.json'
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    os.chmod(path, 0o600)
    print(json.dumps({name: {'rows':len(rows),'profiles':len({r['profile_id'] for r in rows})} for name, rows in result.items()}, ensure_ascii=False))
