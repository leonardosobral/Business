from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import re
stage=Path('_codex/staging/seo-routes-20261003')
source=(stage/'baseline/Business/portal/includes/seo_queue_data.cfm').read_text()
now=datetime.now(ZoneInfo('America/Sao_Paulo'))
source=re.sub(r'updatedAt = "[^"]+"', 'updatedAt = "'+now.astimezone(ZoneInfo('UTC')).isoformat().replace('+00:00','Z')+'"',source,count=1)
source=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',source,count=1)
updates={
'RR-01':{
 'title':'Preservar caracteres especiais nas rotas de eventos',
 'summary':'As rotas passaram a codificar a tag ao repassá-la à consulta interna. Identificadores e dados dos eventos foram preservados.',
 'impact':'Eventos antes bloqueados por 403 ou desviados à busca passam a abrir a página correta nos três idiomas.',
 'rule':'http.error / http.redirect / canonical.mismatch — corrigidos nos casos rechecados',
 'evidence':'Rechecagem focal em 03/10/2026: o cadastro confirmou as tags de Operário Night Run, Rock N Run Nashville e das duas provas Atibaia. A origem reproduziu os erros; o Apache registrou AH10411 por consulta interna com caracteres sem escape. As regras agora codificam os identificadores. As URLs dos quatro eventos foram conferidas em português, inglês e espanhol após a publicação, com HTTP 200 e canonical coerente.',
 'acceptance':'Concluído nos quatro casos: HTTP 200, evento e canonical corretos nos três idiomas, sem mudar tags ou o cadastro. Teste com Apache real também confere caracteres especiais e mantém as restrições de caminhos sensíveis. As medições gerais do relatório permanecem datadas de 29/09.',
 'stateLabel':'Corrigido e rechecado em 03/10/2026'
},
'RR-05':{
 'title':'Confirmar retirada editorial da notícia histórica',
 'summary':'O CMS registra a notícia como rejeitada e não publicada. O HTTP 404 é coerente com esse estado editorial.',
 'impact':'O item foi encerrado após conferir o cadastro; a retirada editorial permanece respeitada.',
 'rule':'http.error — retirada editorial confirmada',
 'evidence':'Rechecagem focal em 03/10/2026: news.tb_content, id 2380, mantém a mesma slug, published=false e editorial_status=rejected, com atualização em 20/09/2026. A URL pública retorna HTTP 404 e continua ausente do sitemap atual. A consulta não encontrou referências a esse endereço no corpo ou resumo de conteúdos publicados; a busca nos arquivos de runtime locais também não encontrou links estáticos. Não foi identificado conteúdo equivalente para redirect.',
 'acceptance':'Concluído: estado editorial e ausência no sitemap conferidos; nenhuma republicação, troca de slug ou redirect genérico foi realizada. Links externos e conteúdos não cobertos por essa consulta não foram avaliados.',
 'stateLabel':'Retirada editorial conferida em 03/10/2026'
}}
for item,values in updates.items():
 idx=source.index('id = "'+item+'"');start=source.rfind('        {',0,idx);end=source.index('\n        }',idx)+len('\n        }')
 block=source[start:end].replace('resolved = false','resolved = true',1)
 for field,value in values.items():
  block,n=re.subn(r'('+field+r' = )"[^\n]*"', lambda m:m[1]+'"'+value.replace('"','""')+'"',block,count=1)
  assert n==1,field
 source=source[:start]+block+source[end:]
assert source.count('resolved = true')==8
assert source.count('resolved = false')==3
candidate=stage/'candidate/Business/portal/includes/seo_queue_data.cfm';candidate.parent.mkdir(parents=True,exist_ok=True);candidate.write_text(source)
