# Notas internas e respostas rápidas do Help Desk

Pedido: disponibilizar notas internas e respostas rápidas editáveis, substituindo a IA no formulário administrativo.

- Nota é registrada no histórico com autor, horário e selo “Nota interna · Somente equipe”. Somente administradores globais podem criar/ler pelo Business. Não notifica o usuário, não muda status/setor e não renova o prazo48h, que já ignora interno=true.
- Reutilizar interno no banco e lock/revisão otimista. Proteger também a consulta legada do RR /atendimento/, que hoje não filtra interno; o repositório novo já filtra.
- Abas Resposta pública / Nota interna no mesmo rascunho, com ação e aviso inequívocos. Na nota, ocultar roteamento e respostas públicas. Não exigir JavaScript para distinguir a ação: botões submit diferentes e confirmação de visibilidade.
- Biblioteca global de respostas rápidas: título80/texto12000, criar/editar/remover com confirmação, limite100, três mensagens atuais como padrões iniciais. Inserção apenas no rascunho, sem substituir o texto ou enviar automaticamente. Página dedicada pela aba “Respostas rápidas”.
- Persistência compartilhada em arquivo JSON privado fora da raiz web /var/lib/runnerhub-business/helpdesk/quick-replies.json. Lock nomeado no runtime + substituição atômica e revisão para evitar perda entre operadores. Não depende de DDL bloqueado no datasource. Runtime atual é um único JVM/host. Datasource seria preferível para múltiplos servidores; localStorage não atenderia biblioteca compartilhada.
- Sem credenciais, DDL, Git, alterações de IA em outros módulos ou reinício do geocoding. Publicação CAS de arquivos estritamente da tarefa com backup e testes.
- Implementação direta autorizada pelo pedido “Então implemente”; não abrir nova etapa de aprovação para o escopo explícito. Escolhas de UX/persistência são decisões de implementação.
