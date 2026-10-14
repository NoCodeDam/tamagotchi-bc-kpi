page 61200 "Tama Setup"
{
    Caption = 'Tamagotchi Setup';
    PageType = Card;
    SourceTable = "Tama Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(CompanyPet)
            {
                Caption = 'Company Tamagotchi';
                field(Enabled; Rec.Enabled) { ApplicationArea = All; ToolTip = 'Collect the selected BC care events. The pet continues to age in the background even when this is disabled.'; }
                field(Generation; Rec."Generation No.") { ApplicationArea = All; ToolTip = 'The current egg. All users in the company care for the same pet.'; }
            }
            group(OriginalDevice)
            {
                Caption = 'Device settings';
                field(BCTimeZone; Rec."BC Time Zone") { ApplicationArea = All; ToolTip = 'The shared clock uses BC time and the time zone captured when the company enables the pet. No manual hour or minute setting is needed.'; }
                field(PlaySound; Rec."Play Sound") { ApplicationArea = All; ToolTip = 'Allow attention sounds in the Role Center. Your browser may require a click before playing sound.'; }
            }
            group(Appearance)
            {
                Caption = 'Appearance';
                field(ShellDesign; Rec."Shell Design")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a cabinet for the Role Center. Colours and the three decorative buttons only change the appearance; all cabinets use the same P1 program and the same pet.';
                }
            }
            group(CareEvents)
            {
                Caption = 'BC events replace the care buttons';
                field(MealEvent; Rec."Meal Event") { ApplicationArea = All; ToolTip = 'The selected BC event gives one meal through the pet menu.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(MealPublisher; MealPublisher) { ApplicationArea = All; Caption = 'Standard event: meal'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(CleanEvent; Rec."Clean Event") { ApplicationArea = All; ToolTip = 'The selected BC event triggers the cleaning action.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(CleanPublisher; CleanPublisher) { ApplicationArea = All; Caption = 'Standard event: cleaning'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(PlayEvent; Rec."Play Event") { ApplicationArea = All; ToolTip = 'The selected BC event plays the five-round left/right guessing game. The pet determines the result.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(PlayPublisher; PlayPublisher) { ApplicationArea = All; Caption = 'Standard event: play'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(MedicineEvent; Rec."Medicine Event") { ApplicationArea = All; ToolTip = 'The selected BC event gives one dose of medicine. The pet may need several doses.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(MedicinePublisher; MedicinePublisher) { ApplicationArea = All; Caption = 'Standard event: medicine'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(DisciplineEvent; Rec."Discipline Event") { ApplicationArea = All; ToolTip = 'The selected BC event uses the discipline function.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(DisciplinePublisher; DisciplinePublisher) { ApplicationArea = All; Caption = 'Standard event: discipline'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(LightOnEvent; Rec."Light On Event") { ApplicationArea = All; ToolTip = 'The selected BC event turns the light on.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(LightOnPublisher; LightOnPublisher) { ApplicationArea = All; Caption = 'Standard event: light on'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(LightOffEvent; Rec."Light Off Event") { ApplicationArea = All; ToolTip = 'The selected BC event turns the light off.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(LightOffPublisher; LightOffPublisher) { ApplicationArea = All; Caption = 'Standard event: light off'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
                field(SnackEvent; Rec."Snack Event") { ApplicationArea = All; ToolTip = 'The selected BC event gives one snack, affecting happiness and weight.'; trigger OnValidate() begin RefreshPublishers(); end; }
                field(SnackPublisher; SnackPublisher) { ApplicationArea = All; Caption = 'Standard event: snack'; Editable = false; ToolTip = 'The AL event subscribed to by the extension.'; }
            }
            group(BackgroundLife)
            {
                Caption = 'Background life';
                field(JobStatus; JobStatusText) { ApplicationArea = All; Caption = 'Job status'; Editable = false; ToolTip = 'BC updates the pet through the recurring job, even when nobody is online.'; }
                field(LastBackground; LastBackgroundTime) { ApplicationArea = All; Caption = 'Last background update'; Editable = false; ToolTip = 'Last successful background update. Check Job Queue Entries if this stops advancing.'; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CreateLifeJob)
            {
                Caption = 'Create / restart background job'; ApplicationArea = All; Image = Start;
                Promoted = true; PromotedCategory = Process; PromotedIsBig = true;
                ToolTip = 'Create the company life job or restart the existing job. Installation and New egg do not create jobs. The pet is not reset.';
                trigger OnAction()
                begin CurrPage.SaveRecord(); Rec.CreateBackgroundJob(); RefreshBackground(); CurrPage.Update(false); end;
            }
            action(NewEgg)
            {
                Caption = 'New egg / reset';
                ApplicationArea = All;
                Image = New;
                ToolTip = 'Start a new egg in the company. The previous life and event log are preserved.';
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    if (Rec."Generation No." > 0) and not Confirm(UserMessage1Lbl, false) then exit;
                    SetupManagement.NewEgg();
                    Rec.Get('');
                    CurrPage.Update(false);
                end;
            }
            action(EventLog)
            {
                Caption = 'Care history';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "Tama Event Log";
                ToolTip = 'View the recorded BC events and the care actions attempted by the pet.';
            }
            action(ViewPet)
            {
                Caption = 'View Tamagotchi';
                ApplicationArea = All;
                Image = View;
                RunObject = page "Tama Pet Viewer";
                ToolTip = 'View the company''s Tamagotchi.';
            }
        }
    }
    var
        UserMessage1Lbl: Label 'Start a new egg and end the current life?';
        Jobs: Codeunit "Tama Background Life";
        JobStatusText: Text;
        LastBackgroundTime: DateTime;
        SetupManagement: Codeunit "Tama Setup Management";
        Events: Codeunit "Tama BC Events";
        MealPublisher, CleanPublisher, PlayPublisher, MedicinePublisher, DisciplinePublisher: Text;
        LightOnPublisher, LightOffPublisher, SnackPublisher: Text;
    trigger OnOpenPage()
    begin
        SetupManagement.EnsureSetup();
        Rec.Get('');
        if Rec."BC Time Zone" = '' then begin Rec.EnsureBCClock(); Rec.Modify(false); end;
        RefreshPublishers();
        RefreshBackground();
    end;
    local procedure RefreshBackground()
    var State: Record "Tama State";
    begin
        JobStatusText := Jobs.StatusText();
        if State.Get('') then LastBackgroundTime := State."Last Background UTC";
    end;
    local procedure RefreshPublishers()
    begin
        MealPublisher := Events.Publisher(Rec."Meal Event");
        CleanPublisher := Events.Publisher(Rec."Clean Event");
        PlayPublisher := Events.Publisher(Rec."Play Event");
        MedicinePublisher := Events.Publisher(Rec."Medicine Event");
        DisciplinePublisher := Events.Publisher(Rec."Discipline Event");
        LightOnPublisher := Events.Publisher(Rec."Light On Event");
        LightOffPublisher := Events.Publisher(Rec."Light Off Event");
        SnackPublisher := Events.Publisher(Rec."Snack Event");
    end;
}

page 61201 "Tama Event Log"
{
    Caption = 'Tamagotchi Care History';
    PageType = List;
    SourceTable = "Tama Event Queue";
    SourceTableView = sorting("Occurred UTC", "Sequence No.") order(descending);
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Events)
            {
                field(Occurred; Rec."Occurred UTC") { ApplicationArea = All; ToolTip = 'When the BC event was recorded.'; }
                field(BCEventName; Rec."BC Event") { ApplicationArea = All; ToolTip = 'The selected BC event.'; }
                field(Care; Rec.Care) { ApplicationArea = All; ToolTip = 'The care action triggered by the event.'; }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Pending, running, completed or skipped.'; }
                field(Result; ResultText) { ApplicationArea = All; Caption = 'Result'; ToolTip = 'How the pet handled the care attempt.'; }
                field(Generation; Rec."Generation No.") { ApplicationArea = All; ToolTip = 'The egg to which the event belongs.'; }
            }
        }
    }
    var
        UI: Codeunit "Tama User Interface";
        ResultText: Text;

    trigger OnAfterGetRecord()
    begin
        ResultText := UI.DisplayResult(Rec.Result);
    end;
}
