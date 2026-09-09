#!/usr/bin/env python3
"""Check legal translations; optionally verify the resources in a built .app."""

import argparse
from collections import Counter
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("en", "de", "es", "fr", "it", "nl", "pl", "pt")
DOCUMENTS = (
    "AcceptableUsePolicy.md", "EULA.md", "Impressum.md", "PrivacyPolicy.md",
    "PushNotificationConsent.md", "TermsOfService.md", "TrademarkDisclaimer.md",
)
COMPANY_DATA = (
    "DigitalFreedom Global LLC", "30 N Gould St, Ste N", "Sheridan, WY 82801",
    "+1 307 451 0707", "2026-002048530",
)


def content(text):
    return re.sub(r"<!--.*?-->", "", text, flags=re.S).strip()


def signature(text):
    return {
        "headings": re.findall(r"^(#{1,6})\s+(\d+(?:\.\d+)*)?", text, re.M),
        "numbers": Counter(re.findall(r"\d+", text)),
        "links": Counter(re.findall(
            r"https?://[^\s<>`)]+|[\w.+-]+@[\w.-]+\.[A-Za-z]+|(?<=\]\()[^)]+", text
        )),
        "bullets": len(re.findall(r"^[-*] ", text, re.M)),
        "table_cells": text.count("|"),
        "company": {value: text.count(value) for value in COMPANY_DATA},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Built macOS .app to inspect")
    args = parser.parse_args()
    checked = 0
    for name in DOCUMENTS:
        source = content((ROOT / "CivoCloudManager/en.lproj" / name).read_text())
        for language in LANGUAGES:
            path = ROOT / "CivoCloudManager" / f"{language}.lproj" / name
            raw = path.read_text()
            translated = content(raw)
            assert f"lang: {language} |" in raw.splitlines()[0], path
            assert translated and "DigitalFreedom Global LLC" in translated, path
            assert "{{" not in translated and "⟪KEEP" not in translated, path
            assert signature(source) == signature(translated), f"Content structure differs: {path}"
            if language != "en":
                assert translated != source, f"Untranslated document: {path}"
            if args.app:
                bundled = args.app / "Contents/Resources" / f"{language}.lproj" / name
                assert bundled.read_bytes() == path.read_bytes(), f"Missing or stale bundle resource: {bundled}"
            checked += 1
    print(f"Validated {checked} legal documents in {len(LANGUAGES)} languages."
          + (" Built app resources match." if args.app else ""))


if __name__ == "__main__":
    main()
