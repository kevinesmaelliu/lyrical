#!/usr/bin/env python3
"""Regenerate Lyrical.xcodeproj/project.pbxproj with unique UUIDs."""
import uuid
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Lyrical.xcodeproj" / "project.pbxproj"


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    I = {k: uid() for k in [
        "project", "projectConfigList", "targetConfigList", "target", "sourcesPhase",
        "frameworksPhase", "mainGroup", "productsGroup", "sourceGroup", "configGroup",
        "appGroup", "modelsGroup", "servicesGroup", "utilsGroup", "viewModelsGroup",
        "viewsGroup", "product", "infoPlist", "sharedXcconfig", "secretsExample",
        "projDebug", "projRelease", "tgtDebug", "tgtRelease",
    ]}

    # filename -> folder under Sources/Lyrical
    file_folders = {
        "LyricalApp.swift": None,
        "AppDelegate.swift": "App",
        "LyricsWindowController.swift": "App",
        "SettingsWindowController.swift": "App",
        "Track.swift": "Models",
        "LyricsWindowPlacement.swift": "Models",
        "KeychainHelper.swift": "Services",
        "LyricsService.swift": "Services",
        "ArtworkCache.swift": "Services",
        "SpotifyAuthService.swift": "Services",
        "SpotifyConfig.swift": "Services",
        "SpotifyPlayerService.swift": "Services",
        "LRCParser.swift": "Utils",
        "PKCE.swift": "Utils",
        "SettingsOpener.swift": "Utils",
        "PlayerViewModel.swift": "ViewModels",
        "LyricsWindowView.swift": "Views",
        "MenuBarView.swift": "Views",
        "MenuBarArtworkLabel.swift": "Views",
        "ConnectSpotifyExplanationView.swift": "Views",
        "SettingsView.swift": "Views",
    }
    files = list(file_folders.keys())

    for name in files:
        key = name.replace(".", "_")
        I[f"ref_{key}"] = uid()
        I[f"bld_{key}"] = uid()

    def file_key(name: str, prefix: str) -> str:
        return prefix + name.replace(".", "_")

    def refs_in(folder: Optional[str]) -> list[str]:
        return [
            f'{I[file_key(name, "ref_")]} /* {name} */'
            for name, parent in file_folders.items()
            if parent == folder
        ]

    lines: list[str] = []

    def w(s: str = "") -> None:
        lines.append(s)

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {")
    w("\t};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")
    w("")
    w("/* Begin PBXBuildFile section */")
    for name in files:
        key = name.replace(".", "_")
        w(f'\t\t{I[f"bld_{key}"]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {I[f"ref_{key}"]} /* {name} */; }};')
    w("/* End PBXBuildFile section */")
    w("")
    w("/* Begin PBXFileReference section */")
    for name in files:
        key = name.replace(".", "_")
        w(
            f'\t\t{I[f"ref_{key}"]} /* {name} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};'
        )
    w(
        f'\t\t{I["product"]} /* Lyrical.app */ = '
        f'{{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Lyrical.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )
    w(
        f'\t\t{I["infoPlist"]} /* Info.plist */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};'
    )
    w(
        f'\t\t{I["sharedXcconfig"]} /* Shared.xcconfig */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Shared.xcconfig; sourceTree = "<group>"; }};'
    )
    w(
        f'\t\t{I["secretsExample"]} /* Secrets.xcconfig.example */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Secrets.xcconfig.example; sourceTree = "<group>"; }};'
    )
    w("/* End PBXFileReference section */")
    w("")
    w("/* Begin PBXFrameworksBuildPhase section */")
    w(f'\t\t{I["frameworksPhase"]} /* Frameworks */ = {{')
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")
    w("")
    w("/* Begin PBXGroup section */")

    def group(gid: str, name: str, child_lines: list[str], path: Optional[str] = None) -> None:
        w(f"\t\t{gid} /* {name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        for child in child_lines:
            w(f"\t\t\t\t{child},")
        w("\t\t\t);")
        if path:
            w(f"\t\t\tpath = {path};")
        w('\t\t\tsourceTree = "<group>";')
        w("\t\t};")

    group(I["appGroup"], "App", refs_in("App"), "App")
    group(I["modelsGroup"], "Models", refs_in("Models"), "Models")
    group(I["servicesGroup"], "Services", refs_in("Services"), "Services")
    group(I["utilsGroup"], "Utils", refs_in("Utils"), "Utils")
    group(I["viewModelsGroup"], "ViewModels", refs_in("ViewModels"), "ViewModels")
    group(I["viewsGroup"], "Views", refs_in("Views"), "Views")
    group(
        I["configGroup"],
        "Config",
        [
            f'{I["sharedXcconfig"]} /* Shared.xcconfig */',
            f'{I["secretsExample"]} /* Secrets.xcconfig.example */',
        ],
        "Config",
    )
    root_swift_refs = refs_in(None)
    w(f'\t\t{I["sourceGroup"]} /* Lyrical */ = {{')
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for ref in root_swift_refs:
        w(f"\t\t\t\t{ref},")
    w(f'\t\t\t\t{I["appGroup"]} /* App */,')
    w(f'\t\t\t\t{I["modelsGroup"]} /* Models */,')
    w(f'\t\t\t\t{I["servicesGroup"]} /* Services */,')
    w(f'\t\t\t\t{I["utilsGroup"]} /* Utils */,')
    w(f'\t\t\t\t{I["viewModelsGroup"]} /* ViewModels */,')
    w(f'\t\t\t\t{I["viewsGroup"]} /* Views */,')
    w("\t\t\t);")
    w("\t\t\tname = Lyrical;")
    w("\t\t\tpath = Sources/Lyrical;")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")
    w(f'\t\t{I["productsGroup"]} /* Products */ = {{')
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f'\t\t\t\t{I["product"]} /* Lyrical.app */,')
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")
    w(f'\t\t{I["mainGroup"]} = {{')
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f'\t\t\t\t{I["sourceGroup"]} /* Lyrical */,')
    w(f'\t\t\t\t{I["configGroup"]} /* Config */,')
    w(f'\t\t\t\t{I["infoPlist"]} /* Info.plist */,')
    w(f'\t\t\t\t{I["productsGroup"]} /* Products */,')
    w("\t\t\t);")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")
    w("/* End PBXGroup section */")
    w("")
    w("/* Begin PBXNativeTarget section */")
    w(f'\t\t{I["target"]} /* Lyrical */ = {{')
    w("\t\t\tisa = PBXNativeTarget;")
    w(f'\t\t\tbuildConfigurationList = {I["targetConfigList"]} /* Build configuration list for PBXNativeTarget "Lyrical" */;')
    w("\t\t\tbuildPhases = (")
    w(f'\t\t\t\t{I["sourcesPhase"]} /* Sources */,')
    w(f'\t\t\t\t{I["frameworksPhase"]} /* Frameworks */,')
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w("\t\t\tname = Lyrical;")
    w("\t\t\tproductName = Lyrical;")
    w(f'\t\t\tproductReference = {I["product"]} /* Lyrical.app */;')
    w('\t\t\tproductType = "com.apple.product-type.application";')
    w("\t\t};")
    w("/* End PBXNativeTarget section */")
    w("")
    w("/* Begin PBXProject section */")
    w(f'\t\t{I["project"]} /* Project object */ = {{')
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f'\t\t\t\t\t{I["target"]} = {{')
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f'\t\t\tbuildConfigurationList = {I["projectConfigList"]} /* Build configuration list for PBXProject "Lyrical" */;')
    w('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f'\t\t\tmainGroup = {I["mainGroup"]};')
    w(f'\t\t\tproductRefGroup = {I["productsGroup"]} /* Products */;')
    w('\t\t\tprojectDirPath = "";')
    w('\t\t\tprojectRoot = "";')
    w("\t\t\ttargets = (")
    w(f'\t\t\t\t{I["target"]} /* Lyrical */,')
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")
    w("")
    w("/* Begin PBXSourcesBuildPhase section */")
    w(f'\t\t{I["sourcesPhase"]} /* Sources */ = {{')
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for name in files:
        key = name.replace(".", "_")
        w(f'\t\t\t\t{I[f"bld_{key}"]} /* {name} in Sources */,')
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")
    w("")
    w("/* Begin XCBuildConfiguration section */")
    w(f'\t\t{I["projDebug"]} /* Debug */ = {{')
    w("\t\t\tisa = XCBuildConfiguration;")
    w(f'\t\t\tbaseConfigurationReference = {I["sharedXcconfig"]} /* Shared.xcconfig */;')
    w("\t\t\tbuildSettings = {")
    w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    w("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    w("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    w("\t\t\t\tENABLE_TESTABILITY = YES;")
    w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;")
    w("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    w("\t\t\t\tSDKROOT = macosx;")
    w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    w('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")
    w(f'\t\t{I["projRelease"]} /* Release */ = {{')
    w("\t\t\tisa = XCBuildConfiguration;")
    w(f'\t\t\tbaseConfigurationReference = {I["sharedXcconfig"]} /* Shared.xcconfig */;')
    w("\t\t\tbuildSettings = {")
    w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    w("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    w('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
    w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;")
    w("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;")
    w("\t\t\t\tSDKROOT = macosx;")
    w("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    w('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";')
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")
    w(f'\t\t{I["tgtDebug"]} /* Debug */ = {{')
    w("\t\t\tisa = XCBuildConfiguration;")
    w(f'\t\t\tbaseConfigurationReference = {I["sharedXcconfig"]} /* Shared.xcconfig */;')
    w("\t\t\tbuildSettings = {")
    w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    w('\t\t\t\t\t"$(inherited)",')
    w('\t\t\t\t\t"@executable_path/../Frameworks",')
    w("\t\t\t\t);")
    w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    w('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
    w("\t\t\t};")
    w("\t\t\tname = Debug;")
    w("\t\t};")
    w(f'\t\t{I["tgtRelease"]} /* Release */ = {{')
    w("\t\t\tisa = XCBuildConfiguration;")
    w(f'\t\t\tbaseConfigurationReference = {I["sharedXcconfig"]} /* Shared.xcconfig */;')
    w("\t\t\tbuildSettings = {")
    w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    w('\t\t\t\t\t"$(inherited)",')
    w('\t\t\t\t\t"@executable_path/../Frameworks",')
    w("\t\t\t\t);")
    w("\t\t\t};")
    w("\t\t\tname = Release;")
    w("\t\t};")
    w("/* End XCBuildConfiguration section */")
    w("")
    w("/* Begin XCConfigurationList section */")
    w(f'\t\t{I["projectConfigList"]} /* Build configuration list for PBXProject "Lyrical" */ = {{')
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f'\t\t\t\t{I["projDebug"]} /* Debug */,')
    w(f'\t\t\t\t{I["projRelease"]} /* Release */,')
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w(f'\t\t{I["targetConfigList"]} /* Build configuration list for PBXNativeTarget "Lyrical" */ = {{')
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f'\t\t\t\t{I["tgtDebug"]} /* Debug */,')
    w(f'\t\t\t\t{I["tgtRelease"]} /* Release */,')
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w("/* End XCConfigurationList section */")
    w("\t};")
    w(f'\trootObject = {I["project"]} /* Project object */;')
    w("}")

    OUT.write_text("\n".join(lines) + "\n")
    print(f"Wrote {OUT}")
    print(f"Target ID (update scheme if needed): {I['target']}")


if __name__ == "__main__":
    main()
