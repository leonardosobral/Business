from pathlib import Path
import json,concurrent.futures
p=Path(__file__).parent
ns={'__file__':str(p/'research.py')};exec((p/'research.py').read_text().split('with concurrent.futures.ThreadPoolExecutor')[0],ns)
urls={
'cia-de-eventos':'https://www.ativo.com/calendario/eventos/america-do-sul/br/sp/bertioga/corrida-de-rua/36216/ultramaratona-de-revezamento-bertioga-maresias-1-etapa/',
'maria-isabel-eventos':'https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/85191/8e58ddfa2547445894798b560b5cc2b4639075495113048536.pdf',
'personew':'https://www.personew.esp.br/runirmaospatrocinio',
'rav-sports':'https://lets.events/e/8-corrida-do-coracao-soceron-ji-parana-ro-2026',
'quanta-esportes-e-eventos':'https://app.poptickets.com.br/evento/circuito-das-cidades-etapa-lagoa-santa',
'dto-sports-eventos-esportivos-e-marketing':'https://www.dtosports.com.br/_files/ugd/1014ec_43455180cb9a4421b3fe5a5269b741b9.pdf',
'sports360o-eventos-esportivos':'https://sports360.com.br/quem-somos/',
'taboada-runners':'https://www.taboadarunners.fit/',
'cpr-eventos-e-producoes':'https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/70069/a5b3982fb38a4f429fab46f5721ea5a2638793708438478428.pdf',
'pace-3-eventos-esportivos':'https://www.pace3.com.br/quem-somos-pace/',
'mountain-do':'https://loja.mountaindo.com.br/quem-somos/',
'wx-esportes-e-negocios':'https://wxesportes.com.br/',
'fg-eventos':'https://www.sinait.org.br/noticia/16097/36-enafitenafitianos-que-se-inscreverem-ate-15-de-outubro-serao-isentos-da-taxa-da-1-corrida-contra-a-escravidao',
'agencia-vqv-eventos':'https://visitmaringa.com.br/ova_sev/agencia-vqv/',
'zbr-events':'https://zbrevents.com.br/igt23k/regulamento/',
}
jobs=[{'id':k,'kind':'extra','url':v} for k,v in urls.items()]
jobs.append({'id':'zbr-events','kind':'extra','url':'https://zbrevents.com.br/guaranirace/pita/regulamento'})
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:r=list(pool.map(ns['fetch'],jobs))
(p/'extra.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print([(x['id'],x.get('file',x.get('error'))) for x in r])
