from pathlib import Path
import json,hashlib
S=Path(__file__).resolve().parent;b=json.loads((S/'baseline-data.json').read_text());src={x['id_evento']:x for x in b['events']}
cur_url='https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/86884/96bd2ae84b2848af9665c2c15721e39f639270721352025193.pdf'
mon_url='https://maratonamonumentalbsb.com.br/wp-content/uploads/2026/07/v6-REGULAMENTO-MARATONA-MONUMENTAL-2026.pdf'
c={43657:{'id_agrega_evento':29,'categorias':'5km,10km,21km,42km','url_regulamento':cur_url},39395:{'categorias':'5km,10km,21km,42km,kids','url_regulamento':mon_url},38982:{'cidade':'Pinhais','cod_cidade':4119152,'id_localidade':4002,'endereco':'Parque das Águas - Pinhais - PR'},37774:{'ativo':False,'tag_301':src[38982]['tag']}}
texts={43657:[
'A Santander Maratona de Curitiba 2026 acontece em 15 de novembro, com largada na Praça Nossa Senhora de Salete. A edição oferece 5 km, 10 km, meia maratona e maratona. A retirada dos kits está prevista para 12 a 14 de novembro no Museu Oscar Niemeyer. Consulte o regulamento e a página oficial de inscrição para horários, disponibilidade e condições atualizadas.',
'The 2026 Santander Curitiba Marathon takes place on November 15, starting at Praça Nossa Senhora de Salete. The edition offers 5 km, 10 km, a half marathon and a marathon. Race kit collection is scheduled for November 12–14 at Museu Oscar Niemeyer. Check the regulations and official registration page for current schedules, availability and conditions.',
'La Maratón Santander de Curitiba 2026 se celebra el 15 de noviembre, con salida en Praça Nossa Senhora de Salete. Ofrece 5 km, 10 km, media maratón y maratón. La entrega de kits está prevista del 12 al 14 de noviembre en Museu Oscar Niemeyer. Consulte el reglamento y la inscripción oficial para horarios, disponibilidad y condiciones actualizadas.'],39395:[
'A Maratona Monumental de Brasília 2026 acontece em 21 e 22 de novembro, na Esplanada dos Ministérios. As provas de 5 km e 10 km estão previstas para 21/11 às 17h; a maratona para 22/11 às 5h e a meia maratona às 6h. Consulte o regulamento oficial para pelotões, retirada de kits, atividades infantis e eventuais atualizações.',
'The 2026 Monumental Brasília Marathon takes place on November 21–22 at Esplanada dos Ministérios. The 5 km and 10 km races are scheduled for November 21 at 5 pm; the marathon starts on November 22 at 5 am and the half marathon at 6 am. Check the official regulations for starting waves, race kit collection, children’s activities and updates.',
'La Maratón Monumental de Brasília 2026 se celebra el 21 y 22 de noviembre en la Esplanada dos Ministérios. Las pruebas de 5 km y 10 km están previstas para el 21/11 a las 17h; la maratón para el 22/11 a las 5h y la media maratón a las 6h. Consulte el reglamento oficial para pelotones, entrega de kits, actividades infantiles y actualizaciones.']}
for eid,t in texts.items():
 c[eid].update(dict(zip(['descricao','descricao_en','descricao_es'],t)))
 c[eid]['descricao_traducoes_meta']={lang:{'source_hash':hashlib.md5(t[0].encode()).hexdigest(),'description_hash':hashlib.md5(t[i].encode()).hexdigest()} for lang,i in [('en',1),('es',2)]}
(S/'changes.json').write_text(json.dumps({'events':c,'sources':{'43657':cur_url,'39395':mon_url,'38982':'https://www.runningland.com.br/night-run-etapa-1-curitiba-2026','37774':'https://www.o2corre.com.br/calendario/night-run-etapa-1-curitiba-2026/'}},ensure_ascii=False,indent=2))
print('Prepared four factual corrections; no event dates changed')
