# Resumo do Comparador no Business — 19/10/2026

Publicado em [PLATAFORMA → Comparador → Resumo](https://business.roadrunners.run/administracao/comparador/resumo/), com o padrão de indicadores, cobertura e fila usado em Conteúdo das provas. O resumo consulta a base atual em cada abertura e não altera produtos.

## Operação

- **Visão geral:** acervo por estado editorial, peso por variante/referência, placa, lacunas técnicas, referência de foto, situação WA e marcas com mais pendências.
- **Cobertura por campo:** foto, descrição, vínculos, lançamento, preço, peso, placa/material, drop, alturas, entressola, cabedal e solado. Cada lacuna abre a fila correspondente.
- **Fila de revisão:** 25 produtos por página, link de edição, campos a revisar e prioridade para marcas marcadas no Brasil. Depois, considera vínculos, foto e peso/placa. Filtros por tipo, recorte, mercado, marca, busca e lacuna; as abas preservam os filtros. Filtros gerais ficam recolhidos, acessíveis por teclado; abas e tabelas têm rolagem interna em telas pequenas.

Comerciais ativos exclui arquivados e protótipos e inclui rascunhos comerciais. Peso/placa se aplicam somente a tênis comerciais ativos, mesmo quando outro recorte inclui todo o acervo. Placa falsa/zero é dado conhecido; ausência é desconhecida. Referência de peso sem variante conta separadamente, sem criar gênero. Material usa denominador de modelos com placa presente. A presença no Brasil é da marca e não comprova estoque do modelo.

Foto significa referência de mídia cadastrada ou URL oficial WA, sem comprovar disponibilidade física do arquivo. Descrição indica presença, sem avaliar qualidade editorial. Cupons/ofertas do banco não incluem feeds/campanhas Awin, cuja gestão continua na integração própria. WA não verificada não significa reprovação; origem e produto têm contagens independentes. O painel não modifica a homologação, a modalidade nem as exclusões editoriais.

## Implementação

Runtime: `services/ComparadorResumoService.cfc`; `administracao/comparador/resumo/{index,backend,home}.cfm`; `administracao/comparador/includes/navigation.cfm`; inserção de um link em `includes/estrutura/sidenav.cfm`.

O serviço reutiliza `ComparadorAdminService.authorize`, exige administrador global e barra delegação. A rota mantém `backend_login.cfm` e `require_admin.cfm`; inclui `private, no-store`. Includes diretos devolvem 403. O serviço só faz SELECT, sem endpoint remoto, migração, alteração de produto ou nova configuração de acesso. Todas as relações um-para-muitos são agregadas antes do JOIN, resultando em um registro por produto. Filtros usam valores validados; texto é escapado. A consulta geral produz um snapshot para métricas, cobertura e fila; a última sincronização é uma leitura separada.

O menu local divergia de produção por trabalho anterior. A publicação aplicou somente a inserção exata do link Resumo à versão de produção, sob hash e âncora únicos. As outras diferenças foram preservadas. Os outros cinco arquivos foram publicados pelos hashes revisados. Backup recuperável e substituição atômica, com rollback protegido contra trabalho concorrente. Nenhum segredo ou Application.cfc foi exportado; a tentativa ampla de leitura foi recusada pela revisão automática e substituída por verificações mínimas.

## Validação e publicação

Foram aprovadas **272 verificações HTTP/de dados** na cópia privada em loopback, com os 208 IDs conciliados à fila canônica e sem duplicação, além de **sete verificações diretas do serviço** para permissões e filtro complexo. Cobertos os três modos de tela, recortes, marcas, presença Brasil, paginação, vazio, tipos/valores inválidos, texto seguro e denominadores não aplicáveis. ScriptProtect permaneceu ativo. O harness usa papéis sintéticos somente em sua aplicação privada e consulta a base real exclusivamente em leitura; não cria sessão administrativa de produção.

Conferência visual em desktop 1280 px e quadro responsivo 390 px, incluindo indicadores, abas e fila. As capturas são da cópia privada; não se declara uma sessão administrativa autenticada em produção. O login Google no navegador não concluiu durante a conferência. Em produção foram verificados os seis hashes, a consulta do serviço publicado com contagens reais e quatro rotas: resumo anônimo 302; backend/home/navegação diretos 403. A proteção de autenticação existente foi mantida.

Contagens observadas: **1.509 produtos gerais**, 814 publicados, 264 rascunhos, 431 arquivados e 93 protótipos ativos como subconjunto. No recorte padrão: **721 tênis comerciais**, 550 com peso (517 por variante e 33 referências separadas), 571 com placa definida, 513 com ambos e **208 pendentes**. Há 171 sem peso e 150 sem placa, com sobreposição, além de uma referência de foto ausente (produto 3). O painel não alterou esses dados.

Release: `20261019T130134Z-7199403b`. Backup: `/var/backups/business-comparador-resumo-20261019/20261019T130134Z-7199403b`. Comprovantes no projeto Comparador em `outputs/business-resumo-20261018/`, com cópia do recibo em `codex/docs/2026-10-19_business-resumo-publicacao.json`. O banco e o catálogo público não exigem deploy nesta entrega. Sem commit, branch, push ou PR.

A cópia privada de testes foi removida e o túnel temporário foi encerrado após a conferência. Os seis hashes publicados foram reconferidos às 13:08 UTC de 19/10/2026; o backup e o comprovante de verificação foram preservados.
