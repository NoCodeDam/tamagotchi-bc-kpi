codeunit 61210 "Tama Life Job"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var Engine: Codeunit "Tama Company Engine";
    begin
        // BC's task scheduler runs this without a browser or an online user.
        Engine.AdvanceThrough(CurrentDateTime(), true);
    end;
}

codeunit 61211 "Tama Background Life"
{
    Permissions = tabledata "Job Queue Entry" = rim;
    var DescriptionLbl: Label 'Tamagotchi: background life';
        NotCreatedLbl: Label 'Not created';

    procedure EnsureScheduled(RestartRequested: Boolean)
    var Entry: Record "Job Queue Entry"; JobId: Guid;
    begin
        Evaluate(JobId, '{7D7FF8C6-D5F3-4A12-A6E9-3AD077D52B23}');
        Entry.LockTable();
        if Entry.Get(JobId) then begin
            // Do not silently restart a job put on hold by an administrator.
            if RestartRequested then Entry.SetStatus(Entry.Status::Ready);
            exit;
        end;
        Entry.Init(); Entry.ID := JobId;
        Entry.Validate("Object Type to Run", Entry."Object Type to Run"::Codeunit);
        Entry.Validate("Object ID to Run", Codeunit::"Tama Life Job");
        Entry.Description := DescriptionLbl;
        Entry."User ID" := CopyStr(UserId(), 1, MaxStrLen(Entry."User ID"));
        Entry."Recurring Job" := true; Entry."No. of Minutes between Runs" := 1;
        Entry."Run on Mondays" := true; Entry."Run on Tuesdays" := true; Entry."Run on Wednesdays" := true;
        Entry."Run on Thursdays" := true; Entry."Run on Fridays" := true; Entry."Run on Saturdays" := true; Entry."Run on Sundays" := true;
        Entry."Run in User Session" := false;
        Entry."Maximum No. of Attempts to Run" := 10; Entry."Rerun Delay (sec.)" := 60;
        Entry."Earliest Start Date/Time" := CurrentDateTime(); Entry.Status := Entry.Status::"On Hold";
        // Enqueue refreshes/locks a persisted entry in newer BC versions.
        // Insert through the table trigger before asking BC to schedule it.
        Entry.Insert(true);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", Entry);
    end;

    procedure StatusText(): Text
    var Entry: Record "Job Queue Entry"; JobId: Guid;
    begin
        Evaluate(JobId, '{7D7FF8C6-D5F3-4A12-A6E9-3AD077D52B23}');
        if Entry.Get(JobId) then exit(Format(Entry.Status));
        exit(NotCreatedLbl);
    end;
}
