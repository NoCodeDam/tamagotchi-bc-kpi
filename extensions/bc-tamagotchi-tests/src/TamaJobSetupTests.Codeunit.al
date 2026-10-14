// Synthetic dedicated test company. Scheduling is vetoed for the pet job only.
codeunit 61254 "Tama Job Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        EnqueueCount: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewEggNeverCreatesOrRestartsScheduledJob()
    var
        Management: Codeunit "Tama Setup Management";
        Probe: Codeunit "Tama Job Setup Tests";
        Entry: Record "Job Queue Entry";
        Setup: Record "Tama Setup";
        BeforeCount, BeforeGeneration: Integer;
    begin
        Management.EnsureSetup(); Setup.Get(''); BeforeGeneration := Setup."Generation No.";
        Entry.SetRange(ID, PetJobId()); BeforeCount := Entry.Count();
        BindSubscription(Probe);
        Management.NewEgg();
        UnbindSubscription(Probe);
        if Probe.ObservedEnqueues() <> 0 then Error('New egg tried to schedule a job.');
        if Entry.Count() <> BeforeCount then Error('New egg created a job implicitly.');
        Setup.Get('');
        if Setup."Generation No." <> BeforeGeneration + 1 then Error('New egg did not start a life.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupCreatesPersistedJobAndReusesItWithoutResettingLife()
    var
        Management: Codeunit "Tama Setup Management";
        Probe: Codeunit "Tama Job Setup Tests";
        Setup: Record "Tama Setup";
        Entry: Record "Job Queue Entry";
        State: Record "Tama State";
        BeforeGeneration: Integer;
        BeforeEpoch: DateTime;
    begin
        // No real task is started/deleted. Run in a fresh test company before
        // manually creating its pet job; existing operator jobs are not touched.
        if Entry.Get(PetJobId()) then Error('Use a fresh test company without an existing pet job for this test.');
        Management.EnsureSetup(); Setup.Get('');
        if Setup."Generation No." = 0 then Management.NewEgg();
        Setup.Get(''); BeforeGeneration := Setup."Generation No.";
        State.Get(''); BeforeEpoch := State."Epoch UTC";
        BindSubscription(Probe);
        Setup.CreateBackgroundJob();
        Entry.Get(PetJobId());
        Entry.TestField("Object Type to Run", Entry."Object Type to Run"::Codeunit);
        Entry.TestField("Object ID to Run", Codeunit::"Tama Life Job");
        Entry.TestField("Recurring Job", true);
        Entry.TestField("No. of Minutes between Runs", 1);
        Entry.TestField("Run in User Session", false);
        Entry.TestField("Run on Mondays", true); Entry.TestField("Run on Tuesdays", true);
        Entry.TestField("Run on Wednesdays", true); Entry.TestField("Run on Thursdays", true);
        Entry.TestField("Run on Fridays", true); Entry.TestField("Run on Saturdays", true);
        Entry.TestField("Run on Sundays", true);
        Setup.CreateBackgroundJob();
        UnbindSubscription(Probe);
        Entry.SetRange(ID, PetJobId());
        if Entry.Count() <> 1 then Error('Setup created duplicate jobs.');
        if Probe.ObservedEnqueues() = 0 then Error('Setup did not invoke standard job scheduling.');
        Setup.Get(''); State.Get('');
        if (Setup."Generation No." <> BeforeGeneration) or (State."Epoch UTC" <> BeforeEpoch) then
            Error('Creating or restarting the job reset the pet.');
    end;

    procedure ObservedEnqueues(): Integer
    begin
        exit(EnqueueCount);
    end;

    local procedure PetJobId(): Guid
    var Value: Guid;
    begin
        Evaluate(Value, '{7D7FF8C6-D5F3-4A12-A6E9-3AD077D52B23}');
        exit(Value);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeEnqueueJobQueueEntry', '', false, false)]
    local procedure BeforeEnqueue(var JobQueueEntry: Record "Job Queue Entry")
    var Persisted: Record "Job Queue Entry";
    begin
        if JobQueueEntry.ID <> PetJobId() then exit;
        // This is the missing-record regression: standard scheduling must only
        // ever receive a record already present in the database.
        if not Persisted.Get(JobQueueEntry.ID) then Error('Job was enqueued before insertion.');
        EnqueueCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure PreventRealTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        if JobQueueEntry.ID = PetJobId() then DoNotScheduleTask := true;
    end;
}
