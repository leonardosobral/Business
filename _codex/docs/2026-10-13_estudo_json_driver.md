# Recuperação do leitor do estudo — 13/10/2026

Sintoma: /estudos/leitor/?ano=2026 exibia “A edição está indisponível”. O HTTP200 retornava JSON truncado; o driver/datasource entregava exatamente64.000 caracteres de cada colunaTEXT/VARCHAR. Publicação41 original tinha648.499 caracteres; a projeção profissional completa527.114. Não havia perda no congelamento nem falta de autorização.

Correção em estudos/includes/StudyAccess.cfc: a consulta autorizada e a seleção editorial permanecem iguais. Uma CTE materializada entrega blocos ordenados de16.000 caracteres na mesma consulta/snapshot; CF remonta, confere comprimento e validadeJSON. Não altera DS, queries do DBA, congelamentos, permissões ou acesso comercial. Preservada a mudança preexistente de validação de e-mail.

Compilação com /opt/coldfusion2025/cfusion/bin/cfcompile.sh e teste isolado:113séries,527.114caracteres,ano2026,corte30/09. Em produção:Chrome37páginas/46canvas. HTTP:anônimo302/401;admin200 comJSON completo;ano2025400;conta sem acesso302/403. Teste original falhou antes e passou depois. Backup `/var/backups/study-reader-json-20261013-v2/baseline`; hash verificado. Recibos no RoadRunners/_codex/staging/reader-json-20261013/.

Depois da correção, o usuário informou ter aumentado o limite do driver para800.000 caracteres. Leitura em blocos mantida como proteção para crescimento futuro. Outros caminhos de notebook/publicação que leem colunas grandes devem ser avaliados separadamente; esta correção foi restrita ao leitor comercial.
