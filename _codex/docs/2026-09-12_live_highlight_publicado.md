# Destaque LIVE! publicado — 12/09/2026

Pedido: destacar somente uma etapa no topo da agregadora, mantendo todas as
outras visíveis na mesma lista. Não adicionar seletor/filtro, botões de troca de
cidade ou redirecionamento. URL: https://roadrunners.run/circuito/live-run-xp/.

## Entrega

O projeto RoadRunners resolve a localização estimada pelo serviço já existente
e promove a próxima etapa da cidade + UF; sem correspondência de cidade, usa a
próxima etapa da mesma UF. Sem contexto utilizável ou etapa elegível no estado,
mantém a ordem original sem destaque. O rótulo é “Etapa em destaque”, com borda
e fundo suaves. O card compartilhado, os links e as contagens foram preservados.

Arquivos de runtime publicados, nesta ordem:

| Arquivo RoadRunners | Baseline | SHA-256 publicado |
|---|---|---|
| `circuito/live_highlight.cfm` | Ausente | `a903ea66b520326e7837651f3044c0d5def21931211c9cd90eecfc0ff6ad7d97` |
| `circuito/index.cfm` | `21815dc7d984ffda97aeeee2038d28bd7bd71b58357028f8b697553482148268` | `b11b0fd4c7488265a3cc5194b908942ca3a0c54d4ad3d64deb1d482f6bed9fbe` |

Checkout RoadRunners atualizado também com o teste CFML, seu harness e
`_codex/docs/circuit-live-highlight.md`. Os dois ajustes de rodapé preexistentes
em produção foram conservados. Nenhum commit, branch, push ou PR foi criado.
Business recebeu apenas artefatos locais de operação e este registro. Não houve
mudança no seu runtime, banco, Google Ads ou mensuração de audiência.

## Evidências executadas

- CFML offline usando card real: 113 verificações passaram. O teste detectou a
  falta de promoção na implementação anterior e um problema de normalização de
  acentos, corrigido com `java.text.Normalizer` + `String.replaceAll`.
- Revisão independente dos dois templates e do publicador: sem bloqueios.
- QA visual e funcional: quatro fixtures em 1440×1000 e 390×844, oito cenários
  aprovados; todos os cards acessíveis por rolagem, sem overflow horizontal.
  Capturas em `Business/output/playwright/live-highlight/`.
- Publicador: nove testes offline; transferência: quatro testes offline.
- Adobe ColdFusion do servidor, em diretório privado
  `/var/tmp/rr-highlight-compile.mjjvul98`: **successful 2 / total 2**.
- Requisições HTTP isoladas com geografia sintética, sem usar ou alterar a sessão
  do usuário: Campinas promoveu 37484; São Caetano (entrada sem acento) promoveu
  37536; Blumenau/SC promoveu Jaraguá 37532; país estrangeiro não teve destaque.
  Todas responderam 200, `Cache-Control: private, no-store`, `CF-Cache-Status:
  DYNAMIC`, com 18 próximas etapas e 169 realizados; links e ordem restante
  preservados. Esse teste valida seleção/renderização, não precisão do provedor
  de localização.
- Navegador real da agregadora: novo include renderizado, 18 próximas etapas e
  169 realizados, conjunto de links idêntico ao baseline. Na localização dessa
  sessão não houve destaque, mantendo a ordem de datas prevista.

## Publicação e recuperação

Pacote privado: `/var/backups/rr-live-highlight.5ccccbd11911`.
Publicador SHA-256:
`fea1cfb363cc2aa000789d1c7fbcbc90b75af9af9f7ae7141291997be801086a`.
`prepare`, `publish` e `verify` retornaram zero; estado final `published`;
dois alvos e 116 guardas preservadas, incluindo os 11 arquivos da mensuração
LIVE!. Backup do index e registro de ausência do include disponíveis no pacote.

Os scripts e recibos ficam em `Business/_codex/staging/live-highlight/`:
`roadrunners-manifest.json`, `release/runtime.tsv`, `private-compile-result.json`,
`remote-release.json`, `remote-publish-result.json`, `remote-verify-result.json`
e `http-qa-result.json`. A CLI `release_remote.py rollback` executa restauração
guardada: restaura o index antes de retirar o include; recusa sobrescrever
alterações concorrentes. Não deve ser executada sem necessidade operacional.
