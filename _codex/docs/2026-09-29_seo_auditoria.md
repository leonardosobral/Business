# Auditoria SEO de 29/09/2026

| Site | Inventário | Páginas analisadas | Erros de página | Avisos | Nota |
| --- | ---: | ---: | ---: | ---: | ---: |
| Road Runners | 102.491 | 100 | 2 | 100 | 70,0 |
| Open Results | 34.144 | 100 | 0 | 1 | 95,0 |

Ambas as rodadas finais concluíram a descoberta e a amostra sem falhas operacionais. Road Runners terminou às 10:16 e Open Results às 10:14, horário de Brasília. Não se trata de análise de todas as URLs nem de comprovação de indexação.

Execuções privadas em `/Users/Shared/RunnerHubReports/seo`:

- Road Runners: `2026-09-29T13-16-46-527Z-1e2c970f`.
- Open Results: `2026-09-29T13-14-14-874Z-558ade87`.
- Primeira tentativa Road Runners, preservada como parcial: `2026-09-29T13-12-03-753Z-a4cba049`. A descoberta atingiu 100 mil URLs. O teto do runner foi ajustado manualmente para 150 mil; análise, taxa, concorrência e prazo permaneceram iguais.

O histórico tem dois pontos por site, com comparação numérica desativada devido a diferenças de configuração/amostra/cobertura. Os achados da comparação automática marcados como novos não devem ser interpretados como novos defeitos quando a configuração é incompatível. A fila foi revisada usando evidência por URL.

## Fila e publicação

Incluído RR-05: notícia antiga retornando HTTP 404 em ambas as tentativas, selecionada pela rechecagem histórica e ausente do inventário atual. O caso exige avaliar intenção de remoção antes de corrigir. Operário Night Run mantém HTTP 403 e outro evento mantém canonical truncado por aspas. A política Googlebot do Open Results continua pendente de decisão; robots.txt foi reconferido. Correções de canonical de notícias, Atleta de Cristo e exclusão dos desafios privados do sitemap mantiveram evidências favoráveis. A fila contém oito frentes: quatro pendentes e quatro concluídas.

Publicados somente `portal/includes/seo_score_data.cfm` e `portal/includes/seo_queue_data.cfm`. O ajuste em `_codex/scripts/seo_run.mjs` pertence ao executor local e não é runtime web. Backup recuperável em `/var/backups/seo-audit-Business-dgkpigll`; recibo em `2026-09-29_seo_auditoria_publicacao.json`. Histórico anterior preservado no diretório privado `audit-20260929`.

Validação: 37 testes Node aprovados após o ajuste; dados gerados confrontados com os relatórios completos; dois includes compilados no Adobe ColdFusion; hashes e metadados publicados conferidos; onze arquivos relacionados preservados; navegador autenticado confirmou notas, datas, inventários, histórico e RR-05. `git diff --check` aprovado. O runtime Lucee temporário está indisponível, então a suíte local CFML não foi executada; compilação Adobe e renderização real foram conferidas. Não houve mudança de layout, autenticação ou sites públicos.
