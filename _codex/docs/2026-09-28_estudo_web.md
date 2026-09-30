# Estudo → versão web

Implementado e ativado em 28/09/2026, validação encerrada em 29/09/2026.

## Fluxo do administrador

Em `/estudo/?caderno=6`, abrir **Brasil que Corre Provas — Publicação web**:

1. Revisar as queries de origem e congelar os resultados necessários.
2. Na seção do ano, atualizar a query de saída para usar esses congelamentos. Executar e congelar.
3. Na aba **Versão web**, escolher edição e congelamento; usar **Conferir pacote**.
4. Inspecionar valores, fontes, denominadores e pendências; escrever a nota pública.
5. **Usar na versão web** ativa o pacote. Apenas executar/congelar não publica.

O seletor aceita congelamentos completos da célula designada para cada edição. Para voltar a um pacote anterior, selecioná-lo e publicar com nota explicativa: a versão anterior permanece registrada. A troca protege contra publicação concorrente por outro admin.

## Estado inicial e limites

- Caderno 6, seções 54/55, células SQL 249 (revisão 2) e 251 (revisão 1).
- 2025: execução congelada #32, publicação #1, versão web 1. Totais 5.279.415 resultados de `vw_resultados` (#7) e 9.360 eventos (#8). O total não afirma um filtro de conclusão. Mais 33 valores de gênero, distâncias e calendário ligados às execuções #6, #15, #16, #17 e #25. Todas as sete origens são identificadas no payload.
- Os demais valores de 2025 continuam usando o snapshot inicial, explicitamente identificados. Valores ausentes continuam nulos. A referência do PDF permanece intacta. 486 comparações e 83 séries.
- 2026: execução #33, publicação #2, versão web 1. É uma ponte para o snapshot v3 existente; preserva integralmente números, corte, coortes e pendências. 535 comparações e 85 séries. Não houve nova coleta nem recálculo de 2026.
- Publicar a prévia não certifica conciliação metodológica. A próxima revisão analítica deve substituir as fontes restantes e atualizar o pacote 2026 a partir de queries revisadas.

## Contrato e persistência

Migration: `_codex/sql/2026-09-28_estudo_web.sql`. Carga inicial e queries vigentes em `estudo_web_2026_09_28/`.

- `estudo.web_bases`: projeções públicas anteriores e contrato JSON permitido, imutáveis.
- `estudo.web_destinos`: célula por edição, versão e ponteiro para publicação ativa.
- `estudo.web_publicacoes`: cópia imutável do payload, run, ator, nota e momento de ativação.
- `estudo.web_payloads`: view de leitura pública, somente pacote ativo e metadados públicos de versão.
- `web_json_valido` valida tipos/chaves/limites; `web_payload_conferido` exige uma única coluna `payload`, uma linha completa, run congelado e bem-sucedido da célula correta, contrato do ano e categorias completas. Valores originais do PDF não podem mudar.
- `publicar_web` trava o destino, valida a versão esperada, valida o pacote e registra a nova publicação. Retry do mesmo run ativo é idempotente no banco.

RoadRunners lê a view pelo datasource habitual com timeout de 5s. Não executa queries de análise nem lê diretamente o acervo interno. A view não expõe SQL, usuários, caminhos operacionais nem dados pessoais. A nota é pública; o administrador deve escrever apenas contexto metodológico nela.

Business conserva a guarda de admin e POST/CSRF das ações. Novas ações: `webCatalog`, `webPreview`, `webPublish`; `StudyPublication.cfc` implementa a ponte. `SqlReadGuard` permite as funções JSON puras `jsonb_object_agg` e `jsonb_typeof`. Não houve mudança de auth/bootstrap ou credenciais.

## Verificação

- 7 testes PostgreSQL locais (com vários casos negativos), incluindo imutabilidade, concorrência, contrato, congelamento e privilégio de leitura.
- 17 testes do adaptador RoadRunners e sintaxe JS.
- 4 templates CFML Business e 1 RR compilados na publicação principal; index Business compilado no ajuste de cache.
- Hashes de 5 arquivos Business + 3 RR verificados; index Business e ajuste do rótulo RR verificados separadamente.
- Chrome autenticado: executar/congelar/conferir/ativar nos dois anos, fontes visíveis, alternância PDF/atual. Aba de publicação e página pública responsivas em 390px sem transbordamento da página.
- Endpoints públicos 200 e exatamente iguais às projeções conferidas; ano inválido 400; API Business sem sessão redireciona 302. Cabeçalhos noindex/nofollow e private/no-store mantidos. Verificação HTTP direta local foi bloqueada pelo WAF (1010); conferência no origin e Chrome concluída.
- Acervo anterior intacto: 3 cadernos, 45 seções, 166 células, 31 execuções e 4 snapshots; comparados ao backup pré-migração.
- Página anterior do estudo não alterada; hash corresponde ao arquivo local intacto.

## Publicação e reversão

Ordem aplicada: schema/carga → Business → executar/congelar/ativar os dois anos → consumidor RoadRunners. O pacote público está no link direto `/brasilquecorreprovas/web/`, sem divulgação na página do PDF.

Backups: `/var/backups/business-estudo-web-20260928/`, subpastas `database`, `runtime`, `cache-version`, `label-correction`. Para rollback de código, restaurar primeiro o consumidor RR a partir de `runtime/RoadRunners/baseline`, depois os arquivos Business do backup correspondente. Conferir os caminhos no manifesto antes de restaurar. Manter as tabelas e congelamentos; não é necessário apagar dados. Para corrigir apenas os números, preferir publicar um congelamento anterior pelo próprio Estudo.

Recibos e prova visual: `estudo_web_2026_09_28/`.
