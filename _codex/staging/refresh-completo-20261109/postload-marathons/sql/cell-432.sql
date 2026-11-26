-- Renovação candidata09/11; curadoria/capturas externas preservadas; entradas=[{"cell": 425, "revision": 1, "run": 292, "started_at": "2026-11-09 15:52:45.816865-03"}, {"cell": 426, "revision": 1, "run": 303, "started_at": "2026-11-09 18:19:51.924112-03"}]
-- Capturas oficiais e auditorias já congeladas no notebook; sem nova coleta.
SELECT id,cell_id,title,result FROM estudo.notebook_runs WHERE id IN(207,208,209,210,297,213,292,303) AND frozen IS TRUE AND status='ok' ORDER BY id

