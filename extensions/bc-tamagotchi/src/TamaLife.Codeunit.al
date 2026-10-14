// Own AL recreation of documented P1 mechanisms, not Bandai source code.
codeunit 61212 "Tama AL Life"
{
    var
        Rules: Codeunit "Tama P1 Rules";
        Epoch: DateTime;
        CharacterId: Integer;
        Minutes: Integer;
        DeathMinute: Integer;
        Hunger: Integer;
        Happy: Integer;
        Weight: Integer;
        Discipline: Integer;
        Poop: Integer;
        Age: Integer;
        StageAwake: Integer;
        HungerElapsed: Integer;
        HappyElapsed: Integer;
        PoopLeft: Integer;
        SickLeft: Integer;
        SickTime: Integer;
        SickCount: Integer;
        MedicineGiven: Integer;
        CareMisses: Integer;
        DisciplineMisses: Integer;
        AdultMisses: Integer;
        HungerCall: Integer;
        HappyCall: Integer;
        LightCall: Integer;
        DisciplineCall: Integer;
        HeartDrops: Integer;
        ZeroMinutes: Integer;
        HealthyAgeSteps: Integer;
        RandomState: Integer;
        StageStartedMinute: Integer;
        BaseHunger: Integer;
        BaseHappy: Integer;
        SickInterval: Integer;
        EvolutionInterval: Integer;
        MinWeight: Integer;
        Shots: Integer;
        WakeHour: Integer;
        BedHour: Integer;
        CallEvery: Integer;
        ClockOrigin: Integer;
        ClockBaseMinute: Integer;
        Sleeping: Boolean;
        Sick: Boolean;
        LightsOn: Boolean;
        SecretAllowed: Boolean;
        TypeTwo: Boolean;
        Successful: Boolean;
        UsingBCClock: Boolean;
        BCTimeZone: Text[250];

    procedure Initialize(AtTime: DateTime; Hour: Integer; Minute: Integer)
    begin
        ClearAll();
        Epoch := AtTime;
        ClockOrigin := Hour * 60 + Minute;
        Hunger := 4; Happy := 4; LightsOn := true; RandomState := 173;
        Configure(0);
    end;

    procedure AdvanceTo(AtTime: DateTime)
    var TargetMinute: Integer; Elapsed: Duration;
    begin
        if AtTime <= Epoch then exit;
        Elapsed := AtTime - Epoch;
        // Date/time is authoritative. Polling never increments time itself.
        TargetMinute := Elapsed div 60000;
        if TargetMinute <= Minutes then exit;
        while (Minutes < TargetMinute) and (CharacterId <> 12) do
            MinuteCore();
        if CharacterId = 12 then Minutes := TargetMinute;
        SyncBCClock();
    end;

    procedure ApplyCare(Care: Enum "Tama Care"; Hour: Integer; Minute: Integer): Boolean
    begin
        if Care = Care::InitializeClock then begin
            ClockOrigin := Hour * 60 + Minute;
            ClockBaseMinute := Minutes;
            exit(true);
        end;
        CareCore(Care.AsInteger());
        exit(Successful);
    end;

    procedure IsDead(): Boolean begin exit(CharacterId = 12); end;
    procedure UseBCClock(TimeZoneId: Text)
    begin
        UsingBCClock := true;
        BCTimeZone := CopyStr(TimeZoneId, 1, 250);
        if BCTimeZone = '' then BCTimeZone := 'UTC';
        SyncBCClock();
    end;

    local procedure SyncBCClock()
    var Zone: Codeunit "Time Zone"; AtTime: DateTime; Milliseconds: BigInteger;
        XmlTime: Text; Hour, Minute, OffsetMinutes: Integer;
    begin
        if not UsingBCClock then exit;
        Milliseconds := Minutes; AtTime := Epoch + Milliseconds * 60000;
        // XML formatting is UTC and never adopts the current viewer's zone.
        XmlTime := Format(AtTime, 0, 9);
        Evaluate(Hour, CopyStr(XmlTime, 12, 2)); Evaluate(Minute, CopyStr(XmlTime, 15, 2));
        OffsetMinutes := Zone.GetTimezoneOffset(AtTime, BCTimeZone) div 60000;
        ClockOrigin := ((Hour * 60 + Minute + OffsetMinutes) mod 1440 + 1440) mod 1440;
        ClockBaseMinute := Minutes;
    end;

    procedure IllMinutes(): Integer begin exit(SickTime); end;
    procedure DosesRemaining(): Integer begin exit(Max(0, Shots - MedicineGiven)); end;

    procedure RefusalKey(Care: Enum "Tama Care"): Text
    begin
        if IsDead() then exit('care.dead');
        if CharacterId = 0 then exit('care.egg');
        if (Care = Care::Clean) and (Poop = 0) then exit('care.clean');
        if Sleeping then exit('care.asleep');
        if Sick and (Care <> Care::Medicine) then exit('care.sick');
        if (Care = Care::Meal) and (Hunger >= 4) then exit('care.food_full');
        if (Care = Care::Snack) and (Happy >= 4) then exit('care.happy_full');
        if (Care = Care::Medicine) and not Sick then exit('care.healthy');
        if (Care = Care::Discipline) and (DisciplineCall = 0) then exit('care.no_call');
        exit('care.refused');
    end;
    procedure DiedAt(): DateTime
    var Milliseconds: BigInteger;
    begin if DeathMinute = 0 then exit(0DT); Milliseconds := DeathMinute; exit(Epoch + Milliseconds * 60000); end;
    procedure Character(): Integer begin exit(CharacterId); end;
    procedure Food(): Integer begin exit(Hunger); end;
    procedure Happiness(): Integer begin exit(Happy); end;
    procedure GetWeight(): Integer begin exit(Weight); end;
    procedure GetDiscipline(): Integer begin exit(Discipline); end;
    procedure GetPoop(): Integer begin exit(Poop); end;
    procedure IsSleeping(): Boolean begin exit(Sleeping); end;
    procedure IsSick(): Boolean begin exit(Sick); end;
    procedure IsLightOn(): Boolean begin exit(LightsOn); end;
    procedure NeedsDiscipline(): Boolean begin exit(DisciplineCall > 0); end;
    procedure ClockMinute(): Integer begin exit(((Minutes - ClockBaseMinute + ClockOrigin) mod 1440 + 1440) mod 1440); end;

    // The minute/care procedures deliberately use a small AL subset so local
    // tests evaluate this exact reviewed AL, not a separately written model.
    local procedure MinuteCore()
    begin
        Minutes := Minutes + 1;
        SyncBCClock();
        if CharacterId = 0 then begin
            if Minutes >= 5 then begin
                Configure(1);
            end;
        end else begin
            if CharacterId <> 12 then begin
                SetSleep();
                if Sleeping then begin
                    if LightsOn then begin
                        if LightCall > 0 then begin
                            LightCall := LightCall - 1;
                            if LightCall = 0 then begin
                                CareMiss();
                            end;
                        end;
                    end;
                end else begin
                    HungerElapsed := HungerElapsed + 1;
                    HappyElapsed := HappyElapsed + 1;
                    if HungerCall > 0 then begin
                        HungerCall := HungerCall - 1;
                        if HungerCall = 0 then begin
                            CareMiss();
                        end;
                    end;
                    if HappyCall > 0 then begin
                        HappyCall := HappyCall - 1;
                        if HappyCall = 0 then begin
                            CareMiss();
                        end;
                    end;
                    if HungerElapsed >= BaseHunger then begin
                        HungerElapsed := HungerElapsed - BaseHunger;
                        if Hunger > 0 then begin Hunger := Hunger - 1; end;
                        if Hunger = 0 then begin HungerCall := 15; end;
                        HeartDrop();
                    end;
                    if HappyElapsed >= BaseHappy then begin
                        HappyElapsed := HappyElapsed - BaseHappy;
                        if Happy > 0 then begin Happy := Happy - 1; end;
                        if Happy = 0 then begin HappyCall := 15; end;
                        HeartDrop();
                    end;
                    if DisciplineCall > 0 then begin
                        DisciplineCall := DisciplineCall - 1;
                        if DisciplineCall = 0 then begin
                            DisciplineMisses := DisciplineMisses + 1;
                        end;
                    end;
                    PoopLeft := PoopLeft - 1;
                    if PoopLeft <= 0 then begin
                        Poop := Min(4, Poop + 1);
                        if CharacterId = 1 then begin PoopLeft := 25; end else begin PoopLeft := 180; end;
                        if Poop >= 4 then begin StartSick(); end;
                    end;
                    if (Hunger = 0) or (Happy = 0) then begin
                        ZeroMinutes := ZeroMinutes + 1;
                    end else begin
                        ZeroMinutes := 0;
                    end;
                    if Sick then begin
                        SickTime := SickTime + 1;
                    end else begin
                        StageAwake := StageAwake + 1;
                        SickLeft := SickLeft - 1;
                        if SickLeft <= 0 then begin StartSick(); end;
                    end;
                    // These two safety thresholds are recreation choices,
                    // not asserted to be the vintage ROM's exact death tests.
                    if (ZeroMinutes >= 360) or (SickTime >= 1440) then begin
                        Kill();
                    end;
                    CheckEvolution();
                end;
            end;
        end;
    end;

    local procedure CareCore(Action: Integer)
    begin
        Successful := false;
        if (CharacterId > 0) and (CharacterId < 12) then begin
            if Action = 2 then begin
                if Poop > 0 then begin Poop := 0; Successful := true; end;
            end;
            if Action = 6 then begin LightsOn := true; Successful := true; end;
            if Action = 7 then begin LightsOn := false; LightCall := 0; Successful := true; end;
            if not Sleeping then begin
                if Action = 4 then begin
                    if Sick then begin
                        MedicineGiven := MedicineGiven + 1;
                        Successful := true;
                        if MedicineGiven >= Shots then begin
                            Sick := false; SickTime := 0; MedicineGiven := 0; SickLeft := SickInterval;
                        end;
                    end;
                end;
                if not Sick then begin
                    if Action = 1 then begin
                        if Hunger < 4 then begin
                            Hunger := Hunger + 1; Weight := Min(99, Weight + 1); HungerCall := 0; Successful := true;
                        end;
                    end;
                    if Action = 8 then begin
                        if Happy < 4 then begin
                            Happy := Happy + 1; Weight := Min(99, Weight + 2); HappyCall := 0; Successful := true;
                        end;
                    end;
                    if Action = 3 then begin
                        PlayGame();
                        Successful := true;
                    end;
                    if Action = 5 then begin
                        if DisciplineCall > 0 then begin
                            Discipline := Min(100, Discipline + 25); DisciplineCall := 0; Successful := true;
                        end;
                    end;
                    if CharacterId = 1 then begin Weight := 5; end;
                    if (Hunger > 0) and (Happy > 0) then begin ZeroMinutes := 0; end;
                end;
            end;
        end;
    end;

    local procedure CareMiss()
    begin
        if CharacterId < 5 then begin
            CareMisses := Min(15, CareMisses + 1);
        end else begin
            AdultMisses := AdultMisses + 1;
            if AdultMisses >= 5 then begin Kill(); end;
        end;
    end;

    local procedure HeartDrop()
    begin
        HeartDrops := HeartDrops + 1;
        if CallEvery > 0 then begin
            if (HeartDrops mod CallEvery = 0) and (Discipline < 100) then begin
                DisciplineCall := 15;
            end;
        end;
    end;

    local procedure StartSick()
    begin
        if not Sick then begin
            Sick := true; SickTime := 0; MedicineGiven := 0; SickCount := SickCount + 1;
            if (SickCount >= 3) and (CharacterId > 1) then begin Kill(); end;
        end;
    end;

    local procedure Kill()
    begin
        if CharacterId <> 12 then begin
            CharacterId := 12; DeathMinute := Minutes; Sleeping := false;
        end;
    end;

    local procedure SetSleep()
    var WasSleeping: Boolean; Hour: Integer;
    begin
        WasSleeping := Sleeping;
        Hour := ClockMinute() div 60;
        if CharacterId = 1 then Sleeping := (Minutes - StageStartedMinute >= 40) and (Minutes - StageStartedMinute < 45)
        else Sleeping := (Hour >= BedHour) or (Hour < WakeHour);
        if Sleeping and not WasSleeping then LightCall := 15;
        if not Sleeping and WasSleeping then begin
            Age += 1;
            LightsOn := true;
            LightCall := 0;
            if (CharacterId >= 5) and (SickCount > 0) then begin
                HealthyAgeSteps := Min(11, HealthyAgeSteps + 1);
                BaseHunger := Rules.AgedInterval(CharacterId, HealthyAgeSteps, false);
                BaseHappy := Rules.AgedInterval(CharacterId, HealthyAgeSteps, true);
            end;
        end;
    end;

    local procedure CheckEvolution()
    begin
        if (CharacterId > 0) and (CharacterId < 5) and (StageAwake >= EvolutionInterval) then begin
            if CharacterId = 1 then Configure(2)
            else if CharacterId = 2 then begin
                TypeTwo := DisciplineMisses >= 3;
                Configure(Rules.Teen(CareMisses));
                if not TypeTwo then Discipline := 50;
            end else begin
                SecretAllowed := (CharacterId = 3) and TypeTwo and (CareMisses < 4) and (DisciplineMisses >= 2);
                Configure(Rules.Adult(CharacterId, TypeTwo, CareMisses, DisciplineMisses));
            end;
        end;
        if (CharacterId = 7) and SecretAllowed and (StageAwake >= EvolutionInterval) then Configure(11);
    end;

    local procedure Configure(NewId: Integer)
    begin
        CharacterId := NewId;
        Rules.Stats(CharacterId, BaseHunger, BaseHappy, SickInterval, EvolutionInterval, MinWeight, Shots, WakeHour, BedHour, Discipline, CallEvery);
        Weight := Max(Weight, MinWeight);
        StageAwake := 0; StageStartedMinute := Minutes; HungerElapsed := 0; HappyElapsed := 0;
        SickLeft := SickInterval; SickCount := 0; Sick := false; SickTime := 0; MedicineGiven := 0;
        HungerCall := 0; HappyCall := 0; DisciplineCall := 0; HeartDrops := 0; PoopLeft := 15;
        HealthyAgeSteps := 0; AdultMisses := 0;
    end;

    local procedure PlayGame()
    var Index, Wins, Threshold: Integer;
    begin
        Threshold := 8;
        if CharacterId = 7 then Threshold := 5;
        if CharacterId = 8 then Threshold := 11;
        for Index := 1 to 5 do begin
            RandomState := (RandomState * 25173 + 13849) mod 32749;
            if RandomState mod 16 < Threshold then Wins += 1;
        end;
        if Wins >= 3 then begin Happy := Min(4, Happy + 1); HappyCall := 0; end;
        Weight := Max(MinWeight, Weight - 1);
    end;

    local procedure Min(A: Integer; B: Integer): Integer begin if A < B then exit(A); exit(B); end;
    local procedure Max(A: Integer; B: Integer): Integer begin if A > B then exit(A); exit(B); end;

    procedure ExportState(): Text
    var State: JsonObject; Value: Text;
    begin
        State.Add('version', 1);
        State.Add('UsingBCClock', UsingBCClock); State.Add('BCTimeZone', BCTimeZone);
        State.Add('epoch', Epoch);
        State.Add('CharacterId', CharacterId);
        State.Add('Minutes', Minutes);
        State.Add('DeathMinute', DeathMinute);
        State.Add('Hunger', Hunger);
        State.Add('Happy', Happy);
        State.Add('Weight', Weight);
        State.Add('Discipline', Discipline);
        State.Add('Poop', Poop);
        State.Add('Age', Age);
        State.Add('StageAwake', StageAwake);
        State.Add('HungerElapsed', HungerElapsed);
        State.Add('HappyElapsed', HappyElapsed);
        State.Add('PoopLeft', PoopLeft);
        State.Add('SickLeft', SickLeft);
        State.Add('SickTime', SickTime);
        State.Add('SickCount', SickCount);
        State.Add('MedicineGiven', MedicineGiven);
        State.Add('CareMisses', CareMisses);
        State.Add('DisciplineMisses', DisciplineMisses);
        State.Add('AdultMisses', AdultMisses);
        State.Add('HungerCall', HungerCall);
        State.Add('HappyCall', HappyCall);
        State.Add('LightCall', LightCall);
        State.Add('DisciplineCall', DisciplineCall);
        State.Add('HeartDrops', HeartDrops);
        State.Add('ZeroMinutes', ZeroMinutes);
        State.Add('HealthyAgeSteps', HealthyAgeSteps);
        State.Add('RandomState', RandomState);
        State.Add('StageStartedMinute', StageStartedMinute);
        State.Add('BaseHunger', BaseHunger);
        State.Add('BaseHappy', BaseHappy);
        State.Add('SickInterval', SickInterval);
        State.Add('EvolutionInterval', EvolutionInterval);
        State.Add('MinWeight', MinWeight);
        State.Add('Shots', Shots);
        State.Add('WakeHour', WakeHour);
        State.Add('BedHour', BedHour);
        State.Add('CallEvery', CallEvery);
        State.Add('ClockOrigin', ClockOrigin);
        State.Add('ClockBaseMinute', ClockBaseMinute);
        State.Add('Sleeping', Sleeping);
        State.Add('Sick', Sick);
        State.Add('LightsOn', LightsOn);
        State.Add('SecretAllowed', SecretAllowed);
        State.Add('TypeTwo', TypeTwo);
        State.Add('Successful', Successful);

        State.WriteTo(Value);
        exit(Value);
    end;

    procedure ImportState(Value: Text)
    var State: JsonObject; Token: JsonToken;
    begin
        if not State.ReadFrom(Value) then Error('Invalid AL life snapshot.');
        State.Get('version', Token); if Token.AsValue().AsInteger() <> 1 then Error('Unsupported AL life snapshot version.');
        State.Get('epoch', Token); Epoch := Token.AsValue().AsDateTime();
        // Additive snapshot keys: old version-one snapshots still load intact.
        UsingBCClock := false; BCTimeZone := '';
        if State.Get('UsingBCClock', Token) then UsingBCClock := Token.AsValue().AsBoolean();
        if State.Get('BCTimeZone', Token) then BCTimeZone := CopyStr(Token.AsValue().AsText(), 1, 250);
        State.Get('CharacterId', Token); CharacterId := Token.AsValue().AsInteger();
        State.Get('Minutes', Token); Minutes := Token.AsValue().AsInteger();
        State.Get('DeathMinute', Token); DeathMinute := Token.AsValue().AsInteger();
        State.Get('Hunger', Token); Hunger := Token.AsValue().AsInteger();
        State.Get('Happy', Token); Happy := Token.AsValue().AsInteger();
        State.Get('Weight', Token); Weight := Token.AsValue().AsInteger();
        State.Get('Discipline', Token); Discipline := Token.AsValue().AsInteger();
        State.Get('Poop', Token); Poop := Token.AsValue().AsInteger();
        State.Get('Age', Token); Age := Token.AsValue().AsInteger();
        State.Get('StageAwake', Token); StageAwake := Token.AsValue().AsInteger();
        State.Get('HungerElapsed', Token); HungerElapsed := Token.AsValue().AsInteger();
        State.Get('HappyElapsed', Token); HappyElapsed := Token.AsValue().AsInteger();
        State.Get('PoopLeft', Token); PoopLeft := Token.AsValue().AsInteger();
        State.Get('SickLeft', Token); SickLeft := Token.AsValue().AsInteger();
        State.Get('SickTime', Token); SickTime := Token.AsValue().AsInteger();
        State.Get('SickCount', Token); SickCount := Token.AsValue().AsInteger();
        State.Get('MedicineGiven', Token); MedicineGiven := Token.AsValue().AsInteger();
        State.Get('CareMisses', Token); CareMisses := Token.AsValue().AsInteger();
        State.Get('DisciplineMisses', Token); DisciplineMisses := Token.AsValue().AsInteger();
        State.Get('AdultMisses', Token); AdultMisses := Token.AsValue().AsInteger();
        State.Get('HungerCall', Token); HungerCall := Token.AsValue().AsInteger();
        State.Get('HappyCall', Token); HappyCall := Token.AsValue().AsInteger();
        State.Get('LightCall', Token); LightCall := Token.AsValue().AsInteger();
        State.Get('DisciplineCall', Token); DisciplineCall := Token.AsValue().AsInteger();
        State.Get('HeartDrops', Token); HeartDrops := Token.AsValue().AsInteger();
        State.Get('ZeroMinutes', Token); ZeroMinutes := Token.AsValue().AsInteger();
        State.Get('HealthyAgeSteps', Token); HealthyAgeSteps := Token.AsValue().AsInteger();
        State.Get('RandomState', Token); RandomState := Token.AsValue().AsInteger();
        State.Get('StageStartedMinute', Token); StageStartedMinute := Token.AsValue().AsInteger();
        State.Get('BaseHunger', Token); BaseHunger := Token.AsValue().AsInteger();
        State.Get('BaseHappy', Token); BaseHappy := Token.AsValue().AsInteger();
        State.Get('SickInterval', Token); SickInterval := Token.AsValue().AsInteger();
        State.Get('EvolutionInterval', Token); EvolutionInterval := Token.AsValue().AsInteger();
        State.Get('MinWeight', Token); MinWeight := Token.AsValue().AsInteger();
        State.Get('Shots', Token); Shots := Token.AsValue().AsInteger();
        State.Get('WakeHour', Token); WakeHour := Token.AsValue().AsInteger();
        State.Get('BedHour', Token); BedHour := Token.AsValue().AsInteger();
        State.Get('CallEvery', Token); CallEvery := Token.AsValue().AsInteger();
        State.Get('ClockOrigin', Token); ClockOrigin := Token.AsValue().AsInteger();
        State.Get('ClockBaseMinute', Token); ClockBaseMinute := Token.AsValue().AsInteger();
        State.Get('Sleeping', Token); Sleeping := Token.AsValue().AsBoolean();
        State.Get('Sick', Token); Sick := Token.AsValue().AsBoolean();
        State.Get('LightsOn', Token); LightsOn := Token.AsValue().AsBoolean();
        State.Get('SecretAllowed', Token); SecretAllowed := Token.AsValue().AsBoolean();
        State.Get('TypeTwo', Token); TypeTwo := Token.AsValue().AsBoolean();
        State.Get('Successful', Token); Successful := Token.AsValue().AsBoolean();

        if (CharacterId < 0) or (CharacterId > 12) or (Hunger < 0) or (Hunger > 4) or (Happy < 0) or (Happy > 4) or (Minutes < 0) or (Epoch = 0DT) then Error('Invalid AL life values.');
    end;
}
