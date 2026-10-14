// No original program or company-state changes. Session language is restored
// before assertions so a failed test cannot leave the runner in another language.
codeunit 61253 "Tama Language Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnglishUSAndUKUseEnglishLabels()
    begin
        CheckEnglish(1033);
        CheckEnglish(2057);
    end;

    [Test]
    procedure DanishUsesDanishLabels()
    var UI: Codeunit "Tama User Interface"; Frame: JsonObject; Previous: Integer; Cabinet: Text;
    begin
        Previous := GlobalLanguage(); GlobalLanguage(1030);
        UI.AddToFrame(Frame);
        Cabinet := Format("Tama Shell Design"::Mermaid);
        GlobalLanguage(Previous);
        Equal('Opsætning', TextOf(Frame, 'setup'));
        Equal('Tillad lyd', TextOf(Frame, 'enableSound'));
        Equal('Havfrue', Cabinet);
        Equal('Mad', TextOf(Frame, 'icon0'));
    end;

    [Test]
    procedure SharedHistoricResultsFollowEachReadersLanguage()
    var UI: Codeunit "Tama User Interface"; Previous: Integer; English, Danish, Legacy, Busy: Text;
    begin
        Previous := GlobalLanguage();
        GlobalLanguage(2057);
        English := UI.DisplayResult('care.completed:1');
        Legacy := UI.DisplayResult('Mad: originalens handling gennemført.');
        Busy := UI.DisplayResult('Originalen er optaget; kunne ikke afslutte menuen.');
        GlobalLanguage(1030);
        Danish := UI.DisplayResult('care.completed:1');
        GlobalLanguage(Previous);
        Equal('Meal: P1 care action completed.', English);
        Equal(English, Legacy);
        Equal('Mad: P1-pasning gennemført.', Danish);
        Equal('The original program is busy; the menu could not be closed.', Busy);
    end;

    local procedure CheckEnglish(LanguageId: Integer)
    var UI: Codeunit "Tama User Interface"; Frame: JsonObject; Previous: Integer; Cabinet, Invoice: Text;
    begin
        Previous := GlobalLanguage(); GlobalLanguage(LanguageId);
        UI.AddToFrame(Frame);
        Cabinet := Format("Tama Shell Design"::Mermaid);
        Invoice := Format("Tama BC Event"::SalesInvoice);
        GlobalLanguage(Previous);
        Equal('Setup', TextOf(Frame, 'setup'));
        Equal('Enable sound', TextOf(Frame, 'enableSound'));
        Equal('Mermaid', Cabinet);
        Equal('Sales invoice posted', Invoice);
    end;

    local procedure TextOf(Frame: JsonObject; TextKey: Text): Text
    var Token: JsonToken; Texts: JsonObject;
    begin
        Frame.Get('ui', Token); Texts := Token.AsObject(); Texts.Get(TextKey, Token);
        exit(Token.AsValue().AsText());
    end;

    local procedure Equal(Expected: Text; Actual: Text)
    begin
        if Expected <> Actual then Error('Expected "%1", got "%2".', Expected, Actual);
    end;
}
