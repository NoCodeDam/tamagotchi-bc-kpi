table 61200 "Tama Setup"
{
    Caption = 'Tamagotchi Setup';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            trigger OnValidate()
            begin
                if Enabled then EnsureBCClock();
            end;
        }
        field(3; "Meal Event"; Enum "Tama BC Event") { Caption = 'Event: meal'; }
        field(4; "Clean Event"; Enum "Tama BC Event") { Caption = 'Event: cleaning'; }
        field(5; "Play Event"; Enum "Tama BC Event") { Caption = 'Event: play'; }
        field(6; "Medicine Event"; Enum "Tama BC Event") { Caption = 'Event: medicine'; }
        field(7; "Discipline Event"; Enum "Tama BC Event") { Caption = 'Event: discipline'; }
        field(8; "Light On Event"; Enum "Tama BC Event") { Caption = 'Event: light on'; }
        field(9; "Light Off Event"; Enum "Tama BC Event") { Caption = 'Event: light off'; }
        field(10; "Snack Event"; Enum "Tama BC Event") { Caption = 'Event: snack'; }
        field(11; "Play Sound"; Boolean) { Caption = 'Play attention sound'; }
        field(12; "Clock Hour"; Integer) { Caption = 'Clock: hour'; MinValue = 0; MaxValue = 23; }
        field(13; "Clock Minute"; Integer) { Caption = 'Clock: minute'; MinValue = 0; MaxValue = 59; }
        field(14; "Generation No."; Integer) { Caption = 'Generation'; Editable = false; }
        field(15; "ROM SHA256"; Text[64]) { Caption = 'Original program: SHA-256'; Editable = false; }
        field(16; "Original ROM"; Blob) { }
        field(17; "Max Steps Per Update"; Integer) { Caption = 'CPU steps per update'; MinValue = 1000; MaxValue = 50000; }
        field(18; "Shell Design"; Enum "Tama Shell Design") { Caption = 'Cabinet'; InitValue = PurplePink; }
        field(19; "BC Time Zone"; Text[250]) { Caption = 'BC time zone'; Editable = false; }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }

    procedure SetDefaults()
    begin
        Enabled := false;
        "Meal Event" := "Tama BC Event"::SalesInvoice;
        "Clean Event" := "Tama BC Event"::CustomerApplication;
        "Play Event" := "Tama BC Event"::CustomerPayment;
        "Medicine Event" := "Tama BC Event"::PurchaseInvoice;
        "Discipline Event" := "Tama BC Event"::SalesOrderReleased;
        "Light On Event" := "Tama BC Event"::PurchaseOrderReleased;
        "Light Off Event" := "Tama BC Event"::BankStatementPosted;
        "Snack Event" := "Tama BC Event"::SalesCreditMemo;
        "Play Sound" := true;
        "Clock Hour" := 12;
        "Clock Minute" := 0;
        "Max Steps Per Update" := 12000;
        "Shell Design" := "Tama Shell Design"::PurplePink;
    end;

    procedure CreateBackgroundJob()
    var Jobs: Codeunit "Tama Background Life";
    begin
        // Explicit setup operation, never called by install/upgrade or NewEgg.
        TestField("Generation No.");
        Jobs.EnsureScheduled(true);
    end;

    procedure EnsureBCClock()
    var Settings: SessionSettings;
    begin
        if "BC Time Zone" <> '' then exit;
        // Activation takes the administrator's BC time zone once. All viewers
        // and the background worker then use the same automatic company clock.
        if GuiAllowed() then begin
            Settings.Init(); "BC Time Zone" := CopyStr(Settings.TimeZone(), 1, 250);
        end;
        if "BC Time Zone" = '' then "BC Time Zone" := 'UTC';
    end;

    procedure CareEvent(Care: Enum "Tama Care"): Enum "Tama BC Event"
    begin
        case Care of
            Care::Meal: exit("Meal Event");
            Care::Clean: exit("Clean Event");
            Care::Play: exit("Play Event");
            Care::Medicine: exit("Medicine Event");
            Care::Discipline: exit("Discipline Event");
            Care::LightOn: exit("Light On Event");
            Care::LightOff: exit("Light Off Event");
            Care::Snack: exit("Snack Event");
        end;
        exit("Tama BC Event"::Disabled);
    end;
}

table 61201 "Tama State"
{
    Caption = 'Tamagotchi state';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "CPU Snapshot"; Blob) { }
        field(3; "Care Snapshot"; Blob) { }
        field(4; "Epoch UTC"; DateTime) { }
        field(5; "Generation No."; Integer) { }
        field(6; "State Version"; Integer) { }
        field(7; Revision; BigInteger) { }
        field(8; "Emulated Ticks"; BigInteger) { }
        field(9; "Last Update UTC"; DateTime) { }
        field(10; "Last Care Result"; Text[250]) { }
        field(11; "AL Life Snapshot"; Blob) { }
        field(12; "Last Background UTC"; DateTime) { }
        field(13; "Died UTC"; DateTime) { }
    }
    keys { key(PK; "Primary Key") { Clustered = true; } }
}

table 61202 "Tama Event Queue"
{
    Caption = 'Tamagotchi events';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "BC Event"; Enum "Tama BC Event") { Caption = 'BC event'; }
        field(2; "Source SystemId"; Guid) { }
        field(3; Care; Enum "Tama Care") { Caption = 'Care'; }
        field(4; "Sequence No."; BigInteger) { AutoIncrement = true; }
        field(5; "Occurred UTC"; DateTime) { Caption = 'Recorded'; }
        field(6; "Generation No."; Integer) { Caption = 'Generation'; }
        field(7; Status; Option) { OptionMembers = Pending,Running,Completed,Skipped; OptionCaption = 'Pending,Running,Completed,Skipped'; }
        field(8; Result; Text[250]) { Caption = 'Result'; }
        field(9; "Completed UTC"; DateTime) { }
    }
    keys
    {
        key(PK; "BC Event", "Source SystemId", Care) { Clustered = true; }
        key(Chronological; "Occurred UTC", "Sequence No.") { }
        key(Pending; Status, "Occurred UTC", "Sequence No.") { }
    }
}

table 61203 "Tama Life Archive"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Generation No."; Integer) { }
        field(2; "CPU Snapshot"; Blob) { }
        field(3; "Care Snapshot"; Blob) { }
        field(4; "Epoch UTC"; DateTime) { }
        field(5; "Archived UTC"; DateTime) { }
        field(6; "ROM SHA256"; Text[64]) { }
        field(7; "AL Life Snapshot"; Blob) { }
    }
    keys { key(PK; "Generation No.") { Clustered = true; } }
}
