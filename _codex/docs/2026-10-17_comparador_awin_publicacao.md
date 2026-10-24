# Publicação automática de campanhas Awin

Publicado em 17/10/2026. A gestão está em **PLATAFORMA → Comparador → Integração Awin → Vinculação e publicação**. A conta 1455398 consulta 10 anunciantes aprovados; a primeira rotina processou 38 campanhas vigentes e publicou a campanha 4143219 (Centauro) no Olympikus Corre 4, produto 4282. As outras 37 ficaram pendentes de confirmação/compatibilidade com o catálogo.

## Arquivos e domínio

- `services/ComparadorAwinService.cfc`: compartilha a consulta autenticada entre administrador e scheduler; token permanece privado no servidor.
- `services/ComparadorAwinPublicationService.cfc`: correspondência conservadora, regras manuais, bloqueios, validação de concorrência, histórico e publicação atômica.
- `administracao/comparador/awin/{backend,home,publication}.cfm`: aba e formulários de vinculação, seleção de até 20 produtos por campanha e ações de bloqueio/restauração.
- `api/comparador/awin-sync.cfm`: endpoint POST autenticado pelo segredo interno existente do Business.

O Comparador consome o contrato privado v1 `/var/lib/runnerhub/business-awin/cache/publication.json`. O envelope tem conta, versão, datas, regras, ofertas, decisões e histórico. A publicação não escreve em `tb_cupom`, nem transforma percentuais/títulos em preços numéricos. O feed de produtos será a fonte de preço e estoque. [Contrato completo no Comparador](../../../Comparador/codex/docs/awin-ofertas.md).

## Operação

Job **24 — Comparador - Campanhas e ofertas Awin**, intervalo 30 minutos, ativo no agendador existente. POST para `https://business.roadrunners.run/api/comparador/awin-sync.cfm`, autenticação `bearer` e `secret_ref=business_internal`; timeout 120 s, sem retries adicionais. Não há novo cron de sistema nem nova credencial.

Primeira execução `211126`, origem `scheduled`, concluída às 16:32 de 17/10/2026 com `200 OK`, 1 oferta e 37 pendências. Monitorar em **Cron Jobs**; atualização sob demanda pelo botão **Sincronizar e publicar**. Uma falha mantém o arquivo anterior; a exibição pública é suspensa após seis horas sem uma consulta válida. Campanhas vencidas ou ainda futuras são filtradas na requisição pública. Bloqueios persistem; mudanças na campanha invalidam confirmações manuais.

`publication.json` é criado com modo 0600, proprietário ColdFusion, dentro do diretório cache já autorizado para escrita. O diretório pai com token continua fora do webroot, com acesso restrito. O histórico mantém 100 eventos; guardar cópias desse arquivo se houver necessidade de auditoria de longo prazo.

## Verificação

32 testes CFML em `_codex/tests/comparador/awin-publication.cfm`: permissões, CSRF, nomes/gerações/variantes, ambiguidades, múltiplos produtos, invalidação de confirmação, retirada, validade/fuso, TTL, identidade, URLs, concorrência, idempotência e persistência. Para repetir, executar somente em harness privado com mapeamento `/services` ao Business e `/publicservices` ao Comparador; criar a fixture em `/var/tmp/runnerhub-awin-publication-validation/fixture` e copiar um snapshot Awin recente para `cache/snapshot.json`. A fixture deve ter configuração fictícia (`publisherId=1455398`, token `fixture-only`) e ser gravável pelo runtime. O teste usa leitura do catálogo real, escreve/exclui apenas arquivos nessa fixture e exige ao menos uma correspondência no snapshot. Não publicar o harness.

Compilação CF2025: 8 templates/componentes Business (incluindo dois suportes) e 2 Comparador. Sete testes HTTP pós-deploy confirmaram login, inclusão protegida, endpoint GET405/POST401, métodos não remotos e produto público. Gestão verificada na sessão administrativa real; oferta pública conferida em desktop 1280px e celular 390px, sem transbordamento horizontal. [Recibo](2026-10-17_comparador_awin_publicacao_recibo.json) · [Testes](2026-10-17_comparador_awin_publicacao_testes.json).

## Publicação e recuperação

Release `20261017T193048Z-57cce513`, 6 arquivos Business e 2 Comparador. Baseline local/produção, backup recuperável e hashes verificados; produtor publicado antes do consumidor. Backups em `/var/backups/awin-publication-20261017/{business,comparador}/20261017T193048Z-57cce513`.

Para rollback: desativar somente o job 24, preservar configuração/cache, conferir os hashes atuais contra o recibo e restaurar somente esses arquivos. A primeira tentativa usou um domínio de smoke incorreto e foi revertida automaticamente antes da entrega validada. Nenhum commit, branch ou push foi criado.

## Feed de preços integrado

Em 17/10/2026, o feed passou a fornecer 49 preços em 49 produtos, com gestão própria e atualização no mesmo job. [Contrato, operação e validação](2026-10-17_comparador_awin_feed.md). Os vínculos das campanhas permanecem independentes.
