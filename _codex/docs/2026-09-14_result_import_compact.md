# Fila — indicadores e filtros compactos

Publicado em 14/09/2026. Único arquivo de runtime alterado:
`administracao/importacoes-resultados/home.cfm`.

- Cinco blocos: Eventos, Pendentes, Processados, Operação e Histórico.
- Operação mantém links separados para processando/falhas; Histórico mantém
  canceladas/arquivadas separados, sem somar chamadas com eventos.
- Extraoficial/final/atualização continuam disponíveis no filtro Publicação,
  sem repetir três cards no resumo.
- Campos e botões do filtro ficam na mesma linha com largura disponível de
  960 px ou mais. Container queries reorganizam a tela em larguras menores,
  inclusive quando o menu lateral reduz a área de conteúdo.
- Nenhuma mudança de SQL, processamento, permissões, API ou dados.

## Validação

Render CFML real com dados controlados; teste visual/DOM no navegador:

| Medida em viewport 1280 px | Antes | Depois |
| --- | --- | --- |
| Linhas de cards | 2 | 1 |
| Altura dos cards | 248,25 px | 72,875 px |
| Linhas dos controles de filtro | 2 | 1 |
| Altura do filtro | 117,016 px | 80,016 px |

Redução aproximada de 58% na soma dessas alturas. Os sete atalhos de status
foram conferidos no DOM, inclusive os quatro agrupados. Em mobile 390 px,
largura da página = 390 px, campos e ações dentro do viewport.

- Suíte integrada SQL/CFML: passou.
- Regressão Node da fila e intenção: 24/24.
- Adobe ColdFusion no servidor: 1/1 arquivo compilado.
- Pós-publicação: hash e metadados do arquivo instalado/backup confirmados;
  123 arquivos/inventários protegidos preservados.
- Rota HTTPS anônima mantém redirecionamento para autenticação. A conferência
  visual usou dados controlados, não a sessão autenticada de produção.

## Publicação e recuperação

Backup: `/var/backups/business-result-import-compact.e6ab27350e20`.
Recibos: `2026-09-14_result_import_compact_release{,-publish,-verify}.json`.

Rollback guardado: `python3 _codex/scripts/deploy_result_import_compact.py rollback`.
Restaura somente o arquivo da tela, sem alterar resultados ou submissões.
