# Geolocalização autônoma — fontes e revisão rápida

Solicitação de 17/10/2026: completar a automação existente pesquisando páginas oficiais e regulamentos, aplicar apenas locais confiáveis e manter município como sugestão. Revisão rápida sem justificativa obrigatória. Implementar, testar e publicar; dispensa anterior de novas pausas de planejamento continua válida.

## Resultado e abordagem

O cron existente percorre o acervo sem seleção manual. Antes do Geoapify, pesquisa até duas URLs do cadastro (`url_hotsite`, `url_inscricao`) e links explícitos de regulamento/site oficial encontrados nelas. Não usa busca genérica paga, credenciais de terceiros ou IA para adivinhar endereços. Leitura determinística de HTML/JSON-LD e PDFs textuais; imagens/PDFs sem texto ou fontes indisponíveis resultam em município/situação explícita, nunca coordenadas inventadas. Pesquisa limitada não significa cobertura de toda a internet.

Alternativas consideradas: somente campos locais (insuficiente, versão atual); pesquisa genérica com agente/serviço novo (mais custo e dependências, não necessário para fontes vinculadas); extrator limitado integrado ao cron (selecionado). Sem contratação ou instalação de dependências.

## Componentes

- `source_fetcher.py`: Python 3 já instalado; processo fixo via CFExecute, sem shell. GET público HTTPS, valida URL e todos os endereços DNS; conecta ao IP público validado com TLS/SNI do hostname. Revalida cada redirecionamento. Não recebe cookies/segredos. Limites: 12 s totais, quatro documentos, HTML 1 MiB, PDF 3 MiB, redirects três, oito MiB totais. Consulta robots.txt com cache; respeita disallow e não contorna autenticação/antibot.
- `Sources.cfc`: cache por snapshot/versão; extrai PDF em memória com CFPDF, até 12 páginas; interpreta JSON-LD Event e trechos explícitos de local/lar­gada. Evidências limitadas, hash, URL, método e data da coleta vão à decisão/auditoria, não os documentos completos.
- `Policy.cfc`: mantém geografia exata, building/amenity e confiança 0,95; endereço completo/venue são campos distintos. Exige nome da prova e data da edição nas fontes externas. Registros contraditórios, local indefinido, kit, outra edição e coordenada aproximada não recebem aprovação automática.
- `Worker`/`Store`: nova versão do snapshot inclui nome, data e URLs, preserva CAS de fonte e coordenada. Itens antigos sem coordenadas entram automaticamente na nova versão; coordenadas existentes nunca são substituídas. Cache de evidência sete dias, negativo um dia. Sem migração nova. Respeita orçamento Geoapify existente de 1.000/dia e 45 s por execução.
- Interface: revisão específica e sugestões municipais separadas; evidência clicável e mapa. Aprovar/descartar e avançar para o próximo sob filtros atuais; justificativa opcional, auditando ator, timestamp e ação padrão. Aprovação ainda exige candidato específico, revisão atual e confirmação. Município nunca é aprovado como largada.

## Segurança, limites e comportamento

Fontes externas são dados não confiáveis, não instruções. URLs privadas/loopback/link-local/multicast, credenciais, tokens, portas não padrão e protocolos não HTTPS são rejeitados; HTTP cadastrado é tentado como HTTPS, sem downgrade. Processos usam executável/script fixos e argumento base64 JSON, sem interpolação de shell. No máximo um acesso por host por segundo dentro do processo; cache de robots compartilhado e documentos não são baixados em cada visita ao painel. Links seguidos precisam ser explícitos de regulamento, PDF ou site oficial; sem varredura recursiva irrestrita. Não usa painel autenticado como fonte.

Nomes/datas/URLs passam a compor a identidade da fonte; mudanças invalidam aprovação antiga. A versão nova do pipeline invalida propostas anteriores para reanálise automática. Aplicação continua transacional com auditoria. Pesquisa indisponível não equivale a localização exata; mantém evidências cadastrais e cidade, com motivo visível. Dados ausentes não bloqueiam o restante do acervo. Automação inclui históricos após próximos/em andamento, inativos por último; não altera ativação dos eventos.

## Verificação e publicação

Testes Python sem rede: SSRF, DNS misto, credenciais, redirects, limites, robots, descoberta de regulamento e extração HTML. CF nativo: JSON-LD compatível, edição errada, endereço de kit, conflito de locais, PDF textual, cache, policy, snapshot obsoleto e revisão sem motivo. Integrações transacionais revertem fixtures, sem alterar eventos reais. Smoke real de fontes públicas é separado e não aplica coordenadas; execução real do cron somente após publicação e verificação.

Preservar árvore suja; nenhum Git commit/push. Publicação somente arquivos deste módulo, baseline por hash, backup recuperável, guards e tela autenticada reais. Datasource, credenciais e permissões não são modificados.
