# Duplicidades confirmadas e descrições regionais — 30/10/2026

## Evidência e prioridade

A auditoria Semrush de 29/10/2026, 09:32 de Brasília, campanha 26661911, terminou com 5.000 páginas/móvel/JS desativado: Site Health 73%, IA 84%, 64 erros, 8.388 advertências e 1.643 observações. Comparativo com 24/10 às 23:40: saúde 79 → 73, erros 20 → 64. Fontes completas em `Business/_codex/staging/seo-reaudit-20261030/`.

Os 34 achados de descrição duplicada foram coletados em quatro páginas da interface. Contêm 30 URLs regionais e quatro fichas de duas provas. Não excluir verificações ou URLs do escopo para elevar a nota.

## Runtime RoadRunners

Somente `estado/index.cfm` alterado nesta rodada. Calendários com mais de uma página passam a ter a página atual/total na descrição, acompanhando os dados já usados no corpo. Exemplo: “Calendário de corridas na Bahia. Página 2 de 4. Consulte datas, distâncias e inscrições das provas de rua e trail.” Calendários de uma página preservam a descrição anterior. Sem alteração de títulos, canonical, filtros, noindex, contagens ou paginação.

Baseline local coincidia com produção, incluindo as melhorias anteriores. Um template compilado, seis cenários Adobe (BA/PR páginas 1/2, Curitiba e AC), metadados distintos e canonicals preservados. Publicado às **15:29:01 (Brasília)**; um hash e cinco dependências compartilhadas preservadas. Backup `/var/backups/seo-duplicidades-20261030-runtime/baseline`. Código sincronizado sob guarda de hashes, sem operações Git.

## Dados das provas

### ADC ZF Clube

- 48501 (`2026-corrida-adc-zf-clube`) e 49606 (`2027-corrida-adc-zf-clube`) apontam para o mesmo evento Ticket Sports 88536.
- [Fonte oficial](https://www.ticketsports.com.br/e/CORRIDA+ADC+ZF+CLUBE-88536) confirma **24/01/2027**, Sorocaba (SP), corridas de 4/8 km e caminhada. Retirada de kits a informar.
- Ambas as datas gerais já eram 24/01/2027; a URL com prefixo 2026 não identifica outra edição histórica. 48501 foi inativado e recebeu `tag_301` para 49606. Seus dois percursos antigos ficaram intactos. Os percursos do alvo já estavam na data correta.
- Resumo factual PT/EN/ES no alvo, com hashes MD5 das traduções coerentes com o texto PT. Nenhum dado comercial/preço foi inferido.

### Outubro Rosa de Chupinguaia

- 48554 (`2026-corrida-e-caminhada-outubro-rosa-ro`) e 48918 (`2026-corrida-e-caminhada-outubro-rosa-chupinguaia`) apontam para o mesmo evento Sympla 3594186.
- [Fonte oficial](https://www.sympla.com.br/evento/corrida-e-caminhada-outubro-rosa/3594186) confirma **31/10/2026**, 6h, em frente ao Sicredi, Chupinguaia (RO), 5 km. Cabeçalho e texto atuais concordam; a descrição antiga do catálogo ainda dizia 25/10.
- Datas gerais dos dois cadastros já eram 31/10. 48554 foi inativado com 301 para 48918, cujo percurso já estava em 31/10. O percurso antigo da duplicada permaneceu intacto. Resumo factual PT/EN/ES do alvo atualizado.

### Integridade e restauração

Nenhum registro apagado, nenhuma data geral ou data/flag de percurso alterada. Fontes duplicadas sem resultados, agenda, inscrições/contas, anúncios ou CRM associados. Seis percursos mantiveram IDs e conteúdo integral. Quarenta e seis grupos dependentes mantiveram contagens/hashes, inclusive metadados de geolocalização, matching e processamento de descrições. Associações de agregadores permaneceram vazias no lote.

`release_data.py rehearse`: aplicação transacional com rollback e ensaio da inversa aprovados antes de publicar. Guards comparam integralmente os quatro eventos, os seis percursos, associações e hashes dependentes; aplicação real e verificação posterior passaram. Backup `/var/backups/seo-duplicidades-20261030-data/` inclui baseline, candidato, estado publicado e inversa. `rollback` só atua quando o estado ainda coincide exatamente com o publicado, sem sobrescrever alterações concorrentes. Nada para executar no DataGrip.

## Conferência pública

`verify_public.py`: **44 verificações** — as 34 URLs reportadas, seis 301 (dois pares em PT/EN/ES) e quatro destinos traduzidos. As 30 descrições regionais são distintas; alvos 200 e canonicals corretos. `verify_translations.py`: quatro verificações adicionais comprovam os novos textos EN/ES, sem fallback acidental ao PT. A baixa dos achados pelo fornecedor depende da nova auditoria.

## Business e continuidade

Painel `portal/includes/seo_semrush_data.cfm` e `portal/conteudo/seo_semrush.cfm` atualizados com a fonte real, preservando a base orgânica de 04/10 (51 pares e seis oportunidades). As notas separam a auditoria de 29/10 das correções posteriores de 30/10. Publicado às **15:33:52**, backup `/var/backups/seo-reaudit-20261030-panel/baseline`. Seis testes Python, dois templates compilados, 19 cenários Adobe antes/depois, oito controles de acesso, dois hashes e 11 dependências preservadas. Evidências no staging `seo-reaudit-20261030/panel/`.

Nova auditoria de 5.000 páginas iniciada após as publicações, com as mesmas configurações. Aguardar a conclusão do mesmo processo; não reexecutar por timeout. Painel mantém a última medição concluída (73%) até importar resultado completo. Site Health acima de 80% ainda não demonstrado. GA4 negou leitura em 30/10; nenhuma permissão/credencial alterada. Canonicals/privacidade de resultados pessoais preservados.

Plano central: `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`. Sem commit, push, branch ou PR.
