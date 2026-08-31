from dataclasses import replace
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


if __name__ == "__main__":
    unittest.main()
