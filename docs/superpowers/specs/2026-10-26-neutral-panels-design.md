# Identidade visual dos painéis Business

Pedido explícito: escala de cinza, branco e amarelo RR, removendo superfícies azuladas. Correção visual de baixo impacto; implementar diretamente sem nova pausa de planejamento.

- Preservar todos os layouts, funcionalidades, permissões e dados. Não editar bibliotecas MDB/vendor nem recolorir fotos, ícones de arquivo semânticos ou etiquetas personalizadas do Trello.
- Base canônica existente: --rh-yellow #f4b120. Superfícies compartilhadas #222222/#262626, campos #1f1f1f, textos claros/cinza; preservar hierarquia usando luminância equivalente nos neutros tingidos.
- Neutralizar slate/azul em CSS próprio e style blocks dos módulos identificados. Manter sucesso, perigo, avisos e cores de etiquetas do Kanban como informação operacional.
- Acabamentos de marca em ciano (banners, documentos, agenda) passam a amarelo RR. Séries secundárias e estados informativos usam cinza/padrões distinguíveis.
- Atualizar somente hrefs de folhas afetadas para invalidar cache. Guardar baseline local antes da edição; produção deve coincidir ou parar para verificar conflito. Publicar arquivos exatos com CAS e backup, sem Git, DDL ou alteração de configuração.
- Verificação: alterações dos templates se limitam a style blocks e href de CSS; CSS sem mudança de estrutura/layout. Inspeção real de Help Desk, suite, auditoria, métricas e Central de Saúde (se sessão permitir), desktop/mobile; contraste/foco e estados preservados.

## Evidência e publicação
- 46 arquivos de runtime (19 CSS e 27 templates) com assinatura estrutural preservada. Cache de cada folha afetada versionado `rr-neutral-20261026`. Sem DDL/Git/configuração ou mudanças de dados/permissões.
- Quatro baselines divergentes eram versões mais novas de produção, sem alterações locais prévias: admin-dashboard.css, portal/conteudo/seo.cfm, head.cfm e home_admin_dashboard.cfm. Incorporadas essas versões e aplicada apenas a correção de paleta/cache; o novo dashboard de decisões foi preservado.
- Backup recuperável: /var/backups/business-rr-neutral-wiuq_arg. CAS/hashes finais e 22 sondagens HTTP aprovadas. Compilação nativa do workspace aprovado; validação funcional prévia de notas/modelos preservada.
- Navegador autenticado: Help Desk, Documentos, Agenda com eventos carregados, auditoria Vicky, dashboard atual, Central de Saúde41703 e AI-mails. Fundos computados com canais iguais:38/38/38 em painéis,27/27/27 em campos,53/53/53 em cartões da Agenda e34/34/34 no fundo da Central. Accent computado #f4b120.
- Inspeção mobile390x844 de AI-mails aprovada; viewport restaurado. Capturas: /private/tmp/business-neutral-helpdesk-20261026.png e /private/tmp/business-neutral-aimails-mobile-20261026.png. Nenhuma ação operacional executada no navegador.
