#!/usr/bin/env python3
"""Build both apps with Microsoft's AL compiler; no tenant access or publishing.

Supply the compiler, .NET host and downloaded BC symbols. Existing builds remain.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import re
import subprocess
import sys
import zipfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def compile_app(dotnet, compiler, project, symbols, output, log):
    command = [str(dotnet), str(compiler), f'/project:{project}',
               f'/packagecachepath:{symbols}', f'/out:{output}']
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    messages = result.stdout + result.stderr
    log.write_text(messages, encoding='utf-8')
    if result.returncode or not output.is_file():
        raise RuntimeError(f'AL compilation failed; see {log.name}')
    return {'package': output.name, 'sha256': sha(output), 'log': log.name,
            'exit_code': result.returncode, 'warnings': messages.count(': warning AL')}


def app_filename(metadata):
    return f"{metadata['publisher']}_{metadata['name']}_{metadata['version']}.app"


def verify_package(file):
    with zipfile.ZipFile(file) as package:
        for name in package.namelist():
            if name.lower().endswith(('.b', '.bin', '.rom')):
                raise RuntimeError('Unexpected firmware file in the app')
            if name.lower().endswith('.al'):
                content = package.read(name).decode('utf-8-sig')
                if 'Subtype = Test' in content:
                    raise RuntimeError('Test codeunit leaked into the main app')
                if any(token in content for token in ['codeunit 61203 "Tama P1 CPU"',
                                                      'codeunit 61201 "Tama ROM"']):
                    raise RuntimeError('Retired emulator object leaked into the app')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['dotnet', 'compiler', 'symbols', 'output']:
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--upstream', type=Path,
                        help='Optional private folder for an additional firmware-byte exclusion check')
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    test_source = source.with_name('bc-tamagotchi-tests')
    metadata = json.loads((source / 'app.json').read_text())
    test_metadata = json.loads((test_source / 'app.json').read_text())
    dependency = test_metadata['dependencies'][0]
    if any(dependency[key] != metadata[key] for key in ['id', 'name', 'publisher', 'version']):
        raise RuntimeError('Test dependency does not match the main app')
    output = args.output.resolve()
    if output.exists():
        raise RuntimeError('Choose a new output directory; retained builds are never overwritten')
    output.mkdir(parents=True)
    cache = output / 'symbols'
    cache.mkdir()
    symbols = []
    for file in sorted(args.symbols.glob('Microsoft_*.app')):
        shutil.copyfile(file, cache / file.name)
        symbols.append({'name': file.name, 'sha256': sha(file)})
    if not symbols:
        raise RuntimeError('No Microsoft BC symbol packages found')
    dotnet, compiler = args.dotnet.resolve(), args.compiler.resolve()
    if 'TranslationFile' in metadata.get('features', []):
        compile_app(dotnet, compiler, source, cache, output / 'translation-generation.app',
                    output / 'translation-generation.txt')
        subprocess.run([sys.executable, str(source / 'tools/translations.py')], check=True)
    main_app = output / app_filename(metadata)
    main_result = compile_app(dotnet, compiler, source, cache, main_app, output / 'main-compile.txt')
    subprocess.run([sys.executable, str(source / 'tools/translations.py'), '--check'], check=True)
    verify_package(main_app)
    if args.upstream:
        reference = (args.upstream / 'tama-candidate.b').read_bytes()
        with zipfile.ZipFile(main_app) as package:
            if any(reference in package.read(name) for name in package.namelist()):
                raise RuntimeError('Firmware bytes leaked into the app')
    shutil.copyfile(main_app, cache / main_app.name)
    test_result = compile_app(dotnet, compiler, test_source, cache,
                              output / app_filename(test_metadata), output / 'tests-compile.txt')
    source_files = []
    for root in (source, test_source):
        runtime_files = [root / 'app.json'] + list((root / 'src').glob('*.al'))
        for folder in ['controladdin', 'Translations']:
            if (root / folder).is_dir():
                runtime_files += [p for p in (root / folder).rglob('*') if p.is_file()]
        for file in sorted(runtime_files):
            source_files.append({'name': str(Path('extensions') / root.name / file.relative_to(root)),
                                 'sha256': sha(file)})
    receipt = {'recorded_at': datetime.now(timezone.utc).isoformat(), 'version': metadata['version'],
               'target': 'BC 27.0 / Cloud / runtime 16.0', 'main': main_result, 'tests': test_result,
               'symbols': symbols, 'source_files': source_files,
               'original_rom_present': False, 'retired_emulator_present': False,
               'main_app_contains_test_objects': False,
               'bc_tenant_tested': False, 'al_tests': {'compiled': sum(len(re.findall(r'\[Test\]', p.read_text())) for p in (test_source / 'src').glob('*.al')), 'executed': 0},
               'remote_published': False}
    (output / 'build-receipt.json').write_text(json.dumps(receipt, indent=2) + chr(10), encoding='utf-8')
    print(json.dumps({'main': main_result, 'tests': test_result, 'output': str(output)}, indent=2))


if __name__ == '__main__':
    main()
