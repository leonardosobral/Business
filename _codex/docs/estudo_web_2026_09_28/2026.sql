-- Ponte para a prévia 2026 já conferida: preserva números, cortes e coorte do snapshot v3.
-- A fonte original permanece identificada. Esta query não recalcula 2026 nem atualiza o corte.
-- Faça novas versões deste pacote no notebook depois de revisar as consultas e os congelamentos de origem.
SELECT payload || jsonb_build_object('meta',(payload->'meta') || jsonb_build_object('origem','Snapshot 2026 v3 preservado e congelado no notebook Business')) AS payload
FROM estudo.web_bases WHERE ano=2026