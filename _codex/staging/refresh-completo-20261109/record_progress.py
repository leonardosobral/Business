"""Record candidate status in the notebook and launch checklist, preserving edits."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('progress_reader',W/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
target=W/'progress-receipt.json'
assert not target.exists(),'Inspect existing progress receipt before recovery'
before=reader.query("""SELECT jsonb_build_object(
 'note',(SELECT jsonb_build_object('id',id,'version',version,'content',content,'hash',md5(content)) FROM estudo.notebook_cells WHERE id=419 AND NOT archived),
 'steps',(SELECT jsonb_agg(to_jsonb(s)) FROM(SELECT DISTINCT ON(detalhes->>'step') id AS version,detalhes->>'step' AS step,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' AND detalhes->>'step' IN('organizar','liberacao') ORDER BY detalhes->>'step',id DESC)s),
 'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'publication',publicacao_id,'status',status) ORDER BY id) FROM estudo.produtos),
 'validation_events',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113')
 )::text AS payload""")
(W/'progress-before.json').write_text(json.dumps(before,ensure_ascii=False,indent=2))
marker='## Renovação integral das fontes — 09/11/2026 — em andamento'
assert marker not in before['note']['content'],'Progress note already saved; inspect before retry'
runs=[json.loads(p.read_text())['run'] for p in sorted((W/'runs').glob('*.json'))]
ids=sorted(int(r['id']) for r in runs)
verified=reader.query("SELECT jsonb_build_object('runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'status',status,'frozen',frozen,'truncated',truncated)) FROM estudo.notebook_runs WHERE id IN("+','.join(map(str,ids))+")))::text AS payload")
assert len(runs)==len(verified['runs'])==32
assert all(r['status']=='ok' and r['frozen'] and not r['truncated'] for r in verified['runs'])
(W/'runs-verified.json').write_text(json.dumps(verified,ensure_ascii=False,indent=2))
audit=json.loads((W/'freshness-audit-receipt.json').read_text())
assert audit['run']['cell_id']=='454' and audit['run']['id']=='299'
appendix=f"""\n\n{marker}

Nova decisão: renovar todas as fontes do recorte de2026, inclusive os vínculos entre edições e as referências comparáveis de2025. O corte de provas continua01/01–30/09 nos dois anos. A coleta emnovembro não inclui automaticamente o quarto trimestre.

Foram congeladas32 execuções candidatas de fontes/derivadas (267–298), com revisões atuais relidas antes de executar. Perfil, atividades, mapeamento, cobertura, preços em preparação e referências históricas têm novas saídas. A soma de atividades377 rev2/run298 usa exatamente os nove novos congelamentos mensais. Nenhum critério analítico foi substituído. As sondagens de perfil/tempos/idades deMaratonas434/436/441 ainda usam a seleção histórica de41 provas; não tratá-las como seleção renovada do vertical.

**Bloqueio da renovação completa:** a fato pública tbbi_fat_perfil_br_2026 ainda contém4.502.542 IDs. A nova auditoria454 rev1/run299, no mesmo snapshot de09/11 às15:55, encontrou4.572.000 IDs operacionais elegíveis:70.186 novos,728 fatos fora da elegibilidade atual e170 datas divergentes. Os totais conservam os IDs; não houve duplicação. As fontes operacionais continuam recebendo mudanças.

**Ação necessária do DBA:** executar a rotina original de carga da fatoBI2026 (e dimensões pertinentes), preservando as regras e o corte até30/09, ou fornecer o SQL/nome da rotina para execução controlada. A rotina não foi localizada no notebook, nas funções do banco ou nos arquivos pesquisados. Nenhuma carga foi inventada; a fato compartilhada não foi modificada nesta renovação.

**Depois da carga:** auditar a conservação; recalcular panorama, idades/gerações, distâncias, tempos, geografia, porte eMaratonas; capturar ambos os calendários e refazer a coorte com os vínculos atuais; conferir e congelar os pacotes. Atualizar juntos leitorBusiness, imprensa, narrativa pública, kit, release e textos da central. Os geradores candidatos e mapas de dependência estão preparados emstaging, sem dados sintéticos publicados.

**Publicação preservada:** Q3 segue publicação41/run233, narrativa pública239; +2,1%/+33,9% continuam sendo os valores da edição publicada deoutubro, sem afirmar que foram renovados. O anual continuaDRAFT. Nenhuma nova prévia foi liberada, nenhum contrato/campanha/convite foi alterado. O principal anual2025 segue sua versão dinâmica publicada; as novas referênciasJan–Set não substituem os denominadores do ano completo.

Leo eCarlos continuam responsáveis. Na central, a renovação foi acrescentada às etapas de organização e liberação, sem validar nenhuma etapa. Fontes e resultados antigos seguem disponíveis no histórico.
"""
steps=[]
suffix='\n\nRENOVAÇÃO DAS FONTES (09/11)\nCandidatos congelados. Falta o DBA renovar a fatoBI2026; depois recalcular coorte e publicar leitor/kit juntos. Auditoria e bloqueio registrados no notebook419 e454/run299. Edição pública anterior preservada.'
for step in before['steps']:
    notes=step['notes']+suffix
    assert len(notes)<=2000,(step['step'],len(notes))
    steps.append(dict(step=step['step'],version=str(step['version']),responsible=step['responsible'],notes=notes))
cfg=dict(actor=json.loads((W/'preflight.json').read_text())['actor'],
         version=before['note']['version'],hash=before['note']['hash'],
         content=before['note']['content']+appendix,steps=steps)
(W/'progress-proposed.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2))
encoded=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));'
cf+='transaction { current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=419 AND NOT archived",{},{datasource="runner_dba",timeout=10});'
cf+='if(current.recordCount!=1 || current.version[1]!=cfg.version || current.hash[1]!=cfg.hash)throw(message="Nota alterada. Reler antes de salvar.");'
cf+='svc=new estudo.includes.StudyNotebook().init();saved=svc.saveCell(419,cfg.version,"markdown","markdown",cfg.content,cfg.actor);structDelete(saved,"content");'
cf+='report={"note":saved};}'
result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
target.write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps({'note_revision':result['note']['version'],'checklist_pending_authenticated_ui':[s['step'] for s in steps],'published':False},ensure_ascii=False))
