# Operação da auditoria SEO — ciclo 1

Implementação: 13/09/2026. Escopo: coletor, regras, relatórios privados, piloto nos dois sites e painel administrativo com revisão curada. Agenda recorrente e integrações de contas Google continuam etapas posteriores.

Às 21:26 de 13/09 (Brasília), o RoadRunners obteve sua primeira descoberta completa: 99.360 URLs, 100 páginas analisadas, 0 falhas operacionais, 1 erro de página e 111 avisos. O cadastro de 33.095 eventos ativos foi reconciliado nos três idiomas. Ver [recuperação do inventário](2026-09-13_seo_descoberta_execucao.md). A tela distingue URLs coletadas e páginas analisadas; uma rodada completa pode conter erros.

## Componentes

- RoadRunners: `_codex/scripts/seo_inventory.mjs` mantém a CLI; `_codex/scripts/seo/` contém o pacote Node isolado, parsers e testes. Requer Node.js >=22; dependências exatas no lockfile. Não publicar esse diretório no docroot.
- Business: `_codex/scripts/seo_run.mjs` executa uma rodada por site, aplica orçamento e lock; `seo_report.mjs` escreve/verifica artefatos e compara com a última rodada completa.
- Configuração pública: `_codex/analyses/seo_monitoramento/sites.json`. Domínios separados e URLs estratégicas reais selecionadas das homes em 13/09. O runner não depende de consultas ao banco nem importa runtime CFML de outro projeto.
- Relatórios privados instalados para este ambiente: `/Users/Shared/RunnerHubReports/seo`. Diretórios 0700, arquivos 0600, fora do workspace Git e do docroot. Não copiar exports privados ou observações para o repositório.

## Executar manualmente

No diretório Business, com Node disponível:

```sh
SEO_INVENTORY_CLI=/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs SEO_REPORT_ROOT=/Users/Shared/RunnerHubReports/seo node _codex/scripts/seo_run.mjs roadrunners
SEO_INVENTORY_CLI=/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs SEO_REPORT_ROOT=/Users/Shared/RunnerHubReports/seo node _codex/scripts/seo_run.mjs openresults
```

Esses caminhos são configuração do executor local, não dependências do runtime web. Em outro host, instalar a distribuição do coletor e definir as duas variáveis para caminhos próprios. Não presumir Node no servidor web. O cron HTTP existente no Business não executa `.mjs` diretamente.

Cada comando faz uma rodada; **nenhuma agenda é criada**. Executar os sites sequencialmente. O piloto usa no máximo 100 páginas, concorrência 2 e 1 request/s, incluindo cada hop de redirect. Recurso: deadline de 15 s incluindo corpo; rodada: até 10 min; descoberta: até 100 sitemaps e 100 mil URLs. Sitemaps/robots são solicitações adicionais contabilizadas no orçamento temporal e de taxa. Limites alcançados não são ampliados automaticamente.

O próprio coletor respeita robots, inclusive em redirects, sem sessão/cookies e sem simular crawler autenticado. Host e porta precisam corresponder à origem permitida. Três respostas consecutivas 429/5xx interrompem o host; 429 tem até duas novas tentativas respeitando Retry-After dentro do orçamento.

## Ler o resultado

O comando imprime `run_id`, estado, exit code e caminhos. Em `<raiz>/<site>/<run_id>/`:

- `manifest.json`: versões/hashes, horários, limites, cobertura, modo e integridade dos arquivos.
- `observations.jsonl`: evidência por URL e sitemap de origem; sem guardar HTML completo por padrão.
- `inventory.csv`: dez colunas legadas na mesma ordem; texto protegido contra fórmulas de planilha.
- `findings.json`: achados atuais com regra, gravidade e evidência.
- `comparison.json`: novos, persistentes, resolvidos e não rechecados. Pendências sobrevivem a amostras rotativas compatíveis.
- `summary.md`: relatório legível em português.

`counts.errors` conta erros SEO/página; a lista `errors` contém falhas operacionais, como XML inválido ou timeout na descoberta. Zero erros SEO pode coexistir com uma rodada parcial por falha operacional.

`latest-complete.json` aponta somente para uma rodada completa com manifesto verificado. Completa significa que o escopo planejado terminou; pode haver erros SEO (`exit 2`). Não significa site saudável ou auditado integralmente. Uma rodada parcial conserva os dados anteriores; recuperar prefixo JSONL válido permite registrar evidência após interrupção.

| Estado/código | Interpretação |
| --- | --- |
| `complete/sample`, exit 0 | Amostra planejada concluída, sem erros da modalidade; warnings podem existir |
| `complete`, exit 2 | Coleta concluída e problemas encontrados |
| `partial` ou `failed`, exit 1 | Falha operacional ou orçamento/cobertura incompleta; não resolver pendências antigas |
| `already_running`, exit 1 | Lock existente; uma segunda coleta não foi iniciada |

HTTP 200, sitemap e canonical declarado não comprovam indexação. `--deep` captura HTML no contrato legado; `--audit` implica GET e aplica as regras. HEAD não avalia metadados HTML. Respostas sem Content-Type ou sem conteúdo ficam explícitas; latência de request não é Core Web Vitals.

## Amostragem e comparação

O conjunto inclui URLs estratégicas, pendências da última rodada completa e seleção determinística por família de rota/idioma. A lista e seu hash ficam no manifesto. O piloto mantém o conjunto de base; não há rodízio periódico ativado. O comparador aceita conjuntos diferentes quando a política continua compatível, mas nunca resolve achados de URLs ausentes ou sem rechecagem válida.

Mudanças de site, modo, schema, versão de regras ou hash de configuração tornam os snapshots incompatíveis. O relatório explica a diferença. Não somar resultados de amostras como se fossem cobertura integral. A descoberta por sitemap não detecta todo conteúdo que falta no próprio sitemap.

## Incidentes e recuperação

- `SIGINT`/`SIGTERM` pedem cancelamento controlado; dados concluídos são preservados. Se o processo for morto antes do JSON final, o runner recupera linhas JSONL completas e registra cauda truncada.
- Se houver crash do executor, verificar o PID em `<raiz>/.locks/<site>.lock` e se ainda existe uma coleta antes de remover o lock abandonado. O lock de gravação `<raiz>/<site>/.report-write.lock` também exige inspeção; não há tomada automática de lock.
- Se algum hash divergir, não utilizar o relatório como baseline. Preservar o arquivo para diagnóstico e gerar nova rodada válida. Hash detecta corrupção; a autenticidade depende do diretório privado.
- Reinstalação do pacote: `npm ci --ignore-scripts --no-audit` em `RoadRunners/_codex/scripts/seo`. Não restaurar o workspace inteiro nem alterar código público para resolver problema do executor.
- Não há rotina de descarte instalada. Retenção deve ser configurada explicitamente após medir o volume; este ciclo apenas grava relatórios.

## Testes

```sh
node --test _codex/tests/seo_report.test.mjs _codex/tests/seo_run.test.mjs
npm --prefix /Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo test
```

As fixtures do coletor usam servidor HTTP apenas em loopback; sandboxes que bloqueiam listen exigem autorização específica para executar os testes. Os testes não acessam os sites de produção.

## Piloto de 13/09/2026

- RoadRunners: 100 páginas inspecionadas; descoberta parcial com 1.090 URLs aceitas, um lote com URLs inválidas e dois timeouts de 15 segundos. Sem baseline completa para comparação.
- OpenResults: 33.096 URLs descobertas, amostra completa de 100 páginas, zero erros operacionais/SEO e dois warnings. É uma baseline técnica da amostra, não aprovação do acervo inteiro.
- Critérios e fila de correções: `2026-09-13_seo_piloto_fila.md`. A primeira comparação longitudinal real ainda não foi realizada.

## Próxima etapa

Usar os relatórios do piloto para uma fila com URL, evidência, regra, impacto, projeto responsável e critério de aceite. Correções de conteúdo e runtime público precisam ser verificadas na origem e publicadas em lotes restritos conforme as instruções de cada projeto. O coletor e a futura agenda não corrigem produção automaticamente.

Search Console e GA4 entram por fontes autorizadas, primeiro com exportações validadas. Acesso ausente é “não conectado”, não zero. Manter cliques/impressões GSC, sessões GA4 e audiência própria com suas definições. Não há conexão dessas contas nesta entrega.


## Consulta no Business

Desde 13/09/2026, a fila revisada está disponível em `/portal/conteudo/?visao=seo`, ligada a Conteúdo das provas e restrita a administradores. É uma apresentação datada de sete frentes, com filtros e critérios de conclusão. Não sincroniza os relatórios automaticamente nem dispara coleta. Ver `2026-09-13_seo_fila_publicacao.md` para arquivos, validação e atualização do snapshot. O painel com ingestão de auditorias e integrações Google permanece uma evolução posterior.

## Relatório visual e nota interna (14/09/2026)

A tela `/portal/conteudo/?visao=seo` apresenta os critérios aprovados, avisos, erros e verificações não medidas, além da fila de correções. A nota interna usa dez critérios com pesos fixos e o pior resultado de cada critério. O contrato completo está em `2026-09-14_seo_relatorio_pontuacao.md`.

Depois de concluir novas rodadas válidas dos dois sites, gere o snapshot do relatório, a partir do repositório Business:

```sh
node _codex/scripts/seo_scorecard.mjs \
  --reports-root /Users/Shared/RunnerHubReports/seo \
  --history-root /Users/Shared/RunnerHubReports/seo/score-history \
  --output /Users/Shared/Projects/RunnerHub/Business/portal/includes/seo_score_data.cfm
```

O gerador valida os relatórios e seus ponteiros de integridade antes de produzir dados. O histórico privado é idempotente por execução/método e precisa ser preservado entre rodadas. Não mover esse diretório para o docroot. A nota inicial usa a auditoria de 13/09; verificações direcionadas de correções não reescrevem a nota anterior. Diferenças de amostra, método, coletor ou cobertura interrompem a comparação numérica de progresso.

Revisar o snapshot gerado e publicar somente `portal/includes/seo_score_data.cfm` pelo procedimento de baseline, backup, compilação e verificação real. A página não inicia coleta ao recarregar. Gerar o arquivo local não atualiza a produção, e esta entrega não instala agendamento automático.

Validação dos cálculos e preservação do contrato operacional:

```sh
node --test _codex/tests/seo_scorecard.test.mjs _codex/tests/seo_report.test.mjs _codex/tests/seo_run.test.mjs
node _codex/scripts/test_seo_queue_cfml_local.mjs --list
node _codex/scripts/test_seo_queue_cfml_local.mjs score-contract render-score-filtered
```

O runner CFML também aceita um nome de cenário por execução para evitar que suspensão do host interrompa uma bateria longa. Isso não substitui a compilação Adobe nem a conferência autenticada do resultado publicado.

### Endereço próprio de SEO

Desde14/09/2026, acessar `/portal/seo/` pelo menu **Marketing e audiência → SEO**. Conteúdo das provas permanece em `/portal/conteudo/`, em **Conteúdo e portal**. O endereço anterior com `?visao=seo` redireciona preservando os filtros permitidos. Detalhes e recuperação em `2026-09-14_seo_navegacao.md`.
