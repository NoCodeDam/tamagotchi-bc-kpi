// Synthetic upgrade/appearance data only. Run in a dedicated test company.
codeunit 61252 "Tama Appearance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FreshSetupHasClassicPurpleCabinet()
    var Setup: Record "Tama Setup";
    begin
        Setup.SetDefaults();
        Setup.TestField("Shell Design", "Tama Shell Design"::PurplePink);
        Setup.TestField("Meal Event", "Tama BC Event"::SalesInvoice);
        Setup.TestField("Clean Event", "Tama BC Event"::CustomerApplication);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpgradePreservesLifeProgramAndCareConfiguration()
    var
        Setup: Record "Tama Setup";
        State: Record "Tama State";
        Management: Codeunit "Tama Setup Management";
        Upgrade: Codeunit "Tama Upgrade";
        Stream: OutStream;
        Input: InStream;
        Snapshot: Text;
    begin
        Management.EnsureSetup(); Setup.Get('');
        Setup."Generation No." := 123;
        Setup."ROM SHA256" := 'synthetic retained reference';
        Setup."Play Event" := "Tama BC Event"::Disabled;
        Setup."Clock Hour" := 17;
        Setup.Modify(false);
        if not State.Get('') then begin State.Init(); State."Primary Key" := ''; State.Insert(false); end;
        State."Generation No." := 123;
        State.Revision := 77;
        State."Emulated Ticks" := 42000;
        State."CPU Snapshot".CreateOutStream(Stream, TextEncoding::UTF8);
        Stream.WriteText('synthetic retained snapshot');
        State.Modify(false);
        Upgrade.MigrateShellDesign(Version.Create(0, 1, 0, 0));
        Setup.Get('');
        Setup.TestField("Shell Design", "Tama Shell Design"::PurplePink);
        Setup.TestField("Generation No.", 123);
        Setup.TestField("ROM SHA256", 'synthetic retained reference');
        Setup.TestField("Play Event", "Tama BC Event"::Disabled);
        Setup.TestField("Clock Hour", 17);
        State.Get(''); State.TestField("Generation No.", 123);
        State.TestField(Revision, 77); State.TestField("Emulated Ticks", 42000);
        State.CalcFields("CPU Snapshot"); State."CPU Snapshot".CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Snapshot);
        if Snapshot <> 'synthetic retained snapshot' then Error('Upgrade changed the existing CPU snapshot.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LaterUpgradeKeepsSelectedCabinet()
    var Setup: Record "Tama Setup"; Management: Codeunit "Tama Setup Management"; Upgrade: Codeunit "Tama Upgrade";
    begin
        Management.EnsureSetup(); Setup.Get('');
        Setup."Shell Design" := "Tama Shell Design"::Mermaid;
        Setup.Modify(false);
        Upgrade.MigrateShellDesign(Version.Create(0, 1, 1, 0));
        Setup.Get(''); Setup.TestField("Shell Design", "Tama Shell Design"::Mermaid);
    end;
}
