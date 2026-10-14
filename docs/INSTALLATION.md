# Installation

## Requirements

- Microsoft Dynamics 365 Business Central **27.0 or later**, with AL runtime 16.0 support.
- A **sandbox** for this prerelease. BC 27.0 compilation has passed; later versions
  and actual tenant installation have not been tested yet.
- Permission to upload/install a per-tenant extension and manage BC Job Queue entries.
- A modern BC web client with canvas support. Audio needs a browser-approved click.

No original firmware, ROM import, external game service or browser extension is required.

## Install the compiled app

1. Download `ERP Heritage_Tamagotchi BC KPI_0.3.0.0.app` from the release assets.
   Check its SHA-256 against the release's `SHA256SUMS.txt`.
2. In your BC sandbox, search for **Extension Management** and use **Upload Extension**
   to upload the main app. Select the deployment option appropriate to your sandbox.
   Wait for deployment to complete and check the deployment result.
3. Assign **TAMA ADMIN** to the setup administrator and **TAMA USER** to the people
   whose BC work should care for the pet. These permission sets supplement their
   existing BC access; they do not grant sales, purchasing, banking or posting rights.
4. Open **Tamagotchi Setup**. Installation creates an egg and settings, **not a
   scheduled job**. Confirm the care mappings and cabinet. **Enabled defaults to No** for a new
   company: turn it on to collect events. The clock follows BC automatically.
   Existing companies keep their enabled state during upgrade.
5. Choose **Create / restart background job** in Setup. This explicit action
   saves the job before scheduling it. Repeated clicks reuse the same company job
   without changing the pet generation. Then open **Job Queue Entries** and confirm
   one job for codeunit **61210 Tama Life Job**:
   recurring, one minute between runs, all seven weekdays selected, and
   **Run in User Session** disabled. Check its status and errors.
6. Check **Last background update** on Setup after the scheduler has had time to run.
   The job creator must keep permission to run the app and BC's standard job framework.
7. In **My Settings**, select **Accountant with Tamagotchi** as your role
   (**Bogholder med Tamagotchi** in Danish). It combines Accountant's standard
   parts and accounting navigation with the pet. The extension no longer inserts
   the pet on the standard Accountant or Business Manager Role Centers.
   Users of other profiles can search for **Company Tamagotchi**.

The normal BC task scheduler may run later than the requested minute. The model
uses timestamps so a delay does not grant the pet extra life.

Earlier 0.2.1.0 failed to install on BC 28.5 because its job was enqueued before
insertion. Explicit setup activation and insertion-before-Enqueue remain in this
release. The event subscribers and their permissions are unchanged from 0.2.2.0.
Event capture and care belong to the current company; check that you are working
in the same company as the pet. TAMA USER is required for event capture and viewing;
TAMA ADMIN is required for setup and job management. Existing financial permissions
remain necessary to perform the configured business actions.

## Existing installations

The app ID remains `a2c683fb-c3bb-4b35-9791-f3f7f73f3a0f`, publisher **ERP Heritage**.
The new name and version identify the same extension; do not remove its data to rename it.
Upgrade behavior needs sandbox verification before replacing an existing installation.

Upgrading from the native 0.2.0.0 build preserves existing data and life rules, adding the BC time-zone field.
Old 0.1.x emulator lives are preserved rather than guessed into the new model.
Use **New egg / reset** explicitly to archive an old life and start native AL life.
Do not use ForceSync or delete compatibility fields to get a fresh pet.

## Test app

`ERP Heritage_Tamagotchi BC KPI Tests_0.3.0.0.app` is optional and requires the
main app. Install it only for [the BC test plan](TESTING.md) in a dedicated test company.
It is not needed to display or care for the pet. The test source is provided separately.

## Uninstalling

Check the pet's Job Queue entry before removing the app and put it on hold so BC
does not keep trying to run an unavailable codeunit. There is no automatic job
cleanup routine in this prerelease. Retaining extension data preserves the stored
life and history; deleting extension data removes them.
