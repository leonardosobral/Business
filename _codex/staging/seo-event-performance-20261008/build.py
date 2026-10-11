from pathlib import Path
import hashlib, json, re

S=Path(__file__).resolve().parent
NAME='includes/backend/backend_evento.cfm'
original=(S/'baseline/rr'/NAME).read_text()
query=re.search(r'(<cfquery name="qEventoEdicoes"[^>]*>)(.*?)(</cfquery>)',original,re.S)
sql=query.group(2)
pattern=r'            FROM tb_resultados res\n(            LEFT JOIN tb_usuarios.*?)(            WHERE res.id_evento = evt.id_evento.*?)(            ORDER BY\n.*?res\.tempo_total ASC,\n)(                pag.id_pagina ASC NULLS LAST\n            LIMIT 1)'
matches=list(re.finditer(pattern,sql,re.S));assert len(matches)==2
common=re.sub(r"            AND upper\(trim\(res.sexo\)\) IN \([^\n]+\)\n",'',matches[0].group(2))
assert common==re.sub(r"            AND upper\(trim\(res.sexo\)\) IN \([^\n]+\)\n",'',matches[1].group(2))
def shortlist(m):
    joins, filters, order, tail=m.groups()
    sex=re.search(r"upper\(trim\(res.sexo\)\) IN \([^\n]+\)",filters).group().replace('upper(trim(res.sexo))','res.sexo_normalizado')
    inner_order='\n'.join('        '+line for line in order.rstrip().removesuffix(',').splitlines())
    return ('            -- Match every ranking tie before applying the public-profile tie-breaker.\n'
            '            FROM (\n'
            '                WITH melhor_classificacao AS MATERIALIZED (\n'
            '                    SELECT res.classificacao_sexo, res.tempo_total\n'
            '                    FROM evento_resultados_elegiveis res\n'
            '                    WHERE '+sex+'\n'+inner_order+'\n                    LIMIT 1\n'
            '                )\n'
            '                SELECT res.tempo_total, res.nome, res.id_usuario, res.classificacao_sexo\n'
            '                FROM evento_resultados_elegiveis res\n'
            '                JOIN melhor_classificacao melhor\n'
            '                    ON res.classificacao_sexo IS NOT DISTINCT FROM melhor.classificacao_sexo\n'
            '                    AND res.tempo_total = melhor.tempo_total\n'
            '                WHERE '+sex+'\n'
            '            ) res\n'+joins+order+tail)
changed,n=re.subn(pattern,shortlist,sql,flags=re.S)
assert n==2
start=changed.index('        LEFT JOIN LATERAL (\n            SELECT\n                res.tempo_total,')
end=changed.index('        ) evento_campea_feminina ON true',start)+len('        ) evento_campea_feminina ON true')
both=changed[start:end]
both='\n'.join('    '+line for line in both.splitlines())
fields=['tempo_total','nome','id_usuario','resultado_reconhecido','tag','tag_prefix','imagem_usuario']
selection=',\n'.join('                '+alias+'.'+field+' AS '+field+'_'+suffix for alias,suffix in [('evento_campeao_masculino','masculino'),('evento_campea_feminina','feminina')] for field in fields)
replacement=('        LEFT JOIN LATERAL (\n'
             '            WITH evento_resultados_elegiveis AS MATERIALIZED (\n'
             '                SELECT res.tempo_total, res.nome, res.id_usuario, res.classificacao_sexo,\n'
             '                    upper(trim(res.sexo)) AS sexo_normalizado\n'
             '                FROM tb_resultados res\n'+'\n'.join('    '+line for line in common.rstrip().splitlines())+'\n'+
             '            )\n'
             '            SELECT\n'+selection+'\n'
             '            FROM (SELECT 1) ancora\n'+both+'\n'
             '        ) evento_campeoes ON true')
changed=changed[:start]+replacement+changed[end:]
# Only the outer projection changes aliases; profile authorization expressions stay intact.
head_end=changed.index('        FROM vw_evento_corridas evt')
head=changed[:head_end]
for alias,suffix in [('evento_campeao_masculino','masculino'),('evento_campea_feminina','feminina')]:
    for field in sorted(fields,key=len,reverse=True):head=re.sub(r'\b'+alias+r'\.'+field+r'\b','evento_campeoes.'+field+'_'+suffix,head)
changed=head+changed[head_end:]
candidate=original[:query.start(2)]+changed+original[query.end(2):]
target=S/'candidate/rr'/NAME;target.write_text(candidate)
assert candidate.count('IS NOT DISTINCT FROM melhor.classificacao_sexo')==2
assert candidate.count("AND pag.perfil_publico = true")==original.count("AND pag.perfil_publico = true")
assert candidate[:query.start(2)]==original[:query.start(2)] and candidate[candidate.index('</cfquery>',query.start(2)):]==original[query.end(2):]
report={'files':1,'query':'qEventoEdicoes','shortlists':n,'unchanged_outside_query':True,'database_mutations':False,'cache_added':False,'source_hash':hashlib.sha256(candidate.encode()).hexdigest()}
(S/'build-passed.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
