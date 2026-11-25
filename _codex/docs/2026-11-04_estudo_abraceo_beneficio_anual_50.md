# Primeiro acesso ABRACEO — benefício anual de 50%

Correção solicitada e publicada em 04/11/2026. Quem resgata o voucher da campanha abraceo-primeiro-acesso passa a registrar, em sua conta pessoal, elegibilidade à compra antecipada do anual de 2026 com 50% de desconto. O fluxo por CNPJ, que também resgata ou cria um voucher interno, segue a mesma regra.

## Regra e persistência

A campanha 27 foi atualizada de 0% para 50%, vinculada ao produto anual-2026 (ID 2, ANUAL, 2026), com avanço da versão 1 para 2 e evento imutável CAMPAIGN_ANNUAL_BENEFIT atribuído ao administrador responsável. Estado ACTIVE, códigos, destinatários, vencimentos e acessos operacionais preservados.

A elegibilidade é gravada em estudo.beneficios como ELIGIBLE, percentual 50, produto anual e acesso de origem. A chave única acesso_id impede repetição por resgate; benefícios de origens independentes não representam descontos acumuláveis. Um novo método comum ensureAnnualBenefit valida identidade pessoal, titularidade do acesso, resgate ativo e produto anual do mesmo ano; voucher é bloqueado antes do acesso/campanha, preservando a ordem de locks de resgate/revogação. Benefício revogado não é reativado. O evento ANNUAL_EARLY_PURCHASE_BENEFIT registra a criação.

StudyAccess.redeem usa a regra comum tanto no novo resgate quanto ao reapresentar um voucher já resgatado. FirstAccess.confirm a reutiliza no CNPJ e retorna o benefício na confirmação. O caminho CNPJ aceita a configuração anterior e a nova, permitindo publicar o código antes da alteração transacional da campanha. A tela inicial apresenta o benefício, e o sucesso do primeiro acesso confirma seu registro, com link para Biblioteca → Edição anual.

## Estado real e correção retroativa

Antes da alteração: 95 vouchers READY, zero resgates/acessos desta campanha. A transação foi preparada para preencher benefícios ausentes de acessos ACTIVE com voucher REDEEMED da mesma conta, sem duplicar nem reativar revogados. Na aplicação real, o backfill criou zero registros porque não havia resgates anteriores.

Após a aplicação: 95 vouchers prontos com as mesmas identidades e vencimentos; campanha 50% para anual-2026; zero acessos ativos sem registro de benefício; nenhum acesso de leitura do anual concedido. Os benefícios surgirão conforme os resgates. O anual permanece DRAFT e será comprado separadamente; oferta/checkout e datas continuam na preparação da edição anual.

## Arquivos e publicação

Quatro arquivos Business: estudos/includes/StudyAccess.cfc, estudos/includes/FirstAccess.cfc, estudos/primeiro-acesso/index.cfm e estudos/primeiro-acesso/primeiro-acesso.js. Os métodos de notebook, leitura e checklist posteriores a requestAccess em StudyAccess foram preservados integralmente. Não houve alterações em queries, congelamentos, autenticação ou papéis das empresas.

Backup recuperável de runtime: /var/backups/business-abraceo-annual-benefit-20261104/baseline. Preflight e recibo de dados no mesmo diretório pai: benefit-before.json e benefit-update.json. Ordem executada: baseline, testes, compilação, publicação de código compatível com ambas as configurações, transação da campanha/backfill, verificação e sincronização local. Um rollback isolado para o código antigo de CNPJ (que exigia 0%) é incompatível com a campanha em 50%; qualquer recuperação posterior deve preservar os benefícios adquiridos e usar código compatível, preferindo correção para frente.

## Testes executados

- Componentes candidatos isolados, com dados de teste em transações revertidas: voucher novo, resgate repetido, primeiro acesso com voucher, CNPJ com novo voucher interno e CNPJ reutilizando convite nominal READY; todos registraram um único benefício de 50%.
- Reparo de acesso previamente resgatado sem benefício e transição de 0% para 50%; benefício revogado preservado; voucher expirado/revogado, outro e-mail, tentativa de benefício em outra conta e identidade ausente bloqueados. O desconto não concedeu leitura gratuita do anual.
- Ensaio do operador de dados com um acesso sem benefício e outro revogado: um benefício preenchido, revogado mantido, tudo revertido e fixtures ausentes depois.
- JavaScript validado por node --check, CFML compilado e quatro hashes de runtime conferidos. Fingerprints dos 95 vouchers preservados.
- HTTP: primeiro acesso 200, APIs GET sem contexto de conta 403/POST sem sessão 401, JS 200. Chrome: campanha ativa exibiu 50% na gestão; mensagem de benefício conferida em desktop 1408 px e celular 390 px, sem transbordamento.

## Central de lançamento

Atualizadas por revisão esperada as observações de piloto, contrato-abraceo, liberacao e venda-anual: retirado o desencontro de 0% como pendência, registrada a correção de 04/11 e mantidos o piloto real, a aprovação contratual, a decisão de acesso da imprensa e a integração do checkout anual. Os quatro novos eventos de acompanhamento são 539–542. Nenhuma etapa foi marcada como validada e nenhum responsável foi alterado.

Evidências, operadores e provas em _codex/staging/abraceo-beneficio-anual-20261104/. As abas próprias 283508649 e 283508654 foram encerradas e suas ausências confirmadas; viewport restaurado e pasta temporária de imagens removida. Componentes de teste e pontes locais removidos pelos blocos finally; nenhum servidor de teste iniciado. Nenhum convite ou mensagem foi enviado.
