-- Capturas oficiais e auditorias já congeladas no notebook; sem nova coleta.
SELECT id,cell_id,title,result FROM estudo.notebook_runs WHERE id IN(207,208,209,210,212,213,242,243) AND frozen IS TRUE AND status='ok' ORDER BY id
