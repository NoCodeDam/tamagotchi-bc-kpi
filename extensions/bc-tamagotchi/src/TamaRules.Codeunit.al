// Own implementation using factual parameters documented by P1 ROM research.
// No original ROM, extracted instructions, Bandai sprites or downloaded code.
codeunit 61213 "Tama P1 Rules"
{
    // IDs match the documented P1 character order. 0=egg, 12=dead.
    procedure Stats(CharacterId: Integer; var HungerMinutes: Integer; var HappyMinutes: Integer; var SickMinutes: Integer; var EvolveMinutes: Integer; var MinWeight: Integer; var Shots: Integer; var WakeHour: Integer; var BedHour: Integer; var Discipline: Integer; var CallEvery: Integer)
    begin
        WakeHour := 9; BedHour := 22; Shots := 2; Discipline := 0; CallEvery := 7;
        case CharacterId of
            0: SetStats(0, 0, 0, 5, 0, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight);
            1: begin SetStats(3, 4, 45, 60, 5, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); WakeHour := -1; BedHour := -1; CallEvery := 0; end;
            2: begin SetStats(50, 60, 990, 1380, 10, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); BedHour := 20; CallEvery := 6; end;
            3: begin SetStats(75, 85, 1656, 2220, 20, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); BedHour := 21; CallEvery := 6; end;
            4: begin SetStats(75, 85, 660, 1380, 20, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); BedHour := 21; CallEvery := 6; end;
            5, 11: begin SetStats(81, 91, 3900, 4095, 30, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); Shots := 1; Discipline := 100; CallEvery := 0; end;
            6: begin SetStats(81, 91, 2808, 3120, 30, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); Shots := 1; Discipline := 50; end;
            7: begin SetStats(55, 65, 2592, 2880, 30, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); Shots := 1; WakeHour := 11; BedHour := 23; end;
            8: begin SetStats(60, 70, 1170, 1560, 20, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); Discipline := 100; CallEvery := 0; end;
            9: begin SetStats(60, 70, 360, 780, 10, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); Shots := 3; Discipline := 50; end;
            10: begin SetStats(45, 50, 660, 1440, 20, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight); WakeHour := 10; end;
            12: SetStats(0, 0, 0, 0, 0, HungerMinutes, HappyMinutes, SickMinutes, EvolveMinutes, MinWeight);
            else Error('Invalid AL pet character.');
        end;
    end;

    local procedure SetStats(H: Integer; P: Integer; S: Integer; E: Integer; W: Integer; var Hunger: Integer; var Happy: Integer; var Sick: Integer; var Evolve: Integer; var Weight: Integer)
    begin Hunger := H; Happy := P; Sick := S; Evolve := E; Weight := W; end;

    procedure AgedInterval(CharacterId: Integer; Steps: Integer; Happy: Boolean): Integer
    var Values: Text; Result: Integer;
    begin
        case CharacterId of
            5, 6, 11: if Happy then Values := '91,69,52,39,30,23,18,14,11,9,7,6' else Values := '81,61,46,35,27,21,16,12,9,7,6,5';
            7: if Happy then Values := '65,49,37,28,21,16,12,9,7,6,5,4' else Values := '55,42,32,24,18,14,11,9,7,6,5,4';
            8, 9: if Happy then Values := '70,53,40,30,23,18,14,11,9,7,6,5' else Values := '60,45,34,26,20,15,12,9,7,6,5,4';
            10: if Happy then Values := '50,38,29,22,17,13,10,8,6,5,4,3' else Values := '45,34,26,20,15,12,9,7,6,5,4,3';
            else Error('Invalid adult character.');
        end;
        if Steps < 0 then Steps := 0;
        if Steps > 11 then Steps := 11;
        Evaluate(Result, SelectStr(Steps + 1, Values));
        exit(Result);
    end;

    procedure Teen(CareMisses: Integer): Integer
    begin if CareMisses < 3 then exit(3); exit(4); end;

    procedure Adult(TeenId: Integer; TypeTwo: Boolean; CareMisses: Integer; DisciplineMisses: Integer): Integer
    begin
        if TeenId = 3 then begin
            if not TypeTwo then begin
                if CareMisses < 3 then begin
                    if DisciplineMisses = 0 then exit(5);
                    if DisciplineMisses = 1 then exit(6);
                    exit(7);
                end;
                if DisciplineMisses < 2 then exit(8);
                if DisciplineMisses < 4 then exit(9);
                exit(10);
            end;
            if CareMisses < 4 then begin if DisciplineMisses < 2 then exit(6); exit(7); end;
            if DisciplineMisses < 8 then exit(9);
            exit(10);
        end;
        if not TypeTwo then begin
            if DisciplineMisses < 2 then exit(8);
            if DisciplineMisses = 2 then exit(9);
            exit(10);
        end;
        if DisciplineMisses < 6 then exit(9);
        exit(10);
    end;
}
