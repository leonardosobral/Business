# Indexação e duplicações prioritárias — 05/10/2026

## Entrega publicada

RoadRunners: `circuito/index.cfm`, `desafiosupra/2024/index.cfm` e `desafiosupra/2025/index.cfm`.
Business: `portal/includes/seo_queue_data.cfm`, `portal/includes/seo_semrush_data.cfm` e `portal/conteudo/seo_semrush.cfm`.

As rotas FCA `fca-corridaderua` e `circuito-catarinense-corrida-de-rua` resolvem o mesmo agregador legado 82 e os mesmos seis eventos. Foi mantido como destino o segundo endereço, já usado nos links do cabeçalho. O alias em GET/HEAD sem parâmetros funcionais redireciona em 301; ambas as rotas declaram o mesmo canonical. Filtros, ações, tracking, POST e formulário conservam o fluxo. A consolidação exige uma única correspondência no banco e tag segura; correspondência ambígua ou tag inválida não recebe destino inferido.

Os rankings Supra 2024 e 2025 receberam títulos e descrições com seus anos e os nomes já presentes no conteúdo. Consultas, resultados e canonical anual foram preservados.

O Business registra a entrega em RR-29, mantendo RR-20 e RR-24 parciais. Os rótulos Semrush foram corrigidos para páginas afetadas, pois as 62 linhas de títulos, oito de conteúdo e quatro de descrições não são conjuntos distintos de duplicação. Os valores, notas e data da auditoria 5.000, e o snapshot orgânico, permanecem históricos.

## Diagnóstico e controles

A primeira verificação pública encontrou o canonical correto, mas HTTP 200 no alias FCA. Os includes de produção acrescentavam nove parâmetros URL em `variaveis.cfm` e dois em `backend_feed.cfm`; o guard após os includes os tratava como parâmetros recebidos. O teste foi ampliado com os defaults reais e reproduziu quatro falhas. O complemento avalia a requisição antes desses includes e decide o 301 após a consulta. Valores explicitamente enviados que coincidem com defaults continuam protegidos.

- 15 cenários e 36 verificações Adobe ColdFusion aprovados no candidato final, incluindo HEAD, POST, formulário, ambiguidade, tag insegura e filtros com valores padrão.
- 19 cenários do painel aprovados antes/depois da publicação, com oito controles de acesso e escaping.
- Seis testes do gerador de snapshot passaram; payload preservado exceto os três rótulos.
- Compilação Adobe dos templates de runtime antes de publicar; baselines e backups recuperáveis; revisão independente do lote e complemento sem impedimentos.
- 17 URLs públicas conferidas: 301 no alias, 200 nos demais casos, cadeia com um único salto, HEAD 301 e filtros preservados. Canonical, alternates, robots e conteúdo principal das páginas de controle preservados.
- Verificação de hashes do complemento: um template RoadRunners e 14 dependências; painel: três arquivos e nove dependências. A publicação inicial verificou três templates e 11 dependências.

Checagem pública final: 2026-10-05T17:32:12.734217+00:00. Saúde nessa amostra: Apache com aproximadamente 16h46 de uptime, seis workers ocupados e 69 livres. Isso não comprova resolução permanente da saturação.

## Dados preservados e limites

Não houve escrita no banco, alteração de datas, resultados, autenticação, configurações Cloudflare ou operação Git.

As duas corridas Farmelhor são eventos distintos: Nova Cruz em 28/11/2026 e Canguaretama em 18/10/2026. Não foram unidas. O sitemap histórico devolveu XML válido com 5.223 URLs; Trail in Motion respondeu 200 em aproximadamente 0,32s na conferência final. Nenhum desses fatos comprova indexação Google ou estabilidade contínua.

O snapshot Semrush mais recente consultado continua `6ac31bf647d73ceec1b0b861`. Nenhuma nova auditoria foi iniciada. A sessão Chrome estava em uso e mudou de janela durante uma tentativa de consulta; não foi feita inspeção autenticada atual no Google, solicitação de indexação ou medição nova de posições. Efeito em indexação/ranking permanece pendente de rastreamento e dados Search Console.

## Próximas frentes

1. Manter acesso/estabilidade sob acompanhamento e investigar retenção apenas com evidência operacional (RR-24).
2. Revisar demais URLs afetadas por duplicação individualmente, preservando eventos legítimos (RR-20).
3. Confirmar com uma auditoria comparável e dados Search Console o que permanece e quais páginas têm oportunidades de posições/CTR; conteúdo e links internos devem seguir essa priorização, sem prometer primeira página.

## Recuperação

Backups no servidor:

- `/var/backups/seo-indexacao-prioridades-20261005-rr/baseline` — três templates originais.
- `/var/backups/seo-indexacao-prioridades-followup-20261005-rr/baseline` — circuito antes do complemento.
- `/var/backups/seo-indexacao-prioridades-followup-20261005-business/baseline` — três arquivos do painel antes da entrega.

Scripts e recibos estão em Business `_codex/staging/seo-indexacao-prioridades-20261005/`. Se necessária reversão total, reverter primeiro o painel com `release_followup.py business rollback`, depois o complemento RoadRunners com `release_followup.py rr rollback`, e só então o lote inicial com `release.py rr rollback`. Os scripts conferem o baseline e rejeitam drift; não executar reversão sobre alterações posteriores sem conciliá-las. O preparo inicial Business não chegou a ser publicado.
