# Known limitations

## Prerelease verification

A user reported that 0.2.1.0 failed to install on BC 28.5 with a missing Job Queue
Entry. The 0.2.2.0 hotfix moved job creation to an explicit Setup action and
inserts the entry before Enqueue. Retesting installation and job creation on the
reported environment remains pending.


Both packages compile and local checks pass. No BC tenant has been connected
for this release. Installation, scheduled background tasks with all users logged
out, permissions, real posting and upgrade paths still need sandbox acceptance.
Compiled AL tests have not been executed. Support for later BC versions is declared,
not independently verified.

BC's task scheduler does not promise exactly one run on the minute. Paused jobs,
permission errors or disabled scheduling can prevent updates being persisted while
everyone is offline. Timestamp catch-up preserves elapsed time when processing
resumes; it does not make a non-running job operational.

A long posting transaction committing after a worker has passed its event's
timestamp needs investigation. The current life model cannot reverse already
processed time. No production guarantee is made for that edge case.

The job has no automatic uninstall cleanup. Put it on hold before uninstalling.
Event/history data has no automatic retention cleanup. The receipt counts care
attempts, not unique business operations. Several configured care actions can
produce several attempts for one business event. No workload benchmark or
production performance budget has been established.

## P1 fidelity

This is an independent recreation using published vintage P1 behavior research.
It is neither Bandai's source nor a verified identical P1 port.

The following are explicit approximation/design choices:

- Fifteen-minute hunger/happiness and lights warning deadlines.
- Sickness at four droppings.
- Death at 360 awake minutes with an empty hunger/happiness meter or 1,440 awake
  minutes ill.
- The discipline-call schedule and aging after sickness.
- Project-created pixel drawings, simplified movement and attention beeps.
- BC events substitute for device inputs; care can be refused by the life model.

Numerical character timings and growth rules refer to rhubarbtart's research
linked in CREDITS. That research also contains hypotheses; the approximations
above must not be described as verified original firmware rules.

There is no Gen 2 selection, manual character selection, real device firmware,
original sound sequence, breeding simulation or active care buttons. Cosmetic
cabinets all use the same life model. Snack-triggered instant childhood death
from later reissues has not been introduced.

## Business meaning

The app reacts to selected business events, not revenue, profit or growth. Invoice
value does not change meal size. Defaults are playful mappings, not validated
business KPIs or a guarantee that normal office activity keeps the pet alive.
It can die overnight or during a weekend, and it can eventually die despite good care.

The pet appears on the new **Accountant with Tamagotchi** Role Center. Standard
Accountant and Business Manager pages are no longer extended. The new page reuses
Accountant parts and offers accounting navigation; it is not a byte-identical copy
of every standard action, and does not inherit other extensions or personalizations
from page 9027. Other profiles can use the standalone Company Tamagotchi viewer.
