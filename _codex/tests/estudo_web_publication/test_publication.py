from pathlib import Path
import unittest,tempfile,subprocess,os,json,shutil
D=Path(__file__).resolve().parent;PG=Path('/opt/homebrew/opt/postgresql@16/bin')
def lit(v):return "'"+str(v).replace("'","''")+"'"
class Publication(unittest.TestCase):
 @classmethod
 def setUpClass(c):
  c.tmp=Path(tempfile.mkdtemp(prefix='web-study-',dir='/private/tmp'));c.port=str(56100+os.getpid()%100)
  subprocess.run([str(PG/'initdb'),'-D',str(c.tmp/'db'),'-U','runner_dba','-A','trust','--no-locale','--encoding=UTF8'],check=True,capture_output=True)
  subprocess.run([str(PG/'pg_ctl'),'-D',str(c.tmp/'db'),'-l',str(c.tmp/'log'),'-o',f'-k {c.tmp} -p {c.port} -h 127.0.0.1','-w','start'],check=True,capture_output=True)
  c.addClassCleanup(c.cleanup);c.cmd=[str(PG/'psql'),'-X','-qAt','-v','ON_ERROR_STOP=1','-h',str(c.tmp),'-p',c.port,'-U','runner_dba','postgres']
  c.sql("CREATE SCHEMA estudo;CREATE ROLE runner;CREATE ROLE estudo_reader;CREATE TABLE estudo.notebook_cells(id bigint primary key);INSERT INTO estudo.notebook_cells VALUES(1),(2);CREATE TABLE estudo.notebook_runs(id bigint primary key,cell_id bigint,cell_version int,status text,frozen bool,truncated bool,result jsonb,row_count int,started_at timestamptz);CREATE FUNCTION estudo.notebook_immutable() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RAISE EXCEPTION 'imutavel|foreign key';END;$$;")
  c.sql((D.parents[1]/'sql/2026-09-28_estudo_web.sql').read_text())
 @classmethod
 def sql(c,s):
  p=subprocess.run(c.cmd,input=s,text=True,capture_output=True)
  if p.returncode:raise AssertionError(p.stderr)
  return p.stdout.strip()
 @classmethod
 def cleanup(c):subprocess.run([str(PG/'pg_ctl'),'-D',str(c.tmp/'db'),'-m','immediate','-w','stop'],capture_output=True);shutil.rmtree(c.tmp)
 def seed(self,payload=None):
  base=json.loads((D/'base-2025.json').read_text());payload=payload or base
  schema=json.loads((D/'contract-2025.json').read_text())
  return 'BEGIN;INSERT INTO estudo.web_bases VALUES(2025,'+lit(json.dumps(base))+','+lit(json.dumps(schema))+');INSERT INTO estudo.web_destinos(ano,cell_id) VALUES(2025,1);INSERT INTO estudo.notebook_runs VALUES(1,1,1,\'ok\',true,false,'+lit(json.dumps({'columns':['payload'],'rows':[{'payload':payload}]}))+',1,now());'
 def test_00_installed(self):self.assertEqual(self.sql("SELECT to_regclass('estudo.web_destinos') IS NOT NULL"),'t')
 def test_publish_repeat_and_immutability(self):
  out=self.sql(self.seed()+"SELECT estudo.publicar_web(2025,1,0,42,'Primeira');SELECT estudo.publicar_web(2025,1,0,42,'Repetido');SELECT count(*) FROM estudo.web_publicacoes;ROLLBACK;")
  self.assertEqual(out.splitlines()[-1],'1')
  for action in ["UPDATE estudo.web_publicacoes SET nota='outro'","DELETE FROM estudo.web_publicacoes","TRUNCATE estudo.web_publicacoes"]:
   with self.assertRaisesRegex(AssertionError,'imutavel|foreign key'):self.sql(self.seed()+"SELECT estudo.publicar_web(2025,1,0,42,'Primeira');"+action+';ROLLBACK;')
 def test_reject_invalid_run(self):
  for update in ["frozen=false","truncated=true","status='error'","cell_id=2","row_count=2"]:
   with self.subTest(update=update),self.assertRaisesRegex(AssertionError,'congelad|complet|celula'):
    self.sql(self.seed()+"UPDATE estudo.notebook_runs SET "+update+";SELECT estudo.publicar_web(2025,1,0,42,'Teste');ROLLBACK;")
 def test_stale_publication(self):
  with self.assertRaisesRegex(AssertionError,'mudou'):
   self.sql(self.seed()+"SELECT estudo.publicar_web(2025,1,5,42,'Teste');ROLLBACK;")
 def test_reject_payload_changes(self):
  base=json.loads((D/'base-2025.json').read_text())
  for mode in ['private','wrong_year','pdf','missing','duplicated']:
   p=json.loads(json.dumps(base))
   if mode=='private':p['sql_text']='SELECT secret'
   if mode=='wrong_year':p['meta']['ano']=2026
   if mode=='pdf':p['series'][0]['valores'][0]['valor']='Wrong'
   if mode=='missing':p['comparacoes'].pop()
   if mode=='duplicated':p['comparacoes'].append(p['comparacoes'][0])
   with self.subTest(mode=mode),self.assertRaisesRegex(AssertionError,'(?i)contrato|referencia|categorias'):
    self.sql(self.seed(p)+"SELECT estudo.publicar_web(2025,1,0,42,'Teste');ROLLBACK;")
 def test_public_role_only_sees_active_payload(self):
  out=self.sql(self.seed()+"SELECT estudo.publicar_web(2025,1,0,42,'Primeira');SET LOCAL ROLE runner;SELECT payload->'meta'->>'ano' FROM estudo.web_payloads;ROLLBACK;")
  self.assertEqual(out.splitlines()[-1],'2025')
  with self.assertRaisesRegex(AssertionError,'permission denied'):self.sql('BEGIN;SET LOCAL ROLE runner;SELECT * FROM estudo.web_publicacoes;ROLLBACK;')
 def test_projection_from_frozen_runs(self):
  data=json.loads((D/'source-runs.json').read_text())
  sql='BEGIN;'
  for y in [2025,2026]:sql+='INSERT INTO estudo.web_bases VALUES('+str(y)+','+lit((D/f'base-{y}.json').read_text())+','+lit((D/f'contract-{y}.json').read_text())+');'
  for r in data['runs']:
   sql+='INSERT INTO estudo.notebook_runs VALUES('+str(r['id'])+','+str(r['cell_id'])+','+str(r['cell_version'])+",'ok',true,false,"+lit(json.dumps(r['result']))+','+str(r['row_count'])+','+lit(r['started_at'])+');'
  for y in [2025,2026]:
   result=self.sql(sql+"SELECT jsonb_build_object('payload',p.payload,'valid',estudo.web_json_valido(p.payload,(SELECT contrato FROM estudo.web_bases WHERE ano="+str(y)+"))) FROM ("+(D/f'{y}.sql').read_text()+') p;ROLLBACK;')
   p=json.loads(result);self.assertTrue(p['valid']);self.assertEqual(p['payload']['meta']['ano'],y)
   if y==2025:
    self.assertEqual(p['payload']['totais_atuais'],{'resultados':5279415,'eventos':9360});self.assertEqual(sum(c['status']=='notebook_em_conciliacao' for c in p['payload']['comparacoes']),33)
   else:self.assertEqual(p['payload']['comparativo'],json.loads((D/'base-2026.json').read_text())['comparativo'])
if __name__=='__main__':unittest.main()
