"""Contract tests against a disposable PostgreSQL cluster, never production."""
from pathlib import Path
import json, os, shutil, subprocess, tempfile, unittest

ROOT=Path(__file__).resolve().parents[2]
SQL=ROOT/'_codex/sql/2026-09-28_estudo_notebook.sql'
PG=Path('/opt/homebrew/opt/postgresql@16/bin')

class NotebookDatabase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=Path(tempfile.mkdtemp(prefix='estudo-pg-',dir='/private/tmp'))
        cls.port=str(55900+os.getpid()%100)
        subprocess.run([str(PG/'initdb'),'-D',str(cls.tmp/'db'),'-U','runner_dba','-A','trust','--no-locale','--encoding=UTF8'],check=True,capture_output=True)
        subprocess.run([str(PG/'pg_ctl'),'-D',str(cls.tmp/'db'),'-l',str(cls.tmp/'log'),'-o',f"-k {cls.tmp} -p {cls.port} -h 127.0.0.1",'-w','start'],check=True,capture_output=True)
        cls.addClassCleanup(cls.cleanup)
        cls.cmd=[str(PG/'psql'),'-X','-qAt','-v','ON_ERROR_STOP=1','-h',str(cls.tmp),'-p',cls.port,'-U','runner_dba','postgres']
        cls.sql("""CREATE SCHEMA estudo; CREATE TABLE estudo.snapshots(id int, dados jsonb);
INSERT INTO estudo.snapshots VALUES(1,'{"original":true}');
CREATE TABLE public.notebooks(notebook_id serial, notebook_title varchar, tag varchar, call_order int NOT NULL DEFAULT 1);
CREATE TABLE public.notebook_cells(id bigserial PRIMARY KEY, notebook_id bigint NOT NULL, cell_order int NOT NULL, cell_type text NOT NULL,lang text,content text NOT NULL,updated_at timestamptz NOT NULL DEFAULT now());
INSERT INTO public.notebooks(notebook_id,notebook_title,tag) VALUES(7,'UFs','ufs');
INSERT INTO public.notebook_cells(id,notebook_id,cell_order,cell_type,lang,content,updated_at) VALUES(30,7,1,'code','sql','SELECT 1 AS cidade;','2026-02-01T11:21:08-03:00'),(75,7,2,'code','html','<table>São Paulo</table>','2026-01-30T09:36:35-03:00');
CREATE TABLE public.source_rows(id int, value text);INSERT INTO public.source_rows VALUES(1,'original');""")
        if SQL.exists():cls.sql('BEGIN;'+SQL.read_text()+'COMMIT;')

    @classmethod
    def cleanup(cls):
        subprocess.run([str(PG/'pg_ctl'),'-D',str(cls.tmp/'db'),'-m','immediate','-w','stop'],capture_output=True)
        shutil.rmtree(cls.tmp)

    @classmethod
    def sql(cls,sql):
        r=subprocess.run(cls.cmd,input=sql,text=True,capture_output=True)
        if r.returncode:raise AssertionError(r.stderr.strip())
        return r.stdout.strip()

    def test_tables_move_preserves_data_and_existing_snapshots(self):
        self.assertEqual(self.sql("SELECT to_regclass('estudo.notebook_cells') IS NOT NULL;"),'t')
        self.assertEqual(self.sql("SELECT to_regclass('public.notebook_cells') IS NULL;"),'t')
        self.assertEqual(self.sql("SELECT id||':'||content FROM estudo.notebook_cells ORDER BY id;"),'30:SELECT 1 AS cidade;\n75:<table>São Paulo</table>')
        self.assertEqual(self.sql("SELECT dados->>'original' FROM estudo.snapshots;"),'true')
        self.assertEqual(self.sql("SELECT count(*) FROM estudo.notebook_revisions;"),'2')

    def test_sequences_follow_ids(self):
        value=self.sql("BEGIN; INSERT INTO estudo.notebooks(notebook_title,caderno_id) VALUES('Nova',1) RETURNING notebook_id;ROLLBACK;")
        self.assertGreater(int(value),7)
        value=self.sql("BEGIN; INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content) VALUES(7,3,'code','sql','SELECT 2') RETURNING id;ROLLBACK;")
        self.assertGreater(int(value),75)

    def test_edit_creates_revision_and_stale_version_cannot_update(self):
        value=self.sql("BEGIN;UPDATE estudo.notebook_cells SET content='SELECT 2',updated_by=42 WHERE id=30 AND version=1;UPDATE estudo.notebook_cells SET content='stale' WHERE id=30 AND version=1;SELECT content||':'||version FROM estudo.notebook_cells WHERE id=30;SELECT count(*) FROM estudo.notebook_revisions WHERE cell_id=30;ROLLBACK;")
        self.assertEqual(value,'SELECT 2:2\n2')

    def test_archive_keeps_history(self):
        self.assertEqual(self.sql("BEGIN;UPDATE estudo.notebook_cells SET archived=true WHERE id=30;SELECT count(*) FROM estudo.notebook_revisions WHERE cell_id=30;ROLLBACK;"),'2')

    def test_revisions_cannot_change_or_disappear(self):
        for action in ["UPDATE estudo.notebook_revisions SET content='changed'","DELETE FROM estudo.notebook_revisions","TRUNCATE estudo.notebook_revisions CASCADE"]:
            with self.subTest(action=action),self.assertRaisesRegex(AssertionError,'imut|immutable'):
                self.sql('BEGIN;'+action+';ROLLBACK;')

    def run_insert(self,truncated=False):
        payload=json.dumps({'columns':['n','texto'],'rows':[{'n':1,'texto':None}]})
        return "INSERT INTO estudo.notebook_runs(cell_id,cell_version,sql_text,sql_sha256,executed_by,status,result,row_count,truncated,duration_ms,finished_at) VALUES(30,1,'SELECT 1',repeat('a',64),42,'ok','"+payload+"'::jsonb,1,"+str(truncated).lower()+",2,now()) RETURNING id;"

    def test_freeze_preserves_json_and_is_immutable(self):
        value=self.sql("BEGIN;"+self.run_insert()+"UPDATE estudo.notebook_runs SET frozen=true,title='Coleta real',note='Revisar' WHERE id=currval('estudo.notebook_runs_id_seq');SELECT frozen||':'||(result->'rows'->0->'texto')::text FROM estudo.notebook_runs WHERE id=currval('estudo.notebook_runs_id_seq');ROLLBACK;")
        self.assertTrue(value.endswith('true:null'),value)
        for action in ["UPDATE estudo.notebook_runs SET result='{}'","DELETE FROM estudo.notebook_runs","TRUNCATE estudo.notebook_runs"]:
            with self.subTest(action=action),self.assertRaisesRegex(AssertionError,'imut|immutable'):
                self.sql("BEGIN;"+self.run_insert()+"UPDATE estudo.notebook_runs SET frozen=true,title='Coleta';"+action+";ROLLBACK;")

    def test_truncated_or_failed_result_cannot_freeze(self):
        with self.assertRaisesRegex(AssertionError,'completo|trunc|congel'):
            self.sql("BEGIN;"+self.run_insert(True)+"UPDATE estudo.notebook_runs SET frozen=true,title='Incompleto';ROLLBACK;")

    def test_reader_has_select_without_write_or_role_memberships(self):
        self.assertEqual(self.sql('BEGIN;SET LOCAL ROLE estudo_reader;SELECT value FROM public.source_rows;ROLLBACK;'),'original')
        for action in ["UPDATE public.source_rows SET value='bad'","DELETE FROM estudo.notebook_cells","CREATE TABLE estudo.bad(id int)"]:
            with self.subTest(action=action),self.assertRaisesRegex(AssertionError,'permission denied'):
                self.sql('BEGIN;SET LOCAL ROLE estudo_reader;'+action+';ROLLBACK;')
        self.assertEqual(self.sql("SELECT rolsuper OR rolcanlogin OR rolcreaterole OR rolcreatedb OR rolbypassrls FROM pg_roles WHERE rolname='estudo_reader';"),'f')

    def test_live_cell_delete_is_refused_in_favor_of_archive(self):
        with self.assertRaisesRegex(AssertionError,'arquiv|exclu'):
            self.sql('BEGIN;DELETE FROM estudo.notebook_cells WHERE id=30;ROLLBACK;')

if __name__=='__main__':unittest.main(verbosity=2)
