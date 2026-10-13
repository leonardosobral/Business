from pathlib import Path
import json,subprocess,tempfile,os
from release import sqljson
P=Path(__file__).parent;ROOT=P.parents[2];p=json.loads((P/'payload.json').read_text());bin='/opt/homebrew/opt/postgresql@16/bin/'
def run(name,args,source=None):
 r=subprocess.run([bin+name]+args,input=source,capture_output=True,text=True,timeout=40,env={**os.environ,'LC_ALL':'C'});assert r.returncode==0,r.stderr;return r.stdout.strip()
with tempfile.TemporaryDirectory(prefix='abraceo-pg-',dir='/private/tmp') as d:
 run('initdb',['-D',d+'/db','-U','postgres','-A','trust','--no-locale','--encoding=UTF8']);started=False
 try:
  run('pg_ctl',['-D',d+'/db','-l',d+'/pg.log','-o',"-F -k "+d+" -c listen_addresses=''",'-w','start']);started=True
  def sql(s):return run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',d,'-U','postgres','-d','postgres'],s)
  sql("CREATE TYPE tipo_titular_conta AS ENUM('PJ','PF');CREATE TYPE status_conta AS ENUM('ATIVO','PENDENTE','SUSPENSO');CREATE TABLE tb_contas(id_conta bigserial PRIMARY KEY,nome_conta varchar(160) NOT NULL,tipo_titular tipo_titular_conta NOT NULL,documento varchar(20) NOT NULL UNIQUE,nome_titular varchar(200) NOT NULL,email_principal varchar(255),telefone_principal varchar(30),status status_conta NOT NULL DEFAULT 'PENDENTE',data_criacao timestamptz NOT NULL DEFAULT now(),data_atualizacao timestamptz NOT NULL DEFAULT now());INSERT INTO tb_contas(nome_conta,tipo_titular,documento,nome_titular,status) VALUES('Existing','PJ','32692507000140','Existing','ATIVO');")
  before=sql('SELECT to_jsonb(c)::text FROM tb_contas c');migration=p['migration'];data=sqljson(p['rows'])
  sql(migration)
  sql("INSERT INTO tb_contas(nome_conta,tipo_titular,documento,documento_pendente,nome_titular,email_principal,telefone_principal,status) SELECT x->>'nome_empresa','PJ',NULL,true,x->>'nome_empresa',nullif(x->>'email',''),nullif(x->>'telefone',''),'PENDENTE' FROM jsonb_array_elements("+data+")x;")
  assert sql("SELECT count(*) FROM tb_contas WHERE documento IS NULL AND documento_pendente AND tipo_titular='PJ' AND status='PENDENTE'")=='47'
  updates=[("status='ATIVO'",'23514'),("tipo_titular='PF'",'23514'),('documento_pendente=false','23514'),("documento='123'",'23514'),("documento='',documento_pendente=false",'23514'),("documento='32692507000140',documento_pendente=false",'23505')]
  for update,code in updates:
   sql("DO $t$ BEGIN BEGIN UPDATE tb_contas SET "+update+" WHERE id_conta=2;RAISE EXCEPTION 'Guard failed';EXCEPTION WHEN SQLSTATE '"+code+"' THEN NULL;END;END $t$;")
  sql("BEGIN;UPDATE tb_contas SET documento='00000000000191',documento_pendente=false,status='ATIVO' WHERE id_conta=2;ROLLBACK;")
  assert sql("SELECT (to_jsonb(c)-'documento_pendente')::text FROM tb_contas c WHERE id_conta=1")==before
  # Verify safe rollback order on the disposable fixture only.
  sql("DELETE FROM tb_contas WHERE documento_pendente;ALTER TABLE tb_contas DROP CONSTRAINT tb_contas_documento_pendente_check;ALTER TABLE tb_contas ALTER COLUMN documento SET NOT NULL;ALTER TABLE tb_contas DROP COLUMN documento_pendente;")
  assert sql('SELECT to_jsonb(c)::text FROM tb_contas c')==before
  out={'passed':True,'checks':['47 public organizer rows fit schema','multiple pending NULL documents allowed','active NULL rejected','PF NULL rejected','unflagged NULL rejected','pending known document rejected','empty known document rejected','duplicate known document rejected','document resolution accepted','existing row preserved','rollback restores schema and row']};(P/'local-tests.json').write_text(json.dumps(out,indent=2));print(json.dumps(out))
 finally:
  if started:run('pg_ctl',['-D',d+'/db','-m','fast','-w','stop'])
