const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
test('PostgreSQL migration is repeatable and enforces one account and one event per card',async()=>{
  const {PGlite}=await import(require.resolve('@electric-sql/pglite'));
  const db=new PGlite();
  try {
    await db.exec('CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY)');
    const sql=fs.readFileSync(path.resolve(__dirname,'../../administracao/agenda/agenda_schema.sql'),'utf8');await db.exec(sql);await db.exec(sql);
    await assert.rejects(db.exec("INSERT INTO tb_google_agenda_conexao VALUES (1,'wrong@example.com','sub','cipher','scopes',now())"));
    await db.exec("INSERT INTO tb_google_agenda_cartoes(card_id,calendar_id,event_id) VALUES ('aaaaaaaaaaaaaaaaaaaaaaaa','calendar','event')");
    await assert.rejects(db.exec("INSERT INTO tb_google_agenda_cartoes(card_id,calendar_id,event_id) VALUES ('aaaaaaaaaaaaaaaaaaaaaaaa','other','event2')"));
    await assert.rejects(db.exec("INSERT INTO tb_google_agenda_cartoes(card_id,calendar_id,event_id) VALUES ('bbbbbbbbbbbbbbbbbbbbbbbb','calendar','event')"));
  } finally {await db.close();}
});
