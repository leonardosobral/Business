import importlib.util,json,hashlib
from pathlib import Path
p=Path(__file__).with_name('estudo_notebook_db_test.py')
spec=importlib.util.spec_from_file_location('fixture',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);C=m.NotebookDatabase
C.setUpClass()
try:
 sql=((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-import.sql').read_text()
 before=C.sql("SELECT encode(sha256(convert_to(jsonb_agg(to_jsonb(c) ORDER BY id)::text,'UTF8')),'hex') FROM estudo.notebook_cells c")
 C.sql('BEGIN;'+sql+'COMMIT;')
 first=C.sql("SELECT count(*)||':'||(SELECT count(*) FROM estudo.notebook_revisions) FROM estudo.notebook_cells")
 C.sql('BEGIN;'+sql+'COMMIT;')
 assert first==C.sql("SELECT count(*)||':'||(SELECT count(*) FROM estudo.notebook_revisions) FROM estudo.notebook_cells")
 assert before==C.sql("SELECT encode(sha256(convert_to(jsonb_agg(to_jsonb(c) ORDER BY id)::text,'UTF8')),'hex') FROM estudo.notebook_cells c WHERE source_key IS NULL")
 assert C.sql("SELECT count(*) FROM estudo.notebook_cells WHERE source_key LIKE 'pdf-2025-%' AND lang='sql'")=='24'
 assert C.sql("SELECT count(*) FROM estudo.notebook_cells WHERE source_key LIKE 'pdf-2025-%' AND lang='html'")=='0'
 assert C.sql("SELECT count(*) FROM estudo.notebooks WHERE source_key LIKE 'pdf-2025-p%'")=='15'
 C.sql("UPDATE estudo.notebook_cells SET content=content||E'\\n-- Edição do DBA' WHERE source_key='pdf-2025-p03-genero'")
 try:C.sql('BEGIN;'+sql+'COMMIT;');raise AssertionError('should conflict')
 except AssertionError as e:assert 'Conflito de conteudo' in str(e),e
 print('PASS: 15 seções, 24 SQLs, sem HTML novo; idempotência, acervo preservado e conflito de edição protegidos.')
finally:C.cleanup()
