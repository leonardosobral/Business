# Vídeos e eventos independentes do destaque — 24/11/2026

O gerenciador permite vincular, trocar ou remover o evento de qualquer vídeo, publicado ou oculto. A ação altera exclusivamente `tb_media.id_evento`; publicação e destaque permanecem independentes. Reutiliza a coluna e a chave estrangeira existentes, sem migração.

A listagem mostra evento, data e cidade, com link para o cadastro e ação por vídeo. Há filtro com/sem evento, busca geral também pelo nome do evento, contagem do recorte, miniaturas 16:9 e tabela mais compacta. O destaque atual continua em um resumo independente. O editor abre somente ao selecionar um vídeo, preserva os filtros e permite busca por nome, cidade, tag ou ID, com resultados limitados a 30.

O salvamento usa POST, CSRF de sessão, validação de IDs/evento existente e comparação do vínculo anterior para evitar sobrescrever uma alteração concorrente. Templates auxiliares rejeitam acesso direto. As regras anteriores de duração, publicação e escolha de um destaque permanecem. A normalização de publicação que já existia no backend não foi ampliada.

## Validação

`python3 _codex/scripts/test_media_event_links_native.py`: CF2025 e PostgreSQL, 42 verificações. Exercita vincular vídeo sem destaque, trocar/remover vínculo, vínculo em vídeo oculto sem publicá-lo, campos de publicação/destaque preservados, edição concorrente, evento inexistente, ID fracionário, CSRF inválido, renderização do editor, filtros com/sem evento e estado vazio. Todas as alterações ocorrem dentro de uma transação revertida em `finally`; o estado original do vídeo é conferido após rollback. As fixtures temporárias são protegidas por localhost/nonce e removidas ao final. O teste de vídeo já destacado é condicional à existência de um destaque; não havia destaque ativo durante esta execução.

Conferência autenticada no navegador: abertura do editor em vídeo oculto, busca por “Maringá” com identificação das edições por data/cidade, filtro com evento (6 vídeos) e layout em cinza/branco/amarelo. Nenhum vínculo foi salvo pela navegação de validação. Captura em `panel.jpg`. Acesso anônimo à página continua redirecionando ao login; templates auxiliares responderam 403.

## Publicação

Base `origin/main` `a0dca781`; arquivos do painel idênticos à produção antes da alteração. Checkout original do Business continha mudanças da frente de canais/importador YouTube e foi preservado; trabalho isolado neste worktree. O trabalho anterior do RunnerHub também foi preservado em seu worktree.

Publicados somente `portal/includes/media_event_action.cfm`, `portal/videos/event_editor.cfm`, `portal/includes/media_backend.cfm` e `portal/videos/home.cfm`, com baseline, backup e substituição atômica por arquivo (auxiliares primeiro). Recibo em `release.json`; backup recuperável `/var/backups/business-video-event-links-20261124-5eoumhfp`. Índice da página e CSS compartilhado mantidos intactos. Nenhum commit ou push foi realizado.
