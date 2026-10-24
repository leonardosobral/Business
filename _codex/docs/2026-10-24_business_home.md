# Home administrativa do Business

Publicada em 24/10/2026 às 13:35:27, horário de Brasília, em `business.roadrunners.run`. A home do administrador global reúne indicadores reais de 7 ou 30 dias, exceções operacionais acionáveis e atalhos organizados por abas. A publicação ficou restrita aos cinco arquivos abaixo; não houve migração, alteração de credenciais, commit, push ou PR.

## Comportamento

Os indicadores usam períodos que incluem o dia atual e identificam a comparação com o período anterior completo. Visitantes representam identidades de navegador; o consumo de publicidade corresponde aos anúncios internos EVENT e BANNER, com acesso aos dois destinos. As fontes de audiência, anúncios, contas e usuários carregam de forma independente, com cache de um minuto e limite de cinco segundos por consulta. Falha de uma fonte aparece como indisponibilidade, sem transformar ausência de dados em zero.

Filas carregadas com valor zero ficam ocultas; filas positivas e falhas de consulta permanecem visíveis. As abas mantêm período, filtros e navegação por links, clique e teclado. Cabeçalho, sala Meet, autenticação e seleção de conta continuam usando os contratos existentes.

O histórico disponível permite comparar visitantes e páginas em sete dias. Interações em sete dias e audiência em trinta dias exibem histórico insuficiente; esse resultado é esperado e evita apresentar crescimento sem cobertura comparável. A cobertura das interações tem uma verificação própria, mais restritiva.

## Escopo publicado

| Arquivo | Responsabilidade |
| --- | --- |
| [business_home_metrics.cfm](/Users/Shared/Projects/RunnerHub/Business/includes/backend/business_home_metrics.cfm) | Consultas agregadas, períodos, cache e disponibilidade independente das fontes. |
| [home_admin_decision_view.cfm](/Users/Shared/Projects/RunnerHub/Business/includes/estrutura/home_admin_decision_view.cfm) | Indicadores, exceções e conteúdo das abas. |
| [business-home-dashboard.js](/Users/Shared/Projects/RunnerHub/Business/assets/js/business-home-dashboard.js) | Interação acessível das abas e sincronização com a URL. |
| [admin-dashboard.css](/Users/Shared/Projects/RunnerHub/Business/assets/css/admin-dashboard.css) | Apresentação da home. |
| [home_admin_dashboard.cfm](/Users/Shared/Projects/RunnerHub/Business/includes/estrutura/home_admin_dashboard.cfm) | Integração das métricas e da nova visualização, preservando as definições das filas. |

O baseline de produção correspondia às cópias locais originais do dashboard e do CSS; os três arquivos novos estavam ausentes. O pacote foi preparado em área privada, compilado e instalado por substituições atômicas de arquivo, com o ponto de entrada por último. A verificação posterior confirmou os cinco hashes, proprietário, grupo e permissões, além da preservação dos seis caminhos de dependência monitorados. Os hashes completos estão no [recibo de verificação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/release-verify.json).

## Validação

| Verificação | Resultado |
| --- | --- |
| Renderização CFML da interface | 43 verificações em seis cenários, incluindo cobertura independente das interações. |
| Testes Node focados | 29 aprovados, cobrindo filas, abas, URL, teclado e contratos existentes. |
| Métricas em PostgreSQL isolado | 36 verificações aprovadas. |
| Backend CFML | 339 verificações aprovadas. |
| SQL de cron | 30 verificações aprovadas. |
| Compilação Adobe ColdFusion 2025 | Três templates CFM compilados no runtime de produção. |
| Proteções do publicador | Sete verificações locais de baseline, metadados, caminhos, substituição e reversão. |
| Integridade depois da publicação | Cinco arquivos confirmados e seis dependências preservadas. |

Os oito casos de consultas reais — quatro fontes em dois períodos — passaram em transações `READ ONLY`, sem cache. A audiência respondeu em 1,14 segundo para sete dias e 1,90 segundo para trinta dias; as demais fontes responderam entre 2 e 19 milissegundos. A agregação por visitante eliminou o timeout observado na primeira versão. As consultas finais e suas evidências estão vinculadas por hash em [production-metrics-sql-integrity.json](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/production-metrics-sql-integrity.json), com resultados agregados em [production-metrics-final.json](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/production-metrics-final.json). Os probes ficaram restritos a loopback e foram removidos ao terminar.

No Chrome autenticado, a página publicada confirmou dados reais de sete e trinta dias, ocultação das filas zeradas e funcionamento das abas Contas, Conteúdo e Comunicação por clique e seta para a direita, preservando os filtros. Evidências: [recibo da interface](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/production-ui-check.json) e [captura da home](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/home-publicada.png).

O acesso anônimo retornou HTTP 200 com a landing pública e opções de entrada, sem a home administrativa. A asserção confirmou ausência de `data-business-home` e de “Usuários do site”; o HTML temporário foi eliminado. O resultado sanitizado está em [production-anonymous-check.json](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/production-anonymous-check.json). Não foi realizada navegação real com uma conta delegada; os arquivos de autenticação e os pontos de entrada monitorados foram preservados.

A suíte Node geral registrou 251 aprovações em 257 testes, com seis falhas preexistentes fora do escopo: ordenação de Plataforma, resumo individual de conteúdo, navegador da agenda Google, migrações de Kanban e Drive, e isolamento da tela de inscrições. O log completo permanece em [business-home-node-suite.log](/tmp/business-home-node-suite.log); os 29 testes focados estão em [scoped-tests.log](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/scoped-tests.log).

## Backup e reversão

Estágio privado no servidor: `/var/backups/business-home-20261024-bmev1ttg`. O subdiretório `baseline` guarda as versões anteriores dos dois arquivos existentes; `candidate` e `manifest.json` guardam o pacote e os metadados necessários à recuperação. Os recibos locais de [preparação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/release-prepare.json), [compilação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/release-compile.json) e [publicação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/release-publish.json) identificam esse estágio.

A reversão está disponível pelo mesmo driver, mantendo os arquivos locais do pacote e o acesso SSH usados na preparação:

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-home-20261024/release.py rollback
```

O comando restaura o dashboard e o CSS com seus metadados anteriores e retira os três arquivos criados, preservando suas cópias no estágio. O driver interrompe a operação se detectar alterações concorrentes ou divergência do pacote local, para não sobrescrever trabalho posterior. Não há reversão de banco de dados. Depois de uma eventual reversão, conferir novamente a home autenticada e a landing anônima.
