import unittest

from _codex.analyses.mif_2026_channels.portfolio import (
    build_portfolio_artifacts,
    classify_exposure,
    commercial_channels,
    coverage_cube,
    nearest_peer_profiles,
    redundancy_candidates,
)


def channel_index_fixture():
    rows = [
        {"channel_name": "ALFA", "channel_type": "parceiro", "gross_value": "400.00", "paid_registrations": 20, "registration_ticket": "20.00"},
        {"channel_name": "BETA", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 20, "registration_ticket": "15.00"},
        {"channel_name": "GAMA", "channel_type": "parceiro", "gross_value": "200.00", "paid_registrations": 20, "registration_ticket": "12.00"},
    ]
    rows.extend(
        {
            "channel_name": f"LOW-{dimension}-{number:02d}",
            "channel_type": "parceiro",
            "gross_value": "1.00",
            "paid_registrations": 30,
            "registration_ticket": "11.00",
        }
        for dimension in ("geography", "modality", "temporal", "lot")
        for number in range(20)
    )
    return rows


def similarity_fixture():
    fixture = {dimension: [] for dimension in ("geography", "modality", "temporal", "lot", "product")}
    for dimension in ("geography", "modality", "temporal", "lot"):
        fixture[dimension].append(
            {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.95, "coverage_a": 90, "coverage_b": 90}
        )
    fixture["geography"].append(
        {"channel_a": "BETA", "channel_b": "ALFA", "similarity_0_1": 0.95, "coverage_a": 90, "coverage_b": 90}
    )
    fixture["temporal"].append(
        {"channel_a": "ALFA", "channel_b": "GAMA", "similarity_0_1": 0.97, "coverage_a": 90, "coverage_b": 90}
    )
    fixture["product"].append(
        {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.99, "coverage_a": 60, "coverage_b": 90}
    )
    for dimension in ("geography", "modality", "temporal", "lot"):
        fixture[dimension].extend(
            {
                "channel_a": "ALFA",
                "channel_b": f"LOW-{dimension}-{number:02d}",
                "similarity_0_1": 0.10,
                "coverage_a": 90,
                "coverage_b": 90,
            }
            for number in range(20)
        )
    return fixture


def portfolio_fixture():
    channels = channel_index_fixture()
    channels.append(
        {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "500.00", "paid_registrations": 40, "registration_ticket": "12.50"}
    )
    return {
        "overview": {"paid_registrations": 100, "gross_value": "1500.00"},
        "channel_index": channels,
        "dossiers": {"similarities": similarity_fixture()},
        "registration_cube": [
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-05", "channel_name": "ALFA", "paid_registrations": 12, "allocated_gross_value": "240.00"},
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-12", "channel_name": "BETA", "paid_registrations": 8, "allocated_gross_value": "120.00"},
            {"phase": "Início", "modality": "21K", "state": "SC", "city": "Florianópolis", "week_start": "2026-01-12", "channel_name": "Orgânico / sem cupom", "paid_registrations": 10, "allocated_gross_value": "125.00"},
        ],
        "generated_at": "2026-09-02T12:00:00-03:00",
    }


class PortfolioContractTests(unittest.TestCase):
    def test_commercial_universe_excludes_organic_and_ticket_boundary(self):
        rows = [
            {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "200.00"},
            {"channel_name": "Cortesia", "channel_type": "cortesia", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.00"},
            {"channel_name": "Sports Week", "channel_type": "parceiro", "gross_value": "100.00", "paid_registrations": 20, "registration_ticket": "10.01"},
        ]

        self.assertEqual(
            [row["channel_name"] for row in commercial_channels(rows, selectable=True)],
            ["Sports Week"],
        )

    def test_exposure_uses_event_and_partner_denominators(self):
        self.assertEqual(
            classify_exposure(selected=40, event_total=100, commercial_total=50),
            "alta",
        )
        self.assertEqual(
            classify_exposure(selected=20, event_total=100, commercial_total=50),
            "média",
        )
        self.assertEqual(
            classify_exposure(selected=12, event_total=100, commercial_total=20),
            "dependência entre parceiros",
        )
        self.assertIsNone(
            classify_exposure(selected=4, event_total=5, commercial_total=4)
        )

    def test_nearest_peer_is_dimension_specific_and_requires_coverage(self):
        result = nearest_peer_profiles(similarity_fixture(), channel_index_fixture())

        self.assertEqual(result["ALFA"]["geography"]["nearest_channel"], "BETA")
        self.assertEqual(result["ALFA"]["temporal"]["nearest_channel"], "GAMA")
        self.assertEqual(result["ALFA"]["product"]["status"], "evidência insuficiente")
        self.assertEqual(result["ALFA"]["product"]["channel_sample_status"], "amostra reduzida")

    def test_redundancy_requires_four_dimensions_including_geography_or_temporal(self):
        rows = redundancy_candidates(similarity_fixture(), channel_index_fixture())

        self.assertEqual(
            [(row["left_channel"], row["right_channel"]) for row in rows],
            [("ALFA", "BETA")],
        )

    def test_static_summary_never_contains_simulator_cube(self):
        artifacts = build_portfolio_artifacts(**portfolio_fixture())

        self.assertNotIn("coverage_cube", artifacts["portfolio/summary.json"])
        self.assertEqual(
            artifacts["portfolio/simulator.json"]["dimensions"],
            ["phase", "modality", "state", "channel_name"],
        )

    def test_simulator_contract_exposes_every_exposure_threshold(self):
        artifacts = build_portfolio_artifacts(**portfolio_fixture())

        self.assertEqual(
            artifacts["portfolio/simulator.json"]["thresholds"],
            {
                "commercial_ticket_min_exclusive": "10.00",
                "minimum_profile_registrations": 10,
                "minimum_dimension_coverage_pct": "70.00",
                "maximum_selected_channels": 10,
                "publishable_cell_minimum_registrations": 5,
                "exposure_classification_minimum_registrations": 10,
                "exposure_high_event_share_pct": "40.00",
                "exposure_medium_event_share_pct": "20.00",
                "exposure_partner_concentration_pct": "60.00",
            },
        )

    def test_summary_dimension_panels_expose_four_non_combined_quadrants_and_top_ten_rows(self):
        artifacts = build_portfolio_artifacts(**portfolio_fixture())
        panels = artifacts["portfolio/summary.json"]["dimension_panels"]
        expected_groups = {
            ("Escala alta", "Mais diferenciado relativamente"),
            ("Escala alta", "Semelhante aos pares"),
            ("Escala menor", "Mais diferenciado relativamente"),
            ("Escala menor", "Semelhante aos pares"),
        }

        self.assertEqual(set(panels), {"geography", "modality", "temporal", "lot", "product"})
        for panel in panels.values():
            self.assertEqual(
                {(row["scale"], row["differentiation"]) for row in panel["quadrants"]},
                expected_groups,
            )
            self.assertTrue(all(isinstance(row["channels"], int) for row in panel["quadrants"]))
            self.assertLessEqual(len(panel["top_channels"]), 10)

    def test_redundancy_excludes_organic_pairs_from_commercial_candidates(self):
        channels = [
            {"channel_name": "ALFA", "channel_type": "parceiro", "gross_value": "400.00", "paid_registrations": 30, "registration_ticket": "20.00"},
            {"channel_name": "BETA", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 30, "registration_ticket": "15.00"},
            {"channel_name": "Orgânico / sem cupom", "channel_type": "organico", "gross_value": "500.00", "paid_registrations": 30, "registration_ticket": "20.00"},
        ]
        similarities = {
            dimension: [
                {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.90, "coverage_a": 90, "coverage_b": 90},
                {"channel_a": "ALFA", "channel_b": "Orgânico / sem cupom", "similarity_0_1": 0.99, "coverage_a": 90, "coverage_b": 90},
            ]
            for dimension in ("geography", "modality", "temporal", "lot")
        }

        rows = redundancy_candidates(similarities, channels)

        self.assertEqual(
            [(row["left_channel"], row["right_channel"]) for row in rows],
            [("ALFA", "BETA")],
        )

    def test_benchmarks_ignore_ticket_ineligible_and_index_absent_pairs(self):
        channels = [
            {"channel_name": "ALFA", "channel_type": "parceiro", "gross_value": "400.00", "paid_registrations": 30, "registration_ticket": "20.00"},
            {"channel_name": "BETA", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 30, "registration_ticket": "15.00"},
            {"channel_name": "CORTESIA", "channel_type": "cortesia", "gross_value": "100.00", "paid_registrations": 30, "registration_ticket": "10.00"},
        ]
        similarities = {
            "geography": [
                {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": 0.80, "coverage_a": 90, "coverage_b": 90},
                {"channel_a": "ALFA", "channel_b": "CORTESIA", "similarity_0_1": 0.99, "coverage_a": 90, "coverage_b": 90},
                {"channel_a": "ALFA", "channel_b": "AUSENTE", "similarity_0_1": 0.99, "coverage_a": 90, "coverage_b": 90},
            ]
        }

        profile = nearest_peer_profiles(similarities, channels)["ALFA"]["geography"]

        self.assertEqual(profile["nearest_channel"], "BETA")
        self.assertEqual(profile["p90_similarity_0_1"], 0.80)
        self.assertEqual(profile["nearest_peer_p25_similarity_0_1"], 0.80)

    def test_invalid_similarity_values_fail_closed(self):
        channels = [
            {"channel_name": "ALFA", "channel_type": "parceiro", "gross_value": "400.00", "paid_registrations": 30, "registration_ticket": "20.00"},
            {"channel_name": "BETA", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 30, "registration_ticket": "15.00"},
        ]
        similarities = {
            dimension: [
                {"channel_a": "ALFA", "channel_b": "BETA", "similarity_0_1": value, "coverage_a": 90, "coverage_b": 90}
                for value in (None, "NaN", -0.01, 1.01)
            ]
            for dimension in ("geography", "modality", "temporal", "lot")
        }

        profiles = nearest_peer_profiles(similarities, channels)

        self.assertEqual(profiles["ALFA"]["geography"]["status"], "evidência insuficiente")
        self.assertEqual(redundancy_candidates(similarities, channels), [])

    def test_sample_qualification_marks_10_to_29_and_excludes_below_10(self):
        channels = [
            {"channel_name": "N09", "channel_type": "parceiro", "gross_value": "90.00", "paid_registrations": 9, "registration_ticket": "20.00"},
            {"channel_name": "N10", "channel_type": "parceiro", "gross_value": "100.00", "paid_registrations": 10, "registration_ticket": "20.00"},
            {"channel_name": "N29", "channel_type": "parceiro", "gross_value": "290.00", "paid_registrations": 29, "registration_ticket": "20.00"},
            {"channel_name": "N30", "channel_type": "parceiro", "gross_value": "300.00", "paid_registrations": 30, "registration_ticket": "20.00"},
        ]
        similarities = {
            dimension: [
                {"channel_a": "N10", "channel_b": "N30", "similarity_0_1": 0.90, "coverage_a": 90, "coverage_b": 90},
                {"channel_a": "N29", "channel_b": "N30", "similarity_0_1": 0.80, "coverage_a": 90, "coverage_b": 90},
            ]
            for dimension in ("geography", "modality", "temporal", "lot")
        }

        profiles = nearest_peer_profiles(similarities, channels)
        candidates = redundancy_candidates(similarities, channels)

        self.assertNotIn("N09", profiles)
        self.assertEqual(profiles["N10"]["geography"]["status"], "amostra reduzida")
        self.assertEqual(profiles["N29"]["geography"]["status"], "amostra reduzida")
        self.assertEqual(profiles["N30"]["geography"]["status"], "referência disponível")
        self.assertEqual(profiles["N30"]["geography"]["nearest_channel_sample_status"], "amostra reduzida")
        candidate = next(row for row in candidates if row["left_channel"] == "N10")
        self.assertEqual(candidate["left_sample_status"], "amostra reduzida")
        self.assertEqual(candidate["right_sample_status"], "referência disponível")
        self.assertEqual(candidate["sample_status"], "amostra reduzida")

    def test_coverage_cube_reconciles_totals_and_omits_city_week_with_fixed_money(self):
        fixture = portfolio_fixture()
        cube = coverage_cube(fixture["registration_cube"], fixture["channel_index"])
        all_total = next(row for row in cube if row["channel_name"] == "Todos os canais")
        commercial_total = next(
            row for row in cube
            if row["channel_name"] == "Canais comerciais não orgânicos"
        )

        self.assertEqual(all_total["paid_registrations"], 30)
        self.assertEqual(commercial_total["paid_registrations"], 20)
        self.assertEqual(all_total["allocated_gross_value"], "485.00")
        self.assertEqual(commercial_total["allocated_gross_value"], "360.00")
        self.assertTrue(all("city" not in row and "week_start" not in row for row in cube))
        self.assertTrue(
            all(
                value is None or (isinstance(value, str) and value.count(".") == 1 and len(value.rsplit(".", 1)[1]) == 2)
                for row in cube
                for value in (row["allocated_gross_value"], row["allocated_discount_value"], row["allocated_fee_value"])
            )
        )


if __name__ == "__main__":
    unittest.main()
