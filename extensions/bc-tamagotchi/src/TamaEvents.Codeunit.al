codeunit 61202 "Tama BC Events"
{
    Permissions = tabledata "Tama Setup" = r, tabledata "Tama Event Queue" = ri;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', true, true)]
    local procedure SalesPosted(SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; PreviewMode: Boolean)
    var
        Invoice: Record "Sales Invoice Header";
        Credit: Record "Sales Cr.Memo Header";
    begin
        if PreviewMode then exit;
        if (SalesInvHdrNo <> '') and Invoice.Get(SalesInvHdrNo) then
            Capture("Tama BC Event"::SalesInvoice, Invoice.SystemId);
        if (SalesCrMemoHdrNo <> '') and Credit.Get(SalesCrMemoHdrNo) then
            Capture("Tama BC Event"::SalesCreditMemo, Credit.SystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnAfterPostApplyCustLedgEntry', '', true, true)]
    local procedure CustomerApplied(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Detail: Record "Detailed Cust. Ledg. Entry";
    begin
        if CustLedgerEntry.IsTemporary() then exit;
        // A partial payment can be followed by another application of the same
        // ledger entry. Deduplicate by the new application row, not that old entry.
        Detail.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        Detail.SetRange("Entry Type", Detail."Entry Type"::Application);
        Detail.SetRange(Unapplied, false);
        if Detail.FindLast() then Capture("Tama BC Event"::CustomerApplication, Detail.SystemId);
        // Posting preview rolls this insert back with the application transaction.
        // Unapply has a different publisher and gives no care reward.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterCustLedgEntryInsert', '', true, true)]
    local procedure CustomerPaymentPosted(var CustLedgerEntry: Record "Cust. Ledger Entry"; PreviewMode: Boolean)
    begin
        if PreviewMode or CustLedgerEntry.IsTemporary() then exit;
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Payment then
            Capture("Tama BC Event"::CustomerPayment, CustLedgerEntry.SystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', true, true)]
    local procedure PurchasePosted(PurchInvHdrNo: Code[20])
    var
        Invoice: Record "Purch. Inv. Header";
    begin
        if (PurchInvHdrNo <> '') and Invoice.Get(PurchInvHdrNo) then
            Capture("Tama BC Event"::PurchaseInvoice, Invoice.SystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterManualReleaseSalesDoc', '', true, true)]
    local procedure SalesReleased(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
        if PreviewMode or SalesHeader.IsTemporary() then exit;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            Capture("Tama BC Event"::SalesOrderReleased, SalesHeader.SystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterManualReleasePurchaseDoc', '', true, true)]
    local procedure PurchaseReleased(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
        if PreviewMode or PurchaseHeader.IsTemporary() then exit;
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            Capture("Tama BC Event"::PurchaseOrderReleased, PurchaseHeader.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Statement", 'OnAfterInsertEvent', '', true, true)]
    local procedure BankStatementInserted(var Rec: Record "Bank Account Statement"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then Capture("Tama BC Event"::BankStatementPosted, Rec.SystemId);
    end;

    procedure Capture(BCEvent: Enum "Tama BC Event"; SourceId: Guid)
    var
        Setup: Record "Tama Setup";
        Queue: Record "Tama Event Queue";
        Index: Integer;
        Care: Enum "Tama Care";
        PostingPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if PostingPreview.IsActive() then exit;
        if BCEvent = BCEvent::Disabled then exit;
        if IsNullGuid(SourceId) then exit;
        if not Setup.Get('') then exit;
        if not Setup.Enabled or (Setup."Generation No." = 0) then exit;
        for Index := 1 to 8 do begin
            Care := "Tama Care".FromInteger(Index);
            if Setup.CareEvent(Care) = BCEvent then begin
                Queue.Init();
                Queue."BC Event" := BCEvent;
                Queue."Source SystemId" := SourceId;
                Queue.Care := Care;
                Queue."Occurred UTC" := CurrentDateTime();
                Queue."Generation No." := Setup."Generation No.";
                Queue.Status := Queue.Status::Pending;
                if Queue.Insert(false) then;
            end;
        end;
        // No COMMIT, emulator, timer or BC write-back in posting transactions.
    end;

    procedure Publisher(BCEvent: Enum "Tama BC Event"): Text
    begin
        case BCEvent of
            BCEvent::Disabled: exit(Format(BCEvent));
            BCEvent::SalesInvoice, BCEvent::SalesCreditMemo: exit('80 Sales-Post → OnAfterPostSalesDoc');
            BCEvent::CustomerApplication: exit('226 CustEntry-Apply Posted Entries → OnAfterPostApplyCustLedgEntry');
            BCEvent::CustomerPayment: exit('12 Gen. Jnl.-Post Line → OnAfterCustLedgEntryInsert');
            BCEvent::PurchaseInvoice: exit('90 Purch.-Post → OnAfterPostPurchaseDoc');
            BCEvent::SalesOrderReleased: exit('414 Release Sales Document → OnAfterManualReleaseSalesDoc');
            BCEvent::PurchaseOrderReleased: exit('415 Release Purchase Document → OnAfterManualReleasePurchaseDoc');
            BCEvent::BankStatementPosted: exit('275 Bank Account Statement → OnAfterInsertEvent');
        end;
    end;
}
