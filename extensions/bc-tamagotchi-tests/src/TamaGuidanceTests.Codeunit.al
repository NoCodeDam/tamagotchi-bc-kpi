codeunit 61255 "Tama Guidance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AdviceFollowsChangedMappingsAndEscalates()
    var Setup: Record "Tama Setup"; Life: Codeunit "Tama AL Life"; Guidance: Codeunit "Tama Care Guidance";
        State: JsonObject; Value: Text; Mild, Severe: JsonArray; Token: JsonToken; Item: JsonObject;
    begin
        Setup.SetDefaults(); Setup.Enabled := true;
        Setup."Meal Event" := "Tama BC Event"::SalesCreditMemo;
        Life.Initialize(CurrentDateTime(), 12, 0); Life.AdvanceTo(CurrentDateTime() + 360000);
        State.ReadFrom(Life.ExportState()); State.Replace('Hunger', 3); State.WriteTo(Value); Life.ImportState(Value);
        Mild := Guidance.Advice(Life, Setup); Mild.Get(0, Token); Item := Token.AsObject();
        Item.Get('level', Token); if Token.AsValue().AsInteger() <> 1 then Error('Mild hunger did not have mild advice.');
        State.Replace('Hunger', 0); State.WriteTo(Value); Life.ImportState(Value);
        Severe := Guidance.Advice(Life, Setup); Severe.Get(0, Token); Item := Token.AsObject();
        Item.Get('level', Token); if Token.AsValue().AsInteger() <> 3 then Error('Empty hunger did not escalate advice.');
        if Guidance.ActionText(Setup, "Tama Care"::Meal) = Guidance.ActionText(Setup, "Tama Care"::Medicine) then
            Error('Advice ignored the changed care mappings.');
    end;

    [Test]
    procedure BCClockUsesTimezoneAndSurvivesRestore()
    var First, Restored: Codeunit "Tama AL Life"; Start: DateTime;
    begin
        Evaluate(Start, '2026-10-14T08:00:00Z', 9);
        First.Initialize(Start, 0, 0); First.UseBCClock('Romance Standard Time');
        if First.ClockMinute() <> 600 then Error('BC clock did not apply Copenhagen summer time.');
        Restored.ImportState(First.ExportState());
        First.AdvanceTo(Start + 600000); Restored.AdvanceTo(Start + 600000);
        if First.ExportState() <> Restored.ExportState() then Error('BC clock changed after restore.');
        if First.ClockMinute() <> 610 then Error('Automatic clock did not advance with BC time.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClockMigrationPreservesOptInAndMappings()
    var Setup: Record "Tama Setup"; Management: Codeunit "Tama Setup Management"; Upgrade: Codeunit "Tama Upgrade";
    begin
        Setup.SetDefaults(); if Setup.Enabled then Error('A fresh company must default to disabled.');
        Management.EnsureSetup(); Setup.Get(''); Setup.Enabled := true;
        Setup."Meal Event" := "Tama BC Event"::CustomerPayment;
        Setup."BC Time Zone" := 'UTC'; Setup.Modify(false);
        Upgrade.MigrateBCClock(Version.Create(0, 2, 2, 0)); Setup.Get('');
        Setup.TestField(Enabled, true);
        Setup.TestField("Meal Event", "Tama BC Event"::CustomerPayment);
        Setup.TestField("BC Time Zone", 'UTC');
    end;

    [Test]
    procedure RefusalReasonsDistinguishFullFoodFromSleepAndIllness()
    var Life: Codeunit "Tama AL Life"; State: JsonObject; Value: Text;
    begin
        Life.Initialize(CurrentDateTime(), 12, 0); Life.AdvanceTo(CurrentDateTime() + 360000);
        if Life.RefusalKey("Tama Care"::Meal) <> 'care.food_full' then Error('Full food did not have its own reason.');
        State.ReadFrom(Life.ExportState()); State.Replace('Sick', true); State.WriteTo(Value); Life.ImportState(Value);
        if Life.RefusalKey("Tama Care"::Meal) <> 'care.sick' then Error('Illness did not have its own reason.');
        State.Replace('Sleeping', true); State.WriteTo(Value); Life.ImportState(Value);
        if Life.RefusalKey("Tama Care"::Meal) <> 'care.asleep' then Error('Sleep did not have its own reason.');
    end;
}
