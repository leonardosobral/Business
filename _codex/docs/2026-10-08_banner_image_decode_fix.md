# Banners: falha de decodificação de imagens

Publicado em produção e verificado em 08/10/2026, às 15:53 BRT.

## Resultado

Corrigida a incompatibilidade entre o acesso a objetos Java pelo Adobe ColdFusion e os leitores ImageIO no Java 17. Corrigida também a mensagem secundária de URLs HTTPS, que aparecia quando o upload já havia falhado. Somente dois arquivos de runtime foram publicados; não houve alteração de banco, credenciais, configuração JVM, permissões de diretórios ou reinício do serviço.

## Causa comprovada

JPG, PNG e GIF válidos eram recusados antes da leitura dos pixels. Uma sonda privada, limitada ao loopback do servidor, revelou `InaccessibleObjectException`: o ColdFusion tentava inspecionar a classe não pública `javax.imageio.ImageIO$ImageReaderIterator` ao chamar `hasNext()`. Os provedores concretos JPG/PNG/GIF também pertencem a pacotes internos do Java não exportados.

O helper agora invoca os métodos pelos contratos públicos `Iterator`, `ImageReader`, `IIOMetadata`, `Element` e `NodeList`. Não utiliza `setAccessible`, `--add-opens` nem relaxa o encapsulamento do Java. Os contratos utilizados estão documentados nas APIs oficiais de [ImageReader](https://docs.oracle.com/en/java/javase/17/docs/api/java.desktop/javax/imageio/ImageReader.html) e [Method.invoke](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/reflect/Method.html).

Os limites de 10 MiB e 40 megapixels continuam sendo verificados antes de decodificar. As verificações do canvas e dos quadros GIF, a preservação dos bytes originais e o fechamento dos recursos continuam ativos. O helper compartilhado mantém a assinatura e o retorno utilizados pelos banners pagos.

No backend HOUSE, a validação HTTPS deixa de emitir uma mensagem adicional apenas quando já existe um erro de upload por campo. Esse erro continua bloqueando o salvamento; uploads bem-sucedidos ainda precisam gerar URLs HTTPS.

## Escopo e hashes SHA-256

| Arquivo | Baseline local e produção | Publicado |
| --- | --- | --- |
| `portal/includes/banner_form_helpers.cfm` | `19b0b58d9d016389ae02af0ba6a1a59608150588e5835aa84d30858f41bd7c0f` | `0ce6cff269a1097fd9369379c11de750217b41cbd12464217be7b52e35252d07` |
| `portal/includes/banner_management_backend.cfm` | `f56124a6c35f9be5b49808cf347892fe1975875dfc7564b6fa6daf802a3a9b1a` | `351127888339b6ec9a652f09b10f0a4099e24f623e463057901ba314b3a11e48` |

Baseline de produção reconferido imediatamente antes da publicação. Os arquivos foram substituídos individualmente de forma atômica, mantendo os respectivos donos, grupos e modo 0644. Hashes finais de produção conferem com os arquivos locais revisados. Não foi feito commit, push ou PR.

## Verificação

- Reprodução antes da correção: oito falhas nos testes de imagem, incluindo rejeição do JPG 1140 × 451; a mensagem HTTPS indevida também foi reproduzida isoladamente.
- Compilador nativo do servidor: dois templates, dois compilados com sucesso.
- Teste nativo de imagens: 22 verificações aprovadas antes e depois da publicação. Inclui JPG, PNG, GIF, animação, canvas diferente do primeiro quadro, extensão enganosa, bytes preservados, arquivos truncados/falsos, excesso de tamanho/pixels e liberação dos arquivos temporários.
- Teste nativo multipart: 22 verificações aprovadas antes e depois da publicação. Inclui desktop/mobile JPG 1140 × 451, nome com espaço e vírgula, dimensões extraídas do arquivo em vez do formulário, URLs seguras, erro de imagem mobile com limpeza do upload parcial, HTTP recusado, CSRF inválido e usuário sem permissão.
- O teste multipart utiliza o bloco real de salvamento HOUSE, `cffile`, parser, validações e limpeza. Somente o SQL e o redirecionamento final são substituídos por captura de resultados, e o destino dos arquivos é temporário. Nenhuma campanha foi criada ou alterada e nenhum arquivo foi colocado no diretório real de banners.
- Revisão independente dos dois diffs: nenhum achado crítico, importante ou menor.
- Página pública de banners: HTTP 302 para autenticação, sem erro 500. Isso não substitui um teste de salvamento pela sessão do usuário.
- As cinco sondas temporárias ficaram inacessíveis externamente (HTTP 404), foram retiradas do webroot e, após a retirada, retornaram HTTP 404 também via loopback.
- `git diff --check`: aprovado.

O JPG original `mim.jpg` não foi anexado: recebemos apenas a captura da tela. O teste nativo utilizou um JPG padrão gerado com as mesmas dimensões exibidas, 1140 × 451. Não foi submetido um banner real pela sessão do usuário.

Os testes regressivos permanecem em `_codex/tests/banner-image-validation.cfm` e `_codex/tests/banner-upload-lifecycle.cfm`. Exigem um runner autorizado e privado; não são endpoints públicos. O runner, o gerador de fixtures e o script multipart utilizados estão arquivados no backup indicado abaixo. Para repetir os testes, recrie os caminhos temporários documentados nos scripts, execute exclusivamente via loopback e retire novamente as sondas do webroot.

### Suíte Node mais ampla

Comando: `node --test _codex/tests/*.test.js _codex/tests/*.test.cjs _codex/tests/*.test.mjs`.

Antes e depois: 382 testes, 376 aprovados, as mesmas seis falhas preexistentes. Não houve nova falha:

1. `google-agenda-browser.test.js`: dependência `jsdom` ausente.
2. `google-agenda-schema.test.js`, “PostgreSQL migration is repeatable and enforces one account and one event per card”: dependência `@electric-sql/pglite` ausente.
3. `google-drive-schema.test.js`, “Drive migration is repeatable and enforces one valid root”: mesma dependência ausente.
4. `mif-report-deployment-contract.test.js`, “modular manifest passes portable privacy and hash verification”: executável Python configurado para outra máquina indisponível.
5. Mesmo arquivo, “the modular feature never changes the existing registrations screen”: comparação histórica encontra alterações já existentes em `inscricoes/home.cfm` e `inscricoes/includes/backend.cfm`.
6. `seo_marathons_heading.test.mjs`: import absoluto de um diretório de outra máquina indisponível.

Não foram instaladas dependências ou modificados testes de outras frentes para mascarar esses resultados. Logs completos baseline e pós-alteração estão junto ao backup.

## Backup e recuperação

Servidor `rr-prod`, diretório privado:

`/var/backups/business-banner-image-20261008-IntiH9eB`

Contém os dois arquivos originais com metadados preservados, `baseline.sha256`, logs Node, as sondas retiradas em `test-probes`, o estágio/scripts em `test-stage` e as imagens de teste em `test-fixtures`. A retirada das sondas é recuperável. Nenhum dado de usuário foi apagado.

Uma eventual reversão deve conferir os hashes atuais para não sobrescrever trabalhos posteriores e restaurar somente esses dois arquivos a partir do backup. As sondas não devem ser recolocadas publicamente sem a proteção de loopback. O backup não contém uma cópia do banco, pois esta tarefa não alterou dados.
