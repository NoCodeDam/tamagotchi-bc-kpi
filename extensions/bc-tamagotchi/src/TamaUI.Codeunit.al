codeunit 61209 "Tama User Interface"
{
    var
        SetupLbl: Label 'Setup';
        EnableSoundLbl: Label 'Enable sound';
        SoundOnLbl: Label 'Sound on';
        UpdateFailedLbl: Label 'Tamagotchi could not be updated.';
        SetupFailedLbl: Label 'Setup could not be opened.';
        OpeningLbl: Label 'Opening the company''s Tamagotchi …';
        ActiveLbl: Label 'active';
        ShellLabelLbl: Label 'Cabinet:';
        ShellDecorativeLbl: Label 'The three buttons are decorative.';
        LcdLbl: Label 'P1 pet LCD';
        EggLbl: Label 'egg';
        MealLbl: Label 'Food';
        HappyLbl: Label 'Happiness';
        WeightLbl: Label 'Weight';
        CleanlinessLbl: Label 'Cleanliness';
        CatchingUpLbl: Label 'Catching up on time while the Role Center was closed …';
        BusyLbl: Label 'The pet is being cared for …';
        CareHintLbl: Label 'Care for the pet by working in BC.';
        Icon0Lbl: Label 'Food';
        Icon1Lbl: Label 'Light';
        Icon2Lbl: Label 'Play';
        Icon3Lbl: Label 'Medicine';
        Icon4Lbl: Label 'Cleaning';
        Icon5Lbl: Label 'Status';
        Icon6Lbl: Label 'Discipline';
        Icon7Lbl: Label 'Attention';
        Shell0Lbl: Label 'Purple / pink';
        Shell1Lbl: Label 'Blue / yellow';
        Shell2Lbl: Label 'Pink / yellow';
        Shell3Lbl: Label 'White / black';
        Shell4Lbl: Label 'Blue / silver';
        Shell5Lbl: Label 'Rainbow';
        Shell6Lbl: Label 'Red glitter';
        Shell7Lbl: Label 'Mermaid';
        Result0Lbl: Label 'The pet is an egg or has died; no care was performed.';
        Result1Lbl: Label 'The original program is busy; the menu could not be closed.';
        Result2Lbl: Label 'The original clock could not be closed.';
        Result3Lbl: Label 'The original program did not accept the menu selection (sleep, animation or end of life).';
        Result4Lbl: Label 'Care was attempted, but the original program remained busy.';
        Result5Lbl: Label 'The menu could not be closed to set the clock.';
        Result6Lbl: Label 'The original clock setting did not accept the hours.';
        Result7Lbl: Label 'The original clock setting did not accept the minutes.';
        Result8Lbl: Label 'The event belongs to an earlier egg.';
        RefusedLbl: Label 'The pet refused the care action (egg, sleep, illness, full meter or death).';
        DeadLbl: Label 'The pet has died. Start a new egg in Setup when you are ready.';
        SleepingLbl: Label 'The pet is sleeping.';
        SickLbl: Label 'The pet is sick and needs medicine.';
        Result9Lbl: Label 'Care interrupted by an explicit new egg.';
        CompletedLbl: Label '%1: P1 care action completed.', Comment = '%1 is the translated care action caption.';
        FoodFullLbl: Label 'Food is already full; no meal was needed.';
        HappyFullLbl: Label 'Happiness is already full; no snack was needed.';
        CleanLbl: Label 'Already clean; there were no droppings to remove.';
        HealthyLbl: Label 'The pet is healthy; no medicine was needed.';
        NoCallLbl: Label 'No discipline call was pending.';
        AsleepResultLbl: Label 'The pet is asleep; this care action must wait.';
        SickResultLbl: Label 'The pet needs medicine before it can eat or play.';
        EggResultLbl: Label 'The egg has not hatched; care must wait.';
        DeadResultLbl: Label 'The pet has died; care cannot revive it.';

    procedure AddToFrame(var Frame: JsonObject)
    var Texts: JsonObject;
    begin
        Texts.Add('dead', DeadLbl);
        Texts.Add('sleeping', SleepingLbl);
        Texts.Add('sick', SickLbl);
        Texts.Add('setup', SetupLbl);
        Texts.Add('enableSound', EnableSoundLbl);
        Texts.Add('soundOn', SoundOnLbl);
        Texts.Add('updateFailed', UpdateFailedLbl);
        Texts.Add('setupFailed', SetupFailedLbl);
        Texts.Add('opening', OpeningLbl);
        Texts.Add('active', ActiveLbl);
        Texts.Add('shellLabel', ShellLabelLbl);
        Texts.Add('shellDecorative', ShellDecorativeLbl);
        Texts.Add('lcd', LcdLbl);
        Texts.Add('egg', EggLbl);
        Texts.Add('meal', MealLbl);
        Texts.Add('happy', HappyLbl);
        Texts.Add('weight', WeightLbl);
        Texts.Add('cleanliness', CleanlinessLbl);
        Texts.Add('catchingUp', CatchingUpLbl);
        Texts.Add('busy', BusyLbl);
        Texts.Add('careHint', CareHintLbl);
        Texts.Add('icon0', Icon0Lbl);
        Texts.Add('icon1', Icon1Lbl);
        Texts.Add('icon2', Icon2Lbl);
        Texts.Add('icon3', Icon3Lbl);
        Texts.Add('icon4', Icon4Lbl);
        Texts.Add('icon5', Icon5Lbl);
        Texts.Add('icon6', Icon6Lbl);
        Texts.Add('icon7', Icon7Lbl);
        Texts.Add('shell0', Shell0Lbl);
        Texts.Add('shell1', Shell1Lbl);
        Texts.Add('shell2', Shell2Lbl);
        Texts.Add('shell3', Shell3Lbl);
        Texts.Add('shell4', Shell4Lbl);
        Texts.Add('shell5', Shell5Lbl);
        Texts.Add('shell6', Shell6Lbl);
        Texts.Add('shell7', Shell7Lbl);
        Frame.Add('ui', Texts);
        Frame.Add('language', GlobalLanguage());
    end;

    procedure DisplayResult(Value: Text): Text
    var CareNo: Integer; Care: Enum "Tama Care"; Prefix: Text; At: Integer;
    begin
        // Persist stable keys, translate on reading. A shared pet and event log
        // never acquire the language of whichever user last advanced the CPU.
        case Value of
            'care.food_full': exit(FoodFullLbl);
            'care.happy_full': exit(HappyFullLbl);
            'care.clean': exit(CleanLbl);
            'care.healthy': exit(HealthyLbl);
            'care.no_call': exit(NoCallLbl);
            'care.asleep': exit(AsleepResultLbl);
            'care.sick': exit(SickResultLbl);
            'care.egg': exit(EggResultLbl);
            'care.dead': exit(DeadResultLbl);
            'care.refused': exit(RefusedLbl);
            'care.unborn', 'Originalen er et æg eller er død; ingen pasning udført.': exit(Result0Lbl);
            'care.busy', 'Originalen er optaget; kunne ikke afslutte menuen.': exit(Result1Lbl);
            'care.clock_exit', 'Kunne ikke forlade originalens ur.': exit(Result2Lbl);
            'care.menu_rejected', 'Originalen accepterede ikke menuvalget (søvn, animation eller afsluttet liv).': exit(Result3Lbl);
            'care.still_busy', 'Pasningen blev forsøgt, men originalen forblev optaget.': exit(Result4Lbl);
            'care.clock_menu_exit', 'Kunne ikke forlade menuen for at indstille uret.': exit(Result5Lbl);
            'care.hours_rejected', 'Originalens urindstilling accepterede ikke timerne.': exit(Result6Lbl);
            'care.minutes_rejected', 'Originalens urindstilling accepterede ikke minutterne.': exit(Result7Lbl);
            'event.previous_life', 'Hændelsen tilhører et tidligere æg.': exit(Result8Lbl);
            'care.reset', 'Pasning afbrudt ved eksplicit nyt æg.': exit(Result9Lbl);
        end;
        if CopyStr(Value, 1, 15) = 'care.completed:' then
            if Evaluate(CareNo, CopyStr(Value, 16)) then
                if (CareNo >= 0) and (CareNo <= 8) then begin
                    Care := "Tama Care".FromInteger(CareNo);
                    exit(StrSubstNo(CompletedLbl, Format(Care)));
                end;
        // Read historic Danish result text from 0.1.0/0.1.1 without rewriting it.
        At := StrPos(Value, ': originalens handling gennemført.');
        if At > 0 then begin
            Prefix := CopyStr(Value, 1, At - 1);
            case Prefix of
                'Indstil originalens ur', 'Set original clock': Care := Care::InitializeClock;
                'Mad', 'Meal': Care := Care::Meal;
                'Rengøring', 'Cleaning': Care := Care::Clean;
                'Leg', 'Play': Care := Care::Play;
                'Medicin', 'Medicine': Care := Care::Medicine;
                'Disciplin', 'Discipline': Care := Care::Discipline;
                'Lys til', 'Light on': Care := Care::LightOn;
                'Lys fra', 'Light off': Care := Care::LightOff;
                'Snack': Care := Care::Snack;
                else exit(Value);
            end;
            exit(StrSubstNo(CompletedLbl, Format(Care)));
        end;
        exit(Value);
    end;
}
