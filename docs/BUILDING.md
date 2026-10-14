# Building from source

Use Microsoft's AL Language tooling and BC symbols matching your target.
The main app declares application/platform 27.0, Cloud and runtime 16.0.
The verification build used official AL compiler 30.0.43.45776 and BC application
27.0.38460.40293 symbols (platform 27.0.40210.0).

## VS Code

1. Open `extensions/bc-tamagotchi` with Microsoft's AL Language extension installed.
2. Create your own local launch configuration for a BC sandbox and download symbols.
   A tenant-specific `launch.json` is intentionally not included.
3. Compile once to refresh the generated XLIFF file.
4. From the repository root, run
   `python3 extensions/bc-tamagotchi/tools/translations.py` to regenerate Danish and
   English UK targets from the compiler IDs, then compile the final main app again.
5. For tests, open `extensions/bc-tamagotchi-tests`. Make the just-built main app
   available as a symbol dependency and compile the separate test app.

English US is the AL source language. Translation generation verifies complete
targets and preserves substitution placeholders. AL changes that add labels also
need Danish entries in `Translations/da-DK.json`.

## Portable command-line build

The build tool uses Python 3.12+ and the standard library. Supply your official
compiler's `alc.dll`, matching .NET host and a directory containing downloaded
`Microsoft_*.app` symbol packages. The compiler and Microsoft symbols are not
redistributed in this repository.

```sh
python3 extensions/bc-tamagotchi/tools/build.py \
  --dotnet /path/to/dotnet \
  --compiler /path/to/alc.dll \
  --symbols /path/to/bc27-symbols \
  --output build/0.3.0.0
```

Choose a **new** output directory for each build. The tool compiles translation
IDs, regenerates targets, compiles both apps, rejects tests/firmware in the main
package and records file hashes. It does not connect to or publish to a tenant.

The build receipt records exact runtime sources and package hashes. Compiler
packages are not assumed to be byte-reproducible across machines or build times;
compare the runtime source inventory as well as the released package checksums.

## Local checks

```sh
python3 -m unittest discover -s extensions/bc-tamagotchi/tests -v
node --test extensions/bc-tamagotchi/tests/widget.cjs
python3 extensions/bc-tamagotchi/tools/translations.py --check
```

The public source has **15 Python checks** and **14 Node checks**, requiring no
Python or npm dependencies. The 11 life checks execute a restricted subset of
our own AL minute/care code with explicit adapters. They are not a BC runtime or
a complete character/aging simulation. The other checks cover UI/event contracts
and translation resources. The 25 actual AL tests are in the separate test app.

Optional preview rendering uses `tools/render_release_assets.cjs` and an installed
Playwright module/Chromium. It runs with in-memory HTML, synthetic demo data and
no web server. Set `ERP_PLAYWRIGHT` to an existing module if it is not on Node's
normal module path. The rendered preview is not tenant test evidence.

To check a supplied source ZIP, extract it to a fresh directory and run the same
checks there. This helps detect accidental dependencies on private working files.
