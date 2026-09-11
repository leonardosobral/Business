# Audiência YouTube — publicação de 10/09/2026

Publicado em **2026-09-10T13:34:32Z (10:34:32 Brasília)**, após autorização do usuário. Somente três arquivos do RoadRunners. Sem reinício, SQL, alteração de permissões, reset de aplicação ou sessão.

## Artefato e recuperação

- Pacote: `_codex/releases/2026-09-10_audience_youtube_linux.tar.gz`.
- SHA-256 do pacote: `16c53efd3489b8dd9afb541de0c1b349c9a267af3c2cb337145f26747f7f3ce7`.
- Destino: `/var/www/roadrunners.com.br`.
- Backup privado: `/var/backups/rr-audience-youtube.36MZOB/`, contendo `before/`, `before.sha256`, `candidate/`, `candidate.sha256`, `guards.sha256` e o pacote.
- Ordem: tracker → modal → bootstrap; substituição individual no mesmo filesystem, preservando root:root e modo 0644 observados.

| Arquivo | SHA-256 publicado |
|---|---|
| `assets/js/rr-audience.js` | `b79bb913eb5f604eecd1ad6a77024198c96179850e3da299d82997f1a409a7d2` |
| `includes/modal/modal_youtube.cfm` | `92a7e067f7d36f361e09d89043c962e45940a8bada22f7846dd5bc6ce8f38aba` |
| `includes/analytics/bootstrap.cfm` | `9578188a77ba16a6c7a48b7c45c37b7137bccd7507892582d02317ee99c32d51` |

Versão efetivamente observada na página: `rr-audience.js?v=b79bb913eb5f`. Hashes de produção confirmados após os testes reais. Autenticação, configurações, Ads, cobrança, coletor, service worker, writer de evento e `LocationResolver.cfc` permaneceram com os hashes anteriores. Cache geográfico **não publicado**; HTTP 403 do provedor continua pendência separada.

Rollback disponível, não executado: conferir o manifesto `before.sha256`, restaurar apenas os três arquivos de `before/` nos caminhos correspondentes e reconferir os hashes. Não restaurar a aplicação inteira ou configurações adjacentes.

## Evidência ponta a ponta

Navegação real pelo Chrome autenticado, sem chamadas artificiais ao coletor ou ao banco. Página `/videos/`, ambiente `prod`, recorte de sete dias, família **Vídeos — lista**, **Incluir acessos internos** ativado somente para a validação.

Antes da reprodução, não havia linhas de conteúdo individual nesse recorte. Depois:

| Vídeo | Aberturas | Visitantes | Inícios | Conclusões |
|---|---:|---:|---:|---:|
| `u0pjXoZMC2I` — Por que ele TROCOU DE CAMISETA tantas vezes no PÓDIO? | 1 | 1 | 1 | 0 |
| `nmLeBM_7ndM` — Tive 2 problemas com o Olympikus Challenger 6 | 1 | 1 | 1 | 0 |

- Primeiro vídeo reproduziu em desktop; pausa, retomada, fechamento e reabertura funcionaram. Reabertura não duplicou abertura/início do mesmo conteúdo na mesma página.
- Segundo vídeo reproduziu em viewport de 390 × 844; iframe com largura 374 px e margem esquerda de 8 px, sem corte do player. Não equivale a teste de dispositivo físico ou de todas as plataformas.
- Business confirmou os dois registros; última recepção exibida em 10/09 às 10:42 Brasília.
- Nenhum anúncio foi clicado. Nenhum login novo foi exigido durante o fluxo.
- O teste não assistiu aos vídeos até o fim. Conclusão e quartis são cobertos pelos testes locais, mas não foram confirmados ponta a ponta nessa sessão. Avançar pelo player, quando aplicável, também não comprova tempo integral assistido.
- Viewport restaurado; aba de teste fechada; Business voltou ao filtro original, todas as páginas e acessos internos excluídos.

Na leitura final do painel comercial padrão (prod, sete dias, todas as páginas), o Business mostrou **1.766 aberturas, 473 visitantes estimados, 522 posições visíveis e 528 anúncios visíveis**. Esses totais são uma fotografia do recorte às 10:42, não resultado atribuído ao novo lote nem números exclusivamente de vídeos. O painel diferencia 1.767 páginas com atividade de 1.766 aberturas naquele contexto.

## Validação local e limites

69/69 testes Node de tracker, modal, privacidade, i18n e navegação editorial passaram novamente antes da publicação. Pacote com exatamente três membros, sem metadados AppleDouble, conferido byte a byte em revisão independente. `node --check` e `git diff --check` passaram.

Não há backfill de inícios anteriores. Os testes internos não devem ser apresentados como audiência comercial. Vídeos ainda não reproduzidos podem continuar sem inícios no filtro padrão. Exposição editorial, demais lacunas de inventário, fonte de UF, retenção operacional, projeção e aquisição continuam como frentes separadas do plano. `tb_log` permanece intacta; aposentadoria condicional somente do writer de visualização de evento fica para o final.
