SELECT jsonb_build_object(
'columns',(SELECT jsonb_agg(to_jsonb(x)) FROM (SELECT column_name,data_type,is_nullable,column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_contas')x),
'constraints',(SELECT jsonb_agg(jsonb_build_object('name',conname,'def',pg_get_constraintdef(oid))) FROM pg_constraint WHERE conrelid='tb_contas'::regclass),
'accounts',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id_conta) FROM tb_contas c),
'profiles',(SELECT jsonb_agg(jsonb_build_object('id_conta',id_conta,'id_origem',id_origem,'origem',origem)) FROM tb_conta_perfis_publicos),
'indexes',(SELECT jsonb_agg(indexdef) FROM pg_indexes WHERE schemaname='public' AND tablename='tb_contas')
)::text payload