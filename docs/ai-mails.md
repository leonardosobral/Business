# AI-mails — uso e operação

## Ativação pelo administrador global

1. No projeto Google Cloud `runnerhub-business`, confira se a [Gmail API está habilitada](https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=runnerhub-business). Se a tela mostrar **Gerenciar**, já está habilitada.
2. Entre como **admin global** e abra [AI-mails](https://business.roadrunners.run/administracao/ai-mails/). Clique em **Autorizar leitura do Gmail**, escolha **contato@runnerhub.run** e conceda as permissões solicitadas. O retorno usa o mesmo endereço OAuth já configurado da Agenda. Não precisa criar nova credencial.
3. Em **Configurações**, confirme o processamento das mensagens pela IA, marque **Monitoramento ativo** e salve. A autorização permite somente leitura do Gmail. Cancelar ou recusar a nova permissão preserva a conexão anterior.
4. Clique em **Atualizar agora**. O servidor coleta em lotes a cada cinco minutos; a fila é processada progressivamente. Confira separadamente **Gmail sincronizado** e **fila de análise**. Uma caixa grande leva várias execuções para concluir a carga inicial.

Se o Google bloquear a autorização, confira o [público do aplicativo](https://console.cloud.google.com/auth/audience?project=runnerhub-business) e o [acesso a dados](https://console.cloud.google.com/auth/scopes?project=runnerhub-business). O escopo é `https://www.googleapis.com/auth/gmail.readonly`. Apps realmente internos à organização Workspace têm requisitos diferentes dos externos; não altere o público apenas para contornar verificação. Referência: [verificação de escopos restritos](https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification).

## O que foi entregue

- Acesso somente para admins globais efetivos, no menu e na suíte Kanban / Agenda / Documentos / AI-mails.
- Indicador no dashboard global; cartões com prioridade, categoria, resumo, justificativa, ações sugeridas e prazos com evidência.
- Busca, filtros e visões Pendentes, Em andamento, Resolvidos e Revisão da triagem.
- Responsável compartilhado, observação, resolução/reabertura, correção manual de classificação e histórico.
- Links à conversa, mensagem de origem e busca por Message-ID no Gmail. O navegador precisa ter acesso à caixa; o token do servidor não autentica o navegador.
- Coleta incremental, fila persistente, tentativas espaçadas, processamento exclusivo e atualização por versão para preservar decisões simultâneas.
- Modelo próprio configurável, OpenAI já existente, respostas estruturadas e RAG seletivo limitado a documentos ativos/vigentes. Nenhum e-mail é incorporado ao RAG.
- Monitor não envia, não arquiva, não marca como lido e não altera etiquetas no Gmail. Anexos não são lidos.

## Padrões e cobertura

- Caixa: `contato@runnerhub.run`.
- Frequência: dois jobs a cada 5 minutos, **Coletar Gmail** e **Analisar conversas**, registrados no [gerenciador de jobs](https://business.roadrunners.run/administracao/cron-jobs/).
- Carga inicial: INBOX dos últimos 30 dias mais conversas antigas não lidas/importantes; até 100 conversas coletadas por página, sem truncamento silencioso da paginação.
- Novas conversas fora da INBOX, arquivadas automaticamente por filtros, não entram inicialmente. Conversas já acompanhadas continuam sendo atualizadas após arquivamento.
- Até duas conversas analisadas por execução, dependendo da duração; contexto textual limitado a 20 mensagens/26 mil caracteres, com aviso quando incompleto.
- Limite inicial: 100 tentativas de análise por dia, fuso de Brasília. Falhas também contam para evitar consumo sem controle. Atingir o limite preserva a fila.
- Modelo inicial: `gpt-4.1-mini`, independente do modelo configurado para a Vicky.
- Uso diário exibe tokens e estimativa de texto para GPT-4.1 mini. Referência consultada em 17/09/2026: US$ 0,40/1M entrada e US$ 1,60/1M saída. Estimativa sem desconto de cache, sem custos RAG; modelos diferentes ou falhas sem contabilização completa são sinalizados como estimativa parcial. [Preço oficial](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
- Retenção: 90 dias para textos de resolvidos e fontes indisponíveis, configurável. Pendências abertas não são expurgadas automaticamente. Após expiração, fica um registro mínimo de estado/hash para uma reconciliação não recriar a pendência. Lixeira, spam e exclusões reconciliadas removem imediatamente os textos locais. Sem acesso Google, essa reconciliação fica pendente e o painel mostra erro.
- Estado Resolvido não depende de lido/não lido no Gmail. Novo pedido recebido após a resolução pode reabrir; origem da evidência também deve ser posterior à resolução. Agradecimento simples não reabre.

## Privacidade

O corpo é lido transitoriamente para processamento e não é armazenado integralmente no Business. Segredos evidentes e CPF são minimizados no texto. Resumos também são dados privados: acesso global restrito, operações protegidas por CSRF, sem dados da caixa em logs de jobs. O processamento usa `store=false`, sem ferramentas executáveis pela IA e sem uploads da caixa ao índice. [Política de dados OpenAI](https://developers.openai.com/api/docs/guides/your-data) e [política de dados Google Workspace](https://developers.google.com/workspace/workspace-api-user-data-developer-policy).

## Publicação e validações

Publicação inicial em 17/09/2026, sem commit/push. Backup recuperável no servidor: `/var/backups/business-ai-mails-20260917-ZLvsHtup/`. Migração aditiva: `administracao/ai-mails/ai_mails_schema.sql`; nenhuma tabela antiga é removida.

Testes executados: compilação dos 19 templates ColdFusion, três testes de navegação da suíte, 30 verificações de regras/banco com transações revertidas e três classificações reais de mensagens fictícias pela OpenAI (cobrança automática, newsletter e agradecimento). Interface validada em prévia local com dados fictícios, incluindo observação, atribuição, resolução, revisão e responsividade. Os dois jobs publicados responderam HTTP 200 pelo agendador com o monitor pausado. Dados sintéticos de conversas/fila foram revertidos. Os 21 arquivos de runtime foram comparados por SHA-256 com produção, sem diferenças. Worker sem credencial: HTTP 403; página sem sessão: redirecionamento 302 para autenticação. Os quatro arquivos temporários de teste foram removidos do servidor (404 confirmado).

**Pendente de validação com a conta:** autorização Gmail, primeira coleta real, calibragem com o fluxo real da equipe e abertura das mensagens em navegador autorizado. A sessão de navegador disponível durante a entrega estava na seleção de contas, sem acesso global. Os testes não substituem essa etapa. Nenhum e-mail real foi lido na implementação.

## Manutenção e reversão

- O segredo de jobs é resolvido em tempo de execução a partir da identidade do agendador existente, nunca gravado nos endpoints ou no banco de jobs.
- Falhas aparecem no topo do módulo e no histórico dos jobs. Use Atualizar agora para antecipar a próxima coleta/retentativa; não reprocessa toda a caixa indiscriminadamente.
- Para pausar: desmarque Monitoramento ativo. Para interromper também os ticks operacionais, desative os dois jobs específicos no gerenciador.
- Para reverter runtime: pause os dois jobs, restaure somente os arquivos de `runtime-before.tgz` e o backup adicional dos três index de suíte. Não remova tabelas nem credenciais; preservar registros permite retomada segura. Retirar arquivos novos deve ser uma ação separada e deliberada.
- Scripts locais de publicação são registros da implantação, não devem ser reexecutados às cegas contra um baseline diferente. Probes temporários de teste são restritos a loopback e removidos após uso.
