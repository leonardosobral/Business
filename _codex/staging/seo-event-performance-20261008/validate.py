from pathlib import Path
import copy, hashlib, json, re, shlex, subprocess

S=Path(__file__).resolve().parent;B=S.parents[2];NAME='includes/backend/backend_evento.cfm'
def sql(group,aggregate):
    src=(S/group/'rr'/NAME).read_text()
    q=re.search(r'<cfquery name="qEventoEdicoes"[^>]*>(.*?)</cfquery>',src,re.S).group(1)
    q=re.sub(r'<cfqueryparam[^>]*value="#VARIABLES.eventRecordAssetsBaseUrl#"[^>]*/>',"'https://roadrunners.run/assets/paginas/'",q)
    q=re.sub(r'<cfqueryparam[^>]*value="#qEvento.id_agrega_evento#"[^>]*/>',str(int(aggregate)),q)
    assert '<cf' not in q
    return q
def literal(value,typ):
    if value is None:return 'NULL::'+typ
    if isinstance(value,bool):return ('true' if value else 'false')+'::'+typ
    if isinstance(value,(int,float)):return str(value)+'::'+typ
    return "'"+value.replace("'","''")+"'::"+typ
def table(name,columns,rows):
    if rows:
        values=',\n'.join('('+','.join(literal(row.get(k),t) for k,t in columns)+')' for row in rows)
        return name+'('+','.join(k for k,t in columns)+') AS (VALUES '+values+')'
    return name+' AS (SELECT '+','.join('NULL::'+t+' AS '+k for k,t in columns)+' WHERE false)'
result_columns=[('id_evento','integer'),('tempo_total','time'),('nome','text'),('id_usuario','integer'),('classificacao_sexo','integer'),('percurso','numeric'),('sexo','text'),('concluinte','boolean'),('homologado','boolean'),('status_final','integer'),('pcd','boolean'),('nome_categoria','text'),('modalidade','text')]
def result(name='Fixture A',sex='M',**kw):
    r=dict(id_evento=1,tempo_total='00:45:00',nome=name,id_usuario=1,classificacao_sexo=1,percurso=10,sexo=sex,concluinte=True,homologado=True,status_final=0,pcd=False,nome_categoria='Geral',modalidade='Corrida');r.update(kw);return r
def page(id=10,**kw):
    r=dict(id_pagina=id,tag='fixture-'+str(id),tag_prefix='atleta',perfil_publico=True,nome='Fixture A',apelido='',path_imagem='fixture.png');r.update(kw);return r
def fixture(c):
    events=[dict(id_evento=1,nome_evento='Fixture Race',cidade='Fixture City',estado='SC',pais='Brasil',data_inicial='2026-10-01',data_final='2026-10-01',tag='fixture-race',status_evento='concluido',id_agrega_evento=42,concluintes=50)]
    definitions=[
        table('vw_evento_corridas',[(k,'integer' if k in ['id_evento','id_agrega_evento','concluintes'] else 'date' if k.startswith('data_') else 'text') for k in events[0]],events),
        table('tb_resultados',result_columns,c['results']),
        table('tb_resultados_resumo',[('id_evento','integer'),('percurso','numeric'),('modalidade','text')],c.get('summary',[dict(id_evento=1,percurso=10,modalidade='Corrida')])),
        table('tb_usuarios',[('id','integer'),('name','text'),('aka','text'),('strava_profile','text'),('imagem_usuario','text')],c.get('users',[dict(id=1,name='Fixture A',aka='',strava_profile='',imagem_usuario='')])),
        table('tb_paginas_usuarios',[('id_usuario','integer'),('id_pagina','integer')],c.get('links',[dict(id_usuario=1,id_pagina=10)])),
        table('tb_paginas',[('id_pagina','integer'),('tag','text'),('tag_prefix','text'),('perfil_publico','boolean'),('nome','text'),('apelido','text'),('path_imagem','text')],c.get('pages',[page()]))]
    return ',\n'.join(definitions)
cases=[]
def add(name,results,**kw):cases.append(dict(name=name,results=results,**kw))
add('no-results',[],expected_m='')
add('male-and-female',[result(),result('Fixture B','F',id_usuario=None)],expected_m='Fixture A',expected_f='Fixture B')
for sex in ['MASC','MASCULINO','MASCULINA',' m ']:add('male-alias-'+sex.strip(),[result(sex=sex)],expected_m='Fixture A')
for sex in ['FEM','FEMININO','FEMININA',' f ']:add('female-alias-'+sex.strip(),[result(sex=sex)],expected_f='Fixture A')
add('classification-before-time',[result(tempo_total='00:55:00'),result('Fixture B',classificacao_sexo=2,tempo_total='00:30:00')],expected_m='Fixture A')
add('positive-before-missing',[result(classificacao_sexo=None,tempo_total='00:20:00'),result('Fixture B',classificacao_sexo=2)],expected_m='Fixture B')
add('zero-before-null',[result(classificacao_sexo=None,tempo_total='00:20:00'),result('Fixture B',classificacao_sexo=0)],expected_m='Fixture B')
for field,value in [('concluinte',False),('homologado',False),('status_final',3),('pcd',True),('nome_categoria','Geral PCD'),('modalidade','Corrida PCD'),('tempo_total','00:00:00'),('tempo_total',None),('percurso',5),('sexo','X')]:
    add('excluded-'+field+'-'+str(value),[result(**{field:value}),result('Fixture B',id_usuario=None)],expected_m='Fixture B')
add('nullable-final-flags',[result(concluinte=None,homologado=None,status_final=None,pcd=None)],expected_m='Fixture A')
add('summary-distance-floor',[result(percurso=10.8)],summary=[dict(id_evento=1,percurso=10.2,modalidade='Corrida')],expected_m='Fixture A')
add('fallback-distance',[result(percurso=10.8)],summary=[],expected_m='Fixture A')
add('empty-distance',[],summary=[],expected_m='')
add('wrong-importer-name',[result('Fixture B')],expected_m='Fixture B',expected_link=False)
add('matching-alias',[result('Fixture Alias')],users=[dict(id=1,name='Other',aka='Fixture Alias')],pages=[page(nome='Other')],expected_m='Fixture Alias',expected_link=True)
add('private-profile',[result()],pages=[page(perfil_publico=False)],expected_m='Fixture A',expected_tag='')
add('non-athlete-profile',[result()],pages=[page(tag_prefix='organizador')],expected_m='Fixture A',expected_tag='')
add('multiple-pages-tie',[result()],links=[dict(id_usuario=1,id_pagina=20),dict(id_usuario=1,id_pagina=10)],pages=[page(20),page(10)],expected_m='Fixture A',expected_tag='fixture-10')
add('different-athletes-tie',[result(),result('Fixture B',id_usuario=2)],users=[dict(id=1,name='Fixture A'),dict(id=2,name='Fixture B')],links=[dict(id_usuario=1,id_pagina=20),dict(id_usuario=2,id_pagina=10)],pages=[page(20),page(10,nome='Fixture B')],expected_m='Fixture B',expected_tag='fixture-10')
add('private-tie-cannot-be-preferred',[result(),result('Fixture B',id_usuario=2)],users=[dict(id=1,name='Fixture A'),dict(id=2,name='Fixture B')],links=[dict(id_usuario=1,id_pagina=5),dict(id_usuario=2,id_pagina=10)],pages=[page(5,perfil_publico=False),page(10,nome='Fixture B')],expected_m='Fixture B',expected_tag='fixture-10')
def compare_query(before,after,prefix='',expected=None):
    ctes=(prefix+',\n' if prefix else '')+'previous AS MATERIALIZED ('+before+'), current AS MATERIALIZED ('+after+')'
    assertions=['(SELECT count(*) FROM previous) AS previous_rows','(SELECT count(*) FROM current) AS current_rows','(SELECT count(*) FROM ((SELECT * FROM previous EXCEPT ALL SELECT * FROM current) UNION ALL (SELECT * FROM current EXCEPT ALL SELECT * FROM previous)) d) AS differences']
    for k,column in [('expected_m','nome_campeao_masculino'),('expected_f','nome_campea_feminina'),('expected_tag','tag_campeao_masculino')]:
        if expected is not None and k in expected:assertions.append('(SELECT coalesce('+column+",'') = "+literal(expected[k],'text')+' FROM current) AS '+k)
    if expected is not None and 'expected_link' in expected:assertions.append('(SELECT vinculo_reconhecido_campeao_masculino = '+literal(expected['expected_link'],'boolean')+' FROM current) AS expected_link')
    return 'WITH '+ctes+' SELECT '+','.join(assertions)
tests=[dict(name=c['name'],sql=compare_query(sql('baseline',42),sql('candidate',42),fixture(c),c)) for c in cases]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
code=helpers+'''
p=json.load(sys.stdin);body='report={checks=[]};transaction {'+raw_query("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')
for item in p['tests']:
 body+=raw_query(item['sql'],'qCheck')+'row={name="'+item['name']+'"};for(c in listToArray(qCheck.columnList)){row[lCase(c)]=qCheck[c][1];}arrayAppend(report.checks,row);'
body+='}'
print(json.dumps(bridge(ROOT,body)))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(code)],input=json.dumps({'tests':tests}),capture_output=True,text=True,timeout=115)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);checks=r['CHECKS'];failed=[x for x in checks if x['differences']!=0 or x['previous_rows']!=x['current_rows'] or not all(v for k,v in x.items() if k.startswith('expected_'))]
r.update(failed=failed,source_hash=hashlib.sha256((S/'candidate/rr'/NAME).read_bytes()).hexdigest(),fixture_only=True,database_mutations=False)
(S/'tests.json').write_text(json.dumps(r,indent=2));print(json.dumps({'checks':len(checks),'failed':failed}));assert not failed
