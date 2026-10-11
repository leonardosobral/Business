from collect import *
fields='cnpj razao_social nome_fantasia descricao_situacao_cadastral data_situacao_cadastral data_inicio_atividade descricao_tipo_de_logradouro logradouro numero complemento bairro cep municipio uf cnae_fiscal cnae_fiscal_descricao cnaes_secundarios natureza_juridica porte ddd_telefone_1 ddd_telefone_2 email'.split()
cnpjs=sorted(set(v for line in (ROOT/'research/selected.txt').read_text().splitlines() for v in line.split()[1:]))
def one(c):
    url='https://brasilapi.com.br/api/cnpj/v1/'+c
    try:
        d=json.loads(fetch(url)); r={k:d.get(k) for k in fields}
        if not r.get('cnpj'): return c,{'erro':d.get('message','Sem dados'),'fonte':url}
        r['fonte']=url
        return c,r
    except Exception as e: return c,{'erro':str(e),'fonte':url}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: data=dict(pool.map(one,cnpjs))
(ROOT/'research/registry.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
for c,r in data.items(): print(c,r.get('razao_social'),r.get('municipio'),r.get('uf'),r.get('descricao_situacao_cadastral'),r.get('erro',''))
