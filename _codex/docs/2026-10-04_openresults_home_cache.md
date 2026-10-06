# Cache do catálogo e da home — 04/10/2026

## Comportamento publicado

O catálogo compartilhado do OpenResults agora fica em APPLICATION por 30 minutos, junto com o catálogo de cidades e a contagem de resultados. A home e a página de estado reutilizam o snapshot. As consultas completas são executadas na primeira carga e nas renovações; não foram substituídas por um catálogo truncado, preservando os consumidores e os filtros existentes.

Depois de expirar, a requisição recebe a versão anterior imediatamente e uma única thread renova o snapshot. Uma falha preserva os dados anteriores e aplica intervalo de 60 segundos antes de tentar novamente. A primeira carga de uma aplicação sem snapshot é síncrona e protegida contra concorrência; falha nessa primeira carga retorna 503 com Retry-After, sem redirecionar ao 404. Reiniciar a aplicação perde o snapshot em memória.

Consultas da fonte têm limites de 10 segundos para eventos e 5 segundos para o contador. O catálogo de cidades é calculado uma vez por renovação. Alterações de eventos/cidades/contagem podem levar aproximadamente 30 minutos para aparecer; em falha da fonte a versão anterior permanece disponível por mais tempo. Próximas provas, estatísticas estaduais e outras consultas independentes conservam seus próprios caches.

O filtro explícito de badges preserva a consulta filtrada anterior, com cache ampliado para 30 minutos, e monta suas cidades a partir desse conjunto. Os demais filtros usam o snapshot compartilhado, sem mudar seus critérios.

## Arquivos

- services/EventCatalogSource.cfc: consultas e construção de cidades, sem dependência de URL ou REQUEST.
- services/EventCatalogCache.cfc: primeira carga única, snapshot, atualização em background e intervalo após falhas.
- includes/backend.cfm: consumo do cache e preservação dos filtros.
- includes/backend_home_cidades.cfm: reutilização das cidades preparadas.
- index.cfm: reutilização do contador.

## Verificação

- 16 verificações sintéticas: primeira carga, isolamento dos dados retornados, resposta imediata quando expirado, renovação única, falhas, payload inválido, recuperação e quatro leitores concorrentes compartilhando uma carga.
- 11 verificações com consultas reais somente de leitura: conjunto de 24.798 eventos, filtros padrão/trail/internacional/cupom/badge, cidades e ordenações. Backend e cidades com cache pronto: 65 ms. Primeira carga no teste: 7,398 s.
- A comparação de cidades usou o mesmo conjunto de linhas nas duas implementações: a query original não desempata todos os eventos, e grafias diferentes da mesma cidade podem ser escolhidas entre consultas independentes. O algoritmo de cidades foi preservado.
- Compilação CFML: 5/5 arquivos. Hashes de produção: 5/5. git diff --check sem erros.
- Home pública HTTP 200 em 0,433 s e 0,249 s, com cidades e contador presentes; filtro trail 0,200 s; busca 0,455 s; RoadRunners 0,120 s. Estado RJ retornou 200 em 4,407 s: suas estatísticas próprias continuam mais lentas e não foram otimizadas nesta alteração.
- Apache após publicação: 3 ocupados, 47 livres. Nenhum reinício ou alteração de configuração foi necessário.

Backup: /var/backups/openresults-home-cache-20261004/baseline. Manifesto e compilação no mesmo diretório pai. Para rollback, conferir hashes, restaurar primeiro index.cfm e includes, depois retirar os dois CFCs; não apagar arquivos alterados posteriormente por outra tarefa.

Artefatos e scripts de publicação/teste ficam no Business em _codex/staging/openresults-home-cache-20261004 e _codex/scripts/{test,deploy,verify}_openresults_home_cache.py. Sem commit ou push.
