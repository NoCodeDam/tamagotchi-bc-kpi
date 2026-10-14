codeunit 61208 "Tama Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "Tama Setup" = rm;

    trigger OnUpgradePerCompany()
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        MigrateShellDesign(Info.DataVersion());
        MigrateALSchema(Info.DataVersion());
        MigrateBCClock(Info.DataVersion());
    end;

    procedure MigrateShellDesign(FromVersion: Version)
    var
        Setup: Record "Tama Setup";
    begin
        // Field 18 is additive. An old company receives the same default as a
        // fresh install; all existing care mappings, ROM and life data survive.
        if FromVersion >= Version.Create(0, 1, 1, 0) then exit;
        if not Setup.Get('') then exit;
        Setup."Shell Design" := "Tama Shell Design"::PurplePink;
        Setup.Modify(false);
    end;

    procedure MigrateALSchema(FromVersion: Version)
    var State: Record "Tama State"; Management: Codeunit "Tama Setup Management";
    begin
        if FromVersion >= Version.Create(0, 2, 0, 0) then exit;
        // Additive fields 11–13 on State and 7 on Archive. A live ROM snapshot
        // is not compatible with the recreated AL game. Keep it intact, with
        // explicit New egg required to archive it. No automatic resurrection.
        if not State.Get('') then Management.NewEgg();
    end;

    procedure MigrateBCClock(FromVersion: Version)
    var Setup: Record "Tama Setup";
    begin
        if FromVersion >= Version.Create(0, 3, 0, 0) then exit;
        if not Setup.Get('') then exit;
        // Field 19 is additive. Existing enabled state, mappings, generation
        // and manual-clock data are preserved; only the automatic zone is filled.
        // A deployment session has no reliable client zone. First Setup open
        // captures BC's interactive zone; workers use UTC until then.
        if GuiAllowed() then begin Setup.EnsureBCClock(); Setup.Modify(false); end;
    end;
}
