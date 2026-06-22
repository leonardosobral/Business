# Importacao de arquivos no CRM

## Regra de vinculo

Todo upload de arquivo deve ser vinculado a um evento de `public.tb_evento_corridas`.
Na tela, o operador escolhe entre os eventos ativos ligados a conta em
`public.tb_conta_eventos`. Esse e o vinculo canonico para cruzar depois com
`public.tb_resultados` e encontrar o `id_usuario` de quem reconheceu/correu a prova.

O `cod_evento` externo e opcional. Use quando existir um codigo do parceiro ou da
plataforma de inscricao. Para planilhas avulsas, pode ficar vazio.

## Fluxo no /crm

1. Abrir `/crm`.
2. Em `Importar arquivo de inscritos`, escolher o evento Road Runners da conta.
3. Informar a fonte: por exemplo `excel`, `csv`, `foco` ou outro identificador do parceiro.
4. Informar `Codigo externo` somente se a origem tiver esse codigo.
5. Manter `Layout = Auto` para arquivos com cabecalho.
6. Usar `Layout = MIF 2017 sem cabecalho` para a planilha antiga nesse formato.
7. Usar `Cabecalho = 0` para arquivos sem cabecalho, preenchendo o mapeamento manual.
8. Se necessario, abrir `Mapeamento manual` e informar letras de coluna ou nomes de
   cabecalho para sobrescrever o mapeamento automatico.
9. Enviar `.xlsx`, `.xls` ou `.csv`.

## Mapeamento de campos

O sistema tenta mapear automaticamente pelos nomes das colunas, reconhecendo
variacoes comuns como:

- nome, nome completo, atleta inscrito
- email
- cpf, documento, doc
- nascimento, data de nascimento, DN
- sexo
- telefone, celular, whatsapp
- cidade, estado, UF, pais
- numero, numeral, numero de inscricao, pedido, protocolo
- percurso, distancia, modalidade, categoria
- status, situacao
- cupom, camiseta, assessoria, origem, campanha
- data do pedido, data de pagamento, valor

O bloco `Mapeamento manual` permite sobrescrever campos pontuais. Cada campo aceita:

- letra de coluna: `A`, `B`, `AA`
- numero da coluna: `1`, `2`, `27`
- nome exato ou normalizado do cabecalho: `Nome completo`, `Data de Nasc.`

Se o sistema nao identificar a coluna de nome, a importacao e bloqueada para evitar
leads invalidos. Nesse caso, preencha `Nome` no mapeamento manual, ajuste a linha de
cabecalho ou escolha um layout especial.

## Gravacao no banco

O upload cria uma linha em `crm.tb_crm_importacoes`, grava as linhas brutas em
`crm.tb_crm_importacao_linhas` e depois executa
`crm.crm_processar_importacao_arquivo(id_crm_importacao)`.

Esse processamento consolida:

- pessoas em `crm.tb_crm_pessoas`
- participacoes em `crm.tb_crm_participacoes`
- match com resultados Road Runners via `crm.crm_match_resultados`
- match com usuarios Road Runners via `crm.crm_match_usuarios`
