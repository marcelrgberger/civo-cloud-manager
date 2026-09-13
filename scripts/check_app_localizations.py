#!/usr/bin/env python3
"""Validate catalog coverage, format arguments and optional built app resources."""

import argparse
from collections import Counter
import json
import plistlib
from pathlib import Path
import re
import subprocess

from check_legal_localizations import LANGUAGES, ROOT


FORMAT = re.compile(
    r"%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|ll|[hljztL])?[@diuoxXfFeEgGaAcCsSp%]"
)


def format_arguments(text):
    """Allow positional argument reordering without changing argument types."""
    result = []
    position = 0
    for token in FORMAT.findall(text):
        if token == "%%":
            continue
        explicit = re.match(r"%(\d+)\$(.*)", token)
        if explicit:
            result.append((int(explicit[1]), explicit[2]))
        else:
            position += 1
            result.append((position, token[1:]))
    return sorted(result)


def read_strings(path):
    # Xcode can emit binary, UTF-16 or XML .strings resources.
    return plistlib.loads(subprocess.check_output(["plutil", "-convert", "xml1", "-o", "-", str(path)]))


def runtime_localization_keys():
    """Keys in the app's declarative help/sidebar lists aren't emitted by Swift."""
    literal = r'"(?:[^"\\]|\\.)*"'
    help_source = (ROOT / "CivoCloudManager/Views/HelpView.swift").read_text()
    sections = re.findall(
        rf'HelpSection\(title:\s*({literal}),\s*icon:\s*{literal},\s*items:\s*\[((?:\s*{literal}\s*,?)*)\s*\]\)',
        help_source,
    )
    assert len(sections) == help_source.count("HelpSection(title:"), "Update help-key extraction for the new declaration syntax"
    assert sections, "No help sections found"
    keys = set()
    for title, items in sections:
        keys.add(json.loads(title))
        keys.update(json.loads(item) for item in re.findall(literal, items))
    sidebar_source = (ROOT / "CivoCloudManager/Views/MainWindow/MainWindowView.swift").read_text()
    keys.update(json.loads(value) for value in re.findall(rf'^\s+case \w+ = ({literal})', sidebar_source, re.M))
    return keys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Built macOS .app to inspect")
    parser.add_argument("--derived-data", type=Path, help="Check Swift's extracted localization keys from a build")
    args = parser.parse_args()
    catalog = json.loads((ROOT / "CivoCloudManager/Localizable.xcstrings").read_text())
    assert catalog["sourceLanguage"] == "en"
    info = plistlib.loads((ROOT / "CivoCloudManager/Info.plist").read_bytes())
    assert info["CFBundleDevelopmentRegion"] == "en"
    assert set(info["CFBundleLocalizations"]) == set(LANGUAGES)
    runtime_keys = runtime_localization_keys()
    missing_runtime_keys = runtime_keys - catalog["strings"].keys()
    assert not missing_runtime_keys, f"Help/sidebar keys absent from catalog: {sorted(missing_runtime_keys)}"
    if args.derived_data:
        extracted_files = list(args.derived_data.rglob("*.stringsdata"))
        assert extracted_files, "No Swift localization extraction files found"
        for path in extracted_files:
            extracted = json.loads(path.read_text())
            for entry in extracted.get("tables", {}).get("Localizable", []):
                assert entry["key"] in catalog["strings"], (extracted.get("source"), entry["key"], "not in catalog")
    for key, entry in catalog["strings"].items():
        locales = entry.get("localizations", {})
        assert set(locales) == set(LANGUAGES), f"Incomplete language coverage: {key!r}"
        source = locales["en"]["stringUnit"]["value"]
        for language in LANGUAGES:
            unit = locales[language]["stringUnit"]
            value = unit["value"]
            assert unit["state"] == "translated", (key, language)
            assert not source.strip() or value.strip(), (key, language, "empty")
            assert format_arguments(source) == format_arguments(value), (key, language, "format arguments")
            assert "⟪KEEP" not in value, (key, language, "temporary placeholder")
            if key in runtime_keys:
                # Keep literal counts/ports/timers. A spelled-out English "one"
                # may legitimately become a digit, and K8s is an identifier.
                source_numbers = Counter(re.findall(r"(?<![A-Za-z0-9])\d+", source))
                translated_numbers = Counter(re.findall(r"(?<![A-Za-z0-9])\d+", value))
                assert source_numbers <= translated_numbers, (key, language, "help numbers")
                for token in ("DELETE ALL DATA", "~/.ssh/", "civo-cloud-manager", ".yaml", "⌘K", "⌘⇧E"):
                    assert source.count(token) == value.count(token), (key, language, "literal instruction", token)

    for language in LANGUAGES:
        path = ROOT / "CivoCloudManager" / f"{language}.lproj" / "InfoPlist.strings"
        localized_info = read_strings(path)
        assert localized_info["CFBundleDisplayName"] == "Civo Cloud Manager", path
        assert localized_info["NSFaceIDUsageDescription"].strip(), path
        if args.app:
            resources = args.app / "Contents/Resources" / f"{language}.lproj"
            bundled = read_strings(resources / "Localizable.strings")
            for key, entry in catalog["strings"].items():
                assert bundled.get(key) == entry["localizations"][language]["stringUnit"]["value"], (language, key, "bundle mismatch")
            bundled_info = read_strings(resources / "InfoPlist.strings")
            assert bundled_info == localized_info, (language, "InfoPlist bundle mismatch")
    print(f"Validated {len(catalog['strings'])} catalog entries in {len(LANGUAGES)} languages."
          + (" Built app resources match." if args.app else ""))


if __name__ == "__main__":
    main()
