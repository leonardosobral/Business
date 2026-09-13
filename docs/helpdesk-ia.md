# Respostas com IA no Help Desk

## Como usar

1. Abra um chamado no [Help Desk do Business](https://business.roadrunners.run/helpdesk/), como administrador global.
2. Opcionalmente, expanda **Orientar a IA** e informe fatos já confirmados ou o foco desejado. Não informe senhas, documentos ou tokens.
3. Clique em **Criar resposta com IA**. A geração pode levar até 90 segundos.
4. Com o editor vazio, o rascunho entra em **Nova mensagem**. Se já houver texto ou você escrever durante a geração, aparece uma sugestão separada: **Usar sugestão no editor** exige confirmação antes de substituir seu texto.
5. Revise fatos, tom e orientações. **Recuperar texto anterior** desfaz a aplicação da sugestão. O único comando que envia a mensagem continua sendo **Enviar resposta**.

Não há configuração manual adicional para o ambiente de produção validado. A integração e a base já existentes foram reutilizadas.

## Fontes e limites

- Assunto, setor, status e mensagens públicas do chamado selecionado. Não consulta outros chamados, perfis, resultados, pagamentos nem atividades do solicitante.
- Abertura e últimas 39 mensagens, até 32.000 caracteres no histórico, com até 4.000 por mensagem. A interface avisa quando o histórico foi reduzido.
- Guia de atendimento curado a partir do FAQ, documentação operacional e fluxos implementados. Não envia arquivos de código, configurações ou segredos como conhecimento.
- Base RAG da Vicky: busca semântica no vector store configurado. Apenas trechos de documentos marcados como `active`, com vigência nula ou já iniciada, podem chegar ao modelo. Regulamentos de eventos exigem referência ao evento na consulta.
- A consulta busca até 50 resultados e seleciona até oito trechos aplicáveis, de até 3.000 caracteres cada. “Consultar a base” não significa enviar todos os documentos integralmente em cada geração.
- A interface identifica o contexto consultado, não promete que cada documento listado fundamenta cada frase. Se não houver trecho aplicável, apresenta um aviso. Falha na consulta ao provedor bloqueia a geração, sem substituir o texto.
- A qualidade depende do conhecimento disponível e da revisão do atendente. A IA não confirma correções nem executa operações.

## Integração e segurança

- Chave existente: `APPLICATION.vickyKnowledge.apiKey`, inicializada pelo Business a partir do ambiente/configuração local.
- Modelo e diretrizes: `tb_vicky_config`. Vector store: `tb_vicky_knowledge_config`. Documentos autorizados: `tb_vicky_documento`.
- API OpenAI: busca semântica seguida de Responses, com `store:false`, sem ferramentas de execução. Referência oficial: [Retrieval](https://developers.openai.com/api/docs/guides/retrieval).
- Endpoint `POST /helpdesk/ai-draft.cfm`: identidade validada no servidor, admin global consultado no banco, CSRF e verificação de origem. Não inclui o backend de mutações do helpdesk.
- Limite de 20 tentativas por operador/hora, uma geração simultânea, mantido em memória da aplicação (reinício o reinicializa).
- Retorno JSON sem cache. Rascunhos não são gravados no banco nem enviados ao solicitante. Logs de falha contêm somente etapa/status/tipo, sem mensagens, documentos ou credenciais.
- E-mails, padrões de CPF e credenciais reconhecíveis são reduzidos antes da chamada. Esta redução não é uma garantia de anonimização: não inserir dados sensíveis na orientação.
- Uma atualização do chamado durante a geração invalida o rascunho. O texto já escrito no navegador permanece intacto.
- Nenhum acesso adicional para admins de conta ou usuários comuns; interface ausente no modo Suporte.

## Arquivos e validação

Runtime: `helpdesk/home.cfm`, `helpdesk/ai-draft.cfm`, `helpdesk/includes/ai-editor.cfm`, `helpdesk/includes/HelpdeskAI.cfc`, `helpdesk/assets/ai-draft.js`.

Regressão local: `node --test _codex/tests/helpdesk-ai.test.cjs`. Compilação de quatro arquivos CFML no ColdFusion do servidor, fora do webroot. Verificação HTTP de método inválido (405) e ausência de sessão (401). Validação autenticada gera rascunho real sem enviar resposta.

Backup recuperável em produção: `/var/backups/business-helpdesk-ai.psFjhh/baseline/`. Contém a página original e a versão inicial do endpoint/serviço encontrada no servidor. As versões finais validadas ficam em `candidate/`. O script de implantação exige hashes do baseline e publica somente o escopo; não é uma rotina genérica para reexecução.

Rollback: após comparar o runtime com `candidate/` para descartar alterações posteriores, restaurar atomicamente `baseline/helpdesk/home.cfm` (remove o botão) e as duas versões iniciais do serviço/endpoint. Os dois arquivos novos de editor/JavaScript podem permanecer sem referência; não é necessário apagá-los nem alterar banco, credenciais ou permissões.
