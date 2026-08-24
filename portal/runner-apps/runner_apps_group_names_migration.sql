UPDATE tb_portal_runner_app_groups
SET nome = 'Apps Principais',
    descricao = 'Primeiro nivel do menu Runner Apps.',
    atualizado_em = now()
WHERE id_group = 1;

UPDATE tb_portal_runner_app_groups
SET nome = 'Apps Secundários',
    descricao = 'Segundo nivel do menu Runner Apps.',
    atualizado_em = now()
WHERE id_group = 2;
