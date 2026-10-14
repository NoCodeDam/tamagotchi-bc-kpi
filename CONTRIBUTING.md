# Contributing

Report issues with app version, BC version, language, Role Center and expected
versus actual behavior. Include pet event status and Job Queue errors with company
details and personal data removed. Use a dedicated sandbox test company.

Do not include credentials, real invoices, license files, firmware or customer
data in issues, pull requests or recordings.

The life rules run in AL. The browser draws frames, plays allowed audio and opens
Setup. Care comes from committed BC events. Keep state persistent, avoid writes
to BC financial data, and preserve existing lives during upgrades.

Run [local checks](docs/BUILDING.md#local-checks). Compile both apps for AL changes.
Changes to lifecycle, transactions, permissions or scheduling also need relevant
[BC sandbox acceptance checks](docs/TESTING.md).

Describe behavior changes and test evidence in your pull request. Contributions
must be compatible with GPLv2 and identify external code or asset provenance. If
a license conflict is found, stop and report it rather than silently substituting
another implementation.
