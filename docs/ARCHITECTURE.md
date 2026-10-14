# Architecture

All lifecycle transitions and LCD composition run in AL. JavaScript draws the
32×16 frame, applies the cabinet, plays permitted audio and opens Setup. It sends
only Ready, Tick and OpenSetup to BC. There are no working care buttons in the browser.

## Flow

1. A supported BC event is handled by codeunit 61202 **Tama BC Events**.
2. Its configured care actions are inserted into **Tama Event Queue** in the
   same posting transaction. The subscribers contain no COMMIT, life simulation
   or writes to BC financial tables. Financial rollback also rolls back care inserts.
3. Codeunit 61210 **Tama Life Job** calls 61205 **Tama Company Engine** through
   BC Job Queue, with one-minute recurrence and all seven weekdays enabled.
4. The engine locks the company pet state, handles committed events ordered by
   Occurred UTC / sequence, advances life to each timestamp and applies the action.
   It then advances to the current timestamp and saves the native snapshot.
5. A viewer uses the same engine and state lock, then obtains an AL-rendered frame
   from 61214 **Tama AL Display**. Viewer polls are not the background scheduler.

The collector and event publishers are unchanged from 0.2.2.0. Posting users
need TAMA USER in the company, as well as their usual business permissions.
Setup Enabled must be Yes. Events are company-specific and add no financial rights.

Each event/care/source GUID combination is deduplicated. Customer application
uses the new detailed application row rather than the old customer entry GUID,
allowing later partial applications to be recorded. Explicit and global preview
guards prevent rewards from posting previews; unapply is not a care trigger.
These contracts need end-to-end posting verification in a BC sandbox.

## Standard publisher catalog

| Supported BC event | Subscriber target |
|---|---|
| Sales invoice | 80 Sales-Post: OnAfterPostSalesDoc |
| Sales credit memo | 80 Sales-Post: OnAfterPostSalesDoc |
| Customer entries applied | 226 CustEntry-Apply Posted Entries: OnAfterPostApplyCustLedgEntry |
| Customer payment | 12 Gen. Jnl.-Post Line: OnAfterCustLedgEntryInsert |
| Purchase invoice | 90 Purch.-Post: OnAfterPostPurchaseDoc |
| Sales order manually released | 414 Release Sales Document: OnAfterManualReleaseSalesDoc |
| Purchase order manually released | 415 Release Purchase Document: OnAfterManualReleasePurchaseDoc |
| Bank reconciliation posted | Table 275 Bank Account Statement: OnAfterInsertEvent |

Signatures compile against the official BC 27.0 symbols. A successful build is
not proof that each user-facing operation invokes the expected event in a tenant.

Job creation is explicit: the Setup page calls `Tama Setup.CreateBackgroundJob()`,
which delegates to the background codeunit. A new Job Queue Entry is inserted
through the standard table trigger before Enqueue is called. The stable per-company
job ID lets later clicks reuse it. Install, upgrade and New egg never schedule tasks.

## Stored data

- **61200 Tama Setup**: mappings, device clock, sound, cabinet and generation.
- **61201 Tama State**: current native JSON snapshot, revision, epoch, last update,
  last background update and recorded death timestamp.
- **61202 Tama Event Queue**: care type, BC event, source SystemId, event/processing
  timestamps, generation, status and result. No invoice amount, lines or customer name.
- **61203 Tama Life Archive**: previous life snapshots retained on explicit reset.

Setup adds field 19, BC Time Zone, without deleting legacy hour/minute fields.
The explicit upgrade path preserves enabled state, mappings and life. Snapshots
add optional automatic-clock keys and still accept older version-one snapshots.

State, event log, settings and archive are company-scoped. Results are stored as
stable keys and translated when read, so a shared pet does not inherit the last
viewer's language. UI labels come from AL/XLIFF and GlobalLanguage, not navigator.language.
Compatibility fields from the retired prototype remain for data preservation.

## Lifecycle

61212 **Tama AL Life** owns the minute model and state serialization. 61213
**Tama P1 Rules** supplies character parameters and growth selection. Time is
stored from the epoch; repeated calls at the same timestamp do not age the pet.
After death, the original death minute is kept and later care cannot revive it.

Life snapshots have version 1; the table's native state envelope is version 2.
Unknown native snapshot versions are rejected. Upgrades preserve old snapshots;
they do not convert old CPU state into an invented native life.

The same state lock protects worker/viewer processing. A long financial transaction
that commits an event after a worker has passed its occurrence timestamp remains
an unresolved timing edge case; it is explicitly in [tenant testing](TESTING.md).

## Environment and privacy

The browser makes no external game requests, stores no pet in localStorage and
loads no CDN. The app has no external telemetry endpoint. Standard BC audit,
Job Queue logs and extension/platform behavior still apply. The display shows
the current company name, so use a demo company for public screenshots.

Main object IDs are **61200–61249**, test IDs **61250–61299**. Check these ranges
against other per-tenant extensions before installing.

Background scheduling follows Microsoft's
[Job Queue documentation](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-job-queue).

## Dedicated accounting Role Center

Page 61204 and profile TAMAGOTCHI BC KPI display **Accountant with Tamagotchi**.
The page composes all standard Accountant parts (including its hidden optional
charts) and our own accounting navigation. It references existing BC pages and
reports; Microsoft's page source is not copied or distributed. It does not inherit
third-party page extensions or profile customizations of the standard Accountant
page. Both former standard Role Center page extensions have been removed.
