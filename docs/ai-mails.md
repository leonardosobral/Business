# AI-mails — uso e operação

## Ativação pelo administrador global

1. No projeto Google Cloud `runnerhub-business`, confira se a [Gmail API está habilitada](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=runnerhub-business). Se a tela mostrar **Gerenciar**, já está habilitada.
2. Entre como **admin global** e abra [AI-mails](https://business.roadrunners.run/administracao/ai-mails/). Clique em **Autorizar leitura do Gmail**, escolha **contato@runnerhub.run** e conceda as permissões solicitadas. O retorno usa o mesmo endereço OAuth já configurado da Agenda. Não precisa criar nova credencial.
3. Em **Configurações**, confirme o processamento das mensagens pela IA, marque **Monitoramento ativo** e salve. A autorização permite somente leitura do Gmail. Cancelar ou recusar a nova permissão preserva a conexão anterior.
4. Clique em **Atualizar agora**. O servidor consulta o Gmail a cada cinco minutos e considera somente mensagens recebidas depois do corte exibido no painel. Não existe carga retroativa da caixa.

Se o Google bloquear a autorização, confira o [público do aplicativo](https://console.cloud.google.com/auth/audience?project=runnerhub-business) e o [acesso a dados](https://console.cloud.google.com/auth/scopes?project=runnerhub-business). O escopo é `https://www.googleapis.com/auth/gmail.readonly`. Apps realmente internos à organização Workspace têm requisitos diferentes dos externos; não altere o público apenas para contornar verificação. Referência: [verificação de escopos restritos](https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification).

## O que foi entregue

- Acesso somente para admins globais efetivos, no menu e na suíte Kanban / Agenda / Documentos / AI-mails.
- Indicador no dashboard global; cartões com prioridade, categoria, resumo, justificativa, ações sugeridas e prazos com evidência.
- Busca, filtros e visões Pendentes, Em andamento, Resolvidos e Revisão da triagem.
- Responsável compartilhado, observação, resolução/reabertura, correção manual de classificação e histórico.
- Análise em lote: seleção de 2 a 50 conversas já analisadas, síntese de padrão/causa provável, impacto, duplicidades, plano com evidências e vínculo persistente entre o lote e cada conversa. Responsável, prioridade e status podem ser aplicados ao conjunto; a observação do lote não sobrescreve as individuais.
- Links à conversa, mensagem de origem e busca por Message-ID no Gmail. O navegador precisa ter acesso à caixa; o token do servidor não autentica o navegador.
- Coleta incremental, fila persistente, tentativas espaçadas, processamento exclusivo e atualização por versão para preservar decisões simultâneas.
- Modelo próprio configurável, OpenAI já existente, respostas estruturadas e RAG seletivo limitado a documentos ativos/vigentes. Nenhum e-mail é incorporado ao RAG.
- A síntese dos lotes usa [Structured Outputs da Responses API](https://developers.openai.com/api/docs/guides/structured-outputs), com esquema estrito, referências limitadas às conversas selecionadas e `store=false`.
- Monitor não envia, não arquiva, não marca como lido e não altera etiquetas no Gmail. Anexos não são lidos.

## Padrões e cobertura

- Caixa: `contato@runnerhub.run`.
- Frequência: dois jobs a cada 5 minutos, **Coletar Gmail** e **Analisar conversas**, registrados no [gerenciador de jobs](https://business.roadrunners.run/administracao/cron-jobs/).
- Início do monitor: o `historyId` atual do Gmail e o horário de corte são gravados juntos. Mensagens anteriores ao corte não entram na fila nem são analisadas.
- Novas mensagens recebidas em conversas já acompanhadas continuam atualizando o resumo. Alterações de etiqueta e mensagens enviadas sem novo recebimento não fazem conteúdo anterior atravessar o corte.
- Até duas conversas analisadas por execução, dependendo da duração; contexto textual limitado a 20 mensagens/26 mil caracteres, com aviso quando incompleto.
- Limite inicial: 100 tentativas de análise por dia, fuso de Brasília. Falhas também contam para evitar consumo sem controle. Atingir o limite preserva a fila.
- Análises manuais em lote têm cota separada de 20 tentativas por dia. Assim, a carga histórica do monitor não bloqueia o trabalho do atendente; falhas também contam nessa cota.
- Modelo inicial: `gpt-4.1-mini`, independente do modelo configurado para a Vicky.
- Uso diário exibe tokens e estimativa de texto para GPT-4.1 mini. Referência consultada em 17/09/2026: US$ 0,40/1M entrada e US$ 1,60/1M saída. Estimativa sem desconto de cache, sem custos RAG; modelos diferentes ou falhas sem contabilização completa são sinalizados como estimativa parcial. [Preço oficial](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
- Retenção: 90 dias para textos de resolvidos e fontes indisponíveis, configurável. Pendências abertas não são expurgadas automaticamente. Após expiração, fica um registro mínimo de estado/hash para uma reconciliação não recriar a pendência. Lixeira, spam e exclusões reconciliadas removem imediatamente os textos locais. Sem acesso Google, essa reconciliação fica pendente e o painel mostra erro.
- Estado Resolvido não depende de lido/não lido no Gmail. Novo pedido recebido após a resolução pode reabrir; origem da evidência também deve ser posterior à resolução. Agradecimento simples não reabre.

## Privacidade

O corpo é lido transitoriamente para processamento e não é armazenado integralmente no Business. Segredos evidentes e CPF são minimizados no texto. Resumos também são dados privados: acesso global restrito, operações protegidas por CSRF, sem dados da caixa em logs de jobs. O processamento usa `store=false`, sem ferramentas executáveis pela IA e sem uploads da caixa ao índice. [Política de dados OpenAI](https://developers.openai.com/api/docs/guides/your-data) e [política de dados Google Workspace](https://developers.google.com/workspace/workspace-api-user-data-developer-policy).

A análise de lote não volta a carregar o corpo da mensagem: envia apenas os resumos e metadados mínimos já disponíveis no AI-mails. A instrução opcional do administrador é tratada como contexto, não como autorização para executar ações.

## Publicação e validações

Publicação inicial em 17/09/2026, sem commit/push. Backup recuperável no servidor: `/var/backups/business-ai-mails-20260917-ZLvsHtup/`. Migração aditiva: `administracao/ai-mails/ai_mails_schema.sql`; nenhuma tabela antiga é removida.

Testes executados: compilação dos 19 templates ColdFusion, três testes de navegação da suíte, 30 verificações de regras/banco com transações revertidas e três classificações reais de mensagens fictícias pela OpenAI (cobrança automática, newsletter e agradecimento). Interface validada em prévia local com dados fictícios, incluindo observação, atribuição, resolução, revisão e responsividade. Os dois jobs publicados responderam HTTP 200 pelo agendador com o monitor pausado. Dados sintéticos de conversas/fila foram revertidos. Os 21 arquivos de runtime foram comparados por SHA-256 com produção, sem diferenças. Worker sem credencial: HTTP 403; página sem sessão: redirecionamento 302 para autenticação. Os quatro arquivos temporários de teste foram removidos do servidor (404 confirmado).

Análise em lote publicada em 19/09/2026, sem commit/push. Backup recuperável no servidor: `/var/backups/business-ai-mail-batches-20260919-s2WyTQ/`. A migração criou apenas três tabelas novas (`tb_ai_mail_batches`, `tb_ai_mail_batch_items` e `tb_ai_mail_batch_audit`) e acrescentou à tabela de uso a coluna que separa as cotas manual e automática. Foram validados compilador ColdFusion, JavaScript, consistência estática da interface/API, migração idempotente e dez cenários transacionais com rollback: estrutura, cota separada, seleção mínima, vínculo, evidências, início, prioridade coletiva, observação independente, resolução com marco de novas mensagens e listagem. A tela real autenticada exibiu seleção, formulário, visão, síntese, evidências e controles de um lote de 30 conversas sem erros de JavaScript. Os testes automatizados não deixaram dados sintéticos persistidos. Os arquivos publicados foram comparados por SHA-256, e o probe temporário foi removido (HTTP 404 confirmado).

Corte “a partir de agora” publicado em 19/09/2026, sem commit/push. Backup recuperável no servidor: `/var/backups/business-ai-mail-start-now-20260919-pLgOvO/`. Às 13:34 (America/Sao_Paulo), o monitor foi reposicionado no `historyId` 5219555: 16.933 conversas que ainda aguardavam análise foram retiradas da fila, enquanto 199 análises já concluídas e os sete lotes existentes (133 vínculos) foram preservados. A regressão transacional comprovou que uma conversa anterior ao corte é descartada antes da chamada à IA e que uma conversa posterior continua sendo analisada. Placeholders históricos sem análise deixaram de aparecer como pendência, sem remoção dos resumos concluídos. A cota automática também passou a contar a partir do corte no primeiro dia, preservando os 100 registros de consumo anteriores; assim, uma mensagem nova não precisa esperar a virada do dia. O painel autenticado confirmou dois jobs ativos, fila zero, cota atual 0/100, corte visível e ausência da configuração de carga histórica.

**Pendente de acompanhamento:** confirmar a primeira nova mensagem recebida depois do corte e calibrar a classificação com o fluxo real da equipe. A conta Gmail está autorizada e o painel autenticado foi validado; a publicação do novo corte não abriu o corpo de nenhuma mensagem real adicional.

## Manutenção e reversão

- O segredo de jobs é resolvido em tempo de execução a partir da identidade do agendador existente, nunca gravado nos endpoints ou no banco de jobs.
- Falhas aparecem no topo do módulo e no histórico dos jobs. Use Atualizar agora para antecipar a próxima coleta/retentativa; não reprocessa toda a caixa indiscriminadamente.
- Se o histórico incremental do Gmail expirar, o monitor registra um novo corte no momento da reconexão. Ele não volta a pesquisar mensagens antigas para reconstruir o período perdido.
- Para pausar: desmarque Monitoramento ativo. Para interromper também os ticks operacionais, desative os dois jobs específicos no gerenciador.
- Para reverter runtime: pause os dois jobs, restaure somente os arquivos de `runtime-before.tgz` e o backup adicional dos três index de suíte. Não remova tabelas nem credenciais; preservar registros permite retomada segura. Retirar arquivos novos deve ser uma ação separada e deliberada.
- Scripts locais de publicação são registros da implantação, não devem ser reexecutados às cegas contra um baseline diferente. Probes temporários de teste são restritos a loopback e removidos após uso.
