enum 61200 "Tama BC Event"
{
    Extensible = false;
    value(0; Disabled) { Caption = 'None'; }
    value(1; SalesInvoice) { Caption = 'Sales invoice posted'; }
    value(2; CustomerApplication) { Caption = 'Customer entries applied (Apply Entries)'; }
    value(3; CustomerPayment) { Caption = 'Customer payment posted'; }
    value(4; PurchaseInvoice) { Caption = 'Purchase invoice posted'; }
    value(5; SalesOrderReleased) { Caption = 'Sales order manually released'; }
    value(6; PurchaseOrderReleased) { Caption = 'Purchase order manually released'; }
    value(7; BankStatementPosted) { Caption = 'Bank reconciliation posted'; }
    value(8; SalesCreditMemo) { Caption = 'Sales credit memo posted'; }
}

enum 61201 "Tama Care"
{
    Extensible = false;
    value(0; InitializeClock) { Caption = 'Set original clock'; }
    value(1; Meal) { Caption = 'Meal'; }
    value(2; Clean) { Caption = 'Cleaning'; }
    value(3; Play) { Caption = 'Play'; }
    value(4; Medicine) { Caption = 'Medicine'; }
    value(5; Discipline) { Caption = 'Discipline'; }
    value(6; LightOn) { Caption = 'Light on'; }
    value(7; LightOff) { Caption = 'Light off'; }
    value(8; Snack) { Caption = 'Snack'; }
}

enum 61202 "Tama Shell Design"
{
    Extensible = false;
    value(0; PurplePink) { Caption = 'Purple / pink'; }
    value(1; BlueYellow) { Caption = 'Blue / yellow'; }
    value(2; PinkYellow) { Caption = 'Pink / yellow'; }
    value(3; WhiteBlack) { Caption = 'White / black'; }
    value(4; BlueSilver) { Caption = 'Blue / silver'; }
    value(5; Rainbow) { Caption = 'Rainbow'; }
    value(6; RedGlitter) { Caption = 'Red glitter'; }
    value(7; Mermaid) { Caption = 'Mermaid'; }
}
