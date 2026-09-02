"""Executable contracts for the six-cell MIF portfolio audit notebook."""

from contextlib import redirect_stdout
from decimal import Decimal
from io import StringIO
import json
from pathlib import Path
import unittest


NOTEBOOK_PATH = (
    Path(__file__).resolve().parents[2]
    / "analyses/mif_2026_channels/notebooks/mif_2026_portfolio_audit.ipynb"
)


class PortfolioNotebookTests(unittest.TestCase):
    def test_cell_five_audits_reduced_dependency_samples_and_pcd(self):
        notebook = json.loads(NOTEBOOK_PATH.read_text(encoding="utf-8"))
        cells = notebook["cells"]
        self.assertEqual(len(cells), 6)
        self.assertTrue(all(cell["cell_type"] == "code" for cell in cells))
        dependency_cells = [
            {
                "phase": "Meio",
                "modality": "21K",
                "state": state,
                "channel_name": channel,
                "paid_registrations": registrations,
                "event_paid_registrations": event_total,
                "commercial_paid_registrations": commercial_total,
                "exposure": "baixa",
                "sample_status": sample_status,
            }
            for state, channel, registrations, event_total, commercial_total, sample_status in (
                ("SC", "PCD", 5, 20, 10, "amostra celular reduzida"),
                ("RS", "PCD", 7, 20, 10, "amostra celular reduzida"),
                ("PR", "PCD", 9, 20, 10, "amostra celular reduzida"),
                ("SP", "ROADRUNNERS", 10, 20, 10, "amostra celular suficiente"),
            )
        ]
        summary = {
            "dependency_cells": dependency_cells,
            "dependency_sample_summary": {
                "published_cells": 4,
                "published_cell_registrations": 31,
                "reduced_cells": 3,
                "reduced_cell_registrations": 21,
                "reduced_cell_share_pct": "75.00",
                "reduced_registration_share_pct": "67.74",
                "publishable_cell_minimum_registrations": 5,
                "sufficient_cell_minimum_registrations": 10,
            },
            "redundancy_candidates": [],
        }
        simulator = {
            "selectable_channels": [
                {
                    "channel_name": channel,
                    "channel_type": channel_type,
                    "paid_registrations": registrations,
                    "gross_value": gross,
                    "registration_ticket": ticket,
                }
                for channel, channel_type, registrations, gross, ticket in (
                    ("ROADRUNNERS", "influenciador", 100, "1000.00", "20.00"),
                    ("Sports Week", "evento_acao", 50, "500.00", "20.00"),
                    ("PCD", "politica", 21, "210.00", "10.01"),
                )
            ]
        }

        def show_rows(rows, columns):
            print(" | ".join(columns))
            for row in rows:
                print(" | ".join(str(row.get(column, "")) for column in columns))

        namespace = {
            "Decimal": Decimal,
            "show_rows": show_rows,
            "summary": summary,
            "simulator": simulator,
        }
        output = StringIO()
        with redirect_stdout(output):
            exec(compile("".join(cells[4]["source"]), str(NOTEBOOK_PATH), "exec"), namespace)

        rendered = output.getvalue()
        self.assertIn("Amostras celulares reduzidas: 3/4 células (75.00%)", rendered)
        self.assertIn("21/31 inscrições publicadas (67.74%)", rendered)
        self.assertIn(
            "PCD: 3 células publicadas; todas são amostra celular reduzida",
            rendered,
        )


if __name__ == "__main__":
    unittest.main()
