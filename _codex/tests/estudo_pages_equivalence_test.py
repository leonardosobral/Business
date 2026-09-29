import importlib.util,json
from pathlib import Path
p=Path(__file__).with_name('estudo_notebook_db_test.py');sp=importlib.util.spec_from_file_location('fixture',p);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);C=m.NotebookDatabase
C.setUpClass()
try:
 C.sql("""CREATE TABLE public.tb_evento_corridas(id_evento int PRIMARY KEY,pais text,data_final date);
 INSERT INTO public.tb_evento_corridas VALUES (1,'BR','2025-06-01'),(2,'BR','2024-01-01'),(3,'BR','2023-12-31'),(4,'US','2025-07-01'),(5,'BR','2026-01-01');
 CREATE TABLE public.tb_resultados(id_resultado int PRIMARY KEY,id_evento int,sexo text,idade_range int4range,status_final int,homologado boolean);
 INSERT INTO public.tb_resultados VALUES
 (1,1,'F','[13,20)',0,true),(2,1,'M','[18,40)',0,true),(3,1,'F',NULL,0,true),(4,1,'F','[35,45)',1,true),
 (5,1,'M','[60,)',0,false),(6,1,NULL,'[19,70)',0,true),(7,2,'M','[13,25)',0,true),(8,2,'F','[25,35)',0,true),
 (9,3,'F','[40,61)',0,true),(10,4,'F','[20,30)',0,true),(11,5,'M','[25,35)',0,true),(12,1,'X','empty',0,true),
 (13,2,'M','[28,29)',0,true),(14,3,'M','[14,15)',0,true);
 CREATE VIEW public.vw_resultados AS SELECT * FROM public.tb_resultados WHERE status_final=0 AND homologado=true;""")
 old=json.loads(((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-v1.json').read_text());new=json.loads(((Path(__file__).resolve().parents[2]/'_codex/staging/estudo-paginas')/'estudo-pages-optimized.json').read_text())
 def get(data,key):return next(c['content'].strip().rstrip(';') for s in data['sections'] for c in s['cells'] if c['key']==key)
 def result(query):return C.sql("SELECT jsonb_agg(to_jsonb(t) ORDER BY versao,faixa) FROM ("+query+"\n)t;")
 for key in ['pdf-2025-p04-faixas','pdf-2025-p05-historico']:
  assert result(get(old,key))==result(get(new,key)),key
  print('EQUIVALENCE_PASS',key)
finally:C.cleanup()
