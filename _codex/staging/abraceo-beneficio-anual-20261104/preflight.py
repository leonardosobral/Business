from inspect import remote,W
import json
sql="""SELECT jsonb_build_object(
'campaign',(SELECT to_jsonb(c) FROM estudo.campanhas c WHERE codigo='abraceo-primeiro-acesso'),
'annual',(SELECT jsonb_build_object('id',id,'code',codigo,'type',tipo,'year',ano,'status',status) FROM estudo.produtos WHERE codigo='anual-2026'),
'actor',(SELECT jsonb_build_object('id',u.id,'admin',u.is_admin) FROM public.tb_usuarios u JOIN estudo.auditoria_comercial a ON a.ator_id=u.id WHERE a.id=513 AND coalesce(u.is_admin,false)),
'vouchers',(SELECT jsonb_agg(jsonb_build_object('id',v.id,'status',v.status,'expiry',v.expira_em,'identity_hash',md5(jsonb_build_array(v.id,v.campanha_id,v.codigo_hash,v.email_destinatario,v.expira_em)::text)) ORDER BY v.id) FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id WHERE c.codigo='abraceo-primeiro-acesso'),
'grants',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',a.id,'user',a.usuario_id,'status',a.status,'voucher',v.id,'voucher_status',v.status,'benefit_id',b.id,'benefit_status',b.status,'benefit_product',b.produto_id)),'[]') FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id JOIN estudo.campanhas c ON c.id=v.campanha_id LEFT JOIN estudo.beneficios b ON b.acesso_id=a.id WHERE c.codigo='abraceo-primeiro-acesso'),
'benefit_constraints',(SELECT jsonb_agg(pg_get_constraintdef(oid)) FROM pg_constraint WHERE conrelid='estudo.beneficios'::regclass)
)::text AS payload"""
r=remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})
assert r['campaign']['beneficio_percentual']==0 and r['annual']['type']=='ANUAL' and r['annual']['year']==2026
assert r['actor']['admin'];(W/'benefit-before.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
print({'campaign_id':r['campaign']['id'],'version':r['campaign']['version'],'percent':0,'target_annual':r['annual']['id'],'annual_status':r['annual']['status'],'vouchers':len(r['vouchers']),'active_grants':sum(g['status']=='ACTIVE'for g in r['grants']),'prior_grants':len(r['grants']),'actor_verified_admin':True})
