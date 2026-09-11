# Audiência — fechamento da implementação

> Atualização de implantação: [publicação, proteção SQL e bloqueios atuais](2026-09-07_audiencia_publicacao.md). Os 15 arquivos Business foram publicados após autorização explícita, com backup privado, hashes conferidos e HTTP403 do guard confirmado na origem antes dos SQLs. A UI autenticada em produção foi validada no estado real **“Medição aguardando instalação”**; migrações/coleta continuam pendentes. As 73 verificações abaixo registram a versão anterior ao guard, não uma nova homologação nativa completa dele.

## Escopo aprovado

O usuário autorizou continuar a implementação até o final, com prioridade no painel do Business. Superfície: aplicação existente, não um dashboard externo. RoadRunners é produtor e dono do contrato; Business é consumidor administrativo. Opt-out com GPC e retenção de 90 dias confirmados. Não alterar autenticação, comprar mídia, criar branches/commits ou presumir histórico anterior.

## Checklist de conclusão

- [x] Painel nativo com resumo, filtros, gráficos, tabelas completas e fallback sem JavaScript.
- [x] Comparação regional por contexto comercial, acesso, perfil ou página.
- [x] Aquisição por campanha/variante e sessões qualificadas; perfis distintos não se confundem com reloads/modais.
- [x] Saúde opcional de retenção sem bloquear métricas quando a rotina não estiver instalada.
- [x] Integrar cliente: recusa, GPC, preferência posterior, limpeza/expiração de IDs e tratamento de 429.
- [x] Integrar servidor: configuração exata por host, bot/prefetch e limitação isolada por host.
- [x] Integrar retenção: migração, executor privado, estado operacional e testes.
- [x] Revisão independente final e regressão SQL/CFML/HTTP/navegador dos arquivos integrados.
- [x] Registrar manifesto final, ordem de publicação, configuração e limitações operacionais.

## Contrato dos gráficos

| Seção | Questão | Dados e forma | Restrições |
| --- | --- | --- | --- |
| Acessos e posições visíveis por dia | Como evoluem as duas contagens? | `daily.sql`, 7/30/90 dias observados; barras agrupadas se menos de 8 dias, linhas quando há 8 ou mais. | Nunca empilhar métricas, nunca preencher dias não observados com zeros; eixo zero. Tabela exata disponível. |
| Posições visíveis por UF | Onde se concentra a exposição observada? | `regions.sql`, até 6 UFs ordenadas por `slot_views`, barra horizontal. | A dimensão regional vem do filtro. Sem somar visitantes entre UFs. Sem exposições: estado vazio, não ranking fictício. |

Paleta azul/dourado já compatível com Business; séries distinguíveis por rótulo e tracejado nas linhas. Componentes MDB existentes, sem nova biblioteca remota. Exatos valores ficam nas tabelas; conteúdo individual e inventário detalhado são consultas de lookup, não gráficos decorativos.

## Evidência final de implementação e teste

- O novo painel foi renderizado no Adobe ColdFusion, usando consultas reais em PostgreSQL descartável.
- Chrome 1440px e 390px: gráficos MDB reais, filtros e disclosures, sem overflow da página, fallback sem JavaScript.
- A inspeção visual detectou o empilhamento padrão do MDB; teste de navegador reproduziu `true != false` e confirmou a correção com `stacked=false`.
- Correção de sessão qualificada: RED para dois perfis diferentes; GREEN em 51 assertivas SQL e 27 assertivas de integração RoadRunners→Business.
- Dados de screenshots/homologação são sintéticos e protegidos, não representam tráfego real.

Resultados confirmados nos arquivos integrados:

| Verificação | Resultado / escopo |
| --- | --- |
| Adobe ColdFusion HTTP + PostgreSQL real descartável | **73 verificações PASS**, incluindo bootstrap assinado, ingestão/replay, filtros/7 consultas Business, controle admin/includes, opt-out/GPC/bots/prefetch, 429/Retry-After, privacidade PT/EN/ES, estados de retenção e indisponibilidade. |
| Consultas Business em PostgreSQL 16 | **51 assertivas PASS**; identificação de perfis distintos, reload, modais, SP→SC, denominadores, desconhecidos, filtros e inventário. |
| RoadRunners→Business, migração/ingestão reais | **27 assertivas PASS**; consultas por leitor em transações somente leitura e isolamento financeiro. |
| Tracker, preferência e traduções | **43 testes Node PASS**; expiração de IDs, recusa entre abas, storage bloqueado, imagem/aba/tempo, eventos idempotentes e espera após 429. |
| Modelos do dashboard | **5 testes Node PASS**; datas observadas, tipo/eixo dos gráficos, ranking regional, desconhecidos, ausência de denominador e de dados. |
| Dashboard real em Chrome | **1440px e 390px PASS**, usando HTML final renderizado no Adobe, gráficos MDB reais, filtros/disclosures, ausência de overflow global e fallback sem JS. |
| Business publicado, autenticado | **PASS no escopo pré-instalação**: rota/menu, filtros simples e avançados, atalho SC, reset e persistência por URL; estado “Medição aguardando instalação” sem números/gráficos inventados. Desktop1571px e mobile390×844 após reload sem corte horizontal. Resize dinâmico completo do shell não é alegado. |
| RoadRunners em Chrome | **6 cenários PASS** após integração do cliente: desktop/mobile, troca SP→SC, estado vazio, filtros/paginação reais e preferência via teclado. |
| Controles CFML | Contratos do serviço de coleta e dos controles de request **PASS**, incluindo separação dos limites por host. |
| Retenção PostgreSQL 16 | Reaplicação limpa, primeira instalação/default ACLs, **10 colisões de memberships/ACLs rejeitadas com rollback preservado**, corte de 90 dias, limites, reenvio, lock, erro/estado, job privado, CLI somente leitura e guard de produção **PASS**. |
| Regressão Ads DOM-ready, sintaxe e whitespace | **PASS**. Business `Application.cfc`, `backend_login.cfm` e `require_admin.cfm` sem alterações frente a HEAD. |

Revisões independentes motivaram correções no isolamento de quota por host, preservação da fila no 429, recusa com armazenamento bloqueado, qualificação por identidade de página e permissões da manutenção. A revisão final também corrigiu o rótulo de retenção: o painel mostra **política** e estado real, sem garantir 90 dias quando a rotina está ausente/atrasada. Esse último caso teve RED no navegador contra o HTML anterior e GREEN na execução final. Nenhum P1/P2 remanescente nos achados revisados; não é alegação de auditoria exaustiva da aplicação inteira.

Última rodada nativa: `/var/www/dev.roadrunners.run/rr-audience-http-kK1RvA`, protegida antes da cópia de CFML por Apache e depois por loopback/token. Ao terminar, a rota foi fechada por movimentação para `/var/tmp/rr-audience-http-kK1RvA-closed`; túnel encerrado e PostgreSQL descartável parado. Diagnósticos locais: `/var/folders/ct/41b1hy657kq5s56h529h2y3m0000gn/T/rr-audience-native-ZiFS41`. Não foram usadas sessões/cookies de usuários nem datasources globais de produção. Depois da publicação e de autorização específica, o login Google existente e o painel completo foram exercitados no estado pré-instalação: filtros e reloads mantiveram a sessão durante essa validação, sem alegar continuidade através do deploy ou validar métricas ainda inexistentes.

Prévias **com dados sintéticos de homologação**, sem o shell completo autenticado: [desktop](/Users/leonardosobral/.codex/visualizations/2026/09/07/01a07958-f899-7911-b124-c6816310077f/audiencia-business-desktop-homologacao.png), [relatório inteiro](/Users/leonardosobral/.codex/visualizations/2026/09/07/01a07958-f899-7911-b124-c6816310077f/audiencia-business-completo-homologacao.png), [mobile](/Users/leonardosobral/.codex/visualizations/2026/09/07/01a07958-f899-7911-b124-c6816310077f/audiencia-business-mobile-homologacao.png).

### Reproduzir as verificações principais

No Business:

```sh
node --test _codex/tests/audience-dashboard.test.cjs
node _codex/scripts/test_audience_report_local.mjs
node _codex/scripts/test_audience_native_http.mjs --run-isolated-dev
node _codex/scripts/test_audience_dashboard_browser.mjs /caminho/rr-audience-native-ID/business-report.html
```

No RoadRunners:

```sh
node --test _codex/tests/audience-tracker.test.js _codex/tests/audience-privacy-controls.test.js _codex/tests/audience-privacy-i18n.test.js
node _codex/scripts/test_audience_business_integration_local.mjs
node _codex/scripts/test_audience_retention_local.mjs
bash _codex/scripts/test_audience_server_controls_local.sh .
node _codex/scripts/test_ads_v1_viewability_dom_ready.mjs
AUDIENCE_BROWSER_CHANNEL=chrome node _codex/tests/audience-browser.test.mjs
```

Os runners de banco exigem PostgreSQL 16 e permissão para processos/sockets locais; o HTTP exige SSH configurado e apenas a execução isolada descrita. Os testes de navegador usam a biblioteca Playwright instalada e Chrome; nesta máquina foi necessário `NODE_PATH=/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules`. Sem runtime/caminho disponível, falhar explicitamente, não usar silenciosamente uma base real. Nenhum desses comandos deve ser convertido em endpoint público.

## Limites operacionais

Esta implementação não deve ser confundida com coleta pública ativada. A implantação exige migrações como operador de DDL, identidade privada e agenda para retenção, segredos/configuração por host fora do Git e verificação de IP de cliente no proxy confiável. A política de backups/logs é separada da exclusão da tabela ativa. Não há gasto nem campanha de aquisição externa criada.

### Bloqueio confirmado no servidor

A inspeção SSH somente leitura encontrou o módulo Apache `remoteip` carregado, mas não encontrou `RemoteIPHeader`/`RemoteIPTrustedProxy`/`RemoteIPInternalProxy` nos vhosts públicos principais, www, beta e dev nem em configuração global ativa. Assim, ainda não está comprovado que `CGI.REMOTE_ADDR` identifique o cliente, em vez de um proxy compartilhado. O limite padrão de 60 requisições/minuto poderia rejeitar visitantes legítimos agrupados no mesmo endereço. Não foi contornado usando `X-Forwarded-For` arbitrário, desativando o limite ou habilitando coleta assim mesmo. A infraestrutura compartilhada não foi alterada.

### Configuração atual — substitui as flags escalares antigas

RoadRunners usa `APPLICATION.audienceMeasurement.hosts[hostname]`, com host exato, ambiente esperado e `enabled=false` por padrão. `config/audience.local.example.cfm` é somente exemplo; o arquivo operacional `config/audience.local.cfm` fica fora do Git. Chaves por host: `environment`, `enabled`, `secret`, `rateLimitRequests` (default 60), `rateLimitWindowSeconds` (60), `rateLimitMaxKeys` (5000).

Preferir segredos de pelo menos 32 caracteres em `RR_AUDIENCE_MEASUREMENT_SECRET_PROD`, `_BETA`, `_DEV` ou `_LOCAL`. Há fallback para `RR_AUDIENCE_MEASUREMENT_SECRET` e depois para o arquivo local, mas não se recomenda reutilizar um segredo entre ambientes. Host ausente, ambiente divergente ou segredo curto mantém a coleta desligada. As antigas `audienceMeasurementEnabled`/`audienceMeasurementSecret` não ativam o protocolo novo.

Os webroots RoadRunners compartilham `APPLICATION.name`. Instalar o mesmo mapa completo e coerente nos roots envolvidos; configuração incompleta em um deles não pode ser tratada como configuração independente. O hook de inicialização garante a presença do mapa sem reiniciar ColdFusion; a implantação deve validar como a configuração será recarregada, sem expor um endpoint público de ativação.

O limitador é por instância ColdFusion, particionado por host, com chave HMAC truncada de host/endereço do cliente; não armazena IP bruto. Cada host tem teto próprio, evitando que dev consuma a capacidade de prod. Os quatro hosts padrão podem ocupar, juntos, até 20.000 entradas efêmeras. Não é limitador distribuído nem prova de presença humana. GPC, bots conhecidos e prefetch/prerender retornam 204 antes de persistir; excesso retorna 429/Retry-After. O cliente preserva eventos para tentar depois desse prazo, sujeito aos limites declarados de fila/rede.

### Preferência e retenção

O controle de medição está disponível no layout público, com textos PT/EN/ES, foco de teclado, fechamento por Escape e alteração posterior. GPC prevalece sobre aceite. Recusa limpa a fila e os identificadores, para a coleta na aba e é propagada entre abas por armazenamento local. Quando armazenamento e cookie estão bloqueados, a recusa permanece na página atual e a interface informa que não conseguiu persistir; não recarrega nem afirma falsamente que salvou. Não promete exclusão retroativa.

O identificador de visitante expira em até 90 dias desde a criação, sem renovação deslizante; sessão usa 30 minutos de inatividade. Eventos detalhados vencem 90×24 horas após o primeiro recebimento, preservado em reenvios. A função privada apaga em lotes de até 5000, com lock, timeout e estado operacional; não cria arquivo/agregado indefinido. O painel distingue rotina ausente, nunca executada, em dia, atrasada, com fila e erro.

`runner` e `runner_dba` não recebem a capacidade de expurgo. A migração rejeita colisões de owner, ACLs inesperadas/delegáveis, default ACLs e memberships diretos/indiretos dos leitores nos papéis de manutenção; não tenta corrigir silenciosamente permissões preexistentes. Um job privado no grupo executor continua permitido. Detalhes, comandos e limites em `RoadRunners/_codex/docs/audience-retention-90-days.md`. Agenda horária implica aproximadamente 90 dias + 1 hora em operação normal sem backlog; falhas/fila exigem intervenção. Agenda não foi instalada.

## Pacote e ordem segura de implantação

Manifestos **somente runtime** nesta pasta:

- [Business](2026-09-07_audience_business_runtime_files.txt): painel, consultas, assets e entrada administrativa no menu.
- [RoadRunners](2026-09-07_audience_roadrunners_runtime_files.txt): contexto, instrumentação, coletor, privacidade e configuração-base desligada.

[Manifesto com SHA-256](2026-09-07_audience_release_manifest.json): **14 arquivos runtime Business + 31 RoadRunners**, mais quatro artefatos privados de implantação. Os 49 hashes foram conferidos contra o código local final; isto não comprova correspondência com produção nem autoriza sobrescrever diferenças remotas.

Não publicar a raiz `_codex`, testes, fixtures HTTP, relatórios sintéticos ou arquivos locais secretos no document root. As migrações `RoadRunners/_codex/sql/2026-09-07_audience_inventory.sql` e `2026-09-07_audience_retention.sql` são artefatos privados para operador de DDL. O executor `RoadRunners/_codex/scripts/run_audience_retention.mjs` deve ser instalado fora da superfície pública, com libpq service e identidade exclusiva; sem senha/URI na linha de comando. O exemplo de configuração não contém segredo e não substitui o arquivo operacional privado.

1. Conferir diffs de cada repositório e hashes do pacote. Backups/versionamento do deploy são responsabilidade operacional; não sobrescrever mudanças concorrentes.
2. Em homologação, aplicar inventário e depois retenção pelo fluxo de DDL existente, verificar grants do datasource real e provisionar o job privado. Rodar primeiro em modo de consulta; execução de expurgo exige `--execute` e, em prod, aprovação operacional explícita no ambiente do job.
3. Resolver e verificar o proxy confiável, inclusive que um cliente não possa falsificar sua origem por header e que duas origens reais não compartilhem um bucket indevido. Manter os hosts desligados até essa validação.
4. Publicar os runtimes nas raízes correspondentes, configuração privada coerente e segredos fora do Git. Banco aditivo vem antes do frontend; Business sem schema mostra instalação pendente. Não há mudança de login Business neste pacote.
5. Homologar páginas completas (home, estado com/sem resultados, busca/AJAX, evento, perfil, notícias, vídeos), desktop/mobile, anônimo/logado e permissões administrativas reais. Conferir privacidade, 429, estado de retenção e saldo Ads inalterado. Os testes isolados não substituem esse smoke test integrado à instalação real.
6. Instalar/verificar a agenda horária e sua observabilidade. Só então habilitar explicitamente o host público e observar coleta/cobertura. Fallback operacional: desligar o host sem remover schema/dados nem reverter autenticação. Parar o job interrompe futuras exclusões, mas não recupera dados já apagados.

Backups locais adicionais desta continuação: `/private/tmp/rr-audience-controls-before.5SyqYc`, `/private/tmp/rr-audience-privacy-before.UWl3GW` e `/private/tmp/rr-audience-retention-hardening-before.eBz5he`. São temporários, não substituem commit ou backup de produção. Nenhum commit, branch, push, deploy público, migração de produção ou mudança de infraestrutura foi feito.

## Limites do que a tela afirma

Histórico começa quando a coleta for instalada e ativada; não há reconstrução de visibilidade passada. “Posição registrada” pode estar vazia ou colapsada; só área realmente montada e exposta chega a “visível”. Geometria não comprova atenção humana e não detecta toda sobreposição. IDs estimam navegadores, não pessoas entre dispositivos. Recusas, GPC, bloqueadores, rede e fechamento de abas reduzem cobertura; os totais são dos eventos observados, não estimativa corrigida do público perdido.

Conteúdo individual mantém tipo/ID canônicos sem URLs livres; reprodução de vídeo depende de sinais reais do player. YouTube em iframe continua abertura de modal, sem afirmar início/conclusão não instrumentados. O painel não inclui previsão de entrega, custo de aquisição sem gasto importado, coortes de retorno, funil de cadastro/histórico ou certificação publicitária. Também não executa débito de créditos. Sessão qualificada nesta versão significa 30 segundos ativos ou duas páginas de conteúdo distintas no recorte.

## Continuação comercial

O painel já separa campanha e variante UTM para comparar “Ache sua corrida” e “Monte seu histórico”. SC permanece o piloto controlado; SP é uma possibilidade de expansão, não uma restrição nacional. Antes de comprar mídia, formar linha de base e definir teto de verba. Comparar sessões qualificadas e posições visíveis geradas, não apenas cliques de entrada. Sem verba/acesso autorizados, nenhuma campanha ou compra foi criada.

Referências de implementação: [DateTimeFormat Adobe](https://guides.adobe.com/content/coldfusion-docs/en/docs/cfml-reference/datetimeformat.html) e [gráficos MDB](https://mdbootstrap.com/docs/standard/data/charts/). As skills build-dashboard e visualize-data orientaram a hierarquia e os denominadores; TDD, systematic-debugging e revisão independente orientaram a validação.
