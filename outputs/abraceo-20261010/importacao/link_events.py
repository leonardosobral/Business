from pathlib import Path
import base64,json,shlex,subprocess
root=Path(__file__).resolve().parents[3];out=Path(__file__).parent
pairs=[(53,45372),(53,46865),(53,45442),(63,47969),(63,43912),(63,40609),(63,42066),(35,42360),(35,37144),(59,36659),(59,39384)]
before=json.loads((out/'eventos-before.json').read_text());assert all(e['contas']=='[]' and e['data_inicial']>'2026-10-11' and e['ativo'] for e in before)
values=','.join('(%s,%s)'%p for p in pairs)
sql=f'''WITH target(id_conta,id_evento) AS (VALUES {values})
SELECT jsonb_agg(jsonb_build_object('id_conta',t.id_conta,'id_evento',e.id_evento,'nome_evento',e.nome_evento,'data_inicial',e.data_inicial,'status',ce.status,'id_conta_evento',ce.id_conta_evento))::text payload
FROM target t JOIN tb_evento_corridas e USING(id_evento) LEFT JOIN tb_conta_eventos ce ON ce.id_conta=t.id_conta AND ce.id_evento=t.id_evento'''
def q(s):return 'q=queryExecute(toString(binaryDecode("'+base64.b64encode(s.encode()).decode()+'","base64")),{}, {datasource="runner_dba"});'
body='transaction {'+q("SET LOCAL lock_timeout='3s'")+q('LOCK TABLE tb_conta_eventos IN SHARE ROW EXCLUSIVE MODE')
body+=q("SELECT usuario_cadastro FROM tb_conta_eventos WHERE id_conta=53 AND id_evento=45372 AND status='ATIVO'")+'if(q.recordCount!=1)throw(message="UI actor not verified");'
body+=q(f"WITH target(id_conta,id_evento) AS (VALUES {values}) SELECT count(*) n FROM target t JOIN tb_evento_corridas e USING(id_evento) JOIN tb_contas c ON c.id_conta=t.id_conta WHERE e.ativo=true AND e.data_inicial::date>'2026-10-11' AND c.status='PENDENTE'")+'if(q.n[1]!=11)throw(message="Event/account eligibility changed");'
body+=q(f"WITH target(id_conta,id_evento) AS (VALUES {values}) SELECT count(*) n FROM tb_conta_eventos ce JOIN target t USING(id_evento) WHERE NOT (ce.id_conta=53 AND ce.id_evento=45372 AND ce.status='ATIVO')")+'if(q.n[1]!=0)throw(message="Conflicting event association");'
body+=q(f"INSERT INTO tb_conta_eventos(id_conta,id_evento,status,usuario_cadastro) SELECT t.id_conta,t.id_evento,'ATIVO',actor.usuario_cadastro FROM (VALUES {values}) t(id_conta,id_evento) CROSS JOIN (SELECT usuario_cadastro FROM tb_conta_eventos WHERE id_conta=53 AND id_evento=45372 AND status='ATIVO') actor WHERE t.id_evento<>45372 RETURNING id_conta_evento")+'if(q.recordCount!=10)throw(message="Wrong inserted count");'
# Explicit user approval on 11/10/2026: use luiz@hleventos.com as principal and retain both in research profile.
body+=q("UPDATE tb_contas SET email_principal='luiz@hleventos.com',data_atualizacao=now() WHERE id_conta=39 AND documento='15135804000175' AND status='PENDENTE' AND email_principal='luiz@hleventos.com | contato@hleventos.com' RETURNING id_conta")+'if(q.recordCount!=1)throw(message="Email normalization baseline changed");'
body+=q(sql)+'report={eventos=deserializeJSON(q.payload[1]),novos_vinculos=10,anterior_via_interface=1,email_normalizado=1};}'
source=(root/'_codex/scripts/deploy_estudo.py').read_text();bridge=source[source.index('def bridge('):source.index('\ndef raw_query(')]
remote='from pathlib import Path\nimport os,tempfile,subprocess,json,shutil\n'+bridge+'\nstage=Path("/var/backups/business-abraceo-precadastro-20261011")\nassert not (stage/"eventos-linked.json").exists()\n(stage/"eventos-before.json").write_text('+repr(json.dumps(before))+')\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\n(stage/"eventos-linked.json").write_text(json.dumps(r))\nprint(json.dumps(r))'
a=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)]
r=subprocess.run(a,capture_output=True,text=True,timeout=115)
if r.returncode:raise SystemExit(r.stderr[-3000:])
d=json.loads(r.stdout);(out/'eventos-linked.json').write_text(json.dumps(d,ensure_ascii=False,indent=2));print({'vinculos_confirmados':len(d['EVENTOS'])})
