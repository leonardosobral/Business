# Banners CPC com carteira compartilhada — desenho técnico

## Escopo aprovado na conversa

Banners continuam em tela separada dos anúncios de eventos. Contas podem anunciar marcas e parceiros por imagens e link HTTPS, sem evento. O produto é CPC e utiliza o saldo, o ledger e os mecanismos financeiros canônicos de Ads. Apenas integrantes autorizados da conta administram seus banners; a equipe RunnerHub aprova a veiculação. HOUSE continua institucional, gratuito e administrado internamente.

Desenho aprovado para implementação em 16/09/2026. A aprovação do desenho não significa que a migration ou o runtime já foram publicados.

## Decisão comercial aprovada

Os banners CPC elegíveis disputam o espaço; HOUSE ocupa o espaço apenas quando não houver CPC elegível. Não alternar gratuitamente um HOUSE sobre uma oportunidade paga elegível. A seleção HOUSE atual, com peso e prioridade, permanece inalterada dentro desse grupo.

Confirmado pelo usuário: “sim, preferencia do pago”. Não criar proporção de alternância entre HOUSE e CPC.

## Evidência do estado atual

- `portal/banners/index.cfm` exige administração global.
- `portal/includes/banner_management_backend.cfm` fixa owner institucional 1 e usa `ads.save_house_banner_campaign_v2`.
- `ads/includes/access.cfm` já distingue papel da conta e identidade real, incluindo preparação de conta nova pendente.
- A fundação de Ads permite BANNER apenas HOUSE em constraints de anúncios e deliveries. BANNER exige `core_event_id IS NULL`.
- `ads.campaign_review_requests.core_event_id` é obrigatório; ativação e revisão validam especificamente EVENT e vínculo de evento.
- `record_cpc_viewable`, `charge_cpc_click_token`, `charge_cpc_click`, validação de entrega e endpoints CPC têm filtros explícitos EVENT.
- O carregador de configuração aceita CPC somente nos cinco placements nativos de evento.
- `AdsV1BannerDeliveryService.cfc` e o renderer aceitam somente HOUSE.
- O escopo de páginas/UFs já existe em `banner_scope_v1`, validado no salvamento, seleção e entrega.

As fontes históricas não substituem a inspeção das definições efetivamente instaladas: a migration deve verificar baseline e abortar diante de divergência, preservando as correções de cobrança e revisão posteriores.

## Alternativas avaliadas

1. **Reutilizar carteira, ledger, campanha e cobrança; especializar cadastro e revisão de BANNER.** Recomendado: uma verdade financeira, interfaces separadas, mesmas proteções contra repetição e saldo insuficiente.
2. Carteira e cobrança próprias para banners. Rejeitado: divide o crédito da conta e duplica conciliação, estorno e prevenção de saldo negativo.
3. Apenas abrir o formulário HOUSE para clientes. Rejeitado: não implementa cobrança, mantém owner institucional e quebra isolamento e aprovação.

## Responsabilidades e limites

### Business: experiência e autorização

- Manter `/portal/banners/` como tela de Banners, sem mover seu formulário para `/ads/`.
- Contexto de conta ativa abre o produto CPC da conta; administração global pode consultar todas as contas e a fila de banners. HOUSE fica numa visão administrativa explicitamente identificada.
- Acesso e mutations dependem da identidade autenticada e do papel efetivo, nunca de `account_id` ou `is_admin` enviados pelo formulário.
- OWNER, ADMIN e OPERADOR criam, editam, enviam, pausam e finalizam banners da conta; VISUALIZADOR apenas consulta. Compra de crédito e resgate seguem as permissões financeiras existentes.
- Conta nova pendente pode preparar banners e enviar à espera da aprovação da conta; pedido de ingresso em conta existente não concede acesso antecipado.
- O servidor revalida conta/ator/campanha em toda ação, incluindo upload, seleção, desempenho e revisão. CSRF obrigatório; GET não altera estado.
- Formulário contém nome, imagens desktop/mobile, destino, texto alternativo, páginas, UFs, dispositivo, período, lance e orçamentos. Dimensões são lidas das imagens, canal é interno, prioridade/peso HOUSE não são oferecidos ao anunciante CPC.
- Reutilizar validação de upload em área temporária, formatos aceitos e nomes aleatórios. Nunca sobrescrever o arquivo já aprovado; falha deixa o último estado persistido intacto e preserva os campos para correção.
- A ação principal é **Enviar para análise**, com **Salvar como rascunho** secundária. Salvar e enviar formam uma operação transacional: não anunciar sucesso de submissão quando só o rascunho foi salvo.
- Revisão mostra ambas as imagens, URL completa, conta, segmentação, período, lance e orçamento. Aprovar somente a versão/revisão exibida; decisão obsoleta falha de forma explícita.
- Editar banner ativo pausa/reabre antes de alterar a peça; editar banner em análise cancela a revisão anterior. Alterações exigem novo envio e aprovação, sem manter a versão nova rodando com aprovação antiga.
- Dashboard de banners inclui impressões visíveis, cliques válidos/cobrados, CTR, CPC médio, gasto, saldo compartilhado, histórico e detalhes expansíveis. O painel de eventos continua mostrando EVENT, não banners acidentalmente.
- Link para Saldo e pagamentos leva ao fluxo financeiro existente; não duplicar checkout ou voucher. O extrato comum identifica campanha e tipo de anúncio para permitir reconciliar o gasto das duas telas.

### Schema ads: regras transacionais

- Persistir BANNER/CPC em `ads.campaigns`, `advertisements`, `creatives` e `campaign_placements`; carteira continua `account_balances`, orçamento continua `campaign_budget_state` e cobrança continua `ledger_entries`.
- Ampliar somente os contratos necessários para aceitar EVENT/CPC e BANNER/CPC, mantendo HOUSE sem débito, BANNER sem evento e EVENT com evento válido. Não remover validações genéricas de produto para acomodar o caso novo.
- Revisão compartilhada distingue explicitamente tipo de anúncio: EVENT exige evento e vínculo; BANNER exige imagem/destino válidos e evento nulo. Toda revisão pertence à mesma campanha/conta/produto.
- Funções de salvar/enviar/revisar são controladas por `ads_owner`, com `search_path=pg_catalog`, ACL mínima e validação do ator real. Nenhum DML financeiro é concedido a runtime.
- Aprovação e ativação revalidam conta ativa, revisão atual, integridade da peça, placement, período e condições financeiras. Não chamar funções antigas desprotegidas diretamente pela UI.
- Clique usa o preço imutável da entrega, nunca um lance vindo do browser; valida token, prazo, produto, deduplicação e disponibilidade financeira sob os locks existentes.
- Preservar a ordem de locks financeira já adotada e testar concorrência entre clique de evento e clique de banner no mesmo saldo. Nenhum saldo negativo, débito repetido ou consumo acima do orçamento.
- Estorno e pagamento seguem as funções atuais. HOUSE existentes não mudam de billing, owner ou saldo. Não migrar campanhas reais para CPC automaticamente.
- Limites total/diário e holds de pagamento valem para banners e eventos; o saldo é comum, o orçamento é individual.
- Migration altera objetos do schema `ads`; lê contas, usuários e vínculos em `public`, sem escrita ou alteração estrutural em `public`.

### RoadRunners: seleção, exibição e medição

- Reutilizar o placement de banner responsivo atual, `rr-sidebar-banner-300x250`, e as posições físicas desktop/mobile. Não criar slots que o site não renderiza.
- Gate CPC de banner explícito e por ambiente, desligado até banco e serviços serem validados. Não permitir que beta/dev herdem configuração de produção.
- Seleção paga filtra conta/campanha/aprovação, saldo, orçamento, período, dispositivo, páginas e UFs antes do ranking. Aplicar novamente as condições na entrega sob lock, para não servir uma aprovação revogada ou banner fora de escopo.
- Ranking de banners considera lance e relevância regional do escopo: campanha específica para a UF tem preferência de relevância sobre nacional; permanece disputa por pontuação, não garantia de posição comprada. Como BANNER não possui evento, não atribuir um bônus fictício de UF do evento.
- Reutilizar a regra matemática de preço do leilão CPC, respeitando o lance máximo e o piso vigente do placement. Persistir preço e contexto de leilão no recibo de entrega; eventos mantêm o ranking/preço atuais sem alterações incidentais.
- Se não houver pago elegível, usar o caminho HOUSE conforme a decisão comercial confirmada. Falha de cobrança/seleção CPC nunca transforma campanha paga em HOUSE.
- Renderer escolhe os endpoints conforme o billing real retornado e mantém recibos individuais. Destino vem do recibo validado, não de URL fornecida no request de clique.
- Compartilhar proteções existentes contra bots, HEAD, preview e prefetch. Cliques filtrados não debitam nem consomem o ID que poderia ser usado pelo humano.
- Impressão depende da peça carregada e de visibilidade contínua já exigida pelo tracker. Entrega não vira impressão automaticamente. Métricas continuam segregadas por produto e billing.

## Sequência de implementação e gates

1. Conferir baseline das funções instaladas e fixtures SQL atuais em ambiente isolado; capturar definições e hashes sem expor credenciais.
2. Escrever testes de contrato que falhem com BANNER/CPC atual: constraints, revisão, ativação, seleção, medição e clique. Executar regressões EVENT/HOUSE em paralelo lógico, sem mutações em campanhas reais.
3. Implementar migration aditiva e funções de produto; testar rollback transacional, reexecução e concorrência financeira em banco descartável.
4. Implementar Business com testes de matriz de papéis, isolamento, CSRF, uploads, salvamento/envio e decisão obsoleta. Separar includes CPC de HOUSE para evitar um backend monolítico condicionado em centenas de pontos.
5. Implementar RoadRunners e configuração desabilitada, testando CPC, HOUSE, fallback, segmentação, preço e tokens sem gerar cliques pagos em produção.
6. Revisar segurança e compilar CFML no runtime do servidor. Verificar telas em desktop e mobile.
7. Entregar migration e contract tests ao operador, respeitando o fluxo de aplicação de banco já usado neste projeto. Não usar credenciais runtime para contornar exigência de DBA.
8. Após migration validada, publicar somente os arquivos desta tarefa com baseline, backup e verificação real. Habilitar CPC de banner apenas após homologação autorizada; nunca ativar anúncio real automaticamente.

## Critérios de aceite obrigatórios

- Uma conta tem o mesmo saldo nas duas telas; banner e evento debitam o mesmo ledger e orçamentos distintos.
- Dois cliques concorrentes sobre saldo insuficiente para ambos não ultrapassam o saldo. Replay do mesmo clique não gera segundo débito. Estorno é idempotente.
- HOUSE gera zero débito; remover a flag paga restaura somente o inventário HOUSE sem apagar histórico financeiro.
- Nenhum anunciante vê/edita/aprova banner de outra conta ou consegue ativar seu próprio rascunho por POST direto.
- Revisão de EVENT continua exigindo vínculo de prova; BANNER não exige nem aceita um evento fictício.
- Editar imagem/destino/orçamento/escopo invalida a aprovação; uma decisão baseada em revisão anterior não ativa a nova peça.
- Banner SC não aparece no contexto BA; nacional pode aparecer em ambos; página não selecionada não entrega a campanha. Sem UF conhecida, não entregar campanha de escopo estadual.
- Conta pendente pode preparar, mas não veicula ou gasta; pedido de acesso a conta existente permanece sem acesso antes de aprovação.
- Eventos mantêm os dois spots e o ranking publicados em 16/09; campanhas e banners existentes não são reclassificados.
- Nenhuma migration aplicada ou publicação é declarada concluída sem execução e evidência.

## Recuperação

Desligar apenas a flag de seleção CPC de banners, mantendo endpoints de recibos já emitidos, extrato, pagamentos e estornos operacionais. Restaurar runtime pelos backups se necessário; não apagar ledger, reviews ou banners. A interrupção comercial não deve impedir conciliação de cliques já entregues dentro da validade.
