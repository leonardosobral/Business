from dataclasses import replace
from datetime import date
from decimal import Decimal
import json
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.facts import (
    allocate_cents,
    assert_reconciled,
    build_fact_bundle,
    build_order_fact,
)
from _codex.tests.mif_2026_channels.fixtures import source_bundle


def _bundle_with_first_registration_products(
    products: list[dict[str, object]],
):
    bundle = source_bundle()
    participants = bundle.participants.copy()
    body = json.loads(participants.loc[0, "body"])
    body["produtos"] = products
    participants.loc[0, "body"] = json.dumps(body, ensure_ascii=False)
    return replace(bundle, participants=participants)


class FactTests(unittest.TestCase):
    def test_order_and_registration_grains_are_unique(self):
        """Dropping composite-key validation would allow duplicate fact rows."""
        facts = build_fact_bundle(source_bundle())
        self.assertFalse(facts.orders.duplicated(["cod_evento", "numero_pedido"]).any())
        self.assertFalse(
            facts.registrations.duplicated(["cod_evento", "numero_inscricao"]).any()
        )

    def test_two_registrations_join_to_one_order_without_duplicating_order_revenue(self):
        """Joining order money directly to registrations would double the paid gross."""
        facts = build_fact_bundle(source_bundle())
        paid_orders = facts.orders.loc[facts.orders["is_paid"]]
        paid_registrations = facts.registrations.loc[facts.registrations["is_paid"]]
        self.assertEqual(len(paid_orders), 1)
        self.assertEqual(len(paid_registrations), 2)
        self.assertEqual(paid_orders["gross_order_value"].sum(), Decimal("600.00"))
        self.assertEqual(
            paid_registrations["allocated_gross_value"].sum(), Decimal("600.00")
        )
        self.assertNotIn("gross_order_value", facts.registrations.columns)

    def test_product_fact_explodes_every_product_item(self):
        """Failing to explode each registration array would hide an observed product item."""
        facts = build_fact_bundle(source_bundle())
        self.assertEqual(len(facts.products), 3)
        self.assertEqual(set(facts.products["product_position"]), {0, 1})

    def test_product_fact_reads_normalized_id_produto_and_single_dynamic_name(self):
        """Ignoring the real dynamic-name schema would collapse products into blanks."""
        bundle = _bundle_with_first_registration_products(
            [
                {
                    "Id_PrOdUtO": "PROD-900",
                    "ID_Estoque": "EST-1",
                    "Camiseta edição limitada R$ 89,90": "segredo-produto",
                },
                {
                    "id_produto": None,
                    "id_estoque": "EST-2",
                    "Gravação de medalha": None,
                },
            ]
        )

        products = build_fact_bundle(bundle).products
        observed = products.loc[products["numero_inscricao"] == 2001].reset_index(
            drop=True
        )

        self.assertEqual(list(observed["product_id"]), ["PROD-900", None])
        self.assertEqual(
            list(observed["product_name"]),
            ["Camiseta edição limitada R$ 89,90", "Gravação de medalha"],
        )
        self.assertTrue(observed["explicit_unit_value"].isna().all())
        self.assertTrue(observed["explicit_total_value"].isna().all())
        self.assertNotIn("segredo-produto", observed.to_string())
        self.assertEqual(
            observed.loc[0, "raw_product_keys"],
            ["Camiseta edição limitada R$ 89,90", "ID_Estoque", "Id_PrOdUtO"],
        )

    def test_product_fact_keeps_normalized_explicit_name_alias_authoritative(self):
        """A dynamic fallback must not replace a present explicit nome/produto value."""
        bundle = _bundle_with_first_registration_products(
            [
                {
                    "iD_pRoDuTo": "PROD-EXPLICIT",
                    "Id_EsToQuE": "EST-3",
                    "NoMe": "Nome explícito",
                    "Chave que não é o nome": None,
                }
            ]
        )

        products = build_fact_bundle(bundle).products
        observed = products.loc[products["numero_inscricao"] == 2001].iloc[0]

        self.assertEqual(observed["product_id"], "PROD-EXPLICIT")
        self.assertEqual(observed["product_name"], "Nome explícito")
        self.assertIn("NoMe", observed["raw_product_keys"])

    def test_product_dynamic_name_fails_closed_without_exactly_one_candidate(self):
        """Guessing among zero or multiple dynamic keys would invent an identity."""
        bundle = _bundle_with_first_registration_products(
            [
                {"ID_Produto": "PROD-ZERO", "ID_Estoque": "EST-4"},
                {
                    "ID_Produto": "PROD-MULTI",
                    "ID_Estoque": "EST-5",
                    "Primeira identidade": None,
                    "Segunda identidade": None,
                },
            ]
        )

        products = build_fact_bundle(bundle).products
        observed = products.loc[products["numero_inscricao"] == 2001].reset_index(
            drop=True
        )

        self.assertEqual(list(observed["product_id"]), ["PROD-ZERO", "PROD-MULTI"])
        self.assertTrue(observed["product_name"].isna().all())

    def test_all_covered_money_allocates_independently_and_reconciles(self):
        """Reusing one financial component for another would break source-backed totals."""
        facts = build_fact_bundle(source_bundle())
        paid = facts.registrations.loc[facts.registrations["is_paid"]]
        expected = {
            "allocated_gross_value": Decimal("600.00"),
            "allocated_discount_value": Decimal("60.00"),
            "allocated_fee_value": Decimal("30.00"),
            "allocated_net_transfer_value": Decimal("510.00"),
            "allocated_cashback_value": Decimal("6.00"),
        }
        for column, total in expected.items():
            with self.subTest(column=column):
                self.assertEqual(paid[column].sum(), total)
        self.assertEqual(
            list(paid["allocation_method"]),
            ["reported_registration_gross_weights"] * 2,
        )

    def test_cent_allocator_uses_largest_remainder(self):
        """Naive independent rounding would lose a cent on a three-way allocation."""
        self.assertEqual(
            allocate_cents(Decimal("10.00"), [Decimal("1"), Decimal("1"), Decimal("1")]),
            [Decimal("3.34"), Decimal("3.33"), Decimal("3.33")],
        )

    def test_missing_registration_prices_allocate_equally(self):
        """Missing all weights must not leave a paid order unallocated."""
        bundle = source_bundle()
        participants = bundle.participants.copy()
        bodies = []
        for raw_body in participants["body"]:
            body = json.loads(raw_body)
            body.pop("valorUnitario")
            bodies.append(json.dumps(body))
        participants["body"] = bodies

        facts = build_fact_bundle(replace(bundle, participants=participants))
        paid = facts.registrations.loc[facts.registrations["is_paid"]]
        self.assertEqual(
            list(paid["allocated_gross_value"]), [Decimal("300.00"), Decimal("300.00")]
        )
        self.assertEqual(
            set(paid["allocation_method"]), {"equal_missing_registration_prices"}
        )

    def test_order_net_transfer_is_not_inferred_from_unrelated_fallback(self):
        """Falling back to valorRepasse would fabricate the unpaid order's net transfer."""
        orders = build_order_fact(source_bundle()).set_index("numero_pedido")
        self.assertIsNone(orders.loc[1002, "net_transfer_value"])

    def test_missing_paid_order_discount_is_an_explicit_allocated_zero(self):
        """A missing discount means no discount, while an invalid value remains invalid."""
        bundle = source_bundle()
        orders = bundle.orders.copy()
        paid_body = json.loads(orders.loc[0, "body"])
        paid_body.pop("desconto")
        orders.loc[0, "body"] = json.dumps(paid_body)

        facts = build_fact_bundle(replace(bundle, orders=orders))

        paid_order = facts.orders.loc[facts.orders["is_paid"]].iloc[0]
        self.assertEqual(paid_order["discount_value"], Decimal("0.00"))
        self.assertEqual(
            set(facts.registrations["allocated_discount_value"]),
            {Decimal("0.00")},
        )
        self.assertEqual(facts.reconciliation["paid_order_discount"], "0.00")
        self.assertEqual(
            facts.reconciliation["allocated_registration_discount"], "0.00"
        )

    def test_order_date_uses_the_export_contract_column(self):
        """Ignoring data_pedido would discard the reliable fresh extraction timeline."""
        bundle = source_bundle()
        orders = bundle.orders.copy()
        orders.loc[0, "data_pedido"] = "2026-06-01T10:00:00-03:00"
        body = json.loads(orders.loc[0, "body"])
        body["dataPedido"] = "formato interno não contratado"
        orders.loc[0, "body"] = json.dumps(body, ensure_ascii=False)

        fact = build_order_fact(replace(bundle, orders=orders)).set_index(
            "numero_pedido"
        )

        self.assertEqual(fact.loc[1001, "order_date"], date(2026, 6, 1))
        self.assertEqual(
            fact.attrs["paid_field_status_counts"]["order_date"]["valido"],
            1,
        )

    def test_registration_fact_does_not_propagate_pii_or_questionnaire_answers(self):
        """Copying raw participant payloads would leak PII and free-text answers."""
        facts = build_fact_bundle(source_bundle())
        forbidden_columns = {
            "nome",
            "email",
            "telefone",
            "cpf",
            "data_nascimento",
            "questionario",
        }
        self.assertTrue(forbidden_columns.isdisjoint(facts.registrations.columns))
        self.assertNotIn("segredo-teste", facts.registrations.to_string())
        self.assertNotIn("Pessoa Teste", facts.registrations.to_string())

    def test_reconciliation_records_counts_and_all_financial_coverage(self):
        """Omitting reconciliation evidence would let covered mismatches go unnoticed."""
        facts = build_fact_bundle(source_bundle())
        self.assertEqual(facts.reconciliation["source_order_rows"], 2)
        self.assertEqual(facts.reconciliation["source_registration_rows"], 2)
        self.assertEqual(facts.reconciliation["orders_with_multiple_registrations"], 1)
        self.assertEqual(facts.reconciliation["registration_join_coverage_pct"], 100.0)
        self.assertEqual(facts.reconciliation["paid_order_cashback"], "6.00")
        self.assertEqual(facts.reconciliation["allocated_registration_cashback"], "6.00")

    def test_assert_reconciled_rejects_invalid_event_and_negative_counts(self):
        """Weak assertions would accept cross-event or logically impossible evidence."""
        facts = build_fact_bundle(source_bundle())
        wrong_event_orders = facts.orders.copy()
        wrong_event_orders.loc[:, "cod_evento"] = 99999
        with self.assertRaisesRegex(ValueError, "unexpected event code"):
            assert_reconciled(replace(facts, orders=wrong_event_orders))

        wrong_event_products = facts.products.copy()
        wrong_event_products.loc[:, "cod_evento"] = 99999
        with self.assertRaisesRegex(ValueError, "unexpected event code"):
            assert_reconciled(replace(facts, products=wrong_event_products))

        invalid_counts = {**facts.reconciliation, "unmatched_registration_count": -1}
        with self.assertRaisesRegex(ValueError, "negative reconciliation count"):
            assert_reconciled(replace(facts, reconciliation=invalid_counts))

        invalid_counts = {
            **facts.reconciliation,
            "orders_with_multiple_registrations": -1,
        }
        with self.assertRaisesRegex(ValueError, "negative reconciliation count"):
            assert_reconciled(replace(facts, reconciliation=invalid_counts))

    def test_composite_order_duplicates_are_rejected_with_row_count(self):
        """Checking numero_pedido alone or skipping duplicates would corrupt order grain."""
        bundle = source_bundle()
        duplicated = pd.concat([bundle.orders, bundle.orders.iloc[[0]]], ignore_index=True)
        with self.assertRaisesRegex(ValueError, "duplicate composite order keys: 2"):
            build_order_fact(replace(bundle, orders=duplicated))

    def test_missing_order_number_is_rejected(self):
        """A single null or blank order number must not create a keyless order fact."""
        bundle = source_bundle()
        for invalid in (None, "  "):
            with self.subTest(invalid=invalid):
                orders = bundle.orders.copy()
                orders["numero_pedido"] = orders["numero_pedido"].astype(object)
                orders.loc[0, "numero_pedido"] = invalid
                with self.assertRaisesRegex(ValueError, "numero_pedido"):
                    build_order_fact(replace(bundle, orders=orders))

    def test_missing_registration_number_is_rejected(self):
        """A null or blank registration number must not create a keyless fact row."""
        bundle = source_bundle()
        for invalid in (None, "  "):
            with self.subTest(invalid=invalid):
                participants = bundle.participants.copy()
                participants["numero_inscricao"] = participants[
                    "numero_inscricao"
                ].astype(object)
                participants.loc[0, "numero_inscricao"] = invalid
                with self.assertRaisesRegex(ValueError, "numero_inscricao"):
                    build_fact_bundle(replace(bundle, participants=participants))

    def test_missing_registration_order_number_is_rejected_at_parse_boundary(self):
        """A missing participant order key must fail before a misleading join error."""
        bundle = source_bundle()
        participants = bundle.participants.copy()
        participants.loc[0, "numero_pedido"] = None
        with self.assertRaisesRegex(ValueError, "numero_pedido"):
            build_fact_bundle(replace(bundle, participants=participants))

    def test_assert_reconciled_rejects_missing_product_grain_key(self):
        """A product row detached from its registration must fail hard reconciliation."""
        facts = build_fact_bundle(source_bundle())
        products = facts.products.copy()
        products.loc[0, "numero_inscricao"] = None
        with self.assertRaisesRegex(ValueError, "numero_inscricao"):
            assert_reconciled(replace(facts, products=products))

    def test_zero_registration_bundle_builds_empty_schema_and_reconciliation(self):
        """No participants for unpaid orders must yield controlled empty fact tables."""
        bundle = source_bundle()
        unpaid_orders = bundle.orders.loc[bundle.orders["numero_pedido"] == 1002].copy()
        no_participants = pd.DataFrame(columns=bundle.participants.columns)

        try:
            facts = build_fact_bundle(
                replace(bundle, orders=unpaid_orders, participants=no_participants)
            )
        except Exception as error:  # pragma: no cover - turns the regression into FAIL
            self.fail(f"empty registrations raised {type(error).__name__}: {error}")

        self.assertTrue(facts.registrations.empty)
        self.assertTrue(facts.products.empty)
        self.assertTrue(
            {
                "numero_inscricao",
                "coupon_title_status",
                "allocated_gross_value",
                "allocation_method",
                "is_paid",
            }.issubset(facts.registrations.columns)
        )
        self.assertEqual(facts.reconciliation["source_registration_rows"], 0)
        self.assertEqual(facts.reconciliation["paid_registration_count"], 0)
        self.assertEqual(facts.reconciliation["registration_join_coverage_pct"], 100.0)


if __name__ == "__main__":
    unittest.main()
