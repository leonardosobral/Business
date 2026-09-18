# AI-mails — projeto para aprovação

Data: 17/09/2026. Situação: projeto aprovado e implementado. Consulte `docs/ai-mails.md` para publicação, validações e ativação pendente do Gmail. As seções abaixo preservam o projeto aprovado.

## 1. Objetivo e escopo

Criar uma central de atenção para a caixa `contato@runnerhub.run`, exclusiva dos administradores globais do Business, integrada visualmente a Kanban, Agenda e Documentos. A página proposta é `/administracao/ai-mails/`.

O administrador encontrará resumos de conversas importantes e pendências concretas: o que aconteceu, por que importa, o que precisa ser feito, eventual prazo e um link para a mensagem original no Gmail. A visualização inicial não reproduzirá toda a caixa de entrada.

Esta proposta foi preparada por inspeção do código local e documentação oficial. Não houve leitura de mensagens da conta, execução de IA sobre e-mails, mudança de permissões, criação de jobs ou publicação de funcionalidade.

## 2. Base existente confirmada no código

| Componente | Reaproveitamento previsto |
| --- | --- |
| `includes/estrutura/admin_suite_nav.cfm` e `assets/css/admin-suite.css` | Navegação e identidade visual da suíte |
| `administracao/agenda/includes/service.cfm` | Cliente Google, renovação de acesso e criptografia de credenciais |
| `Application.cfc` e OAuth da Agenda | Configuração da conta `contato@runnerhub.run` e solicitação de permissões |
| `helpdesk/includes/HelpdeskAI.cfc` | Padrões de acesso à OpenAI, consulta RAG e proteção de conteúdo |
| `services/EventDescriptionRewriteService.cfc` | Padrão existente de respostas estruturadas da IA |
| Gerenciador `/administracao/cron-jobs/` | Agendamento, execução autenticada e histórico operacional |
| `includes/backend/require_admin.cfm` | Restrição de acesso administrativo no servidor |

A autorização compartilhada atualmente solicitada pelo Business inclui identidade, Agenda, Meet e Drive. Não inclui `gmail.readonly`. A existência de login Google ou de acesso ao Gmail em outro aplicativo, como um importador, não comprova que o token desta integração possui essa permissão.

## 3. Experiência proposta

Cabeçalho com nome AI-mails, conta monitorada, estado da conexão, última sincronização concluída e quantidade aguardando análise. Ações: Atualizar agora e Configurações. Atualizar agora agenda uma coleta; a tela continua utilizável durante a análise.

Navegação da suíte: **Kanban · Agenda · Documentos · AI-mails**.

Acima da lista, indicadores clicáveis: pendências abertas, críticas/altas, aguardando resposta da equipe e prazos vencidos. Os grupos podem se sobrepor e não serão apresentados como parcelas de um mesmo total. Uma contagem separada mostrará falhas ou mensagens aguardando análise.

Lista principal de cartões compactos, ordenada por prioridade, prazo explícito e antiguidade da pendência. Em telas amplas, o cartão pode abrir um painel lateral; no celular, uma visão de detalhe em largura total.

Exemplo fictício de cartão:

```text
ALTA · Requer resposta                       Hoje, 09:12
Fornecedor solicita confirmação de quantidade
Remetente: Equipe do fornecedor · Operação de eventos

Resumo: A produção depende da confirmação da quantidade
final de kits. O remetente pediu retorno até amanhã, 12h.
Ação sugerida: Confirmar a quantidade e responder ao fornecedor.
Por que importa: Há um prazo explícito para liberar a produção.
Prazo informado: amanhã, 12h · Responsável: não atribuído

[Abrir no Gmail]  [Assumir]  [Marcar como resolvido]
```

Cada item apresenta:

- Assunto, remetente, categoria e data da última mensagem relevante.
- Resumo objetivo em português, normalmente de duas a quatro linhas.
- Tipo de atenção: responder, executar uma ação ou tomar conhecimento.
- Prioridade e justificativa curta baseada em evidência da conversa.
- Prazo quando informado; “Sem prazo informado” quando ausente.
- Próximo passo sugerido, claramente separado de ações já realizadas.
- Responsável, estado, observação interna e histórico de mudanças.
- Link para a mensagem que originou a pendência e acesso à conversa no Gmail.
- Sinalização quando a análise estiver incompleta, desatualizada ou depender de anexo.

Filtros: prioridade, estado, categoria, responsável, tipo de atenção, período e busca por remetente, assunto ou resumo. Visões: Pendentes, Em andamento, Resolvidos e Revisão da triagem. A revisão inclui mensagens consideradas sem ação e classificações incertas, para corrigir falsos negativos sem poluir a visão principal.

## 4. Unidade de trabalho e prioridades

Uma conversa do Gmail corresponde a um item, identificado por conta e `threadId`. Novas mensagens atualizam o resumo existente. Pedidos múltiplos na mesma conversa aparecem como ações no detalhe, com a prioridade mais alta aplicável ao item.

| Prioridade | Critério proposto | Apresentação |
| --- | --- | --- |
| Crítica | Incidente grave em andamento, operação bloqueada ou prazo explícito imediato com impacto relevante | Vermelho, ícone e rótulo textual |
| Alta | Resposta/decisão importante, compromisso próximo ou impacto significativo para a operação | Laranja, ícone e rótulo textual |
| Normal | Solicitação legítima que exige resposta ou ação, sem evidência de urgência | Azul, ícone e rótulo textual |
| Informativa importante | Informação relevante que merece ciência, sem tarefa identificada | Neutro, rótulo “Para ciência” |

Mensagens de rotina sem relevância ficam fora da visão principal, acessíveis em Revisão da triagem. Mensagens incertas ficam visíveis como “Revisão necessária”. Uma falha técnica nunca equivale a “Sem importância”.

A prioridade combina conteúdo, impacto, prazo, contexto da empresa e regras explícitas de remetentes/assuntos. A marca de importância do Gmail é um sinal auxiliar. “Urgente” no assunto, `no-reply`, categoria Promoções ou idioma estrangeiro não determinam o resultado isoladamente. Cobranças, falhas de pagamento, alertas operacionais e segurança também podem vir de remetentes automáticos.

Prazos extraídos exigem referência à mensagem e distinção entre texto original e data normalizada. Datas ambíguas não serão inventadas. Datas relativas usam a data da mensagem e o fuso conhecido; a interface adota Brasília. Sugestões internas de atendimento não serão exibidas como prazos pedidos pelo remetente.

## 5. Resolver, assumir e reabrir

- **Pendente → Em andamento:** um admin assume a conversa; atribuição fica visível para os demais.
- **Pendente/Em andamento → Resolvido:** ação humana, com autor, data e observação opcional. Atualização por versão impede sobrescrever uma decisão simultânea.
- **Resolvido → Pendente:** reabertura manual, ou nova mensagem recebida contendo pedido/problema relevante posterior à resolução. A interface informa o motivo da reabertura.
- Um agradecimento ou recibo automático não reabre por padrão. Se houver dúvida sobre um pedido novo, o item recebe sinalização de revisão.
- Resposta enviada pela equipe no Gmail atualiza o contexto e pode sugerir “Aguardando retorno”; não conclui automaticamente outras tarefas da conversa.
- Ler, marcar como lido ou arquivar no Gmail não equivale a resolver no AI-mails. O item continuará pendente até decisão explícita, preservando o contexto de que a mensagem saiu da caixa de entrada.
- Conversas conhecidas serão acompanhadas nas atualizações mesmo após arquivamento. Spam, lixeira e exclusão definitiva recebem tratamento próprio e indicação de fonte indisponível, evitando manter conteúdo indevidamente.

“Resolvido” é um estado interno e compartilhado do Business. Não marca como lido, não arquiva, não adiciona etiquetas e não envia resposta no Gmail. A primeira versão necessita apenas de leitura da conta Google.

## 6. Monitoramento no servidor

Proposta inicial: execução a cada **5 minutos**, 24 horas por dia, pelo mecanismo de jobs do Business. O monitor funciona com todos os navegadores fechados. O intervalo é a frequência da coleta, não garantia de tempo de análise quando houver fila ou indisponibilidade.

Na ativação, analisar as conversas da caixa de entrada dos últimos **30 dias**, incluindo lidas e não lidas. Incluir também conversas mais antigas ainda não lidas ou marcadas como importantes; apresentar a cobertura inicial e permitir ampliar o período. Processamento em lotes, com progresso explícito e sem corte silencioso quando o volume exceder o limite de um lote.

Fluxo:

```text
Gmail: novas mensagens e alterações
  → fila persistente e deduplicada
  → leitura da conversa e preparação de texto
  → análise estruturada com IA
  → validação e atualização do item
  → painel, estados compartilhados e indicadores
```

Após a carga inicial, consultar alterações por `historyId`, com paginação. Novas mensagens na INBOX entram na análise; mudanças em conversas já conhecidas atualizam seu contexto, inclusive respostas enviadas. Mensagens novas automaticamente arquivadas por filtros ficam fora do escopo inicial, salvo se integrarem uma conversa acompanhada; ampliar para etiquetas específicas será uma configuração explícita.

O cursor de coleta só avança quando os eventos estiverem persistidos na fila. Chaves únicas por conta/mensagem e por conversa/versão de análise impedem duplicatas. A aplicação grava a análise somente se a conversa ainda estiver na versão analisada, preservando resoluções e prioridades corrigidas por humanos.

Histórico expirado (404) inicia uma reconciliação controlada, sem apagar estados nem recriar todos os itens. Erros 429/5xx usam novas tentativas espaçadas. A fila tem limite por execução, controle de concorrência e recuperação após interrupção. Cada conversa é reanalisada quando seu conteúdo relevante muda; alternar lido/não lido não consome uma análise nova.

São dois trabalhos lógicos: coletor Google e processador IA, com execuções curtas e continuáveis. O histórico dos jobs registra contagens, duração e erros sanitizados, sem corpos de e-mails. O painel mostra separadamente “Gmail sincronizado” e “IA com fila/erro”.

Essa estratégia segue a [sincronização incremental documentada pelo Gmail](https://developers.google.com/workspace/gmail/api/guides/sync). Push via Pub/Sub pode ser uma evolução se houver necessidade de menor latência; exige infraestrutura adicional e renovação periódica da assinatura, conforme a [documentação de push](https://developers.google.com/workspace/gmail/api/guides/push).

## 7. Análise com IA

Reutilizar a credencial OpenAI já configurada no Business, com serviço e instruções específicos para AI-mails. O modelo será configurável e selecionado na implementação após avaliação de qualidade/custo sobre uma amostra aprovada; mudanças no modelo da Vicky não deverão alterar silenciosamente o classificador.

O resultado estruturado incluirá: relevância, prioridade, categoria, resumo, ações sugeridas, necessidade de resposta, prazo explícito, justificativa, mensagem de origem e necessidade de revisão. O servidor valida os campos e as referências antes de publicar o resumo. O padrão é suportado por [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs); formato válido não garante veracidade, portanto serão verificadas também as evidências e as regras do produto.

A análise considera a conversa recebida e as respostas da própria conta. Extrai texto das partes MIME, remove HTML ativo, imagens de rastreamento, assinaturas repetidas e histórico citado duplicado. Conversas extensas terão contexto limitado e sinalizado. Anexos não serão enviados à IA na primeira versão: seus nomes e existência ajudam a sinalizar “Conferir anexo no Gmail”, sem inventar o conteúdo.

Conhecimento institucional curado informa o contexto RunnerHub/Road Runners. A consulta RAG é seletiva, para regras e procedimentos pertinentes. E-mails privados não serão incorporados ao índice RAG compartilhado; só documentos aprovados e ativos podem ser recuperados. A análise pode continuar sem RAG quando ele não for necessário, indicando eventual limitação.

A IA classifica e sugere. O conteúdo recebido é tratado como dado externo e não pode dar instruções ao agente, abrir links, executar tarefas, mudar configurações ou concluir itens. Remetentes não serão considerados autenticados apenas por nome de exibição.

Custos: registrar modelo, tokens, volume processado e estimativa baseada na tabela vigente, com teto configurável. Quando o limite for atingido, os itens continuam na fila e o painel avisa. Não há estimativa monetária responsável antes de conhecer volume, tamanho das conversas e modelo escolhido.

## 8. Acesso Google e links para Gmail

Na ativação será necessário habilitar a [Gmail API no projeto Google Cloud](https://console.cloud.google.com/apis/library/gmail.googleapis.com) e autorizar `https://www.googleapis.com/auth/gmail.readonly` para `contato@runnerhub.run`. O escopo permite ler conteúdo; `gmail.metadata` não atende ao resumo do corpo da mensagem. Referência: [escopos do Gmail](https://developers.google.com/workspace/gmail/api/auth/scopes).

Preferência: aproveitar o cliente OAuth existente e adicionar autorização incremental para Gmail, verificando identidade e escopos concedidos antes de substituir a conexão salva. Cancelamento ou recusa de Gmail não deve invalidar Agenda, Meet ou Documentos. O painel informa capacidades autorizadas por módulo; não condiciona toda a suíte ao novo escopo.

Antes da ativação, conferir se o projeto pertence à organização Workspace e está configurado como Internal. O Gmail usa escopo restrito: as exigências de verificação e avaliação de segurança variam conforme a configuração e exceções aplicáveis. A [documentação do Google](https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification) especifica a exceção para uso interno com projeto e público corretos. Não foi inspecionada a configuração atual do Cloud nesta etapa.

O link Gmail será construído a partir dos identificadores retornados pelo Google, com seleção de conta e fallback de busca pelo cabeçalho Message-ID. A abertura deve ser validada em navegador com uma e com várias contas Google conectadas, inclusive para conversa arquivada. A sessão OAuth do servidor não autentica o navegador do administrador: ele precisa ter acesso à caixa no Gmail para abrir a origem.

## 9. Dados, privacidade e permissões

Somente admins globais com contexto administrativo efetivo podem consultar conteúdo e operar estados. Validação no servidor em páginas e endpoints; contas clientes e usuários comuns não recebem dados ou contagens. Pedidos de mudança exigem CSRF e registram o autor. O worker possui autenticação própria, sem depender de sessão de navegador.

Persistência proposta:

- Configuração: conta, ativação, frequência, janela inicial, regras, modelo e controle de consumo.
- Conversas: IDs de origem, classificação, resumo, ações, estado, responsável, observação, versões e datas.
- Controle de mensagens: IDs, hashes e versões suficientes para deduplicação e rastreio.
- Fila: tarefas de coleta/análise, tentativas, agendamento e erro sanitizado.
- Auditoria: mudanças de estado, responsável e prioridade, sem duplicar os textos em logs.

O corpo integral é obtido para análise com minimização e não vira arquivo permanente do Business. Resumos também são dados da conta: sua retenção e a de caches seguirá política definida na ativação e os requisitos do Google; prever expurgo e reconciliação de exclusões. Credenciais seguem criptografadas e não são expostas ao frontend.

O envio à OpenAI é parte do processamento proposto e precisa estar descrito na ativação e política de uso da integração. Usar `store=false`, sem upload permanente das mensagens e sem adesão ao compartilhamento para treinamento. `store=false` não significa retenção zero para todos os registros do provedor: há controles próprios para monitoramento de abuso, conforme a [documentação de dados da OpenAI](https://developers.openai.com/api/docs/guides/your-data). O uso deve atender também à [política de dados Google Workspace](https://developers.google.com/workspace/workspace-api-user-data-developer-policy).

## 10. Primeira entrega e evoluções

Primeira entrega proposta: acesso Gmail, monitor periódico, análise de conversas, cartões de resumos priorizados, filtros e busca, links de origem, resolução/reabertura, responsável e observação, revisão da triagem, histórico operacional e indicadores. Acrescentar no dashboard global um resumo de pendências AI-mails com link para a fila; contagem por conversa, sem duplicar mensagens do mesmo assunto.

Evoluções opcionais: adiar lembretes, criar tarefa no Kanban ou compromisso na Agenda por comando humano, rascunhos de resposta revisáveis, leitura seletiva de anexos, regras mais avançadas e push Pub/Sub. Envio automático de e-mails não faz parte deste projeto.

## 11. Sequência de implementação após aprovação

1. Validar autorização Google, conta, políticas e modelo; fechar as configurações iniciais sugeridas.
2. Criar tabelas, controle de acesso, fila e fluxo OAuth com migração aditiva e reversível.
3. Implementar sincronização incremental, recuperação de falhas e análise estruturada.
4. Construir tela da suíte, filtros, estados compartilhados, links e resumo no dashboard.
5. Validar com mensagens de teste e, após autorização de acesso, amostra real; calibrar classificação antes de ocultar rotinas automaticamente.
6. Publicar apenas o escopo aprovado com baseline, backup e validação real; ativar o job após a autorização Gmail e confirmar execuções sem painel aberto.

## 12. Critérios de aceite

- A carga inicial informa o que cobre e seu progresso; não deixa mensagens de fora silenciosamente.
- Mensagem importante lida no Gmail continua elegível; newsletters rotineiras não dominam a tela.
- Cobrança e alerta automático relevantes não são descartados por serem `no-reply`.
- Atualizações da mesma conversa produzem um só item, com referência correta e contexto das respostas.
- Resolver em um navegador atualiza a visão dos demais admins; reprocessar a mesma mensagem não reabre o item.
- Pedido novo relevante pode reabrir; agradecimento simples não reabre por padrão.
- A equipe consegue corrigir classificação e recuperar um falso negativo na revisão da triagem.
- Sem autorização ou com erro de IA, a tela distingue fila/erro de “nenhuma pendência”.
- O monitor coleta com a interface fechada; retoma após falha sem duplicar itens.
- Prazo e justificativa podem ser conferidos na mensagem original; o sistema não inventa conteúdo de anexo.
- Links abrem a origem correta no Gmail quando o navegador tem acesso à conta.
- Admins de contas e usuários comuns não acessam o módulo, seus endpoints ou dados.
- Nenhuma ação de resolver, assumir ou reanalisar altera a caixa Gmail.

Decisões sugeridas para aprovação: intervalo de cinco minutos; carga inicial de trinta dias mais antigas não lidas/importantes; operação por conversa; estado Resolvido compartilhado; Gmail somente leitura; anexos abertos no Gmail; RAG institucional seletivo.
