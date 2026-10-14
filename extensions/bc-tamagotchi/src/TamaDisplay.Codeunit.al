// Own fixed-size pixel drawings. These are not sprites extracted from a ROM.
codeunit 61214 "Tama AL Display"
{
    var Pixels: array[512] of Boolean;

    procedure Frame(var Life: Codeunit "Tama AL Life"; AtTime: DateTime): JsonObject
    var Result: JsonObject; Matrix, Icons, Sounds: JsonArray; Index, Bob, CharacterId, Frequency, Second: Integer; Attention: Boolean; Bitmap: Text;
    begin
        Clear(Pixels);
        CharacterId := Life.Character();
        Bob := ((AtTime - CreateDateTime(DT2Date(AtTime), 000000T)) div 1000) mod 2;
        Bitmap := Sprite(CharacterId);
        Paint(Bitmap, 8 + Bob, 1);
        if Life.IsSleeping() then Paint('###|..#|.#.|#..|###', 26, 1);
        if Life.IsSick() and not Life.IsDead() then Paint('.#.|###|.#.', 1, 1);
        if (Life.GetPoop() > 0) and not Life.IsDead() then Paint('.#.|###|###', 27, 12);
        if (not Life.IsLightOn()) and (CharacterId <> 12) then begin
            Clear(Pixels);
            if Life.IsSleeping() then Paint('###|..#|.#.|#..|###', 26, 1);
        end;
        Attention := (Life.Food() = 0) or (Life.Happiness() = 0) or Life.IsSick() or Life.NeedsDiscipline() or (Life.IsSleeping() and Life.IsLightOn());
        for Index := 1 to 512 do Matrix.Add(Pixels[Index]);
        Icons.Add((Life.Food() = 0) and not Life.IsDead());
        Icons.Add(Life.IsSleeping() and Life.IsLightOn());
        Icons.Add((Life.Happiness() = 0) and not Life.IsDead());
        Icons.Add(Life.IsSick() and not Life.IsDead());
        Icons.Add((Life.GetPoop() > 0) and not Life.IsDead());
        Icons.Add(false); Icons.Add(Life.NeedsDiscipline() and not Life.IsDead()); Icons.Add(Attention and not Life.IsDead());
        Result.Add('pixels', Matrix); Result.Add('icons', Icons);
        Second := ((AtTime - CreateDateTime(DT2Date(AtTime), 000000T)) div 1000) mod 60;
        if Attention and not Life.IsDead() and (Second = 0) then Frequency := 4096;
        Result.Add('frequency', Frequency); Result.Add('sounds', Sounds); Result.Add('ticks', 0); Result.Add('soundStartTick', 0);
        Result.Add('hunger', Life.Food()); Result.Add('happy', Life.Happiness()); Result.Add('weight', Life.GetWeight());
        Result.Add('discipline', Life.GetDiscipline()); Result.Add('poop', Life.GetPoop()); Result.Add('stage', CharacterId);
        Result.Add('asleep', Life.IsSleeping()); Result.Add('sick', Life.IsSick()); Result.Add('dead', Life.IsDead());
        Result.Add('clockHour', Life.ClockMinute() div 60); Result.Add('clockMinute', Life.ClockMinute() mod 60);
        Result.Add('diedAt', Life.DiedAt());
        exit(Result);
    end;

    local procedure Paint(Bitmap: Text; X: Integer; Y: Integer)
    var Index, Column, Row: Integer; Mark: Char;
    begin
        for Index := 1 to StrLen(Bitmap) do begin
            Mark := Bitmap[Index];
            if Mark = '|' then begin Row += 1; Column := 0; end
            else begin
                if (Mark = '#') and (X + Column >= 0) and (X + Column < 32) and (Y + Row >= 0) and (Y + Row < 16) then
                    Pixels[(Y + Row) * 32 + X + Column + 1] := true;
                Column += 1;
            end;
        end;
    end;

    local procedure Sprite(CharacterId: Integer): Text
    begin
        case CharacterId of
            0: exit('.....####.....|...##....##...|..#........#..|..#...##...#..|.#...#..#...#.|.#....##....#.|.#..........#.|..#........#..|...##....##...|.....####.....');
            1: exit('..............|..............|.....####.....|....#....#....|...#.#..#.#...|...#......#...|....#.##.#....|.....####.....');
            2: exit('....######....|..##......##..|.#..........#.|#...#....#...#|#............#|#....####....#|.#..........#.|..##......##..|....######....');
            3: exit('...########...|..#........#..|.#..........#.|.#..#....#..#.|.#..........#.|..#...##...#..|...########...|....#....#....|...##....##...');
            4: exit('....######....|...#......#...|..#.#..#...#..|..#.....##.#..|...#......#...|....######....|....#....#....|...##....##...');
            5: exit('..###....###..|..#.#....#.#..|..##########..|.#..........#.|.#..#....#..#.|.#..........#.|.#...####...#.|..##########..|...#......#...|..##......##..');
            6: exit('....######....|..##......##..|.#..##..##..#.|#............#|#....####....#|.#..........#.|..##......##..|....######....|....#....#....|...##....##...');
            7: exit('....######....|...#......#...|..##########..|..#.#....#.#..|..##########..|...#......#...|....######....|....#....#....|....#....#....|...##....##...');
            8: exit('....######....|...#......#...|..#..#..#..#..|..#......####.|..#......#..#.|..#......####.|...#......#...|....######....|....#....#....|...##....##...');
            9: exit('....#####.....|...#.....#....|...#.#.#.#....|...#.....#....|....#####.....|......#.......|......#.......|......#...#...|.......###....');
            10: exit('....######....|...#......#...|...#.#..#.#...|..####..####..|..#........#..|...########...|....#....#....|....#....#....|...##....##...');
            11: exit('.....####.....|...##....##...|..#.#..#...#..|..#...##...#..|..#........#..|...#..##..#...|....######....|.....#..#.....|....##..##....');
            12: exit('......##......|......##......|...########...|......##......|......##......|......##......|...########...|..#........#..|..#..#..#..#..|..#........#..|...########...');
            else Error('Invalid AL pet display character.');
        end;
    end;
}
