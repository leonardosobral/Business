# Dashboard dos admins globais — 12/09/2026

Publicado em https://business.roadrunners.run/ com o visual da suíte administrativa, panorama compacto, filas de revisão, distribuição de completude dos eventos, leitura de notificações, saúde dos pagamentos e infraestrutura.

## Escopo e isolamento

- A seleção de perfil em `home_logado.cfm` permanece intacta. Somente o ramo `businessHomeIsAdmin` inclui o dashboard e suas folhas de estilo.
- `home_conta_dashboard.cfm`, autenticação, permissões, menu, template geral e a suíte Kanban/Agenda/Documentos não foram alterados.
- Os componentes visuais de disponibilidade e cron são incluídos somente pelo dashboard global. O backend compartilhado de disponibilidade não mudou.
- O CSS novo usa `.business-global-dashboard`. A largura do contêiner só muda quando contém esse dashboard.

## Definições preservadas e esclarecidas

- Usuários e eventos nas contas são vínculos ativos, não entidades únicas.
- Filas: cadastros, solicitações de vínculo, eventos Foco Radical para revisão e grupos de agregadores. Barras representam a participação no total; o total fica indisponível se qualquer fonte falhar.
- Conteúdo: eventos ativos com encerramento a partir de hoje e início até 90 dias. Inclui eventos iniciados anteriormente e ainda não encerrados no cadastro. A consulta ganhou somente a contagem do total elegível, para o denominador da completude.
- Completude: sete itens existentes — descrição, inscrição, categorias, organizador, cidade/estado, endereço e imagem. Categorias mutuamente exclusivas: completos; 1–2 itens ausentes; 3 ou mais ausentes. Não se trata de avaliação editorial.
- Portal: log de erros, 404 e visualizações de eventos nos últimos 7 dias. Busca: erros de interpretação e buscas sem resultado nos últimos 30 dias. Removida a soma visual de períodos diferentes.
- Notificações: registros lidos entre os publicados nos últimos 7 dias; o painel mostra numerador e denominador.
- Pagamentos: preservadas as cinco consultas e a rotina canônica de conciliação. Rótulos traduzidos para linguagem operacional.
- Disponibilidade: média histórica dos monitores e resposta das amostras recentes. Cron a executar e com erro podem se sobrepor.
- Flags de carga distinguem indisponibilidade de zero. Consultas continuam somente leitura; nenhuma migração ou alteração de dados.

## Verificação e publicação

- Compilação ColdFusion da versão final em diretório separado: 4/4 templates com sucesso (inclui a navegação existente).
- Testes existentes do Meet e da suíte: 9/9 aprovados. Verificações existentes de observabilidade dos pagamentos aprovadas.
- Validação autenticada em produção: contagens reais, proporções, links internos, explicação expansível dos campos e abertura/fechamento dos monitores.
- Desktop em 1292 px e celular em 390 px: sem transbordamento horizontal da página; tabelas têm rolagem interna. Sem IDs duplicados ou valores NaN/Infinity nas barras.
- Simulação de Protta Corp pela interface existente: tela anterior da conta exibida, sem `.business-global-dashboard`, sem `admin-dashboard.css`, sem `admin-suite.css` e sem card global de Meet. Sessão restaurada para “Todas as contas”. A simulação usa o ramo comum das contas; não foi criado usuário de teste.
- Publicados apenas `includes/estrutura/home_admin_dashboard.cfm`, `includes/estrutura/uptime_status.cfm`, `includes/estrutura/cron_jobs_status.cfm` e `assets/css/admin-dashboard.css`.
- Backup anterior: `/var/backups/business-global-dashboard.f7JVsJ/before/includes/estrutura/` no host `rr-prod`. Substituições verificadas por hash e realizadas preservando proprietário e permissões.
- Reversão: restaurar os três templates desse backup; o CSS novo pode permanecer sem uso. Não é necessário reiniciar ColdFusion ou alterar o banco.
