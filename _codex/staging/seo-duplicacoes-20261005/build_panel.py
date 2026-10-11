from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import shutil,re,json
P=Path(__file__).resolve().parent
names=['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']
for n in names:
 f=P/'candidate/business'/n;f.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/'baseline/business'/n,f)
f=P/'candidate/business/portal/includes/seo_queue_data.cfm';s=f.read_text();now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat(timespec='seconds')+'"',s,count=1)
s=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',s,count=1)
record='''        {
            resolved = true,
            id = "RR-30", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Títulos de etapas",
            title = "Preservar cidade e data nos títulos das etapas",
            summary = "Etapas com nomes diferentes que coincidiam após o corte em 50 caracteres agora mostram cidade, UF e data cadastradas. Cinco eventos conferidos em português, inglês e espanhol.",
            impact = "Distingue etapas legítimas na busca e preserva a cidade que desaparecia do título.",
            owner = "RoadRunners — metadados públicos dos eventos",
            rule = "semrush.6; title.truncated-prefix",
            evidence = "Rechecagem das 62 URLs de títulos apontadas no snapshot 6ac31bf647d73ceec1b0b861. Antes deste lote, nove páginas ainda repetiam títulos: etapas Correr é Massa em Curitiba, Apucarana e Santa Terezinha de Itaipu, e Track&Field Motiva Aeroportos em Curitiba e Londrina. SELECT confirmou nomes completos, cidades e datas diferentes. O corte em 50 caracteres removia essa distinção. O include de títulos agora usa local/data existentes quando nomes distintos têm o mesmo prefixo; em empate de local/data preserva o nome completo. Títulos únicos e diferenciação anterior por datas foram mantidos. O bloco de prefixos não altera nomes já diferenciados por datas; duas páginas com títulos anteriormente distintos também foram conferidas. Prefixos colidentes são consultados com SQL fixo e cache compartilhado de dez minutos; a consulta fria final levou aproximadamente 74 ms nesta medição, evitando varreduras extras por cadastro. Testes Adobe: candidato final passou 64 verificações, incluindo preservação de páginas já distintas e combinação de prefixos colidentes com nomes iguais em várias datas. O baseline inicial reproduziu 38 falhas em 60 verificações. Tabelas temporárias transacionais foram usadas somente nas fixtures; cadastros não foram alterados. Template compilado, backup recuperável e publicação limitada. Quinze páginas PT/EN/ES dos cinco eventos verificadas com títulos distintos, canonical, alternates, descrição, H1 e JSON-LD preservados. Após a publicação, nenhuma repetição de título entre as 62 URLs conferidas; 61 responderam 200 e o alias FCA 301. Esta é verificação direta das URLs, não nova auditoria Semrush nem prova de indexação Google.",
            acceptance = "Publicado e verificado em 05/10. Notas e contadores Semrush históricos preservados. Outras URLs fora desta amostra e ganhos no Google continuam sujeitos a medição.",
            urls = [{url = "https://roadrunners.run/evento/2026-circuito-de-corridas-correr-e-massa-apostou-loterias-etapa-apucarana/", label = "Correr é Massa — Apucarana"}, {url = "https://roadrunners.run/evento/2026-trackfield-run-series-2026-motiva-aeroportos-londrina/", label = "Track&Field — Londrina"}],
            stateLabel = "Publicado — amostra de títulos conferida; ranking não medido"
        },
'''
record=record.replace('Publicado e verificado em 05/10.', 'Publicado e verificado em '+now.strftime('%d/%m')+'.')
assert 'id = "RR-30"' not in s;s=s.replace('    items = [\n','    items = [\n'+record,1)
old='Os 62 e oito itens são páginas afetadas nos relatórios detalhados, não 62 e oito conjuntos distintos.'
new=old+' Continuação em RR-30: as nove páginas ainda com títulos iguais foram corrigidas; etapas Correr é Massa e Track&Field agora conservam cidade/data. Rechecagem direta dos 62 endereços não encontrou títulos repetidos, mas não representa nova coleta do Semrush nem encerra os demais tipos de problema.'
assert s.count(old)==1;s=s.replace(old,new,1);s=s.replace('A revisão não abrangeu todas as 62 páginas.','A revisão inicial de RR-28 não abrangeu todas as 62 páginas.').replace('Conferir o efeito do RR-28 em nova auditoria','Conferir o efeito de RR-28, RR-29 e RR-30 em nova auditoria');f.write_text(s)
f=P/'candidate/business/portal/conteudo/seo_semrush.cfm';s=f.read_text()
old='Os contadores Semrush acima continuam históricos.</p>'
new='Continuação em '+now.strftime('%d/%m')+': rechecagem dos 62 endereços de títulos apontados pela auditoria: nove páginas ainda repetiam títulos porque o corte do nome retirava a cidade. Etapas Correr é Massa e Track&amp;Field receberam local/data nos títulos, com controles em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-30">RR-30</a>. A verificação direta após esse lote não encontrou títulos repetidos nessa amostra. Os contadores Semrush acima continuam históricos; indexação e ranking no Google ainda não foram medidos.</p>'
assert s.count(old)==1;s=s.replace(old,new,1);f.write_text(s)
assert (P/'candidate/business/portal/includes/seo_semrush_data.cfm').read_bytes()==(P/'baseline/business/portal/includes/seo_semrush_data.cfm').read_bytes()
print(json.dumps({'changed_panel_files':2,'semrush_snapshot_preserved':True,'queue_item':'RR-30'}))
