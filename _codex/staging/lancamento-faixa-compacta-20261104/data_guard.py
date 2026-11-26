from inspect import remote,W
import json,sys
sql="SELECT jsonb_build_object('rows',count(*),'max_id',max(id),'hash',md5(coalesce(jsonb_agg(to_jsonb(a) ORDER BY id)::text,'[]')))::text AS payload FROM estudo.auditoria_comercial a WHERE entidade='launch_checklist' AND detalhes->>'release'='2026-q3-20261113'"
r=remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})
mode=sys.argv[1];(W/('data-'+mode+'.json')).write_text(json.dumps(r,indent=2))
if mode=='after':assert r==json.loads((W/'data-before.json').read_text()),'Checklist changed; inspect concurrent edits'
print(r)
