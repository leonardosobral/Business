# Gestão global de Teams

Aprovado pelo usuário em 26/10/2026: separar a gestão global no mesmo padrão de Contas/Empresas e publicar ao concluir.

- `/administracao/teams/` usa head, header, sidenav e footer do Business, tokens cinza/branco/amarelo, indicadores e tabela paginada, busca por nome/cidade, situação, tipo e UF.
- Detalhes por abas com links GET: Cadastro, Responsável técnico, Revisão, Equipe administrativa, Atletas e Histórico. Reutilizar formulários e serviço do módulo; preservar dados digitados em erros e filtro/retorno/paginação durante navegação.
- Revisão permite aprovar/reativar, solicitar ajustes, recusar, suspender e encerrar; mantém CREF/evidência, justificativa, CSRF e versão concorrente já existentes. Suspender/encerrar explicam o encerramento dos vínculos antes da confirmação.
- Acesso global exige identidade verificada do Business e is_admin real/ativo consultado no banco. Usuários de Team, cookies e acessos delegados não concedem acesso global.
- `/teams/` mantém painel dos responsáveis; admins globais são encaminhados à gestão com seleção preservada. Remover decisão global do formulário compartilhado de responsáveis.
- Menu global aponta para Gestão de Teams, junto de Empresas, e menu dos responsáveis continua em Meus Teams. Não renomear nem alterar toda a gestão de Contas.
- Alternativas: manter revisão misturada no painel atual não atende a separação; integrar Teams como Contas mistura domínios. Escolhida a área global própria com o layout existente.
- Sem DDL, alteração do job de convites, envio de emails de teste, commits ou publicações de outras frentes. Testes funcionais em fixture rr_teams_test com rollback, no único banco disponível, sem modificar dados reais.
- Publicação: baseline real, backup recuperável, lista exata de arquivos, CAS/rollback e verificação real depois da publicação.
