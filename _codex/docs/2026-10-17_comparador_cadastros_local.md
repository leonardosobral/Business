> Atualização: publicação e importação concluídas em 17/10/2026. Ver registro final ao fim deste documento; a etapa local abaixo é histórico.

# Comparador — cadastros e ofertas, etapa local 17/10/2026

A pedido do usuário, trabalhar localmente enquanto a VPN estiver indisponível. Nada deste lote foi publicado e nenhum produto foi cadastrado em produção.

## Implementação

- Plataforma → Comparador: submenu nativo expansível, Produtos / Promoções e ofertas / Filtros e cadastros. Busca encontra os destinos internos e restaura o estado do submenu ao limpar.
- Produtos: editor existente preservado; navegação compartilhada; atalhos das ofertas para editar/encerrar.
- Ofertas: lista geral com busca, situação e paginação, edição e encerramento. Encerra por validade, preservando ID, histórico e ausência de reativação de oferta anterior. Novas ofertas continuam vinculadas à tela do produto.
- Cadastros, em abas: marcas, tipos, categorias, características, características por tipo, filtros e opções. Criação, leitura, edição e exclusão de registros sem vínculos; histórico com ator e antes/depois; concorrência por token.
- Tipos aceitam apenas códigos compatíveis com URLs; características seguem o formato de identificador suportado pelo leitor. Códigos primários existentes são fixos. Formato/unidade de características em uso não mudam. Categoria em uso não troca de tipo. Ordem de tipo pode ficar vazia (NULL), preservando ocultação no menu.
- Cadastros usam trava que é coordenada com validação transacional de produtos, publicação e especificações. Mantidos admin global, recusa de acesso delegado e CSRF.
- Filtros administram apresentação e opções dos campos já suportados pelo Comparador; não criam consultas arbitrárias ou novos operadores. Rótulo/ordem/exibição por tipo; opções vazias usam padrões. Marcas, categorias e modelos continuam derivados do catálogo público.

## Banco e leitor

Migração em `../Comparador/codex/docs/sql/2026-10-17_comparador_cadastros.sql`, aditiva e ainda não aplicada em produção. Tabelas tb_filtro, tb_filtro_opcao e tb_cadastro_auditoria. Sem a migração, a área de cadastros informa a dependência; produtos e ofertas continuam no contrato editorial anterior.

Atualizações do leitor público e lote de 22 produtos estão no Comparador; consultar `../Comparador/codex/docs/2026-10-17_atualizacao-catalogo.md`.

## Testes e revisão

Executados: 16 testes JS de navegação; 5 testes preexistentes do publicador em diretórios temporários. Comparador: 8 testes JS de gráficos, 8 verificações SQL, reexecução da migração e permissões em PostgreSQL local descartável. Prévia real no navegador testou abertura/fechamento e busca do submenu.

Preparados, ainda não executados: `_codex/tests/comparador/cadastros.cfm`, `ofertas.cfm` e `Comparador/tests/fixtures/http/filtros_cadastro.cfm`. Executar apenas em harness privado loopback com banco comparador_codex_test; nunca publicar fixtures. CFML/HTTP bloqueados pela ausência do runtime local (conexão recusada em 127.0.0.1:18500), após perda da VPN. Não interpretar testes JS/SQL como homologação dos formulários CFML.

Revisão independente concluída, com correções de corridas de cadastros/produtos e ofertas, códigos de tipos, tratamento de validade nula e ordem opcional de tipos. Nenhum achado confirmado ficou sem correção; validação no runtime real é pendente.

## Retomada

1. Restaurar harness isolado e executar todos os testes CFML/HTTP e cenários visuais antes de publicar.
2. Reconciliar hashes com produção e preservar alterações de outras frentes. `_codex/docs/2026-10-17_comparador-local-manifest.json` é inventário LOCAL, não baseline remoto.
3. Aplicar migração aditiva via conexão DBA existente. Preservar proteções do datasource.
4. Novo manifesto deve abranger arquivos de runtime deste lote; o publicador antigo tem lista de cinco arquivos e não deve ser usado sem atualização/revisão de escopo.
5. Publicar somente após validação; conferir no servidor e importar produtos inicialmente como rascunhos, com fontes e lacunas preservadas.

Sem commit/branch/push. Backup dos arquivos locais anteriores em `_codex/docs/2026-10-17_comparador-local-before.tar.gz`.


## Publicado após retorno da VPN — 17/10/2026

- Migração aplicada pela conexão existente DataGrip RunnerHub/runner_dba. 508 produtos preservados; leitor público com SELECT de filtros/opções e sem escrita ou auditoria.
- 16 arquivos de runtime publicados com conferência integral de hashes e backup. Primeiro backup: `/var/backups/comparador-catalogo-20261017/20261017T105646Z-581004c2`; correção de versão do script para invalidar cache: `/var/backups/comparador-catalogo-20261017/20261017T110923Z-9643663d`.
- CF2025: 45 testes de produtos, 13 de cadastros, 6 de ofertas, 4 de leitura pública; HTTP: 29 produtos + 39 cadastros/ofertas; 16 testes JS de navegação aprovados. Corrigidos tipo cf_sql_bit e isolamento dos testes com transações aninhadas.
- Business autenticado verificado: submenu sob PLATAFORMA, busca por marcas, cadastros, ofertas, criação de rascunho e lista final de 22 rascunhos. HTTP real: novas páginas redirecionam anônimo ao login, includes recusam acesso, tênis/monitores respondem 200 e rascunho direto responde 404.
- Lote 4252–4273: 22 produtos / 16 marcas / 13 tênis + 9 outros produtos. Primeiro criado pela UI; demais importados em transação com auditoria do administrador autenticado 139. Fontes, SKU, referência de medidas e pendências preservados na descrição e no histórico. Preços e datas desconhecidos vazios; nenhuma oferta inventada.
- Novos cadastros: Petzl, Orca e DUX; seis tipos e seis categorias. Salomon e Zoot já existiam com CR no código/nome e nenhum produto vinculado; normalizados com antes/depois auditados.
- Total final 530 produtos, 508 públicos e 22 rascunhos. Hash dos 508 produtos legados idêntico ao anterior: b7da581cbd6bb2f86d7ba98de802922c. 22 auditorias do lote e 17 de cadastros.
- Planilha e JSON atualizados com IDs, links do Business e status. Revisões técnicas pendentes permanecem indicadas; os novos produtos não foram publicados ao público.
- Evidências e scripts de migração/importação/publicação em `Comparador/codex/docs`; captura final em `Comparador/outputs/catalogo-20261017/business-publicado.png`.
- A tentativa de conferir mobile em iframe privado não forneceu evidência utilizável; a validação visual deste deploy foi desktop. A apresentação em celular não foi verificada nesta etapa.

Limpeza concluída: cópias privadas CFML e datasource sintético removidos do servidor; túnel fechado e PostgreSQL local temporário encerrado. Os 16 hashes publicados foram reconferidos.
