# Classificação rápida dos selos — 24/11/2026

Publicada na mesma tela do Business, com entrada recomendada por `/portal/verificados/?filter_status=unclassified`.

- Categoria e botão Salvar na própria linha dos permanentes sem motivo.
- Vínculo/observação opcional; “Outro motivo” exige descrição. O histórico armazena a categoria escolhida e a referência fornecida, sem inferir motivos.
- Lote de 1 a 40 pessoas selecionadas da página. Selecionar todos é limitado à página visível; seleção não passa de uma página para outra.
- Atalho flutuante retorna ao formulário do lote. Após salvar, retorna à lista; perfis classificados saem da fila, sem excluir histórico ou alterar direitos.
- Mesmo escritor PostgreSQL da entrega anterior: confere administrador, concessão permanente e revisão. O lote usa uma transação única e ordem consistente de bloqueios; conflito desfaz todo o envio.

A migração `_codex/sql/2026-11-23_verified_classifications.sql` continua necessária e estava ausente nas verificações de 24/11. Nenhuma nova migração é exigida para o modo rápido. O proprietário foi solicitado a executá-la no DataGrip; a interface permanece com salvamento desabilitado até a disponibilidade da tabela e função.

Validação: 24 verificações nativas CFML com escritor simulado e banco real READ ONLY; PostgreSQL 16 isolado verificou sucesso do lote, rollback por conflito, permissões e invariantes; seleção individual, seleção dos 40 da página, campos opcionais e validação de “Outro” conferidos no navegador. Layout 390px sem overflow. Prévias habilitadas somente na fixture local; nenhuma classificação foi enviada a produção durante os testes.

Publicação: cinco arquivos, `services/VerifiedAdmin.cfc`, `portal/includes/verified_backend.cfm`, `portal/verificados/home.cfm`, `portal/verificados/verified.css` e `portal/verificados/verified.js`. `index.cfm` permaneceu inalterado. Compilação, hashes e proteções públicas conferidos. Backup: `/var/backups/business-verified-quick-8ufcm6ef`. Artefatos em `_codex/staging/verified-quick-20261124/`.

Não houve migração remota, alteração de selo/validade/pagamento, atribuição real de motivo, notificação, commit ou push.

Pós-publicação: lista, fila rápida, VIP, permanente e estorno renderizados pelo código publicado em fixture privada somente de leitura, todos HTTP 200. Recursos temporários desta tarefa encerrados e remoção conferida.

Após a execução do SQL pelo proprietário em 24/11/2026, a verificação somente de leitura confirmou tabela e função disponíveis, com permissões de leitura e classificação para a aplicação. A fila publicada renderizou HTTP 200, sem aviso de migração pendente, com os 40 formulários individuais e o formulário de lote habilitados. Nenhuma classificação foi enviada na verificação; havia 128 perfis pendentes, 128 permanentes e 290 anuais, totalizando 418 ativos. Não foi necessário alterar runtime nem republicar. Recibos: `migration-verification.json` e `migration-ui-verification.json` no diretório de staging desta entrega. A fixture remota temporária foi removida e sua remoção confirmada.
