"""Decision-ready cross-analysis for the compact MIF strategy artifact."""

import unittest

from _codex.analyses.mif_2026_channels.strategy import build_strategy


OVERVIEW = {
    "paid_registrations": 16,
    "gross_value": "3200.00",
}

SUMMARY_DATASETS = {
    "weekly_sales": [{"week_start": "2026-06-01", "paid_registrations": 16}],
    "lot_performance": [],
    "modality_mix": [],
    "state_distribution": [],
    "product_summary": [],
}

REGISTRATIONS = [
    {"phase": "Início", "modality": "21K", "lot": "1", "state": "SC", "channel_name": "Canal A", "paid_registrations": 4},
    {"phase": "Início", "modality": "42K", "lot": "1", "state": "SP", "channel_name": "Canal B", "paid_registrations": 2},
    {"phase": "Meio", "modality": "21K", "lot": "2", "state": "SC", "channel_name": "Canal A", "paid_registrations": 3},
    {"phase": "Encerramento", "modality": "5K", "lot": "7", "state": "SC", "channel_name": "Canal B", "paid_registrations": 5},
    {"phase": "Encerramento", "modality": "5K", "lot": "7", "state": "Não informado", "channel_name": "Canal C", "paid_registrations": 2},
]

PRODUCTS = [
    {"phase": "Início", "modality": "21K", "lot": "1", "classification": "kit_incluso", "product_name": "Camiseta do kit", "registrations_with_product": 4},
    {"phase": "Início", "modality": "21K", "lot": "1", "classification": "adicional", "product_name": "Gravação", "registrations_with_product": 2},
    {"phase": "Início", "modality": "21K", "lot": "1", "classification": "adicional", "product_name": "Finisher", "registrations_with_product": 2},
    {"phase": "Encerramento", "modality": "5K", "lot": "7", "classification": "adicional", "product_name": "Gravação", "registrations_with_product": 3},
]

CHANNELS = [
    {
        "channel_name": "Canal A",
        "channel_type": "parceiro",
        "paid_registrations": 7,
        "gross_value": "1700.00",
        "recommendation": {"category": "Priorizar"},
    },
    {
        "channel_name": "Canal B",
        "channel_type": "influenciador",
        "paid_registrations": 7,
        "gross_value": "1300.00",
        "recommendation": {"category": "Manter com função definida"},
    },
    {
        "channel_name": "Canal C",
        "channel_type": "beneficio",
        "paid_registrations": 2,
        "gross_value": "200.00",
        "recommendation": {"category": "Testar ou renegociar"},
    },
]


def strategy_fixture():
    return build_strategy(
        overview=OVERVIEW,
        summary_datasets=SUMMARY_DATASETS,
        registration_cube=REGISTRATIONS,
        product_cube=PRODUCTS,
        channel_index=CHANNELS,
    )


class StrategyTests(unittest.TestCase):
    def test_phase_distance_crossing_reconciles_and_uses_within_phase_share(self):
        strategy = strategy_fixture()
        rows = strategy["datasets"]["phase_modality"]

        self.assertEqual(sum(row["paid_registrations"] for row in rows), 16)
        self.assertIn(
            {
                "phase": "Início",
                "modality": "21K",
                "paid_registrations": 4,
                "phase_total": 6,
                "within_phase_share_pct": 66.67,
            },
            rows,
        )

    def test_playbooks_expose_when_to_focus_each_distance_and_state(self):
        strategy = strategy_fixture()

        five_k = next(
            row for row in strategy["insights"]["distance_playbook"]
            if row["modality"] == "5K"
        )
        self.assertEqual(five_k["peak_phase"], "Encerramento")
        self.assertEqual(five_k["lead_lot"], "7")
        self.assertEqual(five_k["lead_state"], "SC")
        self.assertEqual(five_k["volume_channel"], "Canal B")

        sc = next(
            row for row in strategy["insights"]["state_timing"]
            if row["state"] == "SC"
        )
        self.assertEqual(sc["peak_phase"], "Encerramento")
        self.assertEqual(sc["early_share_pct"], 33.33)
        self.assertEqual(sc["late_share_pct"], 41.67)

    def test_product_crossings_keep_overlapping_additions_separate(self):
        strategy = strategy_fixture()
        rows = strategy["datasets"]["product_modality_additional"]

        self.assertNotIn("Outros", {row["product_name"] for row in rows})
        self.assertEqual(
            [
                row["registrations_with_product"]
                for row in rows
                if row["modality"] == "21K"
            ],
            [2, 2],
        )
        engraving = next(
            row for row in rows
            if row["modality"] == "21K" and row["product_name"] == "Gravação"
        )
        self.assertEqual(engraving["take_rate_denominator"], 7)
        self.assertEqual(engraving["take_rate_pct"], 28.57)
        twenty_one = next(
            row for row in strategy["insights"]["product_opportunities"]
            if row["modality"] == "21K"
        )
        self.assertEqual(twenty_one["leading_product"], "Finisher")
        self.assertEqual(twenty_one["leading_product_take_rate_pct"], 28.57)

    def test_portfolio_summary_quantifies_concentration_by_action(self):
        strategy = strategy_fixture()
        portfolio = strategy["insights"]["channel_portfolio"]

        self.assertEqual(portfolio["top_2_gross_share_pct"], 93.75)
        self.assertEqual(
            portfolio["recommendation_groups"],
            [
                {"category": "Priorizar", "channels": 1, "paid_registrations": 7, "gross_value": "1700.00", "gross_share_pct": 53.12},
                {"category": "Manter com função definida", "channels": 1, "paid_registrations": 7, "gross_value": "1300.00", "gross_share_pct": 40.62},
                {"category": "Testar ou renegociar", "channels": 1, "paid_registrations": 2, "gross_value": "200.00", "gross_share_pct": 6.25},
            ],
        )

    def test_strategy_carries_compact_summaries_without_raw_observation_cubes(self):
        strategy = strategy_fixture()

        self.assertEqual(strategy["datasets"]["weekly_sales"], SUMMARY_DATASETS["weekly_sales"])
        self.assertNotIn("observations", strategy)
        self.assertNotIn("registration_cube", strategy)
        self.assertNotIn("product_cube", strategy)
        self.assertIn("colineares", strategy["caveats"][0].casefold())

    def test_executive_takeaways_translate_crossings_into_activation_decisions(self):
        strategy = strategy_fixture()
        takeaways = strategy["insights"]["executive_takeaways"]

        self.assertEqual(
            [row["title"] for row in takeaways],
            [
                "O ciclo muda de produto no encerramento",
                "Estados pedem calendários diferentes",
                "O portfólio já é concentrado; o ganho está na função",
                "Produto adicional deve ser ofertado por distância",
            ],
        )
        self.assertIn("5K", takeaways[0]["evidence"])
        self.assertIn("Encerramento", takeaways[0]["evidence"])
        self.assertIn("93,75%", takeaways[2]["evidence"])
        self.assertIn("Gravação", takeaways[3]["evidence"])


if __name__ == "__main__":
    unittest.main()
