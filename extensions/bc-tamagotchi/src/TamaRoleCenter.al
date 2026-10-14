controladdin "Tama P1 Screen"
{
    RequestedHeight = 680;
    MinimumHeight = 680;
    RequestedWidth = 360;
    MinimumWidth = 260;
    HorizontalStretch = true;
    VerticalStretch = false;
    Scripts = 'controladdin/shells.js', 'controladdin/tama.js';
    StyleSheets = 'controladdin/tama.css';
    StartupScript = 'controladdin/startup.js';
    RecreateScript = 'controladdin/startup.js';
    event Ready();
    event Tick();
    event OpenSetup();
    procedure SetFrame(Payload: Text);
}

page 61202 "Tama Role Center Part"
{
    Caption = 'Tamagotchi BC KPI';
    PageType = CardPart;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            usercontrol(Screen; "Tama P1 Screen")
            {
                ApplicationArea = All;
                trigger Ready() begin SendFrame(); end;
                trigger Tick() begin SendFrame(); end;
                trigger OpenSetup() begin Page.Run(Page::"Tama Setup"); end;
            }
        }
    }
    var
        Engine: Codeunit "Tama Company Engine";
    local procedure SendFrame()
    begin
        CurrPage.Screen.SetFrame(Engine.UpdateFrame());
    end;
}

page 61203 "Tama Pet Viewer"
{
    Caption = 'Company Tamagotchi';
    PageType = Card;
    UsageCategory = Tasks;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            part(Tamagotchi; "Tama Role Center Part") { ApplicationArea = All; AccessByPermission = tabledata "Tama Setup" = R; }
        }
    }
}

page 61204 "Tama Accountant Role Center"
{
    Caption = 'Accountant with Tamagotchi';
    PageType = RoleCenter;
    layout
    {
        area(RoleCenter)
        {
            part(Tamagotchi; "Tama Role Center Part") { ApplicationArea = All; AccessByPermission = tabledata "Tama Setup" = R; }
            part(Headline; "Headline RC Accountant") { ApplicationArea = Basic, Suite; }
            part(Activities; "Accountant Activities") { ApplicationArea = Basic, Suite; }
            part(Intercompany; "Intercompany Activities") { ApplicationArea = Intercompany; }
            part(UserTasks; "User Tasks Activities") { ApplicationArea = Suite; }
            part(JobTasks; "Job Queue Tasks Activities") { ApplicationArea = Suite; }
            part(Emails; "Email Activities") { ApplicationArea = Basic, Suite; }
            part(Approvals; "Approvals Activities") { ApplicationArea = Suite; }
            part(TeamActivities; "Team Member Activities") { ApplicationArea = Suite; }
            part(MyAccounts; "My Accounts") { ApplicationArea = Basic, Suite; }
            part(HelpAndCharts; "Help And Chart Wrapper") { ApplicationArea = Basic, Suite; }
            part(CashFlow; "Cash Flow Forecast Chart") { ApplicationArea = Basic, Suite; }
            part(ReportInbox; "Report Inbox Part") { ApplicationArea = Basic, Suite; AccessByPermission = tabledata "Report Inbox" = IMD; }
            part(PowerBI; "Power BI Embedded Report Part") { ApplicationArea = Basic, Suite; }
            part(FinancePerformance; "Finance Performance") { ApplicationArea = Basic, Suite; Visible = false; }
            part(SalesChart; "Trailing Sales Orders Chart") { ApplicationArea = Basic, Suite; Visible = false; }
            part(MyJobQueue; "My Job Queue") { ApplicationArea = Basic, Suite; Visible = false; }
            systempart(Notes; MyNotes) { ApplicationArea = Basic, Suite; }
        }
    }
    // Compose standard BC parts and destinations in our own page. This is not
    // a copy of Microsoft's page source and does not extend standard profiles.
    actions
    {
        area(Embedding)
        {
            action(Accounts) { Caption = 'Chart of Accounts'; ApplicationArea = Basic, Suite; RunObject = page "Chart of Accounts"; }
            action(Customers) { Caption = 'Customers'; ApplicationArea = Basic, Suite; RunObject = page "Customer List"; }
            action(Vendors) { Caption = 'Vendors'; ApplicationArea = Basic, Suite; RunObject = page "Vendor List"; }
            action(Banks) { Caption = 'Bank Accounts'; ApplicationArea = Basic, Suite; RunObject = page "Bank Account List"; }
            action(Invoices) { Caption = 'Sales Invoices'; ApplicationArea = Basic, Suite; RunObject = page "Sales Invoice List"; }
            action(Purchases) { Caption = 'Purchase Invoices'; ApplicationArea = Basic, Suite; RunObject = page "Purchase Invoices"; }
            action(Incoming) { Caption = 'Incoming Documents'; ApplicationArea = Basic, Suite; RunObject = page "Incoming Documents"; }
        }
        area(Sections)
        {
            group(Finance)
            {
                Caption = 'Finance';
                action(GeneralJournals) { Caption = 'General Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const(General), Recurring = const(false)); }
                action(RecurringJournals) { Caption = 'Recurring General Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const(General), Recurring = const(true)); }
                action(Budgets) { Caption = 'G/L Budgets'; ApplicationArea = Basic, Suite; RunObject = page "G/L Budget Names"; }
                action(FinancialReports) { Caption = 'Financial Reports'; ApplicationArea = Basic, Suite; RunObject = page "Financial Reports"; }
                action(AnalysisViews) { Caption = 'Analysis Views'; ApplicationArea = Dimensions; RunObject = page "Analysis View List"; }
                action(Dimensions) { Caption = 'Dimensions'; ApplicationArea = Dimensions; RunObject = page Dimensions; }
                action(Periods) { Caption = 'Accounting Periods'; ApplicationArea = Basic, Suite; RunObject = page "Accounting Periods"; }
                action(VATStatements) { Caption = 'VAT Statements'; ApplicationArea = Basic, Suite; RunObject = page "VAT Statement Names"; }
                action(Registers) { Caption = 'G/L Registers'; ApplicationArea = Basic, Suite; RunObject = page "G/L Registers"; }
            }
            group(Receivables)
            {
                Caption = 'Receivables';
                action(CustomerEntries) { Caption = 'Customer Ledger Entries'; ApplicationArea = Basic, Suite; RunObject = page "Customer Ledger Entries"; }
                action(CashReceipts) { Caption = 'Cash Receipt Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const("Cash Receipts"), Recurring = const(false)); }
                action(SalesJournals) { Caption = 'Sales Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const(Sales), Recurring = const(false)); }
                action(SalesOrders) { Caption = 'Sales Orders'; ApplicationArea = Basic, Suite; RunObject = page "Sales Order List"; }
                action(SalesCredits) { Caption = 'Sales Credit Memos'; ApplicationArea = Basic, Suite; RunObject = page "Sales Credit Memos"; }
                action(PostedInvoices) { Caption = 'Posted Sales Invoices'; ApplicationArea = Basic, Suite; RunObject = page "Posted Sales Invoices"; }
                action(PostedCredits) { Caption = 'Posted Sales Credit Memos'; ApplicationArea = Basic, Suite; RunObject = page "Posted Sales Credit Memos"; }
            }
            group(Payables)
            {
                Caption = 'Payables';
                action(VendorEntries) { Caption = 'Vendor Ledger Entries'; ApplicationArea = Basic, Suite; RunObject = page "Vendor Ledger Entries"; }
                action(PaymentJournals) { Caption = 'Payment Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const(Payments), Recurring = const(false)); }
                action(PurchaseJournals) { Caption = 'Purchase Journals'; ApplicationArea = Basic, Suite; RunObject = page "General Journal Batches"; RunPageView = where("Template Type" = const(Purchases), Recurring = const(false)); }
                action(PurchaseOrders) { Caption = 'Purchase Orders'; ApplicationArea = Basic, Suite; RunObject = page "Purchase Order List"; }
                action(PostedPurchases) { Caption = 'Posted Purchase Invoices'; ApplicationArea = Basic, Suite; RunObject = page "Posted Purchase Invoices"; }
                action(PostedPurchaseCredits) { Caption = 'Posted Purchase Credit Memos'; ApplicationArea = Basic, Suite; RunObject = page "Posted Purchase Credit Memos"; }
            }
            group(CashManagement)
            {
                Caption = 'Cash Management';
                action(Reconciliations) { Caption = 'Bank Reconciliations'; ApplicationArea = Basic, Suite; RunObject = page "Bank Acc. Reconciliation List"; }
                action(PaymentReconciliations) { Caption = 'Payment Reconciliation Journals'; ApplicationArea = Basic, Suite; RunObject = page "Pmt. Reconciliation Journals"; }
                action(BankStatements) { Caption = 'Bank Account Statements'; ApplicationArea = Basic, Suite; RunObject = page "Bank Account Statement List"; }
                action(Forecasts) { Caption = 'Cash Flow Forecasts'; ApplicationArea = Basic, Suite; RunObject = page "Cash Flow Forecast List"; }
            }
            group(Assets)
            {
                Caption = 'Fixed Assets';
                action(FixedAssets) { Caption = 'Fixed Assets'; ApplicationArea = FixedAssets; RunObject = page "Fixed Asset List"; }
                action(AssetJournals) { Caption = 'Fixed Asset Journals'; ApplicationArea = FixedAssets; RunObject = page "FA Journal Batches"; }
            }
            group(CompanyPet)
            {
                Caption = 'Tamagotchi';
                action(PetSetup) { Caption = 'Tamagotchi Setup'; ApplicationArea = All; RunObject = page "Tama Setup"; }
                action(PetHistory) { Caption = 'Care History'; ApplicationArea = All; RunObject = page "Tama Event Log"; }
                action(Jobs) { Caption = 'Job Queue Entries'; ApplicationArea = All; RunObject = page "Job Queue Entries"; }
            }
        }
        area(Reporting)
        {
            action(TrialBalance) { Caption = 'Trial Balance'; ApplicationArea = Basic, Suite; RunObject = report "Trial Balance"; }
            action(ReceivablesReport) { Caption = 'Aged Accounts Receivable'; ApplicationArea = Basic, Suite; RunObject = report "Aged Accounts Receivable"; }
            action(PayablesReport) { Caption = 'Aged Accounts Payable'; ApplicationArea = Basic, Suite; RunObject = report "Aged Accounts Payable"; }
            action(BankTrialBalance) { Caption = 'Bank Detail Trial Balance'; ApplicationArea = Basic, Suite; RunObject = report "Bank Acc. - Detail Trial Bal."; }
            action(BalanceSheet) { Caption = 'Balance Sheet'; ApplicationArea = Basic, Suite; RunObject = report "Balance Sheet"; }
            action(IncomeStatement) { Caption = 'Income Statement'; ApplicationArea = Basic, Suite; RunObject = report "Income Statement"; }
        }
    }
}

profile "TAMAGOTCHI BC KPI"
{
    Caption = 'Accountant with Tamagotchi';
    RoleCenter = "Tama Accountant Role Center";
}

permissionset 61200 "TAMA USER"
{
    Assignable = true;
    Caption = 'Tamagotchi: view and care through BC';
    Permissions =
        table "Tama Setup" = X, tabledata "Tama Setup" = R,
        table "Tama State" = X, tabledata "Tama State" = Rim,
        table "Tama Event Queue" = X, tabledata "Tama Event Queue" = Rim,
        codeunit "Tama BC Events" = X,
        codeunit "Tama AL Life" = X,
        codeunit "Tama P1 Rules" = X,
        codeunit "Tama AL Display" = X,
        codeunit "Tama Company Engine" = X,
        codeunit "Tama User Interface" = X,
        codeunit "Tama Care Guidance" = X,
        tabledata "Job Queue Entry" = r,
        page "Tama Role Center Part" = X,
        page "Tama Accountant Role Center" = X,
        page "Tama Pet Viewer" = X,
        page "Tama Event Log" = X;
}

permissionset 61201 "TAMA ADMIN"
{
    Assignable = true;
    Caption = 'Tamagotchi: setup and new egg';
    IncludedPermissionSets = "TAMA USER";
    Permissions =
        tabledata "Tama Setup" = RIM,
        table "Tama Life Archive" = X, tabledata "Tama Life Archive" = Ri,
        codeunit "Tama Setup Management" = X,
        codeunit "Tama Install" = X,
        codeunit "Tama Background Life" = X,
        codeunit "Tama Life Job" = X,
        codeunit "Job Queue - Enqueue" = X,
        tabledata "Job Queue Entry" = rim,
        page "Tama Setup" = X;
}
