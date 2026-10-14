"""Resource coverage against the compiler's real XLIFF IDs; no BC or ROM."""
import importlib.util
import json
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
APP_NAME = json.loads((ROOT / 'app.json').read_text())['name']
Q = '{urn:oasis:names:tc:xliff:document:1.2}'


class LocalizationTests(unittest.TestCase):
    def test_all_generated_labels_have_current_danish_and_english_targets(self):
        spec = importlib.util.spec_from_file_location('tama_translations', ROOT / 'tools/translations.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertGreater(module.generate(check=True), 0)
        for language, expected in [('en-GB', 'Tamagotchi Setup'), ('da-DK', 'Tamagotchi-opsætning')]:
            tree = ET.parse(ROOT / 'Translations' / (APP_NAME + '.' + language + '.xlf'))
            sources = {unit.findtext(Q + 'source'): unit.findtext(Q + 'target')
                       for unit in tree.findall('.//' + Q + 'trans-unit')}
            self.assertEqual(sources['Tamagotchi Setup'], expected)
            self.assertTrue(all(sources.values()))
            self.assertNotIn('0123456789ABCDEF', sources)  # ROM constants stay locked

    def test_every_widget_label_uses_a_compiler_translatable_al_label(self):
        ui = (ROOT / 'src/TamaUI.Codeunit.al').read_text()
        labels = {m[1]: m[2].replace("''", "'") for m in re.finditer(r"(\w+): Label '((?:[^']|'')*)'", ui)}
        source = ET.parse(ROOT / 'Translations' / (APP_NAME + '.g.xlf'))
        generated = {unit.findtext(Q + 'source') for unit in source.findall('.//' + Q + 'trans-unit')}
        keys = {m[1]: labels[m[2]] for m in re.finditer(r"Texts.Add\('([^']+)', (\w+)\)", ui)}
        self.assertEqual(keys['setup'], 'Setup')
        self.assertEqual(keys['enableSound'], 'Enable sound')
        self.assertTrue(set(keys.values()) <= generated)
        for index in range(8):
            self.assertIn('shell' + str(index), keys)
            self.assertIn('icon' + str(index), keys)
        js = (ROOT / 'controladdin/tama.js').read_text()
        self.assertNotIn('navigator.language', js)
        self.assertNotIn('Opsætning', js)


if __name__ == '__main__':
    unittest.main()
