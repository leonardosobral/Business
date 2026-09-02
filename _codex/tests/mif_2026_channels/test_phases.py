import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.phases import (
    PHASE_ORDER,
    assign_sale_phases,
    build_sale_cycle_boundaries,
    effective_sale_dates,
)


class SalePhaseTests(unittest.TestCase):
    def test_sale_cycle_uses_launch_and_relative_boundaries(self):
        dates = pd.Series(
            pd.to_datetime(
                [
                    "2025-06-02",
                    "2025-06-16",
                    "2025-09-20",
                    "2026-03-01",
                    "2026-07-01",
                    "2026-08-24",
                ]
            )
        )

        boundaries = build_sale_cycle_boundaries(dates)

        self.assertEqual(
            assign_sale_phases(dates, boundaries).tolist(),
            [
                "Lançamento",
                "Início",
                "Início",
                "Meio",
                "Reta final",
                "Encerramento",
            ],
        )
        self.assertEqual(
            PHASE_ORDER,
            ("Lançamento", "Início", "Meio", "Reta final", "Encerramento"),
        )

    def test_effective_sale_date_only_falls_back_when_sale_date_is_missing(self):
        frame = pd.DataFrame(
            {
                "sale_date": [None, None, pd.Timestamp("2025-06-05")],
                "sale_date_status": ["nao_informado", "invalido", "valido"],
                "order_date": pd.to_datetime(
                    ["2025-06-03", "2025-06-04", "2025-06-06"]
                ),
            }
        )

        effective = effective_sale_dates(frame)

        self.assertEqual(effective.iloc[0], pd.Timestamp("2025-06-03"))
        self.assertTrue(pd.isna(effective.iloc[1]))
        self.assertEqual(effective.iloc[2], pd.Timestamp("2025-06-05"))

    def test_sale_cycle_rejects_an_empty_date_series(self):
        with self.assertRaisesRegex(ValueError, "at least one valid date"):
            build_sale_cycle_boundaries(pd.Series([None, pd.NaT]))


if __name__ == "__main__":
    unittest.main()
