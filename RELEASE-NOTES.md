# Tamagotchi BC KPI 0.3.0.0 — A KPI with a pulse

**Gamify your ERP. Most KPIs turn red when you neglect them. This one dies.**

A shared P1-inspired pet lives on the Business Central Role Center. Configure
which supported business events provide food, cleaning, play, medicine, discipline,
lights and snacks. Your company chooses the activities that keep its pet alive.

Life, sleep, illness, development and death run in AL. Standard BC Job Queue
keeps the clock moving after users log off. Eight visual cabinets and Danish,
English UK and English US are included.

Inspired by **Erik Hougaard** and
[BusinessCentralDoom](https://github.com/hougaard/BusinessCentralDoom).
See CREDITS for the vintage P1 research and NOTICE/ LICENSE for provenance and licensing.

## Download

| Asset | Use |
|---|---|
| `ERP Heritage_Tamagotchi BC KPI_0.3.0.0.app` | Main extension to upload to a BC sandbox |
| `ERP Heritage_Tamagotchi BC KPI Tests_0.3.0.0.app` | Optional BC test app, requires the main app |
| `tamagotchi-bc-kpi-source-0.3.0.0.zip` | Complete corresponding public source, guides and build tools |
| `SHA256SUMS.txt` | SHA-256 checksums for these assets |
| `verification.json` | Build/source integrity and test status |
| `social-preview.png` | Share image, generated display preview |

Requirements: BC 27.0+ / Cloud / runtime 16.0, sandbox extension installation
and Job Queue access. Read `docs/INSTALLATION.md` before installation.
No ROM import is required.

## Prerelease status

Both apps compile with **zero errors and zero warnings** against official BC
27.0 symbols. **29 current local checks pass.** The 25 BC AL tests are compiled,
not executed. Actual installation, scheduled tasks after logout, posting events,
concurrency, permissions and upgrades remain pending in a BC sandbox.

This is an independent P1-inspired recreation, with documented approximations.
It is not original firmware or a verified identical P1. The source accompanies
the compiled apps under GPLv2.

## Changes

Select **Accountant with Tamagotchi** in My Settings for the new accounting Role
Center. It reuses Accountant's standard parts and adds accounting navigation and
the pet. The pet is removed from the existing Accountant and Business Manager
Role Centers.

Advice reads your mappings and gets more urgent as needs worsen. A receipt line
shows captured, accepted, refused and pending care attempts. Event subscribers
and capture permissions are unchanged from 0.2.2.0; users need TAMA USER and must
work in the same company as the pet.

Manual clock fields are gone. BC time and a stored BC time zone drive the clock,
including DST. New setups default to Enabled = No; turn it on before testing.
Existing companies preserve their enabled state, mappings and current life.

The suite has 25 compiled AL tests, including all eight mappings through the
shared queue processor. Actual tenant retesting of business callbacks remains pending.

**If you fail to grow the business, your Tamagotchi will die of starvation.
Just like your users might.**
