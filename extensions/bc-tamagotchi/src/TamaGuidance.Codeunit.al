codeunit 61215 "Tama Care Guidance"
{
    Permissions = tabledata "Tama Event Queue" = r, tabledata "Job Queue Entry" = r;
    var
        UI: Codeunit "Tama User Interface";
        DisabledLbl: Label 'Care collection is off. Enable it in Setup to let BC events care for me.';
        EggLbl: Label 'I am still an egg. I hatch after five minutes; care starts then.';
        DeadLbl: Label 'I have died. Business events cannot revive me. Start a new egg in Setup.';
        AsleepLbl: Label 'I am asleep. Food, play and medicine wait until I wake up.';
        FoodFullLbl: Label 'Food is full. My next meal comes when you: %1.';
        FoodMildLbl: Label 'A little hungry. %1.';
        FoodMediumLbl: Label 'Getting hungry! %1.';
        FoodLowLbl: Label 'FEED ME! There is only one food heart left. %1.';
        FoodEmptyLbl: Label 'I AM STARVING! %1. NOW!';
        HappyFullLbl: Label 'Happiness is full. Keep it that way: %1.';
        HappyMildLbl: Label 'A little bored. %1.';
        HappyMediumLbl: Label 'I need some fun! %1.';
        HappyLowLbl: Label 'I am painfully lonely. %1. Please!';
        HappyEmptyLbl: Label 'I AM MISERABLE! %1. Stop watching and give me some joy!';
        CleanFullLbl: Label 'All clean. Next cleanup: %1.';
        CleanMildLbl: Label 'A small mess needs cleaning. %1.';
        CleanMediumLbl: Label 'This place is getting disgusting! %1.';
        CleanLowLbl: Label 'I am wading through filth! %1.';
        CleanEmptyLbl: Label 'THIS IS A BIOHAZARD! %1. Before it gets any worse!';
        MedicineLbl: Label 'I am sick. %1. Medicine doses still needed: %2.';
        MedicineUrgentLbl: Label 'I AM SERIOUSLY ILL! %1. I still need %2 doses!';
        LightsOffLbl: Label 'I need darkness to sleep. %1.';
        LightsUrgentLbl: Label 'TURN THE LIGHT OFF! I am trying to sleep. %1.';
        LightsOnLbl: Label 'I am awake but the screen is dark. %1.';
        DisciplineLbl: Label 'I am calling for discipline. %1 before I stop listening!';
        NoMappingLbl: Label 'Choose an event for %1 in Setup';
        InvoiceLbl: Label 'Post a sales invoice';
        ApplyLbl: Label 'Apply customer entries with Apply Entries';
        PaymentLbl: Label 'Post a customer payment';
        PurchaseLbl: Label 'Post a purchase invoice';
        SalesReleaseLbl: Label 'Manually release a sales order';
        PurchReleaseLbl: Label 'Manually release a purchase order';
        BankLbl: Label 'Post a bank reconciliation';
        CreditLbl: Label 'Post a sales credit memo';
        NoJobLbl: Label 'No background job exists. Use Create / restart background job in Setup.';
        HeldJobLbl: Label 'The background job is %1. Check Job Queue Entries; viewing does not restart it.';
        ReceiptLbl: Label 'Care attempts received: %1 · accepted: %2 · refused: %3 · pending: %4';
        LastLbl: Label 'Latest: %1 → %2. %3';
        PendingLbl: Label 'Waiting to be processed.';

    procedure ActionText(Setup: Record "Tama Setup"; Care: Enum "Tama Care"): Text
    begin
        case Setup.CareEvent(Care) of
            "Tama BC Event"::SalesInvoice: exit(InvoiceLbl);
            "Tama BC Event"::CustomerApplication: exit(ApplyLbl);
            "Tama BC Event"::CustomerPayment: exit(PaymentLbl);
            "Tama BC Event"::PurchaseInvoice: exit(PurchaseLbl);
            "Tama BC Event"::SalesOrderReleased: exit(SalesReleaseLbl);
            "Tama BC Event"::PurchaseOrderReleased: exit(PurchReleaseLbl);
            "Tama BC Event"::BankStatementPosted: exit(BankLbl);
            "Tama BC Event"::SalesCreditMemo: exit(CreditLbl);
        end;
        exit(StrSubstNo(NoMappingLbl, Format(Care)));
    end;

    procedure Advice(var Life: Codeunit "Tama AL Life"; Setup: Record "Tama Setup"): JsonArray
    var Lines: JsonArray; Pattern: Text; Level: Integer;
    begin
        if not Setup.Enabled then Add(Lines, DisabledLbl, 1);
        if Life.IsDead() then begin Add(Lines, DeadLbl, 3); exit(Lines); end;
        if Life.Character() = 0 then begin Add(Lines, EggLbl, 0); exit(Lines); end;
        if Life.IsSleeping() then begin
            Add(Lines, AsleepLbl, 0);
            if Life.IsLightOn() then Add(Lines, StrSubstNo(LightsUrgentLbl, ActionText(Setup, "Tama Care"::LightOff)), 3);
        end else begin
            if Life.IsSick() then begin
                Pattern := MedicineLbl; Level := 2;
                if Life.IllMinutes() >= 60 then begin Pattern := MedicineUrgentLbl; Level := 3; end;
                Add(Lines, StrSubstNo(Pattern, ActionText(Setup, "Tama Care"::Medicine), Life.DosesRemaining()), Level);
            end else begin
                case Life.Food() of
                    4: Pattern := FoodFullLbl; 3: Pattern := FoodMildLbl;
                    2: Pattern := FoodMediumLbl; 1: Pattern := FoodLowLbl; 0: Pattern := FoodEmptyLbl;
                end;
                Add(Lines, StrSubstNo(Pattern, ActionText(Setup, "Tama Care"::Meal)), Urgency(Life.Food()));
                case Life.Happiness() of
                    4: Pattern := HappyFullLbl; 3: Pattern := HappyMildLbl;
                    2: Pattern := HappyMediumLbl; 1: Pattern := HappyLowLbl; 0: Pattern := HappyEmptyLbl;
                end;
                Add(Lines, StrSubstNo(Pattern, ActionText(Setup, "Tama Care"::Play)), Urgency(Life.Happiness()));
            end;
            if not Life.IsLightOn() then Add(Lines, StrSubstNo(LightsOnLbl, ActionText(Setup, "Tama Care"::LightOn)), 1);
            if Life.NeedsDiscipline() then Add(Lines, StrSubstNo(DisciplineLbl, ActionText(Setup, "Tama Care"::Discipline)), 2);
        end;
        case Life.GetPoop() of
            0: Pattern := CleanFullLbl; 1: Pattern := CleanMildLbl;
            2: Pattern := CleanMediumLbl; 3: Pattern := CleanLowLbl; 4: Pattern := CleanEmptyLbl;
        end;
        Add(Lines, StrSubstNo(Pattern, ActionText(Setup, "Tama Care"::Clean)), Urgency(4 - Life.GetPoop()));
        exit(Lines);
    end;

    procedure AddToFrame(var Life: Codeunit "Tama AL Life"; Setup: Record "Tama Setup"; State: Record "Tama State"; var Frame: JsonObject)
    var Lines: JsonArray; Queue: Record "Tama Event Queue"; Job: Record "Job Queue Entry";
        JobId: Guid; Received, Accepted, Refused, Pending: Integer; Receipt, Result: Text;
    begin
        Lines := Advice(Life, Setup);
        Evaluate(JobId, '{7D7FF8C6-D5F3-4A12-A6E9-3AD077D52B23}');
        if not Job.Get(JobId) then Add(Lines, NoJobLbl, 1)
        else if not (Job.Status in [Job.Status::Ready, Job.Status::"In Process"]) then
            Add(Lines, StrSubstNo(HeldJobLbl, Format(Job.Status)), 2);
        Frame.Add('advice', Lines);
        Queue.SetRange("Generation No.", State."Generation No."); Received := Queue.Count();
        Queue.SetRange(Status, Queue.Status::Completed); Accepted := Queue.Count();
        Queue.SetRange(Status, Queue.Status::Skipped); Refused := Queue.Count();
        Queue.SetRange(Status, Queue.Status::Pending); Pending := Queue.Count();
        Queue.SetRange(Status);
        Receipt := StrSubstNo(ReceiptLbl, Received, Accepted, Refused, Pending);
        Queue.SetCurrentKey("Occurred UTC", "Sequence No.");
        if Queue.FindLast() then begin
            Result := UI.DisplayResult(Queue.Result);
            if Queue.Status = Queue.Status::Pending then Result := PendingLbl;
            Receipt += ' ' + StrSubstNo(LastLbl, Format(Queue."BC Event"), Format(Queue.Care), Result);
        end;
        Frame.Add('receipt', Receipt); Frame.Add('received', Received); Frame.Add('pending', Pending);
    end;

    local procedure Urgency(Hearts: Integer): Integer
    begin
        case Hearts of 4: exit(0); 3: exit(1); 2: exit(2); else exit(3); end;
    end;

    local procedure Add(var Lines: JsonArray; MessageText: Text; Level: Integer)
    var Item: JsonObject;
    begin
        Item.Add('text', MessageText); Item.Add('level', Level); Lines.Add(Item);
    end;
}
