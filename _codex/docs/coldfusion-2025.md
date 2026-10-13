# Compatibilidade com ColdFusion 2025

A revisão de outubro de 2026 remove os seguintes usos incompatíveis do código CFML:

- `HTMLEditFormat`: substituído por `encodeForHTML` no texto e `encodeForHTMLAttribute` nos atributos HTML. A codificação de URL e o escape JavaScript existentes foram preservados.

- `cfheader`: removido `statusText`, preservando os códigos HTTP, as condições de acesso e os demais cabeçalhos.

- `new http()`: substituído por `cfhttp`/`cfhttpparam`, com resultado no escopo local da função. URLs, parâmetros, assinaturas, timeouts e tratamento das respostas foram preservados.


Estas alterações não modificam contratos de API nem configurações de ambiente. Antes de publicar, validar no Adobe ColdFusion 2025 as páginas afetadas, os fluxos autenticados e as respostas de erro; análises estáticas e testes Node não substituem essa validação.

Nas integrações HTTP, conferir respostas JSON válidas/inválidas, falhas de rede e códigos não 2xx, sem disparar notificações ou outras ações reais durante os testes.


Referências: [recursos removidos](https://guides.adobe.com/coldfusion/en/docs/introduction-to-coldfusion/deprecated-features.html) e [cfhttp](https://guides.adobe.com/coldfusion/en/docs/cfml-reference/__references__/cfhttp.html).
