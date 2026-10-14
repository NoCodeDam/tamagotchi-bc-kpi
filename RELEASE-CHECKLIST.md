# Publishing the prepared package

Suggested repository name: **tamagotchi-bc-kpi**. Release tag: **v0.3.0.0**.
Title: **Tamagotchi BC KPI 0.3.0.0 — A KPI with a pulse**.

The package is prepared locally. No repository, GitHub release or LinkedIn post
has been created by this preparation.

## Before GitHub publication

1. Extract `tamagotchi-bc-kpi-source-0.3.0.0.zip` into its own empty directory.
   The contained `tamagotchi-bc-kpi/` directory is the repository root. Upload only
   this project, not the parent ERP Heritage workspace or an existing private history.
2. Read README, NOTICE, LICENSE and CREDITS. The distribution retains GPLv2.
   If a concrete license issue is found, stop; do not quietly replace the implementation.
3. Run the local source checks from `docs/BUILDING.md`. Keep generated app files,
   BC symbols, tenant launch configuration and credentials out of Git history.
4. Complete `docs/TESTING.md` in a sandbox. If publishing before completion,
   retain every tenant-pending statement and GitHub's **prerelease** checkbox.
   Do not label it production-ready based on a successful compile.

## GitHub

1. Create the separate **public** repository using your GitHub account. Keep the
   included README/license rather than asking GitHub to generate a conflicting license.
2. Add the extracted source as the initial commit. The package does not include
   a remote, Git history, an access token or a made-up maintainer identity.
3. Use `marketing/GITHUB-ABOUT.md` for About. Suggested topics: `business-central`,
   `dynamics365`, `al-language`, `tamagotchi`, `gamification`, `virtual-pet`.
4. Upload `docs/assets/social-preview.png` as the repository social preview if desired.
5. Create a release from the exact source commit with tag **v0.3.0.0**. Paste
   RELEASE-NOTES.md and attach all six files in the prepared **release-assets/**
   directory. Check **Set as a pre-release** while tenant acceptance is pending.
6. Confirm that the main app, optional test app and corresponding source ZIP are
   all downloadable. Verify checksums after download. GPL source must remain
   available alongside the binaries.

The outer **release-kit ZIP** is a handover bundle; it is not the source-only
repository upload. Its release-assets directory contains the actual GitHub assets.

## LinkedIn

Use `marketing/LINKEDIN.md` and `docs/assets/social-preview.png`. Replace the
single repository-link marker with the real GitHub URL before posting. Erik
Hougaard is already credited; a personal tag can be added through LinkedIn's UI.
The text is explicitly a prerelease announcement and does not claim tenant tests passed.

The dark starvation ending is intentional. The actual app rewards selected events,
not measured business growth. README and the user guide explain that distinction.

## After sandbox acceptance

Record the exact BC version and actual results in docs/TESTING.md. A later release
can remove the prerelease flag once its checks pass. If code changes, rebuild both
apps, regenerate source/checksums and tag that new source; do not replace the
existing release asset under an unchanged version.
