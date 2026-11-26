from pathlib import Path
import base64,hashlib,importlib.util,json
W=Path(__file__).resolve().parent;S=W.parent
assert json.loads((W/'verify-receipt.json').read_text())=={'business':{'verified_hashes':15},'portal':{'verified_hashes':24}}
assert json.loads((W/'http-verification.json').read_text())['public']['calendar']==38.7
assert all(json.loads((W/'cutover-proof-receipt.json').read_text()).values())
spec=importlib.util.spec_from_file_location('reader',S/'inspect.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
query="""SELECT jsonb_build_object('note',(SELECT jsonb_build_object('version',version,'hash',md5(content),'content',content) FROM estudo.notebook_cells WHERE id=419 AND NOT archived),'steps',(SELECT jsonb_agg(to_jsonb(s)) FROM(SELECT DISTINCT ON(detalhes->>'step') id AS version,detalhes->>'step' AS step,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)s),'validation_events',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113'),'destinations',(SELECT jsonb_agg(to_jsonb(d) ORDER BY ano) FROM estudo.web_destinos d),'products',(SELECT jsonb_agg(jsonb_build_object('id',id,'code',codigo,'status',status,'publication',publicacao_id) ORDER BY id) FROM estudo.produtos),'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'version',c.version,'hash',md5(c.content))) FROM estudo.notebook_cells c JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id WHERE n.caderno_id=6 AND NOT c.archived))::text AS payload"""
before=r.query(query);(W/'closure-before.json').write_text(json.dumps(before,ensure_ascii=False,indent=2))
expected=json.loads((W/'central-ui-proposed.json').read_text());old=json.loads((W/'central-ui-before.json').read_text())
for step in before['steps']:
 assert step['notes']==expected.get(step['step'],old[step['step']]),('Notes concurrent change',step['step'])
assert before['validation_events']==0
marker='## Renovação concluída e publicada — 09/11/2026'
assert marker not in before['note']['content'],'Already recorded; inspect receipt before retry'
appendix='''

## Renovação concluída e publicada — 09/11/2026

A carga adaptada e o corte final foram executados pelo responsável no DataGrip. A tabela versionada estudo.fat_perfil_br_2026_20261109 tem4.574.981 IDs de resultado únicos e4.966 eventos elegíveis. A carga usa o snapshot308969104:308969104:, de09/11 às16:55; suas nove parcelas mensais e os controles de conservação passaram. A fato/view públicas originais foram preservadas. Localidades ausentes e tempos zero permanecem conservados; os recortes explicam suas exclusões analíticas.

**Fontes publicadas:** saída251 rev42/run351, contrato18, publicação42. Pareamento387 rev3/run329:615 pares,614 por vínculo e1 por nome. Soma1.191.628→1.218.094 participações, taxa exata2.220995142779458018777672200%, exibida+2,2%. CalendárioJan–Set5.898→8.179 cadastros,+38,7%; eventos com coleta3.232→4.975. Participações elegíveis3.537.379→4.574.981,+29,3%. Calendário, captura e pares são universos distintos e não isolam crescimento real do mercado.

A narrativa pública420 rev7/run352 usa a mesma origem42/351, seis destaques e três comparações. Mulheres53,8%; Millennials46,1%; percursoscurtos61,4%; interior48,0%; terceirotrimestre43,2%; concentração48,1%. O período de provas continua01/01–30/09 nos dois anos; coleta emnovembro não incluiQ4. Perfil, preços, cobertura e demais temas conservam suas populações e datas próprias documentadas nos congelamentos.

**Publicação coordenada:** leitoresBusiness/imprensa compatíveis foram compilados e publicados antes do corte. A transação DataGrip atualizou juntos destino2026(42/vers23), produtoQ3(42) e view pública(run352). Depois foram publicados e conferidos39 arquivos emBusiness/portal: leitores, web deMaratonas eCSVs, hotsite,17arquivos do kit, release/convite, guia1página eexecuçãov7. As37páginas do profissional foram preservadas. PDFs/versões históricos seguem disponíveis; não foi geradoPDF deMaratonas.

**Maratonas:** seção66 com congelamentos renovados,39provas/61.452conclusões na seleção editorialJan–Set2026 e41/54.234 na referência2025; todas as provas continuam listadas. Floripa mantém a fonte oficial402/run210(3.592 classificados) e explicita a diferença paraBI. Dois novos candidatos de inventário aguardam revisão, sem inclusão automática. Boston/NovaYork preservam suas fontes datadas. Principal anual2025 continua publicação37/run205; referênciasJan–Set2025 renovadas não substituem o ano inteiro.

**Anual interno:**418 rev3/run353 renovado como rascunho; produto anual permaneceDRAFT e sem publicação comercial. Preços/descontos/kits/lotes,CNA,ritmo nacional42km,revisão cadastral eQ4 continuam na trilha do anual.

**Conferência:** validador18,conservação das fontes,compilaçãoCFML,hashes39/39,HTTP público/imprensa e leituraBusiness autenticada aprovados. Coorte615 e taxas2,2/38,7 conferidas no navegador; API pública entrega só indicadores permitidos. Anônimo não lêBusiness/PDFinterno. ContratoABRACEO,piloto real,aprovação editorial e contatos continuam pendentes comLeo eCarlos; nenhuma etapa foi validada e nenhum convite/post enviado. Lançamento13/11,95vouchers/resgate24/11 e benefício50% preservados. Acesso temporariamente aberto da imprensa e noindex mantidos conforme decisões existentes.

SQL original doDBA e adaptação continuam nas células455–458. Consultas foram relidas e revisadas com controle deversão, sem substituir alterações concorrentes doDBA; resultados anteriores permanecem congelados nohistórico. Recibos,manifestos ebackups recuperáveis estão em_codex/staging/refresh-completo-20261109/final-release e/var/backups/study-refresh-q3-20261109-final.
'''
cfg={'actor':json.loads((S/'preflight.json').read_text())['actor'],'version':before['note']['version'],'hash':before['note']['hash'],'content':before['note']['content']+appendix}
(W/'closure-note-proposed.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2))
encoded=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));transaction{current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=419 AND NOT archived",{},{datasource="runner_dba",timeout=10});if(current.recordCount!=1||current.version[1]!=cfg.version||current.hash[1]!=cfg.hash)throw(message="Nota alterada. Reler antes de salvar.");svc=new estudo.includes.StudyNotebook().init();saved=svc.saveCell(419,cfg.version,"markdown","markdown",cfg.content,cfg.actor);structDelete(saved,"content");report={note=saved};}'
result=r.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf});(W/'closure-note-receipt.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
after=r.query(query);assert after['note']['content']==cfg['content'] and after['note']['version']==before['note']['version']+1
assert after['validation_events']==0 and after['products']==before['products'] and after['destinations']==before['destinations']
(W/'closure-after.json').write_text(json.dumps(after,ensure_ascii=False,indent=2));print(json.dumps({'note_revision':after['note']['version'],'central_notes':list(expected),'stages_validated':0,'annual_draft':True,'published':True}))
