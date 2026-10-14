codeunit 61206 "Tama Setup Management"
{
    Permissions = tabledata "Tama Setup" = rim, tabledata "Tama State" = rim,
        tabledata "Tama Life Archive" = ri, tabledata "Tama Event Queue" = rim;

    var
        UserMessage1Lbl: Label 'Start an egg first.';

    procedure EnsureSetup()
    var
        Setup: Record "Tama Setup";
    begin
        if Setup.Get('') then exit;
        Setup.Init();
        Setup."Primary Key" := '';
        Setup.SetDefaults();
        if Setup.Insert(false) then;
    end;

    procedure NewEgg()
    var
        Setup: Record "Tama Setup";
        State: Record "Tama State";
        Archive: Record "Tama Life Archive";
        Queue: Record "Tama Event Queue";
        Engine: Codeunit "Tama Company Engine";
        Exists: Boolean;
    begin
        Setup.LockTable();
        Setup.Get('');
        State.LockTable();
        Exists := State.Get('');
        if Exists then begin
            State.CalcFields("CPU Snapshot", "Care Snapshot", "AL Life Snapshot");
            Archive.Init();
            Archive."Generation No." := State."Generation No.";
            Archive."CPU Snapshot" := State."CPU Snapshot";
            Archive."Care Snapshot" := State."Care Snapshot";
            Archive."AL Life Snapshot" := State."AL Life Snapshot";
            Archive."Epoch UTC" := State."Epoch UTC";
            Archive."Archived UTC" := CurrentDateTime();
            Archive."ROM SHA256" := Setup."ROM SHA256";
            Archive.Insert(false);
        end;
        Setup."Generation No." += 1;
        Engine.InitializeLife(Setup, State);
        Setup.Modify(false);
        if Exists then State.Modify(false) else State.Insert(false);
        Queue.SetFilter("Generation No.", '<%1', Setup."Generation No.");
        Queue.SetRange(Status, Queue.Status::Running);
        Queue.ModifyAll(Result, 'care.reset');
        Queue.ModifyAll("Completed UTC", CurrentDateTime());
        Queue.ModifyAll(Status, Queue.Status::Skipped);
        // Installing or resetting a life never creates/restarts scheduled tasks.
        // The administrator starts the job explicitly from Tamagotchi Setup.
        // Old life snapshots and the event log are preserved, never deleted.
    end;

    procedure SetDeviceClock()
    var
        Setup: Record "Tama Setup";
        Queue: Record "Tama Event Queue";
    begin
        Setup.Get('');
        if Setup."Generation No." = 0 then Error(UserMessage1Lbl);
        Queue.Init();
        Queue."BC Event" := "Tama BC Event"::Disabled;
        Queue."Source SystemId" := CreateGuid();
        Queue.Care := "Tama Care"::InitializeClock;
        Queue."Occurred UTC" := CurrentDateTime();
        Queue."Generation No." := Setup."Generation No.";
        Queue.Insert(false);
    end;
}

codeunit 61207 "Tama Install"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        SetupManagement: Codeunit "Tama Setup Management";
        State: Record "Tama State";
    begin
        SetupManagement.EnsureSetup();
        if not State.Get('') then SetupManagement.NewEgg();
    end;
}
