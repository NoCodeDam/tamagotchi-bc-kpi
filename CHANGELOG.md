# Changelog

## 0.3.0.0 — accounting Role Center and care advice / prerelease

- Removed the pet from the standard Accountant and Business Manager Role Centers.
- Added the dedicated **Accountant with Tamagotchi** profile and page, reusing
  Accountant's standard parts with accounting navigation and the pet.
- Added setup-aware care advice that escalates with worsening needs, a cleanliness
  meter, care receipts and specific refusal reasons.
- Removed manual time controls; BC's time and captured BC zone drive the automatic clock, with DST.
- Defaulted new setups to Enabled = No; preserved existing opt-in and mappings.
- Added field 19 and an explicit preservation migration; old snapshots still load.
- Added compiled AL checks for all eight mappings, advice, clock, migration and refusals.
- Preserved the 0.2.2.0 event subscribers and capture permissions.

## 0.2.2.0 — installation hotfix / prerelease

- Removed job creation/restart from install, upgrade and New egg.
- Added `Tama Setup.CreateBackgroundJob()` and the promoted Setup action
  **Create / restart background job**, translated into Danish and English.
- Saved new Job Queue entries with Insert(true) before Enqueue, fixing the
  missing-record path reported on BC 28.5.
- Displayed **Not created** before explicit activation. Repeated activation uses
  the same job; restarting it does not reset the pet.
- Added two compiled AL regression tests for implicit scheduling, persistence,
  idempotency and preservation of the current life.
- Preserved the schema, life rules and event mappings. BC 28.5 retest is pending.

## 0.2.1.0 — prerelease

- Named the app **Tamagotchi BC KPI**, retaining its app ID and publisher for upgrades.
- Branded the Role Center caption and regenerated Danish/English translations.
- Prepared public source, build tools, guides and release assets.
- Added credit to Erik Hougaard / BusinessCentralDoom and the P1 research.
- Separated current native test helpers from the archived emulator test adapter.
- Kept life rules, schema, default care mappings and event subscribers unchanged.

Compiled against BC 27.0, Cloud / runtime 16.0. BC tenant acceptance is pending.

## 0.2.0.0 — earlier development build

Native AL life, background processing through BC Job Queue, saved death timestamps,
an explicit new egg, eight cabinets and per-user languages.

## 0.1.x — retired prototype

Earlier development used a separate ROM with an AL chip emulator. That prototype
was retired and is not part of this release.
