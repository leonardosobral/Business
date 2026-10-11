# Assessorias antigas e revisão da amostra Semrush — 06/10/2026

## RoadRunners publicado

Arquivo: `.htaccess`. Foram acrescentadas quatro linhas após a normalização de host e antes das rotas de idiomas, preservando o restante do arquivo de produção.

Cinco endereços usados por links antigos continuam acessíveis por redirecionamento 301 para suas páginas existentes em `/timer/`:

| Tag | Cadastro confirmado |
|---|---|
| branca-esportes-saude-e-lazer | 315 — Branca Esportes Saúde e Lazer |
| corpo-e-saude | 97 — Corpo e Saude |
| geracao-saude | 137 — Assessoria Esportiva Geração Saúde |
| grupo-de-corrida-espaco-saude | 238 — Grupo de Corrida Espaço Saúde |
| zero-meia-um-saude-e-esporte | 96 — Zero Meia Um Saúde e Esporte |

SELECT confirmou uma correspondência por tag. Os novos links já estavam corrigidos em RR-28, mas as cinco URLs antigas em `/assessoria/` ainda respondiam 404. A regra admite apenas os cinco slugs exatos, GET/HEAD, query vazia e caminho com/sem barra final. Outros slugs, métodos, filtros, tracking recebido por query e ações conservam o fluxo anterior. Não foi criado encaminhamento genérico de toda a área nem inferido destino para URLs incompletas de eventos.

## Business publicado

Arquivos: `portal/includes/seo_queue_data.cfm` e `portal/conteudo/seo_semrush.cfm`. RR-31 registra os cinco aliases recuperados e RR-20 recebe a classificação dos achados restantes. Subabas, filtros, relatórios, GA4, controles de acesso e layout existentes foram preservados. O arquivo `seo_semrush_data.cfm` permaneceu byte a byte idêntico; os totais, notas e datas do fornecedor não foram reduzidos manualmente.

## Evidência atual e limites

Fonte histórica: snapshot Semrush `6ac31bf647d73ceec1b0b861`, auditoria de 5.000 páginas concluída em 05/10 às 01:37 (Brasília). Não há ferramenta Semrush exposta nesta sessão; nenhuma nova auditoria foi iniciada ou atribuída ao fornecedor.

- Oito URLs sinalizadas por conteúdo repetido: etapas LIVE em datas diferentes, Farmelhor em cidades/datas diferentes e as duas rotas FCA. As páginas dos eventos foram preservadas; o alias FCA já está em 301 após RR-29. Não foi declarada resolução global de conteúdo duplicado.
- Quatro URLs antigas de descrições duplicadas: rankings Supra 2024/2025 têm descrições distintas e o alias FCA já foi consolidado. Conferência atual preservou esses metadados.
- Costa Esmeralda: URL canônica portuguesa com barra e versões EN/ES HTTP200, canonical próprio em cada idioma e alternates recíprocos. O endereço sem barra também continua HTTP200 com canonical na versão com barra; não foi criada nova regra para ele.
- Sitemap histórico: HTTP200, XML válido e 5.265 URLs na leitura desta execução.
- Trail in Motion: HTTP200 em aproximadamente 0,37s na leitura; não é prova de estabilidade contínua.
- Quatro endereços incompletos de evento continuam HTTP404. A geração dos links já foi corrigida em RR-28, mas essa entrega não recupera automaticamente URLs malformadas antigas. Nenhuma identidade foi inferida para criar redirecionamento.
- Endpoint Cloudflare de proteção de e-mail continua HTTP404 com noindex/nofollow. As páginas de privacidade respondem HTTP200 e mantêm os links protegidos. A proteção não foi desligada.
- URL do atleta continua HTTP403 na requisição pública. O template de atleta exige login. Não foi aberto perfil autenticado, removida autenticação nem atribuída a origem exata desse 403 a uma regra Cloudflare sem logs.

Nenhum cadastro, data, tradução, autenticação, Cloudflare, sitemap ou operação Git foi alterado. Disponibilidade pontual, nota técnica, indexação, posições e tráfego permanecem medidas distintas. Efeitos sobre a auditoria exigem nova coleta comparável; Google requer sua evidência própria.

## Verificações

- 35 cenários nativos no Apache real em diretório temporário local: baseline e candidato lado a lado, 20 formas positivas de método/barra e 15 controles de métodos, query, slugs e arquivo existente. Todos passaram. A expectativa inicial de HTTP404 para PUT/DELETE foi substituída pela comparação com o retorno real HTTP405 do baseline; nenhum método foi liberado para passar no teste.
- `apache2ctl -t` aprovado antes da publicação. O teste HTTP da fixture exercitou o bloco exato de `.htaccess`, pois o teste global de configuração sozinho não valida todos os arquivos por diretório.
- Backup por hash, publicação de um `.htaccess` e conferência de 17 dependências preservadas. Sem reload/restart de serviços.
- 30 requisições públicas de aliases, destinos e controles: 20 combinações GET/HEAD com/sem barra em 301; cinco destinos em 200 com título, H1, descrição, canonical, alternates e robots preservados; cinco controles negativos continuam 404.
- As cinco cadeias foram efetivamente seguidas: exatamente um salto e destino HTTP200.
- Rechecagem das 34 URLs da auditoria/controles: somente os cinco aliases mudaram para 301; outras 29 preservaram status e metadados.
- URL canônica PT de Costa Esmeralda conferida separadamente; três idiomas HTTP200 com reciprocidade comprovada. XML histórico analisado após a publicação.
- Dois templates Business compilados no Adobe ColdFusion e 19 cenários aprovados antes/depois da publicação, incluindo oito controles de acesso e escaping. Dez dependências Business preservadas.

Gate público final: `2026-10-06T18:38:54.915291+00:00` (15:38 Brasília). Candidatos, baselines privados, ferramentas e recibos estão em Business `_codex/staging/seo-revisao-20261006/`. Baselines de produção foram excluídos do Git pelo ignore local.

## Recuperação

Backups publicados: `/var/backups/seo-legacy-supplier-20261006-rr/baseline` e `/var/backups/seo-legacy-supplier-20261006-business/baseline`.

Para reverter este lote, executar no staging `release.py business rollback`, seguido de `release.py rr rollback`. Scripts recusam mudanças concorrentes por hash. Não reverter sobre publicações posteriores sem conciliar o drift. Recibos: `apache-tests.json`, `public-passed.json`, `other-review-passed.json`, `rr-publish.json`, `rr-verify.json`, `business-publish.json`, `business-verify.json`, `published-render-passed.json`.
