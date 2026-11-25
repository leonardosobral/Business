# Gerenciador de canais do YouTube

O gerenciador de /portal/canais/ passa a ter formulário explícito para canal ou playlist, link ou @identificador, nome, ativação, vínculos por nome e opções adicionais de importação. A lista mostra os nomes das páginas e dos usuários, status e origem, com busca e filtro. As superfícies usam os tokens cinza/branco/amarelo do Business e o layout se adapta a telas pequenas.

As buscas autenticadas retornam até 12 opções após dois caracteres. A página pode sugerir automaticamente um usuário vinculado; nomes digitados sem seleção não são salvos como vínculos. Página e usuário são opcionais; ambos são necessários para os vídeos também entrarem no feed. Os IDs permanecem internos. O servidor valida existência e associação dos vínculos.

As operações exigem administrador global, POST e CSRF. Edições, ativação e remoção usam a revisão updated_at para evitar sobreposição. Remover uma fonte exige confirmação e não remove vídeos já importados. O código usado em media_canal_slug é gerado no cadastro e preservado ao editar. Fontes duplicadas são recusadas. Uma trava transacional evita cadastros simultâneos da mesma origem.

Nenhum schema ou agendamento é modificado. O limite por fonte continua sendo o padrão usado quando o job não informa maxResults. A execução atual pode sobrepor esse limite; a ajuda no formulário explicita essa diferença. Filtros de duração são editados em minutos e convertidos para segundos.

Validação: testes nativos de parsing, buscas, vínculos, CRUD com rollback e renderização; testes JavaScript de seleção, preenchimento do responsável e invalidação de seleção antiga. A publicação usa baseline, backup e substituição seletiva. O RunTV Brasil foi cadastrado após a publicação, ativo, com identidade pública conferida na API do YouTube e sem vínculos inferidos a contas existentes. ID interno 33, código runtv-brasil. A busca por nome foi conferida no navegador (12 sugestões) e o cadastro foi salvo pelo formulário normal. A simulação de importação encontrou cota excedida da API YouTube; nenhum vídeo foi gravado nessa validação. O cron existente considerará a fonte ativa quando a cota estiver disponível.
