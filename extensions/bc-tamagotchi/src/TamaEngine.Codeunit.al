codeunit 61205 "Tama Company Engine"
{
    Permissions = tabledata "Tama Setup" = r, tabledata "Tama State" = rim, tabledata "Tama Event Queue" = rim;
    var
        Life: Codeunit "Tama AL Life";
        Display: Codeunit "Tama AL Display";
        UI: Codeunit "Tama User Interface";
        Guidance: Codeunit "Tama Care Guidance";
        MissingSetupLbl: Label 'Open Tamagotchi Setup.';
        StartEggLbl: Label 'Start the first egg in Tamagotchi Setup.';
        LegacyLifeLbl: Label 'This company still has the old ROM prototype. Use New egg to archive it and start the AL life.';
        MissingStateLbl: Label 'The Tamagotchi state is missing. Do not reset it automatically.';
        InvalidVersionLbl: Label 'Unsupported Tamagotchi state version. An explicit migration is required.';

    procedure UpdateFrame(): Text
    var Setup: Record "Tama Setup"; State: Record "Tama State"; Frame: JsonObject; Value: Text;
    begin
        if not Setup.Get('') then exit(MessageFrame(Setup, MissingSetupLbl));
        if Setup."Generation No." = 0 then exit(MessageFrame(Setup, StartEggLbl));
        AdvanceThrough(CurrentDateTime(), false);
        if not State.Get('') then Error(MissingStateLbl);
        if State."State Version" = 1 then exit(MessageFrame(Setup, LegacyLifeLbl));
        LoadLife(State);
        Frame := Display.Frame(Life, CurrentDateTime());
        Frame.Add('generation', State."Generation No."); Frame.Add('revision', State.Revision);
        Frame.Add('company', CompanyName()); Frame.Add('sound', Setup."Play Sound");
        Frame.Add('shellDesign', Setup."Shell Design".AsInteger()); Frame.Add('busy', false); Frame.Add('lagSeconds', 0);
        Frame.Add('lastCare', UI.DisplayResult(State."Last Care Result"));
        Guidance.AddToFrame(Life, Setup, State, Frame);
        UI.AddToFrame(Frame); Frame.WriteTo(Value); exit(Value);
    end;

    procedure AdvanceThrough(AtTime: DateTime; BackgroundRun: Boolean)
    var Setup: Record "Tama Setup"; State: Record "Tama State"; Queue: Record "Tama Event Queue"; Applied: Boolean;
    begin
        if not Setup.Get('') or (Setup."Generation No." = 0) then exit;
        State.LockTable();
        if not State.Get('') then Error(MissingStateLbl);
        // Legacy snapshots are preserved until the administrator explicitly
        // archives them with New egg. Never silently invent a converted life.
        if State."State Version" = 1 then exit;
        LoadLife(State);
        Life.UseBCClock(Setup."BC Time Zone");
        Queue.SetCurrentKey(Status, "Occurred UTC", "Sequence No.");
        Queue.SetRange(Status, Queue.Status::Pending);
        Queue.SetFilter("Occurred UTC", '<=%1', AtTime);
        if Queue.FindSet(true) then repeat
            if Queue."Generation No." <> State."Generation No." then begin
                Queue.Status := Queue.Status::Skipped; Queue.Result := 'event.previous_life';
            end else begin
                Life.AdvanceTo(Queue."Occurred UTC");
                // Historical clock events remain readable but cannot overwrite BC time.
                Applied := Life.ApplyCare(Queue.Care, Life.ClockMinute() div 60, Life.ClockMinute() mod 60);
                if Applied then begin
                    Queue.Status := Queue.Status::Completed;
                    Queue.Result := CopyStr('care.completed:' + Format(Queue.Care.AsInteger(), 0, 9), 1, 250);
                end else begin
                    Queue.Status := Queue.Status::Skipped; Queue.Result := CopyStr(Life.RefusalKey(Queue.Care), 1, 250);
                end;
                State."Last Care Result" := Queue.Result;
            end;
            Queue."Completed UTC" := AtTime; Queue.Modify(false);
        until Queue.Next() = 0;
        Life.AdvanceTo(AtTime);
        SaveLife(State);
        State."Last Update UTC" := AtTime;
        if BackgroundRun then State."Last Background UTC" := AtTime;
        State.Modify(false);
    end;

    procedure InitializeLife(var Setup: Record "Tama Setup"; var State: Record "Tama State")
    begin
        State.Init(); State."Primary Key" := ''; State."Generation No." := Setup."Generation No.";
        State."State Version" := 2; State."Epoch UTC" := CurrentDateTime(); State.Revision := 0;
        Life.Initialize(State."Epoch UTC", 0, 0);
        Life.UseBCClock(Setup."BC Time Zone");
        SaveLife(State);
    end;

    local procedure LoadLife(var State: Record "Tama State")
    var Input: InStream; Value: Text;
    begin
        if State."State Version" <> 2 then Error(InvalidVersionLbl);
        State.CalcFields("AL Life Snapshot"); State."AL Life Snapshot".CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Value); Life.ImportState(Value);
    end;

    local procedure SaveLife(var State: Record "Tama State")
    var Output: OutStream;
    begin
        Clear(State."AL Life Snapshot"); State."AL Life Snapshot".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText(Life.ExportState()); State.Revision += 1; State."Last Update UTC" := CurrentDateTime();
        State."Died UTC" := Life.DiedAt();
    end;

    local procedure MessageFrame(Setup: Record "Tama Setup"; MessageText: Text): Text
    var Frame: JsonObject; Value: Text;
    begin
        Frame.Add('message', MessageText); Frame.Add('shellDesign', Setup."Shell Design".AsInteger());
        UI.AddToFrame(Frame); Frame.WriteTo(Value); exit(Value);
    end;
}
