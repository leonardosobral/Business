"""Synthetic TicketSports exports used by the MIF analysis tests."""

import json
from decimal import Decimal

import pandas as pd

from _codex.analyses.mif_2026_channels.models import SourceBundle


def orders_rows() -> list[dict[str, object]]:
    """Return synthetic order rows with paid and unpaid commercial states."""
    return [
        {
            "cod_evento": 72611,
            "numero_pedido": 1001,
            "data_pedido": "2026-06-01T10:00:00-03:00",
            "body": json.dumps(
                {
                    "dataPedido": "2026-06-01",
                    "dataPagamento": "2026-06-01",
                    "status": "pago",
                    "valor": "600.00",
                    "desconto": "60.00",
                    "taxa": "30.00",
                    "valorRepassePedido": "510.00",
                    "cashback": "6.00",
                    "qtdParcela": 3,
                    "formaDePagamento": "cartao_credito",
                    "tipoDispositivo": "desktop",
                    "qtdeInscricao": 2,
                    "nome": "Pessoa Teste A",
                    "email": "pessoa.teste.a@example.test",
                    "cupom": {"codigo": "PARCEIRO-ALFA", "titulo": "Parceiro Alfa"},
                    "pagamento": {
                        "metodo": "cartao_credito",
                        "status": "aprovado",
                        "valor": 320.0,
                    },
                    "produtos": [
                        {"nome": "Kit MIF 2026", "tipo": "kit_incluso"},
                        {"nome": "Camiseta Extra", "tipo": "adicional", "valor": 65.0},
                    ],
                }
            ),
        },
        {
            "cod_evento": 72611,
            "numero_pedido": 1002,
            "data_pedido": "2026-06-02T11:00:00-03:00",
            "body": json.dumps(
                {
                    "dataPedido": "2026-06-02",
                    "status": "aguardando_pagamento",
                    "valor": "160.00",
                    "valorRepasse": "120.00",
                    "qtdeInscricao": 0,
                    "nome": "Pessoa Teste C",
                    "cupom": {"codigo": "PARCEIRO-ALFA-2", "titulo": "Parceiro Alfa"},
                    "pagamento": {"metodo": "pix", "status": "pendente", "valor": 160.0},
                    "produtos": [{"nome": "Kit MIF 2026", "tipo": "kit_incluso"}],
                }
            ),
        },
    ]


def participant_rows() -> list[dict[str, object]]:
    """Return two registrations linked to the paid synthetic order."""
    return [
        {
            "cod_evento": 72611,
            "numero_inscricao": 2001,
            "numero_pedido": 1001,
            "body": json.dumps(
                {
                    "nome": "Pessoa Teste A",
                    "modalidade": "42K",
                    "lote": "Lote 1",
                    "dataVenda": "2026-06-01",
                    "dataInscricao": "2026-06-01",
                    "valorUnitario": "400.00",
                    "valorTaxa": "20.00",
                    "valorDesconto": "40.00",
                    "valorDescontoCupom": "10.00",
                    "valorRepasse": "340.00",
                    "cidade": "Cidade Teste",
                    "estado": "SC",
                    "pais": "Brasil",
                    "nascimento": "1990-01-15",
                    "sexo": "F",
                    "ritmo": "05:20",
                    "nome_grupo": "Clube Teste",
                    "tituloCupom": "Parceiro Alfa",
                    "codigoCupom": "PARCEIRO-ALFA",
                    "produtos": [
                        {"id": 1, "nome": "Kit MIF 2026", "quantidade": 1},
                        {
                            "id": 2,
                            "nome": "Camiseta Extra",
                            "quantidade": 1,
                            "valorUnitario": "65.00",
                            "valorTotal": "65.00",
                        },
                    ],
                    "questionario": [{"pergunta": "Livre", "resposta": "segredo-teste"}],
                }
            ),
        },
        {
            "cod_evento": 72611,
            "numero_inscricao": 2002,
            "numero_pedido": 1001,
            "body": json.dumps(
                {
                    "nome": "Pessoa Teste B",
                    "modalidade": "21K",
                    "lote": "Lote 1",
                    "dataVenda": "2026-06-01",
                    "dataInscricao": "2026-06-01",
                    "valorUnitario": "200.00",
                    "valorTaxa": "10.00",
                    "valorDesconto": "20.00",
                    "valorDescontoCupom": "5.00",
                    "valorRepasse": "170.00",
                    "cidade": "Cidade Teste",
                    "estado": "SC",
                    "pais": "Brasil",
                    "nascimento": "1988-07-20",
                    "sexo": "M",
                    "ritmo": "04:55",
                    "nome_grupo": "Clube Teste",
                    "tituloCupom": "Parceiro Alfa",
                    "codigoCupom": "PARCEIRO-ALFA-2",
                    "produtos": [{"codigo": "KIT-21", "produto": "Kit 21K"}],
                }
            ),
        },
    ]


def source_bundle() -> SourceBundle:
    """Return one paid multi-registration order plus one unpaid order."""
    return SourceBundle(
        event_code=72611,
        orders=pd.DataFrame(orders_rows()),
        participants=pd.DataFrame(participant_rows()),
        snapshots=(),
        source_hashes={"orders": "synthetic-orders", "participants": "synthetic-participants"},
    )


def mapping_registration_fact() -> pd.DataFrame:
    """Return reviewed synthetic coupon identities, including organic sales."""
    return pd.DataFrame(
        [
            {
                "numero_inscricao": 3001,
                "coupon_title": "CORRECRICIUMA",
                "coupon_code": "CORRECRICIUMA",
                "is_paid": True,
            },
            {
                "numero_inscricao": 3002,
                "coupon_title": "CORRECRICIUMA",
                "coupon_code": "CORRECRICIUMA_100",
                "is_paid": True,
            },
            {
                "numero_inscricao": 3003,
                "coupon_title": "Sports Week",
                "coupon_code": "SPORTS-WEEK",
                "is_paid": True,
            },
            {
                "numero_inscricao": 3004,
                "coupon_title": "PCD",
                "coupon_code": "PCD",
                "is_paid": True,
            },
            {
                "numero_inscricao": 3005,
                "coupon_title": "Benefício",
                "coupon_code": "BENEFICIO",
                "is_paid": True,
            },
            {
                "numero_inscricao": 3006,
                "coupon_title": None,
                "coupon_code": None,
                "is_paid": True,
            },
            {
                "numero_inscricao": 3007,
                "coupon_title": "Sports Week",
                "coupon_code": "SPORTS-WEEK",
                "is_paid": False,
            },
        ]
    )


def mapping_product_fact() -> pd.DataFrame:
    """Return included, add-on, and unknown synthetic product identities."""
    return pd.DataFrame(
        [
            {
                "product_id": "CAM-INCLUSA",
                "product_name": "Camiseta inclusa",
                "product_quantity": 1,
                "explicit_unit_value": None,
                "explicit_total_value": None,
            },
            {
                "product_id": "CAM-EXTRA",
                "product_name": "Camiseta extra",
                "product_quantity": 2,
                "explicit_unit_value": Decimal("65.00"),
                "explicit_total_value": None,
            },
            {
                "product_id": None,
                "product_name": "Item sem classificação comercial",
                "product_quantity": 1,
                "explicit_unit_value": None,
                "explicit_total_value": Decimal("12.50"),
            },
        ]
    )
