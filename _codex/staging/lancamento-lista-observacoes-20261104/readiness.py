from inspect import remote,W
import json
sql="""SELECT jsonb_build_object(
'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'status',status,'publication',publicacao_id)) FROM estudo.produtos),
'campaigns',(SELECT jsonb_agg(jsonb_build_object('code',c.codigo,'status',c.status,'benefit',c.beneficio_percentual,'vouchers',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id),'ready',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id AND status='READY'),'redeemed',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id AND status='REDEEMED'),'last_redemption_day',(SELECT max((expira_em AT TIME ZONE 'America/Sao_Paulo')::date-1) FROM estudo.vouchers WHERE campanha_id=c.id))) FROM estudo.campanhas c),
'active_accesses',(SELECT count(*) FROM estudo.acessos WHERE status='ACTIVE'),
'declared_representatives',(SELECT count(*) FROM estudo.primeiro_acesso_representantes),
'pending_requests',(SELECT count(*) FROM estudo.solicitacoes WHERE status='PENDING'),
'checklist',(SELECT coalesce(jsonb_agg(to_jsonb(d)),'[]') FROM (SELECT DISTINCT ON(detalhes->>'step') detalhes->>'step' AS step,id AS version,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)d),
'validations',(SELECT coalesce(jsonb_agg(to_jsonb(v)),'[]') FROM (SELECT DISTINCT ON(detalhes->>'step') detalhes->>'step' AS step,id AS version,detalhes->'completed' AS completed FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)v)
)::text AS payload"""
r=remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})
body=r'''
urls=['https://roadrunners.run/brasilquecorreprovas/2026/','https://roadrunners.run/brasilquecorreprovas/2026/kit/','https://roadrunners.run/brasilquecorreprovas/imprensa/']
result=[]
for url in urls:
 p=subprocess.run(['curl','-sS','--max-time','20','-w','\n%{http_code}',url],capture_output=True,text=True,timeout=25);assert p.returncode==0
 text,status=p.stdout.rsplit('\n',1);assert status=='200',(url,status)
 result.append({'url':url,'status':int(status),'temporary_press_open':'Acesso temporariamente aberto'in text,'has_2_1':'+2,1%'in text,'has_33_9':'+33,9%'in text})
print(json.dumps(result))
'''
r['public_http']=remote(body,{})
(W/'readiness-before.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in r.items()if k not in ('checklist','validations')},ensure_ascii=False));print({'existing_notes':len(r['checklist']),'existing_validations':len(r['validations'])})
