from pathlib import Path
from datetime import datetime,timezone
from zoneinfo import ZoneInfo
import re
STAGE=Path(__file__).resolve().parent
name='portal/includes/seo_queue_data.cfm'
text=(STAGE/'baseline/Business'/name).read_text()
previous=STAGE/'candidate/Business'/name
previous_bytes=previous.read_bytes() if previous.exists() else None
def fields(identity,values):
 global text
 at=text.index('            id = "'+identity+'",');start=text.rfind('        {',0,at)
 finish=text.find('\n        }',at)+10
 block=text[start:finish]
 for key,value in values.items():
  replacement=str(value).lower() if isinstance(value,bool) else '"'+value.replace('"','""')+'"'
  block,count=re.subn(r'^(            '+re.escape(key)+r' = ).*?(,?)$',lambda m:m[1]+replacement+m[2],block,count=1,flags=re.M)
  assert count==1,(identity,key)
 text=text[:start]+block+text[finish:]

fields('SH-01',{
 'resolved':True,
 'summary':'A busca Road Runners e a home OpenResults receberam título principal. O texto promocional da busca compartilhada passou a ser parágrafo nas páginas internas.',
 'evidence':'Rechecagem focal em 03/10/2026: 13 páginas públicas retornaram HTTP 200 e um H1 principal coerente — home, busca, evento e notícia Road Runners em PT/EN/ES, além da home OpenResults. No evento e na notícia, o título principal descreve o conteúdo; o slogan do bloco de busca não disputa esse papel. O OpenResults mantém o tamanho visual de sua introdução. Conferência de apresentação e título acessível no desktop e celular; teste CFML cobre 12 combinações de template e idioma. A amostra geral de 29/09 não foi refeita.',
 'acceptance':'Concluído nos templates e casos rechecados. Formulário e seletor de estado preservados; compilação Adobe e conferência do HTML real após publicação. Outros templates e resultados de ranking não são comprovados por este lote.',
 'stateLabel':'Corrigido e rechecado em 03/10/2026'
})
fields('OR-02',{
 'resolved':True,
 'title':'Evitar indexação das páginas individuais de atletas',
 'summary':'As páginas individuais /resultados recebem noindex, follow. O robots permite lê-lo, enquanto eventos e sitemaps continuam indexáveis; /perfil segue bloqueado.',
 'impact':'A estratégia passa a impedir indexação da página individual nos buscadores que respeitam noindex, preservando descoberta das provas. Nomes nas listagens de eventos podem continuar aparecendo; pedidos individuais precisam de atendimento próprio.',
 'evidence':'Decisão explícita em 03/10/2026: evitar exposição de históricos individuais com nomes, mantendo resultados nas listagens de eventos. O usuário aprovou noindex após esclarecer que robots não garante desindexação. A tag noindex, follow foi publicada no head somente do template /resultados/ e validada no HTML público, inclusive no acesso direto ao template. Só depois dessa conferência o robots deixou de bloquear /resultados, permitindo ler a instrução. /perfil permanece bloqueado. Sete casos CFML verificaram a separação de templates; sessenta casos do interpretador local verificaram as regras por agente. O Google ainda precisa rastrear as páginas para aplicar a remoção; não foi verificado o índice privado do Search Console.',
 'acceptance':'Implementação publicada e conferida: páginas individuais públicas com noindex, páginas de eventos sem essa restrição, robots acessível e sitemap sem páginas de histórico pessoal. Dados e acesso preservados. A remoção efetiva do índice depende de nova leitura pelos buscadores; para pedidos urgentes, avaliar Remoções do Search Console junto à regra permanente.',
 'stateLabel':'Noindex publicado; aplicação pelos buscadores pendente'
})
fields('SH-02',{
 'summary':'A seleção do organizador no Road Runners publicado foi corrigida para exigir esse papel no evento. A principal lacuna continua no cadastro compartilhado.',
 'evidence':'Conferência focal de 03/10/2026, distinta da auditoria de páginas de 29/09: o cadastro compartilhado contém 34.320 eventos ativos e 1.332 com vínculo de organização e nome preenchido. O Road Runners publicado ainda selecionava o primeiro fornecedor; agora exige id_fornecedor_tipo=1. Quatro páginas públicas nos dois sites conferiram um evento com organizador cadastrado e outro somente com fornecedor de cronometragem, sem promover este fornecedor a organizador. Na amostra anterior, 40 de 42 SportsEvent no Road Runners e 96 de 99 no OpenResults não tinham organizador. Edição, fonte, unidade, cancelamento e traduções continuam exigindo revisão editorial.',
 'acceptance':'Correção de seleção publicada, sem alterar os cadastros. Completar vínculos e fatos somente com fontes comprovadas; manter consistência do HTML e JSON-LD, status de resultados e acesso existentes. Registrar fonte e data de cada revisão.',
 'stateLabel':'Seleção corrigida; revisão editorial e cadastro pendentes'
})
fields('RR-06',{
 'evidence':'Publicação e auditoria em 29/09/2026 às 21:13: IX Encontro dos Amigos Correm Pôr do Sol retornou 200 com canonical completo e alternates PT/EN/ES. As 77 páginas com declarações hreflang passaram na verificação básica, sem o aviso anterior. Em 03/10, a rechecagem do runtime identificou seleção do primeiro fornecedor no bloco de organizador; este lote reaplicou a seleção pelo papel 1, com prova de ausência quando há somente cronometragem. A disponibilidade de inscrição continua dependendo de confirmação recente para o link exato, sem inferência pela data.'
})
text=text.replace('a home continua sem H1.','a home estava sem H1 nessa auditoria; a correção focal de 03/10 é registrada na fila.')
now=datetime.now(timezone.utc);local=now.astimezone(ZoneInfo('America/Sao_Paulo'))
text=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat().replace('+00:00','Z')+'"',text,count=1)
text=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+local.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',text,count=1)
candidate=STAGE/'candidate/Business'/name;candidate.parent.mkdir(parents=True,exist_ok=True);candidate.write_text(text)
target=Path('/Users/Shared/Projects/RunnerHub/Business')/name
assert target.read_bytes() in [(STAGE/'baseline/Business'/name).read_bytes(),previous_bytes],'Concurrent local queue change'
target.write_text(text)
print('Queue: 10 resolved, 1 pending; historic audits and technical scores retain their dates.')
