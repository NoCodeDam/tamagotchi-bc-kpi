// Synthetic dates/data, no ROM. Run in an isolated BC test company.
codeunit 61250 "Tama Life Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UnattendedLifeDiesWithoutOpeningAPage()
    var Life: Codeunit "Tama AL Life"; Start: DateTime;
    begin
        Start := CreateDateTime(DMY2Date(14, 10, 2026), 120000T);
        Life.Initialize(Start, 12, 0);
        Life.AdvanceTo(Start + 86400000);
        if not Life.IsDead() then Error('Unattended life survived indefinitely.');
        if (Life.DiedAt() <= Start) or (Life.DiedAt() >= Start + 86400000) then Error('Death was not recorded at its actual time.');
    end;

    [Test]
    procedure DelayedWorkerMatchesMinuteByMinuteLife()
    var Fine, Coarse: Codeunit "Tama AL Life"; Start: DateTime; Minute: Integer;
    begin
        Start := CreateDateTime(DMY2Date(14, 10, 2026), 120000T);
        Fine.Initialize(Start, 12, 0); Coarse.Initialize(Start, 12, 0);
        for Minute := 1 to 1440 do Fine.AdvanceTo(Start + Minute * 60000);
        Coarse.AdvanceTo(Start + 86400000);
        if Fine.ExportState() <> Coarse.ExportState() then Error('Worker frequency changed the life outcome.');
    end;

    [Test]
    procedure SavedLifeContinuesWithoutReset()
    var First, Restored: Codeunit "Tama AL Life"; Start: DateTime;
    begin
        Start := CreateDateTime(DMY2Date(14, 10, 2026), 120000T);
        First.Initialize(Start, 12, 0); First.AdvanceTo(Start + 600000);
        Restored.ImportState(First.ExportState());
        First.AdvanceTo(Start + 3600000); Restored.AdvanceTo(Start + 3600000);
        if First.ExportState() <> Restored.ExportState() then Error('Restore changed the life.');
    end;

    [Test]
    procedure PostingAfterDeathCannotResurrect()
    var Life: Codeunit "Tama AL Life"; Start, Death: DateTime;
    begin
        Start := CurrentDateTime(); Life.Initialize(Start, 12, 0); Life.AdvanceTo(Start + 86400000);
        Death := Life.DiedAt();
        if Life.ApplyCare("Tama Care"::Meal, 12, 0) then Error('Dead pet accepted food.');
        if not Life.IsDead() or (Life.DiedAt() <> Death) then Error('Care resurrected a dead pet.');
    end;

    [Test]
    procedure RepeatedFramesCannotAgeLife()
    var Life: Codeunit "Tama AL Life"; Start: DateTime; Before: Text; Index: Integer;
    begin
        Start := CurrentDateTime(); Life.Initialize(Start, 12, 0); Life.AdvanceTo(Start + 600000);
        Before := Life.ExportState();
        for Index := 1 to 100 do Life.AdvanceTo(Start + 600000);
        if Before <> Life.ExportState() then Error('Refreshing changed time.');
    end;

    [Test]
    procedure RejectsUnknownLifeSnapshotVersion()
    var Life: Codeunit "Tama AL Life"; State: JsonObject; Value: Text;
    begin
        Life.Initialize(CurrentDateTime(), 12, 0); State.ReadFrom(Life.ExportState());
        State.Replace('version', 2); State.WriteTo(Value);
        asserterror Life.ImportState(Value);
    end;

    [Test]
    procedure P1ParametersAndEvolutionUseDocumentedValues()
    var Rules: Codeunit "Tama P1 Rules"; H, P, S, E, W, Shots, Wake, Bed, D, CallEvery: Integer;
    begin
        Rules.Stats(5, H, P, S, E, W, Shots, Wake, Bed, D, CallEvery);
        if (H <> 81) or (P <> 91) or (Wake <> 9) or (Bed <> 22) or (Shots <> 1) then Error('Wrong Mametchi parameters.');
        if Rules.Adult(3, true, 0, 0) <> 6 then Error('Type-two Tamatchi growth changed.');
        if Rules.Adult(4, false, 5, 2) <> 9 then Error('Kuchitamatchi growth changed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackgroundCodeunitStoresDeathWithoutRolecenter()
    var Setup: Record "Tama Setup"; State: Record "Tama State"; Job: Record "Job Queue Entry" temporary;
        Management: Codeunit "Tama Setup Management"; Life: Codeunit "Tama AL Life"; Output: OutStream; Start: DateTime;
    begin
        Management.EnsureSetup(); Setup.Get(''); Setup."Generation No." := 999; Setup.Modify(false);
        if not State.Get('') then begin State.Init(); State."Primary Key" := ''; State.Insert(false); end;
        Start := CurrentDateTime() - 86400000;
        Life.Initialize(Start, 12, 0);
        State."Generation No." := 999; State."State Version" := 2;
        State."AL Life Snapshot".CreateOutStream(Output, TextEncoding::UTF8); Output.WriteText(Life.ExportState());
        State.Modify(false);
        Codeunit.Run(Codeunit::"Tama Life Job", Job);
        State.Get(''); State.TestField("Died UTC"); State.TestField("Last Background UTC");
        if State."Died UTC" >= State."Last Background UTC" then Error('Death was deferred to the next user session.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SchemaUpgradeKeepsLegacySnapshotAndRequiresExplicitNewLife()
    var Setup: Record "Tama Setup"; State: Record "Tama State"; Upgrade: Codeunit "Tama Upgrade";
        Management: Codeunit "Tama Setup Management"; Output: OutStream; Input: InStream; Value: Text;
    begin
        Management.EnsureSetup(); Setup.Get(''); Setup."Generation No." := 77; Setup.Modify(false);
        if not State.Get('') then begin State.Init(); State."Primary Key" := ''; State.Insert(false); end;
        State."State Version" := 1; State."Generation No." := 77;
        State."CPU Snapshot".CreateOutStream(Output, TextEncoding::UTF8); Output.WriteText('synthetic legacy evidence'); State.Modify(false);
        Upgrade.MigrateALSchema(Version.Create(0, 1, 2, 0));
        State.Get(''); State.TestField("State Version", 1); State.TestField("Generation No.", 77);
        State.CalcFields("CPU Snapshot", "AL Life Snapshot");
        if State."AL Life Snapshot".HasValue() then Error('Upgrade silently invented a new life.');
        State."CPU Snapshot".CreateInStream(Input, TextEncoding::UTF8); Input.ReadText(Value);
        if Value <> 'synthetic legacy evidence' then Error('Legacy evidence changed.');
    end;
}
