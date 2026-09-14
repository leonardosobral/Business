# Execução — ciclo 1 do plano SEO

Autorização: usuário pediu iniciar em 13/09/2026; escopo executado: ferramenta e piloto das tarefas 1–4. Agenda, painel, integrações Google e correções públicas identificadas pelo piloto continuam entregas posteriores.

Plano: `docs/superpowers/plans/2026-09-13-seo-auditoria-acompanhamento.md`. Operação: `seo_monitoramento_operacao.md`. Resultado e fila: `2026-09-13_seo_piloto_fila.md`.

## Entrega por projeto

| Projeto | Alteração | Estado |
| --- | --- | --- |
| RoadRunners | Wrapper `seo_inventory.mjs`; pacote isolado `seo/` com CLI, HTTP, sitemap, HTML, robots, regras, lockfile e testes; dois documentos AIO/GEO atualizados | Instalado no checkout e validado, Node >=22; 80 testes passam |
| Business | Runner, geração/verificação/comparação de relatórios, configuração dos sites, testes e documentação operacional | 23 testes passam; relatórios privados fora dos três repositórios |
| OpenResults | Atualização factual de `_codex/docs/eventos-antes-dos-resultados.md` | Coletor público reutilizado por contrato; nenhum runtime alterado |

## Validação

- Coletor: 80 testes com fixtures HTTP de loopback, parsers reais e casos de falha. Suíte passou no staging e na instalação final com dependências do lockfile.
- Business: 18 testes de relatório e 5 de runner; última execução conjunta: `node --test --test-reporter=dot _codex/tests/seo_report.test.mjs _codex/tests/seo_run.test.mjs`, exit 0.
- Revisão independente Astra e reproduções próprias corrigiram três casos adicionais: robots em cada redirect, resposta sem MIME/sem conteúdo e recuperação de JSONL interrompido. Regressões passaram e a revisão posterior aprovou.
- Dois pilotos reais sequenciais: 100 páginas por site, concorrência 2, 1 req/s, 15 s por recurso, até 10 min por rodada. Sem ampliação automática de orçamento.
- Conferência adicional de seis URLs por site com HEAD e GET, incluindo evento futuro de Salvador em ambos; um GET extra do sitemap futuro RR identificou as nove URLs inválidas.
- Integridade real validada por `readReport`; arquivos privados 0600 e diretórios 0700. Sem ponteiro de rodada completa para RR; ponteiro OR validado.
- Apresentação do relatório ajustada após o piloto: falhas operacionais aparecem antes dos avisos e separadas de erros SEO/página. Relatórios já gravados permanecem imutáveis.

## Estado das etapas

1. Transporte e descoberta confiáveis: implementados; falhas são registradas como parciais, sem falso sucesso.
2. Regras técnicas HTML/robots/canonical: implementadas e testadas, preservando modo legado e as dez colunas CSV.
3. Configuração, runner e histórico privado: implementados. A comparação foi validada por fixtures; a primeira comparação longitudinal real ainda não ocorreu.
4. Piloto e fila: executados. RR: 1.090 URLs aceitas na descoberta parcial, 100 páginas, 3 falhas operacionais e 111 avisos. OR: 33.096 URLs, 100 páginas, coleta completa, 2 avisos. A baseline completa RR depende de corrigir os sitemaps.
5. Agenda semanal/alertas: não ativados. Locks e cancelamento foram antecipados para proteger o piloto.
6. Search Console/GA4: não conectados. Dados ausentes não foram tratados como zero.

A seleção inicial não incluiu um evento cancelado confirmado. Salvador foi acrescentado às URLs estratégicas OR após a validação manual de página futura; isso altera o hash de configuração. A próxima rodada OR inicia baseline compatível com essa configuração, preservando o relatório inicial. Não há rodízio periódico nem descarte automático de relatórios.

## Preservação e instalação

Baseline Git inicial: RR `17cc7ab5`; OpenResults `e769528`; Business `1423c5b`, com documentos da revisão e caches Python preexistentes preservados.

O coletor foi preparado em `/private/tmp/runnerhub-seo-cycle1` e instalado com conferência de hashes dos 17 arquivos e do script original (`8aae6497f5de87a7c9e621b795dd62540d1788d4f80d4b5ad6d0da6900425403`). Dependências instaladas por `npm ci --ignore-scripts --no-audit`. Documentos externos tiveram o hash anterior conferido antes da cópia.

Raiz dos relatórios: `/Users/Shared/RunnerHubReports/seo`; extratos adicionais em `pilot-review-20260913`. Nenhum HTML bruto foi guardado nos artefatos duráveis. Nenhum arquivo público CFML, robots ou sitemap foi alterado. Não há lote de runtime web a publicar; `_codex`, pacotes Node e relatórios permanecem fora da publicação do docroot. Nenhum commit, branch, tag, push ou PR foi criado.
