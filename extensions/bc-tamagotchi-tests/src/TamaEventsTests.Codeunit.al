codeunit 61251 "Tama Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceEventDeduplicates()
    var Setup: Record "Tama Setup"; Queue: Record "Tama Event Queue"; Events: Codeunit "Tama BC Events"; SourceId: Guid;
    begin
        Prepare(Setup);
        SourceId := CreateGuid();
        Events.Capture("Tama BC Event"::SalesInvoice,SourceId);
        Events.Capture("Tama BC Event"::SalesInvoice,SourceId);
        Queue.SetRange("Source SystemId",SourceId);
        if Queue.Count() <> 1 then Error('The same posted invoice was rewarded more than once.');
        Queue.FindFirst(); Queue.TestField(Care,"Tama Care"::Meal); Queue.TestField("Generation No.",123);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfiguredEventCanGiveTwoDifferentCareActions()
    var Setup: Record "Tama Setup"; Queue: Record "Tama Event Queue"; Events: Codeunit "Tama BC Events"; SourceId: Guid;
    begin
        Prepare(Setup);
        Setup."Medicine Event" := "Tama BC Event"::CustomerApplication; Setup.Modify();
        SourceId := CreateGuid(); Events.Capture("Tama BC Event"::CustomerApplication,SourceId);
        Queue.SetRange("Source SystemId",SourceId);
        if Queue.Count() <> 2 then Error('Both configured care actions must be queued.');
        if not Queue.Get("Tama BC Event"::CustomerApplication,SourceId,"Tama Care"::Clean) then Error('Cleaning is missing.');
        if not Queue.Get("Tama BC Event"::CustomerApplication,SourceId,"Tama Care"::Medicine) then Error('Configured medicine is missing.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledCompanyDoesNotCollectEvents()
    var Setup: Record "Tama Setup"; Queue: Record "Tama Event Queue"; Events: Codeunit "Tama BC Events"; SourceId: Guid;
    begin
        Prepare(Setup); Setup.Enabled := false; Setup.Modify();
        SourceId := CreateGuid(); Events.Capture("Tama BC Event"::SalesInvoice,SourceId);
        Queue.SetRange("Source SystemId",SourceId); if not Queue.IsEmpty() then Error('Disabled pet collected events.');
    end;

    local procedure Prepare(var Setup: Record "Tama Setup")
    var Management: Codeunit "Tama Setup Management";
    begin
        Management.EnsureSetup(); Setup.Get(''); Setup.SetDefaults(); Setup.Enabled := true; Setup."Generation No." := 123; Setup.Modify();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EverySupportedEventUsesTheSameConfiguredCapturePipeline()
    var Setup: Record "Tama Setup"; Queue: Record "Tama Event Queue"; Events: Codeunit "Tama BC Events";
        SourceId: Guid; EventType: Enum "Tama BC Event"; Index: Integer;
        State: Record "Tama State"; Life: Codeunit "Tama AL Life"; Engine: Codeunit "Tama Company Engine";
        Snapshot: JsonObject; Token: JsonToken; Value: Text; Input: InStream; Output: OutStream; AtTime: DateTime;
    begin
        Prepare(Setup);
        Setup."Clean Event" := "Tama BC Event"::Disabled;
        Setup."Play Event" := "Tama BC Event"::Disabled;
        Setup."Medicine Event" := "Tama BC Event"::Disabled;
        Setup."Discipline Event" := "Tama BC Event"::Disabled;
        Setup."Light On Event" := "Tama BC Event"::Disabled;
        Setup."Light Off Event" := "Tama BC Event"::Disabled;
        Setup."Snack Event" := "Tama BC Event"::Disabled;
        for Index := 1 to 8 do begin
            EventType := "Tama BC Event".FromInteger(Index);
            Setup."Meal Event" := EventType; Setup.Modify(false);
            // Each event gets the same hungry native life and goes through the
            // actual shared queue processor, not just a Capture call assertion.
            AtTime := CurrentDateTime(); Life.Initialize(AtTime - 360000, 12, 0); Life.AdvanceTo(AtTime);
            Snapshot.ReadFrom(Life.ExportState()); Snapshot.Replace('Hunger', 1); Snapshot.WriteTo(Value);
            State.LockTable();
            if not State.Get('') then begin State.Init(); State."Primary Key" := ''; State.Insert(false); end;
            State."State Version" := 2; State."Generation No." := 123;
            State."AL Life Snapshot".CreateOutStream(Output, TextEncoding::UTF8); Output.WriteText(Value); State.Modify(false);
            SourceId := CreateGuid();
            Events.Capture(EventType, SourceId); Events.Capture(EventType, SourceId);
            Queue.Reset(); Queue.SetRange("Source SystemId", SourceId);
            if Queue.Count() <> 1 then Error('Configured event %1 was missing or duplicated.', Index);
            Queue.FindFirst(); Queue.TestField(Care, "Tama Care"::Meal);
            Engine.AdvanceThrough(CurrentDateTime(), false);
            Queue.FindFirst(); Queue.TestField(Status, Queue.Status::Completed);
            State.Get(''); State.CalcFields("AL Life Snapshot");
            State."AL Life Snapshot".CreateInStream(Input, TextEncoding::UTF8); Input.ReadText(Value);
            Snapshot.ReadFrom(Value); Snapshot.Get('Hunger', Token);
            if Token.AsValue().AsInteger() <> 2 then Error('Event %1 did not feed the pet through the shared processor.', Index);
        end;
    end;

}
