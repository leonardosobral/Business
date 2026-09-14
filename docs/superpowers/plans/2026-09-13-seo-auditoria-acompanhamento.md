# Auditoria e acompanhamento SEO — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development ou superpowers:executing-plans para executar este plano por tarefa. A execução do primeiro ciclo foi autorizada em 13/09/2026; consultar o estado datado abaixo. Não realizar commits, branches, tags, push ou PR sem solicitação do usuário.

**Goal:** transformar o inventário existente em auditoria técnica confiável e comparável para RoadRunners e OpenResults, com evolução independente para dados de busca e audiência.

**Architecture:** preservar a CLI RoadRunners como entrada de um coletor instalável isoladamente; Business mantém configuração dos sites, orquestração operacional e comparação de relatórios privados. Cada site continua dono de seu conteúdo, sitemap, robots e regras públicas. A primeira versão funciona com arquivos, sem painel, banco novo ou serviço permanente.

**Tech Stack:** Node.js 22 no executor (revisão reproduzida em v22.21.1), ESM, `node:test`, `fetch`, parsers `saxes`, `parse5` e `robots-parser` em pacote isolado; JSON/CSV/Markdown. CFML apenas nas correções públicas comprovadas e em eventual painel posterior.

**Spec:** [Revisão Astra, decisões e contrato mínimo](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-13_revisao_seo_astra.md), apoiada no [plano AIO/GEO existente](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/plano_aio_geo_road_runners_2026.md).

## Estado da execução atualizado em 14/09/2026

As tarefas 1–3 foram implementadas e testadas; o piloto da tarefa 4 gerou a fila exibida no Business. A descoberta RoadRunners foi recuperada e reconciliada com 33.095 eventos em três idiomas. RR-02 foi concluído no primeiro lote; RR-03, RR-04 e OR-01 foram publicados e conferidos em 14/09. O lote atual e suas evidências estão no [registro de correções de canonical e sitemap](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-14_seo_canonicals_publicacao.md). Agenda e fontes Google continuam pendentes; os números das auditorias anteriores permanecem datados, sem serem apresentados como uma nova coleta.

Em 14/09, o usuário também autorizou ampliar a tela com verificações aprovadas, cores por resultado e uma nota estimada. Essa extensão usa uma heurística interna separada dos achados originais, com pesos e cobertura explícitos. O [contrato do relatório e da pontuação](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-14_seo_relatorio_pontuacao.md) substitui a restrição inicial de não exibir nota no painel, preservando as limitações da auditoria e a separação dos dados Google.

## Restrições globais

- Origem: revisão e plano; o usuário autorizou iniciar o primeiro ciclo em 13/09/2026. Escopo iniciado: tarefas 1–4, ferramenta operacional e piloto. Agenda, conexão de contas, painel e correções públicas descobertas no piloto são entregas posteriores.
- Repositórios independentes em `/Users/Shared/Projects/RunnerHub/`; preservar alterações de outras frentes e conferir os respectivos AGENTS antes da execução.
- Não criar commits, tags, branches, pushes ou pull requests sem solicitação do usuário.
- Não usar pacotes do microsite `maratonadefloripa/` para esta ferramenta. Não transformar a raiz CFML em aplicação Node.
- A ferramenta só solicita URLs públicas de hosts explicitamente permitidos; não reutiliza cookies de sessão nem simula identidade autenticada de Googlebot.
- Relatórios reais e exportações privadas ficam fora do docroot e do Git. Não publicar tokens, cookies ou segredos em artefatos.
- HEAD não avalia HTML; página 200 não significa indexada; latência de uma requisição não é Core Web Vitals; sitemap não é censo completo do acervo.
- Eventos futuros e eventos sem resultados no OpenResults podem ser páginas válidas. Não usar essa ausência como critério automático de soft 404.
- Não executar crawl completo dentro de request CFML. O cron HTTP do Business não é executor Node.
- Correções futuras de runtime devem seguir baseline de produção, backup recuperável, lista restrita de arquivos e verificação real após publicação, respeitando o escopo autorizado em cada projeto.

## Etapas e tamanho sugerido

| Etapa | Entrega verificável | Ordem |
| --- | --- | --- |
| 1 | Coletor com descoberta e transporte confiáveis | Primeiro |
| 2 | Auditoria de HTML, robots e canonical com regras explícitas | Após 1 |
| 3 | Configuração dos dois sites, histórico e comparação | Após 1; integrar 2 antes do piloto |
| 4 | Piloto público limitado, baseline e fila de correções | Após 1–3 |
| 5 | Relatório semanal e execução recorrente | Após duas execuções manuais estáveis |
| 6 | Search Console e GA4 por importação validada | Independente após definir o contrato de dados |

Primeiro ciclo encerra em 1–4. Agenda e fontes privadas são entregas próprias. Um painel visual no Business só entra depois de os relatórios demonstrarem utilidade e confiabilidade.

## Contrato de dados e de execução

Novo diretório por execução: `SEO_REPORT_ROOT/<site_id>/<run_id>/`. `SEO_REPORT_ROOT` é configuração operacional obrigatória fora do docroot; não é um caminho vindo de URL/formulário. Identificadores aceitos: `roadrunners` e `openresults`.

- `manifest.json`: versão do schema e das regras, hash do coletor/configuração, site, URL do índice, início/fim UTC, modo, amostragem, limites, contagens, integridade e hashes dos demais arquivos.
- `observations.jsonl`: uma observação por URL, incluindo origem nos sitemaps, `lastmod` bruto, status inicial/final, cadeia de redirects, headers pertinentes, canonical bruto/resolvido, diretivas por agente, título/H1, duração e erro tipado.
- `inventory.csv`: as dez colunas atuais preservadas na mesma ordem; novas colunas aditivas. JSON preserva valores exatos; CSV neutraliza prefixos de fórmula em texto ao exportar para planilhas.
- `findings.json`: objetos `{ site_id, source_url, rule_id, severity, evidence, evaluated_at }`; sem score embutido. O relatório posterior calcula sua nota interna em artefato separado e versionado.
- `summary.md`: cobertura, limites, problemas novos/resolvidos/persistentes e próximas ações, com URL e evidência.

Estados separados:

```js
// Contrato do manifesto; tipos semânticos usados pelas etapas seguintes.
// completion: 'complete' | 'partial' | 'failed'
// scope: 'full' | 'sample'
// discovery_complete: boolean
// html_evaluation: 'evaluated' | 'not_evaluated' | 'failed'
// canonical_url: string | null
// source_sitemaps: string[]
// rule severity: 'error' | 'warning' | 'info'
// exit: 0=rodada válida, 2=achados/falhas de páginas, 1=erro operacional.
```

`complete/sample` significa que a amostra planejada foi concluída, não que todo o site foi verificado. `partial` não atualiza o apontador da última execução completa. Metadado não avaliado usa `null` no JSON, não string vazia interpretada como ausência de tag.

A CLI mantém HEAD no modo legado padrão e GET em `--deep`. `--deep` sozinho continua sendo inventário de HTML, sem habilitar regras SEO. O novo `--audit` implica GET e avaliação HTML; combiná-lo com `--deep` é redundante e válido. Não existe auditoria HTML por HEAD. A precedência do exit code é `1` (erro operacional/integridade) antes de `2` (falhas de páginas/erros SEO), antes de `0`.

## Tarefa 1 — Corrigir descoberta e transporte

**Arquivos RoadRunners**

- Alterar `_codex/scripts/seo_inventory.mjs`: preservar flags e encaminhar execução para o pacote.
- Criar `_codex/scripts/seo/package.json`, `package-lock.json` e `.gitignore`: ESM, privado, Node >=22, scripts de teste; `node_modules/` ignorado.
- Criar `_codex/scripts/seo/cli.mjs`: validar argumentos, executar e escolher exit code.
- Criar `_codex/scripts/seo/http.mjs`: transporte limitado, redirects e cancelamento.
- Criar `_codex/scripts/seo/sitemap.mjs`: parsing e descoberta com proveniência.
- Criar `_codex/scripts/seo/test/http.test.mjs`, `sitemap.test.mjs` e `cli.test.mjs`.
- Atualizar `_codex/docs/aio_geo_fase_1_operacao.md`: instalação e significado dos estados de execução.

**Interfaces**

- `requestResource(url, options) -> Promise<{initial_status, status, final_url, redirects, headers, body, duration_ms}>`; `options` contém `method`, `timeoutMs`, `maxBytes`, `allowedHosts`, `maxRedirects`, `signal`.
- `parseSitemap(xml, sourceUrl) -> {kind: 'index'|'urlset', entries: Array<{loc,lastmod}>}`; erro explícito para XML inválido/raiz incompatível.
- `discoverSitemaps(indexUrl, options) -> Promise<{urls, sitemaps, errors, discovery_complete}>`; `urls` preserva todas as origens antes da deduplicação operacional.
- `main(argv) -> Promise<number>`; diagnósticos em stderr, CSV/artefatos sem mensagens misturadas.

- [ ] Escrever regressões dos casos da [evidência](/Users/Shared/Projects/RunnerHub/Business/_codex/analyses/seo_review_20260913/evidence.json), usando fixtures e servidor HTTP local ou fetch injetado. Exemplo de contrato do parser:

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseSitemap } from '../sitemap.mjs';
test('HTML com status 200 não é sitemap válido', () => {
  assert.throws(() => parseSitemap('<html>offline</html>', 'https://example.test/sitemap.xml'), /sitemap|XML/i);
});
test('namespace qualificado preserva URL de página', () => {
  const result = parseSitemap('<sm:urlset xmlns:sm="http://www.sitemaps.org/schemas/sitemap/0.9"><sm:url><sm:loc>https://example.test/a</sm:loc></sm:url></sm:urlset>', 'https://example.test/sitemap.xml');
  assert.equal(result.entries[0].loc, 'https://example.test/a');
});
```

- [ ] Executar os testes antes da correção e registrar as falhas esperadas, incluindo corpo atrasado e stream que não termina.
- [ ] Instalar parsers no pacote isolado e fixar versões exatas/lockfile no momento da implementação. `saxes` valida XML/namespace; não desenvolver outro parser por regex. Recusar DTD e não resolver entidades externas. `parse5`/`robots-parser` são usados na tarefa 2.
- [ ] Implementar deadline único até consumir/cancelar o corpo; fechar corpos descartados no fallback HEAD→GET e nos redirects. Fazer redirects manualmente, máximo 5, registrando cada etapa e validando host/protocolo antes da próxima solicitação.
- [ ] Aplicar limites por recurso: HTML 2 MiB, robots 512 KiB, XML descomprimido 50 MiB; excesso vira erro observável. Suportar gzip no sitemap sem contabilizar apenas bytes comprimidos. Recusar URL com credenciais, protocolo não HTTP(S), fragmento ou host não permitido. Não pedir o destino externo: registrar a ocorrência.
- [ ] Validar flags numericamente: negativos, `NaN`, valor ausente e flags desconhecidas devem falhar antes de qualquer rede. Preservar `--limit 0` como ilimitado somente na CLI legada; o runner da tarefa 3 sempre fornece orçamento explícito.
- [ ] Acrescentar limites independentes `--max-sitemaps`, `--max-discovered-urls`, `--max-run-ms`, `--max-rps`. `--limit` limita inspeções, sem esconder o custo de descoberta. Limite atingido deve registrar a cobertura truncada.
- [ ] Em índice com filho inválido, preservar observações já obtidas e marcar `partial`/exit 1. Um `urlset` vazio pode ser legítimo; zero URLs para a propriedade inteira gera alerta de cobertura e exige configuração explícita para ser aceito. Detectar duplicatas e ciclos sem loop.
- [ ] Executar `npm --prefix /Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo test` e `node --check /Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs`.

**Aceite:** nenhum XML inválido é reportado como rodada saudável; o deadline cobre corpo e redirects; hosts externos não são solicitados; falhas parciais permanecem auditáveis; o CSV legado mantém a ordem das dez colunas.

## Tarefa 2 — Acrescentar regras técnicas de SEO

**Arquivos RoadRunners**

- Criar `_codex/scripts/seo/html.mjs`, `robots.mjs`, `rules.mjs`.
- Criar `_codex/scripts/seo/test/html.test.mjs`, `robots.test.mjs`, `rules.test.mjs`.
- Alterar `_codex/scripts/seo/cli.mjs` para `--audit` e saída JSON de observações/achados.

**Interfaces**

- `parseHtml(html, finalUrl) -> {canonical_raw, canonical_url, canonical_count, robots_by_agent, title, h1_count}`.
- `evaluateRobots(text, robotsUrl, pageUrl, agent) -> {allowed: boolean|null, matched_rule: string|null}`.
- `classifyObservation(observation, policy) -> Array<{rule_id,severity,evidence}>`; `policy` inclui `expectedIndexable`, `requiredCanonical` e agentes avaliados.

- [ ] Criar testes para espaços em atributos, atributos sem aspas, comentários, entidades, canonical relativo, `<base>`, múltiplos canonicals, `rel="notcanonical"`, `googlebot`, múltiplas metas e headers com escopo.
- [ ] Implementar parsing com árvore HTML, sem usar o texto de comentários/scripts como tags. Tratar canonical no contexto apropriado e preservar conflitos, em vez de escolher silenciosamente o primeiro.
- [ ] Ler robots uma vez por host; analisar separadamente `Googlebot`, `OAI-SearchBot`, `PerplexityBot` e o próprio coletor. Usar `robots-parser`, com regressões próprias para grupo específico versus `*`, wildcard, `$`, regra mais longa e empate Allow/Disallow. Não herdar automaticamente regras `*` para grupo mais específico.
- [ ] Se o próprio coletor estiver bloqueado, registrar `skipped_robots` e não solicitar a página. Falha 5xx/timeout ao obter robots deixa política desconhecida e interrompe a coleta daquele host; 404 registra ausência do arquivo. Não contornar WAF ou fingir bot legítimo.
- [ ] Classificar usando a matriz abaixo e testar cada regra com observação sintética:

| Regra | Tratamento |
| --- | --- |
| Sitemap inválido/incompleto | Erro operacional; nunca saudável |
| Página do sitemap com 4xx/5xx, loop de redirect ou falha de transporte | Erro com status e URL |
| Página esperada como indexável com noindex/none efetivo | Erro, com agente e origem da diretiva |
| Bloqueio efetivo Googlebot em URL pública esperada | Erro de política; não remover a restrição automaticamente |
| Canonical diferente em URL do sitemap | Warning de inconsistência; promoção a erro somente por política específica |
| Canonical ausente | Warning quando a política exigir; não afirmar desindexação |
| Canonicals conflitantes ou destino inválido | Erro com valores observados |
| Redirect em URL do sitemap | Warning, cadeia/status disponíveis; o modo legado preserva exit 2 |
| Content type incompatível com página esperada | Erro; não tentar analisar PDF/binário como HTML |
| Título vazio, H1 ausente/múltiplo | Warning de revisão; não aplicar limite arbitrário de caracteres como erro |
| Indício de soft 404 | Revisão manual; jamais concluir apenas por texto curto/resultado ausente |

```js
// Caso obrigatório de classificação; executado dentro de node:test.
const findings = classifyObservation({
  source_url: 'https://example.test/a', status: 200,
  html_evaluation: 'evaluated', robots_by_agent: {googlebot: ['noindex']},
  canonical_url: 'https://example.test/a'
}, {expectedIndexable: true, requiredCanonical: true, agents: ['googlebot']});
assert.ok(findings.some(f => f.rule_id === 'indexing.noindex' && f.severity === 'error'));
```

- [ ] Testar HEAD como `html_evaluation: not_evaluated` e evitar alertas de canonical/title ausente nesse modo. Separar duração dos headers da duração total de GET.
- [ ] Executar a suíte do pacote, incluindo modo legado e `--audit`. No modo audit, exit 2 corresponde a erro SEO/página; warnings continuam visíveis no relatório sem se tornarem falha operacional.

**Aceite:** os metadados dos casos reproduzidos são lidos corretamente; a classificação tem evidência; nenhuma saída representa HEAD como auditoria HTML ou indexação Google.

## Tarefa 3 — Configurar os dois sites e gerar histórico privado

**Arquivos Business**

- Criar `_codex/analyses/seo_monitoramento/sites.json`: apenas URLs públicas e políticas.
- Criar `_codex/scripts/seo_run.mjs`: processo operacional que invoca a CLI por `SEO_INVENTORY_CLI`, caminho explicitamente configurado para a distribuição do coletor.
- Criar `_codex/scripts/seo_report.mjs`: validar manifestos, escrever resumo e comparar execuções.
- Criar `_codex/tests/seo_report.test.mjs` e `_codex/tests/seo_run.test.mjs`.
- Criar `_codex/docs/seo_monitoramento_operacao.md`: operação, contrato e manutenção.

**Interfaces**

- `runSite(site, options) -> Promise<{run_id, completion, exit_code}>`; spawn com argumentos em array, sem shell/interpolação de URL.
- `compareRuns(previous, current) -> {new, resolved, persistent, not_rechecked, comparable}`; chave de achado `site_id + source_url + rule_id`.
- `writeReport(run, root) -> Promise<{manifest_path, summary_path}>`; gravação temporária + rename atômico.

- [ ] Criar configurações separadas: RoadRunners `https://roadrunners.run/sitemap.xml`, host permitido `roadrunners.run`; OpenResults `https://openresults.run/sitemap.cfm`, host permitido `openresults.run`. Variantes de host só são acrescentadas com necessidade verificada; redirects entre os dois domínios são evidência, não autorização implícita de crawl cruzado.
- [ ] Definir padrões observados de tipos de página e uma lista pública de URLs estratégicas: home, evento futuro, evento com resultado, evento cancelado existente, notícia/vídeo RR. Selecionar URLs reais durante o piloto, preservando-as no manifesto; não inventar tags de eventos.
- [ ] Testar comparação por estado: erro persistente não duplica alerta, página corrigida vira resolvida apenas se reavaliada com sucesso, ausência na amostra vira `not_rechecked`, run parcial não resolve problemas anteriores.

```js
// Contrato mínimo da comparação, com achados já normalizados.
const before = {site_id:'roadrunners', completion:'complete', findings:[{
  site_id:'roadrunners', source_url:'https://roadrunners.run/a', rule_id:'http.error'
}]};
const after = {...before, completion:'partial', findings:[], observations:[]};
assert.equal(compareRuns(before, after).resolved.length, 0);
```

- [ ] Registrar proveniência da URL, versão/hash do coletor/configuração e se a URL veio de sitemap, lista estratégica ou ambos. Preservar duplicatas como diagnóstico sem fazer requisições duplicadas.
- [ ] Amostrar com seleção determinística por família/idioma, incluindo URLs estratégicas e rechecagens de achados prévios dentro do orçamento. Persistir `selected_urls`/hash da seleção; manter um conjunto fixo e permitir rodízio explicitamente identificado.
- [ ] Aplicar piloto por site: no máximo 100 páginas GET, concorrência 2, 1 req/s por host, 15 s por recurso, 10 min por rodada, 100 sitemaps e 100 mil URLs descobertas. Concluir as páginas da amostra previamente selecionada produz `complete/sample`, mesmo quando há mais páginas fora da seleção. Interromper a descoberta ou as páginas selecionadas por tempo, sitemaps, URLs descobertas ou bytes excedidos produz `partial` e exit 1. Não aumentar o orçamento automaticamente.
- [ ] Tratar 429 com `Retry-After`, dentro do orçamento global, no máximo duas tentativas. 429 ou 5xx consecutivos (três) pausam o host e encerram com estado parcial; não manter carga insistente.
- [ ] Escrever observações conforme concluem, finalizar manifesto atomicamente e atualizar `latest-complete` só depois dos hashes validados. Antes do primeiro uso real, verificar que a raiz é privada e não está versionada. Não guardar corpo HTML bruto por padrão.
- [ ] Executar `node --test /Users/Shared/Projects/RunnerHub/Business/_codex/tests/seo_report.test.mjs /Users/Shared/Projects/RunnerHub/Business/_codex/tests/seo_run.test.mjs`.

**Aceite:** cada site tem relatório independente; configuração e completude ficam claras; execução interrompida preserva evidência sem substituir baseline saudável; nenhuma dependência de runtime CFML no checkout RoadRunners.

## Tarefa 4 — Validar em amostra real e produzir fila de correções

**Arquivos de documentação**

- Atualizar Business `_codex/docs/seo_monitoramento_operacao.md` e gerar relatório privado por site.
- Atualizar RoadRunners `_codex/docs/aio_geo_fase_1_operacao.md` e o estado atual no plano AIO/GEO, preservando o diagnóstico histórico.
- Atualizar OpenResults `_codex/docs/eventos-antes-dos-resultados.md` somente com novos fatos observados.

- [ ] Conferir HEAD/hash dos três projetos, disponibilidade do executor Node e instalação do coletor; não presumir ambiente do servidor pela máquina local.
- [ ] Ler apenas índices/robots públicos inicialmente, registrar origem/CDN/horário e validar XML. Não reutilizar as contagens históricas como números atuais.
- [ ] Executar o piloto limitado da tarefa 3 primeiro no RoadRunners e depois no OpenResults; revisar carga, erros e completude entre os sites. Nunca executar o `--deep` ilimitado do manual antigo como primeiro passo.
- [ ] Conferir manualmente cinco achados ou URLs representativas por site no HTML recebido/renderizado, incluindo página legítima de evento futuro e diferenças entre HEAD e GET.
- [ ] Criar fila com `{site, url, regra, evidencia, impacto, arquivo_candidato, dono, criterio_de_aceite}`. Candidatos concretos: RR `sitemaps/index.cfm`, `.htaccess`, `robots.txt`, `includes/estrutura/head.cfm`, `evento/index.cfm`, `noticias/index.cfm`, `videos/index.cfm`; OpenResults `sitemap.cfm`, `robots.txt`, `includes/head.cfm`, `evento/index.cfm`, `includes/backend_evento.cfm`.
- [ ] Validar especialmente a política por agente em robots OpenResults, lastmod e idiomas RR, cache CDN e variantes canônicas. Não alterar política de treinamento de IA, identidade de domínio ou regras de negócio como consequência automática da auditoria.
- [ ] Para correções de runtime autorizadas, preparar um lote pequeno por proprietário; testar fixtures/rotas afetadas, conferir produção, gerar backup, publicar apenas o lote e repetir a observação real depois. O cron e o relatório não corrigem produção automaticamente.

**Aceite:** baseline dos dois sites com amostra/cobertura explícita e fila acionável. Nenhuma contagem de URLs indexadas inferida a partir do sitemap; nenhuma publicação declarada por teste local.

## Tarefa 5 — Operar relatório semanal e alertas

**Arquivos Business**

- Atualizar `_codex/scripts/seo_run.mjs`, `_codex/scripts/seo_report.mjs` e `_codex/docs/seo_monitoramento_operacao.md`.
- Ampliar `_codex/tests/seo_run.test.mjs` com lock, cancelamento e repetição.

- [ ] Fazer duas execuções manuais completas do escopo planejado e conferir a comparação antes de criar agenda.
- [ ] Adicionar lock por site, orçamento total e liberação em cancelamento; segunda execução concorrente deve retornar “já em execução”, não iniciar outro crawl. Interrupção marca parcial e conserva os arquivos válidos.
- [ ] Estabelecer coleta semanal inicial de até 500 URLs GET por site, com conjunto fixo, rechecagem dos achados e rodízio. Usar os mesmos limites de carga; aumentar tempo máximo para 30 min explicitamente. Relatório informa que a amostra não cobre todo o acervo.
- [ ] Relatar erros novos, erros resolvidos, falha de execução e queda inesperada de cobertura. Não notificar cada URL descoberta nem repetir achados inalterados. Queda acima de 20% dispara revisão da descoberta; não prova remoção de conteúdo.
- [ ] Configurar agenda somente quando o usuário solicitar execução recorrente. Na opção local Codex, usar a ferramenta de automação do app, testar a primeira rodada e documentar dependência de máquina/app ativos. Não criar cron de shell como substituto silencioso.
- [ ] Se operação precisar funcionar sem a máquina local, levantar host Node operacional antes de escolher executor permanente. Não instalar Node/reconfigurar servidor web por suposição. O cron HTTP Business pode integrar futuramente um executor por contrato curto de disparo/status; não executar um crawl dentro do endpoint.
- [ ] Retenção inicial proposta: 90 dias de observações e resumos mensais por 12 meses. Qualquer descarte precisa ser configurado explicitamente; o primeiro ciclo apenas escreve arquivos e mede volume.

**Aceite:** rodada repetida é previsível, não se sobrepõe e comunica mudanças relevantes. Executor indisponível aparece como falha de monitoramento, nunca como site saudável.

## Tarefa 6 — Integrar Search Console e audiência sem misturar métricas

**Arquivos Business**

- Criar `_codex/scripts/seo_import_gsc.mjs`, `_codex/scripts/seo_import_ga4.mjs` e respectivos `_codex/tests/seo_import_gsc.test.mjs`, `seo_import_ga4.test.mjs`.
- Criar fixtures sintéticas de exportação em `_codex/tests/fixtures/seo/`.
- Atualizar `_codex/scripts/seo_report.mjs` e `_codex/docs/seo_monitoramento_operacao.md`.

**Interfaces**

- `normalizeGscExport({property, sourceFile, exportedAt, aggregation, rows}) -> {manifest, rows}`; linhas têm período, dimensões, clicks, impressions, ctr e position.
- `normalizeGa4Export({property, stream, sourceFile, exportedAt, timezone, rows}) -> {manifest, rows}`; guardar nome/definição de cada métrica e evento.

- [ ] Confirmar acesso e propriedade de cada domínio. Suportar estado `not_connected`; não inferir configuração pela presença de `gtag`. No GSC, conferir sitemap cadastrado e dados disponíveis antes de enviar qualquer coisa novamente.
- [ ] Começar por exportações reais autorizadas, lendo o cabeçalho/schema efetivo. Fixture sintética cobre arquivo vazio, datas inválidas, propriedade errada, duplicatas e valor indisponível. Guardar origem, hash e data de exportação.
- [ ] Separar agregados por propriedade, página e consulta. Não somar CTR nem posição média: CTR agregado é clicks/impressions; posição precisa de ponderação/documentação compatível. Preservar totais oficiais separadamente, pois tabelas de consultas não necessariamente reconciliam integralmente por anonimização/limites.
- [ ] Comparar janelas equivalentes de 28 dias com dias completos, informar timezone e atraso. Usar histórico anterior se houver acesso; não esperar 28 dias para corrigir erro técnico nem prometer ganho em 28 dias.
- [ ] Importar GA4 só após validar propriedade/fluxo e cobertura de coleta. Sessões GA4, cliques GSC e audiência própria permanecem nomeados por fonte; integração RR→OpenResults requer validação de links, UTMs e eventos antes de atribuir conversão.
- [ ] Depois de validar exports, implementar APIs em entrega própria usando autenticação somente leitura já autorizada. Search Analytics exige paginação e tem cobertura limitada; URL Inspection deve usar amostra/quota e registrar data da versão indexada. Não prometer inspeção live nem exportação de todas as consultas.
- [ ] Testar normalização e cálculos com números conhecidos. Exemplo: grupos com 10 clicks/100 impressions e 10/900 devem resultar em CTR agregado de 2%, não média simples de 5,56%.
- [ ] Reconciliar uma janela por site com a interface/export oficial e apresentar divergências de definição/cobertura antes de publicar o relatório interno.

**Aceite:** dados privados disponíveis aparecem com origem/período/limitações; ausência não vira zero; consulta de desempenho não é tratada como censo de indexação; não há seção “tráfego IA Google” isolada sem fonte que a sustente.

## Evoluções deliberadamente separadas

Um painel administrativo poderá consumir esses artefatos em `Business/portal/seo/index.cfm`, `home.cfm` e `portal/includes/seo_backend.cfm`, reaproveitando login e `require_admin.cfm` do Portal. Antes disso, exige plano de interface, guarda de arquivos fora do docroot, manifesto/hash, testes de acesso e verificação desktop/mobile. Não criar SPA, schema PostgreSQL ou endpoints de crawl nesta entrega.

Core Web Vitals, schemas de eventos/notícias/vídeos, logs de crawlers, benchmarks de citações IA e pesquisa de concorrentes são frentes próprias. Semrush pode complementar dados externos mais tarde. A confiabilidade desta auditoria não depende de contratar uma plataforma nem de instalar o plugin.

## Checklist de conclusão do primeiro ciclo

- [ ] Casos reproduzidos deixam de produzir falsos sucessos e estão cobertos por regressões.
- [ ] CLI mantém compatibilidade explícita, orçamento e artefatos verificáveis.
- [ ] RoadRunners e OpenResults possuem piloto datado e comparação possível.
- [ ] Relatório separa fatos técnicos, indexação, desempenho e audiência.
- [ ] Documentação histórica e estado atual estão identificados.
- [ ] Mudanças públicas, se autorizadas, têm backup e conferência real; não há alterações alheias no lote.
- [ ] Nenhum commit/branch/push/PR criado sem solicitação.

## Referências de implementação

- [parse5 — parser HTML](https://github.com/inikulin/parse5).
- [saxes — parser XML](https://github.com/lddubeau/saxes).
- [robots-parser — interface e regras suportadas](https://www.npmjs.com/package/robots-parser).
- [Google robots.txt](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec).
- [Google robots meta](https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag).
- [Google Search Analytics](https://developers.google.com/webmaster-tools/v1/searchanalytics/query).
- [Google URL Inspection](https://developers.google.com/webmaster-tools/v1/urlInspection.index/inspect).
- [Google Analytics Data API](https://developers.google.com/analytics/devguides/reporting/data/v1).
- [Tarefas agendadas no app](https://learn.chatgpt.com/docs/automations?surface=app).

## Entrega da revisão original

Documento produzido a partir de leitura estática, revisão Astra e 12 cenários locais do script original. Na entrega original, os comandos e arquivos novos eram instruções para implementação futura. O estado da execução autorizada está registrado em `_codex/docs/2026-09-13_seo_cycle1_progress.md`; as caixas abaixo permanecem como especificação e não substituem esse registro. Nenhum runtime dos sites foi alterado e nenhuma publicação foi realizada.


## Execução posterior — recuperação do inventário em 13/09/2026

Após autorização “prossiga”, foram publicadas a correção de geração/encoding do sitemap RoadRunners e a revisão da tela Business. Descoberta completa de 99.360 URLs, cadastro de 33.095 eventos reconciliado em PT/EN/ES, 100 páginas auditadas. RR-02 concluído; RR-01 segue para rotas/canonicals especiais. Fila: 6 pendentes, 1 concluída. Recibos, testes, resultados e limites em `_codex/docs/2026-09-13_seo_descoberta_execucao.md`. Agenda recorrente, integrações e demais correções não fazem parte desta entrega.


## Execução posterior — canonicals e destinos privados em 14/09/2026

O usuário autorizou prosseguir com o plano após informar que já havia solicitado a tradução das descrições no cron em outra frente. Este lote trata três correções independentes dessa implementação:

- **RR-03:** sincronizar a tag limpa do detalhe da notícia com os parâmetros usados pelo canonical e pelos alternates. Publicado e verificado em 12 notícias, incluindo variantes PT/EN/ES, com e sem barra e com campanha.
- **RR-04:** retirar exclusivamente três rotas de desafios que redirecionam para login do sitemap estático; 52 → 49 URLs, autenticação preservada.
- **OR-01:** codificar a tag bruta como segmento do canonical e escapar seus atributos HTML; evento com %3F e dois eventos de controle conferidos.

Não houve nova auditoria completa do inventário neste lote. O Business conserva as datas e métricas das auditorias anteriores e registra a conferência posterior nos itens concluídos. Ver o recibo no registro deste lote para o estado final da publicação da fila.

Permanecem **RR-01** (rotas e canonicals de tags especiais), **SH-01** (hierarquia de títulos) e **OR-02** (intenção da política por agente no robots). A integração da tradução deve ser validada com sua própria frente: geração/salvamento das versões, exibição por idioma e processamento dos eventos antigos que já possuem descrição portuguesa. Não criar uma segunda rotina de tradução nem consolidar todos os idiomas em português sem essa avaliação.

Nenhum commit, branch, tag, push ou PR foi solicitado ou realizado.
