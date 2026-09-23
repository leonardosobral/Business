# Controle de horas dos sócios

Rota: `/administracao/ponto/`, menu **Meu ponto**. CFML + PostgreSQL, seguindo o shell do Business.

## Ativação

Aplicar `administracao/ponto/ponto_schema.sql` no datasource `runner_dba` antes de usar as ações. O script é transacional e pode ser reaplicado. A página mostra um estado de aguardando ativação enquanto a função/view estiverem ausentes. Não cria tabelas durante requisições HTTP.

O módulo exige ADMIN global autenticado, bloqueia o contexto de simulação e utiliza o ID do perfil carregado no servidor. ADMIN de uma conta e DEV isoladamente não concedem acesso. Cada sócio consulta e altera apenas seus registros.

## Uso e regras

- **Iniciar / Pausar / Retomar / Finalizar agora**: horas do banco, persistidas independentemente do navegador. Uma jornada aberta por usuário. Pausar fecha um período; retomar abre outro.
- **Corrigir horários**: informa os períodos reais e finaliza a jornada. Para uma pausa esquecida, dividir o período em duas linhas. Permite corrigir datas e incluir trabalho esquecido. Não exige descrição da atividade ou aprovação.
- **Viagem**: uma linha por data, 8h/dia por padrão, valor ajustável no formulário. Sábados e domingos são opcionais; feriados não são descontados automaticamente. Máximo de 366 dias por lançamento. Conflitos invalidam o intervalo inteiro.
- Viagem futura é programada e só entra nos totais quando a data chegar, sem necessidade de confirmação. Cancelar os dias se os planos mudarem. Para alterar um dia de viagem, cancelar e registrar novamente; ambos permanecem no histórico.
- Ponto e viagem não podem contabilizar a mesma data. Períodos de trabalho não podem se sobrepor, inclusive entre jornadas.
- Horários são armazenados como `timestamptz`. Interface, agrupamento diário, semana (segunda-feira) e mês usam **America/Sao_Paulo**, inclusive durante viagens. Não se usa o fuso do navegador.
- Apenas jornadas finalizadas entram nos totais consolidados. Jornadas abertas/pausadas aparecem em destaque, com alerta após 16h; não são encerradas automaticamente.
- A virada de meia-noite é dividida nos totais diários e mensais, respeitando as pausas. A lista de registros mostra o total da jornada completa; os cartões e totais diários respeitam o filtro.
- Históricos antigos continuam consultáveis por intervalo de datas, com paginação de registros. Não há expiração/limpeza automática.
- Cancelamento é lógico. Alterações preservam o antes/depois dos horários, o autor e a data. Não há exclusão física pelo módulo.

## Integridade

Todas as mutações passam por `ponto_registrar`: verifica ADMIN e propriedade, serializa por usuário com advisory lock transacional, compara versões para impedir sobrescrita por abas antigas e grava auditoria na mesma transação. Índices únicos protegem jornada aberta e diária duplicada. Funções não usam `SECURITY DEFINER`.

Formulários usam POST e token CSRF de sessão; parâmetros são tipados. A identidade não vem de campos do formulário. Erros SQL inesperados ficam no log `business_ponto`, sem exposição de detalhes na interface. Horários futuros são rejeitados para trabalho, mas permitidos para programar viagens.

O modelo é um acompanhamento interno dos sócios. Permissões para funcionários, aprovação, integração com folha, banco de horas, exportação e metas individuais ficam fora desta primeira versão.

## Validação local

Banco PostgreSQL isolado via PGlite, sem conexão com produção:

```sh
PONTO_PGLITE_MODULE=/caminho/node_modules/@electric-sql/pglite/dist/index.js \
  node _codex/tests/ponto/database.mjs
```

Compilação/renderização CFML com Lucee 6 e Java 17, consultas simuladas na fronteira de acesso a dados e execução das consultas reais de leitura no PostgreSQL isolado:

```sh
PONTO_CFML_RUNTIME=/caminho/runtime \
PONTO_JAVA=/caminho/java17/bin/java \
PONTO_PGLITE_MODULE=/caminho/node_modules/@electric-sql/pglite/dist/index.js \
  node _codex/tests/ponto/cfml.mjs
```

O diretório do runtime deve conter `lucee.jar`, `servlet.jar` e `jsp.jar`. O teste não baixa dependências, não executa `Application.cfc` e produz uma página HTML temporária para inspeção visual. Ainda é necessário validar a integração do shell/autenticação no Adobe ColdFusion do ambiente de destino após a migração.
