SELECT jsonb_build_object(
 'columns',(SELECT jsonb_agg(jsonb_build_object('name',column_name,'nullable',is_nullable,'type',data_type,'default',column_default)) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_contas' AND column_name IN ('documento','documento_pendente')),
 'constraints',(SELECT jsonb_agg(jsonb_build_object('name',conname,'validated',convalidated,'definition',pg_get_constraintdef(oid))) FROM pg_constraint WHERE conrelid='public.tb_contas'::regclass),
 'pending',(SELECT count(*) FROM tb_contas WHERE documento_pendente)
)::text payload;
