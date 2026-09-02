from dataclasses import replace
from decimal import Decimal
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.crossings import (
    build_product_cube,
    build_registration_cube,
)
from _codex.analyses.mif_2026_channels.phases import (
    build_sale_cycle_boundaries,
    effective_sale_dates,
)
from _codex.tests.mif_2026_channels.fixtures import channel_metric_facts


FORBIDDEN_KEYS = {"numero_inscricao", "numero_pedido", "body", "raw_products"}


def four_registration_facts():
    facts = channel_metric_facts()
    registrations = facts.registrations.iloc[:4].copy()
    registrations.loc[:, "sale_date"] = pd.to_datetime(
        ["2025-06-02", "2025-06-03", "2026-08-23", "2026-08-24"]
    )
    registrations.loc[:, "registration_date"] = registrations["sale_date"]
    registrations.loc[:, "order_date"] = registrations["sale_date"]
    products = facts.products.loc[
        facts.products["numero_inscricao"].isin(registrations["numero_inscricao"])
    ].copy()
    orders = facts.orders.loc[
        facts.orders["numero_pedido"].isin(registrations["numero_pedido"])
    ].copy()
    return replace(
        facts,
        registrations=registrations,
        products=products,
        orders=orders,
    )


class CrossingTests(unittest.TestCase):
    def test_registration_cube_reconciles_counts_money_and_hides_identifiers(self):
        facts = four_registration_facts()
        boundaries = build_sale_cycle_boundaries(
            effective_sale_dates(facts.registrations)
        )

        cube = build_registration_cube(facts, boundaries)

        self.assertEqual(sum(row["paid_registrations"] for row in cube), 4)
        self.assertEqual(
            sum(Decimal(row["allocated_gross_value"]) for row in cube),
            sum(facts.registrations["allocated_gross_value"], Decimal("0.00")),
        )
        self.assertEqual({row["phase"] for row in cube}, {"Lançamento", "Encerramento"})
        self.assertTrue(all(FORBIDDEN_KEYS.isdisjoint(row) for row in cube))
        self.assertEqual(
            {row["week_start"] for row in cube},
            {"2025-06-02", "2026-08-17", "2026-08-24"},
        )

    def test_product_cube_excludes_only_kit_items_and_keeps_other_sales(self):
        """Mandatory kit items must not hide additional or unknown product sales."""
        facts = four_registration_facts()
        boundaries = build_sale_cycle_boundaries(
            effective_sale_dates(facts.registrations)
        )

        cube = build_product_cube(facts, boundaries)

        kit_rows = [row for row in cube if row["product_name"] == "Kit MIF 2026"]
        add_on_rows = [row for row in cube if row["product_name"] == "Camiseta Extra"]
        self.assertEqual(kit_rows, [])
        self.assertTrue(add_on_rows)
        self.assertEqual(
            {row["classification"] for row in cube},
            {"adicional", "desconhecido"},
        )
        self.assertEqual(
            sum(Decimal(row["explicit_revenue"]) for row in add_on_rows),
            Decimal("130.00"),
        )
        self.assertTrue(all(FORBIDDEN_KEYS.isdisjoint(row) for row in cube))

    def test_cube_keeps_undated_paid_registration_in_unknown_phase(self):
        facts = four_registration_facts()
        registrations = facts.registrations.copy()
        registrations.loc[registrations.index[0], "sale_date"] = None
        registrations.loc[registrations.index[0], "sale_date_status"] = "invalido"
        facts = replace(facts, registrations=registrations)
        boundaries = build_sale_cycle_boundaries(
            effective_sale_dates(facts.registrations)
        )

        cube = build_registration_cube(facts, boundaries)

        unknown = [row for row in cube if row["phase"] == "Não informado"]
        self.assertEqual(sum(row["paid_registrations"] for row in unknown), 1)
        self.assertEqual(sum(row["paid_registrations"] for row in cube), 4)


if __name__ == "__main__":
    unittest.main()
