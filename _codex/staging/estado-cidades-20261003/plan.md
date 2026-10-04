# Filtro de cidades nas páginas de estado

> Execução inline com executing-plans; revisão final independente.

Objetivo aprovado: Cidade junto de Estado, desktop e móvel, pesquisa sem acentos, Todas as cidades, preservar distância/período/modalidade/cupom/badges e contagens do calendário atual. Reutilizar /estado/{uf}/{cidade}/, cidade restrita à UF. Nenhuma mudança em publicidade, autenticação, banco ou rotas de outros idiomas.

Arquitetura: estado/index.cfm monta o controle acessível com details/summary, links e busca. Novo include backend_estado_cidades.cfm agrega qEventosBase com os mesmos filtros de qEventos, exceto cidade, e fornece nomes e contagens. api/eventos.cfm entrega novas contagens somente na primeira página de estado. JS próprio preserva filtros, busca por nome e atualiza o controle sem mudar o controlador compartilhado.

Arquivos runtime: estado/index.cfm; api/eventos.cfm; includes/backend/backend_estado_cidades.cfm; assets/js/runnerhub-estado-cidades.js; assets/css/runnerhub-estado-cidades.css.

1. Escrever testes de URL/cidade e contagens. RED: comportamento ausente.
2. Implementar o include e controle; GREEN: filtros preservados, UF inválida/cidade inválida recusadas, contagens coerentes com período/modalidade/cupom e cidade não restringindo as alternativas.
3. Verificar Adobe CFML, desktop/móvel, busca por acentos, teclado, cidade fora das primeiras dez, limpar cidade e filtro assíncrono.
4. Uma revisão final Astra; corrigir achados relevantes com RED/GREEN.
5. Baseline/backup recuperável, publicar apenas cinco arquivos runtime, verificar hashes e HTTP/HTML e navegação reais. Documentar resultado no RoadRunners.

Review focus: cidades históricas sem provas no período; cidade selecionada fora das dez primeiras; troca de UF deve remover cidade e manter filtros; respostas assíncronas e preservação de escolhas recentes; canonical independente das combinações de filtros. Sem bibliotecas novas.

Git não foi autorizado; não criar branch, worktree, commit, push ou PR. Isolamento por cópia dos cinco arquivos em candidate, com baseline e conferência de hashes locais e de produção antes da instalação.
