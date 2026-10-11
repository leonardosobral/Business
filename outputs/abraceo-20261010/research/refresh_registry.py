from collect import *
fields='cnpj razao_social nome_fantasia descricao_situacao_cadastral data_situacao_cadastral data_inicio_atividade descricao_tipo_de_logradouro logradouro numero complemento bairro cep municipio uf cnae_fiscal cnae_fiscal_descricao natureza_juridica porte ddd_telefone_1 ddd_telefone_2 email'.split()
targets='62503087000177 47234721000120 32955144000198 38445093000130 64080968000158 54070504000107 63168040000167 50292608000105 55330099000181 02525354000185 02525354000266'.split()
saved=ROOT/'research/revisao-registry.json'
data=json.loads(saved.read_text()) if saved.exists() else {}
base=json.loads((ROOT/'research/prepared.json').read_text())
targets += [r['cnpj_pesquisado'] for r in base['filiados'] if r['cnpj_pesquisado'] and (not r['endereco_cadastral'] or not r['situacao_cadastral_consultada'])]
targets=list(dict.fromkeys(targets))
for c in targets:
    if c in data:continue
    u='https://brasilapi.com.br/api/cnpj/v1/'+c
    try:
        d=json.loads(fetch(u)); r={k:d.get(k) for k in fields};r['fonte']=u
        if not r.get('razao_social'):raise ValueError('Sem dados cadastrais')
        data[c]=r
        print(c,r['razao_social'],r['descricao_situacao_cadastral'],flush=True)
    except Exception as e:print(c,str(e)[:100],flush=True)
(ROOT/'research/revisao-registry.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
