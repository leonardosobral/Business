# Enriquecimento na análise Astra existente

Escopo aprovado pelo usuário: aproveitar a mesma análise de páginas oficiais/regulamentos para enriquecer o evento; preencher apenas vazios automaticamente, preservar valores existentes, resolver equivalências sem revisão desnecessária e revisar divergências reais. Mesma chave e mesmo modelo gpt-6-astra. Sem alteração de cotas, permissões, outros módulos, commits ou push.

## Contrato

Além dos locais independentes de prova e kit, o JSON estrito traz até 24 fatos identificados por campo, valor, trecho literal, documento e certeza. Campos nativos permitidos: cidade, estado, país, endereço da prova, datas inicial/final, organizador, tipo da corrida, URLs de inscrição/site/regulamento. Informações complementares: horários/programação, modalidades/distâncias, agenda do kit, período/plataforma de inscrições, preços/lotes com validade, regras, contatos públicos, redes sociais e estrutura.

Cada fato precisa de fonte literal da edição correta e de correspondência semântica ao campo. Países ISO e UFs brasileiras têm equivalências determinísticas entre nomes, idiomas e siglas; isso não autoriza trocar município, número do imóvel, edição ou país. O modelo interpreta a fonte, mas não é a autoridade final de publicação.

## Persistência e revisão

Reutilizar o JSONB localizacoes, no namespace reservado enriquecimento, com valores complementares, evidências e histórico do preenchimento. Sem migração SQL. Campos nativos usam allowlist, binds e limites de tamanho. Não inventar uma modalidade ou preço a partir do título; preços complementares não substituem automaticamente o mecanismo de preços vigente.

Publicar fatos confiáveis vazios após a interpretação, mesmo se Geoapify estiver aguardando cota. Preservar checkpoint, concorrência, auditoria, revisão/CSRF/admin global. Revisões humanas podem aceitar explicitamente um valor divergente, com confirmação e CAS, ou manter o cadastro. Nunca aprovar fato sem evidência ou resolver conflito de fontes por sorteio.

A chave de cache da interpretação muda de versão. A fila reconhece trabalhos antigos e faz uma nova análise enriquecida quando necessário, sem repetir indefinidamente a mesma fonte. Resultados de enriquecimento não provocam loops de reenfileiramento. O cadastro do evento e os detalhes de revisão apresentam os novos dados em seções/abas.

## Verificação

Regressões: UF/país por extenso versus sigla, homônimos e regiões realmente diferentes, fonte antiga, campo inventado, finalidade errada, valores concorrentes, SQL/HTML malicioso, revisões obsoletas, endereço do kit versus prova, quotas e retomada. Teste nativo transacional sem alterações permanentes; chamada real limitada ao Astra e validação do runtime publicado.
