# RoadRunners — publicação concluída, coleta desligada

O usuário autorizou explicitamente **“publique”** o candidato de 30 arquivos, mantendo a coleta desligada. A publicação foi concluída em `ssh.runnerhub.run:/var/www/roadrunners.com.br`, com 18 substituições e 12 novos arquivos. O executor terminou com exit 0; o journal está `completed`, com 30 aplicados e 18 backups verificados. [Recibo desta publicação](2026-09-07_audience_roadrunners_publication_receipt.json).

## Escopo preservado

Não houve DDL, alteração de `runner_dba`, autenticação, proxy, agenda, beta/dev ou ativação. As consultas de audiência mantêm o DSN explícito `runnerhub`, mapeado ao papel `runner`. `includes/ads_v1/viewability.cfm` permaneceu fora do pacote: SHA-256 `6824fabb64fc6715d6e48464113560636e78ded7f1004b6a2c1557c1eb37bc20`, metadados e mtime intactos. A limitação preexistente com imagens quebradas permanece registrada na [reconciliação](2026-09-07_audiencia_reconciliacao_roadrunners.md).

## Pacote, backup e execução

- Manifesto imutável: [candidato](2026-09-07_audience_roadrunners_publication_candidate.json), SHA-256 `6b20ca4534b6c67829245143c40df7ced80e0011cf8fea0078072e643b51d034`.
- Pasta operacional local: `/private/tmp/rr-audience-publish.j1Jkad`.
- Bundle privado remoto: `/var/backups/roadrunners-audience-publish-20260907.IG8snn`, root:root, `0700`.
- Archive original: SHA-256 `5983a424b6ca50bb803d63290699b1a197684b9dcf0a14fac4d720f8cacea3d6`, modo `0600`. Continha 30 arquivos runtime e 30 auxiliares AppleDouble do macOS. Estes últimos ficaram somente em `payload-with-macos-metadata`, na pasta privada. O payload limpo foi extraído seletivamente e contém exatamente os 30 arquivos revisados; nenhum `._*` foi publicado.
- Backup anterior preservado: `/var/backups/roadrunners-audience-20260907.qko32783/before.tar.gz`, SHA-256 `5035a71b74d125dc6dc54dfc029b8ba500f75faaa337f1dc9b9337f107333ab3`.
- Executor revisado: SHA-256 `64178ebedca67f03c5eff81b2db693380793b109bc95fd02c46b38a0e00ff8a6`, 15 testes aprovados e revisão independente sem P1/P2. A cópia aplicada `publish-roadrunners-approved.py`, SHA-256 `8143f0586a26c6959396a4adc794df6e696d9b26e28bc874170a391cbe64155d`, difere somente na abertura deliberada de `APPLY_REVIEW_APPROVED`.

Foram conferidos os 31 baselines antes da publicação: 19 existentes e 12 ausentes, sem diferença de conteúdo/metadados. Dependências novas foram publicadas antes das integrações; configuração e Application ficaram por último. Antes das integrações e após o conjunto completo, o POST canônico exigiu `503 {"error":"disabled"}`. O host `www` manteve o redirect preexistente `301` para `https://roadrunners.run/api/analytics/collect.cfm`, sem seguir redirects nem desabilitar TLS. Não se inferiu o estado de APPLICATION somente dos defaults em disco.

## Verificações pós-publicação

Verificação independente de arquivos em `2026-09-08T01:53:19.415767+00:00`: 30 hashes/tamanhos/modos/owners, 18 backups com metadados/mtime, payload exato, seis guards de autenticação/Ads, três overrides locais ausentes e backup anterior íntegro. Relatório `/private/tmp/rr-audience-publish.j1Jkad/files-postpublish.json`, SHA-256 `366d3761f355cb7d6bcc731024f6fa2a28e87a77cf51b8b61c513881a1c8bce5`.

Foram 104/104 verificações HTTP aprovadas: home, busca, notícias, vídeos e estado SC em acesso público e origem TLS; três novos assets disponíveis; controle de privacidade presente e configuração/tracker de audiência ausentes. POST canônico `503` com corpo exato disabled; GET canônico `405`; WWW GET/POST `301` para destino exato. Apache PID1780160 e ColdFusion PID1780425 permaneceram os mesmos; configtest passou, sem restart/reload. Relatório `/private/tmp/rr-audience-publish.j1Jkad/http-postpublish.json`, SHA-256 `5b84f1addee11ac7313990bc07e81ac354482ce30cb7ae2bd3db0f2e363c74d2`.

Na composição local com os 30 candidatos e o Ads original: 42 testes focados de audiência/privacidade, dois contratos CFML e DOM-ready Ads passaram. O teste de hardening do Ads excluído não integra esse resultado; não se afirma aprovação da suíte completa de 43.

## Validação autenticada e estado do painel

Antes do deploy RoadRunners, o Business já reconheceu os objetos instalados pelo operador via DataGrip: **“Aguardando os primeiros eventos”**, sem última recepção, retenção instalada e sem execução confirmada. SC/30 dias/contexto comercial passou em desktop1460px e mobile390px após reload, sem novo fluxo Google. Essa verificação não comprova audiência zero.

Após o deploy, a mesma aba e sessão RoadRunners continuaram autenticadas: largura/documento1460px, controle de privacidade presente e tracker ausente. O modal foi aberto manualmente para inspeção desktop e não aparece automaticamente. Mobile pós-deploy ficou inconclusivo por interrupção do controle do navegador e não é alegado.

O Business abriu novamente após o deploy, em nova aba com os mesmos cookies, sem Google: SC/30 dias/contexto comercial, largura/documento1648px, ainda aguardando eventos e retenção sem execução confirmada. A aba do painel foi marcada como entrega.

O usuário aceitou manter a janela após esclarecer que abre somente por clique. Não houve simplificação do modelo, remoção do controle ou ativação adicional. Os contadores zerados são esperados com coleta desligada e **não comprovam ausência de visitas**. Permanecem pendentes proxy confiável, rotina operacional de retenção e homologação/ativação explícita. Não há reconstrução retroativa de exposições.

## Recuperação

Payload, backups dos 18 substituídos e journal permanecem privados no bundle. Não reexecutar `--apply`: o executor recusa nova aplicação quando encontra os artefatos de execução. Qualquer recuperação exige reconciliar os 30 alvos e o Ads preservado antes de alterar arquivos, sem sobrescrever mudanças concorrentes. Nenhum rollback foi necessário. Manifests históricos e recibo anterior do Business foram preservados.
