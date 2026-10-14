# Testing and release acceptance

## Current evidence

| Check | State |
|---|---|
| Main app / separate test app against official BC 27.0 symbols | Compiled |
| Current local native, resource and display checks | 29 passed |
| BC AL tests in six test codeunits | 25 compiled; execution pending |
| Actual BC installation and permission assignment | Pending |
| Standard Job Queue after all users log out | Pending |
| Actual posting, preview/rollback and application/unapply scenarios | Pending |
| Concurrent viewer/job and long posting transactions | Pending |
| Upgrade preserving existing lives/settings/history | Pending |
| Original-identical P1 behavior | Not claimed |

Preview images use the real display/cabinet code with generated test data.
They are not screenshots of a BC tenant or original firmware.

## AL tests

Install the optional Tests app in a dedicated sandbox test company with the
standard BC test tooling available. Add codeunits **61250–61255** to a test suite
and run all 25 tests. Tests do not use external firmware or real financial data.

- **61250 Tama Life Tests**: nine lifecycle/worker/snapshot/migration tests.
- **61251 Tama Event Tests**: four event/shared-processor tests.
- **61252 Tama Appearance Tests**: three cabinet/default/upgrade tests.
- **61253 Tama Language Tests**: three translated UI/result tests.
- **61254 Tama Job Setup Tests**: two job-persistence/idempotency/reset tests.
- **61255 Tama Guidance Tests**: four advice/severity, automatic-clock, migration
  and refusal-reason tests.
  Run in a fresh test company before manually creating its job. The tests veto
  actual task scheduling for the pet job; they do not start or delete real tasks.

Persisted-data tests use AutoRollback and TestPermissions Disabled. They do not
validate TAMA USER / TAMA ADMIN restrictions. The worker test directly invokes
the codeunit with a temporary job record; it does not prove scheduled task execution.

## Required: no users online

1. Install the main app and confirm that no pet Job Queue entry was created.
   In Setup choose **Create / restart background job**. Confirm one job per
   company for codeunit 61210, recurring
   every minute on all seven weekdays with Run in User Session disabled.
2. Record the generation, state and Last Background UTC. Close every pet viewer
   and log every interactive user off; no browser polling may continue.
3. Use BC server-side job logs/read-only test tooling to verify successful scheduled
   runs and an increasing Last Background UTC. For a long unattended run, the job
   must persist Died UTC **before** the next viewer opens. Reopening the display
   and seeing a dead pet alone is insufficient: a viewer also performs catch-up.
4. Log in. The same generation should immediately show the saved current/dead state.
   There must be no automatic new egg or long client-side replay.
5. Post a synthetic sales invoice after death. Its care attempt should be rejected,
   with generation and death timestamp unchanged. Only an explicit New egg may reset.

## All eight events and company boundaries

Use Enabled = Yes and assign TAMA USER plus the user's ordinary business
permissions in the test company. Perform each supported event, then repeat with
changed mappings. A configured care attempt must appear in the **same company's**
history. Work in another company must not care for this pet. Disabled companies
must not collect events. Subscribers retain the original 0.2.2.0 permissions.

Check the receipt counter increases and the queue result explains the outcome.
A hungry, awake and healthy pet must accept its mapped food event. A dirty pet
must accept cleaning, including new partial applications/reapplications. Check
that previews, failed posting and unapply do not grant care. This tenant test is
required; local compilation alone does not validate the business callbacks.

## Real business events

In a dedicated synthetic company, test each default mapping and changed mappings.
Cover sales invoice/credit memo, purchase invoice, manual sales/purchase order
release, customer payment, explicit Apply Entries and posted bank reconciliation.
Check amounts and ledger results before/after to confirm the app performs no
financial write-back.

Check preview, posting failure/rollback, duplicate callbacks, partial applications
of the same invoice, unapply, multiple actions on one event and events while the
display is closed. A completed/refused action must not be processed twice.

## Operations and upgrades

- Run the worker and several viewers concurrently. Inspect revisions/event statuses.
- Hold a posting transaction open across worker execution. Verify timestamp ordering;
  record the unresolved late-commit case rather than treating it as passed.
- Click the Setup job action twice; verify a single job and unchanged generation/epoch.
  Use New egg and confirm it neither creates a missing job nor restarts a held one.
- Test administrator-held jobs, scheduler delays, job-user permission failures and
  restart. Restart may not create a new life or grant extra time.
- Test actual TAMA USER/TAMA ADMIN access with representative BC users.
- Test sleep, lights, medicine doses, game wins/losses, development and death.
- Test Danish, English UK and English US simultaneously on the same company pet.
- Select Accountant with Tamagotchi: check its standard parts and accounting destinations.
  Confirm the pet is absent from standard Accountant and Business Manager profiles.
- Test eight cabinets at narrow/wide Role Center widths; buttons must remain decorative.
- Upgrade native 0.2.0.0 and, if available, 0.1.x fixtures without ForceSync or data deletion.
- Put the job on hold before uninstalling; confirm no recurring failures remain.

Record BC version, test date, test company, test suite result, job logs and sanitized
screenshots. The prerelease flag and tenant-pending statements should only change
after the corresponding acceptance checks actually pass.
