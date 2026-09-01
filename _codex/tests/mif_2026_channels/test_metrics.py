from dataclasses import replace
from decimal import Decimal
import re
import unittest

import pandas as pd

from _codex.analyses.mif_2026_channels.metrics import (
    build_analysis,
    build_channel_dossiers,
    build_dimension_overlaps,
    geographic_scope,
    jensen_shannon_similarity,
    percentage_point_delta,
    weighted_ticket,
)
from _codex.tests.mif_2026_channels.fixtures import (
    channel_metric_facts,
    channel_metric_frames,
)


EXPECTED_DATASET_IDS = {
    "event_overview",
    "weekly_sales",
    "lot_performance",
    "modality_mix",
    "country_distribution",
    "state_distribution",
    "city_distribution",
    "age_bands",
    "gender_distribution",
    "pace_bands",
    "club_coverage",
    "payment_mix",
    "device_mix",
    "auxiliary_field_coverage",
    "product_summary",
    "channel_index",
    "channel_aliases",
    "channel_modality_mix",
    "channel_state_mix",
    "channel_lot_mix",
    "channel_weekly_sales",
    "channel_product_mix",
    "channel_profile_coverage",
    "geography_overlap",
    "modality_overlap",
    "lot_overlap",
    "temporal_overlap",
    "profile_overlap",
    "product_overlap",
    "long_tail",
    "data_quality",
}


class MetricTests(unittest.TestCase):
    def test_overall_ticket_is_not_mean_of_channel_means(self):
        """A mean of channel tickets would overstate the event ticket."""
        rows = pd.DataFrame(
            [
                {"value": Decimal("1000.00"), "registrations": 10},
                {"value": Decimal("900.00"), "registrations": 1},
            ]
        )
        self.assertEqual(
            weighted_ticket(rows, "value", "registrations"), Decimal("172.73")
        )
        self.assertIsNone(
            weighted_ticket(rows.iloc[0:0], "value", "registrations")
        )

    def test_full_dossier_threshold_is_ten_paid_registrations(self):
        """An off-by-one threshold would publish a full dossier for nine sales."""
        registrations, orders, products = channel_metric_frames(
            counts={"Canal A": 10, "Canal B": 9}
        )
        full, compact = build_channel_dossiers(registrations, orders, products)
        self.assertEqual([row["channel_name"] for row in full], ["Canal A"])
        self.assertEqual([row["channel_name"] for row in compact], ["Canal B"])
        self.assertEqual(
            compact[0]["sample_warning"],
            "Base abaixo de 10 inscrições pagas; leitura indicativa",
        )

    def test_dossiers_are_alphabetical_and_distinguish_touched_orders(self):
        """Volume sorting or additive order labels would imply an unwanted ranking."""
        registrations, orders, products = channel_metric_frames(
            counts={"Zeta": 11, "Alfa": 10, "Cauda": 2}
        )
        registrations.loc[registrations.index[10], "numero_pedido"] = registrations.loc[
            registrations.index[9], "numero_pedido"
        ]

        full, compact = build_channel_dossiers(registrations, orders, products)

        self.assertEqual([row["channel_name"] for row in full], ["Alfa", "Zeta"])
        self.assertEqual([row["channel_name"] for row in compact], ["Cauda"])
        self.assertEqual(full[1]["touched_paid_orders"], 10)
        self.assertNotIn("score", set().union(*(row.keys() for row in full)))
        self.assertNotIn("rank", set().union(*(row.keys() for row in full)))

    def test_full_dossier_exposes_required_evidence_and_money_formats(self):
        """Omitting bases, coverage, or monetary precision would make comparisons unsafe."""
        registrations, orders, products = channel_metric_frames(
            counts={"Canal A": 10}
        )
        full, _ = build_channel_dossiers(registrations, orders, products)
        dossier = full[0]
        required = {
            "channel_name",
            "channel_type",
            "touched_paid_orders",
            "paid_registrations",
            "registrations_per_order",
            "gross_value",
            "discount_value",
            "fee_value",
            "net_transfer_value",
            "cashback_value",
            "allocated_value_per_touched_order",
            "registration_ticket",
            "share_of_event_registrations",
            "coupon_aliases",
            "geographic_scope",
            "countries",
            "modality_mix",
            "modality_delta_pp",
            "lot_mix",
            "lot_delta_pp",
            "top_states",
            "top_cities",
            "weekly_sales",
            "profile_coverage",
            "age_bands",
            "gender_mix",
            "pace_bands",
            "club_presence",
            "product_mix",
            "profile_delta_pp",
            "similar_channels_by_dimension",
            "distinctive_signals",
            "external_considerations_status",
            "data_limitations",
        }
        self.assertEqual(set(dossier), required)
        for key in (
            "gross_value",
            "discount_value",
            "fee_value",
            "net_transfer_value",
            "cashback_value",
            "allocated_value_per_touched_order",
            "registration_ticket",
        ):
            self.assertRegex(dossier[key], r"^-?\d+\.\d{2}$")
        self.assertEqual(dossier["external_considerations_status"], "não mensurado")
        self.assertTrue(
            {"answered", "valid", "invalid", "missing"}.issubset(
                dossier["profile_coverage"]["pace"]
            )
        )

    def test_geographic_scope_uses_exact_descriptive_thresholds(self):
        """Inclusive or reordered thresholds would change the stated evidence class."""
        cases = [
            ((9, 5, 10, 20, 20, 0), "amostra pequena — sem classificação estável"),
            ((10, 5, 10, 20, 20, 51), "internacional/fora do Brasil"),
            ((10, 4, 8, 39.99, 20, 0), "nacional"),
            ((10, 3, 5, 54.99, 20, 0), "multirregional"),
            ((10, 2, 2, 79.99, 60, 0), "local"),
            ((10, 2, 2, 50, 40, 0), "regional"),
        ]
        for arguments, label in cases:
            with self.subTest(label=label):
                self.assertEqual(geographic_scope(*arguments)["label"], label)

    def test_invalid_geography_cannot_create_false_local_concentration(self):
        """An invalid bucket dominating the source must not count as a state or city."""
        registrations, orders, products = channel_metric_frames(
            counts={"Canal A": 10}
        )
        registrations.loc[registrations.index[:8], ["state", "city"]] = None
        registrations.loc[
            registrations.index[:8], ["state_status", "city_status"]
        ] = "invalido"

        full, _ = build_channel_dossiers(registrations, orders, products)

        self.assertEqual(full[0]["geographic_scope"]["label"], "regional")
        self.assertEqual(full[0]["geographic_scope"]["states"], 2)

    def test_percentage_delta_requires_visible_nonzero_denominators(self):
        """A hidden or zero denominator would create a misleading percentage delta."""
        self.assertEqual(percentage_point_delta(5, 10, 2, 10), 30.0)
        self.assertIsNone(percentage_point_delta(0, 0, 2, 10))
        self.assertIsNone(percentage_point_delta(5, 10, 0, 0))

    def test_dimension_overlaps_stay_separate_and_require_ten_registrations(self):
        """A master similarity or a small-base comparison would violate the study contract."""
        registrations, _, products = channel_metric_frames(
            counts={"Canal A": 10, "Canal B": 10, "Canal C": 9}
        )
        add_ons = (
            products.loc[products["classification"] == "adicional"]
            .groupby("numero_inscricao")["canonical_name"]
            .agg(list)
        )
        rows = registrations.copy()
        rows["addon_products"] = rows["numero_inscricao"].map(add_ons).map(
            lambda value: value if isinstance(value, list) else []
        )
        rows["addon_product_mapping_status"] = "mapeado"

        overlaps = build_dimension_overlaps(rows)

        self.assertEqual(
            set(overlaps),
            {
                "geography_overlap",
                "modality_overlap",
                "lot_overlap",
                "temporal_overlap",
                "profile_overlap",
                "product_overlap",
            },
        )
        for dataset, records in overlaps.items():
            for row in records:
                self.assertEqual({row["channel_a"], row["channel_b"]}, {"Canal A", "Canal B"})
                self.assertGreaterEqual(row["similarity_0_1"], 0)
                self.assertLessEqual(row["similarity_0_1"], 1)
                self.assertIn("coverage_a", row)
                self.assertIn("coverage_b", row)
                if dataset == "profile_overlap":
                    self.assertIn(
                        row["profile_dimension"], {"age", "gender", "pace", "club"}
                    )
        self.assertEqual(
            {row["profile_dimension"] for row in overlaps["profile_overlap"]},
            {"age", "gender", "pace", "club"},
        )
        self.assertNotIn("overall_overlap", overlaps)

    def test_jensen_shannon_similarity_handles_disjoint_and_equal_distributions(self):
        """An unnormalised divergence could escape the documented zero-to-one range."""
        self.assertEqual(jensen_shannon_similarity({"A": 1}, {"A": 4}), 1.0)
        self.assertEqual(jensen_shannon_similarity({"A": 1}, {"B": 1}), 0.0)
        with self.assertRaisesRegex(ValueError, "non-empty"):
            jensen_shannon_similarity({}, {"A": 1})

    def test_build_analysis_emits_stable_ids_and_reconciles_additive_counts(self):
        """Missing IDs or mismatched lots/channels would break downstream report queries."""
        facts = channel_metric_facts()

        result = build_analysis(facts)

        self.assertEqual(set(result.datasets), EXPECTED_DATASET_IDS)
        event_total = result.overview["paid_registrations"]
        self.assertEqual(
            sum(row["paid_registrations"] for row in result.datasets["modality_mix"]),
            event_total,
        )
        self.assertEqual(
            sum(row["paid_registrations"] for row in result.datasets["lot_performance"]),
            event_total,
        )
        self.assertEqual(
            len(result.full_dossiers) + len(result.long_tail),
            len(result.datasets["channel_index"]),
        )
        self.assertEqual(
            sum(row["paid_registrations"] for row in result.datasets["channel_index"]),
            event_total,
        )
        self.assertEqual(result.datasets["event_overview"], [result.overview])

    def test_event_overview_uses_order_and_registration_grains(self):
        """Repeated order money or channel means would inflate overview commerce."""
        facts = channel_metric_facts()
        result = build_analysis(facts)
        overview = result.overview

        self.assertEqual(overview["paid_orders"], len(facts.orders))
        self.assertEqual(overview["paid_registrations"], len(facts.registrations))
        self.assertEqual(overview["gross_value"], "2780.00")
        self.assertEqual(overview["order_ticket"], "106.92")
        self.assertEqual(overview["registration_ticket"], "106.92")
        self.assertEqual(overview["coupon_assisted_share_pct"], 100.0)
        self.assertEqual(overview["organic_share_pct"], 0.0)
        self.assertIn("source_field_coverage", overview)

    def test_weekly_sales_uses_order_date_when_registration_dates_are_absent(self):
        """Missing participant dates must not erase the paid sales timeline."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations.loc[:, "sale_date"] = None
        registrations.loc[:, "sale_date_status"] = "nao_informado"
        registrations.loc[:, "order_date"] = registrations[
            "numero_pedido"
        ].map(facts.orders.set_index("numero_pedido")["order_date"])

        result = build_analysis(replace(facts, registrations=registrations))

        self.assertEqual(
            sum(
                row["paid_registrations"]
                for row in result.datasets["weekly_sales"]
            ),
            len(registrations),
        )
        self.assertTrue(result.datasets["temporal_overlap"])

    def test_weekly_sales_does_not_replace_invalid_sale_dates(self):
        """An invalid participant date must stay excluded instead of looking missing."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations.loc[:, "order_date"] = registrations[
            "numero_pedido"
        ].map(facts.orders.set_index("numero_pedido")["order_date"])
        invalid_index = registrations.index[0]
        registrations.loc[invalid_index, "sale_date"] = None
        registrations.loc[invalid_index, "sale_date_status"] = "invalido"

        result = build_analysis(replace(facts, registrations=registrations))

        self.assertEqual(
            sum(
                row["paid_registrations"]
                for row in result.datasets["weekly_sales"]
            ),
            len(registrations) - 1,
        )

    def test_products_keep_classification_and_only_explicit_revenue(self):
        """Combining included and add-on items or imputing kit revenue would fabricate value."""
        result = build_analysis(channel_metric_facts())
        products = result.datasets["product_summary"]

        self.assertEqual(
            {row["classification"] for row in products},
            {"kit_incluso", "adicional", "desconhecido"},
        )
        included = next(row for row in products if row["classification"] == "kit_incluso")
        additional = next(row for row in products if row["classification"] == "adicional")
        self.assertIsNone(included["explicit_revenue"])
        self.assertRegex(additional["explicit_revenue"], r"^\d+\.\d{2}$")
        self.assertIn("take_rate_denominator", additional)

    def test_product_chart_tail_counts_distinct_registration_union(self):
        """Overlapping tail products must not double-count paid registrations in Outros."""
        facts = channel_metric_facts()
        registrations = facts.registrations.reset_index(drop=True)
        product_rows = []
        for product_index in range(10):
            count = 20 - product_index
            selected = registrations.iloc[:count]
            product_name = f"Produto {product_index + 1:02d}"
            for position, registration in selected.iterrows():
                product_rows.append(
                    {
                        "cod_evento": 72611,
                        "numero_inscricao": registration["numero_inscricao"],
                        "numero_pedido": registration["numero_pedido"],
                        "product_position": position,
                        "canonical_name": product_name,
                        "classification": "adicional",
                        "product_quantity": 1,
                        "product_revenue": None,
                    }
                )
        for product_name, selected in (
            ("Produto 11", registrations.iloc[:8]),
            ("Produto 12", registrations.iloc[4:12]),
        ):
            for position, registration in selected.iterrows():
                product_rows.append(
                    {
                        "cod_evento": 72611,
                        "numero_inscricao": registration["numero_inscricao"],
                        "numero_pedido": registration["numero_pedido"],
                        "product_position": position,
                        "canonical_name": product_name,
                        "classification": "adicional",
                        "product_quantity": 1,
                        "product_revenue": None,
                    }
                )

        result = build_analysis(
            replace(facts, products=pd.DataFrame(product_rows))
        )
        metadata = result.chart_metadata["product_summary"]

        self.assertEqual(metadata["tail_categories"], ["Produto 11", "Produto 12"])
        self.assertEqual(metadata["summed_category_registrations"], 16)
        self.assertEqual(metadata["distinct_registrations_with_product"], 12)
        self.assertEqual(metadata["product_quantity"], 16)
        self.assertEqual(
            metadata["tail_registration_multiplicity"],
            [
                {"tail_product_count": 1, "paid_registrations": 8},
                {"tail_product_count": 2, "paid_registrations": 4},
            ],
        )
        self.assertEqual(metadata["take_rate_denominator"], len(registrations))
        self.assertEqual(metadata["take_rate_pct"], 46.15)
        self.assertEqual(len(result.datasets["product_summary"]), 12)
        self.assertNotIn("numero_inscricao", str(metadata).casefold())

    def test_geography_profile_and_product_deltas_show_bases_and_coverage(self):
        """A delta without both bases and coverage would be unauditable."""
        result = build_analysis(channel_metric_facts())
        dossier = result.full_dossiers[0]

        for row in dossier["top_states"]:
            self.assertTrue(
                {
                    "channel_count",
                    "channel_denominator",
                    "event_count",
                    "event_denominator",
                    "delta_pp",
                    "coverage",
                }.issubset(row)
            )
        for row in dossier["product_mix"]:
            self.assertTrue(
                {
                    "event_registrations_with_product",
                    "event_take_rate_denominator",
                    "take_rate_delta_pp",
                    "coverage",
                }.issubset(row)
            )
        self.assertTrue(result.datasets["pace_bands"])
        self.assertTrue(
            {"answered", "valid", "invalid", "missing"}.issubset(
                result.datasets["pace_bands"][0]["coverage"]
            )
        )

    def test_product_overlap_coverage_is_registration_coverage_not_item_rate(self):
        """Two add-ons on one registration must not produce coverage above 100%."""
        registrations, _, _ = channel_metric_frames(
            counts={"Canal A": 10, "Canal B": 10}
        )
        registrations["addon_products"] = [
            ["Camiseta", "Boné"] if position == 0 else []
            for position in range(len(registrations))
        ]
        registrations["addon_product_mapping_status"] = "mapeado"

        overlaps = build_dimension_overlaps(registrations)

        self.assertEqual(overlaps["product_overlap"][0]["coverage_a"], 100.0)
        self.assertEqual(overlaps["product_overlap"][0]["coverage_b"], 100.0)

    def test_unmapped_products_are_not_treated_as_no_addon_in_overlap(self):
        """Missing mapping evidence must not become a covered 'Sem adicional' segment."""
        registrations, _, _ = channel_metric_frames(
            counts={"Canal A": 10, "Canal B": 10}
        )
        registrations["addon_products"] = [[] for _ in range(len(registrations))]
        registrations["addon_product_mapping_status"] = registrations[
            "channel_name"
        ].map({"Canal A": "não mapeado", "Canal B": "mapeado"})

        overlaps = build_dimension_overlaps(registrations)

        self.assertEqual(overlaps["product_overlap"], [])

    def test_zero_product_mapping_coverage_blocks_overlap_and_product_signals(self):
        """Global 0% mapping coverage must fail closed for product comparisons."""
        facts = channel_metric_facts()
        reconciliation = {
            **facts.reconciliation,
            "product_mapping_coverage_pct": 0.0,
        }

        result = build_analysis(replace(facts, reconciliation=reconciliation))

        self.assertEqual(result.datasets["product_overlap"], [])
        for dossier in result.full_dossiers:
            for row in dossier["product_mix"]:
                self.assertEqual(
                    row["coverage"]["product_mapping_coverage_pct"], 0.0
                )
                self.assertIsNone(row["take_rate_delta_pp"])
            self.assertFalse(
                any(
                    signal["dimension"] in {"product", "produto adicional"}
                    for signal in dossier["distinctive_signals"]
                )
            )

    def test_partial_registration_product_coverage_blocks_channel_product_signals(self):
        """Per-registration mapping gaps must override a nominal global 100% value."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations["product_mapping_covered"] = True
        channel_indices = registrations.index[
            registrations["channel_name"] == "Canal A"
        ]
        registrations.loc[channel_indices[0], "product_mapping_covered"] = False
        registration = registrations.loc[channel_indices[1]]
        products = pd.concat(
            [
                facts.products,
                pd.DataFrame(
                    [
                        {
                            "cod_evento": 72611,
                            "numero_inscricao": registration["numero_inscricao"],
                            "numero_pedido": registration["numero_pedido"],
                            "product_position": 20,
                            "canonical_name": "Adicional Cobertura Parcial",
                            "classification": "adicional",
                            "product_quantity": 1,
                            "product_revenue": Decimal("10.00"),
                        }
                    ]
                ),
            ],
            ignore_index=True,
        )

        result = build_analysis(
            replace(facts, registrations=registrations, products=products)
        )
        dossier = next(
            row for row in result.full_dossiers if row["channel_name"] == "Canal A"
        )

        self.assertEqual(result.datasets["product_overlap"], [])
        self.assertFalse(
            any(
                signal["dimension"] in {"product", "produto adicional"}
                for signal in dossier["distinctive_signals"]
            )
        )

    def test_global_product_coverage_overrides_complete_registration_markers(self):
        """Nominally covered rows cannot override incomplete global reconciliation."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations["product_mapping_covered"] = True
        reconciliation = {
            **facts.reconciliation,
            "product_mapping_coverage_pct": 50.0,
        }

        result = build_analysis(
            replace(
                facts,
                registrations=registrations,
                reconciliation=reconciliation,
            )
        )

        self.assertEqual(result.datasets["product_overlap"], [])
        for dossier in result.full_dossiers:
            for row in dossier["product_mix"]:
                self.assertEqual(
                    row["coverage"]["product_mapping_coverage_pct"], 50.0
                )

    def test_unique_signal_event_count_includes_compact_channels(self):
        """Event comparison must count a segment in the full event, not only eligible channels."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        products = facts.products.copy()
        full_index = registrations.index[registrations["channel_name"] == "Canal A"][0]
        compact_index = registrations.index[registrations["channel_name"] == "Canal C"][0]
        registrations.loc[[full_index, compact_index], "modality"] = "Modalidade Única"
        product_rows = []
        for position, row_index in enumerate((full_index, compact_index), start=10):
            registration = registrations.loc[row_index]
            product_rows.append(
                {
                    "cod_evento": 72611,
                    "numero_inscricao": registration["numero_inscricao"],
                    "numero_pedido": registration["numero_pedido"],
                    "product_position": position,
                    "canonical_name": "Adicional Único",
                    "classification": "adicional",
                    "product_quantity": 1,
                    "product_revenue": Decimal("10.00"),
                }
            )
        products = pd.concat([products, pd.DataFrame(product_rows)], ignore_index=True)

        result = build_analysis(
            replace(facts, registrations=registrations, products=products)
        )
        dossier = next(
            row for row in result.full_dossiers if row["channel_name"] == "Canal A"
        )
        unique_modality = next(
            signal
            for signal in dossier["distinctive_signals"]
            if signal["dimension"] == "modality"
            and signal["segment"] == "Modalidade Única"
            and signal["comparison"] == "único canal elegível"
        )
        unique_product = next(
            signal
            for signal in dossier["distinctive_signals"]
            if signal["dimension"] == "product"
            and signal["segment"] == "Adicional Único"
        )
        self.assertEqual(unique_modality["event_count"], 2)
        self.assertEqual(unique_product["event_count"], 2)

    def test_touched_orders_carry_local_non_additive_metadata(self):
        """Detached channel records must still warn that touched orders overlap."""
        result = build_analysis(channel_metric_facts())

        self.assertEqual(
            result.long_tail[0]["touched_paid_orders_note"],
            "não aditivo entre canais",
        )
        for row in result.datasets["channel_index"]:
            self.assertEqual(
                row["touched_paid_orders_note"], "não aditivo entre canais"
            )

    def test_compact_principals_ignore_invalid_and_missing_buckets(self):
        """Coverage buckets cannot become the advertised principal modality or state."""
        registrations, orders, products = channel_metric_frames(
            counts={"Canal A": 9}
        )
        registrations.loc[
            registrations.index[:8], ["modality", "state"]
        ] = None
        registrations.loc[
            registrations.index[:8], ["modality_status", "state_status"]
        ] = "invalido"
        expected_modality = registrations.loc[registrations.index[8], "modality"]
        expected_state = registrations.loc[registrations.index[8], "state"]

        _, compact = build_channel_dossiers(registrations, orders, products)

        self.assertEqual(compact[0]["principal_modality"]["modality"], expected_modality)
        self.assertEqual(compact[0]["principal_state"]["state"], expected_state)

    def test_invalid_profile_values_are_visible_in_coverage_and_quality(self):
        """Merging invalid values with missing values would conceal source defects."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations.loc[0, ["age", "pace_seconds"]] = None
        registrations.loc[0, ["age_status", "pace_seconds_status"]] = "invalido"

        result = build_analysis(replace(facts, registrations=registrations))

        quality = {row["field"]: row for row in result.datasets["data_quality"]}
        self.assertEqual(quality["age"]["invalid"], 1)
        self.assertEqual(quality["pace_seconds"]["invalid"], 1)
        self.assertIn(
            "Inválido", {row["age_band"] for row in result.datasets["age_bands"]}
        )
        self.assertIn(
            "Inválido", {row["pace_band"] for row in result.datasets["pace_bands"]}
        )

    def test_auxiliary_order_coverage_preserves_source_invalid_counts(self):
        """Inferring coverage from parsed nulls would merge invalid with missing orders."""
        facts = channel_metric_facts()
        reconciliation = {
            **facts.reconciliation,
            "paid_order_field_coverage": {
                "payment_method": {
                    "valido": 20,
                    "invalido": 2,
                    "nao_informado": 4,
                }
            },
        }

        result = build_analysis(replace(facts, reconciliation=reconciliation))

        payment = next(
            row
            for row in result.datasets["auxiliary_field_coverage"]
            if row["field"] == "payment_method"
        )
        self.assertEqual(payment["invalid"], 2)
        self.assertEqual(payment["missing"], 4)
        self.assertEqual(payment["denominator"], 26)

    def test_auxiliary_json_key_coverage_excludes_pii_like_keys(self):
        """Compound source keys naming personal fields are not safe aggregate labels."""
        facts = channel_metric_facts()
        registrations = facts.registrations.copy()
        registrations.at[0, "auxiliary_json_keys"] = [
            "emailCobranca",
            "nome",
            "ritmo",
        ]

        result = build_analysis(replace(facts, registrations=registrations))

        fields = {
            row["field"] for row in result.datasets["auxiliary_field_coverage"]
        }
        self.assertNotIn("json_key:emailCobranca", fields)
        self.assertNotIn("json_key:nome", fields)
        self.assertIn("json_key:ritmo", fields)

    def test_percentages_and_money_are_bounded_and_formatted(self):
        """Out-of-range shares or non-cent money would make serialized metrics unsafe."""
        result = build_analysis(channel_metric_facts())

        def visit(value):
            if isinstance(value, dict):
                for key, child in value.items():
                    if key.endswith("_pct") and child is not None:
                        self.assertGreaterEqual(child, 0)
                        self.assertLessEqual(child, 100)
                    if (key.endswith("_value") or key.endswith("_revenue") or key.endswith("_ticket")) and isinstance(child, str):
                        self.assertTrue(re.fullmatch(r"-?\d+\.\d{2}", child), (key, child))
                    visit(child)
            elif isinstance(value, list):
                for child in value:
                    visit(child)

        visit(result.overview)
        visit(result.datasets)
        visit(result.full_dossiers)
        visit(result.long_tail)


if __name__ == "__main__":
    unittest.main()
