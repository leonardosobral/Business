-- Additive DML only; install disabled, validate, then activate through Business.
WITH inserted_rule AS (
 INSERT INTO public.tb_vicky_notificacao_regra
 (codigo,nome,trigger_type,enabled,admin_only,days_before,web_enabled,whatsapp_enabled,max_per_day,quiet_start,quiet_end,timezone)
 VALUES ('brasil_gigante_d7','Brasil Gigante · etapa em 7 dias','manual',false,false,7,true,true,1,'20:00','08:00','America/Sao_Paulo')
 ON CONFLICT(codigo) DO NOTHING RETURNING id_vicky_notificacao_regra
)
INSERT INTO public.tb_vicky_notificacao_template
 (id_vicky_notificacao_regra,channel,language,title,content,provider_template_name,status)
SELECT r.id_vicky_notificacao_regra,t.channel,'pt-BR','Mais uma etapa está chegando',t.content,t.provider,'active'
FROM inserted_rule r CROSS JOIN (VALUES
 ('web','**Mais uma etapa está chegando**' || chr(10) || chr(10) || 'Lembre-se de reconhecer seus resultados nas etapas já concluídas e manter o seu perfil atualizado.',NULL::varchar),
 ('whatsapp','Mais uma etapa está chegando' || chr(10) || chr(10) || 'Lembre-se de reconhecer seus resultados nas etapas já concluídas e manter o seu perfil atualizado.','atualize_cbg')
) AS t(channel,content,provider);
