# Diagnóstico de tempo da home OpenResults

Medição em 04/10/2026, sem alteração do runtime público. Duas execuções sequenciais das instruções de produção em aplicação CFML isolada, restrita a loopback e removida ao final. Consultas reais somente de leitura; nenhum cache de produção foi limpo. A cópia de diagnóstico preservou cachedwithin e o datasource runnerhub. Incluiu catálogo, filtros, cidades, contagem de resultados e consultas de eventos recentes/próximos; não incluiu toda a renderização HTML, cabeçalho ou resolução de localização.

| Etapa | Sem cache no diagnóstico | Repetição com cache |
| --- | ---: | ---: |
| qEventosBase, 24.798 registros | 4.253 ms | 21 ms |
| qTotalResultados, count dos resultados | 2.196 ms | 0 ms |
| catálogo de 2.708 cidades | 671 ms | 569 ms |
| Total das etapas instrumentadas | 7.218 ms | 648 ms |

A consulta base está em OpenResults/includes/backend.cfm e agrega badges, percursos, cupons e quantidades de concluintes com subconsultas, sobre o histórico inteiro elegível. Cache configurado em 5 minutos. A contagem de resultados em index.cfm tem cache de 15 minutos. A criação do catálogo de cidades em includes/backend_home_cidades.cfm percorre todos os eventos e reconstrói listas a cada execução, sem cache próprio.

Duas requisições públicas consecutivas à home retornaram 200: 7,188 s (primeiro byte 7,185 s) e 1,403 s (primeiro byte 1,131 s). Confirma a oscilação observada entre carga cara e reutilização, coerente com o teste isolado. Sem instrumentação da página pública não se atribui cada milissegundo dessas duas requisições às etapas isoladas.

Há também geolocalização externa síncrona com timeout de 4 s para IP sem contexto/cache, identificada no código, porém não medida como causa desses 7 segundos. A medição não sustenta atribuir a demora atual ao Runner Apps.

Direção sugerida, não implementada: separar consultas enxutas dos cards e dados agregados de cidades/contagem; manter agregados prontos com atualização única em background e servir o último resultado válido enquanto atualiza. Não carregar e enriquecer todo o histórico para cada reconstrução da home.

Dados brutos em staging/openresults-home-profile-20261004/profile.json e http.json; ferramenta em scripts/profile_openresults_home.py.
