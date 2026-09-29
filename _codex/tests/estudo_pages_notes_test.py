import importlib.util
from pathlib import Path
p=Path(__file__).with_name('estudo_notebook_db_test.py')
sp=importlib.util.spec_from_file_location('fixture',p);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);C=m.NotebookDatabase
C.setUpClass()
try:
 original=C.sql("SELECT to_jsonb(c)::text FROM estudo.notebook_cells c ORDER BY id")
 for name in ['import','optimize','notes']:
  C.sql('BEGIN;'+((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/('estudo-pages-'+name+'.sql')).read_text()+'COMMIT;')
 assert C.sql("SELECT count(*) FROM estudo.notebook_cells WHERE source_key LIKE 'pdf-2025-%'")=='93'
 assert C.sql("SELECT count(*) FROM estudo.notebook_cells WHERE source_key LIKE '%-coleta-20260928' AND cell_type='markdown' AND lang=''")=='15'
 assert C.sql("SELECT to_jsonb(c)::text FROM estudo.notebook_cells c WHERE source_key IS NULL ORDER BY id")==original
 before=C.sql("SELECT count(*) FROM estudo.notebook_revisions")
 C.sql('BEGIN;'+((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-notes.sql').read_text()+'COMMIT;')
 assert C.sql("SELECT count(*) FROM estudo.notebook_revisions")==before
 print('PASS: initial import + versioned optimization + 15 notes; 93 cells, original data preserved, notes idempotent.')
finally:C.cleanup()
