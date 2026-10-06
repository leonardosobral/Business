# SEO — captura automática de alterações factuais — 04/10/2026

Publicado no banco compartilhado de eventos, sob responsabilidade de cadastro Business: tabela privada `public.tb_evento_fatos_historico`, função `registra_evento_fatos_historico()` e triggers AFTER INSERT/UPDATE/DELETE em eventos e percursos. A captura futura ocorre na transação de origem; alterações revertidas não deixam fatos de teste persistidos. UPDATE sem diferença nos campos acompanhados não gera registro. INSERT/DELETE conservam os campos acompanhados com antes/depois; reassociação conserva o evento anterior. Sem backfill.

São acompanhados identificadores, nome/tag, datas, localização, categorias/tipo, status, links públicos e ativo do evento; identificadores, distância/unidade, data/horários e tipo do percurso. Não são guardados descrições, atletas/resultados, IP, operador ou sessão. Um link cadastrado não comprova fonte conferida. Esta captura privada não publica automaticamente fatos ou histórico público nem atesta exatidão. O histórico público dos oito eventos já revisados permanece curado manualmente. Administradores do banco continuam capazes de alterar dados; não é trilha inviolável nem captura TRUNCATE.

A função usa SECURITY DEFINER, search_path somente pg_catalog, escrita explicitamente qualificada e validação da origem do trigger; nenhuma permissão de tabela existente muda. A tabela e sequence novas não têm grants não-owner, e runner não tem acesso direto a elas nem EXECUTE direto na função. Os triggers permitem continuar a escrita já autorizada pelo usuário da aplicação.

## Validação e publicação

- 27 cenários PostgreSQL passaram no candidato e novamente com a definição recuperada de produção: INSERT/UPDATE/DELETE, no-op, nulos, campos excluídos, mudança de IDs e de evento de percurso, origem inválida, rollback e lote de mil inserções/atualizações. O recibo está vinculado aos bytes efetivamente testados.
- Ensaio real de instalação, inversão estrutural e falha forçada, todos revertidos. Probe SET LOCAL ROLE runner alterou uma data de evento e uma de percurso, confirmou as duas capturas e reverteu ambas. ACLs reais em public conferidas, além dos testes temporários.
- Publicação aditiva com lock curto, baseline de tabelas/triggers/owners/ACLs confrontado com a inspeção revisada, hashes integrais de todas as linhas de eventos/percursos idênticos antes/depois. Nenhum cadastro foi corrigido nesta implantação.
- Revisão independente aprovada após fechar search_path, vínculo do hash de testes e probe com usuário real. Definição publicada, índices, constraints, defaults, ACLs e triggers conferidos; metadados existentes preservados.
- Três páginas públicas RoadRunners responderam 200 sem erro CFML, com canonical/alternates/JSON-LD iguais aos controles anteriores.

Migração: `_codex/sql/2026-10-04_evento_fatos_historico.sql`. Scripts e recibos: `_codex/staging/seo-fact-change-log-20261004/`. Backup de produção: `/var/backups/seo-fact-change-log-20261004-v2`. A primeira pasta sem v2 contém somente um candidato anterior ensaiado e revertido; não foi publicado.

Rollback operacional: `release.py rollback` confere a definição esperada e remove apenas os dois triggers e a função. Preserva a tabela e os registros capturados. A inversão que remove também a tabela só foi ensaiada vazia dentro de transação revertida. Não executar o SQL completo de remoção em histórico com dados. Nenhuma credencial, membership, proteção de infraestrutura ou rotina de aplicação foi alterada.

## Painel e continuidade

Business: um arquivo `portal/includes/seo_queue_data.cfm` compilado, publicado e conferido por hash. Relatório e fila reais renderizados antes/depois com a evidência nova e oito eventos revisados no resumo; cinco dependências preservadas. Backup `/var/backups/seo-fact-change-log-panel-20261004/baseline` e recibos em `_codex/staging/seo-fact-change-log-panel-20261004/`.

Fila mantém 24 itens, 18 concluídos e seis pendentes. SH-02 parcial: gestão de fontes e aprovação no formulário ainda não implementadas; divergências factuais continuam pendentes. Datas e notas históricas de auditoria, evidência Google e pendência de recuperação da indexação não foram alteradas. Não houve nova auditoria ampla, nova consulta Google, mudança de resultados pessoais ou comprovação de citações por IA.
