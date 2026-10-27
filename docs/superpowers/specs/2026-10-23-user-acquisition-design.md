# Aquisição diária de usuários

Pedido: gráfico em /administracao/usuarios/ com últimos 7, 30, 90 e 365 dias. Mudança pontual no gerenciador existente, preservando login DEV, edição, mesclagem, filtros e permissões ADMIN/DEV/contexto real atuais.

Fonte verificada: public.tb_usuarios.data_criacao, timestamp sem fuso, default now(), obrigatório. Sessão PostgreSQL America/Sao_Paulo. 57.518 contas e nenhuma data nula/futura no diagnóstico somente leitura. A unidade é conta existente, não página/perfil nem login. Inclui inativos e exclusões lógicas; remoções definitivas e mesclagens podem reduzir o histórico recuperável.

Abordagem: agregar uma vez os últimos 365 dias em SQL parametrizado, incluindo dias sem cadastros como zero, e alternar as quatro janelas localmente sem recarregar a lista. Padrão 30 dias, incluindo hoje parcial. Total, média/dia e pico acompanham o mesmo intervalo. Não misturar filtros da lista com os indicadores globais; indicar o escopo. O parâmetro aquisicao_dias aceita apenas 7/30/90/365, preservando outros parâmetros no endereço.

Alternativas: AJAX por período acrescentaria rota autenticada e novas consultas sem necessidade para apenas 365 contagens. Biblioteca externa acrescentaria dependência; SVG local responsivo permite manter o visual atual, tooltip por dia, teclado e tabela acessível de apoio. Não criar um dashboard separado, exportar pessoas ou alterar schema/índices.

Gráfico de linha/área sem suavização, eixo Y começando em zero, datas reais com ticks adaptativos. Leitura por mouse/toque e setas do teclado; foco visível, tabela expansível com os mesmos dados. Erro de consulta é indisponibilidade explícita, nunca falso zero; o restante do gerenciador continua operante.

Teste nativo de SQL com CTE sintética, limites de datas/fuso/ano bissexto e soma independente real; testes JS de seleção/métricas/geometria; renderização CF e navegador normal/estreito. Publicação limitada com backup/CAS, verificando produção, sem Git e sem tocar geolocalização pausada ou credenciais.
