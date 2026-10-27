# Vicky Brasil Gigante Implementation Plan

> Execução inline com executing-plans/TDD; pedido explícito implementar/testar/publicar, sem nova pausa de aprovação.

**Goal:** Ativar lembrete D−7 do Brasil Gigante nos dois canais, gerenciado no Business.
**Architecture:** Gerador específico no RR seleciona inscritos e etapas oficiais e usa fila existente; Business acrescenta a regra e seus templates; serviço respeita o modelo Meta real.
**Tech Stack:** CF2025, PostgreSQL, WhatsApp Cloud API existente.
**Spec:** docs/superpowers/specs/2026-10-24-vicky-brasil-gigante-design.md

## Global Constraints
- Sem IA, cron novo, DDL, credenciais novas, mudança de consentimento ou disparo manual real de teste.
- Todos os inscritos válidos, sem agenda obrigatória; D−7 em America/Sao_Paulo; não retroativo; sem duplicação atleta/etapa/canal.
- Texto/modelo exatos do spec; verificar parâmetros aprovados antes de ativar WhatsApp.
- Preservar alterações locais/publicadas de outras frentes; não fazer operações Git de escrita.

## Review Focus
- Inscrição duplicada, agregador duplicado, outro desafio e evento fora do D−7 não ampliam o público.
- Revogação de consentimento, saída do circuito e desativação da regra antes da entrega devem impedir envio.
- Worker repetido/concorrente não duplica jobs; atraso/horário de silêncio não gera disparos noturnos.
- Template sem parâmetros não pode receber o parâmetro de evento usado por outras regras.
- Gerenciador salva apenas a regra permitida, mantendo autorização e regras antigas.

## Tasks
- [x] 1. Levantar schema real, público, etapas, cron e modelo Meta em leitura; TDD de seleção D−7 e elegibilidade com fixtures SQL/CF sem envios; implementar gerador RR.
- [x] 2. TDD do orquestrador/payload e render/salvamento gerenciador; implementar regra/templates idempotentes e interface Business.
- [x] 3. Revisão independente única, regressões, publicação CAS com backups, instalar regra inicialmente desativada, validar configuração/modelo/render e ativar. Conferir agendador existente e não executar envios de teste.

## Ledger
- Execução no checkout atual pedida pelo usuário; não criar branch/worktree nem commit porque operações Git de escrita não foram autorizadas. Mudanças pendentes de aquisição de usuários e RR comparador são alheias e serão preservadas.
- Interfaces compartilhadas: Task 1 produz candidatesSql/generate e elegibilidade; Task 2 integra ao run e utiliza payload sem alterar regras existentes; Task 3 verifica os mesmos candidatos e hashes antes de ativar.
- Meta consultada em leitura: `atualize_cbg` APPROVED, pt_BR, sem variáveis, com botão URL estático. Payload sem components dinâmicos, regressão dos modelos anteriores com parâmetro de evento.
- Baseline RR: produção usa VickyMetaWhatsappServiceV2, local tinha V3 antes desta tarefa. Publicação aplica apenas este delta preservando V2; não publica a troca alheia V3. Baseline Business dos dois arquivos corresponde ao local anterior.
- Testes RED/GREEN observados: ausência de componente; geração sem novo público; gerenciador sem quinta regra; adiamento sem fuso explícito. Testes de fila gravam até dois jobs em transação revertida, sem chamar worker ou enviar mensagens.
- Revisão independente única: nenhum bloqueio. Evidências de produção, navegador, cron, backups e modelo são verificadas pelo implementador, não inferidas da revisão. Restrição única assegura fila sem duplicação concorrente; não se promete entrega externa exatamente uma vez em falha de transporte.
- Silêncio termina no dia seguinte quando necessário; jobs já gerados podem ser entregues após D−7, ainda antes da prova, sem gerar retroativos. Revalidação impede envio após saída/revogação/regra desativada ou alteração da data da etapa.
- Detalhe de fuso reforçado após revisão: UTC ISO explícito no adiamento, convertido para timestamptz no PostgreSQL; teste RED/GREEN cobre deriva de fuso JDBC e não consumo de tentativas.
- Primeiro ciclo real: 5.861 jobs (5.860 web + um WhatsApp); 19 web entregues inicialmente. Diagnóstico comprovou configuração global `proactiveProvider=manychat`, legado desabilitado, Meta ativo e vínculo Meta válido. Corrigido roteamento apenas do Brasil Gigante para Meta, na geração, revalidação, lookup de vínculo e entrega; demais regras preservam provedor global. Teste RED/GREEN de seleção de provedor e teste nativo do override de vínculo. Reenfileirar apenas o job desta regra suprimido por `whatsapp_not_linked`, após revalidar elegibilidade, sem disparo manual.
- Regressão geral: Python 3.9 do Xcode não atende dependências (pandas ausente/stat follow_symlinks); reexecutado no runtime Python 3.12 do Codex: 273 testes passaram. Seis suítes CF passaram; fila ampliada para nove verificações, serviço para sete.
- Publicação CAS de cinco arquivos, backup inicial `/var/backups/business-vicky-cbg-v28w2wrk`; correção de roteamento em dois arquivos, backup `/var/backups/business-vicky-cbg-bl2txs7r`. Baseline e hashes preservados conferidos; guards Business 302, worker GET 405/POST sem credencial 401.
- Instalação desativada validada (`business-vicky-cbg-test-y19i3_fo`), depois ativada via formulário autenticado Business com CSRF; público não restrito a admins, canais web/WhatsApp habilitados, sete dias e silêncio 20h–08h.
- Retomada de um job suprimido (`business-vicky-cbg-test-f7sxrqot`) sem executar worker manual. Aceitação às 14h08 BRT (`business-vicky-cbg-test-4f2dyw8c`): 5.860 web enfileirados, 58 web concluídos, 1 WhatsApp concluído, 5.802 web aguardando, nenhum erro atual. Ciclo seguinte gerou zero novos jobs, confirmando idempotência. O termo concluído no WhatsApp significa aceite da API, não comprovação de leitura no dispositivo.
- Apenas um inscrito possui vínculo Meta e consentimento válidos hoje; regra não cria consentimentos nem envia WhatsApp a demais inscritos sem opt-in. Webchat cobre todos os 5.860 elegíveis nesta etapa. Geolocalização segue pausada.
- Browser real: quinta regra ativa, mensagem/modelo conferidos, dois canais marcados, sete dias, público correto; painel exibiu 5.861 geradas, 59 entregues, zero falhas; console sem erros. Screenshot `/private/tmp/business-vicky-cbg-20261024.png`.
- Não houve DDL, alteração de credenciais/provedor global ou Git de escrita. Mudanças de aquisição e comparador permanecem preservadas e não foram republicadas.
