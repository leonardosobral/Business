# Road Runners Teams

Autorização: em 26/10/2026 o usuário aprovou as sugestões da discussão e solicitou implementação. Executar e publicar sem novas confirmações; sem operações de Git. Acompanhamento inicial: perfis esportivos e resultados oficiais existentes, sem saúde, contatos privados ou atividades privadas.

## Produto

Cadastro exclusivo de treinador, assessoria, clube, academia, grupo ou empresa, com titular PF/PJ, responsável técnico com CREF ativo, contatos comerciais, cidade/UF e atendimento presencial/online/ambos. Análise global manual com evidência de verificação do CREF, possibilidade de ajustes, recusa, suspensão e encerramento. Cadastro autenticado; dados críticos voltam para revisão. Não automatizar consultas a conselho sem integração comprovada.

Painel por abas: visão geral, atletas, resultados, divulgação, equipe administrativa e cadastro. OWNER/ADMIN/VIEWER, convite administrativo com aceite autenticado. Membros administrativos não são atletas automaticamente. Último titular não pode ser removido. Identidade e login do Business são reutilizados; tenant Teams possui tabelas próprias e não concede vínculo empresarial ou permissão de eventos. Esta separação adapta a proposta de reutilizar contas à forte herança de acessos legados observada no código. Navegação Empresas e Teams; pessoa com dois acessos pode usar ambos.

Diretório público apenas de Teams ativos. Página com link de adesão. Login retorna ao Team; GET nunca vincula. Confirmação explícita informa dados esportivos compartilhados e vínculo exclusivo. Um vínculo ativo por usuário, garantido pelo banco. Novo vínculo/troca define próxima mudança após 14 dias completos. Saída é livre e não apaga o prazo. Exclusão administrativa não apaga o prazo e bloqueia reentrada naquele Team até liberação. Suspensão/encerramento pela plataforma encerra vínculos e permite nova escolha. Histórico preservado, inclusive equipe original dos resultados. Campo livre assessoria não vira filiação.

Atleta pode buscar Team, sair/trocar e convidar responsável por email ou WhatsApp. Email é transacional solicitado pelo usuário; WhatsApp é revisado/enviado pelo próprio usuário. Deduplicação e limite de frequência. Convite não cria conta nem filia. Eventos do funil diferenciam usuário já existente de aquisição atribuída a Teams; medir retenção sobre ações observadas, sem prometer atribuição perfeita.

## Arquitetura e segurança

CFML e PostgreSQL, esquema rr_teams, serviços compartilhados nos dois sites com mesmo conteúdo. Nenhum acesso baseado em cookie de ID; wrappers passam identidade autenticada do servidor e serviços confirmam conta ativa e privilégios no banco. POST + CSRF em mutações; escopo de Team validado a cada operação. Cadastros e convites sem campos secretos em respostas públicas. Transações e bloqueio por atleta protegem concorrência. Convites aleatórios armazenados como hash, com expiração e identidade destinatária conferida. Paginação e consultas limitadas.

## Abordagens

Consideradas: Team como empresa (menor esforço, risco de herança de eventos); identidade/contexto compartilhados com domínio próprio (selecionado para preservar isolamento); autenticação inteiramente nova (duplicação desnecessária).

## Operação

Testes nativos ColdFusion com esquema de fixture em transação revertida; sem envios de teste. Migração aditiva apenas de objetos Teams, validada antes de instalação. Baseline de produção, backup recuperável, publicação CAS apenas do manifesto e probes reais. Não editar credenciais/permissões existentes. Não publicar arquivos alheios nem reiniciar serviços.
