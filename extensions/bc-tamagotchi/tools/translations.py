#!/usr/bin/env python3
"""Maintain complete Danish/English-GB XLIFF from Microsoft's generated IDs.

Run after a compiler label-generation pass. No tenant or historical software.
English-US is the AL source language and is available without a target file.
"""
import argparse
import copy
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
NS = 'urn:oasis:names:tc:xliff:document:1.2'
Q = '{' + NS + '}'
ET.register_namespace('', NS)
ET.register_namespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance')


def generate(check=False):
    folder = ROOT / 'Translations'
    app_name = json.loads((ROOT / 'app.json').read_text())['name']
    source = folder / (app_name + '.g.xlf')
    base = ET.parse(source)
    mapping = json.loads((folder / 'da-DK.json').read_text())
    units = base.findall('.//' + Q + 'trans-unit')
    missing = sorted({unit.findtext(Q + 'source') for unit in units} - mapping.keys())
    if missing:
        raise ValueError('Missing Danish translations: ' + repr(missing))
    for language in ['da-DK', 'en-GB']:
        target_file = folder / (app_name + '.' + language + '.xlf')
        tree = copy.deepcopy(base)
        for file in tree.findall(Q + 'file'):
            file.set('target-language', language)
        expected = {}
        for unit in tree.findall('.//' + Q + 'trans-unit'):
            text = unit.findtext(Q + 'source')
            translated = mapping[text] if language == 'da-DK' else text
            if sorted(re.findall(r'%\d+', text)) != sorted(re.findall(r'%\d+', translated)):
                raise ValueError('Translation lost a placeholder: ' + text)
            target = unit.find(Q + 'target')
            if target is None:
                target = ET.Element(Q + 'target')
                unit.insert(1, target)
            target.text = translated
            target.set('state', 'translated')
            expected[unit.get('id')] = (text, translated)
        if check:
            actual_tree = ET.parse(target_file)
            if any(file.get('target-language') != language for file in actual_tree.findall(Q + 'file')):
                raise ValueError('Wrong target language: ' + str(target_file))
            actual = {unit.get('id'): (unit.findtext(Q + 'source'), unit.findtext(Q + 'target'))
                      for unit in actual_tree.findall('.//' + Q + 'trans-unit')}
            if actual != expected:
                raise ValueError('Stale/incomplete translations: ' + str(target_file))
        else:
            ET.indent(tree, space='  ')
            tree.write(target_file, encoding='utf-8', xml_declaration=True)
    return len(units)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    print(json.dumps({'labels': generate(args.check), 'languages': ['da-DK', 'en-GB', 'en-US (source)']}, ensure_ascii=False))
