# UF global disponível e percentuais de Público

## Escopo e decisão de impacto

Road Runners produz o contexto geográfico; Business apenas consulta os eventos já coletados. Antes, a home incluía `includes/location.cfm`, mas cada requisição de evento perdia `REQUEST.LocationContext`, mesmo com cookies/cache existentes.

`LocationResolver.resolveAvailable()` reutiliza somente cookies ou cache por IP ainda válido. Não faz HTTP, não grava cookies, não renova o cache e não executa sua limpeza. `Application.cfc.OnRequestStart` o chama depois dos controles de acesso existentes e expõe `REQUEST.LocationContext` quando o resultado não é fallback. Erros de leitura não interrompem a página. Há o custo local de normalização e do bloqueio de leitura já existente do cache; não há um novo timeout de rede. A consulta externa atual pode aguardar até quatro segundos por tentativa, motivo para não a acrescentar a toda navegação.

Misses continuam sem contexto, preservando a resolução completa que a home e o circuito LIVE! já executavam. Uma chegada direta fria a evento sem cookie/cache ainda não resolve uma UF nova. Resolução assíncrona dessa chegada fica fora do escopo. Não houve troca de provedor, fallback externo adicional, alteração de autenticação ou encerramento de sessões.

`visitor_uf` continua distinto da UF da prova e do mercado publicitário. Não há reconstrução retroativa da localização nem uso de perfil/evento para preencher acessos desconhecidos. Estados válidos começarão a aparecer conforme novas aberturas com localização disponível forem recebidas; o histórico desconhecido permanece desconhecido.

## Business — Público e navegação

- UF e faixa de tela: número de aberturas e percentual de todas as aberturas do recorte, incluindo UF desconhecida.
- Sequências: percentual de todas as transições filtradas, calculado antes do limite das vinte linhas exibidas.
- Sessões por sequência: percentual das sessões distintas do recorte; uma sessão pode aparecer em várias sequências, portanto os percentuais não são somáveis.
- Sem dados: texto explícito, sem divisão por zero. As tabelas mantêm rolagem horizontal própria.

Nenhuma alteração de schema ou SQL administrativo é necessária. A consulta do relatório permanece somente leitura e usa o DSN existente.

## Publicação controlada

Somente cinco arquivos: RR `services/LocationResolver.cfc`, `Application.cfc`; Business `portal/audiencia/queries/event_interest.sql`, `portal/includes/event_interest_backend.cfm`, `portal/eventos-analytics/home.cfm`.

O resolver local já continha diferenças anteriores de cache negativo não presentes em produção. O pacote é montado a partir do baseline de produção com **somente** a adição de `resolveAvailable`; tais diferenças não são publicadas. Os testes de localização rodam também contra esse candidato exato.

Ferramentas locais: `stage_publico_location.py`, `deploy_publico_location.py`. O publicador verifica hashes, metadados, backup recuperável e 119 guardas de arquivos/árvores fora do escopo; compila os quatro arquivos CFML candidatos com Adobe ColdFusion fora dos webroots antes da troca. Não altera banco, serviços, configurações, credenciais ou Git.

## Verificação

- CFML da tela: 23 cenários renderizados, incluindo Público vazio, todas as UFs desconhecidas, percentuais e denominadores além das linhas exibidas.
- CFML global: 15 verificações, incluindo cookie SC em evento AC, cache, expiração, ausência de chamadas externas e preservação do circuito em acesso frio.
- PostgreSQL temporário: suíte real passou, incluindo trinta sequências com apenas vinte linhas exibidas e filtros vazios.
- Publicador: cinco testes locais passaram, cobrindo rollback, conflito de alvo, mudanças fora do escopo e adulteração de candidato/publicado.
- Compilação Adobe: quatro candidatos compilados na etapa de preparação. A confirmação de publicação exige verificação posterior dos hashes e da página real.

## Resultado publicado

Publicado e verificado em 14/09/2026. Backup recuperável: `/var/backups/business-publico-location.6ff74deb121f`. Recibos locais: `2026-09-14_publico_location_release.json`, `-publish.json` e `-verify.json`. Os cinco hashes e metadados publicados e os 119 guardas foram confirmados.

No Business autenticado, o recorte mostrou 1.492 aberturas: desktop 801 (53,7%), mobile 681 (45,6%) e tablet 10 (0,7%). A navegação usou 292 transições e 965 sessões como denominadores, sem reduzir a base às vinte linhas. Filtro deliberadamente sem resultados mostrou textos vazios explícitos e zero totais. O filtro de teste foi removido ao final. Layout inspecionado em 1280 e 390 pixels; em 390, a largura do documento permaneceu 390 e somente a tabela larga tem rolagem própria. A sessão Business permaneceu autenticada.

Verificação HTTP pública, sem JavaScript nem envio de eventos: a página real `/evento/2026-maratona-salvador-2026/` retornou 200, contexto assinado com `visitorUf=SC` e depois `visitorUf=SP` nos dois cookies sintéticos. Em ambos, `contextUf=BA` e `marketUf=BA`; nenhuma renovação dos cookies de localização na página de evento. O script é `verify_publico_location_http.py` e não grava dados de audiência nem acessa banco diretamente.

Na última leitura do painel, as 1.496 aberturas históricas ainda estavam sem UF. Isso não foi transformado em localização presumida; aguarda-se tráfego novo com localização disponível. Testes sintéticos não foram inseridos para artificialmente preencher o quadro.

A revisão independente identificou uma regressão potencial no circuito LIVE! e o teste novo a reproduziu antes da correção. A revisão final do candidato exato não apontou P1/P2 pendentes. O teste SQL contra o baseline anterior falhou no denominador ausente e passou novamente com a consulta publicada.
