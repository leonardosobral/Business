-- Pedido ao DBA: valores originais do PDF, não recálculos da base atual.
-- Substituir NULL quando a referência original for recuperada; salvar e congelar.
WITH pedidos(pagina,serie,categoria,valor,unidade,responsavel) AS (VALUES
 ('P03','volume_anual','2023',NULL::numeric,'participacoes','DBA'),
 ('P03','volume_anual','2024',NULL::numeric,'participacoes','DBA'),
 ('P03','volume_anual','2025',NULL::numeric,'participacoes','DBA'),
 ('P09','regioes_feminino_rotulos_visiveis','Norte',NULL::numeric,'percentual','DBA'),
 ('P09','regioes_masculino_rotulos_visiveis','Norte',NULL::numeric,'percentual','DBA')
) SELECT * FROM pedidos
