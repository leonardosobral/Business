"""Synthetic TicketSports exports used by the MIF analysis tests."""

import json
from decimal import Decimal
from pathlib import Path

import pandas as pd

from _codex.analyses.mif_2026_channels.models import FactBundle, SourceBundle


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


def channel_metric_frames(
    counts: dict[str, int] | None = None,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Return mapped, anonymous facts with deterministic channel distributions."""
    counts = counts or {"Canal A": 12, "Canal B": 10, "Canal C": 4}
    registrations: list[dict[str, object]] = []
    orders: list[dict[str, object]] = []
    products: list[dict[str, object]] = []
    states = [("SC", "Florianópolis"), ("PR", "Curitiba"), ("SP", "São Paulo")]
    modalities = ["42K", "21K", "10K"]
    lots = ["Lote 1", "Lote 2"]
    genders = ["Feminino", "Masculino", "Não informado"]

    registration_id = 10_000
    order_id = 20_000
    for channel_position, (channel_name, count) in enumerate(counts.items()):
        for position in range(count):
            registration_id += 1
            order_id += 1
            state, city = states[(position + channel_position) % len(states)]
            gross = Decimal("100.00") + Decimal(str(channel_position * 10))
            registration = {
                "cod_evento": 72611,
                "numero_inscricao": registration_id,
                "numero_pedido": order_id,
                "is_paid": True,
                "channel_name": channel_name,
                "channel_type": "parceiro",
                "coupon_title": channel_name,
                "coupon_code": f"{channel_name.upper().replace(' ', '-')}-{position % 2 + 1}",
                "alias_reason": "identidade sintética revisada",
                "modality": modalities[(position + channel_position) % len(modalities)],
                "lot": lots[position % len(lots)],
                "sale_date": pd.Timestamp("2026-06-01") + pd.Timedelta(days=position % 15),
                "registration_date": pd.Timestamp("2026-06-01") + pd.Timedelta(days=position % 15),
                "country": "Brasil",
                "state": state,
                "city": city,
                "age": 20 + (position % 50),
                "gender": genders[position % len(genders)],
                "pace_seconds": 270 + (position % 10) * 30,
                "club": "Clube Alfa" if position % 2 == 0 else None,
                "questionnaire_present": position % 3 != 0,
                "auxiliary_json_keys": ["modalidade", "lote", "ritmo"],
                "allocated_gross_value": gross,
                "allocated_discount_value": Decimal("5.00"),
                "allocated_fee_value": Decimal("2.00"),
                "allocated_net_transfer_value": gross - Decimal("7.00"),
                "allocated_cashback_value": Decimal("1.00"),
            }
            for field in (
                "modality",
                "lot",
                "sale_date",
                "registration_date",
                "country",
                "state",
                "city",
                "age",
                "gender",
                "pace_seconds",
                "club",
                "questionnaire_present",
                "raw_products",
            ):
                value = registration.get(field)
                registration[f"{field}_status"] = (
                    "nao_informado" if value is None else "valido"
                )
            registrations.append(registration)
            orders.append(
                {
                    "cod_evento": 72611,
                    "numero_pedido": order_id,
                    "is_paid": True,
                    "order_date": registration["sale_date"],
                    "payment_date": registration["sale_date"],
                    "gross_order_value": gross,
                    "discount_value": Decimal("5.00"),
                    "fee_value": Decimal("2.00"),
                    "net_transfer_value": gross - Decimal("7.00"),
                    "cashback_value": Decimal("1.00"),
                    "payment_method": "pix" if position % 2 == 0 else "cartao",
                    "device_type": "mobile" if position % 3 else "desktop",
                    "declared_registration_count": 1,
                    "parsed_registration_count": 1,
                }
            )
            if position % 3 == 0:
                products.append(
                    {
                        "cod_evento": 72611,
                        "numero_inscricao": registration_id,
                        "numero_pedido": order_id,
                        "product_position": 0,
                        "canonical_name": "Camiseta Extra",
                        "classification": "adicional",
                        "product_quantity": 1,
                        "product_revenue": Decimal("65.00"),
                    }
                )
            if position % 5 == 0:
                products.append(
                    {
                        "cod_evento": 72611,
                        "numero_inscricao": registration_id,
                        "numero_pedido": order_id,
                        "product_position": 2,
                        "canonical_name": "Item não revisado comercialmente",
                        "classification": "desconhecido",
                        "product_quantity": 1,
                        "product_revenue": Decimal("12.50"),
                    }
                )
            products.append(
                {
                    "cod_evento": 72611,
                    "numero_inscricao": registration_id,
                    "numero_pedido": order_id,
                    "product_position": 1,
                    "canonical_name": "Kit MIF 2026",
                    "classification": "kit_incluso",
                    "product_quantity": 1,
                    "product_revenue": None,
                }
            )

    return (
        pd.DataFrame(registrations),
        pd.DataFrame(orders),
        pd.DataFrame(products),
    )


def channel_metric_facts() -> FactBundle:
    """Return a mapped FactBundle used by aggregate and reconciliation tests."""
    registrations, orders, products = channel_metric_frames()
    return FactBundle(
        orders=orders,
        registrations=registrations,
        products=products,
        reconciliation={
            "paid_order_count": len(orders),
            "paid_registration_count": len(registrations),
            "channel_mapping_coverage_pct": 100.0,
            "product_mapping_coverage_pct": 100.0,
            "order_field_coverage": {},
            "registration_field_coverage": {},
        },
    )


def analysis_result():
    """Return the complete protected synthetic result for artifact tests."""
    from _codex.analyses.mif_2026_channels.metrics import build_analysis
    from _codex.analyses.mif_2026_channels.privacy import protect_analysis

    return protect_analysis(build_analysis(channel_metric_facts()))


def write_source_exports(root: Path) -> tuple[Path, Path]:
    """Write the small synthetic TicketSports fixture exports."""
    orders = root / "orders.csv"
    participants = root / "participants.csv"
    pd.DataFrame(orders_rows()).assign(
        extracted_at="2026-08-30T22:00:00-03:00"
    ).to_csv(orders, index=False)
    pd.DataFrame(participant_rows()).assign(
        extracted_at="2026-08-30T22:00:00-03:00"
    ).to_csv(participants, index=False)
    return orders, participants


def write_reviewed_mappings(root: Path) -> tuple[Path, Path]:
    """Write exact reviewed mappings for the small synthetic source fixture."""
    channel_mapping = root / "channel-mapping.csv"
    product_mapping = root / "product-mapping.csv"
    pd.DataFrame(
        [
            {
                "coupon_title_key": "PARCEIRO ALFA",
                "coupon_code_key": code,
                "coupon_title_example": "Parceiro Alfa",
                "coupon_code_example": code,
                "paid_registrations": 1,
                "channel_name": "Parceiro Alfa",
                "channel_type": "parceiro",
                "alias_reason": "identidade sintética revisada",
                "reviewed": True,
            }
            for code in ("PARCEIRO ALFA", "PARCEIRO ALFA 2")
        ]
    ).to_csv(channel_mapping, index=False)
    pd.DataFrame(
        [
            {
                "product_id_key": product_id,
                "product_name_key": product_name,
                "product_id_example": product_id,
                "product_name_example": product_name,
                "observed_items": 1,
                "canonical_name": canonical_name,
                "classification": classification,
                "classification_reason": "identidade sintética revisada",
                "reviewed": True,
            }
            for product_id, product_name, canonical_name, classification in (
                ("1", "KIT MIF 2026", "Kit MIF 2026", "kit_incluso"),
                ("2", "CAMISETA EXTRA", "Camiseta Extra", "adicional"),
                ("KIT 21", "KIT 21K", "Kit 21K", "kit_incluso"),
            )
        ]
    ).to_csv(product_mapping, index=False)
    return channel_mapping, product_mapping


def write_study_fixture(root: Path) -> tuple[Path, Path, Path, Path]:
    """Write a richer anonymous raw-source fixture with full and long-tail channels."""
    registrations, orders, products = channel_metric_frames()
    products_by_registration = {
        registration_id: group.to_dict("records")
        for registration_id, group in products.groupby("numero_inscricao")
    }
    registration_by_order = registrations.set_index("numero_pedido")
    order_export = []
    participant_export = []
    for order in orders.to_dict("records"):
        registration = registration_by_order.loc[order["numero_pedido"]]
        order_export.append(
            {
                "cod_evento": 72611,
                "numero_pedido": order["numero_pedido"],
                "data_pedido": order["order_date"].isoformat(),
                "extracted_at": "2026-08-30T22:00:00-03:00",
                "body": json.dumps(
                    {
                        "dataPedido": order["order_date"].date().isoformat(),
                        "dataPagamento": order["payment_date"].date().isoformat(),
                        "status": "pago",
                        "valor": str(order["gross_order_value"]),
                        "desconto": str(order["discount_value"]),
                        "taxa": str(order["fee_value"]),
                        "valorRepassePedido": str(order["net_transfer_value"]),
                        "cashback": str(order["cashback_value"]),
                        "qtdeInscricao": 1,
                        "formaDePagamento": order["payment_method"],
                        "tipoDispositivo": order["device_type"],
                        "cupom": {
                            "titulo": registration["coupon_title"],
                            "codigo": registration["coupon_code"],
                        },
                    },
                    ensure_ascii=False,
                ),
            }
        )
    for registration in registrations.to_dict("records"):
        age = int(registration["age"])
        product_rows = products_by_registration.get(registration["numero_inscricao"], [])
        raw_products = []
        for product in product_rows:
            item = {
                "id": product["canonical_name"].upper().replace(" ", "-"),
                "nome": product["canonical_name"],
                "quantidade": int(product["product_quantity"]),
            }
            if product["product_revenue"] is not None:
                item["valorTotal"] = str(product["product_revenue"])
            raw_products.append(item)
        pace_seconds = int(registration["pace_seconds"])
        participant_export.append(
            {
                "cod_evento": 72611,
                "numero_inscricao": registration["numero_inscricao"],
                "numero_pedido": registration["numero_pedido"],
                "extracted_at": "2026-08-30T22:00:00-03:00",
                "body": json.dumps(
                    {
                        "modalidade": registration["modality"],
                        "lote": registration["lot"],
                        "dataVenda": registration["sale_date"].date().isoformat(),
                        "dataInscricao": registration["registration_date"].date().isoformat(),
                        "valorUnitario": str(registration["allocated_gross_value"]),
                        "valorTaxa": str(registration["allocated_fee_value"]),
                        "valorDesconto": str(registration["allocated_discount_value"]),
                        "valorRepasse": str(registration["allocated_net_transfer_value"]),
                        "cidade": registration["city"],
                        "estado": registration["state"],
                        "pais": registration["country"],
                        "nascimento": f"{2026 - age:04d}-01-01",
                        "sexo": registration["gender"],
                        "ritmo": f"{pace_seconds // 60:02d}:{pace_seconds % 60:02d}",
                        "nome_grupo": registration["club"],
                        "tituloCupom": registration["coupon_title"],
                        "codigoCupom": registration["coupon_code"],
                        "produtos": raw_products,
                    },
                    ensure_ascii=False,
                ),
            }
        )
    orders_path = root / "study-orders.csv"
    participants_path = root / "study-participants.csv"
    pd.DataFrame(order_export).to_csv(orders_path, index=False)
    pd.DataFrame(participant_export).to_csv(participants_path, index=False)

    channel_path = root / "study-channel-mapping.csv"
    channel_rows = []
    for registration in registrations.to_dict("records"):
        channel_rows.append(
            {
                "coupon_title_key": registration["coupon_title"].upper(),
                "coupon_code_key": registration["coupon_code"].replace("-", " "),
                "coupon_title_example": registration["coupon_title"],
                "coupon_code_example": registration["coupon_code"],
                "paid_registrations": 1,
                "channel_name": registration["channel_name"],
                "channel_type": registration["channel_type"],
                "alias_reason": "identidade sintética revisada",
                "reviewed": True,
            }
        )
    pd.DataFrame(channel_rows).drop_duplicates(
        ["coupon_title_key", "coupon_code_key"]
    ).to_csv(channel_path, index=False)

    product_path = root / "study-product-mapping.csv"
    product_rows = []
    for product in products.to_dict("records"):
        product_id = product["canonical_name"].upper().replace(" ", "-")
        product_rows.append(
            {
                "product_id_key": product_id.replace("-", " "),
                "product_name_key": product["canonical_name"].upper(),
                "product_id_example": product_id,
                "product_name_example": product["canonical_name"],
                "observed_items": 1,
                "canonical_name": product["canonical_name"],
                "classification": product["classification"],
                "classification_reason": "identidade sintética revisada",
                "reviewed": True,
            }
        )
    pd.DataFrame(product_rows).drop_duplicates(
        ["product_id_key", "product_name_key"]
    ).to_csv(product_path, index=False)
    return orders_path, participants_path, channel_path, product_path
