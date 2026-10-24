from pathlib import Path
import hashlib,json,re
S=Path(__file__).resolve().parent
p=S/'runtime/candidate/includes/backend/backend_evento.cfm';original=(S/'runtime/baseline/includes/backend/backend_evento.cfm').read_text()
pattern=r'''                -- Match every ranking tie before applying the public-profile tie-breaker\.
                FROM \(
                    WITH melhor_classificacao AS MATERIALIZED \(
.*?
                    WHERE res\.sexo_normalizado IN \((?P<sex>[^\n]+)\)
                \) res'''
def replace(m):
 return '''                -- Keep every tie in classification/time before choosing a public profile.
                FROM (
                    SELECT res.tempo_total, res.nome, res.id_usuario, res.classificacao_sexo
                    FROM evento_resultados_elegiveis res
                    WHERE res.sexo_normalizado IN ('''+m['sex']+''')
                    ORDER BY
                        CASE
                            WHEN res.classificacao_sexo = 1 THEN 0
                            WHEN res.classificacao_sexo > 1 THEN 1
                            ELSE 2
                        END,
                        res.classificacao_sexo ASC NULLS LAST,
                        res.tempo_total ASC
                    FETCH FIRST 1 ROW WITH TIES
                ) res'''
candidate,n=re.subn(pattern,replace,original,flags=re.S);assert n==2,n
assert candidate.count('FETCH FIRST 1 ROW WITH TIES')==2
assert candidate.split('<cfquery name="qEventoEdicoes"')[0]==original.split('<cfquery name="qEventoEdicoes"')[0]
assert candidate.split('<cfquery name="qEventoEdicoes"')[1].split('</cfquery>',1)[1]==original.split('<cfquery name="qEventoEdicoes"')[1].split('</cfquery>',1)[1]
p.write_text(candidate)
(S/'runtime/build.json').write_text(json.dumps(dict(only_query_changed=True,rank_shortlists=n,no_cache_added=True,no_database_write=True,sha256=hashlib.sha256(candidate.encode()).hexdigest()),indent=2))
print(json.dumps(dict(rank_shortlists=n,only_query_changed=True,no_cache_added=True)))
