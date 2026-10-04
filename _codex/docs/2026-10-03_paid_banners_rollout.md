# Banners CPC — retomada e rollout de 03/10/2026

## Estado

**Runtime publicado e verificado em 03/10/2026. Veiculação CPC de banners habilitada em produção por solicitação posterior explícita do usuário.** O update dos repositórios havia removido parte da integração e dos contratos de teste. A recuperação preserva as versões mais novas em produção, incluindo o dashboard HOUSE, os uploads validados e os filtros de tráfego automatizado no RoadRunners.

## Produto

- Banners de marcas/parceiros separados de anúncios de eventos, sem evento fictício.
- Mesma carteira e cobrança CPC canônica; aprovação da equipe obrigatória.
- Banners pagos elegíveis têm preferência. HOUSE gratuito é fallback quando não há candidato pago, nunca em caso de erro.
- Tela de banners organizada em Desempenho, Banners e Cadastro; HOUSE explicitamente separado e exclusivo da administração.
- `bannerCpcPlacements` permanece desligado por padrão e isolado por ambiente. A publicação inicial não alterou configuração privada; a liberação posterior abaixo habilitou somente produção, sem aprovar/ativar campanhas individualmente.

## Liberação para contas clientes — autorização posterior

Usuário: “agora eu quero que contas normais de clientes possam incluir banners no site com aprovacao, igual aos ads, e liberar o recurso”.

- Cadastro já publicado em `/portal/banners/`: OWNER, ADMIN da conta e OPERADOR podem gerenciar os próprios banners; VISUALIZADOR permanece somente leitura. Revisão/aprovação continua exclusiva do administrador interno real. Nenhuma permissão foi ampliada para aprovar o próprio anúncio.
- Adicionada exclusivamente `bannerCpcPlacements = ["rr-sidebar-banner-300x250"]` no arquivo físico de produção `/var/www/roadrunners.com.br/config/ads.local.cfm`. Todo conteúdo anterior preservado byte a byte; configuração dev inalterada. Nenhum SQL, saldo ou campanha alterado.
- Backup recuperável `/var/backups/paid-banner-enable.07xo9e4m`, com original, candidato, recibo e compilação Adobe CF 1/1 antes da troca atômica. Owner, grupo e modo preservados.
- SHA anterior `dd3ff39886efec603025a331c596c644f803bddf0794ba3b9166fd8e2259b927`; habilitado `6128dd5c5495824577c251fde9dbdaeaab8cd7c92ee2d53a119027e229d6c64e`.
- Verificações desta liberação: runtime publicado e 94 guards conferidos antes da flag; integração de banners 10/10, ações 14/14, configuração isolada 18/18, suíte de acesso Ads PASS. Validação posterior confirmou hash e alteração somente da flag.
- Business autenticado global abriu a listagem CPC sem erro, ainda sem banners pagos cadastrados. Não houve teste novo logado como cliente comum; os contratos de permissão e a integração cobrem esses papéis. Chrome voltou a ser utilizado pelo usuário durante a conferência; não houve troca de conta nem interferência na edição dele.
- RoadRunners `/estado/ba/` após habilitação: fallback HOUSE Live! Run XP com imagem carregada e os dois anúncios EVENT preservados, sem erro CF na página. Nenhum anúncio clicado. Visitas de verificação podem registrar entrega/visibilidade.
- Log corrente após ativação (12:49:37 UTC / 09:49:37 São Paulo): 42 entregas de banners com status `served`, sem `errorStage` na janela conferida. Isso confirma continuidade da entrega/fallback; não prova entrega paga, pois ainda não havia BANNER CPC cadastrado.
- Não foi necessário reaplicar migration. Não houve commit/push. Script operacional com baseline fixo: `_codex/scripts/enable_paid_banners_production.py`; não é idempotente e deve recusar reexecução sobre produção já alterada.

## Evidência já executada

- PostgreSQL descartável: 11 grupos de contratos financeiros, incluindo concorrência EVENT/BANNER, replay, orçamento, estorno, revisão e isolamento.
- Queries extraídas dos adaptadores: 3 de banners + 11 de EVENT/ledger compartilhado executadas em PostgreSQL descartável.
- Business: 12 suítes CFML de produto e regressão HOUSE; correção final de navegação por abas em verificação própria.
- RoadRunners: configuração 18 casos, wrapper de sidebar 27 casos, serviço 12, contexto 11, renderer 8, clique 324 e tracker 67.
- Regressões JS: 35 testes. Publicador: 11 testes.
- Fixtures do renderer e workspace em 1280 e 390 pixels, sem overflow horizontal. Não substituem verificação autenticada em produção.

## Publicação e verificação real

- Revisão independente final aprovada sem Critical/Important. Minor não bloqueante: upload validado pode ficar órfão quando há rejeição local antes do SQL. Não foram apagados assets históricos; correção futura deve preservar imagens de gravações com resultado incerto.
- Manifesto: `2026-10-03_paid_banners_reviewed_release.json`; recibos `2026-10-03_paid_banners_reviewed_prepare.json`, `2026-10-03_paid_banners_reviewed_prepare-publish.json` e `2026-10-03_paid_banners_reviewed_prepare-verify.json`.
- Backup recuperável: `/var/backups/house-banner-scope.b2300dfa0143`. Compilação Adobe CF21/21; runtime22/22; 94 caminhos protegidos. Publicação e verificação terminaram com exit0, phase `published`.
- Chrome autenticado, administração global: nova listagem CPC abriu sem erro/readiness bloqueada; Desempenho → Banners → Desempenho manteve Últimos90dias. HOUSE explícito preservou6banners/3ativos, gráfico e listagem.
- Chrome autenticado, conta Live!: formulário CPC abriu com imagens desktop/mobile, dimensões automáticas, lance/orçamento/escopo e Enviar para análise/Salvar como rascunho. Nenhum upload ou submit foi realizado. Banners e Ads/Saldo e pagamentos mostraram o mesmo saldo R$408,82. Contexto original Todas as contas restaurado.
- RoadRunners `/estado/ba/`: dois anchors CPC EVENT (Live! Salvador e Maratona de Floripa2027) e banner HOUSE HyperwarpProMIF com imagem carregada, sem erro de página. Nenhum link de anúncio clicado; navegação comum pode registrar entrega/visibilidade.

## Limites da homologação

Nenhuma campanha real foi criada, aprovada ou ativada pela validação; não houve clique pago ou SQL de produção. Contratos financeiros e adaptadores foram testados isoladamente; upload multipart com salvamento e ciclo completo de aprovação/cobrança não foram exercitados em produção. A flag foi habilitada por autorização posterior, mas ainda não havia banner pago real para demonstrar entrega CPC ponta a ponta.

O último teste IAB de viewport solicitado em390px permaneceu em1280px; não é evidência móvel nova. As verificações responsivas anteriores estão registradas no ledger e a conferência autenticada desta publicação foi desktop.

## Operação e recuperação

A migration `RoadRunners/_codex/sql/2026-09-16_ads_paid_banners.sql` foi aplicada pelo operador; não é reaplicada pelo publicador. SHA256: `b706b0921e58d5101f341da4c62f541bcb14b9eee42a058d1d5fa2cd5270da39`.

Para interromper seleção paga, retirar apenas `rr-sidebar-banner-300x250` de `bannerCpcPlacements` no ambiente pertinente; conservar endpoints dos recibos já emitidos e o histórico financeiro. Nunca apagar ledger nem converter campanhas para HOUSE. O backup da flag acima só deve ser restaurado após conferir ausência de outras alterações posteriores no arquivo.

Publicador: `_codex/scripts/deploy_paid_banners.py` (`prepare`, `publish`, `verify`, `rollback`). Preparações anteriores foram somente privadas e estão supersedidas; não usá-las para publicar.

Rollback do runtime publicado (somente após decidir operacionalmente pela recuperação):

```sh
python3 _codex/scripts/deploy_paid_banners.py rollback _codex/docs/2026-10-03_paid_banners_reviewed_release.json _codex/docs/2026-10-03_paid_banners_reviewed_prepare.json
```

Não executado; o comando valida estado/hash e usa o backup exato, sem rollback do banco ou remoção de histórico financeiro.
