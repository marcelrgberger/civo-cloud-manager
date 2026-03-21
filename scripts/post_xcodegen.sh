#!/bin/bash
cd "$(dirname "$0")/.."
python3 << 'PYTHON'
import uuid

P = "CivoCloudManager.xcodeproj/project.pbxproj"
LANGS = ["en","de","es","fr","it","nl","pl","pt"]
c = open(P).read()

if "PBXVariantGroup" in c:
    print("Already patched"); exit()

def uid(): return uuid.uuid4().hex[:24].upper()

vg = uid(); vb = uid(); xf = uid(); xb = uid()
fids = {l: uid() for l in LANGS}

# File refs for each lproj
refs = ""
for l in LANGS:
    refs += f'\t\t{fids[l]} /* {l} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {l}; path = CivoCloudManager/{l}.lproj/InfoPlist.strings; sourceTree = SOURCE_ROOT; }};\n'
refs += f'\t\t{xf} /* Localizable.xcstrings */ = {{isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; name = Localizable.xcstrings; path = CivoCloudManager/Localizable.xcstrings; sourceTree = SOURCE_ROOT; }};\n'
c = c.replace("/* End PBXFileReference section */", refs + "/* End PBXFileReference section */")

# Variant group - insert BEFORE PBXGroup section
kids = ",\n".join(f"\t\t\t\t{fids[l]} /* {l} */" for l in LANGS)
vg_block = f"""/* Begin PBXVariantGroup section */
\t\t{vg} /* InfoPlist.strings */ = {{
\t\t\tisa = PBXVariantGroup;
\t\t\tchildren = (
{kids},
\t\t\t);
\t\t\tname = InfoPlist.strings;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXVariantGroup section */

"""
c = c.replace("/* Begin PBXGroup section */", vg_block + "/* Begin PBXGroup section */")

# Build files
bf = f'\t\t{vb} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {vg} /* InfoPlist.strings */; }};\n'
bf += f'\t\t{xb} /* Localizable.xcstrings in Resources */ = {{isa = PBXBuildFile; fileRef = {xf} /* Localizable.xcstrings */; }};\n'
c = c.replace("/* End PBXBuildFile section */", bf + "/* End PBXBuildFile section */")

# Add to resources build phase
c = c.replace(
    "isa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (",
    f"isa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{vb} /* InfoPlist.strings in Resources */,\n\t\t\t\t{xb} /* Localizable.xcstrings in Resources */,"
)

# Add to CivoCloudManager group children
import re
m = re.search(r'(children = \([^)]*?)([\w]+ /\* Assets)', c)
if m:
    pos = m.start(2)
    c = c[:pos] + f"{vg} /* InfoPlist.strings */,\n\t\t\t\t{xf} /* Localizable.xcstrings */,\n\t\t\t\t" + c[pos:]

# Fix knownRegions
old_kr = "knownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t);"
new_kr = "knownRegions = (\n\t\t\t\tBase,\n" + "".join(f"\t\t\t\t{l},\n" for l in LANGS) + "\t\t\t);"
c = c.replace(old_kr, new_kr)

open(P, "w").write(c)
print("Patched: knownRegions, InfoPlist.strings variant group, Localizable.xcstrings")
PYTHON
