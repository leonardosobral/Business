# Sync conciliado do Business — 27/10/2026

Pedido: sincronizar o servidor após identificar perda do submenu Comparador,
conferindo outras versões antigas. Publicação concluída e verificada.

## Resultado

O inventário inicial comparou **907 arquivos de código rastreados**, incluindo
CFML, JS, CSS, vetores/fontes e os pontos de entrada; **847 iguais e 60 diferentes**,
sem arquivo rastreado ausente. Application.cfc e .htaccess foram apenas comparados
e já coincidiam. Configurações privadas, banco, uploads, arquivos de dados e
artefatos de trabalho ficaram fora do sync.

A revisão dos diffs mostrou que 55 versões publicadas tinham alterações válidas
mais novas: tema neutro RoadRunners, Teams, aquisição de usuários, notas/respostas
do Helpdesk, fechamento automático de chamados e interações Brasil Gigante da
Vicky. Elas foram preservadas em produção e recuperadas no checkout local.
**Não foi realizado upload indiscriminado do checkout.**

A varredura adicional de código no servidor identificou **571 arquivos fora do
inventário rastreado**, incluindo bibliotecas DataTables, legado e módulos novos.
Nenhum foi removido ou modificado. Desses, **40 arquivos dos módulos recentes**
Teams, aquisição e Helpdesk foram recuperados no local para acompanhar as
referências das versões novas, sem copiar configurações privadas.

Após a conciliação e publicação, **947 arquivos locais/servidor têm hashes iguais**
e os **571 adicionais do servidor permanecem com os hashes anteriores**. Essa
verificação prova igualdade dos arquivos inventariados, não uma homologação
funcional integral de todos os módulos ou identidade completa de todos os
arquivos do diretório público.

## Cinco arquivos publicados

1. `includes/estrutura/sidenav.cfm`: reinserido Comparador com Resumo, Produtos,
   Promoções e ofertas, Filtros e cadastros e Integração Awin, CSS e versão do JS.
   Mantidos Meus Teams, Gestão de Teams e rótulo Empresas existentes no servidor.
2. `includes/estrutura/head.cfm`: referência de pesquisas.css atualizada para
   20260824-8, preservando o tema `rr-neutral-20261026` publicado.
3. `administracao/pesquisas/assets/pesquisas.js`: versão já existente no Git local,
   com correção do preview da pergunta de conta e texto de confirmação.
4. `notificacoes/includes/send_backend.cfm`: tratamento de exceção/timeout HTTP
   já existente no Git local, evitando falha aberta da tela no dispatch.
5. `notificacoes/envio/home.cfm`: mensagem correspondente de timeout, orientando
   consultar histórico antes de reenviar. Nenhuma notificação foi enviada.

## Validação

- **16 testes de navegação passaram**: seções, destinos e busca/abertura/restauração
  do submenu. O contrato de destinos estava desatualizado para Consumo OpenAI,
  Resumo e Awin; a expectativa foi atualizada, sem remover destinos existentes.
- `node --check` de pesquisas.js passou.
- **4 templates CFML compilados** pelo ColdFusion 2025 antes da escrita pública;
  a compilação não executou queries ou ações de negócio.
- **11 checks HTTP pós-publicação** passaram: home e Teams 200; páginas
  administrativas conservam redirect 302 de login; JS do menu/Pesquisas 200.
- Na sessão Chrome existente e já autenticada, a página Resumo foi recarregada
  por DOM, sem entrada nativa ou abertura de janela. Comparador está visível,
  aberto e com cinco destinos; o link de Gestão de Teams continua no DOM.
  Evidência: `outputs/business-sync-20261027/menu-publicado-contexto.png`.
- Conferência final: 947 hashes iguais; 571 arquivos extras inalterados.

Limites: não foi executada a suíte completa do Business nem dispatch real de
notificações. Não houve alteração/ensaio de banco ou simulação de credenciais.
Acesso direto ao include sidenav.cfm já retornava 500 antes desta publicação;
foi registrado como condição preexistente, sem mudança de proteção ou correção
fora do sync. `git diff --check` aponta um espaço em branco na linha vazia do
menu herdado de produção; não é erro de compilação nem mudança funcional.

## Publicação e recuperação

Script: `Comparador/codex/scripts/deploy_business_sync_20261027.py`.
Manifesto explícito de cinco arquivos, baseline dos cinco e guard de 902 arquivos
rastreados preservados; cópia de backup com metadados, compilação privada,
substituição atômica por arquivo e rollback automático em falha de smoke/hash.

Release: `/root/codex-backups/business/20261027T123553Z-business-sync`.
Resultado: `rollback: false`, cinco arquivos, 11 checks e hashes confirmados.
O primeiro ensaio de compilação parou antes de publicar por permissão no diretório
temporário; corrigida somente a leitura desse diretório descartável, o segundo
compilou e publicou. Nenhum serviço foi reiniciado.

Para restauração, consultar before.tgz/manifest.json/metadata.json do release,
conferir os hashes atuais e repor apenas os cinco arquivos com owner/permissões
anteriores. Recusar restauração sobre mudanças posteriores. Backups locais dos
60 arquivos antes da conciliação: `outputs/business-sync-20261027/local-before/`.

Checkout Business: 55 versões de produção recuperadas, menu/head conciliados,
40 arquivos adicionais e contrato do teste atualizado. Nenhum commit, branch,
push, pull, migração, limpeza de arquivos remotos ou mudança de configuração.
As alterações ficam locais para futura revisão/versionamento explícitos.

Inventários, diffs, classificação, plano, release e hashes finais estão em
`Comparador/outputs/business-sync-20261027/`.
