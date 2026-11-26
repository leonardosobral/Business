"""Assemble the full canonical vertical from explicitly frozen sources only.

Writes candidates inside this isolated stage. Preserves Boston/NYC captures,
editorial lists and all current chapters. No SQL execution or publication here.
"""
from pathlib import Path
import copy,csv,hashlib,importlib.util,json,re,sys
W=Path(__file__).resolve().parent;BASE=W.parent;BUSINESS=BASE.parents[2];RR=BUSINESS.parent/'RoadRunners'
sys.path.insert(0,str(W));import derive
RUNS=derive.runs()


def rows(cell):
    r=RUNS[cell]
    return r['result']['rows']


def payload(cell):
    p=rows(cell)[0]['payload']
    return json.loads(p) if isinstance(p,str) else p


def exact(s,old,new):
    assert s.count(old)==1,(old,s.count(old))
    return s.replace(old,new)


def date_br(stamp):
    iso=str(stamp)[:10];return iso[8:10]+'/'+iso[5:7]+'/'+iso[:4]


def run(cell):return RUNS[cell]


def series_from(p):
    ss=[]
    for s in p['series']:
        cs=[c for c in p['comparacoes']if c['serie']==s['id']];by={c['categoria']:c for c in cs}
        assert len(by)==len(cs),'Duplicate main comparison category'
        labels=list(dict.fromkeys([r['rotulo']for r in s['valores']]+[c['categoria']for c in cs]))
        vals=[]
        for label in labels:
            a=by.get(label,{}).get('atual') or {}
            vals.append({'label':label,'value':a.get('valor'),'count':a.get('contagem'),'denominator':a.get('denominador'),'source':a.get('fonte'),'note':a.get('nota'),'unit':a.get('unidade',s['unidade'])})
        ss.append({'id':s['id'],'unit':s['unidade'],'note':s.get('ressalva'),'values':vals})
    return ss


def assemble():
    old=json.loads((W/'baseline/data.json').read_text());D=copy.deepcopy(old)
    specials=rows(432);official=next(v['result']['rows'][0]['payload']for v in specials if int(v['id'])==210)
    chapters={int(v['ano']):v['payload']for v in rows(433)}
    age_fields=['total','nascimento','pela_faixa','sem_informacao','dado_invalido','fora_faixa_padrao','geracao_indeterminada','faixa_ampla_geracao_util','range_bi_diverge_operacional','range_so_no_operacional']
    for year,inv,sel,prof,detail,age in [(2025,425,427,434,436,441),(2026,426,428,435,437,442)]:
        Y=D['years'][str(year)];selection=copy.deepcopy(rows(sel));inventory=copy.deepcopy(rows(inv));selected=[v for v in selection if v.get('decisao','selecionada')=='selecionada']
        old_ids={r['id_evento']for r in old['years'][str(year)]['races']};new_ids={r['id_evento']for r in selected};assert new_ids==old_ids,'Editorial selection changed'
        details=copy.deepcopy(payload(detail));assert {r['id_evento']for r in details['provas']}==new_ids
        for r in details['provas']:
            r['source']=f"Base{year} · célula{detail} · congelamento{run(detail)['id']} · coleta{date_br(run(detail)['started_at'])}"
            r['periodo']='Anual' if year==2025 else 'Jan–Set'
            if year==2026 and r['id_evento']==34529:
                o=official['classificados_geral_elite'];r['bi_total']=r['total']
                for dest,src in [('total','concluintes'),('feminino','feminino'),('masculino','masculino'),('minimo','menor_segundos'),('media','medio_segundos'),('mediana','mediano_segundos'),('sub2h30','sub2h30'),('sub3','sub3'),('sub4','sub4')]:r[dest]=o[src]
                for g in official['grupos']:r[g['grupo']]=g['medio_segundos']
                r['source']='RaceTag oficial · célula402/congelamento210 · captura05/10/2026; histograma/perfil BI próprios'
        audit=copy.deepcopy(payload(age));profile=audit.pop('profile');totals={key:sum(r[key]for r in audit['provas'])for key in age_fields}
        def stable(rr):return sorted((r['bloco'],r['sexo'],r['categoria'],r['total'],r['denominador'],r['distancia'])for r in rr if r['bloco']!='idade')
        assert stable(profile)==stable(rows(prof)),'Non-age dimensions differ between profile and decade audit'
        assert totals['nascimento']+totals['pela_faixa']+totals['sem_informacao']+totals['dado_invalido']==totals['total']
        for sex in ('geral','F','M'):
            age_rows=[r for r in profile if r['bloco']=='idade'and r['sexo']==sex]
            assert sum(r['total']for r in age_rows)==age_rows[0]['denominador']
        assert sum(b['total']for b in details['tempos'])==totals['total'],'Histogram conservation failed'
        for r in details['provas']:
            bi=r.get('bi_total',r['total']);assert sum(b['total']for b in details['tempos']if b['id_evento']==r['id_evento'])==bi
            assert r['sub2h30']<=r['sub3']<=r['sub4']<=r['total']
        audit.update(totals=totals,run_id=run(age)['id'],coletado_em=run(age)['started_at'])
        Y.update(series=series_from(chapters[year]),profile=profile,races=details['provas'],bins=details['tempos'],inventory=inventory,selection=selection,meta=chapters[year]['meta'])
        D['age_audit'][str(year)]=audit;D['notes'][str(year)]={'profile_total':totals['total'],'official_total':sum(r['total']for r in details['provas'])}
        for name,cell in [(f'perfil-{year}',prof),(f'provas-{year}',detail),(f'perfil-decadas-{year}',age)]:D['runs'][name]=run(cell)['id']
    D['pairs']=copy.deepcopy(payload(429));D['pairs2025']=copy.deepcopy(payload(446));D['pairs2025']['run']=run(446)['id']
    D['context']=copy.deepcopy(payload(449));D['context']['run']=run(449)['id']
    D['brasil_gigante']=copy.deepcopy(payload(453));G=D['brasil_gigante'];G['meta'].update(status='frozen',publication_run=run(453)['id'],publication_cell=453,frozen_date=date_br(run(453)['started_at']))
    D['runs'].update(capitulo=run(433)['id'],especiais=run(432)['id'],**{f'cell-{c}':run(c)['id']for c in [423,424,425,426,427,428,429,433,434,435,436,437,441,442,444,445,446,449,452,453]})
    # Boston and the NYC capture remain historical independent sources.
    assert D['boston']==old['boston'];assert D['context']['nyc']==old['context']['nyc']
    assert set(D)==set(old),'Canonical chapter lost/added unexpectedly'
    assert len(D['brasil_gigante']['stages'])==8
    P=D['pairs']['coorte'];assert sum(p['n2025']for p in D['pairs']['pares'])==P['n2025'];assert sum(p['n2026']for p in D['pairs']['pares'])==P['n2026'];assert len(D['pairs']['pares'])==P['pares']
    C=G['cohort'];paired=[s for s in G['stages']if s['comparable']];assert len(paired)==C['pairs']==6
    assert sum(s['metrics2025']['total']for s in paired)==C['base_total'];assert sum(s['metrics2026']['total']for s in paired)==C['total']
    A=G['adoption'];assert sum(v['accounts']for v in A['distribution'])==A['registered'];assert sum(v['accounts']for v in A['distribution']if v['stages']>0)==A['with_result'];assert sum(v['accounts']for v in A['distribution']if v['stages']>1)==A['two_or_more']
    (W/'data.json').write_text(json.dumps(D,ensure_ascii=False,separators=(',',':')))
    return D


def renderer(D):
    js=(W/'baseline/maratonas-detalhado.js').read_text();before=js
    js=exact(js,'const pairsToPlot=pairedRaces.slice(0,10);','const pairsToPlot=pairedRaces.slice(0,10);\nconst ownRun=cell=>D.runs["cell-"+cell];\nconst stamp=x=>x?String(x).slice(8,10)+"/"+String(x).slice(5,7)+"/"+String(x).slice(0,4):"—";\nconst floriBi=()=>D.years[2026].races.find(r=>r.id_evento===34529)?.bi_total;')
    js=js.replace('SP City tem somente 53 participações sem informação.','SP City tem '+str(next(r['sem_informacao']for r in D['age_audit']['2026']['provas']if r['id_evento']==33486))+' participações sem informação.')
    js=exact(js,'Auditoria de 19/10/2026 · congelamento ${A.run_id}', 'Auditoria de ${stamp(A.coletado_em)} · congelamento ${A.run_id}')
    js=exact(js,'Nenhuma recarga foi realizada. 2025 usa resultados operacionais; 2026 usa o BI tratado.','A leitura de 2026 usa a fato versionada após a carga de09/11; 2025 usa resultados operacionais. As capturas oficiais independentes conservam suas datas.')
    js=exact(js,'Não encontramos divergências entre os ranges do BI e os operacionais nesta seleção.','Ranges BI e operacional divergentes: ${n(T.range_bi_diverge_operacional)}; range somente operacional: ${n(T.range_so_no_operacional)}.')
    js=exact(js,'A diferença de três segue em conferência.','A diferença de ${n(G.stages.find(r=>r.id===\'joao-pessoa\').metrics2026.total-332)} segue em conferência.')
    # The single-quoted paragraph below needs concatenation to retain JS interpolation.
    js=exact(js,'Em Floripa, ele contém 3.594 registros; o volume editorial acima usa 3.592 de Geral/Elite da fonte oficial.',"Em Floripa, ele contém '+n(floriBi())+' registros; o volume editorial acima usa '+n(G.stages.find(r=>r.id==='floripa').metrics2026.total)+' de Geral/Elite da fonte oficial.")
    js=exact(js,"G.meta.frozen_date||'23/10/2026'","G.meta.frozen_date||'Data não informada'")
    js=exact(js,'não altera os totais da seleção geral de 39 maratonas.','não altera os totais da seleção geral de ${n(D.years[2026].races.length)} maratonas.')
    js=exact(js,"${year===2025?'congelamento 137, coleta de 03/10/2026':'congelamento 174, coleta de 05/10/2026'}", "${year===2025?'principal2025 histórico205, fonte original137':'principal2026 candidato, fonte própria no capítulo'}")
    js=exact(js,"${year===2025?'252':'253, com a captura oficial de Floripa no congelamento 210'}", "${ownRun(year===2025?436:437)+(year===2026?', com a captura oficial de Floripa210':'')}")
    js=exact(js,"'Nas mesmas provas, o volume registrado aumentou.'", "growth>0?'Nas mesmas provas, o volume registrado aumentou.':growth<0?'Nas mesmas provas, o volume registrado recuou.':'Nas mesmas provas, o volume registrado se manteve.'")
    js=exact(js,"'Conclusões nos 17 pares'", "'Conclusões nos '+n(P.pares)+' pares'")
    js=exact(js,"'Os outros 16 pares, nos mesmos nove meses.'", "'Os outros '+n(P.pares-1)+' pares, nos mesmos nove meses.'")
    js=exact(js,'<b>17 provas com uma edição em cada ano</b>','<b>${n(P.pares)} provas com uma edição em cada ano</b>')
    js=exact(js,"'As dez maiores provas entre os 17 pares · conclusões registradas'", "'As dez maiores provas entre os '+n(P.pares)+' pares · conclusões registradas'")
    js=exact(js,'incluem todos os 17.','incluem todos os ${n(P.pares)}.')
    js=exact(js,"'Abrir os 17 pares e suas variações'", "'Abrir os '+n(P.pares)+' pares e suas variações'")
    js=exact(js,'A coorte usa 5.210 resultados da NB; a análise específica de Boston usa uma captura oficial de 5.215.','A coorte usa ${n(nb.n2026)} resultados da NB; a análise específica de Boston conserva sua captura oficial independente de05/10/2026.')
    js=exact(js,"' A evolução entre anos está no quadro dos 17 pares acima.'", "' A evolução entre anos está no quadro dos '+n(D.pairs.coorte.pares)+' pares acima.'")
    js=exact(js,"'Floripa: perfil/histograma usa BI 3594; desempenho usa fonte oficial 3592. Diferença total de dois registros, explicitada sem imputação de idade.'", "'Floripa: perfil/histograma usa BI '+n(floriBi())+'; desempenho usa fonte oficial3592. Diferença de '+n(floriBi()-3592)+' registros, explicitada sem imputação de idade.'")
    old="if(year===2026)html+=section('cenarios'"
    start=js.index(old);end=js.index("\nhtml+=section('fontes'",start)
    js=js[:start]+"""if(year===2026){const S=D.pairs.cenarios;html+=section('cenarios','APOIO INTERNO · NÃO É PROJEÇÃO NACIONAL','Um cenário para acompanhar até dezembro.',`<div class="grid">${card(n(S.jan_set_2026),'Jan–Set observado')}${card(n(S.q4_estavel),'Q4 repetindo a referência')}${card(n(S.q4_varia_com_coorte),'Q4 acompanhando a coorte')}</div><p>${n(S.jan_set_2026)} + ${n(S.q4_2025)} × fator. Fator1 ou ${Number(D.pairs.coorte.fator).toLocaleString('pt-BR',{maximumFractionDigits:7})}. Cauda: ${n(S.provas_q4_referencia)} provas selecionadas deQ4/2025. Supõe repetição e cobertura equivalente; não é intervalo de confiança e não inclui todas as maratonas brasileiras.</p>`);}"""+js[end:]
    js=exact(js,'Congelamentos 248–253 incorporam capítulo, casos especiais e desempenho.','Capítulo: congelamento ${n(D.runs.capitulo)}; especiais: ${n(D.runs.especiais)}; desempenho: ${n(ownRun(year===2025?436:437))}. O principal2025 continua histórico205; os inventários, seleção, perfil e contexto amplo de2025 têm recapturas próprias.')
    js=exact(js,'Seleção e comparação preservam 240–246.','Inventários: ${n(ownRun(425))}/${n(ownRun(426))}; seleções: ${n(ownRun(427))}/${n(ownRun(428))}; comparação: ${n(ownRun(429))}. Capturas oficiais Boston/Floripa permanecem207–210, com data própria.')
    js=exact(js,'${year===2025?252:253}', '${ownRun(year===2025?436:437)}')
    # Boston's independent case-study function is byte-for-byte preserved.
    a=lambda s:s[s.index('function bostonInsert(){'):s.index('function brasilGiganteInsert(){')]
    assert a(js)==a(before),'Historical Boston narrative was changed'
    return js


def exports(D,biz):
    dest=biz/'estudos/lancamento/arquivos';dest.mkdir(parents=True,exist_ok=True)
    with (dest/'maratonas-indicadores-completos.csv').open('w',encoding='utf-8-sig',newline='')as f:
        out=csv.writer(f,delimiter=';');out.writerow(['Ano','Série','Categoria','Valor atual','Unidade','Contagem','Denominador','Fonte','Nota'])
        for year,Y in D['years'].items():
            for s in Y['series']:
                for v in s['values']:out.writerow([year,s['id'],v['label'],v['value'],v['unit'],v['count'],v['denominator'],v['source'],v['note']or s['note']])
    for year in ('2025','2026'):
        fields=['sub3','sub4']+(['decisao']if year=='2025'else[])+['feminino','id_evento','data_final','nome_evento','participacoes','id_agrega_evento']
        with (dest/f'maratonas-selecao-{year}.csv').open('w',encoding='utf-8-sig',newline='')as f:
            out=csv.DictWriter(f,fieldnames=fields);out.writeheader()
            for r in D['years'][year]['selection']:out.writerow({k:r.get(k)for k in fields})
    with (dest/'maratonas-pares-2025-2026.csv').open('w',encoding='utf-8-sig',newline='')as f:
        fields=['n2025','n2026','id2025','id2026','agregador','nome_evento'];out=csv.DictWriter(f,fieldnames=fields);out.writeheader()
        for r in D['pairs']['pares']:out.writerow({k:r.get(k)for k in fields})
    export=[]
    for year,A in D['age_audit'].items():
        for race in A['provas']:
            examples=[v for v in A['exemplos']if v['id_evento']==race['id_evento']]
            def labels(reason):return ' | '.join(f"{v['categoria_origem']or'(categoria vazia)'}: {v['total']}"for v in examples if v['motivo']==reason)
            if race['sem_informacao']:action='Conferir idade/categoria etária no resultado oficial; recarregar somente se houver informação mais precisa.'
            elif race['fora_faixa_padrao']:action='Faixa existente não cabe no grupo padrão. Recarga idêntica não resolve; buscar idade individual ou faixa mais precisa.'
            else:action='Sem lacuna de classificação etária nesta auditoria.'
            export.append(dict(ano=year,**race,exemplos_sem_informacao=labels('Sem informação'),exemplos_faixas=labels('Fora da faixa padrão'),encaminhamento=action,congelamento=A['run_id']))
    original_header=next(csv.reader((BUSINESS/'estudos/lancamento/arquivos/maratonas-auditoria-idades.csv').open(encoding='utf-8-sig'),delimiter=';'))
    with (dest/'maratonas-auditoria-idades.csv').open('w',encoding='utf-8-sig',newline='')as f:
        out=csv.DictWriter(f,fieldnames=original_header,delimiter=';');out.writeheader()
        for r in export:out.writerow({k:r.get(k)for k in original_header})



def build():
    D=assemble();js=renderer(D);html=(W/'baseline/maratonas.cfm').read_text();m=re.search(r'(<script id="study-data" type="application/json">)(.*?)(</script>)',html,re.S)
    raw=json.dumps(D,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    html=html[:m.start(2)]+raw+html[m.end(2):]
    html=exact(html,'ESTUDO WEB · MARATONAS DO BRASIL · 19/10/2026','ESTUDO WEB · MARATONAS DO BRASIL · FONTES RENOVADAS09/11/2026')
    html,count=re.subn(r'maratonas-detalhado\.js\?v=[^"]+','maratonas-detalhado.js?v='+hashlib.sha256(js.encode()).hexdigest()[:14],html);assert count==1
    biz=W/'runtime/business';dest=biz/'estudos/lancamento';dest.mkdir(parents=True,exist_ok=True)
    (dest/'maratonas.cfm').write_text(html);(dest/'maratonas-detalhado.js').write_text(js);exports(D,biz)
    # Reuse the canonical 23/10 publication path's existing reader generator.
    spec=importlib.util.spec_from_file_location('vertical_press_builder',RR/'_codex/staging/imprensa-estudos-20261019/reader-builder.py');reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader);reader.BUSINESS=biz
    def source(path):
        reader.SOURCES['Business/'+str(path.relative_to(biz))]=hashlib.sha256(path.read_bytes()).hexdigest();return path.read_text()
    reader.source=source;press,pressjs,stats=reader.marathon_reader();portal=W/'runtime/portal/brasilquecorreprovas/imprensa/maratonas';portal.mkdir(parents=True,exist_ok=True)
    stamp='<!--- Generated by reader-builder.py. Canonical sources SHA-256: '+json.dumps(reader.SOURCES,ensure_ascii=False,sort_keys=True,separators=(',',':'))+' --->\n'
    (portal/'index.cfm').write_text(stamp+press);(portal/'maratonas-detalhado.js').write_text('// Generated from Business canonical candidate; reader-builder.py.\n'+pressjs)
    manifest={'published':False,'pdfs_generated':False,'principal2025':'historical205','principal2026_run':run(251)['id'],'principal2026_contract':run(251)['result']['rows'][0]['payload']['meta']['contrato_versao'],'principal2026_publication':json.loads((W/'principal-publication.json').read_text())['publication_id']if (W/'principal-publication.json').exists()else'review','principal2026_activation':'not_changed_by_vertical_task','frozen_runs':{str(c):{'run':r['id'],'revision':r['cell_version'],'started_at':r.get('started_at')}for c,r in RUNS.items()if c in derive.CELLS},'reader_stats':stats,'files':{str(p.relative_to(W/'runtime')):hashlib.sha256(p.read_bytes()).hexdigest()for p in sorted((W/'runtime').rglob('*'))if p.is_file()}}
    (W/'candidate-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2));print(json.dumps({'candidate':str(W/'runtime'),'stats':stats,'runs':D['runs']},ensure_ascii=False))

if __name__=='__main__':build()
