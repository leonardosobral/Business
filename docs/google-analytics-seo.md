# GA4 no painel SEO

Aba `/portal/seo/?aba=ga4`, exclusiva para administradores globais do Business. Implementada em 05/10/2026. Escopo inicial: Road Runners. Não representa indexação Google nem substitui Search Console ou Semrush.

## Ativação

1. No projeto Google Cloud do cliente OAuth já usado por Agenda/Drive, habilitar **Google Analytics Data API** e **Google Analytics Admin API**. Permitir o escopo `https://www.googleapis.com/auth/analytics.readonly` na configuração de consentimento, se necessário.
2. Na aba Audiência Google, clicar em **Autorizar Google Analytics** e concluir o consentimento com `contato@runnerhub.run`. A conta precisa ter acesso à propriedade GA4. Não há nova chave, migração ou novo endereço de callback.
3. Selecionar a propriedade que contém o fluxo `G-7MYGVTEDZV`, instalado no Road Runners. O servidor verifica esse vínculo antes de consultar relatórios. Se o identificador instalado mudar, atualizar e validar a integração.
4. Conferir os totais com a interface GA4 usando as mesmas datas, fuso e filtro hostname. A homologação com dados reais depende do consentimento e das APIs habilitadas; fixtures não comprovam essa etapa.

## Relatórios e definições

- 7, 28 ou 90 dias completos, terminando ontem no fuso configurado na propriedade. Comparação com período imediatamente anterior de igual duração. A janela de 90 dias não garante alinhamento de dias da semana.
- Totais: `activeUsers`, `sessions`, `screenPageViews`, `engagementRate`. Usuários vêm da agregação do período pelo GA4; não somamos usuários diários ou por canal. Taxa de engajamento comparada em pontos percentuais.
- Evolução por data; canais por `sessionDefaultChannelGroup`; 20 principais páginas por `landingPage`; referências identificadas de IA por `sessionSource` e `sessionMedium` (até 100 combinações).
- Filtro obrigatório `hostName` em `roadrunners.run` e `www.roadrunners.run` nos cinco relatórios. Outros hosts da propriedade são excluídos.
- Origens de IA reconhecidas por domínio/marca: ChatGPT, Perplexity, Claude, Gemini, Copilot. Não é medição de citações ou presença nas respostas. Atribuição ausente pode aparecer como Direct. Não representa todo o tráfego de IA.
- Cinco relatórios em `batchRunReports`. Dados consultados ao abrir a aba e carregar filtros, com cache em memória de até 15 minutos por propriedade/período/data. Não existe cron ou histórico local persistido; reinício limpa o cache. Não há filtro de período parcial de hoje.
- Metadados de amostragem, thresholding e cardinalidade retornados pelo Google geram avisos. Últimos dias podem ser revisados pelo processamento do GA4. Bloqueadores, consentimento e configuração das tags podem produzir divergências em relação à audiência própria. Valores GA4 não devem ser tratados como contagem garantida de pessoas ou tráfego livre de bots.

## Segurança e operação

OAuth compartilhado com Agenda/Drive/Gmail, com state de uso único, PKCE, verificação de conta/ator e armazenamento criptografado existentes. Analytics é somente leitura. Callback preserva a conexão anterior se uma permissão obrigatória/prévia não for concedida. Reconexões de Agenda e AI-mails mantêm o escopo Analytics quando já autorizado. Nenhum token é enviado ao JavaScript.

API `portal/seo/ga4_api.cfm`: autenticação existente, administrador global, POST e CSRF. Endpoints Google fixos com allowlist. Erros externos não retornam corpos de resposta ou credenciais. Conteúdo de relatórios renderizado via `textContent`; caminhos de página não viram HTML ou links arbitrários.

Arquivos runtime: `portal/conteudo/seo.cfm`, `seo_ga4.cfm`; `portal/seo/ga4_api.cfm`, `ga4_service.cfm`, `assets/ga4.js`, `assets/ga4.css`; `administracao/agenda/api.cfm`, `oauth/callback.cfm`; `administracao/ai-mails/includes/service.cfm`.

## Verificação

- `node --test _codex/tests/seo_ga4.test.cjs`
- `_codex/tests/seo_ga4_service.cfscript`: períodos, anos bissextos, limites, hostname, serialização camelCase Adobe, vínculo da propriedade, cache e OAuth.
- `_codex/staging/seo-ga4-20261005/verify.py candidate|published`: cópia temporária localhost e APIs simuladas; testes HTTP de acesso, render e métodos.
- Interface inspecionada em browser desktop e 390px, com fixture demonstrativa explicitamente identificada. Tabelas com rolagem interna, abas por hash e conteúdo malicioso exibido como texto.

Publicação restrita com baseline, compilação Adobe e backup recuperável em `/var/backups/seo-ga4-20261005`. Não publicar documentação, fixtures ou staging. Rollback pelo script da release, condicionado a hashes para preservar alterações concorrentes.

Referências: [Data API](https://developers.google.com/analytics/devguides/reporting/data/v1), [batchRunReports](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/batchRunReports), [DateRange](https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/DateRange).

## Recibo de publicação — 05/10/2026

Nove arquivos runtime publicados e hashes verificados; nove dependências fora do escopo permaneceram iguais. Sete templates compilados no Adobe ColdFusion. Verificações antes e depois: 26 checks de serviço e oito de HTTP. Oito testes Node passaram (três GA4 e cinco regressões do modelo de calendário). API pública sem sessão retornou 403; asset JavaScript público retornou 200 e hash idêntico ao candidato.

Estado final: código publicado, consentimento Analytics pendente. Interface de autorização e dashboard com respostas simuladas verificados em navegador; não foi possível abrir Chrome por indisponibilidade da ferramenta. O dashboard autenticado com dados reais exige que o usuário conclua o consentimento Google e, se necessário, habilite as APIs. Não houve migração, alteração dos registros de audiência, commit ou push.
