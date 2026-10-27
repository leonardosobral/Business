# Helpdesk Tools Implementation Plan

> Execução inline, orientada por testes, sem Git de escrita. Uma revisão independente ao concluir (executing-plans).

**Goal:** Notas privadas no atendimento e biblioteca compartilhada de respostas rápidas editáveis.
**Architecture:** interno existente, serviço de gravação de nota com lock/revisão, biblioteca JSON privada atômica, includes e assets da interface atual.
**Tech Stack:** CF2025/PostgreSQL/Java NIO/JavaScript.
**Spec:** docs/superpowers/specs/2026-10-26-helpdesk-tools-design.md

## Global Constraints
- Admin global apenas; POST/CSRF; sem notificação para nota; não mudar status/setor; auto-close ignora nota.
- Nunca vazar nota no RR ou suporte Business; proteger consulta legada antes de habilitar gravação.
- Rascunho nunca enviado por inserção; XSS codificado; texto12000/título80; revisão contra sobrescrita concorrente.
- Preservar frentes e geocoding pausado; sem DDL/credenciais/Git.

## Review Focus
- Publicação de nota por campo forjado/modo público, conflitos de rascunho, nota no chamado de outro usuário pela API pública.
- Conteúdo com HTML/script e multilinha; edição/exclusão concorrente e biblioteca vazia sem ressuscitar padrões.
- Falha de gravação de arquivo não corrompe biblioteca; segredos/dados fora de webroot e permissões mínimas.
- Ausência JS: botão explicita salvar nota/publicar; ações de biblioteca continuam funcionais; teclado/mobile.
- Filtro interno na consulta RR legada e repositório; operação nota não dispara notificadores nem muda prazo48h.

## Tasks
- [x] 1. RED/GREEN notas: HelpdeskNotes.save(ticketId,actorId,text,revision,lastMessage); fixture transacional com rollback, bloqueio nãoadmin/conflito e leitura pública excluindo nota. Atualizar guarda/consulta/render.
- [x] 2. RED/GREEN biblioteca: HelpdeskReplies.list/save/remove com revisão; fixtures filesystem temporário, CRUD, vazio, escape/limite e conflito; página/admin handler e inserção de texto, notas e gerência por JS nativo.
- [x] 3. Revisão independente, suites/compilação/HTTP, baseline CAS+backup privado; publicar filtro RR antes de notas Business; validar no navegador desktop/mobile e testes de instalação, sem mensagens públicas de teste.

## Ledger
- Reusar checkout atual preservando sujidade de outras frentes; nenhuma operação de branch/commit/push.
- Interfaces Task1 salva nota sem notifier; Task2 usa hD csrf+global gate; Task3 publica exatamente runtime validado. Nenhum conflito entre interfaces.
- Revisão independente única: sem Critical; Important sobre rascunho interno após falha corrigido RED→GREEN em render.cfm. Preservar message_kind além da ação mantém privacidade ao tentar novamente sem JS.
- Ruling: preservar também ticket_id na gerência — necessidade de contexto do atendimento, tratada na mesma passagem de correção; regressão de render observada RED antes de ajustar hdUrl. Sem isto, voltar ao chamado exigiria nova seleção.
- Java NIO FileChannel inacessível pelo módulo Java do CF; não alterar JVM/permissões. Lock nomeado do servidor + rename atômico atende o runtime atual único; múltiplos JVMs exigiriam migrar biblioteca para armazenamento compartilhado apropriado.
- Revisão não julgou produção/browser/suites nativas: verificação operacional permanece responsabilidade da execução. Sem experimentos simultâneos reais ou injeção de falha de disco; revisão stale e escrita atômica verificadas.
- Correção adicional no mesmo fluxo: ao preservar ticket_id na biblioteca, excluir essa herança para Novo chamado; regressão de render observada RED→GREEN e publicada.
- Evidência: native notes7/replies7/render/guards6 + JS4; 273 regressões Python passaram. Nota transacional integralmente revertida; filtro legado RR testado com nota sintética invisível ao solicitante.
- Publicação CAS de 11 arquivos, guard RR antes do Business, backup inicial /var/backups/business-helpdesk-tools-xzaoo1f9; ajuste final de navegação /var/backups/business-helpdesk-tools-4apr56i_. Sem alterações de outras frentes; geocoding pausado.
- Navegador produção: modo interno oculta envio público; gerência criou e editou modelo temporário, e inseriu suas duas linhas no rascunho sem envio. Remoção somente do modelo sintético via serviço real com comparação exata e backup em /var/backups/business-helpdesk-tools-test-rakgy0vb. Biblioteca final com três modelos originais.
- Desktop/mobile390x844 conferidos; Tab avança Título→Mensagem; viewport restaurado. Screenshots /private/tmp/business-helpdesk-notes-20261026.png, /private/tmp/business-helpdesk-replies-20261026.png e /private/tmp/business-helpdesk-replies-mobile-20261026.png.
- A revisão automática inicialmente bloqueou uma tentativa de preflight por risco de rascunho privado. Após correção e validação, preflight e publicação foram autorizados normalmente. Nenhum bloqueio remanescente.
