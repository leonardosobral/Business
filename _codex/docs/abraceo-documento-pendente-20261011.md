# Pré-cadastros ABRACEO com documento pendente

Publicação concluída em 11/10/2026. Foram revisadas as 55 empresas restantes do inventário de 96 filiados: 47 organizadores confirmados receberam contas e perfis, e 8 casos permaneceram separados. Dos 84 eventos futuros candidatos, 47 receberam vínculo confirmado e 37 permaneceram sem associação.

## Modelo e limites

A migração `_codex/sql/2026-10-11_contas_documento_pendente.sql` foi aplicada manualmente pelo usuário e conferida no catálogo PostgreSQL. O datasource ColdFusion bloqueia ALTER TABLE; nenhuma permissão ou credencial foi alterada. `documento_pendente` exige documento NULL, tipo PJ e status PENDENTE. Documentos preenchidos continuam únicos. CNPJ pesquisado, razão social e endereço são referências no JSON do perfil, e não identificação jurídica confirmada. A tela administrativa exibe esse limite.

As novas contas são IDs 64 a 110. As 47 contas não têm usuários vinculados. Elegibilidade de primeiro acesso, vouchers e acessos ao estudo anteriores foram preservados; este lote não adiciona novos vouchers nem habilita essas contas no fluxo de primeiro acesso.

## Arquivos publicados

- `administracao/contas/includes/backend.cfm`: aceita documento vazio apenas para PJ pendente; grava NULL e o indicador de documento pendente.
- `administracao/contas/home.cfm`: apresenta CNPJ pendente na listagem e nos detalhes e informa a regra no formulário.
- `administracao/contas/includes/perfil_publico.cfm`: apresenta evidência de responsabilidade, fonte e distinção entre pesquisa e titularidade confirmada.
- 47 imagens originais em `assets/contas/abraceo/`.

## Evidências e verificações

`outputs/abraceo-revisao55-20261011/` contém a planilha de acompanhamento, revisão de empresas e revisão de eventos com fontes e justificativas. A pasta `support/` contém os relatórios de importação e publicação. Não reenviar relatórios de suporte como convites.

- Os 3 arquivos CFML foram compilados pelo ColdFusion 2025 real antes da publicação.
- Foram aprovados 8 testes transacionais no banco: dois documentos NULL coexistem; PJ sem documento não pode ser ativada; PF sem documento é recusada; indicadores inconsistentes são recusados; documento vazio é recusado; duplicidade é recusada; preenchimento e ativação com documento são permitidos. Todas as sondagens foram revertidas.
- A simulação inseriu 47 contas, 47 perfis e 47 vínculos e reverteu a transação, verificando restauração integral da baseline. Depois houve gravação definitiva.
- Foram conferidos hashes dos 50 arquivos publicados; 56 contas anteriores, 41 perfis anteriores, vínculos anteriores, usuários, elegibilidade, vouchers e acessos permaneceram iguais à baseline.
- Totais finais: 103 contas no Business, sendo 88 perfis ABRACEO; 47 novas contas pendentes sem usuários e 47 novos vínculos futuros.
- Conferência autenticada da conta AR2 (#66): CNPJ pendente, logo carregado, 0 usuários, 5 eventos futuros, abas e aviso de titularidade; visualização desktop e móvel de 390 px.
- Planilha recalculada e inspecionada: 47 criadas, 8 empresas pendentes, 47 vínculos confirmados, 37 vínculos pendentes; nenhuma ocorrência dos erros de fórmula pesquisados.

A tentativa anterior de testar em PostgreSQL local isolado foi impedida por falta de recursos de memória compartilhada do sistema. A validação efetiva foi feita pelas transações reversíveis no PostgreSQL de produção.

## Recuperação

Backup recuperável em `/var/backups/business-abraceo-revisao55-20261011`: `baseline/` contém os 3 arquivos anteriores; `candidate/` os 50 publicados; `database-before.json` registra a baseline; `commit.json` registra IDs criados; `verified.json` registra a conferência. O operador de publicação restaura arquivos em falha parcial, desde que não haja alteração concorrente.

Para recuperação posterior, comparar hashes e referências atuais antes de restaurar. Não executar novamente a importação: o operador exige baseline inalterada e bloqueia um segundo commit. Preservar migração e dados quando apenas runtime precisar ser recuperado. Não remover contas, perfis ou vínculos sem verificar uso posterior e obter autorização para eventual exclusão. A migração não deve ser revertida enquanto houver documentos pendentes.
