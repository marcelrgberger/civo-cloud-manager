#!/bin/bash
# Post-xcodegen script: patches pbxproj for localization support
PBXPROJ="CivoCloudManager.xcodeproj/project.pbxproj"

python3 << 'PY'
path = "CivoCloudManager.xcodeproj/project.pbxproj"
content = open(path).read()

# 1. Patch knownRegions
old_regions = 'knownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t);'
new_regions = 'knownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t\tde,\n\t\t\t\tes,\n\t\t\t\tfr,\n\t\t\t\tit,\n\t\t\t\tnl,\n\t\t\t\tpl,\n\t\t\t\tpt,\n\t\t\t);'
if old_regions in content:
    content = content.replace(old_regions, new_regions)
    print("Patched knownRegions")

# 2. Add Localizable.xcstrings if missing
if "Localizable.xcstrings" not in content:
    file_ref = '\t\tA1B2C3D4E5F6A7B8 /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; name = Localizable.xcstrings; path = CivoCloudManager/Localizable.xcstrings; sourceTree = SOURCE_ROOT; };\n'
    content = content.replace('/* End PBXFileReference section */', file_ref + '/* End PBXFileReference section */')
    
    build_file = '\t\tB2C3D4E5F6A7B8A1 /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = A1B2C3D4E5F6A7B8 /* Localizable.xcstrings */; };\n'
    content = content.replace('/* End PBXBuildFile section */', build_file + '/* End PBXBuildFile section */')
    
    content = content.replace('/* CivoCloudManager.storekit in Resources */',
        '/* CivoCloudManager.storekit in Resources */,\n\t\t\t\tB2C3D4E5F6A7B8A1 /* Localizable.xcstrings in Resources */')
    print("Added Localizable.xcstrings")

open(path, 'w').write(content)
PY

echo "Post-xcodegen patches applied."
