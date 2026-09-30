# SEO: correção do cabeçalho após saída HTML

Em 29/09/2026, `/portal/seo/` falhava na sessão do usuário com `Failed to add HTML header` em `portal/conteudo/seo.cfm:2`. O problema foi reproduzido no Chrome autenticado antes da alteração.

A view definia `Cache-Control` depois de o layout emitir o menu. Esse cabeçalho já era definido em `portal/seo/index.cfm`, antes do layout. Foi removida somente a definição tardia e mantido um comentário indicando onde a política é definida. O volume de saída anterior pode variar entre sessões; não foi feita comparação com a sessão do sócio.

## Verificação e publicação

- Arquivo local e entrada da rota conferidos contra os hashes de produção antes da edição.
- `git diff --check` aprovado.
- Candidato compilado pelo Adobe ColdFusion em diretório privado: 1 arquivo, 1 sucesso.
- Publicado somente `portal/conteudo/seo.cfm`, com troca atômica e preservação de proprietário e modo.
- Backup recuperável: `/var/backups/seo-header-Business-czy4cpd0/before/portal/conteudo/seo.cfm`. Metadados e hashes estão no `receipt.json` desse diretório.
- Hash publicado confirmado: `6d0ad15bc635d8beeeee914e2478acb59731e570520574bc0438536c688f111a`.
- Doze arquivos relacionados, incluindo entrada da rota, autenticação, dados e layout, permaneceram com os hashes capturados antes da publicação.
- Recarregamento normal na mesma sessão que falhava passou a renderizar as duas notas, 32 verificações, histórico e 7 frentes de correção, sem o erro do ColdFusion.

O runtime temporário Lucee usado por `test_seo_queue_cfml_local.mjs` não está mais disponível, então essa suíte local não foi executada. A validação desta correção usou compilação Adobe e reprodução antes/depois no site real. Não houve alteração de autorização, dados de auditoria ou integrações.

Registro: `2026-09-29_seo_header_publicacao.json`. Evidência visual: `output/seo-header-20260929/seo-corrigido.png`.
