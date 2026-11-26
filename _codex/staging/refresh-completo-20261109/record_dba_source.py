"""Archive incoming/corrected SQL in the notebook without executing either load."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('dba_source_reader',W/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
receipt=W/'dba-source-notebook-receipt.json'
assert not receipt.exists(),'Inspect existing receipt before attempting recovery'
original=(W/'dba-load-review/script_perfil_br_corre_2026.sql').read_bytes().decode('utf-8')
final_path=reader.ROOT/'_codex/sql/2026-11-09_renovar_estudo_q3.sql'
adapted=final_path.read_text()
original_sha=hashlib.sha256(original.encode()).hexdigest()
adapted_sha=hashlib.sha256(adapted.encode()).hexdigest()
before=reader.query("""SELECT jsonb_build_object(
 'note',(SELECT jsonb_build_object('version',version,'hash',md5(content),'content',content) FROM estudo.notebook_cells WHERE id=419 AND NOT archived),
 'section',(SELECT jsonb_build_object('id',notebook_id,'book',caderno_id,'title',notebook_title) FROM estudo.notebooks WHERE notebook_id=63 AND NOT archived),
 'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'publication',publicacao_id,'status',status) ORDER BY id) FROM estudo.produtos),
 'public_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true)
 )::text AS payload""")
assert before['section']['book']==6
(W/'dba-source-notebook-before.json').write_text(json.dumps(before,ensure_ascii=False,indent=2))
marker='## Rotina do DBA recebida e adaptada — 09/11/2026'
assert marker not in before['note']['content'],'Status already registered; inspect before repeating'
appendix=f"""\n\n{marker}

O arquivo `script_perfil_br_corre_2026.sql` foi recebido deCarlos. A pendência de encontrar a rotina está resolvida. Original e SQL adaptado foram registrados na seção **2026 — Fontes BI do DBA**, com hashes e revisão; nenhum dos scripts de carga foi executado pelo notebook.

O original apaga/recria objetos públicos, confirma cada mês e chama gerações sem nascimento. Na fotografia de09/11 às16:09, seus filtros produziram os mesmos4.573.104IDs do universo aprovado; a chamada com dois argumentos, porém, difere em509.932 classificações operacionais. A chamada com quatro argumentos confere com as classificações vigentes da fato. Não desfazer essa correção.

**Próxima ação:** executar integralmente `_codex/sql/2026-11-09_renovar_estudo_q3.sql` numa conexãoDataGrip limpa, sem transação pendente. O datasourceColdFusion `runner_dba` temCREATE/ALTER/DROP/GRANT=false, confirmados em09/11; por isso a criação precisa dessa execução externa. O SQL cria a versão `estudo.fat_perfil_br_2026_20261109`, mantém os objetos públicos, carrega janeiro–setembro em umsnapshot e verifica IDs/valores/meses/dimensões antes de trocar os dois adaptadores `estudo`.

SQL adaptado SHA256 `{adapted_sha}`. Original SHA256 `{original_sha}`. Pré-check somente leitura concluído, SELECT com20colunas compilado e amostra de1000IDs validada. Essas verificações não substituem a execução e os controles pós-carga. O complemento operacional das views continua vivo conforme contrato anterior.

**Após a execução:** reler as revisões atuais das células; ajustar as auditorias413/454 e a proveniência para a versão nova (a fonte pública antiga permanece preservada); renovar as fontesBI, calendários/coorte e congelamentos; então validar e publicar leitores/hotsite/kit juntos. Q3 segue41/run233 e público239 até esse fechamento. O anual permaneceDRAFT e o recorte termina em30/09.
"""
intro=f"""# CargaBI2026 — original recebido do DBA em09/11/2026

**Referência preservada. Não executar o original diretamente:** ele contémDROP/CREATE eCOMMIT por mês e sua geração não prioriza nascimento. O executor do notebook é somente leitura e não permite essa carga.

Arquivo original: `script_perfil_br_corre_2026.sql`; SHA256 `{original_sha}`. Fonte: Carlos Pimenta. Foram preservadas as20colunas e o mapeamento do DBA na adaptação, mantendo o universo e a geração aprovados para o estudo. O SQL seguinte é o original, sem execução.
"""
adapted_intro=f"""# Carga versionada do estudo — candidata pronta para DataGrip

Executar o SQL seguinte **inteiro, numa conexão nova sem transação pendente**. Arquivo local: `_codex/sql/2026-11-09_renovar_estudo_q3.sql`; SHA256 `{adapted_sha}`.

Cria a versão emestudo, mantém a fato/viewpúblicas e as publicações congeladas, usa a função degeração com quatro argumentos e conservaNULLs. Os nove meses compartilham uma transaçãoREPEATABLE READ. Verifica20colunas da fato e contratos52/36 das views, IDs, valores, meses e perdas/duplicações nas dimensões; só depois troca os dois adaptadores do estudo. Se qualquer guarda falhar, não prosseguir com trechos isolados.

Ainda não executado. Depois do sucesso, renovar as consultas do estudo e as mensagens públicas. Rollback dos adaptadores preparado em `dba-load-candidate/40-rollback-study.sql`; a versão carregada não é apagada. Dimensões e complemento porid_resultado continuam vivos, conforme o contrato anterior. Não existe filtro global de tempo positivo/idade/modalidade; os recortes próprios de cada métrica continuam no notebook.
"""
cells=[dict(type='markdown',lang='markdown',content=intro),dict(type='code',lang='sql',content=original),
       dict(type='markdown',lang='markdown',content=adapted_intro),dict(type='code',lang='sql',content=adapted)]
cfg=dict(actor=json.loads((W/'preflight.json').read_text())['actor'],section=63,cells=cells,
         note_version=before['note']['version'],note_hash=before['note']['hash'],note=before['note']['content']+appendix)
encoded=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));transaction {'
cf+='q=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=419 AND NOT archived FOR UPDATE",{},{datasource="runner_dba",timeout=10});if(q.recordCount!=1 || q.version[1]!=cfg.note_version || q.hash[1]!=cfg.note_hash)throw(message="Nota mudou; reler antes de salvar.");'
cf+='svc=new estudo.includes.StudyNotebook().init();created=[];for(c in cfg.cells){dup=queryExecute("SELECT id FROM estudo.notebook_cells WHERE notebook_id=:section AND content=:content AND NOT archived",{section={value=cfg.section,cfsqltype="cf_sql_bigint"},content={value=c.content,cfsqltype="cf_sql_longvarchar"}},{datasource="runner_dba",timeout=10});if(dup.recordCount)throw(message="Uma fonte já foi registrada. Inspecionar antes de repetir.");saved=svc.createCell(cfg.section,c.type,c.lang,c.content,cfg.actor);structDelete(saved,"content");arrayAppend(created,saved);}'
cf+='note=svc.saveCell(419,cfg.note_version,"markdown","markdown",cfg.note,cfg.actor);structDelete(note,"content");report={"created":created,"note":note,"load_executed":false};}'
result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
result.update(original_sha256=original_sha,adapted_sha256=adapted_sha)
receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
