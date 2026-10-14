# A KPI with a pulse

The pet starts as an egg and hatches after about five elapsed minutes. It grows
through baby, child and teen stages. Care and missed discipline calls influence
the adult it becomes. You cannot choose a character from Setup.

Food and happiness have four hearts. Meals restore food; play and snacks can
restore happiness. Weight changes without making the drawing larger. Cleaning
removes droppings, while illness requires the character's number of medicine doses.
Discipline is useful when the pet calls for it, not as a constant bonus.

## Working in BC is how you play

With the defaults, post sales invoices for food and use **Apply Entries** in
the customer module for cleaning. Customer payments trigger play; purchase
invoices trigger medicine. The full set is in [configuration](CONFIGURATION.md).

Care events are attempts, not guaranteed rewards. The pet rejects food if it
is full, asleep or ill. Medicine works only while awake and sick. Cleaning and
light changes can be accepted during sleep. Nothing revives a dead pet.

The advice below the device reads the current care mappings: it tells you which
business action supplies each need, with escalating language as it gets worse.
For example, food warnings range from a little hungry to **I AM STARVING!**.
Changing a mapping changes the instructions; missing mappings point to Setup.

The receipt line shows received, accepted, refused and pending **care attempts**.
Several care mappings can produce several attempts from
one operation. Refusals distinguish full food, sleep, illness, an egg, death,
already-clean status and other specific causes. Accepted play can still lose its
simulated game, so accepted does not always mean a meter increased.

Open **Tamagotchi Care History** from Setup to see Pending, Completed or Skipped
attempts and their results. Several configured actions can produce several rows
from the same business event.

## Sleep, weekends and unattended life

Sleep follows the current character and pet clock. Lights should be turned off
at bedtime. Baby sleep is a short nap; older characters have nightly schedules.
Hunger and happiness decay pause while sleeping. Logged-out time and weekends
continue to count as elapsed life, with the same sleep rules.

The standard BC Job Queue advances the stored life without a Role Center open.
Opening the display also brings it up to the current timestamp. The scheduled job
must actually be working: check its logs and **Last background update** in Setup.

## How long does it live?

There is no one fixed expiry date. Neglect can kill it within hours. The current
model includes death after 360 awake minutes with hunger or happiness continuously
empty, 1,440 awake minutes ill, five adult care mistakes, or the third sickness in
a non-baby stage. These are different routes to death, so six hours is not a
guaranteed minimum survival time.

With ideal care and prompt medicine, scheduled sickness alone gives Mametchi
about **15 days as an adult**, plus earlier growth. Nyorotchi has about **1.4 days
as an adult**. These are parameter-based estimates, not measurements in a BC tenant.
See [known limitations](KNOWN-LIMITATIONS.md) for fidelity and other differences.

## Troubleshooting

| Symptom | Check |
|---|---|
| No pet on my Role Center | Select Accountant with Tamagotchi in My Settings. Standard Accountant/Business Manager no longer include the pet. Search Company Tamagotchi for other profiles. Check TAMA USER. |
| New invoices do not feed it | Check that you posted in the same company as the pet. Confirm Enabled, TAMA USER, food mapping, current generation and event result. It may be full, asleep, sick or dead. |
| A payment did not clean it | The default cleaning trigger is explicit customer application; payment posting defaults to play. |
| Droppings gone but still sick | Cleaning does not heal. Trigger medicine while awake, using enough doses. |
| Background timestamp is old | Check Job Queue status, logs, recurrence, job creator and its BC permissions. |
| It died while nobody was online | Expected for an unattended pet. Logout is not a pause. New egg is an explicit admin action. |
| No sound | Enable sound in Setup and click the display's Enable sound button; browser audio policy still applies. |
| Labels stay Danish | Check the individual BC user's language, then reopen the page. Company/browser language does not choose the labels. |
| Old prototype life shown after upgrade | Choose New egg explicitly to archive it and begin native AL life. |

Restarting the background job, refreshing the browser or posting an invoice does
not reset the generation. This is a shared activity toy, not a financial metric
or an employee ranking system.
