"""BC event / display contracts for the current native AL extension."""
import unittest
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


class SafetyContractTests(unittest.TestCase):
    def test_widget_accepts_only_read_and_setup_events(self):
        source=(ROOT/'controladdin/tama.js').read_text()
        self.assertEqual(set(re.findall(r"invoke\('([^']+)'\)",source)), {'Ready','Tick','OpenSetup'})
        self.assertNotRegex(source,r'\b(?:fetch|XMLHttpRequest|localStorage)\b\s*\(')
        role=(ROOT/'src/TamaRoleCenter.al').read_text()
        self.assertNotIn('event Button',role)

    def test_all_care_bindings_have_defaults_and_native_publishers(self):
        tables=(ROOT/'src/TamaTables.al').read_text()
        for field in ['Meal','Clean','Play','Medicine','Discipline','Light On','Light Off','Snack']:
            self.assertRegex(tables,rf'"{field} Event" := "Tama BC Event"::\w+')
        self.assertIn('"Meal Event" := "Tama BC Event"::SalesInvoice',tables)
        self.assertIn('"Clean Event" := "Tama BC Event"::CustomerApplication',tables)

