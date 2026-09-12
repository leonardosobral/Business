# UF física — rechecagem de 12/09/2026

## Resultado

O bloqueio do provedor continua no caminho nativo do ColdFusion. Não foi alterada
a configuração, o provedor, o proxy nem a fonte de IP. O cache negativo local não
foi publicado e não deve ser apresentado como correção do bloqueio.

O teste de terminal respondeu HTTP 200, mas não representa a integração CFHTTP.
A execução CFML nativa, às 09:17:53–09:17:55 de Brasília, retornou HTTP 403 nas
duas chamadas (requisição padrão e controle com endereço público de teste).
A resposta foi classificada como HTML com sinais de Cloudflare, challenge e
captcha; não foram identificados sinais de rate limit, autorização ou cabeçalho
Retry-After. A classificação é indício do motivo do bloqueio, não confirmação
administrativa do provedor. Não se tentou contornar ou resolver o desafio.

As variáveis de provedor primário, secundário e legado estavam ausentes. O teste
não consultou visitante real, datasource ou sessão. Não armazenou IPs de usuários,
corpo da resposta externa, cookies ou token no relatório.

## Isolamento e encerramento

Foi reutilizado o classificador efêmero já revisado, com Application isolado,
sessões desativadas, sem datasource, acesso Apache somente local, token temporário
e expiração. O bloqueio externo foi conferido antes da instalação da aplicação;
a ausência de token foi recusada antes de qualquer chamada geográfica.

- Rota temporária: `/rr-geo-native-Ts9pLO/`.
- Encerramento: 12/09/2026, 09:17:56 de Brasília; rota removida do webroot e HTTP
  404 confirmado.
- Cópia recuperável privada: `/var/tmp/rr-geo-native-Ts9pLO-closed`, root:root,
  modo 700. Nenhum arquivo da aplicação existente foi sobrescrito.
- Artefatos locais do teste: `/private/tmp/rr-geo-recheck.suRiJK` (inclui material
  efêmero; não publicar nem incorporar ao repositório).

## Consequência para o plano

A audiência comercial por contexto continua separada da UF física. Uma pessoa
em SP procurando provas em SC pertence à audiência comercial de SC; isso não
autoriza preencher sua UF física com SC, nem com a UF do perfil.

A recuperação da UF física depende de uma origem confiável liberada para a
integração ou de um transporte confiável de localização validado na infraestrutura.
Essa pendência não impede contagem de páginas/posições nem a correção dos estados
de inventário. A suíte offline existente de cache de localização passou novamente:
30 verificações, zero falhas; nenhuma publicação desse arquivo foi feita.

## Alternativa pesquisada na continuação de 12/09 — não ativada

GeoJS é um candidato para validação, não uma correção já comprovada. A
[documentação oficial](https://www.geojs.io/docs/v1/endpoints/geo/) oferece consulta
HTTPS de IP com país, região e cidade. O
[projeto oficial](https://github.com/jloh/geojs) descreve uma instância gratuita;
os [termos](https://www.geojs.io/tos/) permitem limitação ou bloqueio por uso
excessivo e não garantem disponibilidade. A
[política de privacidade](https://www.geojs.io/privacy/) declara ausência de logs
de acesso, logs de erro e passagem do tráfego pela Cloudflare. Isso não garante
compatibilidade com o CFHTTP nem elimina a necessidade de aprovar o fornecedor.

Contrato local inspecionado em `RoadRunners/services/LocationResolver.cfc:276-340`:
o normalizador atual espera `countryCode`, `regionName` e `regionCode` (ou campos
legados); o GeoJS usa `country_code` e `region` com nome do estado. Portanto,
trocar somente a URL produziria fallback, não UF confiável. Uma integração deve
mapear explicitamente país e nome do estado, reutilizar a conversão brasileira
existente e preservar estado desconhecido quando faltarem dados. A URL com
`geo.json?ip=` admite o formato de concatenação usado pelo resolver, mas ainda
precisa de teste de transporte nativo e normalização.

Antes de habilitar consultas de visitantes, obter autorização para enviar IP ao
novo destinatário `get.geojs.io`, apenas para geolocalização aproximada, sem ID de
usuário, cookies ou histórico de navegação. Validar primeiro com endereços públicos
de teste, não com visitantes reais. Nenhuma requisição à API GeoJS, troca de
provedor, adaptação de código, acesso a servidor/banco, contratação ou publicação
foi realizada nesta pesquisa. As leituras externas foram apenas documentação.
