// Run with FUNNEL_SQL_PGLITE_MODULE pointing to an isolated PGlite installation.
// No production connection or real user data is used.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const {PGlite} = await import(pathToFileURL(process.env.FUNNEL_SQL_PGLITE_MODULE).href);
const db = new PGlite();
const include = await readFile(new URL('../../portal/funil/includes/ticketsports_coupons.cfm', import.meta.url), 'utf8');
const sql = include.match(/<cfsavecontent[^>]*>([\s\S]*?)<\/cfsavecontent>/)[1].trim().replace(/,$/, '').replaceAll(':coupon_cohort','$3');
try {
  await db.exec(`
    CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY,email text,data_criacao timestamp);
    CREATE TABLE public.tb_ticketsports_pedidos(cod_evento integer,numero_pedido integer,body jsonb,PRIMARY KEY(cod_evento,numero_pedido));
    CREATE TABLE public.tb_ticketsports_participantes(cod_evento integer,numero_inscricao integer,numero_pedido integer,body jsonb,data_pedido timestamp,email text,modalidade text,PRIMARY KEY(cod_evento,numero_inscricao));
    INSERT INTO public.tb_usuarios VALUES
      (1,' A@EXAMPLE.TEST ','2020-01-01'),(2,'b@example.test','2026-02-01'),
      (3,'shared@example.test','2020-01-01'),(4,'SHARED@example.test','2027-01-01'),
      (5,'future@example.test','2027-01-01'),(6,'c+tag@example.test','2020-01-01');
  `);
  const participant = async (id, {event=10,order=id,email='a@example.test',column=email,code='ROADRUNNERS',title='',status='Pago',date='2026-10-01'}={}) => {
    await db.query('INSERT INTO public.tb_ticketsports_pedidos VALUES ($1,$2,$3) ON CONFLICT DO NOTHING', [event,order,{status,evento:{tituloEvento:`Prova sintética ${event}`}}]);
    await db.query('INSERT INTO public.tb_ticketsports_participantes VALUES ($1,$2,$3,$4,$5,$6,$7)', [event,id,order,{email,codigoCupom:code,tituloCupom:title,modalidade:'21K'},date,column,'21K']);
  };
  await participant(1,{code:' roadrunners '});
  await participant(2,{code:'',title:'ROADRUNNERS (Influ x 10% cashback)',date:'2026-10-02'});
  await participant(3,{event:20,order:1,email:'b@example.test',date:'2026-09-01'});
  await participant(4,{email:'b@example.test',status:'Cancelado'});
  await participant(5,{email:'shared@example.test'});
  await participant(6,{email:'absent@example.test'});
  await participant(7,{email:null,column:null});
  await participant(8,{email:'invalid'});
  await participant(9,{email:'a@example.test',column:'b@example.test'});
  await participant(10,{email:'future@example.test'});
  await participant(11,{date:'2026-10-12'});
  await participant(12,{date:null});
  await participant(13,{code:'OTHER'});
  await participant(14,{code:'OTHER',title:'ROADRUNNERS'});
  await participant(15,{code:'ROADRUNNERSFAKE'});
  await participant(16,{email:'c@example.test'});
  await participant(17,{email:' C+TAG@EXAMPLE.TEST ',column:'c+tag@example.test'});
  const report = async (cohort=false, until='2026-10-12') => (await db.query(`
    WITH bounds AS (SELECT CAST($1 AS timestamp) AT TIME ZONE 'America/Sao_Paulo' AS starts_at,CAST($2 AS timestamp) AT TIME ZONE 'America/Sao_Paulo' AS until_at),
    base AS (SELECT u.id FROM public.tb_usuarios u CROSS JOIN bounds b WHERE u.id>0 AND u.data_criacao<(b.until_at AT TIME ZONE 'America/Sao_Paulo') ${cohort ? "AND u.data_criacao>=(b.starts_at AT TIME ZONE 'America/Sao_Paulo')" : ''}),
    ${sql}
    SELECT (SELECT row_to_json(s) FROM coupon_stats s) AS stats,
      (SELECT json_agg(p ORDER BY user_id) FROM coupon_people p) AS people,
      (SELECT json_agg(json_build_object('id',numero_inscricao,'status',match_status) ORDER BY numero_inscricao) FROM coupon_matches) AS matches
  `,['2026-01-01',until,cohort])).rows[0];
  const base = await report();
  assert.deepEqual(base.stats,{registrations:11,matched:4,unmatched:2,ambiguous:1,conflicting:1,invalid:2,outside_base:1});
  assert.deepEqual(base.people.map(p=>[p.user_id,p.registrations,p.events,p.last_event]),[[1,2,1,'Prova sintética 10'],[2,1,1,'Prova sintética 20'],[6,1,1,'Prova sintética 10']]);
  assert.equal(base.people[0].last_at.slice(0,10),'2026-10-02');
  assert.deepEqual(base.matches.map(m=>m.id),[1,2,3,5,6,7,8,9,10,16,17]);
  const cohort = await report(true);
  assert.deepEqual(cohort.people.map(p=>p.user_id),[2]);
  assert.equal(cohort.stats.ambiguous,1); // A duplicate outside the cohort still prevents a false link.
  assert.equal(cohort.stats.outside_base,4);
  const cutoff = await report(false,'2026-10-02');
  assert.equal(cutoff.people.find(p=>p.user_id===1).registrations,1);
  assert.equal(Object.values(base.stats).slice(1).reduce((sum,n)=>sum+n,0),base.stats.registrations);
  await db.exec(`
    INSERT INTO public.tb_usuarios SELECT i,'synthetic-' || i || '@example.test','2020-01-01'::timestamp FROM generate_series(100,50099) i;
    INSERT INTO public.tb_ticketsports_pedidos SELECT 100,i,jsonb_build_object('status','Pago','evento',jsonb_build_object('tituloEvento','Prova sintética de volume')) FROM generate_series(100,10099) i;
    INSERT INTO public.tb_ticketsports_participantes SELECT 100,i,i,jsonb_build_object('email','synthetic-' || i || '@example.test','codigoCupom','ROADRUNNERS'), '2026-10-01'::timestamp,'synthetic-' || i || '@example.test','21K' FROM generate_series(100,10099) i;
  `);
  const volume = await report();
  assert.equal(volume.stats.matched,10004);
  assert.equal(volume.people.length,10003);
  console.log('Funnel coupons SQL: PASS (unique people, repeated registrations, exact aliases, paid orders, event/order keys, dates, cohort, ambiguity, conflicting/missing emails, no email alias guessing)');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally { await db.close(); }
