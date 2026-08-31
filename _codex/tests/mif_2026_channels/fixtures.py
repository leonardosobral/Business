"""Synthetic TicketSports exports used exclusively by source-loader tests."""

import json


def orders_rows() -> list[dict[str, object]]:
    """Return synthetic order rows with paid and unpaid commercial states."""
    return [
        {
            "cod_evento": 72611,
            "numero_pedido": 1001,
            "data_pedido": "2026-06-01T10:00:00-03:00",
            "body": json.dumps(
                {
                    "status": "pago",
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
                    "status": "aguardando_pagamento",
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
                    "cidade": "Cidade Teste",
                    "uf": "TS",
                    "data_nascimento": "1990-01-15",
                    "genero": "F",
                    "ritmo": "05:20",
                    "clube": "Clube Teste",
                    "cupom": {"codigo": "PARCEIRO-ALFA", "titulo": "Parceiro Alfa"},
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
                    "cidade": "Cidade Teste",
                    "uf": "TS",
                    "data_nascimento": "1988-07-20",
                    "genero": "M",
                    "ritmo": "04:55",
                    "clube": "Clube Teste",
                    "cupom": {"codigo": "PARCEIRO-ALFA-2", "titulo": "Parceiro Alfa"},
                }
            ),
        },
    ]
