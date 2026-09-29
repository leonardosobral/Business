# CRM interno — evolução comercial

Status: R1–R5, R7 e R8 implementados e publicados em 24/09/2026. Em 25/09/2026, o usuário priorizou o resultado de campanhas para o Todo Santo Dia, a oferta atual. R6 passa a distinguir início de inscrição próprio de pagamento comprovado; auditoria em `docs/crm-interno-conversoes-fonte.md`. O ponto de partida abaixo descreve o estado anterior à execução.

## Objetivo
Transformar a segmentação já publicada em uma rotina comercial: entender o usuário, identificar uma oportunidade, organizar o atendimento, revisar a campanha e medir resultados comprovados.

## Ponto de partida verificado
- 15 públicos salvos; filtros próprios de cadastro, geografia, idade, resultados, inscrições, acessos identificados e contato.
- Lista com contagens e busca; usuários ao selecionar público; criação/edição em modal com rascunho separado.
- Campanhas revisadas e versionadas para notificação, e-mail e card. Descadastro e limite entre e-mail/notificação já existem.
- A ficha atual mostra perfil básico, agenda/resultados e contatos; ainda não apresenta uma linha do tempo completa.
- `CrmTrackingService.report()` declara entrega externa, abertura e conversão como não integradas. Não apresentar essas capacidades como prontas.
- Última suíte de domínio registrada: 91 verificações. Publicação do modal: `/var/backups/crm-interno.ea2ebfb333992a52`. Conferir baseline novamente antes de executar.

## Requisitos
| ID | Entrega | Comportamento esperado |
|---|---|---|
| R1 | Elegibilidade por canal | Público selecionado mostra total, aptos na consulta e exclusões para cada canal, horário e motivos. Não constitui autorização de envio. |
| R2 | Ficha lateral | Perfil, inscrições, resultados, acessos próprios, preferências e interações em uma lateral, mantendo público e paginação. |
| R3 | Oportunidades | Responsável, interesse, estágio, próxima ação, prazo e histórico por pessoa. Nenhum contato automático. |
| R4 | Sugestões comerciais | Regras explicáveis sugerem ações e permitem preparar rascunhos; não prometem interesse real nem probabilidade de compra. |
| R5 | Evolução dos públicos | Contagens históricas, entradas/saídas e sobreposição. Mudança de regra é separada de mudança da base. |
| R6 | Conversões | Relacionar início de inscrição próprio no Todo Santo Dia a campanhas com objetivo explícito, evento imutável e atribuição por clique registrado. Pagamento e valor continuam métricas separadas, dependentes de fonte financeira comprovada. |
| R7 | Cobertura dos dados | Informar preenchimento e cobertura temporal dos campos/fontes, sem tratar ausência como inatividade. |
| R8 | Planejamento | Calendário e conflitos de contato planejado; avisos não substituem os bloqueios existentes de envio. |

## Decisões de produto
- Ordem: fase 1 (R1/R2/R7), fase 2 (R3/R4), fase 3 (R5/R8), fase 4 (R6).
- Oportunidades: Novo → Em contato → Interessado → Convertido ou Encerrado. Reabertura é explícita e auditada. Convertido manualmente não gera receita comprovada.
- Responsáveis continuam restritos a administradores/desenvolvedores ativos. Abrir acesso para equipe comercial com outros papéis é uma mudança separada de permissões.
- Sugestões iniciais usam regras e modelos editáveis, sem modelo preditivo ou geração automática de campanhas.
- Calendário interno de campanhas utiliza os registros do CRM; não depende de Google Calendar.
- Comparação diária só afirma entradas/saídas entre duas fotografias completas da mesma versão. Não haverá histórico retroativo inventado.
- Fase 4 começa pela validação do CRM existente de inscrições/pedidos (`crm.tb_crm_*`). Importação e vínculo aproximado de pessoa não bastam para comprovar receita atribuída a uma campanha.

## Restrições globais
- Business opera a interface; RoadRunners mantém identidade, públicos, elegibilidade, campanhas e histórico central em `crm_interno`.
- Preservar ADMIN/DEV, contexto real, assinatura HMAC, CSRF, auditoria e preferências comerciais existentes.
- Permanecem revisão manual, fotografia de destinatários e revalidação antes da entrega; não ampliar uma campanha já confirmada.
- E-mail/notificação mantêm intervalo mínimo de 7 dias; cards mantêm limite atual de 3 sessões/dia por entrega, com dispensa por campanha.
- Não usar dados do Strava nem indicadores derivados na segmentação ou em sugestões comerciais deste plano.
- Inscrições próprias são permitidas; não inferir treino, distância escolhida, compra ou consentimento sem fonte correspondente.
- Mudanças de banco são aditivas; nenhuma migração destrutiva, credencial, permissão, commit, branch, push ou PR está autorizada por este plano.
- Publicar runtime de cada fase concluída após testes, baseline e backup, conforme preferência já registrada.
- Não enviar campanhas reais para validar desenvolvimento. Testes usam dados sintéticos; verificações de produção são de leitura.

## Fora desta evolução inicial
WhatsApp/SMS, compra de leads, campanhas automáticas por gatilho, pontuação preditiva, rastreamento médico/lesões, quilometragem de tênis do Strava, nova gestão de permissões e integração direta com checkout ainda não identificado.

## Critério global de conclusão
Cada fase funciona sozinha, passa por testes de domínio e UI, preserva o fluxo público → usuários → modal e tem publicação verificada e instrução de reversão. A fase 4 só é concluída quando um evento próprio de início de inscrição é capturado no fluxo real, deduplicado e exibido no relatório da campanha. Uma tela vazia ou fixture não conclui a integração. A medição financeira permanece indisponível até produtor comprovado.

### Ajuste de R6 — Todo Santo Dia (25/09/2026)

O evento primário é **primeiro início de inscrição autenticado** no Todo Santo Dia. O formulário existente grava `public.desafios.data_inscricao` antes do pagamento e pode alterá-la em nova tentativa; `status='C'` não tem horário próprio nem comprova sozinho captura financeira. Portanto, R6 não chama esse evento de inscrição concluída, compra ou receita. O serviço registra uma ocorrência nova e imutável apenas quando não havia inscrição prévia desse usuário no desafio. Tentativas repetidas e inscrições anteriores à ativação não viram conversões retroativas.

Uma revisão de campanha só participa da atribuição quando seu objetivo salvo é `todosantodia_signup` e seu destino é a página do desafio. O evento guarda o último clique **registrado** da mesma pessoa nos sete dias anteriores, dentro da janela da revisão; cliques de teste e campanhas sem esse objetivo não concorrem. Sem clique elegível, o início permanece sem campanha. O vínculo é uma associação temporal observada, não prova de causalidade ou de clique humano. O relatório mostra contagem de pessoas com início atribuído e data de início da cobertura, sem valor monetário. A confirmação de pagamento, VIP/upgrade e estornos continuam na trilha financeira separada, ainda desabilitada.
